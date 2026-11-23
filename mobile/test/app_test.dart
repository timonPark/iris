import 'package:flutter_test/flutter_test.dart';
import 'package:iris/main.dart';
import 'package:iris/theme/primer_tokens.dart';
import 'package:material_ui/material_ui.dart';

Color scaffoldColor(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(Scaffold));
  return Theme.of(context).scaffoldBackgroundColor;
}

void main() {
  testWidgets('기기가 라이트면 라이트 토큰 테마로 앱 이름을 보인다', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const IrisApp());

    expect(find.text('Iris'), findsOneWidget);
    expect(scaffoldColor(tester), PrimerColors.light.bgColorDefault);
  });

  testWidgets('기기가 다크면 다크 토큰 테마다', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const IrisApp());

    expect(scaffoldColor(tester), PrimerColors.dark.bgColorDefault);
  });
}
