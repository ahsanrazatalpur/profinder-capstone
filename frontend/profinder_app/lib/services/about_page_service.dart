// lib/services/about_page_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';
import '../features/about/models/about_page_model.dart';

class AboutPageService {
  final ApiService _api = ApiService();

  // ── Public (Guest / Customer / Professional / Admin) ────────────────────

  Future<Map<String, dynamic>> getAboutPage({String? lang}) async {
    try {
      final query = lang != null ? '?lang=$lang' : '';
      final response = await _api.get('/about-page/$query');
      return {'success': true, 'data': AboutPageData.fromJson(response.data)};
    } catch (e) {
      return {'success': false, 'data': null, 'error': _errorMessage(e)};
    }
  }

  // ── Admin — Sections ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminSections() async {
    try {
      final response = await _api.get('/about-page/admin/sections/');
      final list = (response.data as List).map((s) => AboutSection.fromJson(s)).toList();
      return {'success': true, 'data': list};
    } catch (e) {
      return {'success': false, 'data': <AboutSection>[], 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> createSection(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/about-page/admin/sections/', data);
      return {'success': true, 'data': AboutSection.fromJson(response.data)};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateSection(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.patch('/about-page/admin/sections/$id/', data);
      return {'success': true, 'data': AboutSection.fromJson(response.data)};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteSection(int id) async {
    try {
      await _api.delete('/about-page/admin/sections/$id/');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  /// [order] — list of {'id': sectionId, 'order': newOrder}
  Future<Map<String, dynamic>> reorderSections(List<Map<String, dynamic>> order) async {
    try {
      await _api.post('/about-page/admin/sections/reorder/', {'order': order});
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  // ── Admin — Dynamic collection items ────────────────────────────────────

  Future<Map<String, dynamic>> getSectionItems(int sectionId) async {
    try {
      final response = await _api.get('/about-page/admin/sections/$sectionId/items/');
      final list = (response.data as List).map((i) => AboutSectionItem.fromJson(i)).toList();
      return {'success': true, 'data': list};
    } catch (e) {
      return {'success': false, 'data': <AboutSectionItem>[], 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> createItem(int sectionId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/about-page/admin/sections/$sectionId/items/', data);
      return {'success': true, 'data': AboutSectionItem.fromJson(response.data)};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateItem(int itemId, Map<String, dynamic> data) async {
    try {
      final response = await _api.patch('/about-page/admin/items/$itemId/', data);
      return {'success': true, 'data': AboutSectionItem.fromJson(response.data)};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteItem(int itemId) async {
    try {
      await _api.delete('/about-page/admin/items/$itemId/');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  /// [order] — list of {'id': itemId, 'order': newOrder}
  Future<Map<String, dynamic>> reorderItems(int sectionId, List<Map<String, dynamic>> order) async {
    try {
      await _api.post('/about-page/admin/sections/$sectionId/items/reorder/', {'order': order});
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  // ── Admin — Multilingual content ────────────────────────────────────────

  Future<Map<String, dynamic>> saveSectionTranslation(
      int sectionId, int languageId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
          '/about-page/admin/sections/$sectionId/translations/$languageId/', data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> saveItemTranslation(
      int itemId, int languageId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
          '/about-page/admin/items/$itemId/translations/$languageId/', data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  // ── Admin — Media ──────────────────────────────────────────────────────────

  /// Upload an image file (already read as bytes/path via image_picker in the
  /// UI layer) and get back an optimized (WebP/auto-quality) delivery URL.
  Future<Map<String, dynamic>> uploadImage(MultipartFile file) async {
    try {
      final formData = FormData.fromMap({'image': file});
      final response = await _api.postForm('/about-page/admin/upload-image/', formData);
      return {'success': true, 'url': response.data['url']};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  // ── Admin — SEO ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSeo() async {
    try {
      final response = await _api.get('/about-page/admin/seo/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'data': null, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> updateSeo(Map<String, dynamic> data) async {
    try {
      final response = await _api.patch('/about-page/admin/seo/', data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  // ── Admin — Publish workflow ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _api.get('/about-page/admin/status/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'data': null, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getPreview({String? lang, bool includeDisabled = false}) async {
    try {
      final params = <String>[];
      if (lang != null) params.add('lang=$lang');
      if (includeDisabled) params.add('include_disabled=true');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _api.get('/about-page/admin/preview/$query');
      return {'success': true, 'data': AboutPageData.fromJson(response.data)};
    } catch (e) {
      return {'success': false, 'data': null, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> publish({String label = ''}) async {
    try {
      final response = await _api.post('/about-page/admin/publish/', {'label': label});
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> unpublish() async {
    try {
      final response = await _api.post('/about-page/admin/unpublish/', {});
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  // ── Admin — Version history ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getVersions() async {
    try {
      final response = await _api.get('/about-page/admin/versions/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'data': <dynamic>[], 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getVersionDetail(int versionId) async {
    try {
      final response = await _api.get('/about-page/admin/versions/$versionId/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'data': null, 'error': _errorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> restoreVersion(int versionId) async {
    try {
      final response = await _api.post('/about-page/admin/versions/$versionId/restore/', {});
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': _errorMessage(e)};
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      return e.message ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }
}