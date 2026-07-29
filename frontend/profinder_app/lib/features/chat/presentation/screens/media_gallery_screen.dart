// lib/features/chat/presentation/screens/media_gallery_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart' show MediaAttachmentEntity;
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../l10n/generated/app_localizations.dart';

class MediaGalleryScreen extends StatefulWidget {
  final int conversationId;
  const MediaGalleryScreen({super.key, required this.conversationId});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  final _repo = ChatRepositoryImpl();
  List<MediaAttachmentEntity> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await _repo.getMedia(widget.conversationId);
      if (!mounted) return;
      setState(() { _items = items; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final images = _items.where((m) => m.fileType == 'image').toList();
    final audio  = _items.where((m) => m.fileType == 'audio').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(t.chatSharedMedia, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(t.chatNoSharedMediaYet, style: TextStyle(fontSize: 14, color: Colors.grey[400])))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (images.isNotEmpty) ...[
                      Text(t.chatPhotos('${images.length}'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
                        itemCount: images.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FullscreenGalleryImage(url: images[i].fileUrl))),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(imageUrl: images[i].fileUrl, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (audio.isNotEmpty) ...[
                      Text(t.chatVoiceMessages('${audio.length}'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      ...audio.map((a) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.mic_none_rounded, color: context.colors.primary),
                                const SizedBox(width: 10),
                                Text(t.chatS('${a.durationSeconds ?? 0}'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text('${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}

class _FullscreenGalleryImage extends StatelessWidget {
  final String url;
  const _FullscreenGalleryImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url))),
    );
  }
}