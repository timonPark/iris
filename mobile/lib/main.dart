import 'package:material_ui/material_ui.dart';

import 'theme/app_theme.dart';
import 'theme/primer_tokens.dart';

void main() {
  runApp(const IrisApp());
}

/// 앱 진입점. 테마는 기기의 라이트·다크 설정을 따른다.
class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iris',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _PlaceholderScreen(),
    );
  }
}

/// 화면 구현(#19, #25) 전까지 테마를 확인하는 자리 표시용 화면.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PrimerSize.stackPaddingNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Iris', style: text.titleLarge),
              Text('준비 중입니다.', style: text.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
