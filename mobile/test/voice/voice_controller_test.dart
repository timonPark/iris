import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris/voice/voice_controller.dart';
import 'package:iris/voice/voice_recorder.dart';

import '../support/fake_recorder.dart';

typedef Sent = ({String path, bool autoStopped});

class Harness {
  Harness({MicPermission permission = MicPermission.granted})
    : recorder = FakeRecorder(permission: permission) {
    voice = VoiceController(
      recorder: recorder,
      onRecorded: (String path, {required bool autoStopped}) async =>
          sent.add((path: path, autoStopped: autoStopped)),
    );
  }

  final FakeRecorder recorder;
  late final VoiceController voice;
  final List<Sent> sent = <Sent>[];
}

void main() {
  // 타이머를 쓰므로 testWidgets의 가짜 시간으로 돌린다.
  testWidgets('녹음을 시작하면 지난 시간이 1초씩 늘고, 끝내면 보낸다', (WidgetTester tester) async {
    final Harness h = Harness();

    await h.voice.start();
    expect(h.voice.recording, isTrue);
    expect(h.voice.elapsed, Duration.zero);
    await tester.pump(const Duration(seconds: 42));
    expect(h.voice.elapsed, const Duration(seconds: 42));

    await h.voice.finish();

    expect(h.voice.recording, isFalse);
    expect(h.sent.single.autoStopped, isFalse);
    expect(h.sent.single.path, h.recorder.lastPath);
    expect(h.recorder.calls, <String>['permission', 'start', 'stop']);
  });

  testWidgets('2분 한도를 넘지 않게 1초 남기고 자동으로 끝내고 보낸다', (WidgetTester tester) async {
    final Harness h = Harness();
    await h.voice.start();

    await tester.pump(const Duration(seconds: 118));
    expect(h.sent, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(h.voice.recording, isFalse);
    expect(h.sent.single.autoStopped, isTrue);
  });

  testWidgets('취소하면 보내지 않고 버린다', (WidgetTester tester) async {
    final Harness h = Harness();
    await h.voice.start();
    await tester.pump(const Duration(seconds: 5));

    await h.voice.cancel();
    await tester.pump(const Duration(minutes: 3));

    expect(h.voice.recording, isFalse);
    expect(h.sent, isEmpty);
    expect(h.recorder.calls.last, 'cancel');
  });

  testWidgets('마이크 권한이 없으면 녹음하지 않고 안내', (WidgetTester tester) async {
    final Harness h = Harness(permission: MicPermission.denied);

    await h.voice.start();

    expect(h.voice.recording, isFalse);
    expect(h.voice.notice, VoiceNotice.permissionNeeded);
    expect(h.recorder.calls, <String>['permission']);

    await h.voice.openSettings();
    expect(h.recorder.calls.last, 'settings');
  });

  testWidgets('녹음 중 백그라운드로 가면 버리고 안내, 녹음 중이 아니면 그대로', (
    WidgetTester tester,
  ) async {
    final Harness h = Harness();
    await h.voice.cancelForBackground();
    expect(h.voice.notice, isNull);

    await h.voice.start();
    await h.voice.cancelForBackground();

    expect(h.voice.recording, isFalse);
    expect(h.voice.notice, VoiceNotice.cancelledInBackground);
    expect(h.sent, isEmpty);

    h.voice.clearNotice();
    expect(h.voice.notice, isNull);
  });

  testWidgets('권한을 기다리는 중에 다시 눌러도 녹음은 하나', (WidgetTester tester) async {
    final Harness h = Harness();
    h.recorder.permissionGate = Completer<MicPermission>();

    final Future<void> first = h.voice.start();
    final Future<void> second = h.voice.start();
    h.recorder.permissionGate!.complete(MicPermission.granted);
    await first;
    await second;

    expect(h.recorder.calls.where((String c) => c == 'start'), hasLength(1));
    expect(h.voice.recording, isTrue);
    await h.voice.cancel();
  });

  testWidgets('시작을 기다리는 중에 백그라운드로 가면 녹음을 시작하지 않는다', (
    WidgetTester tester,
  ) async {
    final Harness h = Harness();
    h.recorder.permissionGate = Completer<MicPermission>();

    final Future<void> starting = h.voice.start();
    await h.voice.cancelForBackground();
    h.recorder.permissionGate!.complete(MicPermission.granted);
    await starting;
    await tester.pump(const Duration(minutes: 3));

    expect(h.voice.recording, isFalse);
    expect(h.recorder.calls.contains('start'), isFalse);
    expect(h.sent, isEmpty);
  });

  testWidgets('녹음기가 시작이나 끝에서 실패하면 정리하고 안내한다', (WidgetTester tester) async {
    final Harness h = Harness();
    h.recorder.failStart = true;

    await h.voice.start();
    expect(h.voice.recording, isFalse);
    expect(h.voice.notice, VoiceNotice.recorderFailed);

    h.recorder.failStart = false;
    h.recorder.failStop = true;
    await h.voice.start();
    expect(h.voice.recording, isTrue);
    await h.voice.finish();

    expect(h.voice.recording, isFalse);
    expect(h.voice.notice, VoiceNotice.recorderFailed);
    expect(h.sent, isEmpty);
  });

  testWidgets('없애면 녹음을 버리고 녹음기를 놓는다', (WidgetTester tester) async {
    final Harness h = Harness();
    await h.voice.start();

    h.voice.dispose();
    await tester.pump(const Duration(minutes: 3));

    expect(h.recorder.calls, containsAllInOrder(<String>['cancel', 'dispose']));
    expect(h.sent, isEmpty);
  });
}
