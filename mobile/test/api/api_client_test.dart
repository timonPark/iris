import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iris/api/api_client.dart';
import 'package:iris/api/api_models.dart';

import '../support/fake_api.dart';

ApiClient clientFor(
  http.Client httpClient, {
  String? token,
  List<AuthErrorCode>? authErrors,
}) {
  return ApiClient(
    baseUrl: 'http://api.test',
    httpClient: httpClient,
    getAccessToken: () => token,
    onAuthError: (AuthErrorCode code) => authErrors?.add(code),
  );
}

void main() {
  test('로그인 응답을 읽고, 아이디와 비밀번호를 보낸다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/auth/login': (_) => loginOk(passwordChangeRequired: true),
    });

    final ApiResult<LoginResponse> result = await clientFor(api.client)
        .login('jhpark', 'pw');

    final LoginResponse data = (result as ApiOk<LoginResponse>).value;
    expect(data.accessToken, 'token-1');
    expect(data.role, Role.user);
    expect(data.passwordChangeRequired, isTrue);
    expect(requestJson(api.requests.single), <String, String>{
      'loginId': 'jhpark',
      'password': 'pw',
    });
    expect(api.requests.single.headers['Authorization'], isNull);
  });

  test('저장한 토큰과 ngrok 안내 건너뛰기 헤더를 보낸다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/auth/password': (_) =>
          jsonResponse(200, <String, String>{'accessToken': 'token-2'}),
    });

    final ApiResult<String> result = await clientFor(
      api.client,
      token: 'token-1',
    ).changePassword(newPassword: 'newpass12');

    expect((result as ApiOk<String>).value, 'token-2');
    final http.Request request = api.requests.single;
    expect(request.headers['Authorization'], 'Bearer token-1');
    expect(request.headers['ngrok-skip-browser-warning'], '1');
    expect(requestJson(request), <String, String>{'newPassword': 'newpass12'});
  });

  test('평소 변경에는 현재 비밀번호도 보낸다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/auth/password': (_) =>
          jsonResponse(200, <String, String>{'accessToken': 'token-2'}),
    });

    await clientFor(
      api.client,
      token: 'token-1',
    ).changePassword(currentPassword: 'old', newPassword: 'newpass12');

    expect(requestJson(api.requests.single), <String, String>{
      'currentPassword': 'old',
      'newPassword': 'newpass12',
    });
  });

  test('오류 응답은 code와 message로 돌려준다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/auth/login': (_) =>
          errorResponse(401, 'INVALID_CREDENTIALS', '아이디 또는 비밀번호가 올바르지 않습니다.'),
    });
    final List<AuthErrorCode> authErrors = <AuthErrorCode>[];

    final ApiResult<LoginResponse> result = await clientFor(
      api.client,
      authErrors: authErrors,
    ).login('a', 'b');

    final ApiError? error = (result as ApiFailure<LoginResponse>).error;
    expect(error?.code, 'INVALID_CREDENTIALS');
    expect(error?.message, '아이디 또는 비밀번호가 올바르지 않습니다.');
    expect(authErrors, isEmpty);
  });

  test('차단, 토큰 무효, 비밀번호 변경 필요는 어느 API에서 받든 알린다', () async {
    final List<String> codes = <String>[
      'ACCOUNT_BLOCKED',
      'UNAUTHORIZED',
      'PASSWORD_CHANGE_REQUIRED',
    ];
    final List<AuthErrorCode> authErrors = <AuthErrorCode>[];
    for (final String code in codes) {
      final FakeApi api = FakeApi(<String, FakeHandler>{
        '/api/v1/auth/password': (_) =>
            errorResponse(code == 'UNAUTHORIZED' ? 401 : 403, code, '안내'),
      });
      await clientFor(
        api.client,
        token: 't',
        authErrors: authErrors,
      ).changePassword(newPassword: 'newpass12');
    }

    expect(authErrors, <AuthErrorCode>[
      AuthErrorCode.accountBlocked,
      AuthErrorCode.unauthorized,
      AuthErrorCode.passwordChangeRequired,
    ]);
  });

  test('연결 실패나 오류 모양이 아닌 응답은 error가 null', () async {
    final MockClient down = MockClient(
      (_) async => throw http.ClientException('down'),
    );
    final MockClient html = MockClient(
      (_) async => http.Response('<html>', 502),
    );

    final ApiResult<LoginResponse> a = await clientFor(down).login('a', 'b');
    final ApiResult<LoginResponse> b = await clientFor(html).login('a', 'b');

    expect((a as ApiFailure<LoginResponse>).error, isNull);
    expect((b as ApiFailure<LoginResponse>).error, isNull);
  });

  test('로그인에는 남아 있는 토큰을 보내지 않는다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/auth/login': (_) => loginOk(),
    });

    await clientFor(api.client, token: 'old').login('a', 'b');

    expect(api.requests.single.headers['Authorization'], isNull);
  });

  test('성공 응답의 모양이 다르면 error가 null', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/auth/login': (_) => jsonResponse(200, <int>[1]),
      '/api/v1/auth/password': (_) =>
          jsonResponse(200, <String, int>{'accessToken': 1}),
    });
    final ApiClient client = clientFor(api.client, token: 't');

    final ApiResult<LoginResponse> a = await client.login('a', 'b');
    final ApiResult<String> b = await client.changePassword(newPassword: 'x');

    expect((a as ApiFailure<LoginResponse>).error, isNull);
    expect((b as ApiFailure<String>).error, isNull);
  });

  test('세션 목록은 커서와 개수를 쿼리로 보내고 페이지를 읽는다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions': (_) => sessionPage(<String>['가', '나'], next: 'c2'),
    });

    final ApiResult<SessionPage> result = await clientFor(
      api.client,
      token: 't',
    ).listSessions(cursor: 'c1', limit: 20);

    final SessionPage page = (result as ApiOk<SessionPage>).value;
    expect(page.items.map((Session s) => s.title), <String>['가', '나']);
    expect(page.items.first.id, 's0');
    expect(page.nextCursor, 'c2');
    final http.Request request = api.requests.single;
    expect(request.method, 'GET');
    expect(request.url.queryParameters, <String, String>{
      'cursor': 'c1',
      'limit': '20',
    });
  });

  test('세션 열람은 질문과 답변을 읽는다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions/s1/questions': (_) =>
          questionPage(<(String, String, String)>[('질문', '답', 'stopped')]),
    });

    final ApiResult<QuestionPage> result = await clientFor(
      api.client,
      token: 't',
    ).listQuestions('s1', limit: 100);

    final Question q = (result as ApiOk<QuestionPage>).value.items.single;
    expect(q.text, '질문');
    expect(q.answer.text, '답');
    expect(q.answer.status, AnswerStatus.stopped);
    expect(api.requests.single.url.queryParameters, <String, String>{
      'limit': '100',
    });
  });

  test('세션 삭제와 답변 중지는 본문 없는 204를 성공으로 본다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions/s1': (_) => http.Response('', 204),
      '/api/v1/sessions/s1/stop': (_) => http.Response('', 204),
    });
    final ApiClient client = clientFor(api.client, token: 't');

    expect(await client.deleteSession('s1'), isA<ApiOk<void>>());
    expect(await client.stopAnswer('s1'), isA<ApiOk<void>>());
    expect(api.requests.map((http.Request r) => r.method), <String>[
      'DELETE',
      'POST',
    ]);
  });

  test('질문 전송은 스트림을 돌려주고, 지난 세션이면 세션 ID도 보낸다', () async {
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions/questions': (_) => sseReply(<String>[
        sseEvent('delta', <String, Object>{'text': '답'}),
      ]),
    });

    final ApiResult<Stream<List<int>>> result = await clientFor(
      api.client,
      token: 't',
    ).sendQuestion('질문', sessionId: 's1');

    final Stream<List<int>> body = (result as ApiOk<Stream<List<int>>>).value;
    expect(
      utf8.decode(await body.expand((List<int> b) => b).toList()),
      contains('답'),
    );
    expect(requestJson(api.requests.single), <String, String>{
      'text': '질문',
      'sessionId': 's1',
    });
  });

  test('질문 전송이 시작 전에 실패하면 오류이고 차단은 알린다', () async {
    final List<AuthErrorCode> authErrors = <AuthErrorCode>[];
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/sessions/questions': (_) =>
          errorResponse(403, 'ACCOUNT_BLOCKED', '차단된 계정입니다.'),
    });

    final ApiResult<Stream<List<int>>> result = await clientFor(
      api.client,
      token: 't',
      authErrors: authErrors,
    ).sendQuestion('질문');

    expect(
      (result as ApiFailure<Stream<List<int>>>).error?.code,
      'ACCOUNT_BLOCKED',
    );
    expect(authErrors, <AuthErrorCode>[AuthErrorCode.accountBlocked]);
    expect(requestJson(api.requests.single), <String, String>{'text': '질문'});
  });

  test('음성 질문은 녹음 파일과 세션 ID를 multipart로 보내고 스트림을 돌려준다', () async {
    final Directory dir = await Directory.systemTemp.createTemp('iris-test-');
    final File audio = File('${dir.path}/voice.m4a')
      ..writeAsBytesSync(<int>[7, 8, 9]);
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/voice/questions': (_) => sseReply(<String>[
        sseEvent('question', <String, Object>{'text': '보정된 질문'}),
      ]),
    });

    final ApiResult<Stream<List<int>>> result = await clientFor(
      api.client,
      token: 't',
    ).sendVoiceQuestion(audio.path, sessionId: 's1');

    expect(result, isA<ApiOk<Stream<List<int>>>>());
    final http.Request request = api.requests.single;
    expect(request.headers['content-type'], startsWith('multipart/form-data'));
    expect(request.headers['Authorization'], 'Bearer t');
    final String body = latin1.decode(request.bodyBytes);
    expect(body, contains('name="audio"; filename="voice.m4a"'));
    expect(body, contains('name="sessionId"'));
    expect(body, contains('s1'));
  });

  test('음성 질문이 인식에 실패하면 규격의 오류를 돌려준다', () async {
    final Directory dir = await Directory.systemTemp.createTemp('iris-test-');
    final File audio = File('${dir.path}/voice.m4a')
      ..writeAsBytesSync(<int>[1]);
    final FakeApi api = FakeApi(<String, FakeHandler>{
      '/api/v1/voice/questions': (_) => errorResponse(
        422,
        'SPEECH_NOT_RECOGNIZED',
        '음성을 인식하지 못했습니다. 다시 녹음해 주세요.',
      ),
    });

    final ApiResult<Stream<List<int>>> result = await clientFor(
      api.client,
      token: 't',
    ).sendVoiceQuestion(audio.path);

    expect(
      (result as ApiFailure<Stream<List<int>>>).error?.code,
      'SPEECH_NOT_RECOGNIZED',
    );
    expect(
      latin1.decode(api.requests.single.bodyBytes),
      isNot(contains('sessionId')),
    );
  });
}
