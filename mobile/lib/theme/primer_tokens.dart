// 생성 파일입니다. 직접 고치지 마세요.
// mobile/tool/primer_tokens에서 `npm run generate`로 만듭니다.
// 원본: @primer/primitives 11.10.0의 CSS 변수 (웹과 같은 값, ssot/PRIMER.md)

import 'dart:ui' show Color, FontWeight;

/// Primer 색 토큰. 라이트와 다크에서 이름이 같고 값만 다르다.
final class PrimerColors {
  const PrimerColors._({
    required this.ansiBlack,
    required this.ansiBlackBright,
    required this.ansiBlue,
    required this.ansiBlueBright,
    required this.ansiCyan,
    required this.ansiCyanBright,
    required this.ansiGray,
    required this.ansiGreen,
    required this.ansiGreenBright,
    required this.ansiMagenta,
    required this.ansiMagentaBright,
    required this.ansiRed,
    required this.ansiRedBright,
    required this.ansiWhite,
    required this.ansiWhiteBright,
    required this.ansiYellow,
    required this.ansiYellowBright,
    required this.avatarBgColor,
    required this.avatarBorderColor,
    required this.avatarStackFadeBgColorDefault,
    required this.avatarStackFadeBgColorMuted,
    required this.bgColorAccentEmphasis,
    required this.bgColorAccentMuted,
    required this.bgColorAttentionEmphasis,
    required this.bgColorAttentionMuted,
    required this.bgColorBlack,
    required this.bgColorClosedEmphasis,
    required this.bgColorClosedMuted,
    required this.bgColorDangerEmphasis,
    required this.bgColorDangerMuted,
    required this.bgColorDefault,
    required this.bgColorDisabled,
    required this.bgColorDoneEmphasis,
    required this.bgColorDoneMuted,
    required this.bgColorDraftEmphasis,
    required this.bgColorDraftMuted,
    required this.bgColorEmphasis,
    required this.bgColorInset,
    required this.bgColorInverse,
    required this.bgColorMuted,
    required this.bgColorNeutralEmphasis,
    required this.bgColorNeutralMuted,
    required this.bgColorOpenEmphasis,
    required this.bgColorOpenMuted,
    required this.bgColorSevereEmphasis,
    required this.bgColorSevereMuted,
    required this.bgColorSponsorsEmphasis,
    required this.bgColorSponsorsMuted,
    required this.bgColorSuccessEmphasis,
    required this.bgColorSuccessMuted,
    required this.bgColorTransparent,
    required this.bgColorUpsellEmphasis,
    required this.bgColorUpsellMuted,
    required this.bgColorWhite,
    required this.borderColorAccentEmphasis,
    required this.borderColorAccentMuted,
    required this.borderColorAttentionEmphasis,
    required this.borderColorAttentionMuted,
    required this.borderColorClosedEmphasis,
    required this.borderColorClosedMuted,
    required this.borderColorDangerEmphasis,
    required this.borderColorDangerMuted,
    required this.borderColorDefault,
    required this.borderColorDisabled,
    required this.borderColorDoneEmphasis,
    required this.borderColorDoneMuted,
    required this.borderColorDraftEmphasis,
    required this.borderColorDraftMuted,
    required this.borderColorEmphasis,
    required this.borderColorMuted,
    required this.borderColorNeutralEmphasis,
    required this.borderColorNeutralMuted,
    required this.borderColorOpenEmphasis,
    required this.borderColorOpenMuted,
    required this.borderColorSevereEmphasis,
    required this.borderColorSevereMuted,
    required this.borderColorSponsorsEmphasis,
    required this.borderColorSponsorsMuted,
    required this.borderColorSuccessEmphasis,
    required this.borderColorSuccessMuted,
    required this.borderColorTranslucent,
    required this.borderColorTransparent,
    required this.borderColorUpsellEmphasis,
    required this.borderColorUpsellMuted,
    required this.buttonDangerBgColorActive,
    required this.buttonDangerBgColorDisabled,
    required this.buttonDangerBgColorHover,
    required this.buttonDangerBgColorRest,
    required this.buttonDangerBorderColorActive,
    required this.buttonDangerBorderColorHover,
    required this.buttonDangerBorderColorRest,
    required this.buttonDangerFgColorActive,
    required this.buttonDangerFgColorDisabled,
    required this.buttonDangerFgColorHover,
    required this.buttonDangerFgColorRest,
    required this.buttonDangerIconColorDisabled,
    required this.buttonDangerIconColorHover,
    required this.buttonDangerIconColorRest,
    required this.buttonDefaultBgColorActive,
    required this.buttonDefaultBgColorDisabled,
    required this.buttonDefaultBgColorHover,
    required this.buttonDefaultBgColorRest,
    required this.buttonDefaultBgColorSelected,
    required this.buttonDefaultBorderColorActive,
    required this.buttonDefaultBorderColorDisabled,
    required this.buttonDefaultBorderColorHover,
    required this.buttonDefaultBorderColorRest,
    required this.buttonDefaultFgColorDisabled,
    required this.buttonDefaultFgColorRest,
    required this.buttonInactiveBgColor,
    required this.buttonInactiveFgColor,
    required this.buttonInvisibleBgColorActive,
    required this.buttonInvisibleBgColorDisabled,
    required this.buttonInvisibleBgColorHover,
    required this.buttonInvisibleBgColorRest,
    required this.buttonInvisibleBorderColorDisabled,
    required this.buttonInvisibleBorderColorHover,
    required this.buttonInvisibleBorderColorRest,
    required this.buttonInvisibleFgColorActive,
    required this.buttonInvisibleFgColorDisabled,
    required this.buttonInvisibleFgColorHover,
    required this.buttonInvisibleFgColorRest,
    required this.buttonInvisibleIconColorDisabled,
    required this.buttonInvisibleIconColorHover,
    required this.buttonInvisibleIconColorRest,
    required this.buttonOutlineBgColorActive,
    required this.buttonOutlineBgColorDisabled,
    required this.buttonOutlineBgColorHover,
    required this.buttonOutlineBgColorRest,
    required this.buttonOutlineBorderColorActive,
    required this.buttonOutlineBorderColorHover,
    required this.buttonOutlineFgColorActive,
    required this.buttonOutlineFgColorDisabled,
    required this.buttonOutlineFgColorHover,
    required this.buttonOutlineFgColorRest,
    required this.buttonPrimaryBgColorActive,
    required this.buttonPrimaryBgColorDisabled,
    required this.buttonPrimaryBgColorHover,
    required this.buttonPrimaryBgColorRest,
    required this.buttonPrimaryBorderColorActive,
    required this.buttonPrimaryBorderColorDisabled,
    required this.buttonPrimaryBorderColorHover,
    required this.buttonPrimaryBorderColorRest,
    required this.buttonPrimaryFgColorDisabled,
    required this.buttonPrimaryFgColorRest,
    required this.buttonPrimaryIconColorDisabled,
    required this.buttonPrimaryIconColorRest,
    required this.buttonStarIconColor,
    required this.buttonCounterDangerBgColorDisabled,
    required this.buttonCounterDangerBgColorHover,
    required this.buttonCounterDangerBgColorRest,
    required this.buttonCounterDangerFgColorDisabled,
    required this.buttonCounterDangerFgColorHover,
    required this.buttonCounterDangerFgColorRest,
    required this.buttonCounterDefaultBgColorRest,
    required this.buttonCounterInvisibleBgColorRest,
    required this.buttonCounterOutlineBgColorDisabled,
    required this.buttonCounterOutlineBgColorHover,
    required this.buttonCounterOutlineBgColorRest,
    required this.buttonCounterOutlineFgColorDisabled,
    required this.buttonCounterOutlineFgColorHover,
    required this.buttonCounterOutlineFgColorRest,
    required this.buttonCounterPrimaryBgColorRest,
    required this.buttonKeybindingHintDangerBgColorActive,
    required this.buttonKeybindingHintDangerBgColorDisabled,
    required this.buttonKeybindingHintDangerBgColorHover,
    required this.buttonKeybindingHintDangerBgColorRest,
    required this.buttonKeybindingHintDangerBorderColorActive,
    required this.buttonKeybindingHintDangerBorderColorDisabled,
    required this.buttonKeybindingHintDangerBorderColorHover,
    required this.buttonKeybindingHintDangerBorderColorRest,
    required this.buttonKeybindingHintDangerFgColorActive,
    required this.buttonKeybindingHintDangerFgColorDisabled,
    required this.buttonKeybindingHintDangerFgColorHover,
    required this.buttonKeybindingHintDangerFgColorRest,
    required this.buttonKeybindingHintDefaultBgColorDisabled,
    required this.buttonKeybindingHintDefaultBgColorRest,
    required this.buttonKeybindingHintDefaultBorderColorDisabled,
    required this.buttonKeybindingHintDefaultBorderColorRest,
    required this.buttonKeybindingHintDefaultFgColorDisabled,
    required this.buttonKeybindingHintDefaultFgColorRest,
    required this.buttonKeybindingHintInactiveBgColor,
    required this.buttonKeybindingHintInactiveBorderColor,
    required this.buttonKeybindingHintInactiveFgColor,
    required this.buttonKeybindingHintInvisibleBgColorActive,
    required this.buttonKeybindingHintInvisibleBgColorDisabled,
    required this.buttonKeybindingHintInvisibleBgColorHover,
    required this.buttonKeybindingHintInvisibleBgColorRest,
    required this.buttonKeybindingHintInvisibleBorderColorDisabled,
    required this.buttonKeybindingHintInvisibleBorderColorRest,
    required this.buttonKeybindingHintInvisibleFgColorDisabled,
    required this.buttonKeybindingHintInvisibleFgColorRest,
    required this.buttonKeybindingHintPrimaryBgColorDisabled,
    required this.buttonKeybindingHintPrimaryBgColorRest,
    required this.buttonKeybindingHintPrimaryBorderColorDisabled,
    required this.buttonKeybindingHintPrimaryBorderColorRest,
    required this.buttonKeybindingHintPrimaryFgColorDisabled,
    required this.buttonKeybindingHintPrimaryFgColorRest,
    required this.cardBgColor,
    required this.codeMirrorActivelineBgColor,
    required this.codeMirrorBgColor,
    required this.codeMirrorCursorFgColor,
    required this.codeMirrorFgColor,
    required this.codeMirrorGutterMarkerFgColorDefault,
    required this.codeMirrorGutterMarkerFgColorMuted,
    required this.codeMirrorGuttersBgColor,
    required this.codeMirrorLineNumberFgColor,
    required this.codeMirrorLinesBgColor,
    required this.codeMirrorMatchingBracketFgColor,
    required this.codeMirrorSelectionBgColor,
    required this.codeMirrorSyntaxFgColorComment,
    required this.codeMirrorSyntaxFgColorConstant,
    required this.codeMirrorSyntaxFgColorEntity,
    required this.codeMirrorSyntaxFgColorKeyword,
    required this.codeMirrorSyntaxFgColorStorage,
    required this.codeMirrorSyntaxFgColorString,
    required this.codeMirrorSyntaxFgColorSupport,
    required this.codeMirrorSyntaxFgColorVariable,
    required this.colorAnsiBlack,
    required this.colorAnsiBlackBright,
    required this.colorAnsiBlue,
    required this.colorAnsiBlueBright,
    required this.colorAnsiCyan,
    required this.colorAnsiCyanBright,
    required this.colorAnsiGray,
    required this.colorAnsiGreen,
    required this.colorAnsiGreenBright,
    required this.colorAnsiMagenta,
    required this.colorAnsiMagentaBright,
    required this.colorAnsiRed,
    required this.colorAnsiRedBright,
    required this.colorAnsiWhite,
    required this.colorAnsiWhiteBright,
    required this.colorAnsiYellow,
    required this.colorAnsiYellowBright,
    required this.colorPrettylightsSyntaxBrackethighlighterAngle,
    required this.colorPrettylightsSyntaxBrackethighlighterUnmatched,
    required this.colorPrettylightsSyntaxCarriageReturnBg,
    required this.colorPrettylightsSyntaxCarriageReturnText,
    required this.colorPrettylightsSyntaxComment,
    required this.colorPrettylightsSyntaxConstant,
    required this.colorPrettylightsSyntaxConstantOtherReferenceLink,
    required this.colorPrettylightsSyntaxEntity,
    required this.colorPrettylightsSyntaxEntityTag,
    required this.colorPrettylightsSyntaxInvalidIllegalBg,
    required this.colorPrettylightsSyntaxInvalidIllegalText,
    required this.colorPrettylightsSyntaxKeyword,
    required this.colorPrettylightsSyntaxMarkupBold,
    required this.colorPrettylightsSyntaxMarkupChangedBg,
    required this.colorPrettylightsSyntaxMarkupChangedText,
    required this.colorPrettylightsSyntaxMarkupDeletedBg,
    required this.colorPrettylightsSyntaxMarkupDeletedText,
    required this.colorPrettylightsSyntaxMarkupHeading,
    required this.colorPrettylightsSyntaxMarkupIgnoredBg,
    required this.colorPrettylightsSyntaxMarkupIgnoredText,
    required this.colorPrettylightsSyntaxMarkupInsertedBg,
    required this.colorPrettylightsSyntaxMarkupInsertedText,
    required this.colorPrettylightsSyntaxMarkupItalic,
    required this.colorPrettylightsSyntaxMarkupList,
    required this.colorPrettylightsSyntaxMetaDiffRange,
    required this.colorPrettylightsSyntaxStorageModifierImport,
    required this.colorPrettylightsSyntaxString,
    required this.colorPrettylightsSyntaxStringRegexp,
    required this.colorPrettylightsSyntaxSublimelinterGutterMark,
    required this.colorPrettylightsSyntaxVariable,
    required this.contributionDefaultBgColor0,
    required this.contributionDefaultBgColor1,
    required this.contributionDefaultBgColor2,
    required this.contributionDefaultBgColor3,
    required this.contributionDefaultBgColor4,
    required this.contributionDefaultBorderColor0,
    required this.contributionDefaultBorderColor1,
    required this.contributionDefaultBorderColor2,
    required this.contributionDefaultBorderColor3,
    required this.contributionDefaultBorderColor4,
    required this.contributionHalloweenBgColor1,
    required this.contributionHalloweenBgColor2,
    required this.contributionHalloweenBgColor3,
    required this.contributionHalloweenBgColor4,
    required this.contributionWinterBgColor1,
    required this.contributionWinterBgColor2,
    required this.contributionWinterBgColor3,
    required this.contributionWinterBgColor4,
    required this.controlBgColorActive,
    required this.controlBgColorDisabled,
    required this.controlBgColorHover,
    required this.controlBgColorRest,
    required this.controlBgColorSelected,
    required this.controlBorderColorDanger,
    required this.controlBorderColorDisabled,
    required this.controlBorderColorEmphasis,
    required this.controlBorderColorRest,
    required this.controlBorderColorSelected,
    required this.controlBorderColorSuccess,
    required this.controlBorderColorWarning,
    required this.controlCheckedBgColorActive,
    required this.controlCheckedBgColorDisabled,
    required this.controlCheckedBgColorHover,
    required this.controlCheckedBgColorRest,
    required this.controlCheckedBorderColorActive,
    required this.controlCheckedBorderColorDisabled,
    required this.controlCheckedBorderColorHover,
    required this.controlCheckedBorderColorRest,
    required this.controlCheckedFgColorDisabled,
    required this.controlCheckedFgColorRest,
    required this.controlDangerBgColorActive,
    required this.controlDangerBgColorHover,
    required this.controlDangerFgColorHover,
    required this.controlDangerFgColorRest,
    required this.controlFgColorDisabled,
    required this.controlFgColorPlaceholder,
    required this.controlFgColorRest,
    required this.controlIconColorRest,
    required this.controlTransparentBgColorActive,
    required this.controlTransparentBgColorDisabled,
    required this.controlTransparentBgColorHover,
    required this.controlTransparentBgColorRest,
    required this.controlTransparentBgColorSelected,
    required this.controlTransparentBorderColorActive,
    required this.controlTransparentBorderColorHover,
    required this.controlTransparentBorderColorRest,
    required this.controlKnobBgColorChecked,
    required this.controlKnobBgColorDisabled,
    required this.controlKnobBgColorRest,
    required this.controlKnobBorderColorChecked,
    required this.controlKnobBorderColorDisabled,
    required this.controlKnobBorderColorRest,
    required this.controlTrackBgColorActive,
    required this.controlTrackBgColorDisabled,
    required this.controlTrackBgColorHover,
    required this.controlTrackBgColorRest,
    required this.controlTrackBorderColorDisabled,
    required this.controlTrackBorderColorRest,
    required this.controlTrackFgColorDisabled,
    required this.controlTrackFgColorRest,
    required this.counterBgColorEmphasis,
    required this.counterBgColorMuted,
    required this.counterBorderColor,
    required this.dashboardBgColor,
    required this.dataAuburnColorEmphasis,
    required this.dataAuburnColorMuted,
    required this.dataBlueColorEmphasis,
    required this.dataBlueColorMuted,
    required this.dataBrownColorEmphasis,
    required this.dataBrownColorMuted,
    required this.dataCoralColorEmphasis,
    required this.dataCoralColorMuted,
    required this.dataGrayColorEmphasis,
    required this.dataGrayColorMuted,
    required this.dataGreenColorEmphasis,
    required this.dataGreenColorMuted,
    required this.dataLemonColorEmphasis,
    required this.dataLemonColorMuted,
    required this.dataLimeColorEmphasis,
    required this.dataLimeColorMuted,
    required this.dataOliveColorEmphasis,
    required this.dataOliveColorMuted,
    required this.dataOrangeColorEmphasis,
    required this.dataOrangeColorMuted,
    required this.dataPineColorEmphasis,
    required this.dataPineColorMuted,
    required this.dataPinkColorEmphasis,
    required this.dataPinkColorMuted,
    required this.dataPlumColorEmphasis,
    required this.dataPlumColorMuted,
    required this.dataPurpleColorEmphasis,
    required this.dataPurpleColorMuted,
    required this.dataRedColorEmphasis,
    required this.dataRedColorMuted,
    required this.dataTealColorEmphasis,
    required this.dataTealColorMuted,
    required this.dataYellowColorEmphasis,
    required this.dataYellowColorMuted,
    required this.diffBlobAdditionLineBgColor,
    required this.diffBlobAdditionLineFgColor,
    required this.diffBlobAdditionNumBgColor,
    required this.diffBlobAdditionNumFgColor,
    required this.diffBlobAdditionWordBgColor,
    required this.diffBlobAdditionWordFgColor,
    required this.diffBlobDeletionLineBgColor,
    required this.diffBlobDeletionLineFgColor,
    required this.diffBlobDeletionNumBgColor,
    required this.diffBlobDeletionNumFgColor,
    required this.diffBlobDeletionWordBgColor,
    required this.diffBlobDeletionWordFgColor,
    required this.diffBlobEmptyLineBgColor,
    required this.diffBlobEmptyNumBgColor,
    required this.diffBlobExpanderIconColor,
    required this.diffBlobHunkLineBgColor,
    required this.diffBlobHunkLineFgColor,
    required this.diffBlobHunkNumBgColorHover,
    required this.diffBlobHunkNumBgColorRest,
    required this.diffBlobHunkNumFgColorHover,
    required this.diffBlobHunkNumFgColorRest,
    required this.displayAuburnBgColorEmphasis,
    required this.displayAuburnBgColorMuted,
    required this.displayAuburnBorderColorEmphasis,
    required this.displayAuburnBorderColorMuted,
    required this.displayAuburnFgColor,
    required this.displayAuburnScale0,
    required this.displayAuburnScale1,
    required this.displayAuburnScale2,
    required this.displayAuburnScale3,
    required this.displayAuburnScale4,
    required this.displayAuburnScale5,
    required this.displayAuburnScale6,
    required this.displayAuburnScale7,
    required this.displayAuburnScale8,
    required this.displayAuburnScale9,
    required this.displayBlueBgColorEmphasis,
    required this.displayBlueBgColorMuted,
    required this.displayBlueBorderColorEmphasis,
    required this.displayBlueBorderColorMuted,
    required this.displayBlueFgColor,
    required this.displayBlueScale0,
    required this.displayBlueScale1,
    required this.displayBlueScale2,
    required this.displayBlueScale3,
    required this.displayBlueScale4,
    required this.displayBlueScale5,
    required this.displayBlueScale6,
    required this.displayBlueScale7,
    required this.displayBlueScale8,
    required this.displayBlueScale9,
    required this.displayBrownBgColorEmphasis,
    required this.displayBrownBgColorMuted,
    required this.displayBrownBorderColorEmphasis,
    required this.displayBrownBorderColorMuted,
    required this.displayBrownFgColor,
    required this.displayBrownScale0,
    required this.displayBrownScale1,
    required this.displayBrownScale2,
    required this.displayBrownScale3,
    required this.displayBrownScale4,
    required this.displayBrownScale5,
    required this.displayBrownScale6,
    required this.displayBrownScale7,
    required this.displayBrownScale8,
    required this.displayBrownScale9,
    required this.displayCoralBgColorEmphasis,
    required this.displayCoralBgColorMuted,
    required this.displayCoralBorderColorEmphasis,
    required this.displayCoralBorderColorMuted,
    required this.displayCoralFgColor,
    required this.displayCoralScale0,
    required this.displayCoralScale1,
    required this.displayCoralScale2,
    required this.displayCoralScale3,
    required this.displayCoralScale4,
    required this.displayCoralScale5,
    required this.displayCoralScale6,
    required this.displayCoralScale7,
    required this.displayCoralScale8,
    required this.displayCoralScale9,
    required this.displayCyanBgColorEmphasis,
    required this.displayCyanBgColorMuted,
    required this.displayCyanBorderColorEmphasis,
    required this.displayCyanBorderColorMuted,
    required this.displayCyanFgColor,
    required this.displayCyanScale0,
    required this.displayCyanScale1,
    required this.displayCyanScale2,
    required this.displayCyanScale3,
    required this.displayCyanScale4,
    required this.displayCyanScale5,
    required this.displayCyanScale6,
    required this.displayCyanScale7,
    required this.displayCyanScale8,
    required this.displayCyanScale9,
    required this.displayGrayBgColorEmphasis,
    required this.displayGrayBgColorMuted,
    required this.displayGrayBorderColorEmphasis,
    required this.displayGrayBorderColorMuted,
    required this.displayGrayFgColor,
    required this.displayGrayScale0,
    required this.displayGrayScale1,
    required this.displayGrayScale2,
    required this.displayGrayScale3,
    required this.displayGrayScale4,
    required this.displayGrayScale5,
    required this.displayGrayScale6,
    required this.displayGrayScale7,
    required this.displayGrayScale8,
    required this.displayGrayScale9,
    required this.displayGreenBgColorEmphasis,
    required this.displayGreenBgColorMuted,
    required this.displayGreenBorderColorEmphasis,
    required this.displayGreenBorderColorMuted,
    required this.displayGreenFgColor,
    required this.displayGreenScale0,
    required this.displayGreenScale1,
    required this.displayGreenScale2,
    required this.displayGreenScale3,
    required this.displayGreenScale4,
    required this.displayGreenScale5,
    required this.displayGreenScale6,
    required this.displayGreenScale7,
    required this.displayGreenScale8,
    required this.displayGreenScale9,
    required this.displayIndigoBgColorEmphasis,
    required this.displayIndigoBgColorMuted,
    required this.displayIndigoBorderColorEmphasis,
    required this.displayIndigoBorderColorMuted,
    required this.displayIndigoFgColor,
    required this.displayIndigoScale0,
    required this.displayIndigoScale1,
    required this.displayIndigoScale2,
    required this.displayIndigoScale3,
    required this.displayIndigoScale4,
    required this.displayIndigoScale5,
    required this.displayIndigoScale6,
    required this.displayIndigoScale7,
    required this.displayIndigoScale8,
    required this.displayIndigoScale9,
    required this.displayLemonBgColorEmphasis,
    required this.displayLemonBgColorMuted,
    required this.displayLemonBorderColorEmphasis,
    required this.displayLemonBorderColorMuted,
    required this.displayLemonFgColor,
    required this.displayLemonScale0,
    required this.displayLemonScale1,
    required this.displayLemonScale2,
    required this.displayLemonScale3,
    required this.displayLemonScale4,
    required this.displayLemonScale5,
    required this.displayLemonScale6,
    required this.displayLemonScale7,
    required this.displayLemonScale8,
    required this.displayLemonScale9,
    required this.displayLimeBgColorEmphasis,
    required this.displayLimeBgColorMuted,
    required this.displayLimeBorderColorEmphasis,
    required this.displayLimeBorderColorMuted,
    required this.displayLimeFgColor,
    required this.displayLimeScale0,
    required this.displayLimeScale1,
    required this.displayLimeScale2,
    required this.displayLimeScale3,
    required this.displayLimeScale4,
    required this.displayLimeScale5,
    required this.displayLimeScale6,
    required this.displayLimeScale7,
    required this.displayLimeScale8,
    required this.displayLimeScale9,
    required this.displayOliveBgColorEmphasis,
    required this.displayOliveBgColorMuted,
    required this.displayOliveBorderColorEmphasis,
    required this.displayOliveBorderColorMuted,
    required this.displayOliveFgColor,
    required this.displayOliveScale0,
    required this.displayOliveScale1,
    required this.displayOliveScale2,
    required this.displayOliveScale3,
    required this.displayOliveScale4,
    required this.displayOliveScale5,
    required this.displayOliveScale6,
    required this.displayOliveScale7,
    required this.displayOliveScale8,
    required this.displayOliveScale9,
    required this.displayOrangeBgColorEmphasis,
    required this.displayOrangeBgColorMuted,
    required this.displayOrangeBorderColorEmphasis,
    required this.displayOrangeBorderColorMuted,
    required this.displayOrangeFgColor,
    required this.displayOrangeScale0,
    required this.displayOrangeScale1,
    required this.displayOrangeScale2,
    required this.displayOrangeScale3,
    required this.displayOrangeScale4,
    required this.displayOrangeScale5,
    required this.displayOrangeScale6,
    required this.displayOrangeScale7,
    required this.displayOrangeScale8,
    required this.displayOrangeScale9,
    required this.displayPineBgColorEmphasis,
    required this.displayPineBgColorMuted,
    required this.displayPineBorderColorEmphasis,
    required this.displayPineBorderColorMuted,
    required this.displayPineFgColor,
    required this.displayPineScale0,
    required this.displayPineScale1,
    required this.displayPineScale2,
    required this.displayPineScale3,
    required this.displayPineScale4,
    required this.displayPineScale5,
    required this.displayPineScale6,
    required this.displayPineScale7,
    required this.displayPineScale8,
    required this.displayPineScale9,
    required this.displayPinkBgColorEmphasis,
    required this.displayPinkBgColorMuted,
    required this.displayPinkBorderColorEmphasis,
    required this.displayPinkBorderColorMuted,
    required this.displayPinkFgColor,
    required this.displayPinkScale0,
    required this.displayPinkScale1,
    required this.displayPinkScale2,
    required this.displayPinkScale3,
    required this.displayPinkScale4,
    required this.displayPinkScale5,
    required this.displayPinkScale6,
    required this.displayPinkScale7,
    required this.displayPinkScale8,
    required this.displayPinkScale9,
    required this.displayPlumBgColorEmphasis,
    required this.displayPlumBgColorMuted,
    required this.displayPlumBorderColorEmphasis,
    required this.displayPlumBorderColorMuted,
    required this.displayPlumFgColor,
    required this.displayPlumScale0,
    required this.displayPlumScale1,
    required this.displayPlumScale2,
    required this.displayPlumScale3,
    required this.displayPlumScale4,
    required this.displayPlumScale5,
    required this.displayPlumScale6,
    required this.displayPlumScale7,
    required this.displayPlumScale8,
    required this.displayPlumScale9,
    required this.displayPurpleBgColorEmphasis,
    required this.displayPurpleBgColorMuted,
    required this.displayPurpleBorderColorEmphasis,
    required this.displayPurpleBorderColorMuted,
    required this.displayPurpleFgColor,
    required this.displayPurpleScale0,
    required this.displayPurpleScale1,
    required this.displayPurpleScale2,
    required this.displayPurpleScale3,
    required this.displayPurpleScale4,
    required this.displayPurpleScale5,
    required this.displayPurpleScale6,
    required this.displayPurpleScale7,
    required this.displayPurpleScale8,
    required this.displayPurpleScale9,
    required this.displayRedBgColorEmphasis,
    required this.displayRedBgColorMuted,
    required this.displayRedBorderColorEmphasis,
    required this.displayRedBorderColorMuted,
    required this.displayRedFgColor,
    required this.displayRedScale0,
    required this.displayRedScale1,
    required this.displayRedScale2,
    required this.displayRedScale3,
    required this.displayRedScale4,
    required this.displayRedScale5,
    required this.displayRedScale6,
    required this.displayRedScale7,
    required this.displayRedScale8,
    required this.displayRedScale9,
    required this.displayTealBgColorEmphasis,
    required this.displayTealBgColorMuted,
    required this.displayTealBorderColorEmphasis,
    required this.displayTealBorderColorMuted,
    required this.displayTealFgColor,
    required this.displayTealScale0,
    required this.displayTealScale1,
    required this.displayTealScale2,
    required this.displayTealScale3,
    required this.displayTealScale4,
    required this.displayTealScale5,
    required this.displayTealScale6,
    required this.displayTealScale7,
    required this.displayTealScale8,
    required this.displayTealScale9,
    required this.displayYellowBgColorEmphasis,
    required this.displayYellowBgColorMuted,
    required this.displayYellowBorderColorEmphasis,
    required this.displayYellowBorderColorMuted,
    required this.displayYellowFgColor,
    required this.displayYellowScale0,
    required this.displayYellowScale1,
    required this.displayYellowScale2,
    required this.displayYellowScale3,
    required this.displayYellowScale4,
    required this.displayYellowScale5,
    required this.displayYellowScale6,
    required this.displayYellowScale7,
    required this.displayYellowScale8,
    required this.displayYellowScale9,
    required this.fgColorAccent,
    required this.fgColorAttention,
    required this.fgColorBlack,
    required this.fgColorClosed,
    required this.fgColorDanger,
    required this.fgColorDefault,
    required this.fgColorDisabled,
    required this.fgColorDone,
    required this.fgColorDraft,
    required this.fgColorLink,
    required this.fgColorMuted,
    required this.fgColorNeutral,
    required this.fgColorOnEmphasis,
    required this.fgColorOnInverse,
    required this.fgColorOpen,
    required this.fgColorSevere,
    required this.fgColorSponsors,
    required this.fgColorSuccess,
    required this.fgColorUpsell,
    required this.fgColorWhite,
    required this.focusOutlineColor,
    required this.headerBgColor,
    required this.headerBorderColorDivider,
    required this.headerFgColorDefault,
    required this.headerFgColorLogo,
    required this.headerSearchBgColor,
    required this.headerSearchBorderColor,
    required this.highlightNeutralBgColor,
    required this.labelAuburnBgColorActive,
    required this.labelAuburnBgColorHover,
    required this.labelAuburnBgColorRest,
    required this.labelAuburnBorderColor,
    required this.labelAuburnFgColorActive,
    required this.labelAuburnFgColorHover,
    required this.labelAuburnFgColorRest,
    required this.labelBlueBgColorActive,
    required this.labelBlueBgColorHover,
    required this.labelBlueBgColorRest,
    required this.labelBlueBorderColor,
    required this.labelBlueFgColorActive,
    required this.labelBlueFgColorHover,
    required this.labelBlueFgColorRest,
    required this.labelBrownBgColorActive,
    required this.labelBrownBgColorHover,
    required this.labelBrownBgColorRest,
    required this.labelBrownBorderColor,
    required this.labelBrownFgColorActive,
    required this.labelBrownFgColorHover,
    required this.labelBrownFgColorRest,
    required this.labelCoralBgColorActive,
    required this.labelCoralBgColorHover,
    required this.labelCoralBgColorRest,
    required this.labelCoralBorderColor,
    required this.labelCoralFgColorActive,
    required this.labelCoralFgColorHover,
    required this.labelCoralFgColorRest,
    required this.labelCyanBgColorActive,
    required this.labelCyanBgColorHover,
    required this.labelCyanBgColorRest,
    required this.labelCyanBorderColor,
    required this.labelCyanFgColorActive,
    required this.labelCyanFgColorHover,
    required this.labelCyanFgColorRest,
    required this.labelGrayBgColorActive,
    required this.labelGrayBgColorHover,
    required this.labelGrayBgColorRest,
    required this.labelGrayBorderColor,
    required this.labelGrayFgColorActive,
    required this.labelGrayFgColorHover,
    required this.labelGrayFgColorRest,
    required this.labelGreenBgColorActive,
    required this.labelGreenBgColorHover,
    required this.labelGreenBgColorRest,
    required this.labelGreenBorderColor,
    required this.labelGreenFgColorActive,
    required this.labelGreenFgColorHover,
    required this.labelGreenFgColorRest,
    required this.labelIndigoBgColorActive,
    required this.labelIndigoBgColorHover,
    required this.labelIndigoBgColorRest,
    required this.labelIndigoBorderColor,
    required this.labelIndigoFgColorActive,
    required this.labelIndigoFgColorHover,
    required this.labelIndigoFgColorRest,
    required this.labelLemonBgColorActive,
    required this.labelLemonBgColorHover,
    required this.labelLemonBgColorRest,
    required this.labelLemonBorderColor,
    required this.labelLemonFgColorActive,
    required this.labelLemonFgColorHover,
    required this.labelLemonFgColorRest,
    required this.labelLimeBgColorActive,
    required this.labelLimeBgColorHover,
    required this.labelLimeBgColorRest,
    required this.labelLimeBorderColor,
    required this.labelLimeFgColorActive,
    required this.labelLimeFgColorHover,
    required this.labelLimeFgColorRest,
    required this.labelOliveBgColorActive,
    required this.labelOliveBgColorHover,
    required this.labelOliveBgColorRest,
    required this.labelOliveBorderColor,
    required this.labelOliveFgColorActive,
    required this.labelOliveFgColorHover,
    required this.labelOliveFgColorRest,
    required this.labelOrangeBgColorActive,
    required this.labelOrangeBgColorHover,
    required this.labelOrangeBgColorRest,
    required this.labelOrangeBorderColor,
    required this.labelOrangeFgColorActive,
    required this.labelOrangeFgColorHover,
    required this.labelOrangeFgColorRest,
    required this.labelPineBgColorActive,
    required this.labelPineBgColorHover,
    required this.labelPineBgColorRest,
    required this.labelPineBorderColor,
    required this.labelPineFgColorActive,
    required this.labelPineFgColorHover,
    required this.labelPineFgColorRest,
    required this.labelPinkBgColorActive,
    required this.labelPinkBgColorHover,
    required this.labelPinkBgColorRest,
    required this.labelPinkBorderColor,
    required this.labelPinkFgColorActive,
    required this.labelPinkFgColorHover,
    required this.labelPinkFgColorRest,
    required this.labelPlumBgColorActive,
    required this.labelPlumBgColorHover,
    required this.labelPlumBgColorRest,
    required this.labelPlumBorderColor,
    required this.labelPlumFgColorActive,
    required this.labelPlumFgColorHover,
    required this.labelPlumFgColorRest,
    required this.labelPurpleBgColorActive,
    required this.labelPurpleBgColorHover,
    required this.labelPurpleBgColorRest,
    required this.labelPurpleBorderColor,
    required this.labelPurpleFgColorActive,
    required this.labelPurpleFgColorHover,
    required this.labelPurpleFgColorRest,
    required this.labelRedBgColorActive,
    required this.labelRedBgColorHover,
    required this.labelRedBgColorRest,
    required this.labelRedBorderColor,
    required this.labelRedFgColorActive,
    required this.labelRedFgColorHover,
    required this.labelRedFgColorRest,
    required this.labelTealBgColorActive,
    required this.labelTealBgColorHover,
    required this.labelTealBgColorRest,
    required this.labelTealBorderColor,
    required this.labelTealFgColorActive,
    required this.labelTealFgColorHover,
    required this.labelTealFgColorRest,
    required this.labelYellowBgColorActive,
    required this.labelYellowBgColorHover,
    required this.labelYellowBgColorRest,
    required this.labelYellowBorderColor,
    required this.labelYellowFgColorActive,
    required this.labelYellowFgColorHover,
    required this.labelYellowFgColorRest,
    required this.menuBgColorActive,
    required this.overlayBackdropBgColor,
    required this.overlayBgColor,
    required this.overlayBorderColor,
    required this.pageHeaderBgColor,
    required this.prettylightsSyntaxBracketHighlighterAngle,
    required this.prettylightsSyntaxBracketHighlighterUnmatched,
    required this.prettylightsSyntaxBrackethighlighterAngle,
    required this.prettylightsSyntaxBrackethighlighterUnmatched,
    required this.prettylightsSyntaxCarriageReturnBg,
    required this.prettylightsSyntaxCarriageReturnText,
    required this.prettylightsSyntaxComment,
    required this.prettylightsSyntaxConstant,
    required this.prettylightsSyntaxConstantOtherReferenceLink,
    required this.prettylightsSyntaxEntity,
    required this.prettylightsSyntaxEntityTag,
    required this.prettylightsSyntaxInvalidIllegalBg,
    required this.prettylightsSyntaxInvalidIllegalText,
    required this.prettylightsSyntaxKeyword,
    required this.prettylightsSyntaxMarkupBold,
    required this.prettylightsSyntaxMarkupChangedBg,
    required this.prettylightsSyntaxMarkupChangedText,
    required this.prettylightsSyntaxMarkupDeletedBg,
    required this.prettylightsSyntaxMarkupDeletedText,
    required this.prettylightsSyntaxMarkupHeading,
    required this.prettylightsSyntaxMarkupIgnoredBg,
    required this.prettylightsSyntaxMarkupIgnoredText,
    required this.prettylightsSyntaxMarkupInsertedBg,
    required this.prettylightsSyntaxMarkupInsertedText,
    required this.prettylightsSyntaxMarkupItalic,
    required this.prettylightsSyntaxMarkupList,
    required this.prettylightsSyntaxMetaDiffRange,
    required this.prettylightsSyntaxStorageModifierImport,
    required this.prettylightsSyntaxString,
    required this.prettylightsSyntaxStringRegexp,
    required this.prettylightsSyntaxSublimeLinterGutterMark,
    required this.prettylightsSyntaxSublimelinterGutterMark,
    required this.prettylightsSyntaxVariable,
    required this.progressBarBgColorAccent,
    required this.progressBarBgColorAttention,
    required this.progressBarBgColorDanger,
    required this.progressBarBgColorDone,
    required this.progressBarBgColorNeutral,
    required this.progressBarBgColorSevere,
    required this.progressBarBgColorSponsors,
    required this.progressBarBgColorSuccess,
    required this.progressBarTrackBgColor,
    required this.progressBarTrackBorderColor,
    required this.reactionButtonSelectedBgColorHover,
    required this.reactionButtonSelectedBgColorRest,
    required this.reactionButtonSelectedFgColorHover,
    required this.reactionButtonSelectedFgColorRest,
    required this.selectMenuBgColorActive,
    required this.selectMenuBorderColor,
    required this.selectionBgColor,
    required this.sideNavBgColorSelected,
    required this.skeletonLoaderBgColor,
    required this.timelineBadgeBgColor,
    required this.tooltipBgColor,
    required this.tooltipFgColor,
    required this.topicTagBorderColor,
    required this.treeViewItemLeadingVisualIconColorRest,
    required this.underlineNavBorderColorActive,
    required this.underlineNavBorderColorHover,
    required this.underlineNavIconColorRest,
  });

