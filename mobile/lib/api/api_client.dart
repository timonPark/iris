import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_models.dart';

/// API 호출 결과.
sealed class ApiResult<T> {
  const ApiResult();
}

class ApiOk<T> extends ApiResult<T> {
  const ApiOk(this.value);
  final T value;
}

/// [error]가 null이면 연결 실패이거나 오류 모양이 아닌 응답이다.
class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);
  final ApiError? error;
}

/// 어느 API에서 받든 로그인 상태를 바꿔야 하는 오류.
enum AuthErrorCode {
  unauthorized('UNAUTHORIZED'),
  accountBlocked('ACCOUNT_BLOCKED'),
  passwordChangeRequired('PASSWORD_CHANGE_REQUIRED');

  const AuthErrorCode(this.code);
  final String code;
}

typedef Json = Map<String, dynamic>;

/// `docs/api/openapi.yaml`의 API를 부르는 클라이언트.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.getAccessToken,
    required this.onAuthError,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;

  /// 저장된 accessToken. 없으면 null(로그인 전).
  final String? Function() getAccessToken;

  /// UNAUTHORIZED, ACCOUNT_BLOCKED, PASSWORD_CHANGE_REQUIRED 응답을 받으면 부른다.
  final void Function(AuthErrorCode code) onAuthError;
  final http.Client _http;

  Future<ApiResult<LoginResponse>> login(String loginId, String password) {
    return _post(
      '/api/v1/auth/login',
      <String, String>{'loginId': loginId, 'password': password},
      LoginResponse.fromJson,
      withToken: false,
    );
  }

  /// 성공하면 새 accessToken. 임시 비밀번호 직후에는 [currentPassword]를 보내지 않는다.
  Future<ApiResult<String>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) {
    return _post('/api/v1/auth/password', <String, String>{
      'currentPassword': ?currentPassword,
      'newPassword': newPassword,
    }, (Json json) => json['accessToken'] as String);
  }

  Future<ApiResult<T>> _post<T>(
    String path,
    Json body,
    T Function(Json json) parse, {
    bool withToken = true,
  }) async {
    try {
      final http.Response response = await _http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(withToken ? getAccessToken() : null),
        body: jsonEncode(body),
      );
      final Object? json = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiOk<T>(parse(json as Json));
      }
      return ApiFailure<T>(_failed(response.statusCode, json));
    } on Exception {
      return ApiFailure<T>(null);
    } on TypeError {
      // 성공 응답의 모양이 규격과 다르다.
      return ApiFailure<T>(null);
    }
  }

  /// 로그인은 토큰 없이 부른다(규격 `security: []`).
  Map<String, String> _headers(String? token) {
    return <String, String>{
      'content-type': 'application/json',
      // ngrok 무료 도메인의 안내 페이지를 건너뛴다. localhost에서는 영향이 없다.
      'ngrok-skip-browser-warning': '1',
      'Authorization': ?(token == null ? null : 'Bearer $token'),
    };
  }

  ApiError? _failed(int status, Object? json) {
    final ApiError? error = ApiError.fromJson(json);
    if (error != null && (status == 401 || status == 403)) {
      for (final AuthErrorCode code in AuthErrorCode.values) {
        if (code.code == error.code) onAuthError(code);
      }
    }
    return error;
  }
}
