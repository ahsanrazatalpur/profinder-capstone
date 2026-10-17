// lib/features/admin/screens/admin_policy_editor_screen.dart
//
// Edit / publish one version of the Privacy Policy (admin, English only).
//
//   * A DRAFT can be edited and published.
//   * A published or archived version is read-only (it is a legal record);
//     to change the policy the admin starts a new version from the list.
//   * The "fill in the blanks" card replaces every "[PLACEHOLDER: ...]" marker
//     in one go, and publishing is blocked until none are left.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/support_content_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../models/support_content_models.dart';
import '../widgets/admin_content_ui.dart';

class AdminPolicyEditorScreen extends StatefulWidget {
  final int versionId;
  final SupportContentDataSource? source;

  const AdminPolicyEditorScreen({super.key, required this.versionId, this.source});

  @override
  State<AdminPolicyEditorScreen> createState() => _AdminPolicyEditorScreenState();
}

class _AdminPolicyEditorScreenState extends State<AdminPolicyEditorScreen> {
  late final SupportContentDataSource _source = widget.source ?? SupportContentService();

  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _body = TextEditingController();
  final Map<String, TextEditingController> _blanks = {};

  AdminPolicyVersion? _version;
  DateTime? _effective;
  bool _loading = true;
  bool _busy = false;
  bool _dirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    for (final c in _blanks.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _editable => _version != null && !_version!.isLocked;

  List<String> get _markers =>
      kPlaceholderPattern.allMatches(_body.text).map((m) => m.group(0)!).toSet().toList();

  int get _markerCount => kPlaceholderPattern.allMatches(_body.text).length;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await _source.getPolicy(widget.versionId);
    if (!mounted) return;
    if (!result.isOk) {
      setState(() { _loading = false; _error = result.error; });
      return;
    }
    _fill(result.data!);
    setState(() { _loading = false; _dirty = false; });
  }

  void _fill(AdminPolicyVersion v) {
    _version = v;
    _title.text = v.title;
    _summary.text = v.changeSummary;
    _body.text = v.body;
    _effective = v.effectiveDate;
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    } else {
      setState(() {}); // placeholder count follows the text
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effective ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _effective = picked;
        _dirty = true;
      });
    }
  }

  void _applyBlanks() {
    var text = _body.text;
    var changed = false;
    for (final marker in _markers) {
      final value = _blanks[marker]?.text.trim() ?? '';
      if (value.isEmpty) continue;
      text = text.replaceAll(marker, value);
      changed = true;
    }
    if (!changed) {
      showContentSnack(context, 'Type a value for at least one blank first.');
      return;
    }
    _body.text = text;
    // Drop fields for markers that no longer exist.
    final left = kPlaceholderPattern.allMatches(text).map((m) => m.group(0)!).toSet();
    final gone = _blanks.keys.where((k) => !left.contains(k)).toList();
    for (final k in gone) {
      _blanks.remove(k)?.dispose();
    }
    _markDirty();
  }

  /// Returns true when the draft was saved.
  Future<bool> _save({bool quiet = false}) async {
    final result = await _source.savePolicy(
      widget.versionId,
      title: _title.text,
      body: _body.text,
      changeSummary: _summary.text,
      effectiveDate: _effective,
    );
    if (!mounted) return false;
    if (!result.isOk) {
      showContentSnack(context, result.error ?? 'Could not save.');
      return false;
    }
    setState(() {
      _version = result.data;
      _dirty = false;
    });
    if (!quiet) showContentSnack(context, 'Draft saved.');
    return true;
  }

  Future<void> _saveTapped() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _save();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _publishTapped() async {
    if (_busy) return;
    final v = _version;
    if (v == null) return;
    final ok = await confirmContentDialog(
      context,
      title: 'Publish version ${v.version}?',
      message: 'It becomes visible to all users right away and can no longer be edited. '
          'To change it later you will have to start a new version.',
      confirmLabel: 'Publish',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final saved = await _save(quiet: true);
    if (!saved) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final result = await _source.publishPolicy(widget.versionId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.isOk) {
      showContentSnack(context, result.error ?? 'Could not publish.');
      return;
    }
    _fill(result.data!);
    setState(() => _dirty = false);
    showContentSnack(context, 'Published. Users can read it now.');
  }

  Future<void> _confirmLeave() async {
    final leave = await confirmContentDialog(
      context,
      title: 'Discard changes?',
      message: 'You have unsaved changes. If you leave now they are lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
    );
    if (leave && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final v = _version;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.lightScaffold,
        appBar: UniversalAppBar(
          title: v == null ? 'Privacy policy' : 'Privacy policy v${v.version}',
          icon: Icons.privacy_tip_rounded,
          color: AppColors.adminColor,
        ),
        body: SafeArea(child: _content()),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
    }
    if (_error != null) return AdminContentError(message: _error!, onRetry: _load);
    final v = _version!;
    final editable = _editable;
    final markers = _markers;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (!editable)
              AdminContentNote(
                icon: Icons.lock_rounded,
                color: AppColors.slate500,
                text: v.status == 'published'
                    ? 'This version is published and cannot be edited. '
                        'To change the policy, go back and start a new version.'
                    : 'This version is archived and cannot be edited.',
              )
            else if (_markerCount > 0)
              AdminContentNote(
                icon: Icons.warning_amber_rounded,
                color: AppColors.warningAmber,
                text: '$_markerCount blank(s) still need a real value. '
                    'You cannot publish until they are filled in.',
              )
            else
              const AdminContentNote(
                icon: Icons.check_circle_rounded,
                color: AppColors.greenDeep,
                text: 'No blanks left. Read the whole text once more, then publish.',
              ),
            const SizedBox(height: 16),
            if (editable && markers.isNotEmpty) ...[
              _blanksCard(markers),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _title,
              enabled: editable,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: editable ? _pickDate : null,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Effective date',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  _effective == null
                      ? 'Not set (today is used when you publish)'
                      : MaterialLocalizations.of(context).formatMediumDate(_effective!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summary,
              enabled: editable,
              maxLength: 500,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(
                labelText: 'What changed (optional)',
                hintText: 'e.g. Added a section about push notifications',
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _body,
              enabled: editable,
              minLines: 14,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(
                labelText: 'Policy text',
                alignLabelWithHint: true,
                helperText: 'Start a line with "# " for a heading and "- " for a bullet. '
                    'Leave a blank line between paragraphs.',
                helperMaxLines: 3,
              ),
            ),
            if (editable) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy || !_dirty ? null : _saveTapped,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy || _markerCount > 0 ? null : _publishTapped,
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('Publish'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _blanksCard(List<String> markers) {
    for (final m in markers) {
      _blanks.putIfAbsent(m, TextEditingController.new);
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fill in the blanks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Each value replaces every place that blank appears in the text.',
              style: TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: 12),
            for (final m in markers) ...[
              TextField(
                key: ValueKey(m),
                controller: _blanks[m],
                decoration: InputDecoration(labelText: placeholderLabel(m), isDense: true),
              ),
              const SizedBox(height: 10),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(onPressed: _applyBlanks, child: const Text('Apply to text')),
            ),
          ],
        ),
      ),
    );
  }
}