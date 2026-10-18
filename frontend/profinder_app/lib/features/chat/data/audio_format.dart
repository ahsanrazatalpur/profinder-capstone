// lib/features/chat/data/audio_format.dart
//
// Voice notes are recorded in different containers depending on the
// platform: AAC/.m4a on Android/iOS/macOS/Windows, Opus/.webm in most
// desktop browsers, and so on. The recorder only gives us a path (or a
// `blob:` URL on web), so instead of guessing from the file name we look
// at the first bytes of the file. That way the upload always carries the
// right extension + MIME type, and the server/other devices can play it.

import 'dart:typed_data';

class AudioFormat {
  final String extension;
  final String mimeType;
  const AudioFormat(this.extension, this.mimeType);

  String get type => mimeType.split('/').first;
  String get subtype => mimeType.split('/').last;
}

AudioFormat sniffAudioFormat(Uint8List b) {
  bool at(int offset, String s) {
    if (b.length < offset + s.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (b[offset + i] != s.codeUnitAt(i)) return false;
    }
    return true;
  }

  if (at(0, 'RIFF') && at(8, 'WAVE'))
    return const AudioFormat('wav', 'audio/wav');
  if (at(0, 'OggS')) return const AudioFormat('ogg', 'audio/ogg');
  if (at(0, 'fLaC')) return const AudioFormat('flac', 'audio/flac');
  // Matroska / WebM (EBML header)
  if (b.length >= 4 &&
      b[0] == 0x1A &&
      b[1] == 0x45 &&
      b[2] == 0xDF &&
      b[3] == 0xA3) {
    return const AudioFormat('webm', 'audio/webm');
  }
  // MP4 / M4A ("....ftyp")
  if (at(4, 'ftyp')) return const AudioFormat('m4a', 'audio/mp4');
  // Raw AAC (ADTS) — sync word 0xFFF, layer bits == 00
  if (b.length >= 2 && b[0] == 0xFF && (b[1] & 0xF6) == 0xF0) {
    return const AudioFormat('aac', 'audio/aac');
  }
  // MP3 — ID3 tag, or MPEG frame sync with a non-zero layer
  if (at(0, 'ID3') ||
      (b.length >= 2 &&
          b[0] == 0xFF &&
          (b[1] & 0xE0) == 0xE0 &&
          (b[1] & 0x06) != 0)) {
    return const AudioFormat('mp3', 'audio/mpeg');
  }
  // Unknown: keep the old behaviour (AAC in an m4a container).
  return const AudioFormat('m4a', 'audio/mp4');
}