  final Color ansiBlack;
  final Color ansiBlackBright;
  final Color ansiBlue;
  final Color ansiBlueBright;
  final Color ansiCyan;
  final Color ansiCyanBright;
  final Color ansiGray;
  final Color ansiGreen;
  final Color ansiGreenBright;
  final Color ansiMagenta;
  final Color ansiMagentaBright;
  final Color ansiRed;
  final Color ansiRedBright;
  final Color ansiWhite;
  final Color ansiWhiteBright;
  final Color ansiYellow;
  final Color ansiYellowBright;
  final Color avatarBgColor;
  final Color avatarBorderColor;
  final Color avatarStackFadeBgColorDefault;
  final Color avatarStackFadeBgColorMuted;
  final Color bgColorAccentEmphasis;
  final Color bgColorAccentMuted;
  final Color bgColorAttentionEmphasis;
  final Color bgColorAttentionMuted;
  final Color bgColorBlack;
  final Color bgColorClosedEmphasis;
  final Color bgColorClosedMuted;
  final Color bgColorDangerEmphasis;
  final Color bgColorDangerMuted;
  final Color bgColorDefault;
  final Color bgColorDisabled;
  final Color bgColorDoneEmphasis;
  final Color bgColorDoneMuted;
  final Color bgColorDraftEmphasis;
  final Color bgColorDraftMuted;
  final Color bgColorEmphasis;
  final Color bgColorInset;
  final Color bgColorInverse;
  final Color bgColorMuted;
  final Color bgColorNeutralEmphasis;
  final Color bgColorNeutralMuted;
  final Color bgColorOpenEmphasis;
  final Color bgColorOpenMuted;
  final Color bgColorSevereEmphasis;
  final Color bgColorSevereMuted;
  final Color bgColorSponsorsEmphasis;
  final Color bgColorSponsorsMuted;
  final Color bgColorSuccessEmphasis;
  final Color bgColorSuccessMuted;
  final Color bgColorTransparent;
  final Color bgColorUpsellEmphasis;
  final Color bgColorUpsellMuted;
  final Color bgColorWhite;
  final Color borderColorAccentEmphasis;
  final Color borderColorAccentMuted;
  final Color borderColorAttentionEmphasis;
  final Color borderColorAttentionMuted;
  final Color borderColorClosedEmphasis;
  final Color borderColorClosedMuted;
  final Color borderColorDangerEmphasis;
  final Color borderColorDangerMuted;
  final Color borderColorDefault;
  final Color borderColorDisabled;
  final Color borderColorDoneEmphasis;
  final Color borderColorDoneMuted;
  final Color borderColorDraftEmphasis;
  final Color borderColorDraftMuted;
  final Color borderColorEmphasis;
  final Color borderColorMuted;
  final Color borderColorNeutralEmphasis;
  final Color borderColorNeutralMuted;
  final Color borderColorOpenEmphasis;
  final Color borderColorOpenMuted;
  final Color borderColorSevereEmphasis;
  final Color borderColorSevereMuted;
  final Color borderColorSponsorsEmphasis;
  final Color borderColorSponsorsMuted;
  final Color borderColorSuccessEmphasis;
  final Color borderColorSuccessMuted;
  final Color borderColorTranslucent;
  final Color borderColorTransparent;
  final Color borderColorUpsellEmphasis;
  final Color borderColorUpsellMuted;
  final Color buttonDangerBgColorActive;
  final Color buttonDangerBgColorDisabled;
  final Color buttonDangerBgColorHover;
  final Color buttonDangerBgColorRest;
  final Color buttonDangerBorderColorActive;
  final Color buttonDangerBorderColorHover;
  final Color buttonDangerBorderColorRest;
  final Color buttonDangerFgColorActive;
  final Color buttonDangerFgColorDisabled;
  final Color buttonDangerFgColorHover;
  final Color buttonDangerFgColorRest;
  final Color buttonDangerIconColorDisabled;
  final Color buttonDangerIconColorHover;
  final Color buttonDangerIconColorRest;
  final Color buttonDefaultBgColorActive;
  final Color buttonDefaultBgColorDisabled;
  final Color buttonDefaultBgColorHover;
  final Color buttonDefaultBgColorRest;
  final Color buttonDefaultBgColorSelected;
  final Color buttonDefaultBorderColorActive;
  final Color buttonDefaultBorderColorDisabled;
  final Color buttonDefaultBorderColorHover;
  final Color buttonDefaultBorderColorRest;
  final Color buttonDefaultFgColorDisabled;
  final Color buttonDefaultFgColorRest;
  final Color buttonInactiveBgColor;
  final Color buttonInactiveFgColor;
  final Color buttonInvisibleBgColorActive;
  final Color buttonInvisibleBgColorDisabled;
  final Color buttonInvisibleBgColorHover;
  final Color buttonInvisibleBgColorRest;
  final Color buttonInvisibleBorderColorDisabled;
  final Color buttonInvisibleBorderColorHover;
  final Color buttonInvisibleBorderColorRest;
  final Color buttonInvisibleFgColorActive;
  final Color buttonInvisibleFgColorDisabled;
  final Color buttonInvisibleFgColorHover;
  final Color buttonInvisibleFgColorRest;
  final Color buttonInvisibleIconColorDisabled;
  final Color buttonInvisibleIconColorHover;
  final Color buttonInvisibleIconColorRest;
  final Color buttonOutlineBgColorActive;
  final Color buttonOutlineBgColorDisabled;
  final Color buttonOutlineBgColorHover;
  final Color buttonOutlineBgColorRest;
  final Color buttonOutlineBorderColorActive;
  final Color buttonOutlineBorderColorHover;
  final Color buttonOutlineFgColorActive;
  final Color buttonOutlineFgColorDisabled;
  final Color buttonOutlineFgColorHover;
  final Color buttonOutlineFgColorRest;
  final Color buttonPrimaryBgColorActive;
  final Color buttonPrimaryBgColorDisabled;
  final Color buttonPrimaryBgColorHover;
  final Color buttonPrimaryBgColorRest;
  final Color buttonPrimaryBorderColorActive;
  final Color buttonPrimaryBorderColorDisabled;
  final Color buttonPrimaryBorderColorHover;
  final Color buttonPrimaryBorderColorRest;
  final Color buttonPrimaryFgColorDisabled;
  final Color buttonPrimaryFgColorRest;
  final Color buttonPrimaryIconColorDisabled;
  final Color buttonPrimaryIconColorRest;
  final Color buttonStarIconColor;
  final Color buttonCounterDangerBgColorDisabled;
  final Color buttonCounterDangerBgColorHover;
  final Color buttonCounterDangerBgColorRest;
  final Color buttonCounterDangerFgColorDisabled;
  final Color buttonCounterDangerFgColorHover;
  final Color buttonCounterDangerFgColorRest;
  final Color buttonCounterDefaultBgColorRest;
  final Color buttonCounterInvisibleBgColorRest;
  final Color buttonCounterOutlineBgColorDisabled;
  final Color buttonCounterOutlineBgColorHover;
  final Color buttonCounterOutlineBgColorRest;
  final Color buttonCounterOutlineFgColorDisabled;
  final Color buttonCounterOutlineFgColorHover;
  final Color buttonCounterOutlineFgColorRest;
  final Color buttonCounterPrimaryBgColorRest;
  final Color buttonKeybindingHintDangerBgColorActive;
  final Color buttonKeybindingHintDangerBgColorDisabled;
  final Color buttonKeybindingHintDangerBgColorHover;
  final Color buttonKeybindingHintDangerBgColorRest;
  final Color buttonKeybindingHintDangerBorderColorActive;
  final Color buttonKeybindingHintDangerBorderColorDisabled;
  final Color buttonKeybindingHintDangerBorderColorHover;
  final Color buttonKeybindingHintDangerBorderColorRest;
  final Color buttonKeybindingHintDangerFgColorActive;
  final Color buttonKeybindingHintDangerFgColorDisabled;
  final Color buttonKeybindingHintDangerFgColorHover;
  final Color buttonKeybindingHintDangerFgColorRest;
  final Color buttonKeybindingHintDefaultBgColorDisabled;
  final Color buttonKeybindingHintDefaultBgColorRest;
  final Color buttonKeybindingHintDefaultBorderColorDisabled;
  final Color buttonKeybindingHintDefaultBorderColorRest;
  final Color buttonKeybindingHintDefaultFgColorDisabled;
  final Color buttonKeybindingHintDefaultFgColorRest;
  final Color buttonKeybindingHintInactiveBgColor;
  final Color buttonKeybindingHintInactiveBorderColor;
  final Color buttonKeybindingHintInactiveFgColor;
  final Color buttonKeybindingHintInvisibleBgColorActive;
  final Color buttonKeybindingHintInvisibleBgColorDisabled;
  final Color buttonKeybindingHintInvisibleBgColorHover;
  final Color buttonKeybindingHintInvisibleBgColorRest;
  final Color buttonKeybindingHintInvisibleBorderColorDisabled;
  final Color buttonKeybindingHintInvisibleBorderColorRest;
  final Color buttonKeybindingHintInvisibleFgColorDisabled;
  final Color buttonKeybindingHintInvisibleFgColorRest;
  final Color buttonKeybindingHintPrimaryBgColorDisabled;
  final Color buttonKeybindingHintPrimaryBgColorRest;
  final Color buttonKeybindingHintPrimaryBorderColorDisabled;
  final Color buttonKeybindingHintPrimaryBorderColorRest;
  final Color buttonKeybindingHintPrimaryFgColorDisabled;
  final Color buttonKeybindingHintPrimaryFgColorRest;
  final Color cardBgColor;
  final Color codeMirrorActivelineBgColor;
  final Color codeMirrorBgColor;
  final Color codeMirrorCursorFgColor;
  final Color codeMirrorFgColor;
  final Color codeMirrorGutterMarkerFgColorDefault;
  final Color codeMirrorGutterMarkerFgColorMuted;
  final Color codeMirrorGuttersBgColor;
  final Color codeMirrorLineNumberFgColor;
  final Color codeMirrorLinesBgColor;
  final Color codeMirrorMatchingBracketFgColor;
  final Color codeMirrorSelectionBgColor;
  final Color codeMirrorSyntaxFgColorComment;
  final Color codeMirrorSyntaxFgColorConstant;
  final Color codeMirrorSyntaxFgColorEntity;
  final Color codeMirrorSyntaxFgColorKeyword;
  final Color codeMirrorSyntaxFgColorStorage;
  final Color codeMirrorSyntaxFgColorString;
  final Color codeMirrorSyntaxFgColorSupport;
  final Color codeMirrorSyntaxFgColorVariable;
  final Color colorAnsiBlack;
  final Color colorAnsiBlackBright;
  final Color colorAnsiBlue;
  final Color colorAnsiBlueBright;
  final Color colorAnsiCyan;
  final Color colorAnsiCyanBright;
  final Color colorAnsiGray;
  final Color colorAnsiGreen;
  final Color colorAnsiGreenBright;
  final Color colorAnsiMagenta;
  final Color colorAnsiMagentaBright;
  final Color colorAnsiRed;
  final Color colorAnsiRedBright;
  final Color colorAnsiWhite;
  final Color colorAnsiWhiteBright;
  final Color colorAnsiYellow;
  final Color colorAnsiYellowBright;
  final Color colorPrettylightsSyntaxBrackethighlighterAngle;
  final Color colorPrettylightsSyntaxBrackethighlighterUnmatched;
  final Color colorPrettylightsSyntaxCarriageReturnBg;
  final Color colorPrettylightsSyntaxCarriageReturnText;
  final Color colorPrettylightsSyntaxComment;
  final Color colorPrettylightsSyntaxConstant;
  final Color colorPrettylightsSyntaxConstantOtherReferenceLink;
  final Color colorPrettylightsSyntaxEntity;
  final Color colorPrettylightsSyntaxEntityTag;
  final Color colorPrettylightsSyntaxInvalidIllegalBg;
  final Color colorPrettylightsSyntaxInvalidIllegalText;
  final Color colorPrettylightsSyntaxKeyword;
  final Color colorPrettylightsSyntaxMarkupBold;
  final Color colorPrettylightsSyntaxMarkupChangedBg;
  final Color colorPrettylightsSyntaxMarkupChangedText;
  final Color colorPrettylightsSyntaxMarkupDeletedBg;
  final Color colorPrettylightsSyntaxMarkupDeletedText;
  final Color colorPrettylightsSyntaxMarkupHeading;
  final Color colorPrettylightsSyntaxMarkupIgnoredBg;
  final Color colorPrettylightsSyntaxMarkupIgnoredText;
  final Color colorPrettylightsSyntaxMarkupInsertedBg;
  final Color colorPrettylightsSyntaxMarkupInsertedText;
  final Color colorPrettylightsSyntaxMarkupItalic;
  final Color colorPrettylightsSyntaxMarkupList;
  final Color colorPrettylightsSyntaxMetaDiffRange;
  final Color colorPrettylightsSyntaxStorageModifierImport;
  final Color colorPrettylightsSyntaxString;
  final Color colorPrettylightsSyntaxStringRegexp;
  final Color colorPrettylightsSyntaxSublimelinterGutterMark;
  final Color colorPrettylightsSyntaxVariable;
  final Color contributionDefaultBgColor0;
  final Color contributionDefaultBgColor1;
  final Color contributionDefaultBgColor2;
  final Color contributionDefaultBgColor3;
  final Color contributionDefaultBgColor4;
  final Color contributionDefaultBorderColor0;
  final Color contributionDefaultBorderColor1;
  final Color contributionDefaultBorderColor2;
  final Color contributionDefaultBorderColor3;
  final Color contributionDefaultBorderColor4;
  final Color contributionHalloweenBgColor1;
  final Color contributionHalloweenBgColor2;
  final Color contributionHalloweenBgColor3;
  final Color contributionHalloweenBgColor4;
  final Color contributionWinterBgColor1;
  final Color contributionWinterBgColor2;
  final Color contributionWinterBgColor3;
  final Color contributionWinterBgColor4;
  final Color controlBgColorActive;
  final Color controlBgColorDisabled;
  final Color controlBgColorHover;
  final Color controlBgColorRest;
  final Color controlBgColorSelected;
  final Color controlBorderColorDanger;
  final Color controlBorderColorDisabled;
  final Color controlBorderColorEmphasis;
  final Color controlBorderColorRest;
  final Color controlBorderColorSelected;
  final Color controlBorderColorSuccess;
  final Color controlBorderColorWarning;
  final Color controlCheckedBgColorActive;
  final Color controlCheckedBgColorDisabled;
  final Color controlCheckedBgColorHover;
  final Color controlCheckedBgColorRest;
  final Color controlCheckedBorderColorActive;
  final Color controlCheckedBorderColorDisabled;
  final Color controlCheckedBorderColorHover;
  final Color controlCheckedBorderColorRest;
  final Color controlCheckedFgColorDisabled;
  final Color controlCheckedFgColorRest;
  final Color controlDangerBgColorActive;
  final Color controlDangerBgColorHover;
  final Color controlDangerFgColorHover;
  final Color controlDangerFgColorRest;
  final Color controlFgColorDisabled;
  final Color controlFgColorPlaceholder;
  final Color controlFgColorRest;
  final Color controlIconColorRest;
  final Color controlTransparentBgColorActive;
  final Color controlTransparentBgColorDisabled;
  final Color controlTransparentBgColorHover;
  final Color controlTransparentBgColorRest;
  final Color controlTransparentBgColorSelected;
  final Color controlTransparentBorderColorActive;
  final Color controlTransparentBorderColorHover;
  final Color controlTransparentBorderColorRest;
  final Color controlKnobBgColorChecked;
  final Color controlKnobBgColorDisabled;
  final Color controlKnobBgColorRest;
  final Color controlKnobBorderColorChecked;
  final Color controlKnobBorderColorDisabled;
  final Color controlKnobBorderColorRest;
  final Color controlTrackBgColorActive;
  final Color controlTrackBgColorDisabled;
  final Color controlTrackBgColorHover;
  final Color controlTrackBgColorRest;
  final Color controlTrackBorderColorDisabled;
  final Color controlTrackBorderColorRest;
  final Color controlTrackFgColorDisabled;
  final Color controlTrackFgColorRest;
  final Color counterBgColorEmphasis;
  final Color counterBgColorMuted;
  final Color counterBorderColor;
  final Color dashboardBgColor;
  final Color dataAuburnColorEmphasis;
  final Color dataAuburnColorMuted;
  final Color dataBlueColorEmphasis;
  final Color dataBlueColorMuted;
  final Color dataBrownColorEmphasis;
  final Color dataBrownColorMuted;
  final Color dataCoralColorEmphasis;
  final Color dataCoralColorMuted;
  final Color dataGrayColorEmphasis;
  final Color dataGrayColorMuted;
  final Color dataGreenColorEmphasis;
  final Color dataGreenColorMuted;
  final Color dataLemonColorEmphasis;
  final Color dataLemonColorMuted;
  final Color dataLimeColorEmphasis;
  final Color dataLimeColorMuted;
  final Color dataOliveColorEmphasis;
  final Color dataOliveColorMuted;
  final Color dataOrangeColorEmphasis;
  final Color dataOrangeColorMuted;
  final Color dataPineColorEmphasis;
  final Color dataPineColorMuted;
  final Color dataPinkColorEmphasis;
  final Color dataPinkColorMuted;
  final Color dataPlumColorEmphasis;
  final Color dataPlumColorMuted;
  final Color dataPurpleColorEmphasis;
  final Color dataPurpleColorMuted;
  final Color dataRedColorEmphasis;
  final Color dataRedColorMuted;
  final Color dataTealColorEmphasis;
  final Color dataTealColorMuted;
  final Color dataYellowColorEmphasis;
  final Color dataYellowColorMuted;
  final Color diffBlobAdditionLineBgColor;
  final Color diffBlobAdditionLineFgColor;
  final Color diffBlobAdditionNumBgColor;
  final Color diffBlobAdditionNumFgColor;
  final Color diffBlobAdditionWordBgColor;
  final Color diffBlobAdditionWordFgColor;
  final Color diffBlobDeletionLineBgColor;
  final Color diffBlobDeletionLineFgColor;
  final Color diffBlobDeletionNumBgColor;
  final Color diffBlobDeletionNumFgColor;
  final Color diffBlobDeletionWordBgColor;
  final Color diffBlobDeletionWordFgColor;
  final Color diffBlobEmptyLineBgColor;
  final Color diffBlobEmptyNumBgColor;
  final Color diffBlobExpanderIconColor;
  final Color diffBlobHunkLineBgColor;
  final Color diffBlobHunkLineFgColor;
  final Color diffBlobHunkNumBgColorHover;
  final Color diffBlobHunkNumBgColorRest;
  final Color diffBlobHunkNumFgColorHover;
  final Color diffBlobHunkNumFgColorRest;
  final Color displayAuburnBgColorEmphasis;
  final Color displayAuburnBgColorMuted;
  final Color displayAuburnBorderColorEmphasis;
  final Color displayAuburnBorderColorMuted;
  final Color displayAuburnFgColor;
  final Color displayAuburnScale0;
  final Color displayAuburnScale1;
  final Color displayAuburnScale2;
  final Color displayAuburnScale3;
  final Color displayAuburnScale4;
  final Color displayAuburnScale5;
  final Color displayAuburnScale6;
  final Color displayAuburnScale7;
  final Color displayAuburnScale8;
  final Color displayAuburnScale9;
  final Color displayBlueBgColorEmphasis;
  final Color displayBlueBgColorMuted;
  final Color displayBlueBorderColorEmphasis;
  final Color displayBlueBorderColorMuted;
  final Color displayBlueFgColor;
  final Color displayBlueScale0;
  final Color displayBlueScale1;
  final Color displayBlueScale2;
  final Color displayBlueScale3;
  final Color displayBlueScale4;
  final Color displayBlueScale5;
  final Color displayBlueScale6;
  final Color displayBlueScale7;
  final Color displayBlueScale8;
  final Color displayBlueScale9;
  final Color displayBrownBgColorEmphasis;
  final Color displayBrownBgColorMuted;
  final Color displayBrownBorderColorEmphasis;
  final Color displayBrownBorderColorMuted;
  final Color displayBrownFgColor;
  final Color displayBrownScale0;
  final Color displayBrownScale1;
  final Color displayBrownScale2;
  final Color displayBrownScale3;
  final Color displayBrownScale4;
  final Color displayBrownScale5;
  final Color displayBrownScale6;
  final Color displayBrownScale7;
  final Color displayBrownScale8;
  final Color displayBrownScale9;
  final Color displayCoralBgColorEmphasis;
  final Color displayCoralBgColorMuted;
  final Color displayCoralBorderColorEmphasis;
  final Color displayCoralBorderColorMuted;
  final Color displayCoralFgColor;
  final Color displayCoralScale0;
  final Color displayCoralScale1;
  final Color displayCoralScale2;
  final Color displayCoralScale3;
  final Color displayCoralScale4;
  final Color displayCoralScale5;
  final Color displayCoralScale6;
  final Color displayCoralScale7;
  final Color displayCoralScale8;
  final Color displayCoralScale9;
  final Color displayCyanBgColorEmphasis;
  final Color displayCyanBgColorMuted;
  final Color displayCyanBorderColorEmphasis;
  final Color displayCyanBorderColorMuted;
  final Color displayCyanFgColor;
  final Color displayCyanScale0;
  final Color displayCyanScale1;
  final Color displayCyanScale2;
  final Color displayCyanScale3;
  final Color displayCyanScale4;
  final Color displayCyanScale5;
  final Color displayCyanScale6;
  final Color displayCyanScale7;
  final Color displayCyanScale8;
  final Color displayCyanScale9;
  final Color displayGrayBgColorEmphasis;
  final Color displayGrayBgColorMuted;
  final Color displayGrayBorderColorEmphasis;
  final Color displayGrayBorderColorMuted;
  final Color displayGrayFgColor;
  final Color displayGrayScale0;
  final Color displayGrayScale1;
  final Color displayGrayScale2;
  final Color displayGrayScale3;
  final Color displayGrayScale4;
  final Color displayGrayScale5;
  final Color displayGrayScale6;
  final Color displayGrayScale7;
  final Color displayGrayScale8;
  final Color displayGrayScale9;
  final Color displayGreenBgColorEmphasis;
  final Color displayGreenBgColorMuted;
  final Color displayGreenBorderColorEmphasis;
  final Color displayGreenBorderColorMuted;
  final Color displayGreenFgColor;
  final Color displayGreenScale0;
  final Color displayGreenScale1;
  final Color displayGreenScale2;
  final Color displayGreenScale3;
  final Color displayGreenScale4;
  final Color displayGreenScale5;
  final Color displayGreenScale6;
  final Color displayGreenScale7;
  final Color displayGreenScale8;
  final Color displayGreenScale9;
  final Color displayIndigoBgColorEmphasis;
  final Color displayIndigoBgColorMuted;
  final Color displayIndigoBorderColorEmphasis;
  final Color displayIndigoBorderColorMuted;
  final Color displayIndigoFgColor;
  final Color displayIndigoScale0;
  final Color displayIndigoScale1;
  final Color displayIndigoScale2;
  final Color displayIndigoScale3;
  final Color displayIndigoScale4;
  final Color displayIndigoScale5;
  final Color displayIndigoScale6;
  final Color displayIndigoScale7;
  final Color displayIndigoScale8;
  final Color displayIndigoScale9;
  final Color displayLemonBgColorEmphasis;
  final Color displayLemonBgColorMuted;
  final Color displayLemonBorderColorEmphasis;
  final Color displayLemonBorderColorMuted;
  final Color displayLemonFgColor;
  final Color displayLemonScale0;
  final Color displayLemonScale1;
  final Color displayLemonScale2;
  final Color displayLemonScale3;
  final Color displayLemonScale4;
  final Color displayLemonScale5;
  final Color displayLemonScale6;
  final Color displayLemonScale7;
  final Color displayLemonScale8;
  final Color displayLemonScale9;
  final Color displayLimeBgColorEmphasis;
  final Color displayLimeBgColorMuted;
  final Color displayLimeBorderColorEmphasis;
  final Color displayLimeBorderColorMuted;
  final Color displayLimeFgColor;
  final Color displayLimeScale0;
  final Color displayLimeScale1;
  final Color displayLimeScale2;
  final Color displayLimeScale3;
  final Color displayLimeScale4;
  final Color displayLimeScale5;
  final Color displayLimeScale6;
  final Color displayLimeScale7;
  final Color displayLimeScale8;
  final Color displayLimeScale9;
  final Color displayOliveBgColorEmphasis;
  final Color displayOliveBgColorMuted;
  final Color displayOliveBorderColorEmphasis;
  final Color displayOliveBorderColorMuted;
  final Color displayOliveFgColor;
  final Color displayOliveScale0;
  final Color displayOliveScale1;
  final Color displayOliveScale2;
  final Color displayOliveScale3;
  final Color displayOliveScale4;
  final Color displayOliveScale5;
  final Color displayOliveScale6;
  final Color displayOliveScale7;
  final Color displayOliveScale8;
  final Color displayOliveScale9;
  final Color displayOrangeBgColorEmphasis;
  final Color displayOrangeBgColorMuted;
  final Color displayOrangeBorderColorEmphasis;
  final Color displayOrangeBorderColorMuted;
  final Color displayOrangeFgColor;
  final Color displayOrangeScale0;
  final Color displayOrangeScale1;
  final Color displayOrangeScale2;
  final Color displayOrangeScale3;
  final Color displayOrangeScale4;
  final Color displayOrangeScale5;
  final Color displayOrangeScale6;
  final Color displayOrangeScale7;
  final Color displayOrangeScale8;
  final Color displayOrangeScale9;
  final Color displayPineBgColorEmphasis;
  final Color displayPineBgColorMuted;
  final Color displayPineBorderColorEmphasis;
  final Color displayPineBorderColorMuted;
  final Color displayPineFgColor;
  final Color displayPineScale0;
  final Color displayPineScale1;
  final Color displayPineScale2;
  final Color displayPineScale3;
  final Color displayPineScale4;
  final Color displayPineScale5;
  final Color displayPineScale6;
  final Color displayPineScale7;
  final Color displayPineScale8;
  final Color displayPineScale9;
  final Color displayPinkBgColorEmphasis;
  final Color displayPinkBgColorMuted;
  final Color displayPinkBorderColorEmphasis;
  final Color displayPinkBorderColorMuted;
  final Color displayPinkFgColor;
  final Color displayPinkScale0;
  final Color displayPinkScale1;
  final Color displayPinkScale2;
  final Color displayPinkScale3;
  final Color displayPinkScale4;
  final Color displayPinkScale5;
  final Color displayPinkScale6;
  final Color displayPinkScale7;
  final Color displayPinkScale8;
  final Color displayPinkScale9;
  final Color displayPlumBgColorEmphasis;
  final Color displayPlumBgColorMuted;
  final Color displayPlumBorderColorEmphasis;
  final Color displayPlumBorderColorMuted;
  final Color displayPlumFgColor;
  final Color displayPlumScale0;
  final Color displayPlumScale1;
  final Color displayPlumScale2;
  final Color displayPlumScale3;
  final Color displayPlumScale4;
  final Color displayPlumScale5;
  final Color displayPlumScale6;
  final Color displayPlumScale7;
  final Color displayPlumScale8;
  final Color displayPlumScale9;
  final Color displayPurpleBgColorEmphasis;
  final Color displayPurpleBgColorMuted;
  final Color displayPurpleBorderColorEmphasis;
  final Color displayPurpleBorderColorMuted;
  final Color displayPurpleFgColor;
  final Color displayPurpleScale0;
  final Color displayPurpleScale1;
  final Color displayPurpleScale2;
  final Color displayPurpleScale3;
  final Color displayPurpleScale4;
  final Color displayPurpleScale5;
  final Color displayPurpleScale6;
  final Color displayPurpleScale7;
  final Color displayPurpleScale8;
  final Color displayPurpleScale9;
  final Color displayRedBgColorEmphasis;
  final Color displayRedBgColorMuted;
  final Color displayRedBorderColorEmphasis;
  final Color displayRedBorderColorMuted;
  final Color displayRedFgColor;
  final Color displayRedScale0;
  final Color displayRedScale1;
  final Color displayRedScale2;
  final Color displayRedScale3;
  final Color displayRedScale4;
  final Color displayRedScale5;
  final Color displayRedScale6;
  final Color displayRedScale7;
  final Color displayRedScale8;
  final Color displayRedScale9;
  final Color displayTealBgColorEmphasis;
  final Color displayTealBgColorMuted;
  final Color displayTealBorderColorEmphasis;
  final Color displayTealBorderColorMuted;
  final Color displayTealFgColor;
  final Color displayTealScale0;
  final Color displayTealScale1;
  final Color displayTealScale2;
  final Color displayTealScale3;
  final Color displayTealScale4;
  final Color displayTealScale5;
  final Color displayTealScale6;
  final Color displayTealScale7;
  final Color displayTealScale8;
  final Color displayTealScale9;
  final Color displayYellowBgColorEmphasis;
  final Color displayYellowBgColorMuted;
  final Color displayYellowBorderColorEmphasis;
  final Color displayYellowBorderColorMuted;
  final Color displayYellowFgColor;
  final Color displayYellowScale0;
  final Color displayYellowScale1;
  final Color displayYellowScale2;
  final Color displayYellowScale3;
  final Color displayYellowScale4;
  final Color displayYellowScale5;
  final Color displayYellowScale6;
  final Color displayYellowScale7;
  final Color displayYellowScale8;
  final Color displayYellowScale9;
  final Color fgColorAccent;
  final Color fgColorAttention;
  final Color fgColorBlack;
  final Color fgColorClosed;
  final Color fgColorDanger;
  final Color fgColorDefault;
  final Color fgColorDisabled;
  final Color fgColorDone;
  final Color fgColorDraft;
  final Color fgColorLink;
  final Color fgColorMuted;
  final Color fgColorNeutral;
  final Color fgColorOnEmphasis;
  final Color fgColorOnInverse;
  final Color fgColorOpen;
  final Color fgColorSevere;
  final Color fgColorSponsors;
  final Color fgColorSuccess;
  final Color fgColorUpsell;
  final Color fgColorWhite;
  final Color focusOutlineColor;
  final Color headerBgColor;
  final Color headerBorderColorDivider;
  final Color headerFgColorDefault;
  final Color headerFgColorLogo;
  final Color headerSearchBgColor;
  final Color headerSearchBorderColor;
  final Color highlightNeutralBgColor;
  final Color labelAuburnBgColorActive;
  final Color labelAuburnBgColorHover;
  final Color labelAuburnBgColorRest;
  final Color labelAuburnBorderColor;
  final Color labelAuburnFgColorActive;
  final Color labelAuburnFgColorHover;
  final Color labelAuburnFgColorRest;
  final Color labelBlueBgColorActive;
  final Color labelBlueBgColorHover;
  final Color labelBlueBgColorRest;
  final Color labelBlueBorderColor;
  final Color labelBlueFgColorActive;
  final Color labelBlueFgColorHover;
  final Color labelBlueFgColorRest;
  final Color labelBrownBgColorActive;
  final Color labelBrownBgColorHover;
  final Color labelBrownBgColorRest;
  final Color labelBrownBorderColor;
  final Color labelBrownFgColorActive;
  final Color labelBrownFgColorHover;
  final Color labelBrownFgColorRest;
  final Color labelCoralBgColorActive;
  final Color labelCoralBgColorHover;
  final Color labelCoralBgColorRest;
  final Color labelCoralBorderColor;
  final Color labelCoralFgColorActive;
  final Color labelCoralFgColorHover;
  final Color labelCoralFgColorRest;
  final Color labelCyanBgColorActive;
  final Color labelCyanBgColorHover;
  final Color labelCyanBgColorRest;
  final Color labelCyanBorderColor;
  final Color labelCyanFgColorActive;
  final Color labelCyanFgColorHover;
  final Color labelCyanFgColorRest;
  final Color labelGrayBgColorActive;
  final Color labelGrayBgColorHover;
  final Color labelGrayBgColorRest;
  final Color labelGrayBorderColor;
  final Color labelGrayFgColorActive;
  final Color labelGrayFgColorHover;
  final Color labelGrayFgColorRest;
  final Color labelGreenBgColorActive;
  final Color labelGreenBgColorHover;
  final Color labelGreenBgColorRest;
  final Color labelGreenBorderColor;
  final Color labelGreenFgColorActive;
  final Color labelGreenFgColorHover;
  final Color labelGreenFgColorRest;
  final Color labelIndigoBgColorActive;
  final Color labelIndigoBgColorHover;
  final Color labelIndigoBgColorRest;
  final Color labelIndigoBorderColor;
  final Color labelIndigoFgColorActive;
  final Color labelIndigoFgColorHover;
  final Color labelIndigoFgColorRest;
  final Color labelLemonBgColorActive;
  final Color labelLemonBgColorHover;
  final Color labelLemonBgColorRest;
  final Color labelLemonBorderColor;
  final Color labelLemonFgColorActive;
  final Color labelLemonFgColorHover;
  final Color labelLemonFgColorRest;
  final Color labelLimeBgColorActive;
  final Color labelLimeBgColorHover;
  final Color labelLimeBgColorRest;
  final Color labelLimeBorderColor;
  final Color labelLimeFgColorActive;
  final Color labelLimeFgColorHover;
  final Color labelLimeFgColorRest;
  final Color labelOliveBgColorActive;
  final Color labelOliveBgColorHover;
  final Color labelOliveBgColorRest;
  final Color labelOliveBorderColor;
  final Color labelOliveFgColorActive;
  final Color labelOliveFgColorHover;
  final Color labelOliveFgColorRest;
  final Color labelOrangeBgColorActive;
  final Color labelOrangeBgColorHover;
  final Color labelOrangeBgColorRest;
  final Color labelOrangeBorderColor;
  final Color labelOrangeFgColorActive;
  final Color labelOrangeFgColorHover;
  final Color labelOrangeFgColorRest;
  final Color labelPineBgColorActive;
  final Color labelPineBgColorHover;
  final Color labelPineBgColorRest;
  final Color labelPineBorderColor;
  final Color labelPineFgColorActive;
  final Color labelPineFgColorHover;
  final Color labelPineFgColorRest;
  final Color labelPinkBgColorActive;
  final Color labelPinkBgColorHover;
  final Color labelPinkBgColorRest;
  final Color labelPinkBorderColor;
  final Color labelPinkFgColorActive;
  final Color labelPinkFgColorHover;
  final Color labelPinkFgColorRest;
  final Color labelPlumBgColorActive;
  final Color labelPlumBgColorHover;
  final Color labelPlumBgColorRest;
  final Color labelPlumBorderColor;
  final Color labelPlumFgColorActive;
  final Color labelPlumFgColorHover;
  final Color labelPlumFgColorRest;
  final Color labelPurpleBgColorActive;
  final Color labelPurpleBgColorHover;
  final Color labelPurpleBgColorRest;
  final Color labelPurpleBorderColor;
  final Color labelPurpleFgColorActive;
  final Color labelPurpleFgColorHover;
  final Color labelPurpleFgColorRest;
  final Color labelRedBgColorActive;
  final Color labelRedBgColorHover;
  final Color labelRedBgColorRest;
  final Color labelRedBorderColor;
  final Color labelRedFgColorActive;
  final Color labelRedFgColorHover;
  final Color labelRedFgColorRest;
  final Color labelTealBgColorActive;
  final Color labelTealBgColorHover;
  final Color labelTealBgColorRest;
  final Color labelTealBorderColor;
  final Color labelTealFgColorActive;
  final Color labelTealFgColorHover;
  final Color labelTealFgColorRest;
  final Color labelYellowBgColorActive;
  final Color labelYellowBgColorHover;
  final Color labelYellowBgColorRest;
  final Color labelYellowBorderColor;
  final Color labelYellowFgColorActive;
  final Color labelYellowFgColorHover;
  final Color labelYellowFgColorRest;
  final Color menuBgColorActive;
  final Color overlayBackdropBgColor;
  final Color overlayBgColor;
  final Color overlayBorderColor;
  final Color pageHeaderBgColor;
  final Color prettylightsSyntaxBracketHighlighterAngle;
  final Color prettylightsSyntaxBracketHighlighterUnmatched;
  final Color prettylightsSyntaxBrackethighlighterAngle;
  final Color prettylightsSyntaxBrackethighlighterUnmatched;
  final Color prettylightsSyntaxCarriageReturnBg;
  final Color prettylightsSyntaxCarriageReturnText;
  final Color prettylightsSyntaxComment;
  final Color prettylightsSyntaxConstant;
  final Color prettylightsSyntaxConstantOtherReferenceLink;
  final Color prettylightsSyntaxEntity;
  final Color prettylightsSyntaxEntityTag;
  final Color prettylightsSyntaxInvalidIllegalBg;
  final Color prettylightsSyntaxInvalidIllegalText;
  final Color prettylightsSyntaxKeyword;
  final Color prettylightsSyntaxMarkupBold;
  final Color prettylightsSyntaxMarkupChangedBg;
  final Color prettylightsSyntaxMarkupChangedText;
  final Color prettylightsSyntaxMarkupDeletedBg;
  final Color prettylightsSyntaxMarkupDeletedText;
  final Color prettylightsSyntaxMarkupHeading;
  final Color prettylightsSyntaxMarkupIgnoredBg;
  final Color prettylightsSyntaxMarkupIgnoredText;
  final Color prettylightsSyntaxMarkupInsertedBg;
  final Color prettylightsSyntaxMarkupInsertedText;
  final Color prettylightsSyntaxMarkupItalic;
  final Color prettylightsSyntaxMarkupList;
  final Color prettylightsSyntaxMetaDiffRange;
  final Color prettylightsSyntaxStorageModifierImport;
  final Color prettylightsSyntaxString;
  final Color prettylightsSyntaxStringRegexp;
  final Color prettylightsSyntaxSublimeLinterGutterMark;
  final Color prettylightsSyntaxSublimelinterGutterMark;
  final Color prettylightsSyntaxVariable;
  final Color progressBarBgColorAccent;
  final Color progressBarBgColorAttention;
  final Color progressBarBgColorDanger;
  final Color progressBarBgColorDone;
  final Color progressBarBgColorNeutral;
  final Color progressBarBgColorSevere;
  final Color progressBarBgColorSponsors;
  final Color progressBarBgColorSuccess;
  final Color progressBarTrackBgColor;
  final Color progressBarTrackBorderColor;
  final Color reactionButtonSelectedBgColorHover;
  final Color reactionButtonSelectedBgColorRest;
  final Color reactionButtonSelectedFgColorHover;
  final Color reactionButtonSelectedFgColorRest;
  final Color selectMenuBgColorActive;
  final Color selectMenuBorderColor;
  final Color selectionBgColor;
  final Color sideNavBgColorSelected;
  final Color skeletonLoaderBgColor;
  final Color timelineBadgeBgColor;
  final Color tooltipBgColor;
  final Color tooltipFgColor;
  final Color topicTagBorderColor;
  final Color treeViewItemLeadingVisualIconColorRest;
  final Color underlineNavBorderColorActive;
  final Color underlineNavBorderColorHover;
  final Color underlineNavIconColorRest;

