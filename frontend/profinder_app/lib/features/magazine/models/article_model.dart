// lib/features/magazine/models/article_model.dart

class ArticleCategory {
  final int    id;
  final String name;
  final String icon;
  final String color;
  final int    articlesCount;

  ArticleCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.articlesCount,
  });

  factory ArticleCategory.fromJson(Map<String, dynamic> json) {
    return ArticleCategory(
      id:            json['id']             ?? 0,
      name:          json['name']           ?? '',
      icon:          json['icon']           ?? 'article',
      color:         json['color']          ?? '#2563EB',
      articlesCount: json['articles_count'] ?? 0,
    );
  }
}

class Article {
  final int     id;
  final String  title;
  final String  slug;
  final String  summary;
  final String  content;
  final String  coverImage;
  final int?    categoryId;
  final String  categoryName;
  final String  categoryColor;
  final String  editorialLabel;   // ✅ "ProFinder Health Desk" etc. — admin naam nahi
  final int     readTime;
  final int     viewsCount;
  final bool    isPublished;
  final String  publishedAt;

  Article({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.content,
    required this.coverImage,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.editorialLabel,
    required this.readTime,
    required this.viewsCount,
    required this.isPublished,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id:             json['id']              ?? 0,
      title:          json['title']           ?? '',
      slug:           json['slug']            ?? '',
      summary:        json['summary']         ?? '',
      content:        json['content']         ?? '',
      coverImage:     json['cover_image']     ?? '',
      categoryId:     json['category'],
      categoryName:   json['category_name']   ?? '',
      categoryColor:  json['category_color']  ?? '#2563EB',
      editorialLabel: json['editorial_label'] ?? 'ProFinder Editorial',
      readTime:       json['read_time']       ?? 1,
      viewsCount:     json['views_count']     ?? 0,
      isPublished:    json['is_published']    ?? false,
      publishedAt:    json['published_at']    ?? '',
    );
  }
}

// ── Admin Analytics Models ────────────────────────────────────────────────────

class ArticleAnalytics {
  final int    id;
  final String title;
  final String slug;
  final String coverImage;
  final String categoryName;
  final String categoryColor;
  final String editorialLabel;
  final bool   isPublished;
  final int    viewsCount;
  final int    uniqueViewers;
  final String publishedAt;
  final List<ViewLog> recentViews;

  ArticleAnalytics({
    required this.id,
    required this.title,
    required this.slug,
    required this.coverImage,
    required this.categoryName,
    required this.categoryColor,
    required this.editorialLabel,
    required this.isPublished,
    required this.viewsCount,
    required this.uniqueViewers,
    required this.publishedAt,
    required this.recentViews,
  });

  factory ArticleAnalytics.fromJson(Map<String, dynamic> json) {
    final logs = (json['recent_views'] as List? ?? [])
        .map((v) => ViewLog.fromJson(v))
        .toList();
    return ArticleAnalytics(
      id:             json['id']              ?? 0,
      title:          json['title']           ?? '',
      slug:           json['slug']            ?? '',
      coverImage:     json['cover_image']     ?? '',
      categoryName:   json['category_name']   ?? '',
      categoryColor:  json['category_color']  ?? '#2563EB',
      editorialLabel: json['editorial_label'] ?? '',
      isPublished:    json['is_published']    ?? false,
      viewsCount:     json['views_count']     ?? 0,
      uniqueViewers:  json['unique_viewers']  ?? 0,
      publishedAt:    json['published_at']    ?? '',
      recentViews:    logs,
    );
  }
}

class ViewLog {
  final String userName;
  final String userEmail;
  final String userRole;
  final String viewedAt;

  ViewLog({
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.viewedAt,
  });

  factory ViewLog.fromJson(Map<String, dynamic> json) {
    return ViewLog(
      userName:  json['user_name']  ?? 'Guest',
      userEmail: json['user_email'] ?? '',
      userRole:  json['user_role']  ?? '',
      viewedAt:  json['viewed_at']  ?? '',
    );
  }
}

class MagazineAnalyticsSummary {
  final int totalViews;
  final int viewsToday;
  final int viewsThisWeek;
  final int uniqueReaders;
  final int totalArticles;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<ArticleAnalytics>  articles;

  MagazineAnalyticsSummary({
    required this.totalViews,
    required this.viewsToday,
    required this.viewsThisWeek,
    required this.uniqueReaders,
    required this.totalArticles,
    required this.categoryBreakdown,
    required this.articles,
  });

  factory MagazineAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final s   = json['summary'] ?? {};
    final cats = (json['category_breakdown'] as List? ?? [])
        .map((c) => CategoryBreakdown.fromJson(c))
        .toList();
    final arts = (json['articles'] as List? ?? [])
        .map((a) => ArticleAnalytics.fromJson(a))
        .toList();
    return MagazineAnalyticsSummary(
      totalViews:       s['total_views']     ?? 0,
      viewsToday:       s['views_today']     ?? 0,
      viewsThisWeek:    s['views_this_week'] ?? 0,
      uniqueReaders:    s['unique_readers']  ?? 0,
      totalArticles:    s['total_articles']  ?? 0,
      categoryBreakdown: cats,
      articles:          arts,
    );
  }
}

class CategoryBreakdown {
  final String categoryName;
  final String categoryColor;
  final int    totalViews;

  CategoryBreakdown({
    required this.categoryName,
    required this.categoryColor,
    required this.totalViews,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categoryName:  json['article__category__name']  ?? 'Uncategorized',
      categoryColor: json['article__category__color'] ?? '#6B7280',
      totalViews:    json['total_views']              ?? 0,
    );
  }
}