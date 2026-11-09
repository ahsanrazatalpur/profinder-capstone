// lib/features/onboarding/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

/// Shown exactly once - the first time the app is ever opened - before the
/// splash/auth flow. LocaleProvider.hasChosenLanguage gates this in main.dart:
/// once the user presses Continue here, this screen never appears again.
class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const LanguageSelectionScreen({super.key, required this.onContinue});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    final currentCode = context.read<LocaleProvider>().locale.languageCode;
    _selectedCode = (currentCode == 'ur') ? 'ur' : 'en';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(builder: (context) => _buildScaffold(context, t)),
    );
  }

  Widget _buildScaffold(BuildContext context, AppLocalizations t) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      const AppLogo(size: 80, showName: false),
                      const SizedBox(height: 16),
                      Text(
                        t.authWelcomeProfinder,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select your preferred language / اپنی زبان منتخب کریں',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Two Large Equal-Sized Selection Cards
                      Expanded(
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildLargeCard(code: 'en', englishTitle: 'English', nativeTitle: 'English', subtitle: 'Browse in English', flag: '🇬🇧')),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildLargeCard(code: 'ur', englishTitle: 'Urdu', nativeTitle: 'اردو', subtitle: 'اردو زبان میں استعمال کریں', flag: '🇵🇰')),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildLargeCard(code: 'en', englishTitle: 'English', nativeTitle: 'English', subtitle: 'Browse in English', flag: '🇬🇧')),
                                  const SizedBox(height: 16),
                                  Expanded(child: _buildLargeCard(code: 'ur', englishTitle: 'Urdu', nativeTitle: 'اردو', subtitle: 'اردو زبان میں استعمال کریں', flag: '🇵🇰')),
                                ],
                              ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune_rounded, size: 16, color: context.colors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'You can change language anytime in Settings / ترتیبات',
                            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            await context.read<LocaleProvider>().setLocale(_selectedCode);
                            widget.onContinue();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedCode == 'ur' ? 'جاری رکھیں (Continue)' : 'Continue (جاری رکھیں)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLargeCard({
    required String code,
    required String englishTitle,
    required String nativeTitle,
    required String subtitle,
    required String flag,
  }) {
    final isSelected = _selectedCode == code;
    final primaryColor = AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() => _selectedCode = code);
        context.read<LocaleProvider>().setLocale(code);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Flag badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.12) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Text(flag, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 12),
            // Primary Name
            Text(
              nativeTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
            if (englishTitle != nativeTitle) ...[
              const SizedBox(height: 2),
              Text(
                englishTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 14),
            // Selection indicator radio
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
