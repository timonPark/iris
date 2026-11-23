import '../api/api_models.dart';

/// 화면 문구. 오류 문구는 `docs/api/openapi.yaml`의 `message`를 그대로 쓰고,
/// 샘플(#5)과 사용자 웹(#18)에서 정한 안내만 덧붙인다.
abstract final class Messages {
  static const String blocked = '차단된 계정입니다. 관리자에게 문의해 주세요.';
  static const String adminAccount = '관리자 계정은 관리자 웹을 이용해 주세요.';
  static const String unauthorized = '다시 로그인해 주세요.';
  static const String serverError = '서버 오류가 발생했습니다.';
  static const String passwordMismatch = '새 비밀번호가 서로 다릅니다.';
  static const String passwordTooShort = '새 비밀번호는 8자 이상이어야 합니다.';
  static const String currentPasswordWrong = '현재 비밀번호가 올바르지 않습니다.';
  static const String passwordChanged = '비밀번호를 변경했습니다.';
}

const int minPasswordLength = 8;

/// 오류 응답을 화면 문구로. 응답 본문이 없으면(연결 실패 등) 서버 오류.
String errorText(ApiError? error) {
  if (error == null) {
    return Messages.serverError;
  }
  if (error.code == 'ACCOUNT_BLOCKED') {
    return Messages.blocked;
  }
  return error.message;
}

/// 새 비밀번호 확인. 문제가 없으면 null.
String? newPasswordProblem(String newPassword, String confirm) {
  if (newPassword.length < minPasswordLength) {
    return Messages.passwordTooShort;
  }
  if (newPassword != confirm) {
    return Messages.passwordMismatch;
  }
  return null;
}
