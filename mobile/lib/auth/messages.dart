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
  static const String serverErrorRetry = '서버 오류가 발생했습니다. 잠시 후 다시 질문해 주세요.';
  static const String questionTooLong = '질문은 65,536자까지 보낼 수 있습니다.';
  static const String disconnected = '연결이 끊겼습니다. 답변은 서버에서 계속 저장됩니다.';
  static const String micPermissionNeeded = '음성 입력을 쓰려면 마이크 권한이 필요합니다.';
  static const String recordingCancelledInBackground =
      '다른 화면으로 나가서 녹음을 취소했습니다.';
  static const String voiceAutoStopped = '녹음이 2분이 되어 자동으로 끝내고 보냈습니다.';
  static const String voiceProcessing = '음성을 질문으로 바꾸는 중…';
  static const String recorderFailed = '녹음하지 못했습니다. 다시 시도해 주세요.';
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

/// 채팅의 오류 문구. 서버 오류와 연결 실패에는 샘플의 "잠시 후 다시 질문해 주세요."를 덧붙인다.
String chatErrorText(ApiError? error) {
  if (error == null || error.code == 'SERVER_ERROR') {
    return Messages.serverErrorRetry;
  }
  return errorText(error);
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
