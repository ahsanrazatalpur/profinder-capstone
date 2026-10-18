// Shared fake for the admin ticket widget tests. No network, no Dio.

import 'package:profinder_app/features/admin/models/support_admin_models.dart';
import 'package:profinder_app/services/support_admin_service.dart';
import 'package:profinder_app/services/support_service.dart';

AdminPerson adminPerson({int id = 1, String name = 'Admin One', String email = 'admin@example.com'}) =>
    AdminPerson(id: id, name: name, email: email, role: 'admin');

AdminTicketSummary adminSummary({
  int id = 1,
  String reference = 'PF-000001',
  String subject = 'Cannot withdraw',
  String category = 'payment',
  String status = 'open',
  String priority = 'normal',
  bool guest = false,
  AdminPerson? assignedTo,
  bool needsReply = true,
}) =>
    AdminTicketSummary(
      id: id,
      reference: reference,
      subject: subject,
      category: category,
      status: status,
      priority: priority,
      role: guest ? 'guest' : 'customer',
      requester: guest
          ? null
          : const AdminPerson(id: 7, name: 'Alice Khan', email: 'alice@example.com', role: 'customer'),
      contactEmail: guest ? 'guest@example.com' : '',
      assignedTo: assignedTo,
      createdAt: DateTime(2026, 10, 9, 14, 30),
      lastActivityAt: DateTime(2026, 10, 10, 9, 5),
      needsReply: needsReply,
    );

AdminTicketMessage adminMessage(int id, String body, {bool staff = false, bool internal = false}) =>
    AdminTicketMessage(
      id: id,
      body: body,
      isStaff: staff,
      isInternal: internal,
      authorName: staff ? 'Admin One' : null,
      createdAt: DateTime(2026, 10, 10, 9, id),
    );

class FakeAdminSource implements SupportAdminDataSource {
  // Mutable "server" state for one ticket.
  String status;
  String priority;
  AdminPerson? assignee;
  bool guest;
  List<AdminTicketMessage> messages;

  SupportResult<AdminTicketCounts> counts;
  SupportResult<AdminTicketPage> page;
  SupportResult<AdminTicketPage>? morePage;
  SupportResult<AdminTicketDetail>? detailOverride;
  SupportResult<AdminTicketDetail>? replyOverride;

  final List<Map<String, Object?>> listCalls = [];
  final List<Map<String, Object?>> updateCalls = [];
  final List<Map<String, Object?>> replyCalls = [];

  FakeAdminSource({
    this.status = 'open',
    this.priority = 'normal',
    this.assignee,
    this.guest = false,
    List<AdminTicketMessage>? messages,
    SupportResult<AdminTicketCounts>? counts,
    SupportResult<AdminTicketPage>? page,
    this.morePage,
    this.detailOverride,
    this.replyOverride,
  })  : messages = messages ??
            [
              adminMessage(1, 'My withdrawal failed.'),
              adminMessage(2, 'Please share the amount.', staff: true),
              adminMessage(3, 'SECRET: looks like fraud check', staff: true, internal: true),
            ],
        counts = counts ??
            const SupportResult.ok(AdminTicketCounts(
              byStatus: {'open': 2, 'in_progress': 1, 'awaiting_user': 0, 'resolved': 4, 'closed': 9},
              unassignedActive: 2,
              mineActive: 1,
              needsReply: 2,
            )),
        page = page ??
            SupportResult.ok(AdminTicketPage(count: 2, results: [
              adminSummary(priority: 'high'),
              adminSummary(id: 2, reference: 'PF-000002', subject: 'Cannot log in', guest: true, needsReply: false),
            ]));

  AdminTicketDetail build() => AdminTicketDetail(
        summary: adminSummary(
          status: status,
          priority: priority,
          guest: guest,
          assignedTo: assignee,
        ),
        relatedBooking: 55,
        platform: 'android',
        appVersion: '',
        appLanguage: 'ur',
        closedAt: null,
        messages: messages,
        events: [
          AdminTicketEvent(action: 'created', detail: '', actorName: 'Alice Khan', createdAt: DateTime(2026, 10, 9, 14, 30)),
          AdminTicketEvent(action: 'status_changed', detail: 'open -> in_progress', actorName: 'Admin One', createdAt: DateTime(2026, 10, 9, 15)),
        ],
      );

  @override
  Future<SupportResult<AdminTicketCounts>> getCounts() async => counts;

  @override
  Future<SupportResult<AdminTicketPage>> getTickets({
    String? status,
    String? assigned,
    bool needsReply = false,
    String? query,
    int offset = 0,
    int limit = 30,
  }) async {
    listCalls.add({'status': status, 'assigned': assigned, 'needsReply': needsReply, 'query': query, 'offset': offset});
    if (offset > 0 && morePage != null) return morePage!;
    return page;
  }

  @override
  Future<SupportResult<AdminTicketDetail>> getTicket(int id) async =>
      detailOverride ?? SupportResult.ok(build());

  @override
  Future<SupportResult<AdminTicketDetail>> reply(int id, String body, {required bool internal}) async {
    replyCalls.add({'body': body, 'internal': internal});
    if (replyOverride != null) return replyOverride!;
    messages = [...messages, adminMessage(messages.length + 1, body, staff: true, internal: internal)];
    if (!internal && status == 'open') status = 'awaiting_user';
    return SupportResult.ok(build());
  }

  @override
  Future<SupportResult<AdminTicketDetail>> update(
    int id, {
    String? status,
    String? priority,
    String? assignee,
  }) async {
    updateCalls.add({'status': status, 'priority': priority, 'assignee': assignee});
    if (status != null) this.status = status;
    if (priority != null) this.priority = priority;
    if (assignee == 'me') this.assignee = adminPerson();
    if (assignee == 'none') this.assignee = null;
    return SupportResult.ok(build());
  }
}
