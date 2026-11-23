import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../theme/primer_tokens.dart';
import 'settings_screen.dart';

/// 채팅 화면(#25) 전까지 로그인 뒤에 보이는 자리. 설정으로만 갈 수 있다.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key, required this.controller});

  final AuthController controller;

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iris'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('설정'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(PrimerSize.stackPaddingNormal),
        child: Text(
          '채팅 화면은 준비 중입니다.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
