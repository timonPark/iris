import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../api/api_models.dart';
import '../auth/messages.dart';
import 'chat_item.dart';
import 'sse.dart';

/// 질문 하나의 답변 읽기. 다른 세션으로 바꿔도(generation이 바뀌어도) 끝까지 읽는다.
class _Run {
  _Run({
    required this.gen,
    required this.key,
    required this.title,
    required this.sessionId,
  });

  final int gen;
  final String key;

  /// 세션 제목. 음성 질문의 새 세션은 보정된 질문이 올 때 정해진다.
  String title;

  /// 이 질문의 세션. 새 세션이면 `session` 이벤트로 정해진다.
  String? sessionId;
  bool received = false;
  bool finished = false;
  final Completer<void> done = Completer<void>();

  void complete() {
    if (!done.isCompleted) done.complete();
  }
}

/// 지금 보고 있는 세션(새 세션 또는 연 세션)의 질문과 답변.
/// generation이 바뀌면(다른 세션을 열거나 새로 시작) 진행 중이던 흐름의 결과는 화면에 쓰지 않는다.
class ChatController extends ChangeNotifier {
  ChatController({
    required this.client,
    required this.onSaved,
    bool Function()? isForeground,
  }) : _isForeground = isForeground ?? _appInForeground;

  final ApiClient client;

  /// 질문과 답변이 저장되었다. 세션 목록 맨 위에 올린다.
  final void Function(Session session) onSaved;
  final bool Function() _isForeground;

  /// 저장된 세션의 ID. 새 세션은 답변이 저장되기 전까지 null.
  String? sessionId;
  String? title;
  List<ChatItem> items = const <ChatItem>[];
  bool streaming = false;

  /// 음성 질문을 보정된 질문으로 바꾸는 중(입력칸과 녹음 버튼을 쓸 수 없다).
  bool processingVoice = false;

  /// 중지할 수 있다(서버에 진행 중인 답변이 있고 세션 ID를 안다).
  bool canStop = false;
  bool loading = false;
  String? loadError;

  int _generation = 0;
  int _nextKey = 0;

  /// 중지에 쓰는 세션 ID(`session` 이벤트 또는 지금 세션).
  String? _pendingId;

  /// 연결이 끊겨 모바일 앱이 앞으로 오면 다시 불러올 세션.
  String? _reloadId;
  _Run? _active;
  StreamSubscription<SseEvent>? _subscription;
  bool _disposed = false;

  static bool _appInForeground() {
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  Future<void> send(String text) {
    final _Run run = _begin(
      (String key) => ChatItem(
        key: key,
        question: text,
        answer: const ChatAnswer('', AnswerState.streaming),
      ),
      title ?? text,
    );
    return _ask(run, client.sendQuestion(text, sessionId: run.sessionId));
  }

  /// 음성 질문. 보정된 질문(`question` 이벤트)이 올 때까지 "처리 중"이고, 올린 녹음 파일은 지운다.
  Future<void> sendVoice(String path, {bool autoStopped = false}) {
    final _Run run = _begin(
      (String key) => ChatItem(
        key: key,
        question: '',
        pending: true,
        autoStopped: autoStopped,
      ),
      title ?? '',
    );
    _set(() => processingVoice = true);
    final Future<ApiResult<Stream<List<int>>>> request = client
        .sendVoiceQuestion(path, sessionId: run.sessionId)
        .whenComplete(() => _deleteQuietly(path));
    return _ask(run, request);
  }

  Future<void> _ask(
    _Run run,
    Future<ApiResult<Stream<List<int>>>> request,
  ) async {
    final ApiResult<Stream<List<int>>> result = await request;
    switch (result) {
      case ApiFailure<Stream<List<int>>>(:final ApiError? error):
        _update(
          run,
          (ChatItem i) => i.withAnswer(null).withError(chatErrorText(error)),
        );
      case ApiOk<Stream<List<int>>>(:final Stream<List<int>> value):
        // 스트림이 열렸으면 서버에 진행 중인 답변이 있다. 지난 세션은 이때부터 중지할 수 있다.
        if (run.sessionId != null && _current(run)) _set(() => canStop = true);
        await _read(run, value);
    }
    if (_current(run)) {
      _set(() {
        streaming = false;
        canStop = false;
        processingVoice = false;
      });
    }
  }

  /// 질문을 스레드에 붙이고 받는 중으로 바꾼다.
  _Run _begin(ChatItem Function(String key) item, String runTitle) {
    final _Run run = _Run(
      gen: _generation,
      key: 'new-${_nextKey++}',
      title: runTitle,
      sessionId: sessionId,
    );
    _pendingId = sessionId;
    _set(() {
      items = <ChatItem>[...items, item(run.key)];
      streaming = true;
      canStop = false;
    });
    return run;
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // 이미 없으면 그만이다.
    }
  }

