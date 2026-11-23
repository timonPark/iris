/// 요청·응답 모양. `docs/api/openapi.yaml`의 components/schemas와 같다.
library;

/// 관리자 또는 사용자(`Role`).
enum Role { admin, user }

/// `LoginResponse`.
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.role,
    required this.passwordChangeRequired,
  });

  final String accessToken;
  final Role role;

  /// 임시 비밀번호 상태. true면 비밀번호 변경 API 외에는 거부된다.
  final bool passwordChangeRequired;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      role: Role.values.byName(json['role'] as String),
      passwordChangeRequired: json['passwordChangeRequired'] as bool,
    );
  }
}

/// `ErrorResponse`의 `error`. [code]로 분기하고 [message]는 화면에 그대로 보여줄 수 있다.
class ApiError {
  const ApiError({required this.code, required this.message});

  final String code;
  final String message;

  /// 오류 모양이 아니면 null.
  static ApiError? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final Object? error = json['error'];
    if (error is! Map<String, dynamic>) {
      return null;
    }
    final Object? code = error['code'];
    final Object? message = error['message'];
    if (code is! String || message is! String) {
      return null;
    }
    return ApiError(code: code, message: message);
  }
}
