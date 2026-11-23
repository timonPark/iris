import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris/chat/sse.dart';

Future<List<SseEvent>> parse(List<String> chunks) {
  return parseSse(Stream<List<int>>.fromIterable(chunks.map(utf8.encode)))
      .toList();
}

void main() {
  test('질문 전송 이벤트를 차례로 읽는다', () async {
    final List<SseEvent> events = await parse(<String>[
      'event: session\ndata: {"id":"s1"}\n\n',
      'event: delta\ndata: {"text":"안녕"}\n\n',
      'event: done\ndata: {"answerId":"a1"}\n\n',
    ]);

    expect(events, <Matcher>[
      isA<SessionEvent>().having((SessionEvent e) => e.id, 'id', 's1'),
      isA<DeltaEvent>().having((DeltaEvent e) => e.text, 'text', '안녕'),
      isA<DoneEvent>(),
    ]);
  });

  test('조각 경계에서 나뉜 줄, CRLF, 주석, 모르는 이벤트를 다룬다', () async {
    final List<SseEvent> events = await parse(<String>[
      ': keepalive\r\n\r\nevent: del',
      'ta\r\ndata: {"text":"a\\nb"}\r',
      '\n\r\nevent: unknown\ndata: {}\n\n',
      'event: stopped\ndata: {"answerId":"a1"}\n\n',
      'event: error\ndata: {"code":"SERVER_ERROR","message":"오류"}\n\n',
    ]);

    expect(events, hasLength(3));
    expect((events[0] as DeltaEvent).text, 'a\nb');
    expect(events[1], isA<StoppedEvent>());
    final ErrorEvent error = events[2] as ErrorEvent;
    expect(error.code, 'SERVER_ERROR');
    expect(error.message, '오류');
  });

  test('보정된 질문(음성) 이벤트도 읽는다', () async {
    final List<SseEvent> events = await parse(<String>[
      'event: question\ndata: {"text":"질문"}\n\n',
    ]);
    expect((events.single as QuestionEvent).text, '질문');
  });
}
