import 'dart:convert';

/// 질문 전송 SSE 이벤트(`docs/api/openapi.yaml` 상단의 SSE 표).
sealed class SseEvent {
  const SseEvent();
}

/// 첫 질문일 때 새로 만들 세션 ID. 중지 API에 쓴다.
class SessionEvent extends SseEvent {
  const SessionEvent(this.id);
  final String id;
}

/// 보정된 질문 텍스트(음성 질문에서만 온다).
class QuestionEvent extends SseEvent {
  const QuestionEvent(this.text);
  final String text;
}

class DeltaEvent extends SseEvent {
  const DeltaEvent(this.text);
  final String text;
}

class DoneEvent extends SseEvent {
  const DoneEvent();
}

class StoppedEvent extends SseEvent {
  const StoppedEvent();
}

class ErrorEvent extends SseEvent {
  const ErrorEvent(this.code, this.message);
  final String code;
  final String message;
}

/// 바이트 스트림을 이벤트로. 주석 줄(`: keepalive`)과 모르는 이벤트는 건너뛴다.
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  String name = 'message';
  final List<String> data = <String>[];
  await for (final String line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      final SseEvent? event = _event(name, data.join('\n'));
      if (data.isNotEmpty && event != null) yield event;
      name = 'message';
      data.clear();
    } else if (line.startsWith('event:')) {
      name = _value(line, 'event:');
    } else if (line.startsWith('data:')) {
      data.add(_value(line, 'data:'));
    }
  }
}

/// SSE 표준: 콜론 뒤의 공백 하나만 뗀다.
String _value(String line, String field) {
  final String value = line.substring(field.length);
  return value.startsWith(' ') ? value.substring(1) : value;
}

SseEvent? _event(String name, String raw) {
  final Map<String, dynamic> data;
  try {
    data = jsonDecode(raw) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }
  return switch (name) {
    'session' => SessionEvent(data['id'] as String),
    'question' => QuestionEvent(data['text'] as String),
    'delta' => DeltaEvent(data['text'] as String),
    'done' => const DoneEvent(),
    'stopped' => const StoppedEvent(),
    'error' => ErrorEvent(data['code'] as String, data['message'] as String),
    _ => null,
  };
}
