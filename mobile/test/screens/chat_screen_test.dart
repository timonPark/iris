import 'dart:async';

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
    expect(find.text('새 세션'), findsOneWidget);
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
}
