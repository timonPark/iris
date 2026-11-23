import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:iris/api/api_client.dart';
import 'package:iris/api/api_models.dart';
import 'package:iris/chat/sessions_controller.dart';

import '../support/fake_api.dart';

SessionsController sessionsWith(FakeApi api) {
  return SessionsController(
    ApiClient(
      baseUrl: 'http://api.test',
      httpClient: api.client,
      getAccessToken: () => 't',
      onAuthError: (_) {},
    ),
  );
}

void main() {
  test('페이지를 이어 불러오고 마지막이면 멈춘다', () async {
    final List<http.Response> pages = <http.Response>[
      sessionPage(<String>['가', '나'], next: 'c1'),
      sessionPage(<String>['다'], from: 2),
    ];
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions': (_) => pages.removeAt(0),
    });
    final SessionsController sessions = sessionsWith(api);

    await sessions.loadMore();
    expect(sessions.items.map((Session s) => s.title), <String>['가', '나']);
    expect(sessions.hasMore, isTrue);

    await sessions.loadMore();
    await sessions.loadMore();
    expect(sessions.items.map((Session s) => s.title), <String>['가', '나', '다']);
    expect(sessions.hasMore, isFalse);
    expect(api.requests, hasLength(2));
    expect(api.requests.last.url.queryParameters['cursor'], 'c1');
  });

  test('불러오다 실패하면 오류 문구, 다시 부르면 이어서', () async {
    final List<http.Response> pages = <http.Response>[
      errorResponse(500, 'SERVER_ERROR', '서버 오류가 발생했습니다.'),
      sessionPage(<String>['가']),
    ];
    final SessionsController sessions = sessionsWith(
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => pages.removeAt(0),
      }),
    );

    await sessions.loadMore();
    expect(sessions.error, '서버 오류가 발생했습니다.');

    await sessions.loadMore();
    expect(sessions.error, isNull);
    expect(sessions.items.single.title, '가');
  });

  test('저장된 세션은 맨 위로, 지운 세션은 빠진다', () async {
    final SessionsController sessions = sessionsWith(
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['가', '나']),
      }),
    );
    await sessions.loadMore();

    sessions.putOnTop(
      Session(id: 's1', title: '나', updatedAt: DateTime.utc(2026)),
    );
    sessions.putOnTop(
      Session(id: 'new', title: '새', updatedAt: DateTime.utc(2026)),
    );
    sessions.remove('s0');

    expect(sessions.items.map((Session s) => s.id), <String>['new', 's1']);
  });

  test('지운 세션은 나중에 저장 알림이 와도 다시 올라오지 않는다', () async {
    final SessionsController sessions = sessionsWith(
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['가']),
      }),
    );
    await sessions.loadMore();

    sessions.remove('s0');
    sessions.putOnTop(
      Session(id: 's0', title: '가', updatedAt: DateTime.utc(2026)),
    );

    expect(sessions.items, isEmpty);
  });

  test('불러올 때마다 횟수가 늘어 목록 끝 표시를 다시 만든다', () async {
    final SessionsController sessions = sessionsWith(
      FakeApi(<String, FakeHandler>{
        '/api/v1/sessions': (_) => sessionPage(<String>['가'], next: 'c'),
      }),
    );
    await sessions.loadMore();
    final int first = sessions.loads;
    await sessions.loadMore();

    expect(sessions.items, hasLength(1));
    expect(sessions.loads, first + 1);
  });
}
