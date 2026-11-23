import 'package:material_ui/material_ui.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_storage.dart';
import 'config.dart';
import 'screens/chat_screen.dart';
import 'screens/force_change_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(IrisApp());
}

/// 앱 진입점. 테마는 기기의 라이트·다크 설정을 따르고, 화면은 로그인 상태를 따른다.
class IrisApp extends StatefulWidget {
  IrisApp({super.key, AuthController? controller})
    : controller =
          controller ??
          AuthController(storage: const AuthStorage(), baseUrl: apiBaseUrl);

  final AuthController controller;

  @override
  State<IrisApp> createState() => _IrisAppState();
}

class _IrisAppState extends State<IrisApp> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_closePushedScreens);
    widget.controller.restore();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_closePushedScreens);
    super.dispose();
  }

  /// 설정 같은 위에 연 화면에서 로그인이 풀리면 그 화면을 닫는다.
  void _closePushedScreens() {
    if (widget.controller.screen != AuthScreen.home) {
      _navigator.currentState?.popUntil(
        (Route<dynamic> route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iris',
      navigatorKey: _navigator,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, Widget? _) => _screen(),
      ),
    );
  }

  Widget _screen() {
    final AuthController controller = widget.controller;
    return switch (controller.screen) {
      AuthScreen.loading => const Scaffold(),
      AuthScreen.login => LoginScreen(controller: controller),
      AuthScreen.forceChange => ForceChangeScreen(controller: controller),
      AuthScreen.home => ChatScreen(controller: controller),
    };
  }
}
