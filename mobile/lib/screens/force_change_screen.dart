import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../auth/password_change.dart';
import '../theme/app_theme.dart';
import '../widgets/form_parts.dart';
import 'auth_layout.dart';

/// 임시 비밀번호로 로그인한 직후. 바꾸기 전에는 다른 화면으로 갈 수 없다.
class ForceChangeScreen extends StatefulWidget {
  const ForceChangeScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<ForceChangeScreen> createState() => _ForceChangeScreenState();
}

class _ForceChangeScreenState extends State<ForceChangeScreen> {
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final String? error = await changePassword(
      client: widget.controller.client,
      newPassword: _newPassword.text,
      confirm: _confirm.text,
      onChanged: widget.controller.passwordChanged,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AuthLayout(
      children: <Widget>[
        Text('비밀번호 변경', style: text.titleMedium),
        Text(
          '임시 비밀번호로 로그인했습니다. 계속하려면 새 비밀번호로 바꿔 주세요.',
          style: text.bodyMedium?.copyWith(
            color: primerColorsOf(context).fgColorMuted,
          ),
        ),
        if (_error != null) Flash(text: _error!, kind: FlashKind.danger),
        LabeledField(
          label: '새 비밀번호',
          controller: _newPassword,
          obscure: true,
          hint: '8자 이상',
          autofillHints: const <String>[AutofillHints.newPassword],
        ),
        LabeledField(
          label: '새 비밀번호 확인',
          controller: _confirm,
          obscure: true,
          autofillHints: const <String>[AutofillHints.newPassword],
        ),
        PrimaryButton(label: '변경하고 계속하기', busy: _busy, onPressed: _submit),
      ],
    );
  }
}
