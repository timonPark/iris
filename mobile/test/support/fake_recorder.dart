import 'dart:async';
import 'dart:io';

import 'package:iris/voice/voice_recorder.dart';

/// 기기 없이 쓰는 녹음기. 끝내면 작은 임시 파일을 돌려준다.
class FakeRecorder implements VoiceRecorder {
  FakeRecorder({this.permission = MicPermission.granted});

  MicPermission permission;
  final List<String> calls = <String>[];

  /// 있으면 권한 응답을 이것이 끝날 때까지 미룬다.
  Completer<MicPermission>? permissionGate;

  /// 녹음 시작·끝에서 기기 오류를 낸다.
  bool failStart = false;
  bool failStop = false;
  String? lastPath;

  @override
  Future<MicPermission> requestPermission() async {
    calls.add('permission');
    final Completer<MicPermission>? gate = permissionGate;
    return gate == null ? permission : gate.future;
  }

  @override
  Future<void> start() async {
    calls.add('start');
    if (failStart) throw Exception('recorder start failed');
  }

  @override
  Future<String?> stop() async {
    calls.add('stop');
    if (failStop) throw Exception('recorder stop failed');
    // 위젯 테스트의 가짜 시간에서도 끝나도록 동기로 만든다.
    final Directory dir = Directory.systemTemp.createTempSync('iris-test-');
    final File file = File('${dir.path}/voice.m4a')
      ..writeAsBytesSync(<int>[1, 2, 3]);
    lastPath = file.path;
    return file.path;
  }

  @override
  Future<void> cancel() async => calls.add('cancel');

  @override
  Future<void> openSettings() async => calls.add('settings');

  @override
  Future<void> dispose() async => calls.add('dispose');
}
