import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';
import '../voice/voice_controller.dart';
import 'form_parts.dart';

/// 녹음 중에 입력칸 자리에 나오는 막대(샘플 #5): 빨간 점, "녹음 중", `0:42 / 2:00`, 진행 막대, 취소, 보내기.
/// "다시 탭하면 끝내고 보낸다"는 녹음 버튼 자리의 보내기 버튼이다.
class RecorderBar extends StatelessWidget {
  const RecorderBar({super.key, required this.voice});

  final VoiceController voice;

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    return Container(
      padding: const EdgeInsets.all(PrimerSize.baseSize8),
      decoration: BoxDecoration(
        color: c.bgColorDangerMuted,
        border: Border.all(
          color: c.borderColorDangerMuted,
          width: PrimerSize.borderWidthThin,
        ),
        borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PrimerSize.baseSize8,
        children: <Widget>[
          _status(context, c),
          _track(c),
          _buttons(context, c),
        ],
      ),
    );
  }

  Widget _status(BuildContext context, PrimerColors c) {
    return Row(
      spacing: PrimerSize.baseSize8,
      children: <Widget>[
        Container(
          width: PrimerSize.baseSize12,
          height: PrimerSize.baseSize12,
          decoration: BoxDecoration(
            color: c.bgColorDangerEmphasis,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              '녹음 중',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: PrimerText.baseTextWeightSemibold),
            ),
          ),
        ),
        _time(context),
      ],
    );
  }

  /// `0:42 / 2:00`. 화면 읽기는 "2분 중 42초".
  Widget _time(BuildContext context) {
    return Semantics(
      label: '2분 중 ${_spoken(voice.elapsed)}',
      excludeSemantics: true,
      child: Text(
        '${_clock(voice.elapsed)} / ${_clock(VoiceController.maxLength)}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _track(PrimerColors c) {
    final double done =
        voice.elapsed.inMilliseconds / VoiceController.maxLength.inMilliseconds;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusFull),
      child: LinearProgressIndicator(
        value: done.clamp(0, 1),
        minHeight: PrimerSize.baseSize4,
        backgroundColor: c.bgColorNeutralMuted,
        color: c.bgColorDangerEmphasis,
      ),
    );
  }

  Widget _buttons(BuildContext context, PrimerColors c) {
    return Row(
      children: <Widget>[
        OutlinedButton(
          onPressed: voice.cancel,
          style: defaultButtonStyle(context, c),
          child: const Text('취소'),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: voice.finish,
          icon: const Icon(Icons.arrow_upward),
          label: const Text('보내기'),
          style: primaryButtonStyle(context, c),
        ),
      ],
    );
  }

  /// 화면 읽기용: `42초`, `1분 15초`.
  static String _spoken(Duration d) {
    final int minutes = d.inMinutes;
    final int seconds = d.inSeconds % 60;
    return minutes == 0 ? '$seconds초' : '$minutes분 $seconds초';
  }

  /// `0:42`처럼 분:초.
  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