  /// 결과는 SSE의 `stopped` 이벤트로 온다. 이미 끝났으면(NOT_STREAMING) 할 일이 없다.
  Future<void> stop() async {
    final String? id = _pendingId;
    if (id != null) await client.stopAnswer(id);
  }

  Future<void> open(Session session) async {
    final int gen = _restart(
      id: session.id,
      name: session.title,
      isLoading: true,
    );
    final ApiResult<List<ChatItem>> result = await _fetchAll(session.id);
    if (gen != _generation) return;
    _set(() {
      loading = false;
      switch (result) {
        case ApiOk<List<ChatItem>>(:final List<ChatItem> value):
          items = value;
        case ApiFailure<List<ChatItem>>(:final ApiError? error):
          loadError = errorText(error);
      }
    });
  }

  /// 빈 새 세션으로. 받던 답변은 끊는다(지운 세션일 때).
  void reset() {
    unawaited(_subscription?.cancel());
    _active?.complete();
    _restart(id: null, name: null, isLoading: false);
  }

  /// 모바일 앱이 앞으로 왔다. 연결이 끊긴 답변이 있으면 그 세션을 다시 불러온다.
  Future<void> resumed() async {
    final String? id = _reloadId;
    if (id == null) return;
    final int gen = _generation;
    final ApiResult<List<ChatItem>> result = await _fetchAll(id);
    if (gen != _generation) return;
    // 끊긴 질문까지 저장되었으면 서버의 질문 수가 화면의 저장된(또는 저장될) 질문 수 이상이다.
    if (result case ApiOk<List<ChatItem>>(:final List<ChatItem> value)
        when value.length >= _savedCount()) {
      _reloadId = null;
      _set(() {
        items = value;
        sessionId = id;
        title ??= value.first.question;
      });
      onSaved(
        Session(id: id, title: title!, updatedAt: DateTime.now().toUtc()),
      );
    }
  }

  int _savedCount() =>
      items.where((ChatItem i) => i.answer != null || i.notice != null).length;

  Future<void> _read(_Run run, Stream<List<int>> bytes) {
    _active = run;
    _subscription = parseSse(bytes).listen(
      (SseEvent e) => _onEvent(run, e),
      onError: (Object _) => _cut(run),
      onDone: () => run.finished ? run.complete() : _cut(run),
      cancelOnError: true,
    );
    return run.done.future;
  }

  void _onEvent(_Run run, SseEvent event) {
    switch (event) {
      case SessionEvent(:final String id):
        run.sessionId = id;
        if (_current(run)) {
          _pendingId = id;
          _set(() => canStop = true);
        }
      case DeltaEvent(:final String text):
        _onDelta(run, text);
      case DoneEvent():
        _finish(run, AnswerState.completed);
      case StoppedEvent():
        _finish(run, AnswerState.stopped);
      case ErrorEvent(:final String code, :final String message):
        _onError(run, ApiError(code: code, message: message));
      case QuestionEvent(:final String text):
        _onQuestion(run, text);
    }
  }

  /// 음성 질문의 보정된 텍스트. 이때부터 처리 중이 끝나고 답변을 받는다.
  void _onQuestion(_Run run, String text) {
    if (run.title.isEmpty) run.title = text;
    if (_current(run)) _set(() => processingVoice = false);
    _update(run, (ChatItem i) => i.withQuestion(text));
  }

