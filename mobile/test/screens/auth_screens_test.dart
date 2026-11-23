import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/auth/auth_controller.dart';
import 'package:iris/auth/auth_storage.dart';
import 'package:iris/main.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_api.dart';
import '../support/finders.dart';

const AuthStorage storage = AuthStorage();

Future<void> startApp(WidgetTester tester, FakeApi api) async {
  final AuthController controller = AuthController(
    storage: storage,
    baseUrl: 'http://api.test',
    httpClient: api.client,
  );
  await tester.pumpWidget(IrisApp(controller: controller));
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String text) async {
  await tester.enterText(fieldFor(label), text);
}

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await enter(tester, '아이디', 'jhpark');
  await enter(tester, '비밀번호', 'pw');
  await tapButton(tester, '로그인');
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  testWidgets('로그인 화면은 샘플(#5)의 문구다', (WidgetTester tester) async {
    await startApp(tester, FakeApi(<String, FakeHandler>{}));

    expect(find.text('Iris'), findsOneWidget);
    expect(fieldFor('아이디'), findsOneWidget);
    expect(fieldFor('비밀번호'), findsOneWidget);
    expect(find.text('계정이 없으면 관리자에게 요청해 주세요.'), findsOneWidget);
  });

  testWidgets('로그인하면 채팅 자리로 가고 토큰을 저장한다', (WidgetTester tester) async {
    await startApp(
      tester,
      FakeApi(<String, FakeHandler>{'/api/v1/auth/login': (_) => loginOk()}),
    );

    await login(tester);

    expect(find.text('채팅 화면은 준비 중입니다.'), findsOneWidget);
    final StoredAuth? stored = await storage.load();
    expect(stored?.accessToken, 'token-1');
    expect(stored?.loginId, 'jhpark');
  });

  testWidgets('임시 비밀번호로 로그인하면 변경 화면이 뜬다', (WidgetTester tester) async {
    await startApp(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/auth/login': (_) => loginOk(passwordChangeRequired: true),
      }),
    );

    await login(tester);

    expect(
      find.text('임시 비밀번호로 로그인했습니다. 계속하려면 새 비밀번호로 바꿔 주세요.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, '변경하고 계속하기'), findsOneWidget);
  });

  testWidgets('차단된 계정은 안내를 보고 토큰을 저장하지 않는다', (WidgetTester tester) async {
    await startApp(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/auth/login': (_) =>
            errorResponse(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.'),
      }),
    );

    await login(tester);

    expect(find.text('차단된 계정입니다. 관리자에게 문의해 주세요.'), findsOneWidget);
    expect(await storage.load(), isNull);
  });

  testWidgets('틀린 비밀번호는 규격 문구, 관리자 계정은 막는다', (WidgetTester tester) async {
    final List<FakeHandler> answers = <FakeHandler>[
      (_) =>
          errorResponse(401, 'INVALID_CREDENTIALS', '아이디 또는 비밀번호가 올바르지 않습니다.'),
      (_) => loginOk(role: 'admin'),
    ];
    await startApp(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/auth/login': (request) => answers.removeAt(0)(request),
      }),
    );

    await login(tester);
    expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);

    await login(tester);
    expect(find.text('관리자 계정은 관리자 웹을 이용해 주세요.'), findsOneWidget);
    expect(await storage.load(), isNull);
  });

  testWidgets('연결에 실패하면 서버 오류', (WidgetTester tester) async {
    await startApp(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/auth/login': (_) => throw Exception('down'),
      }),
    );

    await login(tester);

    expect(find.text('서버 오류가 발생했습니다.'), findsOneWidget);
  });
}
