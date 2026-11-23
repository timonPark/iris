import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 로그인 상태. 기기 보안 저장소에 두어 모바일 앱을 껐다 켜도 유지된다(#19에서 사용자와 정함).
class StoredAuth {
  const StoredAuth({
    required this.accessToken,
    required this.passwordChangeRequired,
    required this.loginId,
  });

  final String accessToken;

  /// 임시 비밀번호 상태. true면 비밀번호 강제 변경 화면만 쓸 수 있다.
  final bool passwordChangeRequired;

  /// 로그인할 때 입력한 아이디. 세션 목록 아래에 보여준다(#25).
  final String loginId;

  StoredAuth copyWith({String? accessToken, bool? passwordChangeRequired}) {
    return StoredAuth(
      accessToken: accessToken ?? this.accessToken,
      passwordChangeRequired:
          passwordChangeRequired ?? this.passwordChangeRequired,
      loginId: loginId,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'accessToken': accessToken,
    'passwordChangeRequired': passwordChangeRequired,
    'loginId': loginId,
  };

  /// 모양이 다르면 null.
  static StoredAuth? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final Object? token = value['accessToken'];
    final Object? required = value['passwordChangeRequired'];
    final Object? loginId = value['loginId'];
    if (token is! String || required is! bool || loginId is! String) {
      return null;
    }
    return StoredAuth(
      accessToken: token,
      passwordChangeRequired: required,
      loginId: loginId,
    );
  }
}

const String authStorageKey = 'iris.auth';

/// 로그인 상태를 iOS Keychain, Android Keystore에 저장한다.
class AuthStorage {
  const AuthStorage([this._store = const FlutterSecureStorage()]);

  final FlutterSecureStorage _store;

  /// 저장한 것이 없거나, 깨졌거나, 키체인·키스토어를 읽지 못하면 null(로그인 전).
  Future<StoredAuth?> load() async {
    try {
      final String? raw = await _store.read(key: authStorageKey);
      return raw == null ? null : StoredAuth.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> save(StoredAuth auth) {
    return _store.write(key: authStorageKey, value: jsonEncode(auth.toJson()));
  }

  Future<void> clear() => _store.delete(key: authStorageKey);
}
