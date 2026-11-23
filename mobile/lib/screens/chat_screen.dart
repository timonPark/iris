import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../api/api_models.dart';
import '../auth/auth_controller.dart';
import '../chat/chat_controller.dart';
import '../chat/sessions_controller.dart';
import '../voice/voice_controller.dart';
import '../voice/voice_recorder.dart';
import '../widgets/composer.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/session_drawer.dart';
import '../widgets/thread_view.dart';
import 'settings_screen.dart';

/// 로그인 뒤의 화면 틀: 세션 목록 서랍 + 본문(채팅 또는 설정).
/// 모바일 앱을 새로 열면 빈 새 세션에서 시작한다.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.controller,
    required this.recorder,
  });

  final AuthController controller;
  final VoiceRecorder recorder;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final SessionsController _sessions = SessionsController(
    widget.controller.client,
  );
  late final ChatController _chat = ChatController(
    client: widget.controller.client,
    onSaved: _sessions.putOnTop,
  );
  late final VoiceController _voice = VoiceController(
    recorder: widget.recorder,
    onRecorded: _chat.sendVoice,
  );
  late final AppLifecycleListener _lifecycle;
  final GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();
  bool _settings = false;

  @override
  void initState() {
    super.initState();
    unawaited(_sessions.loadMore());
    // 답변 중 연결이 끊겼으면 앞으로 왔을 때 그 세션을 다시 불러온다.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_chat.resumed()),
      // 녹음 중에 백그라운드로 가면 보내지 않고 버린다(GLOSSARY "음성 입력").
      onHide: () => unawaited(_voice.cancelForBackground()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _voice.dispose();
    _chat.dispose();
    _sessions.dispose();
    super.dispose();
  }

  void _closeDrawer() => _scaffold.currentState?.closeDrawer();

  void _open(Session session) {
    _closeDrawer();
    // 녹음은 그 녹음을 시작한 세션의 것이라 다른 곳으로 가면 버린다.
    unawaited(_voice.cancel());
    final bool same = session.id == _chat.sessionId;
    setState(() => _settings = false);
    // 지금 세션(답변을 받는 중일 수 있음)은 다시 불러오지 않는다.
    if (!same) unawaited(_chat.open(session));
  }

  void _backToChat() => setState(() => _settings = false);

  void _showSettings() {
    _closeDrawer();
    unawaited(_voice.cancel());
    setState(() => _settings = true);
  }

  void _askDelete(Session session) {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => DeleteDialog(
        session: session,
        client: widget.controller.client,
        onDeleted: (String id) {
          _sessions.remove(id);
          if (id == _chat.sessionId) _chat.reset();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_chat, _sessions, _voice]),
      builder: (BuildContext context, Widget? _) => PopScope(
        // 기기의 뒤로 가기도 설정에서는 채팅으로 돌아온다.
        canPop: !_settings,
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (!didPop) _backToChat();
        },
        child: _scaffoldView(),
      ),
    );
  }

  Widget _scaffoldView() {
    return Scaffold(
      key: _scaffold,
      appBar: _appBar(),
      drawer: SessionDrawer(
        sessions: _sessions,
        currentId: _settings ? null : _chat.sessionId,
        loginId: widget.controller.loginId,
        onOpen: _open,
        onDelete: _askDelete,
        onSettings: _showSettings,
      ),
      body: SafeArea(top: false, child: _body()),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      // 설정에서는 저장된 세션이 없어도 채팅으로 돌아올 수 있게 뒤로 가기(샘플은 메뉴 버튼).
      leading: _settings
          ? IconButton(
              tooltip: '채팅으로 돌아가기',
              onPressed: _backToChat,
              icon: const Icon(Icons.arrow_back),
            )
          : IconButton(
              tooltip: '세션 목록 열기',
              onPressed: () => _scaffold.currentState?.openDrawer(),
              icon: const Icon(Icons.menu),
            ),
      title: Text(
        _settings ? '설정' : (_chat.title ?? '새 세션'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _body() {
    if (_settings) return SettingsBody(controller: widget.controller);
    return Column(
      children: <Widget>[
        Expanded(child: ThreadView(chat: _chat)),
        Composer(chat: _chat, voice: _voice),
      ],
    );
  }
}
