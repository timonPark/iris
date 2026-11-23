/// 백엔드 주소. `flutter run --dart-define=API_BASE_URL=...`로 바꾼다.
const String _defaultApiBaseUrl = 'http://localhost:8000';

final String apiBaseUrl = resolveApiBaseUrl(
  const String.fromEnvironment('API_BASE_URL'),
);

/// 비운 값이면 기본 주소를 쓰고, 끝의 `/`는 뺀다(웹의 `resolveApiBaseUrl`과 같다).
String resolveApiBaseUrl(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return _defaultApiBaseUrl;
  }
  return trimmed.replaceFirst(RegExp(r'/+$'), '');
}
