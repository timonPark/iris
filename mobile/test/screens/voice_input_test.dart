import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/auth/auth_controller.dart';
import 'package:iris/auth/auth_storage.dart';
import 'package:iris/main.dart';
import 'package:iris/voice/voice_recorder.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_api.dart';
import '../support/fake_recorder.dart';

const String voicePath = '/api/v1/voice/questions';
const AuthStorage storage = AuthStorage();

Future<void> startChat(
  WidgetTester tester,
  FakeApi api,
  FakeRecorder recorder,
) async {
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
      recorder: recorder,
    ),
  );
  await tester.pumpAndSettle();
}

/// 업로드의 파일 읽기 같은 실제 입출력이 끝나도록 실제 시간과 가짜 시간을 번갈아 흘린다.
Future<void> settleIo(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Future<void> tapMic(WidgetTester tester) async {
  await tester.tap(find.byTooltip('녹음 시작'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('입력이 비면 녹음 버튼, 글자가 있으면 보내기 버튼', (WidgetTester tester) async {
    await startChat(tester, FakeApi(<String, FakeHandler>{}), FakeRecorder());

    expect(find.byTooltip('녹음 시작'), findsOneWidget);
    expect(find.byTooltip('질문 보내기'), findsNothing);
    expect(
      find.text('입력하거나 녹음 버튼을 눌러 말해 보세요. 지난 대화는 세션 목록에서 볼 수 있습니다.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '글자');
    await tester.pump();

    expect(find.byTooltip('녹음 시작'), findsNothing);
    expect(find.byTooltip('질문 보내기'), findsOneWidget);
  });

  testWidgets('녹음 중에는 녹음 막대, 보내면 처리 중, 보정된 질문 뒤 답변', (
    WidgetTester tester,
  ) async {
    final ControlledSse sse = ControlledSse();
    final FakeRecorder recorder = FakeRecorder();
    final FakeApi api = FakeApi(
      <String, FakeHandler>{},
      streams: <String, FakeStreamHandler>{voicePath: sse.handler},
    );
    await startChat(tester, api, recorder);

    await tapMic(tester);
    expect(find.text('녹음 중'), findsOneWidget);
    expect(find.text('0:00 / 2:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 42));
    expect(find.text('0:42 / 2:00'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '취소'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '보내기'));
    await settleIo(tester);
    expect(find.text('음성을 질문으로 바꾸는 중…'), findsOneWidget);
    final TextField input = tester.widget(find.byType(TextField));
    expect(input.enabled, isFalse);
    final IconButton mic = tester.widget(
      find.ancestor(
        of: find.byTooltip('녹음 시작'),
        matching: find.byType(IconButton),
      ),
    );
    expect(mic.onPressed, isNull);

    sse.send('session', <String, Object>{'id': 's1'});
    sse.send('question', <String, Object>{'text': '내일 할 일 정리해 줘'});
    sse.send('delta', <String, Object>{'text': '정리했습니다.'});
    await settleIo(tester);

    expect(find.text('음성을 질문으로 바꾸는 중…'), findsNothing);
    expect(find.text('내일 할 일 정리해 줘'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, '중지'), findsOneWidget);
    expect(api.requestsTo(voicePath), hasLength(1));
  });

  testWidgets('취소하면 보내지 않고 녹음 버튼으로 돌아온다', (WidgetTester tester) async {
    final FakeApi api = FakeApi(<String, FakeHandler>{});
    final FakeRecorder recorder = FakeRecorder();
    await startChat(tester, api, recorder);

    await tapMic(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
    await tester.pump();

    expect(find.text('녹음 중'), findsNothing);
    expect(find.byTooltip('녹음 시작'), findsOneWidget);
    expect(api.requestsTo(voicePath), isEmpty);
    expect(recorder.calls.last, 'cancel');
  });

  testWidgets('2분이 되면 자동으로 보내고 안내한다', (WidgetTester tester) async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      voicePath: (_) => sseReply(<String>[
        sseEvent('session', <String, Object>{'id': 's1'}),
        sseEvent('question', <String, Object>{'text': '긴 질문'}),
        sseEvent('done', <String, Object>{'answerId': 'a1'}),
      ]),
    });
    await startChat(tester, api, FakeRecorder());

    await tapMic(tester);
    await tester.pump(const Duration(minutes: 2));
    await settleIo(tester);

    expect(find.text('녹음 중'), findsNothing);
    expect(api.requestsTo(voicePath), hasLength(1));
    // 안내는 처리 중일 때만(샘플): 보정된 질문이 오면 사라진다.
    expect(find.text('녹음이 2분이 되어 자동으로 끝내고 보냈습니다.'), findsNothing);
    expect(find.text('긴 질문'), findsWidgets);
  });

  testWidgets('인식에 실패하면 안내만 보이고 다시 녹음할 수 있다', (WidgetTester tester) async {
    await startChat(
      tester,
      FakeApi(<String, FakeHandler>{
        voicePath: (_) => errorResponse(
          422,
          'SPEECH_NOT_RECOGNIZED',
          '음성을 인식하지 못했습니다. 다시 녹음해 주세요.',
        ),
      }),
      FakeRecorder(),
    );

    await tapMic(tester);
    await tester.tap(find.widgetWithText(FilledButton, '보내기'));
    await settleIo(tester);

    expect(find.text('음성을 인식하지 못했습니다. 다시 녹음해 주세요.'), findsOneWidget);
    expect(find.text('음성을 질문으로 바꾸는 중…'), findsNothing);
    final IconButton mic = tester.widget(
      find.ancestor(
        of: find.byTooltip('녹음 시작'),
        matching: find.byType(IconButton),
      ),
    );
    expect(mic.onPressed, isNotNull);
  });

  testWidgets('마이크 권한이 없으면 안내와 설정 열기', (WidgetTester tester) async {
    final FakeRecorder recorder = FakeRecorder(
      permission: MicPermission.denied,
    );
    await startChat(tester, FakeApi(<String, FakeHandler>{}), recorder);

    await tapMic(tester);

    expect(find.text('음성 입력을 쓰려면 마이크 권한이 필요합니다.'), findsOneWidget);
    expect(find.text('녹음 중'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, '설정 열기'));
    await tester.pump();
    expect(recorder.calls.last, 'settings');
  });

  testWidgets('녹음 중 백그라운드로 가면 버리고, 돌아오면 안내', (WidgetTester tester) async {
    final FakeApi api = FakeApi(<String, FakeHandler>{});
    final FakeRecorder recorder = FakeRecorder();
    await startChat(tester, api, recorder);
    await tapMic(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('녹음 중'), findsNothing);
    expect(find.text('다른 화면으로 나가서 녹음을 취소했습니다.'), findsOneWidget);
    expect(api.requestsTo(voicePath), isEmpty);
    expect(recorder.calls.last, 'cancel');
  });

  testWidgets('녹음 중에 다른 세션이나 설정을 열면 녹음을 버린다', (WidgetTester tester) async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions': (_) => sessionPage(<String>['지난 세션']),
      '/api/v1/sessions/s0/questions': (_) => questionPage(
        <(String, String, String)>[('옛 질문', '옛 답', 'completed')],
      ),
    });
    final FakeRecorder recorder = FakeRecorder();
    await startChat(tester, api, recorder);

    await tapMic(tester);
    await tester.tap(find.byTooltip('세션 목록 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지난 세션'));
    await settleIo(tester);
    expect(find.text('녹음 중'), findsNothing);
    expect(recorder.calls.last, 'cancel');

    await tapMic(tester);
    await tester.tap(find.byTooltip('세션 목록 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 3));

    expect(recorder.calls.last, 'cancel');
    expect(api.requestsTo(voicePath), isEmpty);
  });

  testWidgets('녹음기가 실패하면 안내한다', (WidgetTester tester) async {
    final FakeRecorder recorder = FakeRecorder()..failStart = true;
    await startChat(tester, FakeApi(<String, FakeHandler>{}), recorder);

    await tapMic(tester);

    expect(find.text('녹음하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('녹음 중'), findsNothing);
  });
}