  static const PrimerColors light = PrimerColors._(
    ansiBlack: Color(0xFF1F2328),
    ansiBlackBright: Color(0xFF393F46),
    ansiBlue: Color(0xFF0969DA),
    ansiBlueBright: Color(0xFF218BFF),
    ansiCyan: Color(0xFF1B7C83),
    ansiCyanBright: Color(0xFF3192AA),
    ansiGray: Color(0xFF59636E),
    ansiGreen: Color(0xFF116329),
    ansiGreenBright: Color(0xFF1A7F37),
    ansiMagenta: Color(0xFF8250DF),
    ansiMagentaBright: Color(0xFFA475F9),
    ansiRed: Color(0xFFCF222E),
    ansiRedBright: Color(0xFFA40E26),
    ansiWhite: Color(0xFF59636E),
    ansiWhiteBright: Color(0xFF818B98),
    ansiYellow: Color(0xFF4D2D00),
    ansiYellowBright: Color(0xFF633C01),
    avatarBgColor: Color(0xFFFFFFFF),
    avatarBorderColor: Color(0x261F2328),
    avatarStackFadeBgColorDefault: Color(0xFFC8D1DA),
    avatarStackFadeBgColorMuted: Color(0xFFDAE0E7),
    bgColorAccentEmphasis: Color(0xFF0969DA),
    bgColorAccentMuted: Color(0xFFDDF4FF),
    bgColorAttentionEmphasis: Color(0xFF9A6700),
    bgColorAttentionMuted: Color(0xFFFFF8C5),
    bgColorBlack: Color(0xFF1F2328),
    bgColorClosedEmphasis: Color(0xFFCF222E),
    bgColorClosedMuted: Color(0xFFFFEBE9),
    bgColorDangerEmphasis: Color(0xFFCF222E),
    bgColorDangerMuted: Color(0xFFFFEBE9),
    bgColorDefault: Color(0xFFFFFFFF),
    bgColorDisabled: Color(0xFFEFF2F5),
    bgColorDoneEmphasis: Color(0xFF8250DF),
    bgColorDoneMuted: Color(0xFFFBEFFF),
    bgColorDraftEmphasis: Color(0xFF59636E),
    bgColorDraftMuted: Color(0x1F818B98),
    bgColorEmphasis: Color(0xFF25292E),
    bgColorInset: Color(0xFFF6F8FA),
    bgColorInverse: Color(0xFF25292E),
    bgColorMuted: Color(0xFFF6F8FA),
    bgColorNeutralEmphasis: Color(0xFF59636E),
    bgColorNeutralMuted: Color(0x1F818B98),
    bgColorOpenEmphasis: Color(0xFF1F883D),
    bgColorOpenMuted: Color(0xFFDAFBE1),
    bgColorSevereEmphasis: Color(0xFFBC4C00),
    bgColorSevereMuted: Color(0xFFFFF1E5),
    bgColorSponsorsEmphasis: Color(0xFFBF3989),
    bgColorSponsorsMuted: Color(0xFFFFEFF7),
    bgColorSuccessEmphasis: Color(0xFF1F883D),
    bgColorSuccessMuted: Color(0xFFDAFBE1),
    bgColorTransparent: Color(0x00FFFFFF),
    bgColorUpsellEmphasis: Color(0xFF8250DF),
    bgColorUpsellMuted: Color(0xFFFBEFFF),
    bgColorWhite: Color(0xFFFFFFFF),
    borderColorAccentEmphasis: Color(0xFF0969DA),
    borderColorAccentMuted: Color(0x6654AEFF),
    borderColorAttentionEmphasis: Color(0xFF9A6700),
    borderColorAttentionMuted: Color(0x66D4A72C),
    borderColorClosedEmphasis: Color(0xFFCF222E),
    borderColorClosedMuted: Color(0x66FF8182),
    borderColorDangerEmphasis: Color(0xFFCF222E),
    borderColorDangerMuted: Color(0x66FF8182),
    borderColorDefault: Color(0xFFD1D9E0),
    borderColorDisabled: Color(0x1A818B98),
    borderColorDoneEmphasis: Color(0xFF8250DF),
    borderColorDoneMuted: Color(0x66C297FF),
    borderColorDraftEmphasis: Color(0xFF59636E),
    borderColorDraftMuted: Color(0xB3D1D9E0),
    borderColorEmphasis: Color(0xFF818B98),
    borderColorMuted: Color(0xB3D1D9E0),
    borderColorNeutralEmphasis: Color(0xFF59636E),
    borderColorNeutralMuted: Color(0xB3D1D9E0),
    borderColorOpenEmphasis: Color(0xFF1A7F37),
    borderColorOpenMuted: Color(0x664AC26B),
    borderColorSevereEmphasis: Color(0xFFBC4C00),
    borderColorSevereMuted: Color(0x66FB8F44),
    borderColorSponsorsEmphasis: Color(0xFFBF3989),
    borderColorSponsorsMuted: Color(0x66FF80C8),
    borderColorSuccessEmphasis: Color(0xFF1A7F37),
    borderColorSuccessMuted: Color(0x664AC26B),
    borderColorTranslucent: Color(0x261F2328),
    borderColorTransparent: Color(0x00FFFFFF),
    borderColorUpsellEmphasis: Color(0xFF8250DF),
    borderColorUpsellMuted: Color(0x66C297FF),
    buttonDangerBgColorActive: Color(0xFFA40E26),
    buttonDangerBgColorDisabled: Color(0xFFEFF2F5),
    buttonDangerBgColorHover: Color(0xFFCF222E),
    buttonDangerBgColorRest: Color(0xFFF6F8FA),
    buttonDangerBorderColorActive: Color(0x261F2328),
    buttonDangerBorderColorHover: Color(0x261F2328),
    buttonDangerBorderColorRest: Color(0xFFD1D9E0),
    buttonDangerFgColorActive: Color(0xFFFFFFFF),
    buttonDangerFgColorDisabled: Color(0x80D1242F),
    buttonDangerFgColorHover: Color(0xFFFFFFFF),
    buttonDangerFgColorRest: Color(0xFFD1242F),
    buttonDangerIconColorDisabled: Color(0x80D1242F),
    buttonDangerIconColorHover: Color(0xFFFFFFFF),
    buttonDangerIconColorRest: Color(0xFFD1242F),
    buttonDefaultBgColorActive: Color(0xFFE6EAEF),
    buttonDefaultBgColorDisabled: Color(0xFFEFF2F5),
    buttonDefaultBgColorHover: Color(0xFFEFF2F5),
    buttonDefaultBgColorRest: Color(0xFFF6F8FA),
    buttonDefaultBgColorSelected: Color(0xFFE6EAEF),
    buttonDefaultBorderColorActive: Color(0xFFD1D9E0),
    buttonDefaultBorderColorDisabled: Color(0x1A818B98),
    buttonDefaultBorderColorHover: Color(0xFFD1D9E0),
    buttonDefaultBorderColorRest: Color(0xFFD1D9E0),
    buttonDefaultFgColorDisabled: Color(0xFF818B98),
    buttonDefaultFgColorRest: Color(0xFF25292E),
    buttonInactiveBgColor: Color(0xFFE6EAEF),
    buttonInactiveFgColor: Color(0xFF59636E),
    buttonInvisibleBgColorActive: Color(0x26818B98),
    buttonInvisibleBgColorDisabled: Color(0x00FFFFFF),
    buttonInvisibleBgColorHover: Color(0x1A818B98),
    buttonInvisibleBgColorRest: Color(0x00FFFFFF),
    buttonInvisibleBorderColorDisabled: Color(0x00FFFFFF),
    buttonInvisibleBorderColorHover: Color(0x00FFFFFF),
    buttonInvisibleBorderColorRest: Color(0x00FFFFFF),
    buttonInvisibleFgColorActive: Color(0xFF25292E),
    buttonInvisibleFgColorDisabled: Color(0xFF818B98),
    buttonInvisibleFgColorHover: Color(0xFF25292E),
    buttonInvisibleFgColorRest: Color(0xFF25292E),
    buttonInvisibleIconColorDisabled: Color(0xFF818B98),
    buttonInvisibleIconColorHover: Color(0xFF59636E),
    buttonInvisibleIconColorRest: Color(0xFF59636E),
    buttonOutlineBgColorActive: Color(0xFF0757BA),
    buttonOutlineBgColorDisabled: Color(0xFFEFF2F5),
    buttonOutlineBgColorHover: Color(0xFF0969DA),
    buttonOutlineBgColorRest: Color(0xFFF6F8FA),
    buttonOutlineBorderColorActive: Color(0x261F2328),
    buttonOutlineBorderColorHover: Color(0x261F2328),
    buttonOutlineFgColorActive: Color(0xFFFFFFFF),
    buttonOutlineFgColorDisabled: Color(0x800969DA),
    buttonOutlineFgColorHover: Color(0xFFFFFFFF),
    buttonOutlineFgColorRest: Color(0xFF0969DA),
    buttonPrimaryBgColorActive: Color(0xFF197935),
    buttonPrimaryBgColorDisabled: Color(0xFF95D8A6),
    buttonPrimaryBgColorHover: Color(0xFF1C8139),
    buttonPrimaryBgColorRest: Color(0xFF1F883D),
    buttonPrimaryBorderColorActive: Color(0x261F2328),
    buttonPrimaryBorderColorDisabled: Color(0xFF95D8A6),
    buttonPrimaryBorderColorHover: Color(0x261F2328),
    buttonPrimaryBorderColorRest: Color(0x261F2328),
    buttonPrimaryFgColorDisabled: Color(0xCCFFFFFF),
    buttonPrimaryFgColorRest: Color(0xFFFFFFFF),
    buttonPrimaryIconColorDisabled: Color(0xCCFFFFFF),
    buttonPrimaryIconColorRest: Color(0xCCFFFFFF),
    buttonStarIconColor: Color(0xFFEAC54F),
    buttonCounterDangerBgColorDisabled: Color(0x0DCF222E),
    buttonCounterDangerBgColorHover: Color(0x33FFFFFF),
    buttonCounterDangerBgColorRest: Color(0x1ACF222E),
    buttonCounterDangerFgColorDisabled: Color(0x80D1242F),
    buttonCounterDangerFgColorHover: Color(0xFFFFFFFF),
    buttonCounterDangerFgColorRest: Color(0xFFC21C2C),
    buttonCounterDefaultBgColorRest: Color(0x1F818B98),
    buttonCounterInvisibleBgColorRest: Color(0x1F818B98),
    buttonCounterOutlineBgColorDisabled: Color(0x0D0969DA),
    buttonCounterOutlineBgColorHover: Color(0x33FFFFFF),
    buttonCounterOutlineBgColorRest: Color(0x1A0969DA),
    buttonCounterOutlineFgColorDisabled: Color(0x800969DA),
    buttonCounterOutlineFgColorHover: Color(0xFFFFFFFF),
    buttonCounterOutlineFgColorRest: Color(0xFF0550AE),
    buttonCounterPrimaryBgColorRest: Color(0x33002D11),
    buttonKeybindingHintDangerBgColorActive: Color(0x661F2328),
    buttonKeybindingHintDangerBgColorDisabled: Color(0xFFEFF2F5),
    buttonKeybindingHintDangerBgColorHover: Color(0x331F2328),
    buttonKeybindingHintDangerBgColorRest: Color(0xFFEFF2F5),
    buttonKeybindingHintDangerBorderColorActive: Color(0x261F2328),
    buttonKeybindingHintDangerBorderColorDisabled: Color(0x1A818B98),
    buttonKeybindingHintDangerBorderColorHover: Color(0x261F2328),
    buttonKeybindingHintDangerBorderColorRest: Color(0xB3D1D9E0),
    buttonKeybindingHintDangerFgColorActive: Color(0xFFFFFFFF),
    buttonKeybindingHintDangerFgColorDisabled: Color(0xFF818B98),
    buttonKeybindingHintDangerFgColorHover: Color(0xFFFFFFFF),
    buttonKeybindingHintDangerFgColorRest: Color(0xFF59636E),
    buttonKeybindingHintDefaultBgColorDisabled: Color(0xFFEFF2F5),
    buttonKeybindingHintDefaultBgColorRest: Color(0xFFEFF2F5),
    buttonKeybindingHintDefaultBorderColorDisabled: Color(0x1A818B98),
    buttonKeybindingHintDefaultBorderColorRest: Color(0xB3D1D9E0),
    buttonKeybindingHintDefaultFgColorDisabled: Color(0xFF818B98),
    buttonKeybindingHintDefaultFgColorRest: Color(0xFF59636E),
    buttonKeybindingHintInactiveBgColor: Color(0xFFEFF2F5),
    buttonKeybindingHintInactiveBorderColor: Color(0xB3D1D9E0),
    buttonKeybindingHintInactiveFgColor: Color(0xFF59636E),
    buttonKeybindingHintInvisibleBgColorActive: Color(0x26818B98),
    buttonKeybindingHintInvisibleBgColorDisabled: Color(0x00FFFFFF),
    buttonKeybindingHintInvisibleBgColorHover: Color(0x1A818B98),
    buttonKeybindingHintInvisibleBgColorRest: Color(0xFFEFF2F5),
    buttonKeybindingHintInvisibleBorderColorDisabled: Color(0x1A818B98),
    buttonKeybindingHintInvisibleBorderColorRest: Color(0x00FFFFFF),
    buttonKeybindingHintInvisibleFgColorDisabled: Color(0xFF818B98),
    buttonKeybindingHintInvisibleFgColorRest: Color(0xFF59636E),
    buttonKeybindingHintPrimaryBgColorDisabled: Color(0x1A002D11),
    buttonKeybindingHintPrimaryBgColorRest: Color(0x33002D11),
    buttonKeybindingHintPrimaryBorderColorDisabled: Color(0x1A818B98),
    buttonKeybindingHintPrimaryBorderColorRest: Color(0x261F2328),
    buttonKeybindingHintPrimaryFgColorDisabled: Color(0xCCFFFFFF),
    buttonKeybindingHintPrimaryFgColorRest: Color(0xFFFFFFFF),
    cardBgColor: Color(0xFFFFFFFF),
    codeMirrorActivelineBgColor: Color(0x1F818B98),
    codeMirrorBgColor: Color(0xFFFFFFFF),
    codeMirrorCursorFgColor: Color(0xFF1F2328),
    codeMirrorFgColor: Color(0xFF1F2328),
    codeMirrorGutterMarkerFgColorDefault: Color(0xFFFFFFFF),
    codeMirrorGutterMarkerFgColorMuted: Color(0xFF59636E),
    codeMirrorGuttersBgColor: Color(0xFFFFFFFF),
    codeMirrorLineNumberFgColor: Color(0xFF59636E),
    codeMirrorLinesBgColor: Color(0xFFFFFFFF),
    codeMirrorMatchingBracketFgColor: Color(0xFF1F2328),
    codeMirrorSelectionBgColor: Color(0x6654AEFF),
    codeMirrorSyntaxFgColorComment: Color(0xFF1F2328),
    codeMirrorSyntaxFgColorConstant: Color(0xFF0550AE),
    codeMirrorSyntaxFgColorEntity: Color(0xFF8250DF),
    codeMirrorSyntaxFgColorKeyword: Color(0xFFCF222E),
    codeMirrorSyntaxFgColorStorage: Color(0xFFCF222E),
    codeMirrorSyntaxFgColorString: Color(0xFF0A3069),
    codeMirrorSyntaxFgColorSupport: Color(0xFF0550AE),
    codeMirrorSyntaxFgColorVariable: Color(0xFF953800),
    colorAnsiBlack: Color(0xFF1F2328),
    colorAnsiBlackBright: Color(0xFF393F46),
    colorAnsiBlue: Color(0xFF0969DA),
    colorAnsiBlueBright: Color(0xFF218BFF),
    colorAnsiCyan: Color(0xFF1B7C83),
    colorAnsiCyanBright: Color(0xFF3192AA),
    colorAnsiGray: Color(0xFF59636E),
    colorAnsiGreen: Color(0xFF116329),
    colorAnsiGreenBright: Color(0xFF1A7F37),
    colorAnsiMagenta: Color(0xFF8250DF),
    colorAnsiMagentaBright: Color(0xFFA475F9),
    colorAnsiRed: Color(0xFFCF222E),
    colorAnsiRedBright: Color(0xFFA40E26),
    colorAnsiWhite: Color(0xFF59636E),
    colorAnsiWhiteBright: Color(0xFF818B98),
    colorAnsiYellow: Color(0xFF4D2D00),
    colorAnsiYellowBright: Color(0xFF633C01),
    colorPrettylightsSyntaxBrackethighlighterAngle: Color(0xFF59636E),
    colorPrettylightsSyntaxBrackethighlighterUnmatched: Color(0xFF82071E),
    colorPrettylightsSyntaxCarriageReturnBg: Color(0xFFCF222E),
    colorPrettylightsSyntaxCarriageReturnText: Color(0xFFF6F8FA),
    colorPrettylightsSyntaxComment: Color(0xFF59636E),
    colorPrettylightsSyntaxConstant: Color(0xFF0550AE),
    colorPrettylightsSyntaxConstantOtherReferenceLink: Color(0xFF0A3069),
    colorPrettylightsSyntaxEntity: Color(0xFF6639BA),
    colorPrettylightsSyntaxEntityTag: Color(0xFF0550AE),
    colorPrettylightsSyntaxInvalidIllegalBg: Color(0xFFFFEBE9),
    colorPrettylightsSyntaxInvalidIllegalText: Color(0xFFD1242F),
    colorPrettylightsSyntaxKeyword: Color(0xFFCF222E),
    colorPrettylightsSyntaxMarkupBold: Color(0xFF1F2328),
    colorPrettylightsSyntaxMarkupChangedBg: Color(0xFFFFD8B5),
    colorPrettylightsSyntaxMarkupChangedText: Color(0xFF953800),
    colorPrettylightsSyntaxMarkupDeletedBg: Color(0xFFFFEBE9),
    colorPrettylightsSyntaxMarkupDeletedText: Color(0xFF82071E),
    colorPrettylightsSyntaxMarkupHeading: Color(0xFF0550AE),
    colorPrettylightsSyntaxMarkupIgnoredBg: Color(0xFF0550AE),
    colorPrettylightsSyntaxMarkupIgnoredText: Color(0xFFD1D9E0),
    colorPrettylightsSyntaxMarkupInsertedBg: Color(0xFFDAFBE1),
    colorPrettylightsSyntaxMarkupInsertedText: Color(0xFF116329),
    colorPrettylightsSyntaxMarkupItalic: Color(0xFF1F2328),
    colorPrettylightsSyntaxMarkupList: Color(0xFF3B2300),
    colorPrettylightsSyntaxMetaDiffRange: Color(0xFF8250DF),
    colorPrettylightsSyntaxStorageModifierImport: Color(0xFF1F2328),
    colorPrettylightsSyntaxString: Color(0xFF0A3069),
    colorPrettylightsSyntaxStringRegexp: Color(0xFF116329),
    colorPrettylightsSyntaxSublimelinterGutterMark: Color(0xFF818B98),
    colorPrettylightsSyntaxVariable: Color(0xFF953800),
    contributionDefaultBgColor0: Color(0xFFEFF2F5),
    contributionDefaultBgColor1: Color(0xFFACEEBB),
    contributionDefaultBgColor2: Color(0xFF4AC26B),
    contributionDefaultBgColor3: Color(0xFF2DA44E),
    contributionDefaultBgColor4: Color(0xFF116329),
    contributionDefaultBorderColor0: Color(0x0D1F2328),
    contributionDefaultBorderColor1: Color(0x0D1F2328),
    contributionDefaultBorderColor2: Color(0x0D1F2328),
    contributionDefaultBorderColor3: Color(0x0D1F2328),
    contributionDefaultBorderColor4: Color(0x0D1F2328),
    contributionHalloweenBgColor1: Color(0xFFF0DB3D),
    contributionHalloweenBgColor2: Color(0xFFFFD642),
    contributionHalloweenBgColor3: Color(0xFFF68C41),
    contributionHalloweenBgColor4: Color(0xFF1F2328),
    contributionWinterBgColor1: Color(0xFFB6E3FF),
    contributionWinterBgColor2: Color(0xFF54AEFF),
    contributionWinterBgColor3: Color(0xFF0969DA),
    contributionWinterBgColor4: Color(0xFF0A3069),
    controlBgColorActive: Color(0xFFE6EAEF),
    controlBgColorDisabled: Color(0xFFEFF2F5),
    controlBgColorHover: Color(0xFFEFF2F5),
    controlBgColorRest: Color(0xFFF6F8FA),
    controlBgColorSelected: Color(0xFFF6F8FA),
    controlBorderColorDanger: Color(0xFFCF222E),
    controlBorderColorDisabled: Color(0x1A818B98),
    controlBorderColorEmphasis: Color(0xFF818B98),
    controlBorderColorRest: Color(0xFFD1D9E0),
    controlBorderColorSelected: Color(0xFFF6F8FA),
    controlBorderColorSuccess: Color(0xFF1A7F37),
    controlBorderColorWarning: Color(0xFF9A6700),
    controlCheckedBgColorActive: Color(0xFF0757BA),
    controlCheckedBgColorDisabled: Color(0xFF818B98),
    controlCheckedBgColorHover: Color(0xFF0860CA),
    controlCheckedBgColorRest: Color(0xFF0969DA),
    controlCheckedBorderColorActive: Color(0xFF0757BA),
    controlCheckedBorderColorDisabled: Color(0xFF818B98),
    controlCheckedBorderColorHover: Color(0xFF0860CA),
    controlCheckedBorderColorRest: Color(0xFF0969DA),
    controlCheckedFgColorDisabled: Color(0xFFFFFFFF),
    controlCheckedFgColorRest: Color(0xFFFFFFFF),
    controlDangerBgColorActive: Color(0x66FFEBE9),
    controlDangerBgColorHover: Color(0xFFFFEBE9),
    controlDangerFgColorHover: Color(0xFFD1242F),
    controlDangerFgColorRest: Color(0xFFD1242F),
    controlFgColorDisabled: Color(0xFF818B98),
    controlFgColorPlaceholder: Color(0xFF59636E),
    controlFgColorRest: Color(0xFF25292E),
    controlIconColorRest: Color(0xFF59636E),
    controlTransparentBgColorActive: Color(0x26818B98),
    controlTransparentBgColorDisabled: Color(0xFFEFF2F5),
    controlTransparentBgColorHover: Color(0x1A818B98),
    controlTransparentBgColorRest: Color(0x00FFFFFF),
    controlTransparentBgColorSelected: Color(0x26818B98),
    controlTransparentBorderColorActive: Color(0x00FFFFFF),
    controlTransparentBorderColorHover: Color(0x00FFFFFF),
    controlTransparentBorderColorRest: Color(0x00FFFFFF),
    controlKnobBgColorChecked: Color(0xFFFFFFFF),
    controlKnobBgColorDisabled: Color(0xFFEFF2F5),
    controlKnobBgColorRest: Color(0xFFFFFFFF),
    controlKnobBorderColorChecked: Color(0xFF0969DA),
    controlKnobBorderColorDisabled: Color(0xFFEFF2F5),
    controlKnobBorderColorRest: Color(0xFFD1D9E0),
    controlTrackBgColorActive: Color(0xFFDAE0E7),
    controlTrackBgColorDisabled: Color(0xFF818B98),
    controlTrackBgColorHover: Color(0xFFE0E6EB),
    controlTrackBgColorRest: Color(0xFFE6EAEF),
    controlTrackBorderColorDisabled: Color(0xFF818B98),
    controlTrackBorderColorRest: Color(0xFFD1D9E0),
    controlTrackFgColorDisabled: Color(0xFFFFFFFF),
    controlTrackFgColorRest: Color(0xFF59636E),
    counterBgColorEmphasis: Color(0xFF59636E),
    counterBgColorMuted: Color(0x1F818B98),
    counterBorderColor: Color(0x00FFFFFF),
    dashboardBgColor: Color(0xFFFFFFFF),
    dataAuburnColorEmphasis: Color(0xFF9D615C),
    dataAuburnColorMuted: Color(0xFFF2E9E9),
    dataBlueColorEmphasis: Color(0xFF006EDB),
    dataBlueColorMuted: Color(0xFFD1F0FF),
    dataBrownColorEmphasis: Color(0xFF856D4C),
    dataBrownColorMuted: Color(0xFFEEEAE2),
    dataCoralColorEmphasis: Color(0xFFD43511),
    dataCoralColorMuted: Color(0xFFFFE5DB),
    dataGrayColorEmphasis: Color(0xFF808FA3),
    dataGrayColorMuted: Color(0xFFE8ECF2),
    dataGreenColorEmphasis: Color(0xFF30A147),
    dataGreenColorMuted: Color(0xFFCAF7CA),
    dataLemonColorEmphasis: Color(0xFF866E04),
    dataLemonColorMuted: Color(0xFFF7EEA1),
    dataLimeColorEmphasis: Color(0xFF527A29),
    dataLimeColorMuted: Color(0xFFE3F2B5),
    dataOliveColorEmphasis: Color(0xFF64762D),
    dataOliveColorMuted: Color(0xFFF0F0AD),
    dataOrangeColorEmphasis: Color(0xFFEB670F),
    dataOrangeColorMuted: Color(0xFFFFE7D1),
    dataPineColorEmphasis: Color(0xFF167E53),
    dataPineColorMuted: Color(0xFFBFF8DB),
    dataPinkColorEmphasis: Color(0xFFCE2C85),
    dataPinkColorMuted: Color(0xFFFFE5F1),
    dataPlumColorEmphasis: Color(0xFFA830E8),
    dataPlumColorMuted: Color(0xFFF8E5FF),
    dataPurpleColorEmphasis: Color(0xFF894CEB),
    dataPurpleColorMuted: Color(0xFFF1E5FF),
    dataRedColorEmphasis: Color(0xFFDF0C24),
    dataRedColorMuted: Color(0xFFFFE2E0),
    dataTealColorEmphasis: Color(0xFF179B9B),
    dataTealColorMuted: Color(0xFFC7F5EF),
    dataYellowColorEmphasis: Color(0xFFB88700),
    dataYellowColorMuted: Color(0xFFFFEC9E),
    diffBlobAdditionLineBgColor: Color(0xFFDAFBE1),
    diffBlobAdditionLineFgColor: Color(0xFF1F2328),
    diffBlobAdditionNumBgColor: Color(0xFFACEEBB),
    diffBlobAdditionNumFgColor: Color(0xFF1F2328),
    diffBlobAdditionWordBgColor: Color(0xFFACEEBB),
    diffBlobAdditionWordFgColor: Color(0xFF1F2328),
    diffBlobDeletionLineBgColor: Color(0xFFFFEBE9),
    diffBlobDeletionLineFgColor: Color(0xFF1F2328),
    diffBlobDeletionNumBgColor: Color(0xFFFFCECB),
    diffBlobDeletionNumFgColor: Color(0xFF1F2328),
    diffBlobDeletionWordBgColor: Color(0xFFFFCECB),
    diffBlobDeletionWordFgColor: Color(0xFF1F2328),
    diffBlobEmptyLineBgColor: Color(0xFFF6F8FA),
    diffBlobEmptyNumBgColor: Color(0xFFF6F8FA),
    diffBlobExpanderIconColor: Color(0xFF59636E),
    diffBlobHunkLineBgColor: Color(0xFFDDF4FF),
    diffBlobHunkLineFgColor: Color(0xFF59636E),
    diffBlobHunkNumBgColorHover: Color(0xFF0969DA),
    diffBlobHunkNumBgColorRest: Color(0xFFB6E3FF),
    diffBlobHunkNumFgColorHover: Color(0xFFFFFFFF),
    diffBlobHunkNumFgColorRest: Color(0xFF1F2328),
    displayAuburnBgColorEmphasis: Color(0xFF9D615C),
    displayAuburnBgColorMuted: Color(0xFFF2E9E9),
    displayAuburnBorderColorEmphasis: Color(0xFF9D615C),
    displayAuburnBorderColorMuted: Color(0xFFE6D6D5),
    displayAuburnFgColor: Color(0xFF8A5551),
    displayAuburnScale0: Color(0xFFF2E9E9),
    displayAuburnScale1: Color(0xFFE6D6D5),
    displayAuburnScale2: Color(0xFFD4B7B5),
    displayAuburnScale3: Color(0xFFC59E9B),
    displayAuburnScale4: Color(0xFFB4827E),
    displayAuburnScale5: Color(0xFF9D615C),
    displayAuburnScale6: Color(0xFF8A5551),
    displayAuburnScale7: Color(0xFF744744),
    displayAuburnScale8: Color(0xFF5D3937),
    displayAuburnScale9: Color(0xFF432928),
    displayBlueBgColorEmphasis: Color(0xFF006EDB),
    displayBlueBgColorMuted: Color(0xFFD1F0FF),
    displayBlueBorderColorEmphasis: Color(0xFF006EDB),
    displayBlueBorderColorMuted: Color(0xFFADE1FF),
    displayBlueFgColor: Color(0xFF005FCC),
    displayBlueScale0: Color(0xFFD1F0FF),
    displayBlueScale1: Color(0xFFADE1FF),
    displayBlueScale2: Color(0xFF75C8FF),
    displayBlueScale3: Color(0xFF47AFFF),
    displayBlueScale4: Color(0xFF0F8FFF),
    displayBlueScale5: Color(0xFF006EDB),
    displayBlueScale6: Color(0xFF005FCC),
    displayBlueScale7: Color(0xFF004DB3),
    displayBlueScale8: Color(0xFF003D99),
    displayBlueScale9: Color(0xFF002B75),
    displayBrownBgColorEmphasis: Color(0xFF856D4C),
    displayBrownBgColorMuted: Color(0xFFEEEAE2),
    displayBrownBorderColorEmphasis: Color(0xFF856D4C),
    displayBrownBorderColorMuted: Color(0xFFDFD7C8),
    displayBrownFgColor: Color(0xFF755F43),
    displayBrownScale0: Color(0xFFEEEAE2),
    displayBrownScale1: Color(0xFFDFD7C8),
    displayBrownScale2: Color(0xFFCBBDA4),
    displayBrownScale3: Color(0xFFB8A484),
    displayBrownScale4: Color(0xFFA68B64),
    displayBrownScale5: Color(0xFF856D4C),
    displayBrownScale6: Color(0xFF755F43),
    displayBrownScale7: Color(0xFF64513A),
    displayBrownScale8: Color(0xFF51412F),
    displayBrownScale9: Color(0xFF3A2E22),
    displayCoralBgColorEmphasis: Color(0xFFD43511),
    displayCoralBgColorMuted: Color(0xFFFFE5DB),
    displayCoralBorderColorEmphasis: Color(0xFFD43511),
    displayCoralBorderColorMuted: Color(0xFFFECEBE),
    displayCoralFgColor: Color(0xFFBA2E12),
    displayCoralScale0: Color(0xFFFFE5DB),
    displayCoralScale1: Color(0xFFFECEBE),
    displayCoralScale2: Color(0xFFFCAB92),
    displayCoralScale3: Color(0xFFF88768),
    displayCoralScale4: Color(0xFFF25F3A),
    displayCoralScale5: Color(0xFFD43511),
    displayCoralScale6: Color(0xFFBA2E12),
    displayCoralScale7: Color(0xFF9B2712),
    displayCoralScale8: Color(0xFF7E2011),
    displayCoralScale9: Color(0xFF5D180E),
    displayCyanBgColorEmphasis: Color(0xFF007B94),
    displayCyanBgColorMuted: Color(0xFFBDF4FF),
    displayCyanBorderColorEmphasis: Color(0xFF007B94),
    displayCyanBorderColorMuted: Color(0xFF7AE9FF),
    displayCyanFgColor: Color(0xFF006A80),
    displayCyanScale0: Color(0xFFBDF4FF),
    displayCyanScale1: Color(0xFF7AE9FF),
    displayCyanScale2: Color(0xFF00D0FA),
    displayCyanScale3: Color(0xFF00B7DB),
    displayCyanScale4: Color(0xFF0099B8),
    displayCyanScale5: Color(0xFF007B94),
    displayCyanScale6: Color(0xFF006A80),
    displayCyanScale7: Color(0xFF00596B),
    displayCyanScale8: Color(0xFF004857),
    displayCyanScale9: Color(0xFF003742),
    displayGrayBgColorEmphasis: Color(0xFF647182),
    displayGrayBgColorMuted: Color(0xFFE8ECF2),
    displayGrayBorderColorEmphasis: Color(0xFF647182),
    displayGrayBorderColorMuted: Color(0xFFD2DAE4),
    displayGrayFgColor: Color(0xFF5C6570),
    displayGrayScale0: Color(0xFFE8ECF2),
    displayGrayScale1: Color(0xFFD2DAE4),
    displayGrayScale2: Color(0xFFB4C0CF),
    displayGrayScale3: Color(0xFF9BA9BB),
    displayGrayScale4: Color(0xFF808FA3),
    displayGrayScale5: Color(0xFF647182),
    displayGrayScale6: Color(0xFF5C6570),
    displayGrayScale7: Color(0xFF4E535A),
    displayGrayScale8: Color(0xFF424448),
    displayGrayScale9: Color(0xFF303031),
    displayGreenBgColorEmphasis: Color(0xFF2C8141),
    displayGreenBgColorMuted: Color(0xFFCAF7CA),
    displayGreenBorderColorEmphasis: Color(0xFF2C8141),
    displayGreenBorderColorMuted: Color(0xFF9CEDA0),
    displayGreenFgColor: Color(0xFF2B6E3F),
    displayGreenScale0: Color(0xFFCAF7CA),
    displayGreenScale1: Color(0xFF9CEDA0),
    displayGreenScale2: Color(0xFF54D961),
    displayGreenScale3: Color(0xFF31BF46),
    displayGreenScale4: Color(0xFF30A147),
    displayGreenScale5: Color(0xFF2C8141),
    displayGreenScale6: Color(0xFF2B6E3F),
    displayGreenScale7: Color(0xFF285C3B),
    displayGreenScale8: Color(0xFF254B34),
    displayGreenScale9: Color(0xFF1D3528),
    displayIndigoBgColorEmphasis: Color(0xFF5A61E7),
    displayIndigoBgColorMuted: Color(0xFFE5E9FF),
    displayIndigoBorderColorEmphasis: Color(0xFF5A61E7),
    displayIndigoBorderColorMuted: Color(0xFFD2D7FE),
    displayIndigoFgColor: Color(0xFF494EDF),
    displayIndigoScale0: Color(0xFFE5E9FF),
    displayIndigoScale1: Color(0xFFD2D7FE),
    displayIndigoScale2: Color(0xFFB1B9FB),
    displayIndigoScale3: Color(0xFF979FF7),
    displayIndigoScale4: Color(0xFF7A82F0),
    displayIndigoScale5: Color(0xFF5A61E7),
    displayIndigoScale6: Color(0xFF494EDF),
    displayIndigoScale7: Color(0xFF393CD5),
    displayIndigoScale8: Color(0xFF2D2DB4),
    displayIndigoScale9: Color(0xFF25247B),
    displayLemonBgColorEmphasis: Color(0xFF866E04),
    displayLemonBgColorMuted: Color(0xFFF7EEA1),
    displayLemonBorderColorEmphasis: Color(0xFF866E04),
    displayLemonBorderColorMuted: Color(0xFFF0DB3D),
    displayLemonFgColor: Color(0xFF786002),
    displayLemonScale0: Color(0xFFF7EEA1),
    displayLemonScale1: Color(0xFFF0DB3D),
    displayLemonScale2: Color(0xFFD8BD0E),
    displayLemonScale3: Color(0xFFC2A60A),
    displayLemonScale4: Color(0xFFA68C07),
    displayLemonScale5: Color(0xFF866E04),
    displayLemonScale6: Color(0xFF786002),
    displayLemonScale7: Color(0xFF654F01),
    displayLemonScale8: Color(0xFF523F00),
    displayLemonScale9: Color(0xFF3D2E00),
    displayLimeBgColorEmphasis: Color(0xFF527A29),
    displayLimeBgColorMuted: Color(0xFFE3F2B5),
    displayLimeBorderColorEmphasis: Color(0xFF527A29),
    displayLimeBorderColorMuted: Color(0xFFC7E580),
    displayLimeFgColor: Color(0xFF476C28),
    displayLimeScale0: Color(0xFFE3F2B5),
    displayLimeScale1: Color(0xFFC7E580),
    displayLimeScale2: Color(0xFF9BD039),
    displayLimeScale3: Color(0xFF80B530),
    displayLimeScale4: Color(0xFF6C9D2F),
    displayLimeScale5: Color(0xFF527A29),
    displayLimeScale6: Color(0xFF476C28),
    displayLimeScale7: Color(0xFF3A5B25),
    displayLimeScale8: Color(0xFF2F4A21),
    displayLimeScale9: Color(0xFF213319),
    displayOliveBgColorEmphasis: Color(0xFF64762D),
    displayOliveBgColorMuted: Color(0xFFF0F0AD),
    displayOliveBorderColorEmphasis: Color(0xFF64762D),
    displayOliveBorderColorMuted: Color(0xFFDBE170),
    displayOliveFgColor: Color(0xFF56682C),
    displayOliveScale0: Color(0xFFF0F0AD),
    displayOliveScale1: Color(0xFFDBE170),
    displayOliveScale2: Color(0xFFB9C832),
    displayOliveScale3: Color(0xFF9BAE32),
    displayOliveScale4: Color(0xFF819532),
    displayOliveScale5: Color(0xFF64762D),
    displayOliveScale6: Color(0xFF56682C),
    displayOliveScale7: Color(0xFF495A2B),
    displayOliveScale8: Color(0xFF3B4927),
    displayOliveScale9: Color(0xFF2A331F),
    displayOrangeBgColorEmphasis: Color(0xFFB8500F),
    displayOrangeBgColorMuted: Color(0xFFFFE7D1),
    displayOrangeBorderColorEmphasis: Color(0xFFB8500F),
    displayOrangeBorderColorMuted: Color(0xFFFECFAA),
    displayOrangeFgColor: Color(0xFFA24610),
    displayOrangeScale0: Color(0xFFFFE7D1),
    displayOrangeScale1: Color(0xFFFECFAA),
    displayOrangeScale2: Color(0xFFFBAF74),
    displayOrangeScale3: Color(0xFFF68C41),
    displayOrangeScale4: Color(0xFFEB670F),
    displayOrangeScale5: Color(0xFFB8500F),
    displayOrangeScale6: Color(0xFFA24610),
    displayOrangeScale7: Color(0xFF8D3C11),
    displayOrangeScale8: Color(0xFF70300F),
    displayOrangeScale9: Color(0xFF54230D),
    displayPineBgColorEmphasis: Color(0xFF167E53),
    displayPineBgColorMuted: Color(0xFFBFF8DB),
    displayPineBorderColorEmphasis: Color(0xFF167E53),
    displayPineBorderColorMuted: Color(0xFF80EFB9),
    displayPineFgColor: Color(0xFF156F4B),
    displayPineScale0: Color(0xFFBFF8DB),
    displayPineScale1: Color(0xFF80EFB9),
    displayPineScale2: Color(0xFF1DD781),
    displayPineScale3: Color(0xFF1DBF76),
    displayPineScale4: Color(0xFF1AA267),
    displayPineScale5: Color(0xFF167E53),
    displayPineScale6: Color(0xFF156F4B),
    displayPineScale7: Color(0xFF135D41),
    displayPineScale8: Color(0xFF114B36),
    displayPineScale9: Color(0xFF0D3627),
    displayPinkBgColorEmphasis: Color(0xFFCE2C85),
    displayPinkBgColorMuted: Color(0xFFFFE5F1),
    displayPinkBorderColorEmphasis: Color(0xFFCE2C85),
    displayPinkBorderColorMuted: Color(0xFFFDC9E2),
    displayPinkFgColor: Color(0xFFB12F79),
    displayPinkScale0: Color(0xFFFFE5F1),
    displayPinkScale1: Color(0xFFFDC9E2),
    displayPinkScale2: Color(0xFFF8A5CF),
    displayPinkScale3: Color(0xFFF184BC),
    displayPinkScale4: Color(0xFFE55DA5),
    displayPinkScale5: Color(0xFFCE2C85),
    displayPinkScale6: Color(0xFFB12F79),
    displayPinkScale7: Color(0xFF8E2E66),
    displayPinkScale8: Color(0xFF6E2B53),
    displayPinkScale9: Color(0xFF4D233D),
    displayPlumBgColorEmphasis: Color(0xFFA830E8),
    displayPlumBgColorMuted: Color(0xFFF8E5FF),
    displayPlumBorderColorEmphasis: Color(0xFFA830E8),
    displayPlumBorderColorMuted: Color(0xFFF0CDFE),
    displayPlumFgColor: Color(0xFF961EDC),
    displayPlumScale0: Color(0xFFF8E5FF),
    displayPlumScale1: Color(0xFFF0CDFE),
    displayPlumScale2: Color(0xFFE2A7FB),
    displayPlumScale3: Color(0xFFD487F7),
    displayPlumScale4: Color(0xFFC264F2),
    displayPlumScale5: Color(0xFFA830E8),
    displayPlumScale6: Color(0xFF961EDC),
    displayPlumScale7: Color(0xFF7D1EB8),
    displayPlumScale8: Color(0xFF651D96),
    displayPlumScale9: Color(0xFF471769),
    displayPurpleBgColorEmphasis: Color(0xFF894CEB),
    displayPurpleBgColorMuted: Color(0xFFF1E5FF),
    displayPurpleBorderColorEmphasis: Color(0xFF894CEB),
    displayPurpleBorderColorMuted: Color(0xFFE6D2FE),
    displayPurpleFgColor: Color(0xFF783AE4),
    displayPurpleScale0: Color(0xFFF1E5FF),
    displayPurpleScale1: Color(0xFFE6D2FE),
    displayPurpleScale2: Color(0xFFD1B1FC),
    displayPurpleScale3: Color(0xFFBC91F8),
    displayPurpleScale4: Color(0xFFA672F3),
    displayPurpleScale5: Color(0xFF894CEB),
    displayPurpleScale6: Color(0xFF783AE4),
    displayPurpleScale7: Color(0xFF6223D7),
    displayPurpleScale8: Color(0xFF4F21AB),
    displayPurpleScale9: Color(0xFF391B79),
    displayRedBgColorEmphasis: Color(0xFFDF0C24),
    displayRedBgColorMuted: Color(0xFFFFE2E0),
    displayRedBorderColorEmphasis: Color(0xFFDF0C24),
    displayRedBorderColorMuted: Color(0xFFFECDCD),
    displayRedFgColor: Color(0xFFC50D28),
    displayRedScale0: Color(0xFFFFE2E0),
    displayRedScale1: Color(0xFFFECDCD),
    displayRedScale2: Color(0xFFFDA5A7),
    displayRedScale3: Color(0xFFFB8389),
    displayRedScale4: Color(0xFFF85461),
    displayRedScale5: Color(0xFFDF0C24),
    displayRedScale6: Color(0xFFC50D28),
    displayRedScale7: Color(0xFFA60C29),
    displayRedScale8: Color(0xFF880C27),
    displayRedScale9: Color(0xFF610A20),
    displayTealBgColorEmphasis: Color(0xFF127E81),
    displayTealBgColorMuted: Color(0xFFC7F5EF),
    displayTealBorderColorEmphasis: Color(0xFF127E81),
    displayTealBorderColorMuted: Color(0xFF89EBE1),
    displayTealFgColor: Color(0xFF106E75),
    displayTealScale0: Color(0xFFC7F5EF),
    displayTealScale1: Color(0xFF89EBE1),
    displayTealScale2: Color(0xFF22D3C7),
    displayTealScale3: Color(0xFF1DB9B4),
    displayTealScale4: Color(0xFF179B9B),
    displayTealScale5: Color(0xFF127E81),
    displayTealScale6: Color(0xFF106E75),
    displayTealScale7: Color(0xFF0D5B63),
    displayTealScale8: Color(0xFF0A4852),
    displayTealScale9: Color(0xFF073740),
    displayYellowBgColorEmphasis: Color(0xFF946A00),
    displayYellowBgColorMuted: Color(0xFFFFEC9E),
    displayYellowBorderColorEmphasis: Color(0xFF946A00),
    displayYellowBorderColorMuted: Color(0xFFFFD642),
    displayYellowFgColor: Color(0xFF805900),
    displayYellowScale0: Color(0xFFFFEC9E),
    displayYellowScale1: Color(0xFFFFD642),
    displayYellowScale2: Color(0xFFEBB400),
    displayYellowScale3: Color(0xFFD19D00),
    displayYellowScale4: Color(0xFFB88700),
    displayYellowScale5: Color(0xFF946A00),
    displayYellowScale6: Color(0xFF805900),
    displayYellowScale7: Color(0xFF704D00),
    displayYellowScale8: Color(0xFF5C3D00),
    displayYellowScale9: Color(0xFF422B00),
    fgColorAccent: Color(0xFF0969DA),
    fgColorAttention: Color(0xFF9A6700),
    fgColorBlack: Color(0xFF1F2328),
    fgColorClosed: Color(0xFFD1242F),
    fgColorDanger: Color(0xFFD1242F),
    fgColorDefault: Color(0xFF1F2328),
    fgColorDisabled: Color(0xFF818B98),
    fgColorDone: Color(0xFF8250DF),
    fgColorDraft: Color(0xFF59636E),
    fgColorLink: Color(0xFF0969DA),
    fgColorMuted: Color(0xFF59636E),
    fgColorNeutral: Color(0xFF59636E),
    fgColorOnEmphasis: Color(0xFFFFFFFF),
    fgColorOnInverse: Color(0xFFFFFFFF),
    fgColorOpen: Color(0xFF1A7F37),
    fgColorSevere: Color(0xFFBC4C00),
    fgColorSponsors: Color(0xFFBF3989),
    fgColorSuccess: Color(0xFF1A7F37),
    fgColorUpsell: Color(0xFF8250DF),
    fgColorWhite: Color(0xFFFFFFFF),
    focusOutlineColor: Color(0xFF0969DA),
    headerBgColor: Color(0xFF25292E),
    headerBorderColorDivider: Color(0xFF818B98),
    headerFgColorDefault: Color(0xB3FFFFFF),
    headerFgColorLogo: Color(0xFFFFFFFF),
    headerSearchBgColor: Color(0xFF25292E),
    headerSearchBorderColor: Color(0xFF818B98),
    highlightNeutralBgColor: Color(0xFFFFF8C5),
    labelAuburnBgColorActive: Color(0xFFD4B7B5),
    labelAuburnBgColorHover: Color(0xFFE6D6D5),
    labelAuburnBgColorRest: Color(0xFFF2E9E9),
    labelAuburnBorderColor: Color(0x00FFFFFF),
    labelAuburnFgColorActive: Color(0xFF5D3937),
    labelAuburnFgColorHover: Color(0xFF744744),
    labelAuburnFgColorRest: Color(0xFF8A5551),
    labelBlueBgColorActive: Color(0xFF75C8FF),
    labelBlueBgColorHover: Color(0xFFADE1FF),
    labelBlueBgColorRest: Color(0xFFD1F0FF),
    labelBlueBorderColor: Color(0x00FFFFFF),
    labelBlueFgColorActive: Color(0xFF003D99),
    labelBlueFgColorHover: Color(0xFF004DB3),
    labelBlueFgColorRest: Color(0xFF005FCC),
    labelBrownBgColorActive: Color(0xFFCBBDA4),
    labelBrownBgColorHover: Color(0xFFDFD7C8),
    labelBrownBgColorRest: Color(0xFFEEEAE2),
    labelBrownBorderColor: Color(0x00FFFFFF),
    labelBrownFgColorActive: Color(0xFF51412F),
    labelBrownFgColorHover: Color(0xFF64513A),
    labelBrownFgColorRest: Color(0xFF755F43),
    labelCoralBgColorActive: Color(0xFFFCAB92),
    labelCoralBgColorHover: Color(0xFFFECEBE),
    labelCoralBgColorRest: Color(0xFFFFE5DB),
    labelCoralBorderColor: Color(0x00FFFFFF),
    labelCoralFgColorActive: Color(0xFF7E2011),
    labelCoralFgColorHover: Color(0xFF9B2712),
    labelCoralFgColorRest: Color(0xFFBA2E12),
    labelCyanBgColorActive: Color(0xFF00D0FA),
    labelCyanBgColorHover: Color(0xFF7AE9FF),
    labelCyanBgColorRest: Color(0xFFBDF4FF),
    labelCyanBorderColor: Color(0x00FFFFFF),
    labelCyanFgColorActive: Color(0xFF004857),
    labelCyanFgColorHover: Color(0xFF00596B),
    labelCyanFgColorRest: Color(0xFF006A80),
    labelGrayBgColorActive: Color(0xFFB4C0CF),
    labelGrayBgColorHover: Color(0xFFD2DAE4),
    labelGrayBgColorRest: Color(0xFFE8ECF2),
    labelGrayBorderColor: Color(0x00FFFFFF),
    labelGrayFgColorActive: Color(0xFF424448),
    labelGrayFgColorHover: Color(0xFF4E535A),
    labelGrayFgColorRest: Color(0xFF5C6570),
    labelGreenBgColorActive: Color(0xFF54D961),
    labelGreenBgColorHover: Color(0xFF9CEDA0),
    labelGreenBgColorRest: Color(0xFFCAF7CA),
    labelGreenBorderColor: Color(0x00FFFFFF),
    labelGreenFgColorActive: Color(0xFF254B34),
    labelGreenFgColorHover: Color(0xFF285C3B),
    labelGreenFgColorRest: Color(0xFF2B6E3F),
    labelIndigoBgColorActive: Color(0xFFB1B9FB),
    labelIndigoBgColorHover: Color(0xFFD2D7FE),
    labelIndigoBgColorRest: Color(0xFFE5E9FF),
    labelIndigoBorderColor: Color(0x00FFFFFF),
    labelIndigoFgColorActive: Color(0xFF2D2DB4),
    labelIndigoFgColorHover: Color(0xFF393CD5),
    labelIndigoFgColorRest: Color(0xFF494EDF),
    labelLemonBgColorActive: Color(0xFFD8BD0E),
    labelLemonBgColorHover: Color(0xFFF0DB3D),
    labelLemonBgColorRest: Color(0xFFF7EEA1),
    labelLemonBorderColor: Color(0x00FFFFFF),
    labelLemonFgColorActive: Color(0xFF523F00),
    labelLemonFgColorHover: Color(0xFF654F01),
    labelLemonFgColorRest: Color(0xFF786002),
    labelLimeBgColorActive: Color(0xFF9BD039),
    labelLimeBgColorHover: Color(0xFFC7E580),
    labelLimeBgColorRest: Color(0xFFE3F2B5),
    labelLimeBorderColor: Color(0x00FFFFFF),
    labelLimeFgColorActive: Color(0xFF2F4A21),
    labelLimeFgColorHover: Color(0xFF3A5B25),
    labelLimeFgColorRest: Color(0xFF476C28),
    labelOliveBgColorActive: Color(0xFFB9C832),
    labelOliveBgColorHover: Color(0xFFDBE170),
    labelOliveBgColorRest: Color(0xFFF0F0AD),
    labelOliveBorderColor: Color(0x00FFFFFF),
    labelOliveFgColorActive: Color(0xFF3B4927),
    labelOliveFgColorHover: Color(0xFF495A2B),
    labelOliveFgColorRest: Color(0xFF56682C),
    labelOrangeBgColorActive: Color(0xFFFBAF74),
    labelOrangeBgColorHover: Color(0xFFFECFAA),
    labelOrangeBgColorRest: Color(0xFFFFE7D1),
    labelOrangeBorderColor: Color(0x00FFFFFF),
    labelOrangeFgColorActive: Color(0xFF70300F),
    labelOrangeFgColorHover: Color(0xFF8D3C11),
    labelOrangeFgColorRest: Color(0xFFA24610),
    labelPineBgColorActive: Color(0xFF1DD781),
    labelPineBgColorHover: Color(0xFF80EFB9),
    labelPineBgColorRest: Color(0xFFBFF8DB),
    labelPineBorderColor: Color(0x00FFFFFF),
    labelPineFgColorActive: Color(0xFF114B36),
    labelPineFgColorHover: Color(0xFF135D41),
    labelPineFgColorRest: Color(0xFF156F4B),
    labelPinkBgColorActive: Color(0xFFF8A5CF),
    labelPinkBgColorHover: Color(0xFFFDC9E2),
    labelPinkBgColorRest: Color(0xFFFFE5F1),
    labelPinkBorderColor: Color(0x00FFFFFF),
    labelPinkFgColorActive: Color(0xFF6E2B53),
    labelPinkFgColorHover: Color(0xFF8E2E66),
    labelPinkFgColorRest: Color(0xFFB12F79),
    labelPlumBgColorActive: Color(0xFFE2A7FB),
    labelPlumBgColorHover: Color(0xFFF0CDFE),
    labelPlumBgColorRest: Color(0xFFF8E5FF),
    labelPlumBorderColor: Color(0x00FFFFFF),
    labelPlumFgColorActive: Color(0xFF651D96),
    labelPlumFgColorHover: Color(0xFF7D1EB8),
    labelPlumFgColorRest: Color(0xFF961EDC),
    labelPurpleBgColorActive: Color(0xFFD1B1FC),
    labelPurpleBgColorHover: Color(0xFFE6D2FE),
    labelPurpleBgColorRest: Color(0xFFF1E5FF),
    labelPurpleBorderColor: Color(0x00FFFFFF),
    labelPurpleFgColorActive: Color(0xFF4F21AB),
    labelPurpleFgColorHover: Color(0xFF6223D7),
    labelPurpleFgColorRest: Color(0xFF783AE4),
    labelRedBgColorActive: Color(0xFFFDA5A7),
    labelRedBgColorHover: Color(0xFFFECDCD),
    labelRedBgColorRest: Color(0xFFFFE2E0),
    labelRedBorderColor: Color(0x00FFFFFF),
    labelRedFgColorActive: Color(0xFF880C27),
    labelRedFgColorHover: Color(0xFFA60C29),
    labelRedFgColorRest: Color(0xFFC50D28),
    labelTealBgColorActive: Color(0xFF22D3C7),
    labelTealBgColorHover: Color(0xFF89EBE1),
    labelTealBgColorRest: Color(0xFFC7F5EF),
    labelTealBorderColor: Color(0x00FFFFFF),
    labelTealFgColorActive: Color(0xFF0A4852),
    labelTealFgColorHover: Color(0xFF0D5B63),
    labelTealFgColorRest: Color(0xFF106E75),
    labelYellowBgColorActive: Color(0xFFEBB400),
    labelYellowBgColorHover: Color(0xFFFFD642),
    labelYellowBgColorRest: Color(0xFFFFEC9E),
    labelYellowBorderColor: Color(0x00FFFFFF),
    labelYellowFgColorActive: Color(0xFF5C3D00),
    labelYellowFgColorHover: Color(0xFF704D00),
    labelYellowFgColorRest: Color(0xFF805900),
    menuBgColorActive: Color(0x00FFFFFF),
    overlayBackdropBgColor: Color(0x66C8D1DA),
    overlayBgColor: Color(0xFFFFFFFF),
    overlayBorderColor: Color(0x80D1D9E0),
    pageHeaderBgColor: Color(0xFFF6F8FA),
    prettylightsSyntaxBracketHighlighterAngle: Color(0xFF59636E),
    prettylightsSyntaxBracketHighlighterUnmatched: Color(0xFF82071E),
    prettylightsSyntaxBrackethighlighterAngle: Color(0xFF59636E),
    prettylightsSyntaxBrackethighlighterUnmatched: Color(0xFF82071E),
    prettylightsSyntaxCarriageReturnBg: Color(0xFFCF222E),
    prettylightsSyntaxCarriageReturnText: Color(0xFFF6F8FA),
    prettylightsSyntaxComment: Color(0xFF59636E),
    prettylightsSyntaxConstant: Color(0xFF0550AE),
    prettylightsSyntaxConstantOtherReferenceLink: Color(0xFF0A3069),
    prettylightsSyntaxEntity: Color(0xFF6639BA),
    prettylightsSyntaxEntityTag: Color(0xFF0550AE),
    prettylightsSyntaxInvalidIllegalBg: Color(0xFFFFEBE9),
    prettylightsSyntaxInvalidIllegalText: Color(0xFFD1242F),
    prettylightsSyntaxKeyword: Color(0xFFCF222E),
    prettylightsSyntaxMarkupBold: Color(0xFF1F2328),
    prettylightsSyntaxMarkupChangedBg: Color(0xFFFFD8B5),
    prettylightsSyntaxMarkupChangedText: Color(0xFF953800),
    prettylightsSyntaxMarkupDeletedBg: Color(0xFFFFEBE9),
    prettylightsSyntaxMarkupDeletedText: Color(0xFF82071E),
    prettylightsSyntaxMarkupHeading: Color(0xFF0550AE),
    prettylightsSyntaxMarkupIgnoredBg: Color(0xFF0550AE),
    prettylightsSyntaxMarkupIgnoredText: Color(0xFFD1D9E0),
    prettylightsSyntaxMarkupInsertedBg: Color(0xFFDAFBE1),
    prettylightsSyntaxMarkupInsertedText: Color(0xFF116329),
    prettylightsSyntaxMarkupItalic: Color(0xFF1F2328),
    prettylightsSyntaxMarkupList: Color(0xFF3B2300),
    prettylightsSyntaxMetaDiffRange: Color(0xFF8250DF),
    prettylightsSyntaxStorageModifierImport: Color(0xFF1F2328),
    prettylightsSyntaxString: Color(0xFF0A3069),
    prettylightsSyntaxStringRegexp: Color(0xFF116329),
    prettylightsSyntaxSublimeLinterGutterMark: Color(0xFF818B98),
    prettylightsSyntaxSublimelinterGutterMark: Color(0xFF818B98),
    prettylightsSyntaxVariable: Color(0xFF953800),
    progressBarBgColorAccent: Color(0xFF0969DA),
    progressBarBgColorAttention: Color(0xFF9A6700),
    progressBarBgColorDanger: Color(0xFFCF222E),
    progressBarBgColorDone: Color(0xFF8250DF),
    progressBarBgColorNeutral: Color(0xFF59636E),
    progressBarBgColorSevere: Color(0xFFBC4C00),
    progressBarBgColorSponsors: Color(0xFFBF3989),
    progressBarBgColorSuccess: Color(0xFF1F883D),
    progressBarTrackBgColor: Color(0xFFD1D9E0),
    progressBarTrackBorderColor: Color(0x00FFFFFF),
    reactionButtonSelectedBgColorHover: Color(0xFFCAECFF),
    reactionButtonSelectedBgColorRest: Color(0xFFDDF4FF),
    reactionButtonSelectedFgColorHover: Color(0xFF0550AE),
    reactionButtonSelectedFgColorRest: Color(0xFF0969DA),
    selectMenuBgColorActive: Color(0xFFB6E3FF),
    selectMenuBorderColor: Color(0x00FFFFFF),
    selectionBgColor: Color(0x330969DA),
    sideNavBgColorSelected: Color(0xFFFFFFFF),
    skeletonLoaderBgColor: Color(0x1A818B98),
    timelineBadgeBgColor: Color(0xFFF6F8FA),
    tooltipBgColor: Color(0xFF25292E),
    tooltipFgColor: Color(0xFFFFFFFF),
    topicTagBorderColor: Color(0x00FFFFFF),
    treeViewItemLeadingVisualIconColorRest: Color(0xFF54AEFF),
    underlineNavBorderColorActive: Color(0xFFFD8C73),
    underlineNavBorderColorHover: Color(0xB3D1D9E0),
    underlineNavIconColorRest: Color(0xFF59636E),
  );

