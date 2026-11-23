import 'package:material_ui/material_ui.dart';

import '../api/api_models.dart';
import '../chat/sessions_controller.dart';
import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';

/// 세션 목록 서랍: 위에 "Iris"와 닫기, 가운데 세션 목록(끝이 보이면 이어 불러오기), 아래에 아이디와 설정.
class SessionDrawer extends StatelessWidget {
  const SessionDrawer({
    super.key,
    required this.sessions,
    required this.currentId,
    required this.loginId,
    required this.onOpen,
    required this.onDelete,
    required this.onSettings,
  });

  final SessionsController sessions;

  /// 지금 보고 있는 세션. 설정을 보고 있거나 새 세션이면 null.
  final String? currentId;
  final String loginId;
  final ValueChanged<Session> onOpen;
  final ValueChanged<Session> onDelete;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    return Drawer(
      // 샘플처럼 오른쪽에 큰 컨트롤 하나만큼 본문이 보인다.
      width: MediaQuery.sizeOf(context).width - PrimerSize.controlLargeSize,
      backgroundColor: c.bgColorMuted,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _Head(),
            const _Heading(),
            Expanded(child: _list()),
            _Foot(loginId: loginId, onSettings: onSettings),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final List<Session> items = sessions.items;
    final bool footer = sessions.error != null || sessions.hasMore;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: PrimerSize.stackPaddingCondensed,
      ),
      itemCount: items.length + (footer ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == items.length) return _footer();
        final Session s = items[index];
        return _SessionRow(
          session: s,
          current: s.id == currentId,
          onOpen: onOpen,
          onDelete: onDelete,
        );
      },
    );
  }

  Widget _footer() {
    final String? error = sessions.error;
    if (error != null) {
      return _LoadError(text: error, onRetry: sessions.loadMore);
    }
    // 목록 끝이 화면에 들어오면(만들어지면) 다음 페이지를 부른다.
    return _More(
      key: ValueKey<int>(sessions.loads),
      onVisible: sessions.loadMore,
    );
  }
}

class _Head extends StatelessWidget {
  const _Head();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: PrimerSize.stackPaddingCondensed,
        horizontal: PrimerSize.stackPaddingNormal,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text('Iris', style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            tooltip: '세션 목록 닫기',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PrimerSize.stackPaddingNormal,
        PrimerSize.baseSize8,
        PrimerSize.stackPaddingNormal,
        PrimerSize.baseSize4,
      ),
      child: Text(
        '세션',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: PrimerText.baseTextWeightSemibold),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.current,
    required this.onOpen,
    required this.onDelete,
  });

  final Session session;
  final bool current;
  final ValueChanged<Session> onOpen;
  final ValueChanged<Session> onDelete;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium;
    return Material(
      color: current
          ? primerColorsOf(context).bgColorAccentMuted
          : primerColorsOf(context).bgColorTransparent,
      borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(PrimerRadius.borderRadiusMedium),
        onTap: () => onOpen(session),
        child: Row(
          children: <Widget>[
            Expanded(child: _title(style)),
            IconButton(
              tooltip: "'${session.title}' 세션 삭제",
              onPressed: () => onDelete(session),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PrimerSize.controlMediumPaddingInlineCondensed,
      ),
      child: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: current
            ? style?.copyWith(fontWeight: PrimerText.baseTextWeightSemibold)
            : style,
      ),
    );
  }
}

/// "이전 세션을 불러오는 중…". 만들어지면 [onVisible]을 한 번 부른다.
class _More extends StatefulWidget {
  const _More({super.key, required this.onVisible});

  final Future<void> Function() onVisible;

  @override
  State<_More> createState() => _MoreState();
}

class _MoreState extends State<_More> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => widget.onVisible(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PrimerSize.baseSize12),
      child: Text(
        '이전 세션을 불러오는 중…',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.text, required this.onRetry});

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PrimerSize.baseSize12),
      child: Column(
        spacing: PrimerSize.baseSize8,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.loginId, required this.onSettings});

  final String loginId;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: PrimerSize.stackPaddingCondensed,
        horizontal: PrimerSize.stackPaddingNormal,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: primerColorsOf(context).borderColorDefault),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(loginId, overflow: TextOverflow.ellipsis)),
          TextButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('설정'),
          ),
        ],
      ),
    );
  }
}
