// lib/features/chat/domain/entities/message_status.dart
//
// Mirrors backend `Message.STATUS_CHOICES` (apps/messaging/models.py) plus
// one purely client-side state: `failed`, used when an optimistic send
// fails and never reaches the server at all.

enum MessageStatus {
  sending,   // optimistic — sitting only in this device's memory
  sent,      // saved on the server
  delivered, // recipient's device has fetched it
  seen,      // recipient opened the conversation and read it
  failed,    // client-only — optimistic send failed, show retry
}

extension MessageStatusX on MessageStatus {
  static MessageStatus fromServerString(String? value) {
    switch (value) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'seen':
        return MessageStatus.seen;
      case 'sending':
        return MessageStatus.sending;
      default:
        return MessageStatus.sent;
    }
  }

  /// Rank used to avoid a late "delivered" event downgrading an
  /// already-"seen" message (out-of-order socket events can happen).
  int get rank {
    switch (this) {
      case MessageStatus.sending:
        return 0;
      case MessageStatus.sent:
        return 1;
      case MessageStatus.delivered:
        return 2;
      case MessageStatus.seen:
        return 3;
      case MessageStatus.failed:
        return -1;
    }
  }
}