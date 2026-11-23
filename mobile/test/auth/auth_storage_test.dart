import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/auth/auth_storage.dart';

/// 키체인·키스토어가 깨져 읽기에 실패하는 저장소.
class _BrokenStore extends FlutterSecureStorage {
  const _BrokenStore();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(code: 'broken');
  }
}

void main() {
  const StoredAuth auth = StoredAuth(
    accessToken: 'token-1',
    passwordChangeRequired: true,
    loginId: 'jhpark',
  );

  test('저장한 로그인 상태를 다시 읽는다', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    const AuthStorage storage = AuthStorage();

    await storage.save(auth);
    final StoredAuth? loaded = await storage.load();

    expect(loaded?.accessToken, 'token-1');
    expect(loaded?.passwordChangeRequired, isTrue);
    expect(loaded?.loginId, 'jhpark');
  });

  test('저장한 것이 없으면 null', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    expect(await const AuthStorage().load(), isNull);
  });

  test('모양이 다르거나 깨진 값이면 null', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      authStorageKey: '{"accessToken": 1}',
    });
    expect(await const AuthStorage().load(), isNull);

    FlutterSecureStorage.setMockInitialValues(<String, String>{
      authStorageKey: 'not json',
    });
    expect(await const AuthStorage().load(), isNull);
  });

  test('지우면 다시 읽을 때 null', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    const AuthStorage storage = AuthStorage();
    await storage.save(auth);

    await storage.clear();

    expect(await storage.load(), isNull);
  });

  test('저장소를 읽지 못하면 로그인 전으로 본다', () async {
    expect(await const AuthStorage(_BrokenStore()).load(), isNull);
  });
}
