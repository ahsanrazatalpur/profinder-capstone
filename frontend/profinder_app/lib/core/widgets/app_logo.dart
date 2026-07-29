// lib/core/widgets/app_logo.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';
import '../theme/theme_context_ext.dart';

class AppLogo extends StatelessWidget {
  final double size;        // Controls overall size
  final bool   showName;    // Show "ProFinder" text or not
  final bool   showTagline; // Show tagline or not
  final bool   inverted;    // White logo on dark background (splash screen)

  const AppLogo({
    super.key,
    this.size       = 90,
    this.showName   = true,
    this.showTagline = false,
    this.inverted   = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outer glow ring
          Container(
            width:  size,
            height: size,
            decoration: BoxDecoration(
              color: inverted
                  ? AppColors.white.withOpacity(0.15)
                  : context.colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              // Inner circle with PF initials
              child: Container(
                width:  size * 0.72,
                height: size * 0.72,
                decoration: BoxDecoration(
                  color: inverted ? AppColors.white : context.colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'P',
                          style: TextStyle(
                            fontSize:   size * 0.28,
                            fontWeight: FontWeight.bold,
                            color:      inverted
                                ? context.colors.primary
                                : AppColors.white,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: 'F',
                          style: TextStyle(
                            fontSize:   size * 0.28,
                            fontWeight: FontWeight.bold,
                            color:      context.colors.accent,
                            height:     1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // App name
          if (showName) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              AppStrings.appName,
              style: AppTextStyles.h2.copyWith(
                letterSpacing: 1.5,
                color: inverted ? AppColors.white : context.colors.textPrimary,
              ),
            ),
          ],

          // Tagline
          if (showTagline) ...[
            const SizedBox(height: AppSizes.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Text(
                AppStrings.appTagline,
                style: AppTextStyles.bodySmall.copyWith(
                  color: inverted
                      ? AppColors.white.withOpacity(0.8)
                      : context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}