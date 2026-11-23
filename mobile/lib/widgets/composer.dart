import 'package:material_ui/material_ui.dart';

import '../auth/messages.dart';
import '../chat/chat_controller.dart';
import '../chat/chat_item.dart';
import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';
import 'form_parts.dart';

/// 질문 입력. 답변을 받는 동안에는 보내기 자리에 중지 버튼.
/// 음성 입력(#32)에서 입력이 비어 있을 때 녹음 버튼으로 바꾼다.
class Composer extends StatefulWidget {
  const Composer({super.key, required this.chat});

  final ChatController chat;

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
          _box(context),
        ],
      ),
    );
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
          widget.chat.streaming ? _stopButton(c) : _sendButton(c),
        ],
      ),
    );
  }

  Widget _input(BuildContext context) {
    return TextField(
      controller: _text,
      minLines: 1,
      maxLines: 5,
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

  Widget _sendButton(PrimerColors c) {
    final bool enabled = !widget.chat.loading && _text.text.trim().isNotEmpty;
    return IconButton.filled(
      tooltip: '질문 보내기',
      onPressed: enabled ? _submit : null,
      icon: const Icon(Icons.arrow_upward),
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