  static const PrimerColors dark = PrimerColors._(
    ansiBlack: Color(0xFF2F3742),
    ansiBlackBright: Color(0xFF656C76),
    ansiBlue: Color(0xFF58A6FF),
    ansiBlueBright: Color(0xFF79C0FF),
    ansiCyan: Color(0xFF39C5CF),
    ansiCyanBright: Color(0xFF56D4DD),
    ansiGray: Color(0xFF656C76),
    ansiGreen: Color(0xFF3FB950),
    ansiGreenBright: Color(0xFF56D364),
    ansiMagenta: Color(0xFFBE8FFF),
    ansiMagentaBright: Color(0xFFD2A8FF),
    ansiRed: Color(0xFFFF7B72),
    ansiRedBright: Color(0xFFFFA198),
    ansiWhite: Color(0xFFF0F6FC),
    ansiWhiteBright: Color(0xFFFFFFFF),
    ansiYellow: Color(0xFFD29922),
    ansiYellowBright: Color(0xFFE3B341),
    avatarBgColor: Color(0x1AFFFFFF),
    avatarBorderColor: Color(0x26FFFFFF),
    avatarStackFadeBgColorDefault: Color(0xFF3D444D),
    avatarStackFadeBgColorMuted: Color(0xFF2A313C),
    bgColorAccentEmphasis: Color(0xFF1F6FEB),
    bgColorAccentMuted: Color(0x1A388BFD),
    bgColorAttentionEmphasis: Color(0xFF9E6A03),
    bgColorAttentionMuted: Color(0x26BB8009),
    bgColorBlack: Color(0xFF010409),
    bgColorClosedEmphasis: Color(0xFFDA3633),
    bgColorClosedMuted: Color(0x1AF85149),
    bgColorDangerEmphasis: Color(0xFFDA3633),
    bgColorDangerMuted: Color(0x1AF85149),
    bgColorDefault: Color(0xFF0D1117),
    bgColorDisabled: Color(0xFF212830),
    bgColorDoneEmphasis: Color(0xFF8957E5),
    bgColorDoneMuted: Color(0x26AB7DF8),
    bgColorDraftEmphasis: Color(0xFF656C76),
    bgColorDraftMuted: Color(0x33656C76),
    bgColorEmphasis: Color(0xFF3D444D),
    bgColorInset: Color(0xFF010409),
    bgColorInverse: Color(0xFFFFFFFF),
    bgColorMuted: Color(0xFF151B23),
    bgColorNeutralEmphasis: Color(0xFF656C76),
    bgColorNeutralMuted: Color(0x33656C76),
    bgColorOpenEmphasis: Color(0xFF238636),
    bgColorOpenMuted: Color(0x262EA043),
    bgColorSevereEmphasis: Color(0xFFBD561D),
    bgColorSevereMuted: Color(0x1ADB6D28),
    bgColorSponsorsEmphasis: Color(0xFFBF4B8A),
    bgColorSponsorsMuted: Color(0x1ADB61A2),
    bgColorSuccessEmphasis: Color(0xFF238636),
    bgColorSuccessMuted: Color(0x262EA043),
    bgColorTransparent: Color(0x00000000),
    bgColorUpsellEmphasis: Color(0xFF8957E5),
    bgColorUpsellMuted: Color(0x26AB7DF8),
    bgColorWhite: Color(0xFFFFFFFF),
    borderColorAccentEmphasis: Color(0xFF1F6FEB),
    borderColorAccentMuted: Color(0x66388BFD),
    borderColorAttentionEmphasis: Color(0xFF9E6A03),
    borderColorAttentionMuted: Color(0x66BB8009),
    borderColorClosedEmphasis: Color(0xFFDA3633),
    borderColorClosedMuted: Color(0x66F85149),
    borderColorDangerEmphasis: Color(0xFFDA3633),
    borderColorDangerMuted: Color(0x66F85149),
    borderColorDefault: Color(0xFF3D444D),
    borderColorDisabled: Color(0x1A656C76),
    borderColorDoneEmphasis: Color(0xFF8957E5),
    borderColorDoneMuted: Color(0x66AB7DF8),
    borderColorDraftEmphasis: Color(0xFF656C76),
    borderColorDraftMuted: Color(0xB33D444D),
    borderColorEmphasis: Color(0xFF656C76),
    borderColorMuted: Color(0xB33D444D),
    borderColorNeutralEmphasis: Color(0xFF656C76),
    borderColorNeutralMuted: Color(0xB33D444D),
    borderColorOpenEmphasis: Color(0xFF238636),
    borderColorOpenMuted: Color(0x662EA043),
    borderColorSevereEmphasis: Color(0xFFBD561D),
    borderColorSevereMuted: Color(0x66DB6D28),
    borderColorSponsorsEmphasis: Color(0xFFBF4B8A),
    borderColorSponsorsMuted: Color(0x66DB61A2),
    borderColorSuccessEmphasis: Color(0xFF238636),
    borderColorSuccessMuted: Color(0x662EA043),
    borderColorTranslucent: Color(0x26FFFFFF),
    borderColorTransparent: Color(0x00000000),
    borderColorUpsellEmphasis: Color(0xFF8957E5),
    borderColorUpsellMuted: Color(0x66AB7DF8),
    buttonDangerBgColorActive: Color(0xFFDA3633),
    buttonDangerBgColorDisabled: Color(0xFF212830),
    buttonDangerBgColorHover: Color(0xFFB62324),
    buttonDangerBgColorRest: Color(0xFF212830),
    buttonDangerBorderColorActive: Color(0x26FFFFFF),
    buttonDangerBorderColorHover: Color(0x26FFFFFF),
    buttonDangerBorderColorRest: Color(0xFF3D444D),
    buttonDangerFgColorActive: Color(0xFFFFFFFF),
    buttonDangerFgColorDisabled: Color(0x80F85149),
    buttonDangerFgColorHover: Color(0xFFFFFFFF),
    buttonDangerFgColorRest: Color(0xFFFA5E55),
    buttonDangerIconColorDisabled: Color(0x80F85149),
    buttonDangerIconColorHover: Color(0xFFFFFFFF),
    buttonDangerIconColorRest: Color(0xFFFA5E55),
    buttonDefaultBgColorActive: Color(0xFF2A313C),
    buttonDefaultBgColorDisabled: Color(0xFF212830),
    buttonDefaultBgColorHover: Color(0xFF262C36),
    buttonDefaultBgColorRest: Color(0xFF212830),
    buttonDefaultBgColorSelected: Color(0xFF2A313C),
    buttonDefaultBorderColorActive: Color(0xFF3D444D),
    buttonDefaultBorderColorDisabled: Color(0x1A656C76),
    buttonDefaultBorderColorHover: Color(0xFF3D444D),
    buttonDefaultBorderColorRest: Color(0xFF3D444D),
    buttonDefaultFgColorDisabled: Color(0xFF656C76),
    buttonDefaultFgColorRest: Color(0xFFF0F6FC),
    buttonInactiveBgColor: Color(0xFF262C36),
    buttonInactiveFgColor: Color(0xFF9198A1),
    buttonInvisibleBgColorActive: Color(0x40656C76),
    buttonInvisibleBgColorDisabled: Color(0x00000000),
    buttonInvisibleBgColorHover: Color(0x33656C76),
    buttonInvisibleBgColorRest: Color(0x00000000),
    buttonInvisibleBorderColorDisabled: Color(0x00000000),
    buttonInvisibleBorderColorHover: Color(0x00000000),
    buttonInvisibleBorderColorRest: Color(0x00000000),
    buttonInvisibleFgColorActive: Color(0xFFF0F6FC),
    buttonInvisibleFgColorDisabled: Color(0xFF656C76),
    buttonInvisibleFgColorHover: Color(0xFFF0F6FC),
    buttonInvisibleFgColorRest: Color(0xFFF0F6FC),
    buttonInvisibleIconColorDisabled: Color(0xFF656C76),
    buttonInvisibleIconColorHover: Color(0xFF9198A1),
    buttonInvisibleIconColorRest: Color(0xFF9198A1),
    buttonOutlineBgColorActive: Color(0xFF0D419D),
    buttonOutlineBgColorDisabled: Color(0xFF212830),
    buttonOutlineBgColorHover: Color(0xFF262C36),
    buttonOutlineBgColorRest: Color(0xFFF0F6FC),
    buttonOutlineBorderColorActive: Color(0xFF3D444D),
    buttonOutlineBorderColorHover: Color(0xFF3D444D),
    buttonOutlineFgColorActive: Color(0xFFFFFFFF),
    buttonOutlineFgColorDisabled: Color(0x804493F8),
    buttonOutlineFgColorHover: Color(0xFF58A6FF),
    buttonOutlineFgColorRest: Color(0xFF388BFD),
    buttonPrimaryBgColorActive: Color(0xFF2E9A40),
    buttonPrimaryBgColorDisabled: Color(0xFF105823),
    buttonPrimaryBgColorHover: Color(0xFF29903B),
    buttonPrimaryBgColorRest: Color(0xFF238636),
    buttonPrimaryBorderColorActive: Color(0x26FFFFFF),
    buttonPrimaryBorderColorDisabled: Color(0xFF105823),
    buttonPrimaryBorderColorHover: Color(0x26FFFFFF),
    buttonPrimaryBorderColorRest: Color(0x26FFFFFF),
    buttonPrimaryFgColorDisabled: Color(0x66FFFFFF),
    buttonPrimaryFgColorRest: Color(0xFFFFFFFF),
    buttonPrimaryIconColorDisabled: Color(0x66FFFFFF),
    buttonPrimaryIconColorRest: Color(0xFFFFFFFF),
    buttonStarIconColor: Color(0xFFE3B341),
    buttonCounterDangerBgColorDisabled: Color(0x0DDA3633),
    buttonCounterDangerBgColorHover: Color(0x33FFFFFF),
    buttonCounterDangerBgColorRest: Color(0x33490202),
    buttonCounterDangerFgColorDisabled: Color(0x80F85149),
    buttonCounterDangerFgColorHover: Color(0xFFFFFFFF),
    buttonCounterDangerFgColorRest: Color(0xFFF85149),
    buttonCounterDefaultBgColorRest: Color(0xFF2F3742),
    buttonCounterInvisibleBgColorRest: Color(0x33656C76),
    buttonCounterOutlineBgColorDisabled: Color(0x0D1F6FEB),
    buttonCounterOutlineBgColorHover: Color(0x33051D4D),
    buttonCounterOutlineBgColorRest: Color(0x33051D4D),
    buttonCounterOutlineFgColorDisabled: Color(0x804493F8),
    buttonCounterOutlineFgColorHover: Color(0xFF58A6FF),
    buttonCounterOutlineFgColorRest: Color(0xFF388BFD),
    buttonCounterPrimaryBgColorRest: Color(0x3304260F),
    buttonKeybindingHintDangerBgColorActive: Color(0x66010409),
    buttonKeybindingHintDangerBgColorDisabled: Color(0xFF2A313C),
    buttonKeybindingHintDangerBgColorHover: Color(0x33010409),
    buttonKeybindingHintDangerBgColorRest: Color(0xFF2A313C),
    buttonKeybindingHintDangerBorderColorActive: Color(0x1A010409),
    buttonKeybindingHintDangerBorderColorDisabled: Color(0x1A656C76),
    buttonKeybindingHintDangerBorderColorHover: Color(0x1A010409),
    buttonKeybindingHintDangerBorderColorRest: Color(0xB33D444D),
    buttonKeybindingHintDangerFgColorActive: Color(0xFFFFFFFF),
    buttonKeybindingHintDangerFgColorDisabled: Color(0xFF656C76),
    buttonKeybindingHintDangerFgColorHover: Color(0xFFFFFFFF),
    buttonKeybindingHintDangerFgColorRest: Color(0xFF9198A1),
    buttonKeybindingHintDefaultBgColorDisabled: Color(0xFF2A313C),
    buttonKeybindingHintDefaultBgColorRest: Color(0xFF2A313C),
    buttonKeybindingHintDefaultBorderColorDisabled: Color(0x1A656C76),
    buttonKeybindingHintDefaultBorderColorRest: Color(0xB33D444D),
    buttonKeybindingHintDefaultFgColorDisabled: Color(0xFF656C76),
    buttonKeybindingHintDefaultFgColorRest: Color(0xFF9198A1),
    buttonKeybindingHintInactiveBgColor: Color(0xFF2A313C),
    buttonKeybindingHintInactiveBorderColor: Color(0xB33D444D),
    buttonKeybindingHintInactiveFgColor: Color(0xFF9198A1),
    buttonKeybindingHintInvisibleBgColorActive: Color(0x40656C76),
    buttonKeybindingHintInvisibleBgColorDisabled: Color(0x00000000),
    buttonKeybindingHintInvisibleBgColorHover: Color(0x33656C76),
    buttonKeybindingHintInvisibleBgColorRest: Color(0xFF2A313C),
    buttonKeybindingHintInvisibleBorderColorDisabled: Color(0x1A656C76),
    buttonKeybindingHintInvisibleBorderColorRest: Color(0x00000000),
    buttonKeybindingHintInvisibleFgColorDisabled: Color(0xFF656C76),
    buttonKeybindingHintInvisibleFgColorRest: Color(0xFF9198A1),
    buttonKeybindingHintPrimaryBgColorDisabled: Color(0x1A04260F),
    buttonKeybindingHintPrimaryBgColorRest: Color(0x3304260F),
    buttonKeybindingHintPrimaryBorderColorDisabled: Color(0x1A656C76),
    buttonKeybindingHintPrimaryBorderColorRest: Color(0x1A04260F),
    buttonKeybindingHintPrimaryFgColorDisabled: Color(0x66FFFFFF),
    buttonKeybindingHintPrimaryFgColorRest: Color(0xFFFFFFFF),
    cardBgColor: Color(0xFF151B23),
    codeMirrorActivelineBgColor: Color(0x33656C76),
    codeMirrorBgColor: Color(0xFF0D1117),
    codeMirrorCursorFgColor: Color(0xFFF0F6FC),
    codeMirrorFgColor: Color(0xFFF0F6FC),
    codeMirrorGutterMarkerFgColorDefault: Color(0xFF0D1117),
    codeMirrorGutterMarkerFgColorMuted: Color(0xFF9198A1),
    codeMirrorGuttersBgColor: Color(0xFF0D1117),
    codeMirrorLineNumberFgColor: Color(0xFF9198A1),
    codeMirrorLinesBgColor: Color(0xFF0D1117),
    codeMirrorMatchingBracketFgColor: Color(0xFFF0F6FC),
    codeMirrorSelectionBgColor: Color(0x66388BFD),
    codeMirrorSyntaxFgColorComment: Color(0xFF656C76),
    codeMirrorSyntaxFgColorConstant: Color(0xFF79C0FF),
    codeMirrorSyntaxFgColorEntity: Color(0xFFD2A8FF),
    codeMirrorSyntaxFgColorKeyword: Color(0xFFFF7B72),
    codeMirrorSyntaxFgColorStorage: Color(0xFFFF7B72),
    codeMirrorSyntaxFgColorString: Color(0xFFA5D6FF),
    codeMirrorSyntaxFgColorSupport: Color(0xFF79C0FF),
    codeMirrorSyntaxFgColorVariable: Color(0xFFFFA657),
    colorAnsiBlack: Color(0xFF2F3742),
    colorAnsiBlackBright: Color(0xFF656C76),
    colorAnsiBlue: Color(0xFF58A6FF),
    colorAnsiBlueBright: Color(0xFF79C0FF),
    colorAnsiCyan: Color(0xFF39C5CF),
    colorAnsiCyanBright: Color(0xFF56D4DD),
    colorAnsiGray: Color(0xFF656C76),
    colorAnsiGreen: Color(0xFF3FB950),
    colorAnsiGreenBright: Color(0xFF56D364),
    colorAnsiMagenta: Color(0xFFBE8FFF),
    colorAnsiMagentaBright: Color(0xFFD2A8FF),
    colorAnsiRed: Color(0xFFFF7B72),
    colorAnsiRedBright: Color(0xFFFFA198),
    colorAnsiWhite: Color(0xFFF0F6FC),
    colorAnsiWhiteBright: Color(0xFFFFFFFF),
    colorAnsiYellow: Color(0xFFD29922),
    colorAnsiYellowBright: Color(0xFFE3B341),
    colorPrettylightsSyntaxBrackethighlighterAngle: Color(0xFF9198A1),
    colorPrettylightsSyntaxBrackethighlighterUnmatched: Color(0xFFF85149),
    colorPrettylightsSyntaxCarriageReturnBg: Color(0xFFB62324),
    colorPrettylightsSyntaxCarriageReturnText: Color(0xFFF0F6FC),
    colorPrettylightsSyntaxComment: Color(0xFF9198A1),
    colorPrettylightsSyntaxConstant: Color(0xFF79C0FF),
    colorPrettylightsSyntaxConstantOtherReferenceLink: Color(0xFFA5D6FF),
    colorPrettylightsSyntaxEntity: Color(0xFFD2A8FF),
    colorPrettylightsSyntaxEntityTag: Color(0xFF7EE787),
    colorPrettylightsSyntaxInvalidIllegalBg: Color(0x1AF85149),
    colorPrettylightsSyntaxInvalidIllegalText: Color(0xFFF85149),
    colorPrettylightsSyntaxKeyword: Color(0xFFFF7B72),
    colorPrettylightsSyntaxMarkupBold: Color(0xFFF0F6FC),
    colorPrettylightsSyntaxMarkupChangedBg: Color(0xFF5A1E02),
    colorPrettylightsSyntaxMarkupChangedText: Color(0xFFFFDFB6),
    colorPrettylightsSyntaxMarkupDeletedBg: Color(0xFF67060C),
    colorPrettylightsSyntaxMarkupDeletedText: Color(0xFFFFDCD7),
    colorPrettylightsSyntaxMarkupHeading: Color(0xFF1F6FEB),
    colorPrettylightsSyntaxMarkupIgnoredBg: Color(0xFF1158C7),
    colorPrettylightsSyntaxMarkupIgnoredText: Color(0xFFF0F6FC),
    colorPrettylightsSyntaxMarkupInsertedBg: Color(0xFF033A16),
    colorPrettylightsSyntaxMarkupInsertedText: Color(0xFFAFF5B4),
    colorPrettylightsSyntaxMarkupItalic: Color(0xFFF0F6FC),
    colorPrettylightsSyntaxMarkupList: Color(0xFFF2CC60),
    colorPrettylightsSyntaxMetaDiffRange: Color(0xFFD2A8FF),
    colorPrettylightsSyntaxStorageModifierImport: Color(0xFFF0F6FC),
    colorPrettylightsSyntaxString: Color(0xFFA5D6FF),
    colorPrettylightsSyntaxStringRegexp: Color(0xFF7EE787),
    colorPrettylightsSyntaxSublimelinterGutterMark: Color(0xFF3D444D),
    colorPrettylightsSyntaxVariable: Color(0xFFFFA657),
    contributionDefaultBgColor0: Color(0xFF151B23),
    contributionDefaultBgColor1: Color(0xFF033A16),
    contributionDefaultBgColor2: Color(0xFF196C2E),
    contributionDefaultBgColor3: Color(0xFF2EA043),
    contributionDefaultBgColor4: Color(0xFF56D364),
    contributionDefaultBorderColor0: Color(0x0D010409),
    contributionDefaultBorderColor1: Color(0x0D010409),
    contributionDefaultBorderColor2: Color(0x0D010409),
    contributionDefaultBorderColor3: Color(0x0D010409),
    contributionDefaultBorderColor4: Color(0x0D010409),
    contributionHalloweenBgColor1: Color(0xFFFAC68F),
    contributionHalloweenBgColor2: Color(0xFFC46212),
    contributionHalloweenBgColor3: Color(0xFF984B10),
    contributionHalloweenBgColor4: Color(0xFFE3D04F),
    contributionWinterBgColor1: Color(0xFF0C2D6B),
    contributionWinterBgColor2: Color(0xFF1158C7),
    contributionWinterBgColor3: Color(0xFF58A6FF),
    contributionWinterBgColor4: Color(0xFFCAE8FF),
    controlBgColorActive: Color(0xFF2A313C),
    controlBgColorDisabled: Color(0xFF212830),
    controlBgColorHover: Color(0xFF262C36),
    controlBgColorRest: Color(0xFF212830),
    controlBgColorSelected: Color(0xFF212830),
    controlBorderColorDanger: Color(0xFFDA3633),
    controlBorderColorDisabled: Color(0x1A656C76),
    controlBorderColorEmphasis: Color(0xFF656C76),
    controlBorderColorRest: Color(0xFF3D444D),
    controlBorderColorSelected: Color(0xFFF0F6FC),
    controlBorderColorSuccess: Color(0xFF238636),
    controlBorderColorWarning: Color(0xFF9E6A03),
    controlCheckedBgColorActive: Color(0xFF3685F3),
    controlCheckedBgColorDisabled: Color(0xFF656C76),
    controlCheckedBgColorHover: Color(0xFF2A7AEF),
    controlCheckedBgColorRest: Color(0xFF1F6FEB),
    controlCheckedBorderColorActive: Color(0xFF3685F3),
    controlCheckedBorderColorDisabled: Color(0xFF656C76),
    controlCheckedBorderColorHover: Color(0xFF2A7AEF),
    controlCheckedBorderColorRest: Color(0xFF1F6FEB),
    controlCheckedFgColorDisabled: Color(0xFF010409),
    controlCheckedFgColorRest: Color(0xFFFFFFFF),
    controlDangerBgColorActive: Color(0x66F85149),
    controlDangerBgColorHover: Color(0x1AF85149),
    controlDangerFgColorHover: Color(0xFFFF7B72),
    controlDangerFgColorRest: Color(0xFFF85149),
    controlFgColorDisabled: Color(0xFF656C76),
    controlFgColorPlaceholder: Color(0xFF9198A1),
    controlFgColorRest: Color(0xFFF0F6FC),
    controlIconColorRest: Color(0xFF9198A1),
    controlTransparentBgColorActive: Color(0x40656C76),
    controlTransparentBgColorDisabled: Color(0xFF212830),
    controlTransparentBgColorHover: Color(0x33656C76),
    controlTransparentBgColorRest: Color(0x00000000),
    controlTransparentBgColorSelected: Color(0x33656C76),
    controlTransparentBorderColorActive: Color(0x00000000),
    controlTransparentBorderColorHover: Color(0x00000000),
    controlTransparentBorderColorRest: Color(0x00000000),
    controlKnobBgColorChecked: Color(0xFFFFFFFF),
    controlKnobBgColorDisabled: Color(0xFF212830),
    controlKnobBgColorRest: Color(0xFF262C36),
    controlKnobBorderColorChecked: Color(0xFF1F6FEB),
    controlKnobBorderColorDisabled: Color(0xFF212830),
    controlKnobBorderColorRest: Color(0xFF3D444D),
    controlTrackBgColorActive: Color(0xFF2F3742),
    controlTrackBgColorDisabled: Color(0xFF656C76),
    controlTrackBgColorHover: Color(0xFF2A313C),
    controlTrackBgColorRest: Color(0xFF010409),
    controlTrackBorderColorDisabled: Color(0xFF656C76),
    controlTrackBorderColorRest: Color(0xFF3D444D),
    controlTrackFgColorDisabled: Color(0xFFFFFFFF),
    controlTrackFgColorRest: Color(0xFF9198A1),
    counterBgColorEmphasis: Color(0xFF656C76),
    counterBgColorMuted: Color(0x33656C76),
    counterBorderColor: Color(0x00000000),
    dashboardBgColor: Color(0xFF010409),
    dataAuburnColorEmphasis: Color(0xFFA86F6B),
    dataAuburnColorMuted: Color(0xFF271817),
    dataBlueColorEmphasis: Color(0xFF0576FF),
    dataBlueColorMuted: Color(0xFF001A47),
    dataBrownColorEmphasis: Color(0xFF94774C),
    dataBrownColorMuted: Color(0xFF241C14),
    dataCoralColorEmphasis: Color(0xFFE1430E),
    dataCoralColorMuted: Color(0xFF351008),
    dataGrayColorEmphasis: Color(0xFF576270),
    dataGrayColorMuted: Color(0xFF1C1C1C),
    dataGreenColorEmphasis: Color(0xFF2F6F37),
    dataGreenColorMuted: Color(0xFF122117),
    dataLemonColorEmphasis: Color(0xFF977B0C),
    dataLemonColorMuted: Color(0xFF291D00),
    dataLimeColorEmphasis: Color(0xFF5F892F),
    dataLimeColorMuted: Color(0xFF141F0F),
    dataOliveColorEmphasis: Color(0xFF7A8321),
    dataOliveColorMuted: Color(0xFF171E0B),
    dataOrangeColorEmphasis: Color(0xFF984B10),
    dataOrangeColorMuted: Color(0xFF311708),
    dataPineColorEmphasis: Color(0xFF18915E),
    dataPineColorMuted: Color(0xFF082119),
    dataPinkColorEmphasis: Color(0xFFD34591),
    dataPinkColorMuted: Color(0xFF2D1524),
    dataPlumColorEmphasis: Color(0xFFB643EF),
    dataPlumColorMuted: Color(0xFF2A0E3F),
    dataPurpleColorEmphasis: Color(0xFF975BF1),
    dataPurpleColorMuted: Color(0xFF211047),
    dataRedColorEmphasis: Color(0xFFEB3342),
    dataRedColorMuted: Color(0xFF3C0614),
    dataTealColorEmphasis: Color(0xFF106C70),
    dataTealColorMuted: Color(0xFF041F25),
    dataYellowColorEmphasis: Color(0xFF895906),
    dataYellowColorMuted: Color(0xFF2E1A00),
    diffBlobAdditionLineBgColor: Color(0x262EA043),
    diffBlobAdditionLineFgColor: Color(0xFFF0F6FC),
    diffBlobAdditionNumBgColor: Color(0x4D3FB950),
    diffBlobAdditionNumFgColor: Color(0xFFF0F6FC),
    diffBlobAdditionWordBgColor: Color(0x662EA043),
    diffBlobAdditionWordFgColor: Color(0xFFF0F6FC),
    diffBlobDeletionLineBgColor: Color(0x1AF85149),
    diffBlobDeletionLineFgColor: Color(0xFFF0F6FC),
    diffBlobDeletionNumBgColor: Color(0x4DF85149),
    diffBlobDeletionNumFgColor: Color(0xFFF0F6FC),
    diffBlobDeletionWordBgColor: Color(0x66F85149),
    diffBlobDeletionWordFgColor: Color(0xFFF0F6FC),
    diffBlobEmptyLineBgColor: Color(0xFF151B23),
    diffBlobEmptyNumBgColor: Color(0xFF151B23),
    diffBlobExpanderIconColor: Color(0xFF9198A1),
    diffBlobHunkLineBgColor: Color(0x1A388BFD),
    diffBlobHunkLineFgColor: Color(0xFF9198A1),
    diffBlobHunkNumBgColorHover: Color(0xFF1F6FEB),
    diffBlobHunkNumBgColorRest: Color(0xFF0C2D6B),
    diffBlobHunkNumFgColorHover: Color(0xFFFFFFFF),
    diffBlobHunkNumFgColorRest: Color(0xFFF0F6FC),
    displayAuburnBgColorEmphasis: Color(0xFF87534F),
    displayAuburnBgColorMuted: Color(0xFF271817),
    displayAuburnBorderColorEmphasis: Color(0xFFA86F6B),
    displayAuburnBorderColorMuted: Color(0xFF3A2422),
    displayAuburnFgColor: Color(0xFFBF9592),
    displayAuburnScale0: Color(0xFF271817),
    displayAuburnScale1: Color(0xFF3A2422),
    displayAuburnScale2: Color(0xFF543331),
    displayAuburnScale3: Color(0xFF6D4340),
    displayAuburnScale4: Color(0xFF87534F),
    displayAuburnScale5: Color(0xFFA86F6B),
    displayAuburnScale6: Color(0xFFBF9592),
    displayAuburnScale7: Color(0xFFC6A19F),
    displayAuburnScale8: Color(0xFFD4B7B5),
    displayAuburnScale9: Color(0xFFDFCAC8),
    displayBlueBgColorEmphasis: Color(0xFF005BD1),
    displayBlueBgColorMuted: Color(0xFF001A47),
    displayBlueBorderColorEmphasis: Color(0xFF0576FF),
    displayBlueBorderColorMuted: Color(0xFF002766),
    displayBlueFgColor: Color(0xFF4DA0FF),
    displayBlueScale0: Color(0xFF001A47),
    displayBlueScale1: Color(0xFF002766),
    displayBlueScale2: Color(0xFF00378A),
    displayBlueScale3: Color(0xFF0046A8),
    displayBlueScale4: Color(0xFF005BD1),
    displayBlueScale5: Color(0xFF0576FF),
    displayBlueScale6: Color(0xFF4DA0FF),
    displayBlueScale7: Color(0xFF61ADFF),
    displayBlueScale8: Color(0xFF85C2FF),
    displayBlueScale9: Color(0xFFA3D3FF),
    displayBrownBgColorEmphasis: Color(0xFF755E3E),
    displayBrownBgColorMuted: Color(0xFF241C14),
    displayBrownBorderColorEmphasis: Color(0xFF94774C),
    displayBrownBorderColorMuted: Color(0xFF342A1D),
    displayBrownFgColor: Color(0xFFB69A6D),
    displayBrownScale0: Color(0xFF241C14),
    displayBrownScale1: Color(0xFF342A1D),
    displayBrownScale2: Color(0xFF483A28),
    displayBrownScale3: Color(0xFF5D4A32),
    displayBrownScale4: Color(0xFF755E3E),
    displayBrownScale5: Color(0xFF94774C),
    displayBrownScale6: Color(0xFFB69A6D),
    displayBrownScale7: Color(0xFFBFA77D),
    displayBrownScale8: Color(0xFFCDBB98),
    displayBrownScale9: Color(0xFFDBCEB3),
    displayCoralBgColorEmphasis: Color(0xFFC31328),
    displayCoralBgColorMuted: Color(0xFF3C0614),
    displayCoralBorderColorEmphasis: Color(0xFFEB3342),
    displayCoralBorderColorMuted: Color(0xFF58091A),
    displayCoralFgColor: Color(0xFFF27D83),
    displayCoralScale0: Color(0xFF351008),
    displayCoralScale1: Color(0xFF51180B),
    displayCoralScale2: Color(0xFF72220D),
    displayCoralScale3: Color(0xFF902A0E),
    displayCoralScale4: Color(0xFFB3350F),
    displayCoralScale5: Color(0xFFE1430E),
    displayCoralScale6: Color(0xFFF7794B),
    displayCoralScale7: Color(0xFFFA8C61),
    displayCoralScale8: Color(0xFFFDAA86),
    displayCoralScale9: Color(0xFFFFC0A3),
    displayCyanBgColorEmphasis: Color(0xFF036A8C),
    displayCyanBgColorMuted: Color(0xFF001F29),
    displayCyanBorderColorEmphasis: Color(0xFF0587B3),
    displayCyanBorderColorMuted: Color(0xFF002E3D),
    displayCyanFgColor: Color(0xFF07ACE4),
    displayCyanScale0: Color(0xFF001F29),
    displayCyanScale1: Color(0xFF002E3D),
    displayCyanScale2: Color(0xFF014156),
    displayCyanScale3: Color(0xFF02536F),
    displayCyanScale4: Color(0xFF036A8C),
    displayCyanScale5: Color(0xFF0587B3),
    displayCyanScale6: Color(0xFF07ACE4),
    displayCyanScale7: Color(0xFF09B7F1),
    displayCyanScale8: Color(0xFF45CBF7),
    displayCyanScale9: Color(0xFF80DBF9),
    displayGrayBgColorEmphasis: Color(0xFF576270),
    displayGrayBgColorMuted: Color(0xFF1C1C1C),
    displayGrayBorderColorEmphasis: Color(0xFF6E7F96),
    displayGrayBorderColorMuted: Color(0xFF2A2B2D),
    displayGrayFgColor: Color(0xFF92A1B5),
    displayGrayScale0: Color(0xFF1C1C1C),
    displayGrayScale1: Color(0xFF2A2B2D),
    displayGrayScale2: Color(0xFF393D41),
    displayGrayScale3: Color(0xFF474E57),
    displayGrayScale4: Color(0xFF576270),
    displayGrayScale5: Color(0xFF6E7F96),
    displayGrayScale6: Color(0xFF92A1B5),
    displayGrayScale7: Color(0xFF9BABBF),
    displayGrayScale8: Color(0xFFB3C0D1),
    displayGrayScale9: Color(0xFFC4CFDE),
    displayGreenBgColorEmphasis: Color(0xFF2F6F37),
    displayGreenBgColorMuted: Color(0xFF122117),
    displayGreenBorderColorEmphasis: Color(0xFF388F3F),
    displayGreenBorderColorMuted: Color(0xFF182F1F),
    displayGreenFgColor: Color(0xFF41B445),
    displayGreenScale0: Color(0xFF122117),
    displayGreenScale1: Color(0xFF182F1F),
    displayGreenScale2: Color(0xFF214529),
    displayGreenScale3: Color(0xFF285830),
    displayGreenScale4: Color(0xFF2F6F37),
    displayGreenScale5: Color(0xFF388F3F),
    displayGreenScale6: Color(0xFF41B445),
    displayGreenScale7: Color(0xFF46C144),
    displayGreenScale8: Color(0xFF75D36F),
    displayGreenScale9: Color(0xFF99E090),
    displayIndigoBgColorEmphasis: Color(0xFF514ED4),
    displayIndigoBgColorMuted: Color(0xFF1B183F),
    displayIndigoBorderColorEmphasis: Color(0xFF7070E1),
    displayIndigoBorderColorMuted: Color(0xFF25215F),
    displayIndigoFgColor: Color(0xFF9899EC),
    displayIndigoScale0: Color(0xFF1B183F),
    displayIndigoScale1: Color(0xFF25215F),
    displayIndigoScale2: Color(0xFF312C90),
    displayIndigoScale3: Color(0xFF3935C0),
    displayIndigoScale4: Color(0xFF514ED4),
    displayIndigoScale5: Color(0xFF7070E1),
    displayIndigoScale6: Color(0xFF9899EC),
    displayIndigoScale7: Color(0xFFA2A5F1),
    displayIndigoScale8: Color(0xFFB7BAF6),
    displayIndigoScale9: Color(0xFFC8CBF9),
    displayLemonBgColorEmphasis: Color(0xFF786008),
    displayLemonBgColorMuted: Color(0xFF291D00),
    displayLemonBorderColorEmphasis: Color(0xFF977B0C),
    displayLemonBorderColorMuted: Color(0xFF372901),
    displayLemonFgColor: Color(0xFFBA9B12),
    displayLemonScale0: Color(0xFF291D00),
    displayLemonScale1: Color(0xFF372901),
    displayLemonScale2: Color(0xFF4F3C02),
    displayLemonScale3: Color(0xFF614C05),
    displayLemonScale4: Color(0xFF786008),
    displayLemonScale5: Color(0xFF977B0C),
    displayLemonScale6: Color(0xFFBA9B12),
    displayLemonScale7: Color(0xFFC4A717),
    displayLemonScale8: Color(0xFFD7BC1D),
    displayLemonScale9: Color(0xFFE3D04F),
    displayLimeBgColorEmphasis: Color(0xFF496C28),
    displayLimeBgColorMuted: Color(0xFF141F0F),
    displayLimeBorderColorEmphasis: Color(0xFF5F892F),
    displayLimeBorderColorMuted: Color(0xFF1F3116),
    displayLimeFgColor: Color(0xFF7DAE37),
    displayLimeScale0: Color(0xFF141F0F),
    displayLimeScale1: Color(0xFF1F3116),
    displayLimeScale2: Color(0xFF2C441D),
    displayLimeScale3: Color(0xFF375421),
    displayLimeScale4: Color(0xFF496C28),
    displayLimeScale5: Color(0xFF5F892F),
    displayLimeScale6: Color(0xFF7DAE37),
    displayLimeScale7: Color(0xFF89BA36),
    displayLimeScale8: Color(0xFF9FCC3E),
    displayLimeScale9: Color(0xFFBCDA67),
    displayOliveBgColorEmphasis: Color(0xFF5E681D),
    displayOliveBgColorMuted: Color(0xFF171E0B),
    displayOliveBorderColorEmphasis: Color(0xFF7A8321),
    displayOliveBorderColorMuted: Color(0xFF252D10),
    displayOliveFgColor: Color(0xFFA2A626),
    displayOliveScale0: Color(0xFF171E0B),
    displayOliveScale1: Color(0xFF252D10),
    displayOliveScale2: Color(0xFF374115),
    displayOliveScale3: Color(0xFF485219),
    displayOliveScale4: Color(0xFF5E681D),
    displayOliveScale5: Color(0xFF7A8321),
    displayOliveScale6: Color(0xFFA2A626),
    displayOliveScale7: Color(0xFFB2AF24),
    displayOliveScale8: Color(0xFFCBC025),
    displayOliveScale9: Color(0xFFE2D04B),
    displayOrangeBgColorEmphasis: Color(0xFF984B10),
    displayOrangeBgColorMuted: Color(0xFF311708),
    displayOrangeBorderColorEmphasis: Color(0xFFC46212),
    displayOrangeBorderColorMuted: Color(0xFF43200A),
    displayOrangeFgColor: Color(0xFFED8326),
    displayOrangeScale0: Color(0xFF311708),
    displayOrangeScale1: Color(0xFF43200A),
    displayOrangeScale2: Color(0xFF632F0D),
    displayOrangeScale3: Color(0xFF7B3C0E),
    displayOrangeScale4: Color(0xFF984B10),
    displayOrangeScale5: Color(0xFFC46212),
    displayOrangeScale6: Color(0xFFED8326),
    displayOrangeScale7: Color(0xFFF1933B),
    displayOrangeScale8: Color(0xFFF6B06A),
    displayOrangeScale9: Color(0xFFFAC68F),
    displayPineBgColorEmphasis: Color(0xFF14714C),
    displayPineBgColorMuted: Color(0xFF082119),
    displayPineBorderColorEmphasis: Color(0xFF18915E),
    displayPineBorderColorMuted: Color(0xFF0B3224),
    displayPineFgColor: Color(0xFF1BB673),
    displayPineScale0: Color(0xFF082119),
    displayPineScale1: Color(0xFF0B3224),
    displayPineScale2: Color(0xFF0E4430),
    displayPineScale3: Color(0xFF115A3E),
    displayPineScale4: Color(0xFF14714C),
    displayPineScale5: Color(0xFF18915E),
    displayPineScale6: Color(0xFF1BB673),
    displayPineScale7: Color(0xFF1AC176),
    displayPineScale8: Color(0xFF1BDA81),
    displayPineScale9: Color(0xFF3EEA97),
    displayPinkBgColorEmphasis: Color(0xFFAC2F74),
    displayPinkBgColorMuted: Color(0xFF2D1524),
    displayPinkBorderColorEmphasis: Color(0xFFD34591),
    displayPinkBorderColorMuted: Color(0xFF451C35),
    displayPinkFgColor: Color(0xFFE57BB2),
    displayPinkScale0: Color(0xFF2D1524),
    displayPinkScale1: Color(0xFF451C35),
    displayPinkScale2: Color(0xFF65244A),
    displayPinkScale3: Color(0xFF842A5D),
    displayPinkScale4: Color(0xFFAC2F74),
    displayPinkScale5: Color(0xFFD34591),
    displayPinkScale6: Color(0xFFE57BB2),
    displayPinkScale7: Color(0xFFEC8DBD),
    displayPinkScale8: Color(0xFFF4A9CD),
    displayPinkScale9: Color(0xFFF9BED9),
    displayPlumBgColorEmphasis: Color(0xFF9518D8),
    displayPlumBgColorMuted: Color(0xFF2A0E3F),
    displayPlumBorderColorEmphasis: Color(0xFFB643EF),
    displayPlumBorderColorMuted: Color(0xFF40125E),
    displayPlumFgColor: Color(0xFFD07EF7),
    displayPlumScale0: Color(0xFF2A0E3F),
    displayPlumScale1: Color(0xFF40125E),
    displayPlumScale2: Color(0xFF5C1688),
    displayPlumScale3: Color(0xFF7517AB),
    displayPlumScale4: Color(0xFF9518D8),
    displayPlumScale5: Color(0xFFB643EF),
    displayPlumScale6: Color(0xFFD07EF7),
    displayPlumScale7: Color(0xFFD889FA),
    displayPlumScale8: Color(0xFFE4A5FD),
    displayPlumScale9: Color(0xFFEDBDFF),
    displayPurpleBgColorEmphasis: Color(0xFF7730E8),
    displayPurpleBgColorMuted: Color(0xFF211047),
    displayPurpleBorderColorEmphasis: Color(0xFF975BF1),
    displayPurpleBorderColorMuted: Color(0xFF31146B),
    displayPurpleFgColor: Color(0xFFB687F7),
    displayPurpleScale0: Color(0xFF211047),
    displayPurpleScale1: Color(0xFF31146B),
    displayPurpleScale2: Color(0xFF481A9E),
    displayPurpleScale3: Color(0xFF5B1CCA),
    displayPurpleScale4: Color(0xFF7730E8),
    displayPurpleScale5: Color(0xFF975BF1),
    displayPurpleScale6: Color(0xFFB687F7),
    displayPurpleScale7: Color(0xFFC398FB),
    displayPurpleScale8: Color(0xFFD2AFFD),
    displayPurpleScale9: Color(0xFFE1C7FF),
    displayRedBgColorEmphasis: Color(0xFFC31328),
    displayRedBgColorMuted: Color(0xFF3C0614),
    displayRedBorderColorEmphasis: Color(0xFFEB3342),
    displayRedBorderColorMuted: Color(0xFF58091A),
    displayRedFgColor: Color(0xFFF27D83),
    displayRedScale0: Color(0xFF3C0614),
    displayRedScale1: Color(0xFF58091A),
    displayRedScale2: Color(0xFF790C20),
    displayRedScale3: Color(0xFF990F24),
    displayRedScale4: Color(0xFFC31328),
    displayRedScale5: Color(0xFFEB3342),
    displayRedScale6: Color(0xFFF27D83),
    displayRedScale7: Color(0xFFF48B8D),
    displayRedScale8: Color(0xFFF7ADAB),
    displayRedScale9: Color(0xFFF9C1BE),
    displayTealBgColorEmphasis: Color(0xFF106C70),
    displayTealBgColorMuted: Color(0xFF041F25),
    displayTealBorderColorEmphasis: Color(0xFF158A8A),
    displayTealBorderColorMuted: Color(0xFF073036),
    displayTealFgColor: Color(0xFF1CB0AB),
    displayTealScale0: Color(0xFF041F25),
    displayTealScale1: Color(0xFF073036),
    displayTealScale2: Color(0xFF0A464D),
    displayTealScale3: Color(0xFF0C555A),
    displayTealScale4: Color(0xFF106C70),
    displayTealScale5: Color(0xFF158A8A),
    displayTealScale6: Color(0xFF1CB0AB),
    displayTealScale7: Color(0xFF1FBDB2),
    displayTealScale8: Color(0xFF24D6C4),
    displayTealScale9: Color(0xFF5FE3D1),
    displayYellowBgColorEmphasis: Color(0xFF895906),
    displayYellowBgColorMuted: Color(0xFF2E1A00),
    displayYellowBorderColorEmphasis: Color(0xFFAA7109),
    displayYellowBorderColorMuted: Color(0xFF3D2401),
    displayYellowFgColor: Color(0xFFD3910D),
    displayYellowScale0: Color(0xFF2E1A00),
    displayYellowScale1: Color(0xFF3D2401),
    displayYellowScale2: Color(0xFF5A3702),
    displayYellowScale3: Color(0xFF6D4403),
    displayYellowScale4: Color(0xFF895906),
    displayYellowScale5: Color(0xFFAA7109),
    displayYellowScale6: Color(0xFFD3910D),
    displayYellowScale7: Color(0xFFDF9E11),
    displayYellowScale8: Color(0xFFEDB431),
    displayYellowScale9: Color(0xFFF0CA6A),
    fgColorAccent: Color(0xFF4493F8),
    fgColorAttention: Color(0xFFD29922),
    fgColorBlack: Color(0xFF010409),
    fgColorClosed: Color(0xFFF85149),
    fgColorDanger: Color(0xFFF85149),
    fgColorDefault: Color(0xFFF0F6FC),
    fgColorDisabled: Color(0xFF656C76),
    fgColorDone: Color(0xFFAB7DF8),
    fgColorDraft: Color(0xFF9198A1),
    fgColorLink: Color(0xFF4493F8),
    fgColorMuted: Color(0xFF9198A1),
    fgColorNeutral: Color(0xFF9198A1),
    fgColorOnEmphasis: Color(0xFFFFFFFF),
    fgColorOnInverse: Color(0xFF010409),
    fgColorOpen: Color(0xFF3FB950),
    fgColorSevere: Color(0xFFDB6D28),
    fgColorSponsors: Color(0xFFDB61A2),
    fgColorSuccess: Color(0xFF3FB950),
    fgColorUpsell: Color(0xFFAB7DF8),
    fgColorWhite: Color(0xFFFFFFFF),
    focusOutlineColor: Color(0xFF1F6FEB),
    headerBgColor: Color(0xF2151B23),
    headerBorderColorDivider: Color(0xFF656C76),
    headerFgColorDefault: Color(0xB3FFFFFF),
    headerFgColorLogo: Color(0xFFF0F6FC),
    headerSearchBgColor: Color(0xFF0D1117),
    headerSearchBorderColor: Color(0xFF2A313C),
    highlightNeutralBgColor: Color(0x66D29922),
    labelAuburnBgColorActive: Color(0xFF543331),
    labelAuburnBgColorHover: Color(0xFF3A2422),
    labelAuburnBgColorRest: Color(0xFF271817),
    labelAuburnBorderColor: Color(0x00000000),
    labelAuburnFgColorActive: Color(0xFFD4B7B5),
    labelAuburnFgColorHover: Color(0xFFC6A19F),
    labelAuburnFgColorRest: Color(0xFFBF9592),
    labelBlueBgColorActive: Color(0xFF00378A),
    labelBlueBgColorHover: Color(0xFF002766),
    labelBlueBgColorRest: Color(0xFF001A47),
    labelBlueBorderColor: Color(0x00000000),
    labelBlueFgColorActive: Color(0xFF85C2FF),
    labelBlueFgColorHover: Color(0xFF61ADFF),
    labelBlueFgColorRest: Color(0xFF4DA0FF),
    labelBrownBgColorActive: Color(0xFF483A28),
    labelBrownBgColorHover: Color(0xFF342A1D),
    labelBrownBgColorRest: Color(0xFF241C14),
    labelBrownBorderColor: Color(0x00000000),
    labelBrownFgColorActive: Color(0xFFCDBB98),
    labelBrownFgColorHover: Color(0xFFBFA77D),
    labelBrownFgColorRest: Color(0xFFB69A6D),
    labelCoralBgColorActive: Color(0xFF72220D),
    labelCoralBgColorHover: Color(0xFF51180B),
    labelCoralBgColorRest: Color(0xFF351008),
    labelCoralBorderColor: Color(0x00000000),
    labelCoralFgColorActive: Color(0xFFFDAA86),
    labelCoralFgColorHover: Color(0xFFFA8C61),
    labelCoralFgColorRest: Color(0xFFF7794B),
    labelCyanBgColorActive: Color(0xFF014156),
    labelCyanBgColorHover: Color(0xFF002E3D),
    labelCyanBgColorRest: Color(0xFF001F29),
    labelCyanBorderColor: Color(0x00000000),
    labelCyanFgColorActive: Color(0xFF45CBF7),
    labelCyanFgColorHover: Color(0xFF09B7F1),
    labelCyanFgColorRest: Color(0xFF07ACE4),
    labelGrayBgColorActive: Color(0xFF393D41),
    labelGrayBgColorHover: Color(0xFF2A2B2D),
    labelGrayBgColorRest: Color(0xFF1C1C1C),
    labelGrayBorderColor: Color(0x00000000),
    labelGrayFgColorActive: Color(0xFFB3C0D1),
    labelGrayFgColorHover: Color(0xFF9BABBF),
    labelGrayFgColorRest: Color(0xFF92A1B5),
    labelGreenBgColorActive: Color(0xFF214529),
    labelGreenBgColorHover: Color(0xFF182F1F),
    labelGreenBgColorRest: Color(0xFF122117),
    labelGreenBorderColor: Color(0x00000000),
    labelGreenFgColorActive: Color(0xFF75D36F),
    labelGreenFgColorHover: Color(0xFF46C144),
    labelGreenFgColorRest: Color(0xFF41B445),
    labelIndigoBgColorActive: Color(0xFF312C90),
    labelIndigoBgColorHover: Color(0xFF25215F),
    labelIndigoBgColorRest: Color(0xFF1B183F),
    labelIndigoBorderColor: Color(0x00000000),
    labelIndigoFgColorActive: Color(0xFFB7BAF6),
    labelIndigoFgColorHover: Color(0xFFA2A5F1),
    labelIndigoFgColorRest: Color(0xFF9899EC),
    labelLemonBgColorActive: Color(0xFF4F3C02),
    labelLemonBgColorHover: Color(0xFF372901),
    labelLemonBgColorRest: Color(0xFF291D00),
    labelLemonBorderColor: Color(0x00000000),
    labelLemonFgColorActive: Color(0xFFD7BC1D),
    labelLemonFgColorHover: Color(0xFFC4A717),
    labelLemonFgColorRest: Color(0xFFBA9B12),
    labelLimeBgColorActive: Color(0xFF2C441D),
    labelLimeBgColorHover: Color(0xFF1F3116),
    labelLimeBgColorRest: Color(0xFF141F0F),
    labelLimeBorderColor: Color(0x00000000),
    labelLimeFgColorActive: Color(0xFF9FCC3E),
    labelLimeFgColorHover: Color(0xFF89BA36),
    labelLimeFgColorRest: Color(0xFF7DAE37),
    labelOliveBgColorActive: Color(0xFF374115),
    labelOliveBgColorHover: Color(0xFF252D10),
    labelOliveBgColorRest: Color(0xFF171E0B),
    labelOliveBorderColor: Color(0x00000000),
    labelOliveFgColorActive: Color(0xFFCBC025),
    labelOliveFgColorHover: Color(0xFFB2AF24),
    labelOliveFgColorRest: Color(0xFFA2A626),
    labelOrangeBgColorActive: Color(0xFF632F0D),
    labelOrangeBgColorHover: Color(0xFF43200A),
    labelOrangeBgColorRest: Color(0xFF311708),
    labelOrangeBorderColor: Color(0x00000000),
    labelOrangeFgColorActive: Color(0xFFF6B06A),
    labelOrangeFgColorHover: Color(0xFFF1933B),
    labelOrangeFgColorRest: Color(0xFFED8326),
    labelPineBgColorActive: Color(0xFF0E4430),
    labelPineBgColorHover: Color(0xFF0B3224),
    labelPineBgColorRest: Color(0xFF082119),
    labelPineBorderColor: Color(0x00000000),
    labelPineFgColorActive: Color(0xFF1BDA81),
    labelPineFgColorHover: Color(0xFF1AC176),
    labelPineFgColorRest: Color(0xFF1BB673),
    labelPinkBgColorActive: Color(0xFF65244A),
    labelPinkBgColorHover: Color(0xFF451C35),
    labelPinkBgColorRest: Color(0xFF2D1524),
    labelPinkBorderColor: Color(0x00000000),
    labelPinkFgColorActive: Color(0xFFF4A9CD),
    labelPinkFgColorHover: Color(0xFFEC8DBD),
    labelPinkFgColorRest: Color(0xFFE57BB2),
    labelPlumBgColorActive: Color(0xFF5C1688),
    labelPlumBgColorHover: Color(0xFF40125E),
    labelPlumBgColorRest: Color(0xFF2A0E3F),
    labelPlumBorderColor: Color(0x00000000),
    labelPlumFgColorActive: Color(0xFFE4A5FD),
    labelPlumFgColorHover: Color(0xFFD889FA),
    labelPlumFgColorRest: Color(0xFFD07EF7),
    labelPurpleBgColorActive: Color(0xFF481A9E),
    labelPurpleBgColorHover: Color(0xFF31146B),
    labelPurpleBgColorRest: Color(0xFF211047),
    labelPurpleBorderColor: Color(0x00000000),
    labelPurpleFgColorActive: Color(0xFFD2AFFD),
    labelPurpleFgColorHover: Color(0xFFC398FB),
    labelPurpleFgColorRest: Color(0xFFB687F7),
    labelRedBgColorActive: Color(0xFF790C20),
    labelRedBgColorHover: Color(0xFF58091A),
    labelRedBgColorRest: Color(0xFF3C0614),
    labelRedBorderColor: Color(0x00000000),
    labelRedFgColorActive: Color(0xFFF7ADAB),
    labelRedFgColorHover: Color(0xFFF48B8D),
    labelRedFgColorRest: Color(0xFFF27D83),
    labelTealBgColorActive: Color(0xFF0A464D),
    labelTealBgColorHover: Color(0xFF073036),
    labelTealBgColorRest: Color(0xFF041F25),
    labelTealBorderColor: Color(0x00000000),
    labelTealFgColorActive: Color(0xFF24D6C4),
    labelTealFgColorHover: Color(0xFF1FBDB2),
    labelTealFgColorRest: Color(0xFF1CB0AB),
    labelYellowBgColorActive: Color(0xFF5A3702),
    labelYellowBgColorHover: Color(0xFF3D2401),
    labelYellowBgColorRest: Color(0xFF2E1A00),
    labelYellowBorderColor: Color(0x00000000),
    labelYellowFgColorActive: Color(0xFFEDB431),
    labelYellowFgColorHover: Color(0xFFDF9E11),
    labelYellowFgColorRest: Color(0xFFD3910D),
    menuBgColorActive: Color(0xFF151B23),
    overlayBackdropBgColor: Color(0x66212830),
    overlayBgColor: Color(0xFF010409),
    overlayBorderColor: Color(0xB33D444D),
    pageHeaderBgColor: Color(0xFF0D1117),
    prettylightsSyntaxBracketHighlighterAngle: Color(0xFF9198A1),
    prettylightsSyntaxBracketHighlighterUnmatched: Color(0xFFF85149),
    prettylightsSyntaxBrackethighlighterAngle: Color(0xFF9198A1),
    prettylightsSyntaxBrackethighlighterUnmatched: Color(0xFFF85149),
    prettylightsSyntaxCarriageReturnBg: Color(0xFFB62324),
    prettylightsSyntaxCarriageReturnText: Color(0xFFF0F6FC),
    prettylightsSyntaxComment: Color(0xFF9198A1),
    prettylightsSyntaxConstant: Color(0xFF79C0FF),
    prettylightsSyntaxConstantOtherReferenceLink: Color(0xFFA5D6FF),
    prettylightsSyntaxEntity: Color(0xFFD2A8FF),
    prettylightsSyntaxEntityTag: Color(0xFF7EE787),
    prettylightsSyntaxInvalidIllegalBg: Color(0x1AF85149),
    prettylightsSyntaxInvalidIllegalText: Color(0xFFF85149),
    prettylightsSyntaxKeyword: Color(0xFFFF7B72),
    prettylightsSyntaxMarkupBold: Color(0xFFF0F6FC),
    prettylightsSyntaxMarkupChangedBg: Color(0xFF5A1E02),
    prettylightsSyntaxMarkupChangedText: Color(0xFFFFDFB6),
    prettylightsSyntaxMarkupDeletedBg: Color(0xFF67060C),
    prettylightsSyntaxMarkupDeletedText: Color(0xFFFFDCD7),
    prettylightsSyntaxMarkupHeading: Color(0xFF1F6FEB),
    prettylightsSyntaxMarkupIgnoredBg: Color(0xFF1158C7),
    prettylightsSyntaxMarkupIgnoredText: Color(0xFFF0F6FC),
    prettylightsSyntaxMarkupInsertedBg: Color(0xFF033A16),
    prettylightsSyntaxMarkupInsertedText: Color(0xFFAFF5B4),
    prettylightsSyntaxMarkupItalic: Color(0xFFF0F6FC),
    prettylightsSyntaxMarkupList: Color(0xFFF2CC60),
    prettylightsSyntaxMetaDiffRange: Color(0xFFD2A8FF),
    prettylightsSyntaxStorageModifierImport: Color(0xFFF0F6FC),
    prettylightsSyntaxString: Color(0xFFA5D6FF),
    prettylightsSyntaxStringRegexp: Color(0xFF7EE787),
    prettylightsSyntaxSublimeLinterGutterMark: Color(0xFF3D444D),
    prettylightsSyntaxSublimelinterGutterMark: Color(0xFF3D444D),
    prettylightsSyntaxVariable: Color(0xFFFFA657),
    progressBarBgColorAccent: Color(0xFF1F6FEB),
    progressBarBgColorAttention: Color(0xFF9E6A03),
    progressBarBgColorDanger: Color(0xFFDA3633),
    progressBarBgColorDone: Color(0xFF8957E5),
    progressBarBgColorNeutral: Color(0xFF656C76),
    progressBarBgColorSevere: Color(0xFFBD561D),
    progressBarBgColorSponsors: Color(0xFFBF4B8A),
    progressBarBgColorSuccess: Color(0xFF238636),
    progressBarTrackBgColor: Color(0xFF3D444D),
    progressBarTrackBorderColor: Color(0x00000000),
    reactionButtonSelectedBgColorHover: Color(0x5C3A8CFD),
    reactionButtonSelectedBgColorRest: Color(0x33388BFD),
    reactionButtonSelectedFgColorHover: Color(0xFF79C0FF),
    reactionButtonSelectedFgColorRest: Color(0xFF4493F8),
    selectMenuBgColorActive: Color(0xFF0C2D6B),
    selectMenuBorderColor: Color(0xFF3D444D),
    selectionBgColor: Color(0xB31F6FEB),
    sideNavBgColorSelected: Color(0xFF212830),
    skeletonLoaderBgColor: Color(0x33656C76),
    timelineBadgeBgColor: Color(0xFF212830),
    tooltipBgColor: Color(0xFF3D444D),
    tooltipFgColor: Color(0xFFFFFFFF),
    topicTagBorderColor: Color(0x00000000),
    treeViewItemLeadingVisualIconColorRest: Color(0xFF9198A1),
    underlineNavBorderColorActive: Color(0xFFF78166),
    underlineNavBorderColorHover: Color(0xB33D444D),
    underlineNavIconColorRest: Color(0xFF9198A1),
  );
}

