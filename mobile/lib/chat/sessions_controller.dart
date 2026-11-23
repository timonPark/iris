import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_models.dart';
import '../auth/messages.dart';

/// 세션 목록(최근 활동 순). 목록 끝이 보이면 [loadMore]로 이어 불러온다.
class SessionsController extends ChangeNotifier {
  SessionsController(this._client);

  static const int pageSize = 20;

  final ApiClient _client;
  List<Session> items = <Session>[];

  /// 아직 불러오지 않은 페이지가 있다.
  bool hasMore = true;
  String? error;
  String? _cursor;
  bool _inFlight = false;
  bool _disposed = false;

  /// 지운 세션. 받던 답변이 나중에 저장되어도 다시 올리지 않는다.
  final Set<String> _removed = <String>{};

  /// 불러온 횟수. 목록 끝 표시를 새로 만들어 다음 페이지를 부르게 한다.
  int loads = 0;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> loadMore() async {
    if (_inFlight || !hasMore) return;
    _inFlight = true;
    final ApiResult<SessionPage> result = await _client.listSessions(
      cursor: _cursor,
      limit: pageSize,
    );
    _inFlight = false;
    loads++;
    switch (result) {
      case ApiOk<SessionPage>(:final SessionPage value):
        items = <Session>[
          ...items,
          ...value.items.where((Session s) => !_has(s.id)),
        ];
        _cursor = value.nextCursor;
        hasMore = value.nextCursor != null;
        error = null;
      case ApiFailure<SessionPage>(error: final ApiError? failure):
        error = errorText(failure);
    }
    notifyListeners();
  }

  /// 새로 생겼거나 질문이 온 세션을 맨 위로.
  void putOnTop(Session session) {
    if (_removed.contains(session.id)) return;
    items = <Session>[session, ..._without(session.id)];
    notifyListeners();
  }

  void remove(String id) {
    _removed.add(id);
    items = _without(id);
    notifyListeners();
  }

  bool _has(String id) => items.any((Session s) => s.id == id);

  List<Session> _without(String id) =>
      items.where((Session s) => s.id != id).toList();
}
