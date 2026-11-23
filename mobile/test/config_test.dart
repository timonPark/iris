import 'package:flutter_test/flutter_test.dart';
import 'package:iris/config.dart';

void main() {
  test('API_BASE_URL을 넣지 않으면 http://localhost:8000이다', () {
    expect(apiBaseUrl, 'http://localhost:8000');
  });

  test('비운 값이나 공백이면 기본 주소다', () {
    expect(resolveApiBaseUrl(''), 'http://localhost:8000');
    expect(resolveApiBaseUrl('  '), 'http://localhost:8000');
  });

  test('넣은 값은 앞뒤 공백과 끝의 /를 뺀 주소다(웹과 같다)', () {
    expect(resolveApiBaseUrl('http://10.0.2.2:8000'), 'http://10.0.2.2:8000');
    expect(
      resolveApiBaseUrl(' http://10.0.2.2:8000// '),
      'http://10.0.2.2:8000',
    );
  });
}