/// 간격, 컨트롤 크기, 테두리 두께, 화면 너비 기준. 논리 픽셀(rem × 16).
abstract final class PrimerSize {
  static const double baseSize112 = 112;
  static const double baseSize12 = 12;
  static const double baseSize128 = 128;
  static const double baseSize16 = 16;
  static const double baseSize2 = 2;
  static const double baseSize20 = 20;
  static const double baseSize24 = 24;
  static const double baseSize28 = 28;
  static const double baseSize32 = 32;
  static const double baseSize36 = 36;
  static const double baseSize4 = 4;
  static const double baseSize40 = 40;
  static const double baseSize44 = 44;
  static const double baseSize48 = 48;
  static const double baseSize6 = 6;
  static const double baseSize64 = 64;
  static const double baseSize8 = 8;
  static const double baseSize80 = 80;
  static const double baseSize96 = 96;
  static const double baseSizeNegative12 = -12;
  static const double baseSizeNegative16 = -16;
  static const double baseSizeNegative2 = -2;
  static const double baseSizeNegative20 = -20;
  static const double baseSizeNegative24 = -24;
  static const double baseSizeNegative28 = -28;
  static const double baseSizeNegative32 = -32;
  static const double baseSizeNegative36 = -36;
  static const double baseSizeNegative4 = -4;
  static const double baseSizeNegative40 = -40;
  static const double baseSizeNegative44 = -44;
  static const double baseSizeNegative48 = -48;
  static const double baseSizeNegative6 = -6;
  static const double baseSizeNegative8 = -8;
  static const double borderWidthDefault = 1;
  static const double borderWidthThick = 2;
  static const double borderWidthThicker = 4;
  static const double borderWidthThin = 1;
  static const double breakpointLarge = 1012;
  static const double breakpointMedium = 768;
  static const double breakpointSmall = 544;
  static const double breakpointXlarge = 1280;
  static const double breakpointXsmall = 320;
  static const double breakpointXxlarge = 1400;
  static const double controlLargeGap = 8;
  static const double controlLargePaddingBlock = 10;
  static const double controlLargePaddingInlineCondensed = 8;
  static const double controlLargePaddingInlineNormal = 12;
  static const double controlLargePaddingInlineSpacious = 16;
  static const double controlLargeSize = 40;
  static const double controlMediumGap = 8;
  static const double controlMediumPaddingBlock = 6;
  static const double controlMediumPaddingInlineCondensed = 8;
  static const double controlMediumPaddingInlineNormal = 12;
  static const double controlMediumPaddingInlineSpacious = 16;
  static const double controlMediumSize = 32;
  static const double controlMinTargetAuto = 44;
  static const double controlMinTargetCoarse = 44;
  static const double controlMinTargetFine = 16;
  static const double controlSmallGap = 4;
  static const double controlSmallPaddingBlock = 4;
  static const double controlSmallPaddingInlineCondensed = 8;
  static const double controlSmallPaddingInlineNormal = 12;
  static const double controlSmallPaddingInlineSpacious = 16;
  static const double controlSmallSize = 28;
  static const double controlXlargeGap = 8;
  static const double controlXlargePaddingBlock = 14;
  static const double controlXlargePaddingInlineCondensed = 8;
  static const double controlXlargePaddingInlineNormal = 12;
  static const double controlXlargePaddingInlineSpacious = 16;
  static const double controlXlargeSize = 48;
  static const double controlXsmallGap = 4;
  static const double controlXsmallPaddingBlock = 2;
  static const double controlXsmallPaddingInlineCondensed = 4;
  static const double controlXsmallPaddingInlineNormal = 8;
  static const double controlXsmallPaddingInlineSpacious = 12;
  static const double controlXsmallSize = 24;
  static const double controlStackLargeGapAuto = 8;
  static const double controlStackLargeGapCondensed = 8;
  static const double controlStackLargeGapSpacious = 12;
  static const double controlStackMediumGapAuto = 8;
  static const double controlStackMediumGapCondensed = 8;
  static const double controlStackMediumGapSpacious = 12;
  static const double controlStackSmallGapAuto = 8;
  static const double controlStackSmallGapCondensed = 8;
  static const double controlStackSmallGapSpacious = 16;
  static const double focusOutlineOffset = -2;
  static const double focusOutlineWidth = 2;
  static const double outlineFocusOffset = -2;
  static const double outlineFocusWidth = 2;
  static const double overlayBorderRadius = 6;
  static const double overlayHeightLarge = 432;
  static const double overlayHeightMedium = 320;
  static const double overlayHeightSmall = 256;
  static const double overlayHeightXlarge = 600;
  static const double overlayOffset = 4;
  static const double overlayPaddingCondensed = 8;
  static const double overlayPaddingNormal = 16;
  static const double overlayPaddingBlockCondensed = 4;
  static const double overlayPaddingBlockNormal = 12;
  static const double overlayWidthLarge = 640;
  static const double overlayWidthMedium = 480;
  static const double overlayWidthSmall = 320;
  static const double overlayWidthXlarge = 960;
  static const double overlayWidthXsmall = 192;
  static const double spinnerSizeLarge = 64;
  static const double spinnerSizeMedium = 32;
  static const double spinnerSizeSmall = 16;
  static const double spinnerStrokeWidthDefault = 2;
  static const double stackGapCondensed = 8;
  static const double stackGapNormal = 16;
  static const double stackGapSpacious = 24;
  static const double stackPaddingCondensed = 8;
  static const double stackPaddingNormal = 16;
  static const double stackPaddingSpacious = 24;
}

