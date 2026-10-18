// lib/features/admin/screens/admin_article_editor_screen.dart
//
// Create / edit one Help Center article (admin, English only).
// A new article starts unpublished; users only see it once "Published" is on.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/support_content_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../models/support_content_models.dart';
import '../widgets/admin_content_ui.dart';

class AdminArticleEditorScreen extends StatefulWidget {
  /// null = create a new article.
  final int? articleId;
  final SupportContentDataSource? source;

  const AdminArticleEditorScreen({super.key, this.articleId, this.source});

  @override
  State<AdminArticleEditorScreen> createState() =>
      _AdminArticleEditorScreenState();
}

class _AdminArticleEditorScreenState extends State<AdminArticleEditorScreen> {
  late final SupportContentDataSource _source =
      widget.source ?? SupportContentService();

  final _title = TextEditingController();
  final _body = TextEditingController();

  List<AdminHelpCategory> _categories = [];
  int? _categoryId;
  String _audience = 'all';
  bool _published = false;
  bool _wasPublished = false;
  int? _id;
  bool _loading = true;
  bool _busy = false;
  bool _dirty = false;
  String? _error;

  bool get _isNew => _id == null;

  @override
  void initState() {
    super.initState();
    _id = widget.articleId;
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final cats = await _source.listCategories();
    if (!mounted) return;
    if (!cats.isOk) {
      setState(() {
        _loading = false;
        _error = cats.error;
      });
      return;
    }
    _categories = cats.data ?? [];
    if (_id != null) {
      final article = await _source.getArticle(_id!);
      if (!mounted) return;
      if (!article.isOk) {
        setState(() {
          _loading = false;
          _error = article.error;
        });
        return;
      }
      _apply(article.data!);
    } else if (_categories.isNotEmpty) {
      _categoryId = _categories.first.id;
    }
    setState(() {
      _loading = false;
      _dirty = false;
    });
  }

  void _apply(AdminHelpArticle a) {
    _id = a.id;
    _title.text = a.title;
    _body.text = a.body;
    _audience = kAdminAudienceLabels.containsKey(a.audience)
        ? a.audience
        : 'all';
    _published = a.isPublished;
    _wasPublished = a.isPublished;
    _categoryId = _categories.any((c) => c.id == a.categoryId)
        ? a.categoryId
        : (_categories.isEmpty ? null : _categories.first.id);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _saveTapped() async {
    if (_busy) return;
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      showContentSnack(context, 'Add a title and the article text first.');
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) {
      showContentSnack(context, 'Choose a category.');
      return;
    }
    setState(() => _busy = true);

    ContentResult<AdminHelpArticle> result;
    if (_isNew) {
      result = await _source.createArticle(
        categoryId: categoryId,
        audience: _audience,
        title: _title.text,
        body: _body.text,
      );
      if (result.isOk && _published) {
        result = await _source.updateArticle(
          result.data!.id,
          isPublished: true,
        );
      }
    } else {
      result = await _source.updateArticle(
        _id!,
        categoryId: categoryId,
        audience: _audience,
        title: _title.text,
        body: _body.text,
        isPublished: _published,
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.isOk) {
      showContentSnack(context, result.error ?? 'Could not save.');
      return;
    }
    _apply(result.data!);
    setState(() => _dirty = false);
    showContentSnack(
      context,
      _published ? 'Saved. This article is live.' : 'Saved as a draft.',
    );
  }

  Future<void> _deleteTapped() async {
    final ok = await confirmContentDialog(
      context,
      title: 'Delete this article?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final result = await _source.deleteArticle(_id!);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.isOk) {
      showContentSnack(context, result.error ?? 'Could not delete.');
      return;
    }
    setState(() => _dirty = false);
    Navigator.pop(context);
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
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.lightScaffold,
        appBar: UniversalAppBar(
          title: widget.articleId == null && _isNew
              ? 'New article'
              : 'Edit article',
          icon: Icons.article_rounded,
          color: AppColors.adminColor,
        ),
        body: SafeArea(child: _content()),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.adminColor),
      );
    }
    if (_error != null)
      return AdminContentError(message: _error!, onRetry: _load);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c.id, child: Text(c.title)),
              ],
              onChanged: (v) {
                setState(() => _categoryId = v);
                _markDirty();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Who can see it'),
              items: [
                for (final e in kAdminAudienceLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _audience = v);
                _markDirty();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              maxLength: 200,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _body,
              minLines: 10,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(
                labelText: 'Article text',
                alignLabelWithHint: true,
                helperText:
                    'Start a line with "- " for a bullet. '
                    'Leave a blank line between paragraphs.',
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published'),
              subtitle: Text(
                _published
                    ? 'Users can read this article.'
                    : 'Hidden from users until you turn this on.',
              ),
              value: _published,
              activeThumbColor: AppColors.greenDeep,
              onChanged: (v) {
                setState(() => _published = v);
                _markDirty();
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy || !(_dirty || _isNew) ? null : _saveTapped,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isNew ? 'Create article' : 'Save changes'),
            ),
            if (!_isNew) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy || _wasPublished ? null : _deleteTapped,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(
                  _wasPublished
                      ? 'Turn off "Published" and save to delete'
                      : 'Delete article',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.dangerRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
