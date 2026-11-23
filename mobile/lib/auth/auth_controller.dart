import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import 'auth_storage.dart';

/// 로그인 상태에 따라 보이는 화면. 채팅 화면은 #25에서 만들고, 그때까지는 채팅 자리(home)다.
enum AuthScreen { loading, login, forceChange, home }

/// 다른 화면에서 로그인 화면으로 보내진 이유.
enum LoginNotice { blocked, unauthorized }

/// 로그인 상태와 화면 전환. 로그인 상태의 기준은 보안 저장소([AuthStorage])다.
class AuthController extends ChangeNotifier {
  AuthController({
    required this._storage,
    required String baseUrl,
    http.Client? httpClient,
  }) {
    client = ApiClient(
      baseUrl: baseUrl,
      httpClient: httpClient,
      getAccessToken: () => _auth?.accessToken,
      onAuthError: handleAuthError,
    );
  }

  final AuthStorage _storage;
  late final ApiClient client;
  StoredAuth? _auth;
  AuthScreen screen = AuthScreen.loading;
  LoginNotice? notice;

  /// 로그인한 아이디(세션 목록 아래에 보여준다).
  String get loginId => _auth?.loginId ?? '';

  /// 모바일 앱을 열 때 저장한 로그인 상태를 읽는다.
  Future<void> restore() async {
    _auth = await _storage.load();
    _show(_screenFor(_auth));
  }

  Future<void> loggedIn(StoredAuth auth) async {
    await _keep(auth);
    notice = null;
    _show(_screenFor(auth));
  }

  Future<void> passwordChanged(String accessToken) async {
    final StoredAuth? auth = _auth;
    if (auth != null) {
      await _keep(
        auth.copyWith(accessToken: accessToken, passwordChangeRequired: false),
      );
    }
    if (screen == AuthScreen.forceChange) _show(AuthScreen.home);
  }

  /// 차단·토큰 무효면 토큰을 지우고 로그인 화면, 임시 비밀번호 상태면 강제 변경 화면.
  Future<void> handleAuthError(AuthErrorCode code) async {
    final StoredAuth? auth = _auth;
    if (code == AuthErrorCode.passwordChangeRequired && auth != null) {
      _auth = auth.copyWith(passwordChangeRequired: true);
      _show(AuthScreen.forceChange);
      await _storage.save(_auth!);
      return;
    }
    // 화면을 먼저 바꾸고 저장소를 지운다.
    _auth = null;
    notice = code == AuthErrorCode.accountBlocked
        ? LoginNotice.blocked
        : LoginNotice.unauthorized;
    _show(AuthScreen.login);
    await _storage.clear();
  }

  Future<void> _keep(StoredAuth auth) async {
    _auth = auth;
    await _storage.save(auth);
  }

  void _show(AuthScreen next) {
    screen = next;
    notifyListeners();
  }

  static AuthScreen _screenFor(StoredAuth? auth) {
    if (auth == null) return AuthScreen.login;
    return auth.passwordChangeRequired
        ? AuthScreen.forceChange
        : AuthScreen.home;
  }
}
