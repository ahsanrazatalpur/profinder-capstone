// Cross-platform voice message recorder component supporting mobile, desktop, and web.
//
// Technical considerations:
//  - Web support: Browser environments use blob URLs where local temporary paths are unavailable.
//  - Codec negotiation: Audio encoder is dynamically negotiated based on platform runtime capabilities.
//  - Lifecycle and memory safety: Disposing or navigating away automatically cancels the recorder session,
//    releasing microphone hardware handles without dangling streams.

import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_text_styles.dart';

class VoiceRecorderButton extends StatefulWidget {
  final void Function(File audioFile, int durationSeconds) onRecorded;
  const VoiceRecorderButton({super.key, required this.onRecorded});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  /// Hard cap so a forgotten recording can't grow without bound
  /// (the server also rejects very large uploads).
  static const int _maxSeconds = 300;

  final _recorder = AudioRecorder();
  final _stopwatch = Stopwatch();
  bool _isRecording = false;
  bool _busy = false; // true while starting/stopping — ignores extra taps
  int _seconds = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    // Fire-and-forget: discard any in-flight recording, then free the mic.
    unawaited(
      _recorder.cancel().catchError((_) {}).whenComplete(_recorder.dispose),
    );
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Picks the best encoder the current platform can actually record with.
  Future<({AudioEncoder encoder, String ext})> _pickEncoder() async {
    // Browsers usually record Opus/WebM (Safari: AAC/MP4); mobile and most
    // desktop platforms prefer AAC in an .m4a container.
    final candidates = kIsWeb
        ? const [
            (encoder: AudioEncoder.opus, ext: 'webm'),
            (encoder: AudioEncoder.aacLc, ext: 'm4a'),
            (encoder: AudioEncoder.wav, ext: 'wav'),
          ]
        : const [
            (encoder: AudioEncoder.aacLc, ext: 'm4a'),
            (encoder: AudioEncoder.opus, ext: 'opus'),
            (encoder: AudioEncoder.wav, ext: 'wav'),
          ];
    for (final c in candidates) {
      try {
        if (await _recorder.isEncoderSupported(c.encoder)) return c;
      } catch (_) {
        // try the next one
      }
    }
    return candidates.last; // wav is supported practically everywhere
  }

  Future<void> _start() async {
    if (_busy || _isRecording) return;
    _busy = true;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        _toast(AppLocalizations.of(context).chatMicPermissionRequired);
        return;
      }

      final picked = await _pickEncoder();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.${picked.ext}';

      // On web there is no file system: the path is ignored by the plugin
      // and stop() returns a blob: URL.
      final String path;
      if (kIsWeb) {
        path = fileName;
      } else {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/$fileName';
      }

      await _recorder.start(RecordConfig(encoder: picked.encoder), path: path);

      _stopwatch
        ..reset()
        ..start();
      if (!mounted) {
        await _recorder.cancel();
        return;
      }
      setState(() {
        _isRecording = true;
        _seconds = 0;
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        final s = _stopwatch.elapsed.inSeconds;
        if (s != _seconds) setState(() => _seconds = s);
        if (s >= _maxSeconds) _stopAndSend();
      });
    } catch (e) {
      debugPrint('Voice recording failed to start: $e');
      if (mounted) _toast(AppLocalizations.of(context).voiceRecordStartFailed);
    } finally {
      _busy = false;
    }
  }

  Future<void> _stopAndSend() async {
    if (_busy || !_isRecording) return;
    _busy = true;
    _ticker?.cancel();
    _stopwatch.stop();
    final duration = _stopwatch.elapsed.inSeconds;
    try {
      // Too short to be worth sending (an accidental tap) — discard it.
      if (duration < 1) {
        await _recorder.cancel();
        if (mounted) setState(() => _isRecording = false);
        return;
      }

      final path = await _recorder.stop();
      if (mounted) setState(() => _isRecording = false);
      if (path == null || path.isEmpty) return;
      widget.onRecorded(File(path), duration);
    } catch (e) {
      debugPrint('Voice recording failed to stop: $e');
      if (mounted) setState(() => _isRecording = false);
      if (mounted) _toast(AppLocalizations.of(context).voiceRecordSaveFailed);
    } finally {
      _busy = false;
    }
  }

  Future<void> _cancel() async {
    if (_busy || !_isRecording) return;
    _busy = true;
    _ticker?.cancel();
    _stopwatch.stop();
    try {
      await _recorder.cancel(); // stops AND deletes the temp file (all platforms)
    } catch (_) {}
    if (mounted) setState(() => _isRecording = false);
    _busy = false;
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
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? context.colors.divider : AppColors.slate100, shape: BoxShape.circle),
            child: Icon(Icons.close_rounded, size: 16, color: context.colors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
        ),
        const SizedBox(width: 6),
        Text(_fmt(_seconds), style: TextStyle(fontSize: AppFontSizes.secondary, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
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