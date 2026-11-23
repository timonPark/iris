/// 화면의 답변 상태. 저장된 답변은 completed 또는 stopped("중단됨").
/// disconnected는 받는 도중 연결이 끊긴 것으로, 서버는 답변을 계속 저장한다(ADR 0003).
enum AnswerState { streaming, completed, stopped, disconnected }

class ChatAnswer {
  const ChatAnswer(this.text, this.state);

  final String text;
  final AnswerState state;
}

/// 스레드의 질문 하나와 그 답변. 답변 전에 실패하면 answer 없이 error만 있다.
class ChatItem {
  const ChatItem({
    required this.key,
    required this.question,
    this.answer,
    this.error,
    this.notice,
  });

  final String key;
  final String question;
  final ChatAnswer? answer;

  /// 오류 안내(빨간 상자).
  final String? error;

  /// 알림(파란 상자). 연결이 끊긴 때.
  final String? notice;

  ChatItem withAnswer(ChatAnswer? answer) => ChatItem(
    key: key,
    question: question,
    answer: answer,
    error: error,
    notice: notice,
  );

  ChatItem withError(String error) => ChatItem(
    key: key,
    question: question,
    answer: answer,
    error: error,
    notice: notice,
  );

  ChatItem withNotice(String notice) => ChatItem(
    key: key,
    question: question,
    answer: answer,
    error: error,
    notice: notice,
  );
}

/// 백엔드와 같이 코드 포인트(글자) 수로 센다.
const int maxQuestionLength = 65536;

int questionLength(String text) => text.runes.length;

/// 받은 조각이 있으면 [state]로 남기고, 없으면 답변을 지운다(서버의 저장 규칙과 같다).
ChatAnswer? keepReceived(ChatAnswer? answer, AnswerState state) {
  if (answer == null || answer.text.isEmpty) return null;
  return ChatAnswer(answer.text, state);
}
