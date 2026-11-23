import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_models.dart';

/// API 호출 결과.
sealed class ApiResult<T> {
  const ApiResult();
}

class ApiOk<T> extends ApiResult<T> {
  const ApiOk(this.value);
  final T value;
}

/// [error]가 null이면 연결 실패이거나 오류 모양이 아닌 응답이다.
class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);
  final ApiError? error;
}

/// 어느 API에서 받든 로그인 상태를 바꿔야 하는 오류.
enum AuthErrorCode {
  unauthorized('UNAUTHORIZED'),
  accountBlocked('ACCOUNT_BLOCKED'),
  passwordChangeRequired('PASSWORD_CHANGE_REQUIRED');

  const AuthErrorCode(this.code);
  final String code;
}

typedef Json = Map<String, dynamic>;

/// `docs/api/openapi.yaml`의 API를 부르는 클라이언트.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.getAccessToken,
    required this.onAuthError,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;

  /// 저장된 accessToken. 없으면 null(로그인 전).
  final String? Function() getAccessToken;

  /// UNAUTHORIZED, ACCOUNT_BLOCKED, PASSWORD_CHANGE_REQUIRED 응답을 받으면 부른다.
  final void Function(AuthErrorCode code) onAuthError;
  final http.Client _http;

  /// 로그인은 토큰 없이 부른다(규격 `security: []`).
  Future<ApiResult<LoginResponse>> login(String loginId, String password) {
    return _call(
      'POST',
      '/api/v1/auth/login',
      (Object? json) => LoginResponse.fromJson(json as Json),
      body: <String, String>{'loginId': loginId, 'password': password},
      withToken: false,
    );
  }

  /// 성공하면 새 accessToken. 임시 비밀번호 직후에는 [currentPassword]를 보내지 않는다.
  Future<ApiResult<String>> changePassword({
    String? currentPassword,
    required String newPassword,
  }) {
    return _call(
      'POST',
      '/api/v1/auth/password',
      (Object? json) => (json as Json)['accessToken'] as String,
      body: <String, String>{
        'currentPassword': ?currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<ApiResult<SessionPage>> listSessions({String? cursor, int? limit}) {
    return _call(
      'GET',
      '/api/v1/sessions',
      (Object? json) => SessionPage.fromJson(json as Json),
      query: _page(cursor, limit),
    );
  }

  /// 최신 질문부터 내려온다.
  Future<ApiResult<QuestionPage>> listQuestions(
    String sessionId, {
    String? cursor,
    int? limit,
  }) {
    return _call(
      'GET',
      '/api/v1/sessions/$sessionId/questions',
      (Object? json) => QuestionPage.fromJson(json as Json),
      query: _page(cursor, limit),
    );
  }

  Future<ApiResult<void>> deleteSession(String sessionId) {
    return _call('DELETE', '/api/v1/sessions/$sessionId', (Object? _) {});
  }

  /// 결과는 질문 전송 SSE의 `stopped` 이벤트로 온다.
  Future<ApiResult<void>> stopAnswer(String sessionId) {
    return _call('POST', '/api/v1/sessions/$sessionId/stop', (Object? _) {});
  }

  /// 질문 전송. 성공하면 SSE 본문. 스트리밍 시작 전 실패는 일반 오류 응답이다.
  Future<ApiResult<Stream<List<int>>>> sendQuestion(
    String text, {
    String? sessionId,
  }) {
    final Json body = <String, String>{'text': text, 'sessionId': ?sessionId};
    return _openStream(
      () => _send('POST', '/api/v1/sessions/questions', body: body),
    );
  }

  /// 음성 질문 전송(모바일 앱 전용). 녹음 파일을 올리면 SSE로 보정된 질문(`question`)과 답변이 온다.
  Future<ApiResult<Stream<List<int>>>> sendVoiceQuestion(
    String audioPath, {
    String? sessionId,
  }) {
    return _openStream(() async {
      final http.MultipartRequest request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$baseUrl/api/v1/voice/questions'),
            )
            ..headers.addAll(_headers(getAccessToken())..remove('content-type'))
            ..files.add(await http.MultipartFile.fromPath('audio', audioPath));
      if (sessionId != null) request.fields['sessionId'] = sessionId;
      return _http.send(request);
    });
  }

  /// 성공이면 본문 스트림, 아니면 오류 응답(차단·토큰 무효는 알린다).
  Future<ApiResult<Stream<List<int>>>> _openStream(
    Future<http.StreamedResponse> Function() send,
  ) async {
    try {
      final http.StreamedResponse response = await send();
      if (_ok(response.statusCode)) {
        return ApiOk<Stream<List<int>>>(response.stream);
      }
      final Object? json = await _readJson(response);
      return ApiFailure<Stream<List<int>>>(_failed(response.statusCode, json));
    } on Exception {
      return const ApiFailure<Stream<List<int>>>(null);
    }
  }

  Future<ApiResult<T>> _call<T>(
    String method,
    String path,
    T Function(Object? json) parse, {
    Json? body,
    Map<String, String>? query,
    bool withToken = true,
  }) async {
    try {
      final http.StreamedResponse response = await _send(
        method,
        path,
        body: body,
        query: query,
        withToken: withToken,
      );
      final Object? json = await _readJson(response);
      if (_ok(response.statusCode)) {
        return ApiOk<T>(parse(json));
      }
      return ApiFailure<T>(_failed(response.statusCode, json));
    } on Exception {
      return ApiFailure<T>(null);
    } on TypeError {
      // 성공 응답의 모양이 규격과 다르다.
      return ApiFailure<T>(null);
    }
  }

  Future<http.StreamedResponse> _send(
    String method,
    String path, {
    Json? body,
    Map<String, String>? query,
    bool withToken = true,
  }) {
    final Uri url = Uri.parse('$baseUrl$path');
    final http.Request request = http.Request(
      method,
      query == null ? url : url.replace(queryParameters: query),
    )..headers.addAll(_headers(withToken ? getAccessToken() : null));
    if (body != null) {
      request.body = jsonEncode(body);
    }
    return _http.send(request);
  }

  Map<String, String> _headers(String? token) {
    return <String, String>{
      'content-type': 'application/json',
      // ngrok 무료 도메인의 안내 페이지를 건너뛴다. localhost에서는 영향이 없다.
      'ngrok-skip-browser-warning': '1',
      'Authorization': ?(token == null ? null : 'Bearer $token'),
    };
  }

  /// 본문이 없으면(204) null.
  static Future<Object?> _readJson(http.StreamedResponse response) async {
    final List<int> bytes = await response.stream.toBytes();
    return bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
  }

  static bool _ok(int status) => status >= 200 && status < 300;

  static Map<String, String>? _page(String? cursor, int? limit) {
    final Map<String, String> query = <String, String>{
      'cursor': ?cursor,
      'limit': ?limit?.toString(),
    };
    return query.isEmpty ? null : query;
  }

  ApiError? _failed(int status, Object? json) {
    final ApiError? error = ApiError.fromJson(json);
    if (error != null && (status == 401 || status == 403)) {
      for (final AuthErrorCode code in AuthErrorCode.values) {
        if (code.code == error.code) onAuthError(code);
      }
    }
    return error;
  }
}
