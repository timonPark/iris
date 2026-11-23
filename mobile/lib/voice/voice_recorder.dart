import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum MicPermission { granted, denied }

/// 녹음기. 화면과 상태는 이 인터페이스만 쓰고, 테스트는 가짜로 바꾼다.
abstract interface class VoiceRecorder {
  /// 처음이면 기기가 권한을 묻는다. 이미 거절했으면 묻지 않고 denied.
  Future<MicPermission> requestPermission();

  Future<void> start();

  /// 끝내고 녹음 파일 경로를 돌려준다. 보낸 뒤에는 받는 쪽이 지운다.
  Future<String?> stop();

  /// 끝내고 녹음 파일을 지운다.
  Future<void> cancel();

  /// 기기 설정의 이 모바일 앱 화면을 연다(마이크 권한을 켜도록).
  Future<void> openSettings();

  /// 녹음기를 놓는다. 다시 쓰면 새로 잡는다.
  Future<void> dispose();
}

/// `record` 패키지로 기기 마이크를 녹음한다(AAC, m4a). 백엔드가 ffmpeg로 변환하므로 형식은 상관없다.
class DeviceVoiceRecorder implements VoiceRecorder {
  static const String _prefix = 'iris-voice-';

  AudioRecorder? _recorder;

  /// 지금 녹음 중인 파일. 취소하거나 실패하면 이 앱이 직접 지운다.
  String? _path;

  AudioRecorder get _audio => _recorder ??= AudioRecorder();

  @override
  Future<MicPermission> requestPermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    return status.isGranted ? MicPermission.granted : MicPermission.denied;
  }

  @override
  Future<void> start() async {
    final Directory dir = await getTemporaryDirectory();
    await _sweep(dir);
    final String path =
        '${dir.path}/$_prefix${DateTime.now().millisecondsSinceEpoch}.m4a';
    _path = path;
    await _audio.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
      path: path,
    );
  }

  @override
  Future<String?> stop() async {
    final String? path = await _audio.stop();
    _path = null;
    return path;
  }

  @override
  Future<void> cancel() async {
    try {
      await _audio.cancel();
    } finally {
      final String? path = _path;
      _path = null;
      if (path != null) await _delete(File(path));
    }
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  @override
  Future<void> dispose() async {
    final AudioRecorder? recorder = _recorder;
    _recorder = null;
    await recorder?.dispose();
  }

  /// 비정상 종료 등으로 남은 예전 녹음 파일을 지운다(음성 파일은 남기지 않는다).
  static Future<void> _sweep(Directory dir) async {
    await for (final FileSystemEntity entry in dir.list()) {
      final String name = entry.uri.pathSegments.last;
      if (entry is File && name.startsWith(_prefix)) await _delete(entry);
    }
  }

  static Future<void> _delete(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // 이미 없다.
    }
  }
}
