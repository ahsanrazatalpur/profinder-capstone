// Shared fakes for the ticket / help widget tests. No network, no Dio.

import 'package:profinder_app/features/support/models/ticket_models.dart';
import 'package:profinder_app/services/support_service.dart';

SupportTicketSummary ticketSummary({
  int id = 1,
  String reference = 'PF-000001',
  String subject = 'Cannot withdraw',
  String category = 'payment',
  TicketStatus status = TicketStatus.open,
  bool lastMessageIsStaff = false,
}) =>
    SupportTicketSummary(
      id: id,
      reference: reference,
      subject: subject,
      category: category,
      status: status,
      createdAt: DateTime(2026, 10, 9, 14, 30),
      lastActivityAt: DateTime(2026, 10, 10, 9, 5),
      lastMessageIsStaff: lastMessageIsStaff,
    );

TicketMessageItem ticketMessage(int id, String body, {bool staff = false}) => TicketMessageItem(
      id: id,
      body: body,
      isStaff: staff,
      createdAt: DateTime(2026, 10, 10, 9, id),
    );

SupportTicketDetail ticketDetail({
  TicketStatus status = TicketStatus.open,
  List<TicketMessageItem>? messages,
  String subject = 'Cannot withdraw',
}) =>
    SupportTicketDetail(
      summary: ticketSummary(status: status, subject: subject),
      messages: messages ??
          [
            ticketMessage(1, 'My withdrawal failed.'),
            ticketMessage(2, 'Please share the amount.', staff: true),
          ],
    );

class FakeTicketSource implements TicketDataSource {
  SupportResult<List<SupportTicketSummary>> tickets;
  SupportResult<SupportTicketDetail> detail;
  SupportResult<SupportTicketDetail> created;
  SupportResult<SupportTicketDetail> replied;
  SupportResult<SupportTicketDetail> closed;
  SupportResult<GuestReceipt> guest;

  final List<Map<String, String?>> createCalls = [];
  final List<String> replyCalls = [];
  final List<Map<String, String?>> guestCalls = [];
  int listCalls = 0;
  int closeCalls = 0;

  FakeTicketSource({
    SupportResult<List<SupportTicketSummary>>? tickets,
    SupportResult<SupportTicketDetail>? detail,
    SupportResult<SupportTicketDetail>? created,
    SupportResult<SupportTicketDetail>? replied,
    SupportResult<SupportTicketDetail>? closed,
    SupportResult<GuestReceipt>? guest,
  })  : tickets = tickets ?? SupportResult.ok([ticketSummary()]),
        detail = detail ?? SupportResult.ok(ticketDetail()),
        created = created ?? SupportResult.ok(ticketDetail()),
        replied = replied ??
            SupportResult.ok(ticketDetail(messages: [
              ticketMessage(1, 'My withdrawal failed.'),
              ticketMessage(2, 'Please share the amount.', staff: true),
              ticketMessage(3, 'It was 500.'),
            ])),
        closed = closed ?? SupportResult.ok(ticketDetail(status: TicketStatus.closed)),
        guest = guest ?? const SupportResult.ok(GuestReceipt('PF-000042'));

  @override
  Future<SupportResult<List<SupportTicketSummary>>> getTickets() async {
    listCalls++;
    return tickets;
  }

  @override
  Future<SupportResult<SupportTicketDetail>> getTicket(int id) async => detail;

  @override
  Future<SupportResult<SupportTicketDetail>> createTicket({
    required String subject,
    required String body,
    required String category,
    String? platform,
    String? appLanguage,
  }) async {
    createCalls.add({'subject': subject, 'body': body, 'category': category});
    return created;
  }

  @override
  Future<SupportResult<SupportTicketDetail>> replyToTicket(int id, String body) async {
    replyCalls.add(body);
    return replied;
  }

  @override
  Future<SupportResult<SupportTicketDetail>> closeTicket(int id) async {
    closeCalls++;
    return closed;
  }

  @override
  Future<SupportResult<GuestReceipt>> sendGuestContact({
    required String email,
    required String subject,
    required String body,
    required String category,
    String? platform,
    String? appLanguage,
  }) async {
    guestCalls.add({'email': email, 'subject': subject, 'body': body, 'category': category});
    return guest;
  }
}
