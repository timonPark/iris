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
}
