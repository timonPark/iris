import 'package:material_ui/material_ui.dart';

import '../api/api_client.dart';
import '../api/api_models.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_storage.dart';
import '../auth/messages.dart';
import '../theme/app_theme.dart';
import '../widgets/form_parts.dart';
import 'auth_layout.dart';

const Map<LoginNotice, String> _noticeText = <LoginNotice, String>{
  LoginNotice.blocked: Messages.blocked,
  LoginNotice.unauthorized: Messages.unauthorized,
};

/// 로그인. 가입 기능은 없다(계정은 관리자만 만든다).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginId = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String loginId = _loginId.text;
    setState(() => _busy = true);
    final ApiResult<LoginResponse> result = await widget.controller.client
        .login(loginId, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = _errorFor(result);
    });
    if (result case ApiOk<LoginResponse>(:final LoginResponse value)
        when value.role == Role.user) {
      await widget.controller.loggedIn(
        StoredAuth(
          accessToken: value.accessToken,
          passwordChangeRequired: value.passwordChangeRequired,
          loginId: loginId,
        ),
      );
    }
  }

  /// 관리자 계정은 모바일 앱에서 받지 않는다(ssot/GLOSSARY.md "사용자 앱").
  static String? _errorFor(ApiResult<LoginResponse> result) {
    return switch (result) {
      ApiOk<LoginResponse>(:final LoginResponse value) =>
        value.role == Role.admin ? Messages.adminAccount : null,
      ApiFailure<LoginResponse>(:final ApiError? error) => errorText(error),
    };
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final LoginNotice? notice = widget.controller.notice;
    final String? flash =
        _error ?? (notice == null ? null : _noticeText[notice]);
    return AuthLayout(
      children: <Widget>[
        // 좁은 화면이라 title-large 대신 title-medium (ssot/PRIMER.md 3번 규칙)
        Text('Iris', textAlign: TextAlign.center, style: text.titleMedium),
        if (flash != null) Flash(text: flash, kind: FlashKind.danger),
        LabeledField(
          label: '아이디',
          controller: _loginId,
          autofillHints: const <String>[AutofillHints.username],
        ),
        LabeledField(
          label: '비밀번호',
          controller: _password,
          obscure: true,
          autofillHints: const <String>[AutofillHints.password],
        ),
        PrimaryButton(label: '로그인', busy: _busy, onPressed: _submit),
        _note(context, text),
      ],
    );
  }

  Widget _note(BuildContext context, TextTheme text) {
    return Text(
      '계정이 없으면 관리자에게 요청해 주세요.',
      textAlign: TextAlign.center,
      style: text.bodySmall?.copyWith(
        color: primerColorsOf(context).fgColorMuted,
      ),
    );
  }
}
