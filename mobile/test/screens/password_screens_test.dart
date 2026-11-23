import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/auth/auth_controller.dart';
import 'package:iris/auth/auth_storage.dart';
import 'package:iris/main.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_api.dart';
import '../support/finders.dart';

const AuthStorage storage = AuthStorage();

Future<void> startAs(
  WidgetTester tester,
  FakeApi api, {
  required bool temporary,
}) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  await storage.save(
    StoredAuth(
      accessToken: 'token-1',
      passwordChangeRequired: temporary,
      loginId: 'jhpark',
    ),
  );
  final AuthController controller = AuthController(
    storage: storage,
    baseUrl: 'http://api.test',
    httpClient: api.client,
  );
  await tester.pumpWidget(IrisApp(controller: controller));
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, Map<String, String> fields) async {
  for (final MapEntry<String, String> field in fields.entries) {
    await tester.enterText(fieldFor(field.key), field.value);
  }
}

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.widgetWithText(FilledButton, label));
  await tester.tap(find.widgetWithText(FilledButton, label));
  await tester.pumpAndSettle();
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('설정'));
  await tester.pumpAndSettle();
}

FakeHandler changed(String token) =>
    (_) => jsonResponse(200, <String, String>{'accessToken': token});

void main() {
  group('비밀번호 강제 변경', () {
    testWidgets('확인 값이 다르거나 8자보다 짧으면 보내지 않는다', (WidgetTester tester) async {
      final FakeApi api = FakeApi(<String, FakeHandler>{});
      await startAs(tester, api, temporary: true);

      await fill(tester, <String, String>{
        '새 비밀번호': 'short',
        '새 비밀번호 확인': 'short',
      });
      await tapButton(tester, '변경하고 계속하기');
      expect(find.text('새 비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);

      await fill(tester, <String, String>{
        '새 비밀번호': 'newpass12',
        '새 비밀번호 확인': 'newpass13',
      });
      await tapButton(tester, '변경하고 계속하기');
      expect(find.text('새 비밀번호가 서로 다릅니다.'), findsOneWidget);
      expect(api.requests, isEmpty);
    });

    testWidgets('바꾸면 새 토큰을 저장하고 채팅 자리로 간다', (WidgetTester tester) async {
      final FakeApi api = FakeApi(<String, FakeHandler>{
        '/api/v1/auth/password': changed('token-2'),
      });
      await startAs(tester, api, temporary: true);

      await fill(tester, <String, String>{
        '새 비밀번호': 'newpass12',
        '새 비밀번호 확인': 'newpass12',
      });
      await tapButton(tester, '변경하고 계속하기');

      expect(find.text('채팅 화면은 준비 중입니다.'), findsOneWidget);
      expect(requestJson(api.requests.single), <String, String>{
        'newPassword': 'newpass12',
      });
      final StoredAuth? stored = await storage.load();
      expect(stored?.accessToken, 'token-2');
      expect(stored?.passwordChangeRequired, isFalse);
    });

    testWidgets('백엔드가 거부하면 그 문구를 보여 준다', (WidgetTester tester) async {
      await startAs(
        tester,
        FakeApi(<String, FakeHandler>{
          '/api/v1/auth/password': (_) => errorResponse(
            422,
            'VALIDATION_FAILED',
            '현재 비밀번호와 다른 비밀번호를 입력해 주세요.',
          ),
        }),
        temporary: true,
      );

      await fill(tester, <String, String>{
        '새 비밀번호': 'temppass1',
        '새 비밀번호 확인': 'temppass1',
      });
      await tapButton(tester, '변경하고 계속하기');

      expect(find.text('현재 비밀번호와 다른 비밀번호를 입력해 주세요.'), findsOneWidget);
    });
  });

  testWidgets('연결에 실패하면 서버 오류', (WidgetTester tester) async {
    await startAs(
      tester,
      FakeApi(<String, FakeHandler>{
        '/api/v1/auth/password': (_) => throw Exception('down'),
      }),
      temporary: true,
    );

    await fill(tester, <String, String>{
      '새 비밀번호': 'newpass12',
      '새 비밀번호 확인': 'newpass12',
    });
    await tapButton(tester, '변경하고 계속하기');

    expect(find.text('서버 오류가 발생했습니다.'), findsOneWidget);
  });

  group('설정의 비밀번호 변경', () {
    const Map<String, String> filled = <String, String>{
      '현재 비밀번호': 'oldpass12',
      '새 비밀번호': 'newpass12',
      '새 비밀번호 확인': 'newpass12',
    };

    testWidgets('바꾸면 완료 안내를 보이고 칸을 비운다', (WidgetTester tester) async {
      final FakeApi api = FakeApi(<String, FakeHandler>{
        '/api/v1/auth/password': changed('token-2'),
      });
      await startAs(tester, api, temporary: false);
      await openSettings(tester);

      await fill(tester, filled);
      await tapButton(tester, '비밀번호 변경');

      expect(find.text('비밀번호를 변경했습니다.'), findsOneWidget);
      expect(requestJson(api.requests.single), <String, String>{
        'currentPassword': 'oldpass12',
        'newPassword': 'newpass12',
      });
      expect((await storage.load())?.accessToken, 'token-2');
      final TextField current = tester.widget(fieldFor('현재 비밀번호'));
      expect(current.controller?.text, isEmpty);
    });

    testWidgets('현재 비밀번호가 틀리면 설정 화면의 문구', (WidgetTester tester) async {
      await startAs(
        tester,
        FakeApi(<String, FakeHandler>{
          '/api/v1/auth/password': (_) => errorResponse(
            401,
            'INVALID_CREDENTIALS',
            '아이디 또는 비밀번호가 올바르지 않습니다.',
          ),
        }),
        temporary: false,
      );
      await openSettings(tester);

      await fill(tester, filled);
      await tapButton(tester, '비밀번호 변경');

      expect(find.text('현재 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    });

    testWidgets('차단되면 설정에서 로그인 화면으로 가서 안내를 본다', (WidgetTester tester) async {
      await startAs(
        tester,
        FakeApi(<String, FakeHandler>{
          '/api/v1/auth/password': (_) =>
              errorResponse(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.'),
        }),
        temporary: false,
      );
      await openSettings(tester);

      await fill(tester, filled);
      await tapButton(tester, '비밀번호 변경');

      expect(find.text('차단된 계정입니다. 관리자에게 문의해 주세요.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
      expect(find.text('현재 비밀번호'), findsNothing);
      expect(await storage.load(), isNull);
    });

    testWidgets('토큰이 무효면 로그인 화면에서 다시 로그인 안내', (WidgetTester tester) async {
      await startAs(
        tester,
        FakeApi(<String, FakeHandler>{
          '/api/v1/auth/password': (_) =>
              errorResponse(401, 'UNAUTHORIZED', '다시 로그인해 주세요.'),
        }),
        temporary: false,
      );
      await openSettings(tester);

      await fill(tester, filled);
      await tapButton(tester, '비밀번호 변경');

      expect(find.text('다시 로그인해 주세요.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
      expect(await storage.load(), isNull);
    });
  });
}
