import 'package:material_ui/material_ui.dart';

import '../theme/primer_tokens.dart';

/// 로그인과 비밀번호 강제 변경의 틀: 가운데 정렬, 화면이 낮으면 스크롤.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: PrimerSize.stackPaddingSpacious,
              horizontal: PrimerSize.stackPaddingNormal,
            ),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: PrimerSize.stackGapNormal,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
