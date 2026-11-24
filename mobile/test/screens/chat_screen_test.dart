import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:iris/auth/auth_controller.dart';
import 'package:iris/auth/auth_storage.dart';
import 'package:iris/main.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_api.dart';

const String sendPath = '/api/v1/sessions/questions';
const AuthStorage storage = AuthStorage();

Future<void> startChat(WidgetTester tester, FakeApi api) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  await storage.save(
    const StoredAuth(
      accessToken: 'token-1',
      passwordChangeRequired: false,
      loginId: 'jhpark',
    ),
  );
  await tester.pumpWidget(
    IrisApp(
      controller: AuthController(
        storage: storage,
        baseUrl: 'http://api.test',
        httpClient: api.client,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> ask(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byTooltip('질문 보내기'));
  await tester.pump();
}

Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('세션 목록 열기'));
  await tester.pumpAndSettle();
}

/// 서랍을 열고 [새 세션]을 누른다.
Future<void> tapNewSession(WidgetTester tester) async {
  await openDrawer(tester);
  await tester.tap(inDrawer('새 세션'));
  await tester.pumpAndSettle();
}

Finder inDrawer(String text) =>
    find.descendant(of: find.byType(Drawer), matching: find.text(text));

/// 서랍의 세션 제목(위에서부터).
List<String?> drawerTitles(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Text && w.maxLines == 1,
        ),
      ),
    )
    .map((Text t) => t.data)
    .toList();

const String pastQuestionsPath = '/api/v1/sessions/s0/questions';

/// 목록에 "지난 세션" 하나(옛 질문, 옛 답).
Map<String, FakeHandler> pastSession() => <String, FakeHandler>{
  '/api/v1/sessions': (_) => sessionPage(<String>['지난 세션']),
  pastQuestionsPath: (_) =>
      questionPage(<(String, String, String)>[('옛 질문', '옛 답', 'completed')]),
};

Future<void> openPastSession(WidgetTester tester) async {
  await openDrawer(tester);
  await tester.tap(find.text('지난 세션'));
  await tester.pumpAndSettle();
  expect(find.text('옛 답'), findsOneWidget);
}

/// 위쪽 막대가 "새 세션"이고 대화 없이 안내만 보인다.
void expectBlankNewSession() {
  expect(
    find.descendant(of: find.byType(AppBar), matching: find.text('새 세션')),
    findsOneWidget,
  );
  expect(find.text('Iris에게 질문하세요'), findsOneWidget);
  expect(find.text('옛 답'), findsNothing);
}

/// 첫 질문은 [sse]로 흘리고, 그다음 질문은 '다음 답'으로 바로 끝난다.
FakeStreamHandler firstThenDone(ControlledSse sse) {
  int sends = 0;
  return (http.Request r) => sends++ == 0
      ? sse.handler(r)
      : http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode(sseDone('다음 답'))),
          200,
        );
}

/// 지난 세션 열람 응답을 [page]가 끝날 때까지 미룬다.
Map<String, FakeStreamHandler> delayed(Completer<List<int>> page) =>
    <String, FakeStreamHandler>{
      pastQuestionsPath: (_) =>
          http.StreamedResponse(Stream<List<int>>.fromFuture(page.future), 200),
    };

String sseDone(String answer) => <String>[
  sseEvent('session', <String, Object>{'id': 'new1'}),
  sseEvent('delta', <String, Object>{'text': answer}),
  sseEvent('done', <String, Object>{'answerId': 'a1'}),
].join();

