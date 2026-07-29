// lib/features/auth/widgets/social_auth_button.dart
//
// Premium social-signup button: ripple (InkWell), hover feedback for
// desktop/web (MouseRegion), and a subtle press-scale — the "hover
// effects, ripple effect, press animation" the spec asks for, in one
// reusable widget instead of copy-pasted per provider.

import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

class SocialAuthButton extends StatefulWidget {
  final Widget       logo;
  final String       label;
  final Color        background;
  final Color        textColor;
  final Color?       borderColor;
  final VoidCallback onTap;

  const SocialAuthButton({
    super.key,
    required this.logo,
    required this.label,
    required this.background,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton> {
  bool _hovering = false;
  bool _pressed  = false;

  @override
  Widget build(BuildContext context) {
    final hoverTint = Color.alphaBlend(
      Colors.black.withOpacity(0.04),
      widget.background,
    );

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: _hovering ? hoverTint : widget.background,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: widget.borderColor ?? Colors.transparent,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.logo,
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    widget.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:      widget.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}