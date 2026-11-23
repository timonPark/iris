import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 요청 하나에 대한 가짜 백엔드 응답.
typedef FakeHandler = http.Response Function(http.Request request);

/// 경로별로 응답을 정하는 가짜 백엔드. 받은 요청은 [requests]에 쌓인다.
class FakeApi {
  FakeApi(this.handlers);

  final Map<String, FakeHandler> handlers;
  final List<http.Request> requests = <http.Request>[];

  late final MockClient client = MockClient((http.Request request) async {
    requests.add(request);
    final FakeHandler? handler = handlers[request.url.path];
    if (handler == null) {
      return jsonResponse(404, <String, Object>{});
    }
    return handler(request);
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
