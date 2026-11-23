import 'package:flutter_test/flutter_test.dart';
import 'package:iris/theme/app_theme.dart';
import 'package:iris/theme/primer_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// 기본 배경·글자, 강조 배경 위 글자(fgColorOnEmphasis), 테두리 짝.
void _expectColorScheme(
  ThemeData theme,
  Brightness brightness,
  PrimerColors c,
) {
  final ColorScheme s = theme.colorScheme;
  expect(theme.brightness, brightness);
  expect(theme.scaffoldBackgroundColor, c.bgColorDefault);
  expect(
    <Color>[s.surface, s.onSurface, s.onSurfaceVariant],
    <Color>[c.bgColorDefault, c.fgColorDefault, c.fgColorMuted],
  );
  expect(
    <Color>[s.primary, s.onPrimary, s.secondary, s.onSecondary],
    <Color>[
      c.bgColorAccentEmphasis,
      c.fgColorOnEmphasis,
      c.bgColorAccentEmphasis,
      c.fgColorOnEmphasis,
    ],
  );
  expect(
    <Color>[s.error, s.onError],
    <Color>[c.bgColorDangerEmphasis, c.fgColorOnEmphasis],
  );
  expect(
    <Color>[s.outline, s.outlineVariant],
    <Color>[c.borderColorDefault, c.borderColorMuted],
  );
}

typedef _Text = ({double size, double height, FontWeight weight});

const _Text _titleLarge = (
  size: PrimerText.textTitleSizeLarge,
  height: PrimerText.textTitleLineHeightLarge,
  weight: PrimerText.textTitleWeightLarge,
);
const _Text _titleMedium = (
  size: PrimerText.textTitleSizeMedium,
  height: PrimerText.textTitleLineHeightMedium,
  weight: PrimerText.textTitleWeightMedium,
);
const _Text _titleSmall = (
  size: PrimerText.textTitleSizeSmall,
  height: PrimerText.textTitleLineHeightSmall,
  weight: PrimerText.textTitleWeightSmall,
);
const _Text _bodyLarge = (
  size: PrimerText.textBodySizeLarge,
  height: PrimerText.textBodyLineHeightLarge,
  weight: PrimerText.textBodyWeight,
);
const _Text _bodyMedium = (
  size: PrimerText.textBodySizeMedium,
  height: PrimerText.textBodyLineHeightMedium,
  weight: PrimerText.textBodyWeight,
);
const _Text _bodySmall = (
  size: PrimerText.textBodySizeSmall,
  height: PrimerText.textBodyLineHeightSmall,
  weight: PrimerText.textBodyWeight,
);

void _expectStyle(TextStyle? style, _Text token, Color color) {
  expect(style?.fontSize, token.size);
  expect(style?.height, token.height);
  expect(style?.fontWeight, token.weight);
  expect(style?.color, color);
}

/// Primer 제목·본문 토큰의 크기, 줄 간격, 굵기.
void _expectTextTheme(TextTheme t, Color color) {
  _expectStyle(t.titleLarge, _titleLarge, color);
  _expectStyle(t.titleMedium, _titleMedium, color);
  _expectStyle(t.titleSmall, _titleSmall, color);
  _expectStyle(t.bodyLarge, _bodyLarge, color);
  _expectStyle(t.bodyMedium, _bodyMedium, color);
  _expectStyle(t.bodySmall, _bodySmall, color);
}

void main() {
  for (final (Brightness brightness, PrimerColors c)
      in <(Brightness, PrimerColors)>[
        (Brightness.light, PrimerColors.light),
        (Brightness.dark, PrimerColors.dark),
      ]) {
    final ThemeData theme = buildAppTheme(brightness);
    test(
      '$brightness 색은 Primer 짝 규칙대로다',
      () => _expectColorScheme(theme, brightness, c),
    );
    test(
      '$brightness 글자는 Primer 토큰이다',
      () => _expectTextTheme(theme.textTheme, c.fgColorDefault),
    );
  }
}
