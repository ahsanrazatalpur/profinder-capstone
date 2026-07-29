// lib/core/widgets/app_loader.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_sizes.dart';
import '../theme/theme_context_ext.dart';

// Full screen loader — used in splash screen
class AppSplashLoader extends StatelessWidget {
  final bool inverted; // White dots on dark background

  const AppSplashLoader({
    super.key,
    this.inverted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width:  index == 1 ? 20 : 8, // Middle dot wider
          height: 8,
          decoration: BoxDecoration(
            color: inverted
                ? AppColors.white.withOpacity(index == 1 ? 1.0 : 0.4)
                : context.colors.primary.withOpacity(index == 1 ? 1.0 : 0.4),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        );
      }),
    );
  }
}

// Small inline loader — used inside buttons
class AppButtonLoader extends StatelessWidget {
  const AppButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 22,
      width:  22,
      child:  CircularProgressIndicator(
        color:       AppColors.white,
        strokeWidth: 2.5,
      ),
    );
  }
}

// Full screen centered loader — used when fetching data
class AppFullLoader extends StatelessWidget {
  final String? message;

  const AppFullLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.colors.primary),
          if (message != null) ...[
            const SizedBox(height: AppSizes.md),
            Text(message!, style: TextStyle(color: context.colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}