/// 모서리. 논리 픽셀(rem × 16).
abstract final class PrimerRadius {
  static const double borderRadiusDefault = 6;
  static const double borderRadiusFull = 9999;
  static const double borderRadiusLarge = 12;
  static const double borderRadiusMedium = 6;
  static const double borderRadiusSmall = 3;
}

/// 글자 크기(논리 픽셀), 줄 간격(배수), 굵기.
abstract final class PrimerText {
  static const double baseTextLineHeightLoose = 1.75;
  static const double baseTextLineHeightNormal = 1.5;
  static const double baseTextLineHeightRelaxed = 1.625;
  static const double baseTextLineHeightSnug = 1.375;
  static const double baseTextLineHeightTight = 1.25;
  static const double baseTextSize2xl = 40;
  static const double baseTextSizeLg = 20;
  static const double baseTextSizeMd = 16;
  static const double baseTextSizeSm = 14;
  static const double baseTextSizeXl = 32;
  static const double baseTextSizeXs = 12;
  static const FontWeight baseTextWeightLight = FontWeight.w300;
  static const FontWeight baseTextWeightMedium = FontWeight.w500;
  static const FontWeight baseTextWeightNormal = FontWeight.w400;
  static const FontWeight baseTextWeightSemibold = FontWeight.w600;
  static const double textBodyLineHeightLarge = 1.5;
  static const double textBodyLineHeightMedium = 1.5;
  static const double textBodyLineHeightSmall = 1.625;
  static const double textBodySizeLarge = 16;
  static const double textBodySizeMedium = 14;
  static const double textBodySizeSmall = 12;
  static const FontWeight textBodyWeight = FontWeight.w400;
  static const double textCaptionLineHeight = 1.25;
  static const double textCaptionSize = 12;
  static const FontWeight textCaptionWeight = FontWeight.w400;
  static const double textCodeBlockLineHeight = 1.5;
  static const double textCodeBlockSize = 13;
  static const FontWeight textCodeBlockWeight = FontWeight.w400;
  static const FontWeight textCodeInlineWeight = FontWeight.w400;
  static const double textDisplayLineHeight = 1.375;
  static const double textDisplaySize = 40;
  static const FontWeight textDisplayWeight = FontWeight.w500;
  static const double textSubtitleLineHeight = 1.625;
  static const double textSubtitleSize = 20;
  static const FontWeight textSubtitleWeight = FontWeight.w400;
  static const double textTitleLineHeightLarge = 1.5;
  static const double textTitleLineHeightMedium = 1.625;
  static const double textTitleLineHeightSmall = 1.5;
  static const double textTitleSizeLarge = 32;
  static const double textTitleSizeMedium = 20;
  static const double textTitleSizeSmall = 16;
  static const FontWeight textTitleWeightLarge = FontWeight.w600;
  static const FontWeight textTitleWeightMedium = FontWeight.w600;
  static const FontWeight textTitleWeightSmall = FontWeight.w600;
}
