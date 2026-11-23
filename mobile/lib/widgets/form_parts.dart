import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';

/// 샘플(#5)의 입력칸: 굵은 라벨, 큰 입력칸, 필요하면 아래에 힌트.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.hint,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final String? hint;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    final TextTheme text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PrimerSize.controlSmallGap,
        children: <Widget>[
          Text(
            label,
            style: text.bodyMedium?.copyWith(
              fontWeight: PrimerText.baseTextWeightSemibold,
            ),
          ),
          TextField(
            controller: controller,
            obscureText: obscure,
            autofillHints: autofillHints,
            style: text.bodyLarge,
            decoration: _decoration(c),
          ),
          if (hint != null)
            Text(hint!, style: text.bodySmall?.copyWith(color: c.fgColorMuted)),
        ],
      ),
    );
  }

  InputDecoration _decoration(PrimerColors c) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: c.bgColorDefault,
      constraints: const BoxConstraints(minHeight: PrimerSize.controlLargeSize),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: PrimerSize.controlLargePaddingInlineNormal,
        vertical: PrimerSize.controlMediumPaddingBlock,
      ),
      enabledBorder: border(c.borderColorDefault, PrimerSize.borderWidthThin),
      focusedBorder: border(c.focusOutlineColor, PrimerSize.borderWidthThick),
    );
  }
}

enum FlashKind { danger, success, info }

/// 상자의 바탕, 테두리, 아이콘 색과 아이콘.
typedef _FlashLook = ({Color bg, Color border, Color fg, IconData icon});

_FlashLook _look(FlashKind kind, PrimerColors c) {
  return switch (kind) {
    FlashKind.danger => (
      bg: c.bgColorDangerMuted,
      border: c.borderColorDangerMuted,
      fg: c.fgColorDanger,
      icon: Icons.error_outline,
    ),
    FlashKind.success => (
      bg: c.bgColorSuccessMuted,
      border: c.borderColorSuccessMuted,
      fg: c.fgColorSuccess,
      icon: Icons.check_circle_outline,
    ),
    FlashKind.info => (
      bg: c.bgColorAccentMuted,
      border: c.borderColorAccentMuted,
      fg: c.fgColorAccent,
      icon: Icons.info_outline,
    ),
  };
}

/// 안내 상자. 오류는 빨간 상자, 완료는 초록 상자, 알림은 파란 상자.
class Flash extends StatelessWidget {
  const Flash({super.key, required this.text, required this.kind});

  final String text;
  final FlashKind kind;

  @override
  Widget build(BuildContext context) {
    final _FlashLook look = _look(kind, primerColorsOf(context));
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: PrimerSize.stackPaddingCondensed,
          horizontal: PrimerSize.stackPaddingNormal,
        ),
        decoration: BoxDecoration(
          color: look.bg,
          border: Border.all(
            color: look.border,
            width: PrimerSize.borderWidthThin,
          ),
          borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PrimerSize.controlMediumGap,
          children: <Widget>[
            Icon(look.icon, size: PrimerText.textBodySizeLarge, color: look.fg),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// 폭 전체를 쓰는 주 버튼. [busy]면 응답 전에 다시 누를 수 없다.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        // 터치 화면이라 최소 터치 크기(44)로 둔다(샘플 #5의 버튼 규칙).
        minimumSize: const Size.fromHeight(PrimerSize.controlMinTargetCoarse),
        backgroundColor: c.buttonPrimaryBgColorRest,
        foregroundColor: c.buttonPrimaryFgColorRest,
        disabledBackgroundColor: c.buttonPrimaryBgColorDisabled,
        disabledForegroundColor: c.buttonPrimaryFgColorDisabled,
        side: BorderSide(color: c.buttonPrimaryBorderColorRest),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
        ),
        textStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontWeight: PrimerText.baseTextWeightSemibold),
      ),
      child: Text(label),
    );
  }
}

/// Primer 기본 버튼(회색 테두리). 높이는 터치 최소 크기(44).
ButtonStyle defaultButtonStyle(BuildContext context, PrimerColors c) {
  return OutlinedButton.styleFrom(
    minimumSize: const Size(0, PrimerSize.controlMinTargetCoarse),
    padding: const EdgeInsets.symmetric(
      horizontal: PrimerSize.controlMediumPaddingInlineNormal,
    ),
    backgroundColor: c.buttonDefaultBgColorRest,
    foregroundColor: c.buttonDefaultFgColorRest,
    disabledBackgroundColor: c.buttonDefaultBgColorDisabled,
    disabledForegroundColor: c.buttonDefaultFgColorDisabled,
    side: BorderSide(color: c.buttonDefaultBorderColorRest),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
    ),
    textStyle: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: PrimerText.baseTextWeightSemibold),
  );
}

/// Primer 위험 버튼(삭제). 높이는 터치 최소 크기(44).
ButtonStyle dangerButtonStyle(BuildContext context, PrimerColors c) {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, PrimerSize.controlMinTargetCoarse),
    padding: const EdgeInsets.symmetric(
      horizontal: PrimerSize.controlMediumPaddingInlineNormal,
    ),
    backgroundColor: c.buttonDangerBgColorRest,
    foregroundColor: c.buttonDangerFgColorRest,
    side: BorderSide(color: c.buttonDangerBorderColorRest),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
    ),
    textStyle: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: PrimerText.baseTextWeightSemibold),
  );
}

/// Primer 주 버튼(초록). 높이는 터치 최소 크기(44).
ButtonStyle primaryButtonStyle(BuildContext context, PrimerColors c) {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, PrimerSize.controlMinTargetCoarse),
    padding: const EdgeInsets.symmetric(
      horizontal: PrimerSize.controlMediumPaddingInlineNormal,
    ),
    backgroundColor: c.buttonPrimaryBgColorRest,
    foregroundColor: c.buttonPrimaryFgColorRest,
    side: BorderSide(color: c.buttonPrimaryBorderColorRest),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
    ),
    textStyle: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: PrimerText.baseTextWeightSemibold),
  );
}
