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

enum FlashKind { danger, success }

/// 안내 상자. 오류는 빨간 상자, 완료는 초록 상자.
class Flash extends StatelessWidget {
  const Flash({super.key, required this.text, required this.kind});

  final String text;
  final FlashKind kind;

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    final bool danger = kind == FlashKind.danger;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: PrimerSize.stackPaddingCondensed,
          horizontal: PrimerSize.stackPaddingNormal,
        ),
        decoration: BoxDecoration(
          color: danger ? c.bgColorDangerMuted : c.bgColorSuccessMuted,
          border: Border.all(
            color: danger
                ? c.borderColorDangerMuted
                : c.borderColorSuccessMuted,
            width: PrimerSize.borderWidthThin,
          ),
          borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
        ),
        child: _content(context, c, danger),
      ),
    );
  }

  Widget _content(BuildContext context, PrimerColors c, bool danger) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PrimerSize.controlMediumGap,
      children: <Widget>[
        Icon(
          danger ? Icons.error_outline : Icons.check_circle_outline,
          size: PrimerText.textBodySizeLarge,
          color: danger ? c.fgColorDanger : c.fgColorSuccess,
        ),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
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