void main() {
  testWidgets('로그인 뒤에는 빈 새 세션', (WidgetTester tester) async {
    await startChat(tester, FakeApi(<String, FakeHandler>{}));

    expect(find.text('새 세션'), findsOneWidget);
    expect(find.text('Iris에게 질문하세요'), findsOneWidget);
    expect(
      find.text('입력하거나 녹음 버튼을 눌러 말해 보세요. 지난 대화는 세션 목록에서 볼 수 있습니다.'),
      findsOneWidget,
    );
  });

  testWidgets('질문하면 답변이 스트리밍되고 중지 버튼이 보인다', (WidgetTester tester) async {
    final ControlledSse sse = ControlledSse();
    await startChat(
      tester,
      FakeApi(
        <String, FakeHandler>{},
        streams: <String, FakeStreamHandler>{sendPath: sse.handler},
      ),
    );

    await ask(tester, '주간 보고서 써 줘');
    sse.send('session', <String, Object>{'id': 'new1'});
    sse.send('delta', <String, Object>{'text': '초안입니다.'});
    await tester.pump();

    expect(find.text('주간 보고서 써 줘'), findsWidgets);
    expect(find.textContaining('초안입니다.'), findsOneWidget);
    expect(find.text('답변을 받는 중…'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '중지'), findsOneWidget);

    sse.send('done', <String, Object>{'answerId': 'a1'});
    await sse.cut();
    await tester.pumpAndSettle();

    expect(find.text('답변을 받는 중…'), findsNothing);
    // 입력이 비어 있으므로 보내기 자리는 녹음 버튼이다(#32).
    expect(find.byTooltip('녹음 시작'), findsOneWidget);
  });

  testWidgets('답변이 끝나면 같은 세션에 이어서 질문한다', (WidgetTester tester) async {
    final List<String> replies = <String>[sseDone('첫 답'), sseDone('둘째 답')];
    final FakeApi api = FakeApi(<String, FakeHandler>{
      sendPath: (_) => sseReply(<String>[replies.removeAt(0)]),
    });
    await startChat(tester, api);

    await ask(tester, '첫 질문');
    await tester.pumpAndSettle();
    await ask(tester, '둘째 질문');
    await tester.pumpAndSettle();

    expect(find.text('둘째 답'), findsOneWidget);
    final List<http.Request> sent = api.requestsTo(sendPath);
    expect(sent, hasLength(2));
    expect(requestJson(sent.last), <String, String>{
      'text': '둘째 질문',
      'sessionId': 'new1',
    });
  });

  testWidgets('65,536자를 넘으면 보내지 않고 안내', (WidgetTester tester) async {
    final FakeApi api = FakeApi(<String, FakeHandler>{});
    await startChat(tester, api);

    await ask(tester, '가' * 65537);

    expect(find.text('질문은 65,536자까지 보낼 수 있습니다.'), findsOneWidget);
    expect(api.requestsTo(sendPath), isEmpty);
  });

  testWidgets('세션 목록에서 지난 세션을 열면 중단된 답변이 보인다', (WidgetTester tester) async {
    await startChat(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['독서 메모 찾아 줘']),
        '/api/v1/sessions/s0/questions': (_) => questionPage(
          <(String, String, String)>[('2장도 정리해 줘', '2장은', 'stopped')],
        ),
      }),
    );

    await openDrawer(tester);
    expect(find.text('jhpark'), findsOneWidget);
    await tester.tap(find.text('독서 메모 찾아 줘'));
    await tester.pumpAndSettle();

    expect(find.text('독서 메모 찾아 줘'), findsOneWidget);
    expect(find.text('2장은'), findsOneWidget);
    expect(find.text('중단됨'), findsOneWidget);
  });

  testWidgets('목록 끝까지 내리면 다음 세션을 이어서 불러온다', (WidgetTester tester) async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions': (http.Request r) =>
          r.url.queryParameters['cursor'] == null
          ? sessionPage(<String>[
              for (int i = 0; i < 20; i++) '세션 $i',
            ], next: 'c1')
          : sessionPage(<String>['마지막 세션'], from: 20),
    });
    await startChat(tester, api);
    await openDrawer(tester);
    expect(api.requestsTo('/api/v1/sessions'), hasLength(1));

    await tester.scrollUntilVisible(
      find.text('마지막 세션'),
      200,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );

    expect(api.requestsTo('/api/v1/sessions'), hasLength(2));
    expect(find.text('마지막 세션'), findsOneWidget);
  });

  testWidgets('세션을 삭제하면 확인한 뒤 목록에서 빠진다', (WidgetTester tester) async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions': (_) => sessionPage(<String>['여행 준비물', '운동 루틴']),
      '/api/v1/sessions/s0': (_) => http.Response('', 204),
    });
    await startChat(tester, api);
    await openDrawer(tester);

    await tester.tap(find.byTooltip("'여행 준비물' 세션 삭제"));
    await tester.pumpAndSettle();
    expect(find.text('세션을 삭제할까요?'), findsOneWidget);
    expect(find.text("'여행 준비물' 세션이 목록에서 사라지고 다시 볼 수 없습니다."), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(api.requestsTo('/api/v1/sessions/s0').single.method, 'DELETE');
    expect(find.text('여행 준비물'), findsNothing);
    expect(find.text('운동 루틴'), findsOneWidget);
  });

  testWidgets('답변이 저장되면 세션 목록 맨 위에 생긴다', (WidgetTester tester) async {
    await startChat(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['옛 세션']),
        sendPath: (_) => sseReply(<String>[sseDone('답')]),
      }),
    );

    await ask(tester, '새 질문');
    await tester.pumpAndSettle();
    await openDrawer(tester);

    final Offset newRow = tester.getTopLeft(
      find.descendant(of: find.byType(Drawer), matching: find.text('새 질문')),
    );
    expect(newRow.dy, lessThan(tester.getTopLeft(find.text('옛 세션')).dy));
  });

  testWidgets('질문 중 차단되면 로그인 화면에서 안내', (WidgetTester tester) async {
    await startChat(
      tester,
      FakeApi(<String, FakeHandler>{
        sendPath: (_) => errorResponse(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.'),
      }),
    );

    await ask(tester, '질문');
    await tester.pumpAndSettle();

    expect(find.text('차단된 계정입니다. 관리자에게 문의해 주세요.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
  });

  testWidgets('설정은 세션 목록 아래에서 연다', (WidgetTester tester) async {
    await startChat(tester, FakeApi(<String, FakeHandler>{}));
    await openDrawer(tester);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('비밀번호 변경'), findsWidgets);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('설정에서 뒤로 가면 채팅으로 돌아온다(세션이 없어도)', (WidgetTester tester) async {
    await startChat(tester, FakeApi(<String, FakeHandler>{}));
    await openDrawer(tester);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('채팅으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('Iris에게 질문하세요'), findsOneWidget);
    expect(find.text('새 세션'), findsOneWidget);
  });

  testWidgets('삭제 중에 대화상자를 닫아도 지워지면 목록에서 빠진다', (WidgetTester tester) async {
    final Completer<List<int>> reply = Completer<List<int>>();
    final FakeApi api = FakeApi(
      <String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['여행 준비물']),
      },
      streams: <String, FakeStreamHandler>{
        '/api/v1/sessions/s0': (_) => http.StreamedResponse(
          Stream<List<int>>.fromFuture(reply.future),
          204,
        ),
      },
    );
    await startChat(tester, api);
    await openDrawer(tester);
    await tester.tap(find.byTooltip("'여행 준비물' 세션 삭제"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
    await tester.pumpAndSettle();

    reply.complete(<int>[]);
    await tester.pumpAndSettle();

    expect(find.text('여행 준비물'), findsNothing);
  });

  testWidgets('답변 중인 세션을 목록에서 다시 눌러도 받던 답변을 잃지 않는다', (
    WidgetTester tester,
  ) async {
    final ControlledSse sse = ControlledSse();
    final FakeApi api = FakeApi(
      <String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['지난 세션']),
        '/api/v1/sessions/s0/questions': (_) => questionPage(
          <(String, String, String)>[('옛 질문', '옛 답', 'completed')],
        ),
      },
      streams: <String, FakeStreamHandler>{sendPath: sse.handler},
    );
    await startChat(tester, api);
    await openDrawer(tester);
    await tester.tap(find.text('지난 세션'));
    await tester.pumpAndSettle();
    await ask(tester, '이어서 질문');
    sse.send('delta', <String, Object>{'text': '이어지는 조각'});
    await tester.pump();

    await openDrawer(tester);
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('지난 세션')),
    );
    await tester.pumpAndSettle();

    expect(api.requestsTo('/api/v1/sessions/s0/questions'), hasLength(1));
    expect(find.textContaining('이어지는 조각'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '중지'), findsOneWidget);
  });

  testWidgets('보고 있는 세션을 지우면 빈 새 세션으로', (WidgetTester tester) async {
    await startChat(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['지난 세션']),
        '/api/v1/sessions/s0/questions': (_) => questionPage(
          <(String, String, String)>[('옛 질문', '옛 답', 'completed')],
        ),
        '/api/v1/sessions/s0': (_) => http.Response('', 204),
      }),
    );
    await openDrawer(tester);
    await tester.tap(find.text('지난 세션'));
    await tester.pumpAndSettle();
    expect(find.text('옛 답'), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(find.byTooltip("'지난 세션' 세션 삭제"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('Iris에게 질문하세요'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('새 세션')),
      findsOneWidget,
    );
  });

  testWidgets('삭제에 실패하면 대화상자에 오류를 보이고 목록에 둔다', (WidgetTester tester) async {
    await startChat(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['여행 준비물']),
        '/api/v1/sessions/s0': (_) =>
            errorResponse(500, 'SERVER_ERROR', '서버 오류가 발생했습니다.'),
      }),
    );
    await openDrawer(tester);
    await tester.tap(find.byTooltip("'여행 준비물' 세션 삭제"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('세션을 삭제할까요?'), findsOneWidget);
    expect(find.text('서버 오류가 발생했습니다.'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
    await tester.pumpAndSettle();
    expect(find.text('여행 준비물'), findsOneWidget);
  });

  group('새 세션 버튼', () {
    testWidgets('지난 세션을 연 뒤 누르면 빈 새 세션이 되고 다음 질문은 새 세션으로 저장된다', (
      WidgetTester tester,
    ) async {
      final FakeApi api = FakeApi(<String, FakeHandler>{
        ...pastSession(),
        sendPath: (_) => sseReply(<String>[sseDone('새 답')]),
      });
      await startChat(tester, api);
      await openPastSession(tester);

      await tapNewSession(tester);

      expect(find.byType(Drawer), findsNothing);
      expectBlankNewSession();
      await ask(tester, '새 질문');
      await tester.pumpAndSettle();
      expect(requestJson(api.requestsTo(sendPath).single), <String, String>{
        'text': '새 질문',
      });
      await openDrawer(tester);
      expect(drawerTitles(tester), <String>['새 질문', '지난 세션']);
    });

    testWidgets('이미 빈 새 세션이면 아무 일도 없다(쓰던 입력도 그대로)', (
      WidgetTester tester,
    ) async {
      await startChat(tester, FakeApi(<String, FakeHandler>{}));
      await tester.enterText(find.byType(TextField), '쓰는 중');

      await tapNewSession(tester);

      expectBlankNewSession();
      expect(find.text('쓰는 중'), findsOneWidget);
    });

    testWidgets('답변을 받는 중에 누르고 바로 질문해도 두 세션이 따로 저장된다', (
      WidgetTester tester,
    ) async {
      final ControlledSse sse = ControlledSse();
      final FakeApi api = FakeApi(
        <String, FakeHandler>{},
        streams: <String, FakeStreamHandler>{sendPath: firstThenDone(sse)},
      );
      await startChat(tester, api);
      await ask(tester, '긴 질문');
      sse.send('session', <String, Object>{'id': 'long1'});
      sse.send('delta', <String, Object>{'text': '받는 중인 조각'});
      await tester.pump();

      await tapNewSession(tester);
      expectBlankNewSession();
      expect(find.textContaining('받는 중인 조각'), findsNothing);
      await ask(tester, '다음 질문');
      await tester.pumpAndSettle();
      sse.send('done', <String, Object>{'answerId': 'a1'});
      await sse.cut();
      await tester.pumpAndSettle();

      expect(requestJson(api.requestsTo(sendPath).last), <String, String>{
        'text': '다음 질문',
      });
      expect(find.text('다음 답'), findsOneWidget);
      await openDrawer(tester);
      expect(drawerTitles(tester), <String>['긴 질문', '다음 질문']);
    });

    testWidgets('지난 세션을 보다 설정으로 간 뒤 누르면 채팅의 빈 새 세션으로', (
      WidgetTester tester,
    ) async {
      await startChat(tester, FakeApi(pastSession()));
      await openPastSession(tester);
      await openDrawer(tester);
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();

      // 설정의 위쪽 막대는 뒤로 가기라 서랍은 화면 왼쪽 끝에서 밀어 연다.
      await tester.dragFrom(const Offset(1, 300), const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.tap(inDrawer('새 세션'));
      await tester.pumpAndSettle();

      expect(find.text('비밀번호 변경'), findsNothing);
      expectBlankNewSession();
    });

    testWidgets('지난 세션을 불러오는 중에 누르면 늦게 온 지난 대화가 덮지 않는다', (
      WidgetTester tester,
    ) async {
      final Completer<List<int>> page = Completer<List<int>>();
      await startChat(tester, FakeApi(pastSession(), streams: delayed(page)));
      await openDrawer(tester);
      await tester.tap(find.text('지난 세션'));
      // 불러오는 중 표시가 계속 움직여 pumpAndSettle 대신 시간을 정해 흘린다.
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byTooltip('세션 목록 열기'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(inDrawer('새 세션'));
      await tester.pumpAndSettle();

      page.complete(
        pastSession()[pastQuestionsPath]!(http.Request('GET', Uri())).bodyBytes,
      );
      await tester.pumpAndSettle();

      expectBlankNewSession();
    });
  });
}
