// lib/features/chat/presentation/widgets/voice_recorder_button.dart
//
// ✅ NEW — Voice message recording. Uses the `record` package (add to
// pubspec.yaml: record: ^5.x). Tap once to start, tap again to stop &
// send, or tap the X that appears alongside to discard.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_ext.dart';

class VoiceRecorderButton extends StatefulWidget {
  final void Function(File audioFile, int durationSeconds) onRecorded;
  const VoiceRecorderButton({super.key, required this.onRecorded});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _ticker;
  String? _path;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice messages.')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _path!);

    setState(() {
      _isRecording = true;
      _seconds = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _stopAndSend() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    final duration = _seconds;
    setState(() => _isRecording = false);

    if (path == null || duration < 1) return; // too short to be worth sending
    widget.onRecorded(File(path), duration);
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    await _recorder.stop();
    setState(() => _isRecording = false);
    if (_path != null) {
      final f = File(_path!);
      if (await f.exists()) await f.delete();
    }
  }

  String _fmt(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(1, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return GestureDetector(
        onTap: _start,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.mic_none_rounded, size: 18, color: Colors.white),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _cancel,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
        ),
        const SizedBox(width: 6),
        Text(_fmt(_seconds), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _stopAndSend,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}