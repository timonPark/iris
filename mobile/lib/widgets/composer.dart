import 'package:material_ui/material_ui.dart';

import '../auth/messages.dart';
import '../chat/chat_controller.dart';
import '../chat/chat_item.dart';
import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';
import '../voice/voice_controller.dart';
import 'form_parts.dart';
import 'recorder_bar.dart';

/// 질문 입력. 입력이 비어 있으면 녹음 버튼, 글자가 있으면 보내기 버튼(샘플 #5).
/// 답변을 받는 동안에는 중지 버튼, 녹음 중에는 입력칸 자리가 녹음 막대로 바뀐다.
class Composer extends StatefulWidget {
  const Composer({super.key, required this.chat, required this.voice});

  final ChatController chat;
  final VoiceController voice;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final TextEditingController _text = TextEditingController();
  bool _tooLong = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _text.text;
    final bool over = questionLength(text) > maxQuestionLength;
    setState(() => _tooLong = over);
    if (over) return;
    widget.chat.send(text);
    _text.clear();
  }

  void _record() {
    setState(() => _tooLong = false);
    widget.voice.start();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PrimerSize.stackPaddingCondensed),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PrimerSize.baseSize8,
        children: <Widget>[
          if (_tooLong)
            const Flash(text: Messages.questionTooLong, kind: FlashKind.danger),
          ..._voiceNotice(),
          widget.voice.recording
              ? RecorderBar(voice: widget.voice)
              : _box(context),
        ],
      ),
    );
  }

  List<Widget> _voiceNotice() {
    return switch (widget.voice.notice) {
      VoiceNotice.permissionNeeded => <Widget>[
        const Flash(text: Messages.micPermissionNeeded, kind: FlashKind.danger),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: widget.voice.openSettings,
            style: defaultButtonStyle(context, primerColorsOf(context)),
            child: const Text('설정 열기'),
          ),
        ),
      ],
      VoiceNotice.cancelledInBackground => <Widget>[
        const Flash(
          text: Messages.recordingCancelledInBackground,
          kind: FlashKind.info,
        ),
      ],
      VoiceNotice.recorderFailed => <Widget>[
        const Flash(text: Messages.recorderFailed, kind: FlashKind.danger),
      ],
      null => <Widget>[],
    };
  }

  Widget _box(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    return Container(
      padding: const EdgeInsets.all(PrimerSize.baseSize4),
      decoration: BoxDecoration(
        color: c.bgColorDefault,
        border: Border.all(
          color: c.borderColorDefault,
          width: PrimerSize.borderWidthThin,
        ),
        borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: PrimerSize.baseSize8,
        children: <Widget>[
          Expanded(child: _input(context)),
          _action(c),
        ],
      ),
    );
  }

  /// 보내기 자리의 버튼: 답변 중이면 중지, 비어 있으면 녹음, 글자가 있으면 보내기.
  Widget _action(PrimerColors c) {
    final ChatController chat = widget.chat;
    if (chat.streaming && !chat.processingVoice) return _stopButton(c);
    if (_text.text.trim().isEmpty) {
      final bool busy = chat.loading || chat.streaming;
      return _iconButton(c, '녹음 시작', Icons.mic, busy ? null : _record);
    }
    final bool enabled = !chat.loading && !chat.streaming;
    return _iconButton(
      c,
      '질문 보내기',
      Icons.arrow_upward,
      enabled ? _submit : null,
    );
  }

  Widget _input(BuildContext context) {
    return TextField(
      controller: _text,
      enabled: !widget.chat.processingVoice,
      minLines: 1,
      maxLines: 5,
      onChanged: (String _) => widget.voice.clearNotice(),
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: const InputDecoration(
        hintText: '질문을 입력하세요',
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: PrimerSize.baseSize12,
          horizontal: PrimerSize.baseSize8,
        ),
      ),
    );
  }

  Widget _iconButton(
    PrimerColors c,
    String tooltip,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(PrimerSize.controlMinTargetCoarse),
        backgroundColor: c.buttonPrimaryBgColorRest,
        foregroundColor: c.buttonPrimaryFgColorRest,
        disabledBackgroundColor: c.buttonPrimaryBgColorDisabled,
        disabledForegroundColor: c.buttonPrimaryFgColorDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
        ),
      ),
    );
  }

  Widget _stopButton(PrimerColors c) {
    return OutlinedButton.icon(
      onPressed: widget.chat.canStop ? widget.chat.stop : null,
      icon: const Icon(Icons.stop),
      label: const Text('중지'),
      style: defaultButtonStyle(context, c),
    );
  }
}
