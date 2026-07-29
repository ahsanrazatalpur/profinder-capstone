// lib/features/magazine/services/magazine_service.dart

import '../../../services/api_service.dart';
import '../models/article_model.dart';

class MagazineService {
  final ApiService _api = ApiService();

  Future<List<ArticleCategory>> getCategories() async {
    try {
      final res  = await _api.get('/articles/categories/');
      final list = res.data is List ? List<dynamic>.from(res.data) : [];
      return list.map((j) => ArticleCategory.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  Future<List<Article>> getArticles({int? categoryId, String query = ''}) async {
    try {
      final params = <String>[];
      if (categoryId != null) params.add('category_id=$categoryId');
      if (query.trim().isNotEmpty) params.add('q=${Uri.encodeComponent(query.trim())}');
      final qs   = params.isEmpty ? '' : '?${params.join('&')}';
      final res  = await _api.get('/articles/$qs');
      final list = res.data is List ? List<dynamic>.from(res.data) : [];
      return list.map((j) => Article.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  Future<Article?> getArticle(String slug) async {
    try {
      final res = await _api.get('/articles/$slug/');
      return Article.fromJson(res.data as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<List<Article>> adminGetAll() async {
    try {
      final res  = await _api.get('/articles/admin/all/');
      final list = res.data is List ? List<dynamic>.from(res.data) : [];
      return list.map((j) => Article.fromJson(j)).toList();
    } catch (_) { return []; }
  }

  // ✅ NEW — admin analytics
  Future<MagazineAnalyticsSummary?> adminGetAnalytics() async {
    try {
      final res = await _api.get('/articles/admin/analytics/');
      return MagazineAnalyticsSummary.fromJson(
          res.data as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> adminCreate(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/articles/', data);
      return {'success': true, 'data': res.data};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  Future<Map<String, dynamic>> adminUpdate(String slug, Map<String, dynamic> data) async {
    try {
      final res = await _api.patch('/articles/$slug/', data);
      return {'success': true, 'data': res.data};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  Future<bool> adminDelete(String slug) async {
    try { await _api.delete('/articles/$slug/'); return true; }
    catch (_) { return false; }
  }

  Future<String?> uploadCoverImage(dynamic formData) async {
    try {
      final res = await _api.postForm('/articles/upload-image/', formData);
      return res.data['url'] as String?;
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> adminCreateCategory(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/articles/categories/', data);
      return {'success': true, 'data': res.data};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  Future<bool> adminDeleteCategory(int id) async {
    try { await _api.delete('/articles/categories/$id/'); return true; }
    catch (_) { return false; }
  }
}