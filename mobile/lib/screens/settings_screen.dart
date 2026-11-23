import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../auth/messages.dart';
import '../auth/password_change.dart';
import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';
import '../widgets/form_parts.dart';

/// 설정. 지금은 비밀번호 변경만 있다. 세션 목록 아래의 "설정"으로 연다(#25 전에는 채팅 자리에서).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(PrimerSize.stackPaddingNormal),
        child: _PasswordPanel(controller: controller),
      ),
    );
  }
}

class _PasswordPanel extends StatefulWidget {
  const _PasswordPanel({required this.controller});

  final AuthController controller;

  @override
  State<_PasswordPanel> createState() => _PasswordPanelState();
}

class _PasswordPanelState extends State<_PasswordPanel> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _error;
  bool _done = false;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _done = false;
    });
    final String? error = await changePassword(
      client: widget.controller.client,
      currentPassword: _current.text,
      newPassword: _newPassword.text,
      confirm: _confirm.text,
      onChanged: widget.controller.passwordChanged,
    );
    if (!mounted) return;
    if (error == null) {
      for (final TextEditingController c in <TextEditingController>[
        _current,
        _newPassword,
        _confirm,
      ]) {
        c.clear();
      }
    }
    setState(() {
      _busy = false;
      _done = error == null;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    return Container(
      padding: const EdgeInsets.all(PrimerSize.stackPaddingNormal),
      decoration: BoxDecoration(
        border: Border.all(
          color: c.borderColorDefault,
          width: PrimerSize.borderWidthThin,
        ),
        borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PrimerSize.stackGapNormal,
        children: _fields(Theme.of(context).textTheme),
      ),
    );
  }

  List<Widget> _fields(TextTheme text) {
    return <Widget>[
      Text('비밀번호 변경', style: text.titleSmall),
      if (_error != null) Flash(text: _error!, kind: FlashKind.danger),
      if (_done)
        const Flash(text: Messages.passwordChanged, kind: FlashKind.success),
      LabeledField(label: '현재 비밀번호', controller: _current, obscure: true),
      LabeledField(
        label: '새 비밀번호',
        controller: _newPassword,
        obscure: true,
        hint: '8자 이상',
      ),
      LabeledField(label: '새 비밀번호 확인', controller: _confirm, obscure: true),
      PrimaryButton(label: '비밀번호 변경', busy: _busy, onPressed: _submit),
    ];
  }
}
