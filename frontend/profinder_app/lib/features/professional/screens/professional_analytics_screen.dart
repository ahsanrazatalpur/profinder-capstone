// lib/features/professional/screens/professional_analytics_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';

class ProfessionalAnalyticsScreen extends StatefulWidget {
  const ProfessionalAnalyticsScreen({super.key});

  @override
  State<ProfessionalAnalyticsScreen> createState() => _ProfessionalAnalyticsScreenState();
}

class _ProfessionalAnalyticsScreenState extends State<ProfessionalAnalyticsScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.get(AppConstants.professionalAnalytics);
      if (!mounted) return;
      setState(() {
        _analytics = res.data is Map ? res.data as Map<String, dynamic> : {};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load analytics. Pull down to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = width > 600;
    final isDesktop = width > 900;
    
    final a = _analytics ?? {};
    final performanceScore = (a['performance_score'] ?? 0).toDouble();
    final contentPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final cardSpacing = isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0);
    final gridColumns = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leadingWidth: isDesktop ? 60 : null,
        leading: isDesktop ? const SizedBox(width: 8) : null,
        title: Text(
          'Analytics',
          style: TextStyle(
            fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _load,
            icon: Icon(
              Icons.refresh_rounded,
              color: context.colors.textSecondary,
              size: isDesktop ? 24.0 : 20.0,
            ),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.professionalColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: TextStyle(
                      fontSize: isDesktop ? 16.0 : 14.0,
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: _error != null
                  ? _buildErrorState(isDark, isDesktop, isTablet)
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(contentPadding),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.sizeOf(context).height - 
                            (isDesktop ? 200 : (isTablet ? 180 : 160)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Performance Score Card
                            _buildPerformanceScoreCard(
                              performanceScore,
                              isDark,
                              isDesktop,
                              isTablet,
                              scale,
                            ),
                            
                            SizedBox(height: cardSpacing),
                            
                            // Stats Grid
                            _buildStatsGrid(
                              a,
                              isDark,
                              isDesktop,
                              isTablet,
                              gridColumns,
                              cardSpacing,
                              scale,
                            ),
                            
                            SizedBox(height: cardSpacing * 1.5),
                            
                            // Info Note
                            _buildInfoNote(isDark, isDesktop, isTablet),
                            
                            SizedBox(height: cardSpacing),
                            
                            // Last Updated
                            _buildLastUpdated(isDark, isDesktop, isTablet),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
    );
  }

  // ── Error State ──────────────────────────────────────────
  Widget _buildErrorState(bool isDark, bool isDesktop, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 48.0 : (isTablet ? 32.0 : 24.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 80.0 : (isTablet ? 70.0 : 60.0),
              height: isDesktop ? 80.0 : (isTablet ? 70.0 : 60.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error.withOpacity(0.1),
                    AppColors.error.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isDesktop ? 40.0 : (isTablet ? 36.0 : 30.0),
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Load Analytics',
              style: TextStyle(
                fontSize: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w400,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: isDesktop ? 15.0 : (isTablet ? 14.0 : 13.0),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.professionalColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0),
                  vertical: isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Performance Score Card ─────────────────────────────
  Widget _buildPerformanceScoreCard(
    double score,
    bool isDark,
    bool isDesktop,
    bool isTablet,
    double scale,
  ) {
    final color = score >= 80 
        ? const Color(0xFF10B981) 
        : (score >= 50 
            ? const Color(0xFFF59E0B) 
            : const Color(0xFFEF4444));
    
    final scoreSize = ResponsiveUtils.sp(
      isDesktop ? 56 : (isTablet ? 48 : 40),
      scale,
      min: 36,
      max: 60,
    ).toDouble();
    
    final padding = isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.3 : 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Colors.white.withOpacity(0.3),
                size: isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0),
              ),
              const SizedBox(width: 10),
              Text(
                'Performance Score',
                style: TextStyle(
                  fontSize: isDesktop ? 16.0 : (isTablet ? 14.0 : 13.0),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            score.toStringAsFixed(0),
            style: TextStyle(
              fontSize: scoreSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'out of 100',
            style: TextStyle(
              fontSize: isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0),
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: isDesktop ? 10.0 : (isTablet ? 8.0 : 7.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: isDesktop ? 11.0 : 10.0,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '100',
                style: TextStyle(
                  fontSize: isDesktop ? 11.0 : 10.0,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Grid ──────────────────────────────────────────
  Widget _buildStatsGrid(
    Map<String, dynamic> a,
    bool isDark,
    bool isDesktop,
    bool isTablet,
    int columns,
    double spacing,
    double scale,
  ) {
    final stats = [
      {
        'label': 'Profile Views',
        'value': '${a['profile_views'] ?? 0}',
        'icon': Icons.visibility_outlined,
        'color': const Color(0xFF3B82F6),
        'subtext': 'Total views',
      },
      {
        'label': 'Visitors',
        'value': '${a['visitors'] ?? 0}',
        'icon': Icons.people_outline_rounded,
        'color': const Color(0xFF8B5CF6),
        'subtext': 'Unique visitors',
      },
      {
        'label': 'Acceptance Rate',
        'value': '${a['acceptance_rate'] ?? 0}%',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF10B981),
        'subtext': 'Bookings accepted',
      },
      {
        'label': 'Response Rate',
        'value': '${a['response_rate'] ?? 0}%',
        'icon': Icons.reply_rounded,
        'color': const Color(0xFFF59E0B),
        'subtext': 'Messages replied',
      },
      {
        'label': 'Average Rating',
        'value': '${a['average_rating'] ?? 0} / 5',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFEF4444),
        'subtext': 'From reviews',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: isDesktop ? 1.6 : (isTablet ? 1.5 : 1.4),
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          stat['label'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['color'] as Color,
          stat['subtext'] as String,
          isDark,
          isDesktop,
          isTablet,
          scale,
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtext,
    bool isDark,
    bool isDesktop,
    bool isTablet,
    double scale,
  ) {
    final iconSize = ResponsiveUtils.sp(
      isDesktop ? 22 : (isTablet ? 20 : 18),
      scale,
      min: 16,
      max: 24,
    ).toDouble();
    
    final valueSize = ResponsiveUtils.sp(
      isDesktop ? 22 : (isTablet ? 20 : 18),
      scale,
      min: 16,
      max: 24,
    ).toDouble();
    
    final padding = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0)),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 8.0 : (isTablet ? 7.0 : 6.0)),
            decoration: BoxDecoration(
              color: isDark 
                  ? color.withOpacity(0.12) 
                  : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(isDesktop ? 10.0 : (isTablet ? 9.0 : 8.0)),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.5),
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtext.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: isDesktop ? 10.0 : 9.0,
                    color: context.colors.textSecondary.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Info Note ────────────────────────────────────────────
  Widget _buildInfoNote(bool isDark, bool isDesktop, bool isTablet) {
    final padding = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF312E81).withOpacity(0.2),
                  const Color(0xFF1E1B4B).withOpacity(0.1),
                ]
              : [
                  const Color(0xFF6366F1).withOpacity(0.06),
                  const Color(0xFF818CF8).withOpacity(0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0)),
        border: Border.all(
          color: isDark
              ? const Color(0xFF818CF8).withOpacity(0.15)
              : const Color(0xFF6366F1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Performance Score = 40% rating + 30% acceptance rate + 30% response rate.',
              style: TextStyle(
                fontSize: isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0),
                color: isDark 
                    ? const Color(0xFFC4B5FD)
                    : context.colors.textSecondary,
                fontWeight: FontWeight.w400,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Last Updated ────────────────────────────────────────
  Widget _buildLastUpdated(bool isDark, bool isDesktop, bool isTablet) {
    return Center(
      child: Text(
        'Last updated: ${DateTime.now().toString().substring(0, 16)}',
        style: TextStyle(
          fontSize: isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0),
          color: context.colors.textSecondary.withOpacity(0.4),
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}