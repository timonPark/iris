import 'package:material_ui/material_ui.dart';

import '../api/api_client.dart';
import '../api/api_models.dart';
import '../auth/messages.dart';
import '../theme/app_theme.dart';
import '../theme/primer_tokens.dart';
import 'form_parts.dart';

/// 세션 삭제 확인. 지우면 [onDeleted]를 부르고 닫는다. 이미 없는 세션(SESSION_NOT_FOUND)도 지운 것으로 본다.
class DeleteDialog extends StatefulWidget {
  const DeleteDialog({
    super.key,
    required this.session,
    required this.client,
    required this.onDeleted,
  });

  final Session session;
  final ApiClient client;
  final ValueChanged<String> onDeleted;

  @override
  State<DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<DeleteDialog> {
  String? _error;
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final ApiResult<void> result = await widget.client.deleteSession(
      widget.session.id,
    );
    final ApiError? error = switch (result) {
      ApiOk<void>() => null,
      ApiFailure<void>(:final ApiError? error) => error,
    };
    // 기다리는 동안 대화상자를 닫았어도 지워졌으면 목록에 반영한다.
    if (result is ApiOk<void> || error?.code == 'SESSION_NOT_FOUND') {
      widget.onDeleted(widget.session.id);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = errorText(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final PrimerColors c = primerColorsOf(context);
    return AlertDialog(
      backgroundColor: c.overlayBgColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: c.overlayBorderColor),
        borderRadius: BorderRadius.circular(PrimerSize.overlayBorderRadius),
      ),
      title: Text('세션을 삭제할까요?', style: Theme.of(context).textTheme.titleSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PrimerSize.stackGapNormal,
        children: <Widget>[
          if (_error != null) Flash(text: _error!, kind: FlashKind.danger),
          Text("'${widget.session.title}' 세션이 목록에서 사라지고 다시 볼 수 없습니다."),
        ],
      ),
      actions: _actions(context, c),
    );
  }

  List<Widget> _actions(BuildContext context, PrimerColors c) {
    return <Widget>[
      OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: defaultButtonStyle(context, c),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: _busy ? null : _confirm,
        style: dangerButtonStyle(context, c),
        child: const Text('삭제'),
      ),
    ];
  }
}
