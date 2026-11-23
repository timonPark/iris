import '../api/api_client.dart';
import '../api/api_models.dart';
import 'messages.dart';

/// 비밀번호 변경. 성공하면 새 토큰을 [onChanged]로 넘기고 null, 실패하면 화면 문구.
/// [currentPassword]는 설정에서 바꿀 때만 보낸다(임시 비밀번호 직후 강제 변경에는 없음).
Future<String?> changePassword({
  required ApiClient client,
  String? currentPassword,
  required String newPassword,
  required String confirm,
  required Future<void> Function(String accessToken) onChanged,
}) async {
  final String? problem = newPasswordProblem(newPassword, confirm);
  if (problem != null) {
    return problem;
  }
  final ApiResult<String> result = await client.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
  switch (result) {
    case ApiOk<String>(:final String value):
      await onChanged(value);
      return null;
    case ApiFailure<String>(:final ApiError? error):
      return _failureText(error, sentCurrent: currentPassword != null);
  }
}

/// 설정에서 현재 비밀번호가 틀리면 규격 문구("아이디 또는 비밀번호가…") 대신 설정에 맞는 문구.
String _failureText(ApiError? error, {required bool sentCurrent}) {
  if (sentCurrent && error?.code == 'INVALID_CREDENTIALS') {
    return Messages.currentPasswordWrong;
  }
  return errorText(error);
}
