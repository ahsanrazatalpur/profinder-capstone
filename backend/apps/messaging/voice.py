# PATH: backend/apps/messaging/voice.py
#
# Validation helpers for voice notes uploaded to the chat.
#
# Why this exists: clients on different platforms record in different
# containers (AAC/.m4a on phones, Opus/.webm in desktop browsers, WAV on
# some desktop backends). Previously the upload was stored as-is with
# whatever name the client sent, with no checks — an empty/garbage upload
# or an unexpected format failed *after* the Message row had already been
# created, leaving an empty "ghost" message in the thread. We now check the
# file up-front, label it with its real extension (so browsers/phones play
# it correctly) and reject bad uploads with a clear 4xx instead of a 500.

import uuid

MAX_VOICE_BYTES = 10 * 1024 * 1024      # 10 MB — ~5 min of AAC is ~2-3 MB
MAX_VOICE_SECONDS = 15 * 60             # sanity clamp for the stored duration


def sniff_audio_extension(head: bytes):
    """Return a file extension for a recognised audio container, else None."""
    if head[:4] == b'RIFF' and head[8:12] == b'WAVE':
        return 'wav'
    if head[:4] == b'OggS':
        return 'ogg'
    if head[:4] == b'fLaC':
        return 'flac'
    if head[:4] == b'\x1a\x45\xdf\xa3':       # Matroska / WebM (EBML)
        return 'webm'
    if head[4:8] == b'ftyp':                   # MP4 / M4A
        return 'm4a'
    if len(head) >= 2 and head[0] == 0xFF and (head[1] & 0xF6) == 0xF0:
        return 'aac'                           # raw AAC (ADTS)
    if head[:3] == b'ID3' or (
        len(head) >= 2 and head[0] == 0xFF and (head[1] & 0xE0) == 0xE0 and (head[1] & 0x06) != 0
    ):
        return 'mp3'
    return None


def validate_voice_note(upload):
    """
    Check an uploaded voice note. Returns (error, status_code).
    On success returns (None, None) and renames `upload` so it carries a
    safe, unique name with the correct extension.
    """
    size = getattr(upload, 'size', None)
    if not size:
        return 'The voice note is empty. Please record it again.', 400
    if size > MAX_VOICE_BYTES:
        return 'The voice note is too large (max 10 MB).', 413

    try:
        head = upload.read(16)
        upload.seek(0)
    except Exception:
        return 'Could not read the uploaded voice note.', 400

    ext = sniff_audio_extension(head)
    if ext is None:
        return 'Unsupported audio format. Please record the voice note again.', 400

    upload.name = f'voice_{uuid.uuid4().hex[:12]}.{ext}'
    return None, None


def clean_duration(raw):
    """Parse duration_seconds from the request; None if missing/invalid."""
    try:
        value = int(float(raw))
    except (TypeError, ValueError):
        return None
    return max(0, min(value, MAX_VOICE_SECONDS))
