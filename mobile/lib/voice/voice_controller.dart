import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'voice_recorder.dart';

/// 입력칸 위에 띄우는 음성 입력 안내.
enum VoiceNotice { permissionNeeded, cancelledInBackground, recorderFailed }

/// 녹음이 끝났다. [autoStopped]면 2분이 되어 자동으로 끝난 것.
typedef OnRecorded = Future<void> Function(
  String path, {
  required bool autoStopped,
});

/// 음성 입력의 녹음 상태(`ssot/GLOSSARY.md` "음성 입력"): 탭하면 시작, 다시 탭하면 끝내고 보낸다.
/// 최대 2분이고, 2분이 되면 자동으로 끝내고 보낸다. 취소하면 버린다.
class VoiceController extends ChangeNotifier {
  VoiceController({required this.recorder, required this.onRecorded});

  /// 녹음은 2분까지(`docs/api/openapi.yaml` 음성 질문 전송).
  static const Duration maxLength = Duration(minutes: 2);

  /// 백엔드는 2분을 0.1초만 넘어도 거절하므로(`AUDIO_TOO_LONG`), 시작·멈춤 지연을 감안해 1초 남기고 끝낸다.
  static const Duration _stopMargin = Duration(seconds: 1);
  static const Duration _tickEvery = Duration(milliseconds: 200);

  final VoiceRecorder recorder;
  final OnRecorded onRecorded;

  bool recording = false;
  Duration elapsed = Duration.zero;
  VoiceNotice? notice;
  Timer? _timer;
  DateTime _startedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _starting = false;

  /// 취소하거나 없앨 때마다 늘린다. 기다리던 시작이 끝났을 때 바뀌었으면 그 결과를 버린다.
  int _epoch = 0;

  Future<void> start() async {
    if (recording || _starting) return;
    _starting = true;
    notice = null;
    final int epoch = _epoch;
    try {
      final MicPermission permission = await recorder.requestPermission();
      if (epoch != _epoch) return;
      if (permission == MicPermission.denied) {
        return _show(VoiceNotice.permissionNeeded);
      }
      // 녹음기 시작 전에 재기 시작해야 실제 녹음이 잰 시간보다 길어지지 않는다.
      _startedAt = clock.now();
      await recorder.start();
      // 시작을 기다리는 동안 취소되었으면(백그라운드, 화면 닫힘) 바로 버린다.
      if (epoch != _epoch) {
        await _discard();
        return;
      }
      _begin();
    } on Exception {
      _fail();
    } finally {
      _starting = false;
    }
  }

  /// 끝내고 보낸다.
  Future<void> finish({bool autoStopped = false}) async {
    if (!recording) return;
    _stop();
    final String? path;
    try {
      path = await recorder.stop();
    } on Exception {
      return _fail();
    }
    notifyListeners();
    if (path != null) await onRecorded(path, autoStopped: autoStopped);
  }

  /// 보내지 않고 버린다. 시작을 기다리는 중이면 그 시작을 버린다.
  Future<void> cancel() async {
    if (_starting) _epoch++;
    if (!recording) return;
    _stop();
    await _discard();
    notifyListeners();
  }

  /// 모바일 앱이 백그라운드로 갔다. 녹음 중이면 버리고 돌아왔을 때 안내한다.
  Future<void> cancelForBackground() async {
    if (_starting) return cancel();
    if (!recording) return;
    notice = VoiceNotice.cancelledInBackground;
    await cancel();
  }

  Future<void> openSettings() => recorder.openSettings();

  void clearNotice() {
    if (notice == null) return;
    notice = null;
    notifyListeners();
  }

  void _begin() {
    recording = true;
    elapsed = Duration.zero;
    _timer = Timer.periodic(_tickEvery, (Timer _) => _tick());
    notifyListeners();
  }

  void _show(VoiceNotice next) {
    notice = next;
    notifyListeners();
  }

  /// 기기 녹음기가 실패했다. 남은 녹음을 버리고 다시 녹음할 수 있게 안내한다.
  void _fail() {
    _stop();
    unawaited(_discard());
    _show(VoiceNotice.recorderFailed);
  }

  Future<void> _discard() async {
    try {
      await recorder.cancel();
    } on Exception {
      // 이미 멈췄거나 파일이 없다.
    }
  }

  Future<void> _release(bool discard) async {
    if (discard) await _discard();
    await recorder.dispose();
  }

  void _tick() {
    final Duration now = clock.now().difference(_startedAt);
    if (now >= maxLength - _stopMargin) {
      unawaited(finish(autoStopped: true));
      return;
    }
    if (now.inSeconds == elapsed.inSeconds) return;
    elapsed = Duration(seconds: now.inSeconds);
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    recording = false;
  }

  @override
  void dispose() {
    _epoch++;
    _timer?.cancel();
    final bool wasRecording = recording;
    recording = false;
    unawaited(_release(wasRecording));
    super.dispose();
  }
}
