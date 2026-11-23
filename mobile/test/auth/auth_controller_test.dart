import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/api/api_client.dart';
import 'package:iris/auth/auth_controller.dart';
import 'package:iris/auth/auth_storage.dart';

import '../support/fake_api.dart';

const AuthStorage storage = AuthStorage();

AuthController controllerWith(FakeApi api) {
  return AuthController(
    storage: storage,
    baseUrl: 'http://api.test',
    httpClient: api.client,
  );
}

Future<void> saved(StoredAuth auth) async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  await storage.save(auth);
}

const StoredAuth user = StoredAuth(
  accessToken: 'token-1',
  passwordChangeRequired: false,
  loginId: 'jhpark',
);

void main() {
  final FakeApi noApi = FakeApi(<String, FakeHandler>{});

  test('저장한 것이 없으면 로그인 화면', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final AuthController controller = controllerWith(noApi);
    expect(controller.screen, AuthScreen.loading);

    await controller.restore();

    expect(controller.screen, AuthScreen.login);
  });

  test('저장한 로그인 상태가 있으면 바로 채팅 자리, 임시 비밀번호면 강제 변경', () async {
    await saved(user);
    final AuthController a = controllerWith(noApi);
    await a.restore();
    expect(a.screen, AuthScreen.home);
    expect(a.loginId, 'jhpark');

    await saved(
      const StoredAuth(
        accessToken: 't',
        passwordChangeRequired: true,
        loginId: 'temp',
      ),
    );
    final AuthController b = controllerWith(noApi);
    await b.restore();
    expect(b.screen, AuthScreen.forceChange);
  });

  test('비밀번호를 바꾸면 새 토큰을 저장하고 채팅 자리로', () async {
    await saved(
      const StoredAuth(
        accessToken: 'old',
        passwordChangeRequired: true,
        loginId: 'temp',
      ),
    );
    final AuthController controller = controllerWith(noApi);
    await controller.restore();

    await controller.passwordChanged('new');

    expect(controller.screen, AuthScreen.home);
    final StoredAuth? stored = await storage.load();
    expect(stored?.accessToken, 'new');
    expect(stored?.passwordChangeRequired, isFalse);
  });

  test('차단되면 토큰을 지우고 로그인 화면에 차단 안내', () async {
    await saved(user);
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/auth/password': (_) =>
          errorResponse(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.'),
    });
    final AuthController controller = controllerWith(api);
    await controller.restore();

    await controller.client.changePassword(
      currentPassword: 'a',
      newPassword: 'newpass12',
    );
    await pumpEventQueue();

    expect(controller.screen, AuthScreen.login);
    expect(controller.notice, LoginNotice.blocked);
    expect(await storage.load(), isNull);
    expect(api.requests.single.headers['Authorization'], 'Bearer token-1');
  });

  test('토큰이 무효면 다시 로그인 안내, 비밀번호 변경 필요면 강제 변경 화면', () async {
    await saved(user);
    final AuthController controller = controllerWith(noApi);
    await controller.restore();

    await controller.handleAuthError(AuthErrorCode.passwordChangeRequired);
    expect(controller.screen, AuthScreen.forceChange);
    expect((await storage.load())?.passwordChangeRequired, isTrue);

    await controller.handleAuthError(AuthErrorCode.unauthorized);
    expect(controller.screen, AuthScreen.login);
    expect(controller.notice, LoginNotice.unauthorized);
    expect(await storage.load(), isNull);
  });

  test('로그인하면 저장하고 안내를 지운다', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final AuthController controller = controllerWith(noApi);
    await controller.restore();
    await controller.handleAuthError(AuthErrorCode.accountBlocked);

    await controller.loggedIn(user);

    expect(controller.screen, AuthScreen.home);
    expect(controller.notice, isNull);
    expect((await storage.load())?.accessToken, 'token-1');
  });
}
