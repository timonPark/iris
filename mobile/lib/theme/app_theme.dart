import 'package:material_ui/material_ui.dart';

import 'primer_tokens.dart';

/// Primer 토큰으로 만든 앱 테마. 화면은 색과 글자를 이 테마나 토큰에서 가져온다.
ThemeData buildAppTheme(Brightness brightness) {
  final PrimerColors c = brightness == Brightness.dark
      ? PrimerColors.dark
      : PrimerColors.light;
  return ThemeData(
    brightness: brightness,
    colorScheme: _colorScheme(brightness, c),
    scaffoldBackgroundColor: c.bgColorDefault,
    textTheme: _textTheme(c.fgColorDefault),
  );
}

ColorScheme _colorScheme(Brightness brightness, PrimerColors c) {
  return ColorScheme(
    brightness: brightness,
    primary: c.bgColorAccentEmphasis,
    onPrimary: c.fgColorOnEmphasis,
    secondary: c.bgColorAccentEmphasis,
    onSecondary: c.fgColorOnEmphasis,
    error: c.bgColorDangerEmphasis,
    onError: c.fgColorOnEmphasis,
    surface: c.bgColorDefault,
    onSurface: c.fgColorDefault,
    onSurfaceVariant: c.fgColorMuted,
    outline: c.borderColorDefault,
    outlineVariant: c.borderColorMuted,
  );
}

/// 글자 토큰 묶음: 크기, 줄 간격, 굵기.
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

TextTheme _textTheme(Color color) {
  TextStyle style(_Text t) => TextStyle(
    fontSize: t.size,
    height: t.height,
    fontWeight: t.weight,
    color: color,
  );
  return TextTheme(
    titleLarge: style(_titleLarge),
    titleMedium: style(_titleMedium),
    titleSmall: style(_titleSmall),
    bodyLarge: style(_bodyLarge),
    bodyMedium: style(_bodyMedium),
    bodySmall: style(_bodySmall),
  );
}
