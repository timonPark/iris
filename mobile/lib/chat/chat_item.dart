/// 화면의 답변 상태. 저장된 답변은 completed 또는 stopped("중단됨").
/// disconnected는 받는 도중 연결이 끊긴 것으로, 서버는 답변을 계속 저장한다(ADR 0003).
enum AnswerState { streaming, completed, stopped, disconnected }

class ChatAnswer {
  const ChatAnswer(this.text, this.state);

  final String text;
  final AnswerState state;
}

/// 스레드의 질문 하나와 그 답변. 답변 전에 실패하면 answer 없이 error만 있다.
/// 음성 질문은 보정된 텍스트가 오기 전까지 [question]이 비어 있고 [pending]이다.
class ChatItem {
  const ChatItem({
    required this.key,
    required this.question,
    this.answer,
    this.error,
    this.notice,
    this.pending = false,
    this.autoStopped = false,
  });

  final String key;
  final String question;
  final ChatAnswer? answer;

  /// 오류 안내(빨간 상자).
  final String? error;

  /// 알림(파란 상자). 연결이 끊긴 때.
  final String? notice;

  /// 음성을 질문으로 바꾸는 중.
  final bool pending;

  /// 녹음이 2분이 되어 자동으로 끝내고 보낸 음성 질문.
  final bool autoStopped;

  ChatItem _copy({
    String? question,
    ChatAnswer? answer,
    bool clearAnswer = false,
    String? error,
    String? notice,
    bool? pending,
  }) {
    return ChatItem(
      key: key,
      question: question ?? this.question,
      answer: clearAnswer ? null : (answer ?? this.answer),
      error: error ?? this.error,
      notice: notice ?? this.notice,
      pending: pending ?? this.pending,
      autoStopped: autoStopped,
    );
  }

  ChatItem withAnswer(ChatAnswer? answer) =>
      _copy(answer: answer, clearAnswer: answer == null);

  ChatItem withError(String error) => _copy(error: error, pending: false);

  ChatItem withNotice(String notice) => _copy(notice: notice);

  /// 보정된 질문 텍스트가 왔다.
  ChatItem withQuestion(String question) =>
      _copy(question: question, pending: false);
}

/// 백엔드와 같이 코드 포인트(글자) 수로 센다.
const int maxQuestionLength = 65536;

int questionLength(String text) => text.runes.length;

/// 받은 조각이 있으면 [state]로 남기고, 없으면 답변을 지운다(서버의 저장 규칙과 같다).
ChatAnswer? keepReceived(ChatAnswer? answer, AnswerState state) {
  if (answer == null || answer.text.isEmpty) return null;
  return ChatAnswer(answer.text, state);
}
