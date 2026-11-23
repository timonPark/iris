import 'package:material_ui/material_ui.dart';

import '../auth/messages.dart';
import '../chat/chat_controller.dart';
import '../chat/chat_item.dart';
import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';
import 'form_parts.dart';

/// 세션의 질문과 답변. 비어 있으면 새 세션 안내.
/// 아래에서부터 쌓아(reverse) 맨 아래를 보고 있으면 답변을 따라 내려간다.
class ThreadView extends StatelessWidget {
  const ThreadView({super.key, required this.chat});

  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    if (chat.items.isEmpty && !chat.loading && chat.loadError == null) {
      return const _Empty();
    }
    return SingleChildScrollView(
      reverse: true,
      padding: const EdgeInsets.all(PrimerSize.stackPaddingNormal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PrimerSize.stackGapSpacious,
        children: <Widget>[
          if (chat.loadError != null)
            Flash(text: chat.loadError!, kind: FlashKind.danger),
          for (final ChatItem item in chat.items) _Item(item: item),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PrimerSize.stackPaddingSpacious),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: PrimerSize.baseSize8,
          children: <Widget>[
            Text('Iris에게 질문하세요', style: text.titleMedium),
            Text(
              '입력하거나 녹음 버튼을 눌러 말해 보세요. 지난 대화는 세션 목록에서 볼 수 있습니다.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: primerColorsOf(context).fgColorMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item});

  final ChatItem item;

  @override
  Widget build(BuildContext context) {
    final ChatAnswer? answer = item.answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PrimerSize.stackGapSpacious,
      children: <Widget>[
        // 2분 자동 종료 안내는 처리 중일 때만(샘플): 보정된 질문이 오면 일반 질문과 같다.
        if (item.autoStopped && item.pending)
          const Flash(text: Messages.voiceAutoStopped, kind: FlashKind.info),
        if (item.pending)
          const _QuestionBubble(text: Messages.voiceProcessing, pending: true),
        if (item.question.isNotEmpty) _QuestionBubble(text: item.question),
        if (answer != null) _AnswerView(answer: answer),
        if (item.notice != null)
          Flash(text: item.notice!, kind: FlashKind.info),
        if (item.error != null)
          Flash(text: item.error!, kind: FlashKind.danger),
      ],
    );
  }
}

/// 질문 말풍선: 오른쪽 정렬, 최대 너비는 전체에서 큰 컨트롤 하나만큼 뺀 값.
class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({required this.text, this.pending = false});

  final String text;

  /// 음성을 질문으로 바꾸는 중(점 아이콘과 함께).
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: PrimerSize.controlLargeSize),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: PrimerSize.baseSize8,
            horizontal: PrimerSize.baseSize12,
          ),
          decoration: BoxDecoration(
            color: primerColorsOf(context).bgColorMuted,
            borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusLarge),
          ),
          child: pending ? _pendingText(context) : _text(context),
        ),
      ),
    );
  }

  Widget _text(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyLarge);

  Widget _pendingText(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: PrimerSize.baseSize8,
        children: <Widget>[
          const Icon(Icons.more_horiz, size: PrimerText.textBodySizeLarge),
          Flexible(child: _text(context)),
        ],
      ),
    );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView({required this.answer});

  final ChatAnswer answer;

  @override
  Widget build(BuildContext context) {
    final bool streaming = answer.state == AnswerState.streaming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PrimerSize.baseSize8,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: answer.text,
            children: <InlineSpan>[
              if (streaming) const WidgetSpan(child: _Caret()),
            ],
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (streaming) const _Meta(),
        if (answer.state == AnswerState.stopped) const _StoppedLabel(),
      ],
    );
  }
}

/// 받는 중인 답변 끝의 커서.
class _Caret extends StatelessWidget {
  const _Caret();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PrimerSize.baseSize8,
      height: PrimerText.textBodySizeLarge,
      margin: const EdgeInsets.only(left: PrimerSize.baseSize2),
      decoration: BoxDecoration(
        color: primerColorsOf(context).fgColorAccent,
        borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusSmall),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        '답변을 받는 중…',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: primerColorsOf(context).fgColorMuted),
      ),
    );
  }
}

/// "중단됨" 표시(주의 색 테두리의 알약 모양).
class _StoppedLabel extends StatelessWidget {
  const _StoppedLabel();

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PrimerSize.baseSize8),
      decoration: BoxDecoration(
        border: Border.all(
          color: c.borderColorAttentionEmphasis,
          width: PrimerSize.borderWidthThin,
        ),
        borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusFull),
      ),
      child: Text(
        '중단됨',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: c.fgColorAttention),
      ),
    );
  }
}