  void _onDelta(_Run run, String text) {
    if (!run.received && _current(run)) _set(() => title = run.title);
    run.received = true;
    _update(
      run,
      (ChatItem i) => i.withAnswer(
        ChatAnswer((i.answer?.text ?? '') + text, AnswerState.streaming),
      ),
    );
  }

  void _finish(_Run run, AnswerState state) {
    run.finished = true;
    run.complete();
    _update(
      run,
      (ChatItem i) => i.withAnswer(ChatAnswer(i.answer?.text ?? '', state)),
    );
    _saved(run);
  }

  void _onError(_Run run, ApiError error) {
    run.finished = true;
    run.complete();
    _update(
      run,
      (ChatItem i) => i
          .withAnswer(keepReceived(i.answer, AnswerState.stopped))
          .withError(chatErrorText(error)),
    );
    if (run.received) _saved(run);
  }

  /// `done`/`stopped`/`error` 없이 끝났다(연결이 끊김). 서버는 답변을 끝까지 저장한다(ADR 0003).
  void _cut(_Run run) {
    run.complete();
    if (!_current(run)) return;
    _update(
      run,
      (ChatItem i) => i
          .withAnswer(keepReceived(i.answer, AnswerState.disconnected))
          .withNotice(Messages.disconnected),
    );
    _reloadId = run.sessionId;
    // 이어서 묻는 질문이 새 세션으로 가지 않도록 끊긴 답변의 세션을 지금 세션으로 둔다.
    sessionId ??= run.sessionId;
    if (_isForeground()) unawaited(resumed());
  }

  /// 질문과 답변이 저장되었다: 목록 맨 위에 올리고, 아직 보고 있는 세션이면 지금 세션으로 정한다.
  void _saved(_Run run) {
    final String? id = run.sessionId;
    if (id == null || _disposed) return;
    if (_current(run)) {
      _set(() {
        sessionId = id;
        title = run.title;
      });
    }
    onSaved(
      Session(id: id, title: run.title, updatedAt: DateTime.now().toUtc()),
    );
  }

  int _restart({
    required String? id,
    required String? name,
    required bool isLoading,
  }) {
    _pendingId = id;
    _reloadId = null;
    _set(() {
      sessionId = id;
      title = name;
      items = const <ChatItem>[];
      streaming = false;
      canStop = false;
      processingVoice = false;
      loading = isLoading;
      loadError = null;
    });
    return ++_generation;
  }

  /// 질문을 100개씩 끝까지 받아 오래된 순으로 바꾼다.
  Future<ApiResult<List<ChatItem>>> _fetchAll(String id) async {
    final List<ChatItem> all = <ChatItem>[];
    String? cursor;
    do {
      final ApiResult<QuestionPage> page = await client.listQuestions(
        id,
        cursor: cursor,
        limit: 100,
      );
      if (page case ApiFailure<QuestionPage>(:final ApiError? error)) {
        return ApiFailure<List<ChatItem>>(error);
      }
      final QuestionPage value = (page as ApiOk<QuestionPage>).value;
      all.addAll(value.items.map(_fromQuestion));
      cursor = value.nextCursor;
    } while (cursor != null);
    return ApiOk<List<ChatItem>>(all.reversed.toList());
  }

  static ChatItem _fromQuestion(Question q) {
    final AnswerState state = q.answer.status == AnswerStatus.stopped
        ? AnswerState.stopped
        : AnswerState.completed;
    return ChatItem(
      key: q.id,
      question: q.text,
      answer: ChatAnswer(q.answer.text, state),
    );
  }

  bool _current(_Run run) => run.gen == _generation;

  void _update(_Run run, ChatItem Function(ChatItem item) change) {
    if (!_current(run)) return;
    _set(
      () => items = <ChatItem>[
        for (final ChatItem i in items) i.key == run.key ? change(i) : i,
      ],
    );
  }

  void _set(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  /// 화면이 사라지면(로그인이 풀리는 등) 받던 답변을 끊고 늦게 온 결과는 버린다.
  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    _active?.complete();
    super.dispose();
  }
}
