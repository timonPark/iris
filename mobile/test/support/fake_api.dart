import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 요청 하나에 대한 가짜 백엔드 응답.
typedef FakeHandler = http.Response Function(http.Request request);

/// 본문을 조금씩 흘려보내는 응답(SSE).
typedef FakeStreamHandler = http.StreamedResponse Function(
  http.Request request,
);

/// 경로별로 응답을 정하는 가짜 백엔드. 받은 요청은 [requests]에 쌓인다.
class FakeApi {
  FakeApi(this.handlers, {this.streams = const <String, FakeStreamHandler>{}});

  final Map<String, FakeHandler> handlers;
  final Map<String, FakeStreamHandler> streams;
  final List<http.Request> requests = <http.Request>[];

  /// [path]로 온 요청만.
  List<http.Request> requestsTo(String path) =>
      requests.where((http.Request r) => r.url.path == path).toList();

  late final MockClient client = MockClient.streaming((
    http.BaseRequest base,
    http.ByteStream body,
  ) async {
    final http.Request request = http.Request(base.method, base.url)
      ..headers.addAll(base.headers)
      ..bodyBytes = await body.toBytes();
    requests.add(request);
    final FakeStreamHandler? stream = streams[request.url.path];
    if (stream != null) {
      return stream(request);
    }
    final FakeHandler? handler = handlers[request.url.path];
    final http.Response response =
        handler?.call(request) ?? jsonResponse(404, <String, Object>{});
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  });
}

http.Response jsonResponse(int status, Object body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

http.Response errorResponse(int status, String code, String message) {
  return jsonResponse(status, <String, Object>{
    'error': <String, String>{'code': code, 'message': message},
  });
}

http.Response loginOk({
  String token = 'token-1',
  String role = 'user',
  bool passwordChangeRequired = false,
}) {
  return jsonResponse(200, <String, Object>{
    'accessToken': token,
    'role': role,
    'passwordChangeRequired': passwordChangeRequired,
  });
}

Map<String, dynamic> requestJson(http.Request request) {
  return jsonDecode(request.body) as Map<String, dynamic>;
}

/// SSE 이벤트 하나의 본문.
String sseEvent(String event, Map<String, Object> data) {
  return 'event: $event\ndata: ${jsonEncode(data)}\n\n';
}

/// 한 번에 끝나는 SSE 응답.
http.Response sseReply(List<String> events) {
  return http.Response.bytes(
    utf8.encode(events.join()),
    200,
    headers: <String, String>{'content-type': 'text/event-stream'},
  );
}

/// 이벤트를 하나씩 흘리는 SSE. [handler]를 질문 전송 경로에 걸고 [send]로 흘린다.
class ControlledSse {
  final StreamController<List<int>> _body = StreamController<List<int>>();

  http.StreamedResponse handler(http.Request request) {
    return http.StreamedResponse(
      _body.stream,
      200,
      headers: <String, String>{'content-type': 'text/event-stream'},
    );
  }

  void send(String event, Map<String, Object> data) {
    _body.add(utf8.encode(sseEvent(event, data)));
  }

  /// 끝 이벤트 없이 연결이 끊긴다.
  Future<void> cut() => _body.close();

  /// 연결 오류로 끊긴다.
  void fail() {
    _body.addError(http.ClientException('connection lost'));
    _body.close();
  }
}

/// 세션 목록 한 페이지.
http.Response sessionPage(List<String> titles, {String? next, int from = 0}) {
  return jsonResponse(200, <String, Object>{
    'items': <Map<String, String>>[
      for (int i = 0; i < titles.length; i++)
        <String, String>{
          'id': 's${from + i}',
          'title': titles[i],
          'updatedAt': '2026-11-23T00:00:00Z',
        },
    ],
    'nextCursor': ?next,
  });
}

/// 세션 열람 한 페이지(최신 질문부터).
http.Response questionPage(
  List<(String question, String answer, String status)> newestFirst, {
  String? next,
}) {
  return jsonResponse(200, <String, Object>{
    'items': <Map<String, Object>>[
      for (final (String q, String a, String status) in newestFirst)
        <String, Object>{
          'id': 'q-$q',
          'text': q,
          'createdAt': '2026-11-23T00:00:00Z',
          'answer': <String, String>{
            'id': 'a-$q',
            'text': a,
            'status': status,
            'createdAt': '2026-11-23T00:00:00Z',
          },
        },
    ],
    'nextCursor': ?next,
  });
}
