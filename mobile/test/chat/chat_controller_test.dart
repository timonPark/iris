import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:iris/api/api_client.dart';
import 'package:iris/api/api_models.dart';
import 'package:iris/chat/chat_controller.dart';
import 'package:iris/chat/chat_item.dart';

import '../support/fake_api.dart';

const String send = '/api/v1/sessions/questions';

class Harness {
  Harness(this.api, {this.foreground = true}) {
    chat = ChatController(
      client: ApiClient(
        baseUrl: 'http://api.test',
        httpClient: api.client,
        getAccessToken: () => 't',
        onAuthError: (_) {},
      ),
      onSaved: saved.add,
      isForeground: () => foreground,
    );
  }

  final FakeApi api;
  bool foreground;
  late final ChatController chat;
  final List<Session> saved = <Session>[];

  ChatItem get last => chat.items.last;
}

void main() {
  test('새 세션에 질문하면 답변이 쌓이고, 끝나면 세션이 저장된다', () async {
    final Harness h = Harness(
      FakeApi(<String, FakeHandler>{
        send: (_) => sseReply(<String>[
          sseEvent('session', <String, Object>{'id': 's1'}),
          sseEvent('delta', <String, Object>{'text': '안녕'}),
          sseEvent('delta', <String, Object>{'text': '하세요'}),
          sseEvent('done', <String, Object>{'answerId': 'a1'}),
        ]),
      }),
    );

    await h.chat.send('인사해 줘');

    expect(h.last.question, '인사해 줘');
    expect(h.last.answer?.text, '안녕하세요');
    expect(h.last.answer?.state, AnswerState.completed);
    expect(h.chat.sessionId, 's1');
    expect(h.chat.title, '인사해 줘');
    expect(h.chat.streaming, isFalse);
    expect(h.saved.single.id, 's1');
  });

  test('session 이벤트 뒤에 중지할 수 있고, 중지하면 중단됨', () async {
    final ControlledSse sse = ControlledSse();
    final Harness h = Harness(
      FakeApi(
        <String, FakeHandler>{
          '/api/v1/sessions/s1/stop': (_) => http.Response('', 204),
        },
        streams: <String, FakeStreamHandler>{send: sse.handler},
      ),
    );

    final Future<void> sending = h.chat.send('길게 답해 줘');
    await pumpEventQueue();
    expect(h.chat.streaming, isTrue);
    expect(h.chat.canStop, isFalse);

    sse.send('session', <String, Object>{'id': 's1'});
    sse.send('delta', <String, Object>{'text': '첫'});
    await pumpEventQueue();
    expect(h.chat.canStop, isTrue);
    expect(h.last.answer?.state, AnswerState.streaming);

    await h.chat.stop();
    sse.send('stopped', <String, Object>{'answerId': 'a1'});
    await sse.cut();
    await sending;

    expect(h.api.requestsTo('/api/v1/sessions/s1/stop'), hasLength(1));
    expect(h.last.answer?.state, AnswerState.stopped);
    expect(h.last.answer?.text, '첫');
    expect(h.saved.single.id, 's1');
  });

  test('시작 전 실패는 답변 없이 서버 오류 안내', () async {
    final Harness h = Harness(
      FakeApi(<String, FakeHandler>{
        send: (_) => errorResponse(500, 'SERVER_ERROR', '서버 오류'),
      }),
    );

    await h.chat.send('질문');

    expect(h.last.answer, isNull);
    expect(h.last.error, '서버 오류가 발생했습니다. 잠시 후 다시 질문해 주세요.');
    expect(h.saved, isEmpty);
  });

  test('답변 중 error 이벤트는 받은 부분을 중단됨으로 두고 규격 문구', () async {
    final Harness h = Harness(
      FakeApi(<String, FakeHandler>{
        send: (_) => sseReply(<String>[
          sseEvent('session', <String, Object>{'id': 's1'}),
          sseEvent('delta', <String, Object>{'text': '반쯤'}),
          sseEvent('error', <String, Object>{
            'code': 'SESSION_BUSY',
            'message': '답변 중입니다.',
          }),
        ]),
      }),
    );

    await h.chat.send('질문');

    expect(h.last.answer?.state, AnswerState.stopped);
    expect(h.last.error, '답변 중입니다.');
    expect(h.saved.single.id, 's1');
  });

  group('연결이 끊기면', () {
    late ControlledSse sse;
    late FakeApi api;
    late List<http.Response> reloads;

    setUp(() {
      sse = ControlledSse();
      reloads = <http.Response>[];
      api = FakeApi(
        <String, FakeHandler>{
          '/api/v1/sessions/s1/questions': (_) => reloads.removeAt(0),
        },
        streams: <String, FakeStreamHandler>{send: sse.handler},
      );
    });

    Future<Harness> cutAfterDelta({required bool foreground}) async {
      final Harness h = Harness(api, foreground: foreground);
      final Future<void> sending = h.chat.send('질문');
      sse.send('session', <String, Object>{'id': 's1'});
      sse.send('delta', <String, Object>{'text': '받은 부분'});
      sse.fail();
      await sending;
      return h;
    }

    test('받은 부분까지 두고 안내, 앞으로 오면 다시 불러와 저장된 답변을 보인다', () async {
      final Harness h = await cutAfterDelta(foreground: false);

      expect(h.last.answer?.text, '받은 부분');
      expect(h.last.answer?.state, AnswerState.disconnected);
      expect(h.last.notice, '연결이 끊겼습니다. 답변은 서버에서 계속 저장됩니다.');
      expect(h.chat.streaming, isFalse);
      expect(api.requestsTo('/api/v1/sessions/s1/questions'), isEmpty);

      reloads.add(
        questionPage(<(String, String, String)>[('질문', '전체 답변', 'completed')]),
      );
      h.foreground = true;
      await h.chat.resumed();

      expect(h.last.answer?.text, '전체 답변');
      expect(h.last.answer?.state, AnswerState.completed);
      expect(h.last.notice, isNull);
      expect(h.chat.sessionId, 's1');
      expect(h.saved.single.id, 's1');
    });

    test('앞에 있을 때 끊기면 바로 다시 불러오고, 아직 저장 전이면 안내를 둔다', () async {
      reloads.add(questionPage(<(String, String, String)>[]));

      final Harness h = await cutAfterDelta(foreground: true);
      await pumpEventQueue();

      expect(api.requestsTo('/api/v1/sessions/s1/questions'), hasLength(1));
      expect(h.last.answer?.text, '받은 부분');
      expect(h.last.notice, isNotNull);
      expect(h.saved, isEmpty);
    });
  });

  test('세션을 열면 질문을 끝까지 받아 오래된 순으로 보인다', () async {
    final List<http.Response> pages = <http.Response>[
      questionPage(<(String, String, String)>[
        ('셋', 'c', 'completed'),
        ('둘', 'b', 'stopped'),
      ], next: 'p2'),
      questionPage(<(String, String, String)>[('하나', 'a', 'completed')]),
    ];
    final Harness h = Harness(
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions/s9/questions': (_) => pages.removeAt(0),
      }),
    );

    await h.chat.open(
      Session(id: 's9', title: '지난 세션', updatedAt: DateTime.utc(2026)),
    );

    expect(h.chat.items.map((ChatItem i) => i.question), <String>[
      '하나',
      '둘',
      '셋',
    ]);
    expect(h.chat.items[1].answer?.state, AnswerState.stopped);
    expect(h.chat.title, '지난 세션');
    expect(h.chat.sessionId, 's9');
    expect(h.chat.loading, isFalse);
    expect(h.api.requests.last.url.queryParameters['cursor'], 'p2');
  });

  test('세션을 불러오지 못하면 오류 문구', () async {
    final Harness h = Harness(
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions/s9/questions': (_) =>
            errorResponse(404, 'SESSION_NOT_FOUND', '세션을 찾을 수 없습니다.'),
      }),
    );

    await h.chat.open(
      Session(id: 's9', title: 't', updatedAt: DateTime.utc(2026)),
    );

    expect(h.chat.loadError, '세션을 찾을 수 없습니다.');
    expect(h.chat.items, isEmpty);
  });

  test('다른 세션을 열어도 받던 답변은 끝까지 읽어 저장되면 알린다', () async {
    final ControlledSse sse = ControlledSse();
    final Harness h = Harness(
      FakeApi(
        <String, FakeHandler>{
          '/api/v1/sessions/s9/questions': (_) =>
              questionPage(<(String, String, String)>[('옛', '답', 'completed')]),
        },
        streams: <String, FakeStreamHandler>{send: sse.handler},
      ),
    );

    final Future<void> sending = h.chat.send('새 질문');
    sse.send('session', <String, Object>{'id': 's1'});
    await pumpEventQueue();
    await h.chat.open(
      Session(id: 's9', title: '옛 세션', updatedAt: DateTime.utc(2026)),
    );
    sse.send('delta', <String, Object>{'text': '뒤에서'});
    sse.send('done', <String, Object>{'answerId': 'a1'});
    await sse.cut();
    await sending;

    expect(h.chat.sessionId, 's9');
    expect(h.chat.items.single.question, '옛');
    expect(h.chat.streaming, isFalse);
    expect(h.saved.single.id, 's1');
  });

  test('새로 시작하면 빈 새 세션', () async {
    final Harness h = Harness(
      FakeApi(<String, FakeHandler>{
        send: (_) => sseReply(<String>[
          sseEvent('session', <String, Object>{'id': 's1'}),
          sseEvent('delta', <String, Object>{'text': '답'}),
          sseEvent('done', <String, Object>{'answerId': 'a1'}),
        ]),
      }),
    );
    await h.chat.send('질문');

    h.chat.reset();

    expect(h.chat.items, isEmpty);
    expect(h.chat.sessionId, isNull);
    expect(h.chat.title, isNull);
  });

  test('첫 답변이 저장 전에 끊겨도 다음 질문은 같은 세션으로 보낸다', () async {
    final ControlledSse sse = ControlledSse();
    final FakeApi api = FakeApi(
      <String, FakeHandler>{
        '/api/v1/sessions/s1/questions': (_) =>
            questionPage(<(String, String, String)>[]),
      },
      streams: <String, FakeStreamHandler>{send: sse.handler},
    );
    final Harness h = Harness(api, foreground: false);
    final Future<void> first = h.chat.send('첫 질문');
    sse.send('session', <String, Object>{'id': 's1'});
    sse.send('delta', <String, Object>{'text': '조각'});
    sse.fail();
    await first;

    api.streams[send] = (_) =>
        ControlledSse().handler(http.Request('POST', Uri()));
    unawaited(h.chat.send('둘째 질문'));
    await pumpEventQueue();

    expect(requestJson(api.requestsTo(send).last), <String, String>{
      'text': '둘째 질문',
      'sessionId': 's1',
    });
  });

  test('없앤 뒤에 오는 이벤트는 무시하고 저장도 알리지 않는다', () async {
    final ControlledSse sse = ControlledSse();
    final Harness h = Harness(
      FakeApi(
        <String, FakeHandler>{},
        streams: <String, FakeStreamHandler>{send: sse.handler},
      ),
    );
    unawaited(h.chat.send('질문'));
    sse.send('session', <String, Object>{'id': 's1'});
    await pumpEventQueue();

    h.chat.dispose();
    sse.send('delta', <String, Object>{'text': '늦은 조각'});
    sse.send('done', <String, Object>{'answerId': 'a1'});
    await pumpEventQueue();

    expect(h.saved, isEmpty);
  });

  test('끝 이벤트를 받으면 연결이 닫히기 전에도 받는 중이 끝난다', () async {
    final ControlledSse sse = ControlledSse();
    final Harness h = Harness(
      FakeApi(
        <String, FakeHandler>{},
        streams: <String, FakeStreamHandler>{send: sse.handler},
      ),
    );
    final Future<void> sending = h.chat.send('질문');
    sse.send('session', <String, Object>{'id': 's1'});
    sse.send('delta', <String, Object>{'text': '답'});
    sse.send('done', <String, Object>{'answerId': 'a1'});
    await sending;

    expect(h.chat.streaming, isFalse);
    expect(h.last.answer?.state, AnswerState.completed);
  });

  test('돌아와서 다시 불러오기에 실패하면 다음에 다시 시도한다', () async {
    final ControlledSse sse = ControlledSse();
    final List<http.Response> reloads = <http.Response>[
      errorResponse(500, 'SERVER_ERROR', '오류'),
      questionPage(<(String, String, String)>[('질문', '전체', 'completed')]),
    ];
    final Harness h = Harness(
      FakeApi(
        <String, FakeHandler>{
          '/api/v1/sessions/s1/questions': (_) => reloads.removeAt(0),
        },
        streams: <String, FakeStreamHandler>{send: sse.handler},
      ),
      foreground: false,
    );
    final Future<void> sending = h.chat.send('질문');
    sse.send('session', <String, Object>{'id': 's1'});
    sse.send('delta', <String, Object>{'text': '조각'});
    sse.fail();
    await sending;

    await h.chat.resumed();
    expect(h.last.notice, isNotNull);
    await h.chat.resumed();

    expect(h.last.answer?.text, '전체');
    expect(h.last.notice, isNull);
  });
}
