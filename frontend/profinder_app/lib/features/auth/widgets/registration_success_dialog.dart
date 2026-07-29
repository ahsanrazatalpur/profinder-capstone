// lib/features/auth/widgets/registration_success_dialog.dart
//
// Shown right after a successful registration. Matches the spec's exact
// copy ("Welcome to ProFinder! Please verify your email to activate your
// account.") with a premium animated checkmark — elastic scale + fade in,
// nothing overdone.
//
// NOTE: there is no Email Verification screen/flow built yet (that needs
// a backend verification-token endpoint too) — this dialog's continue
// button goes to Login for now. Flagging that honestly rather than
// wiring a fake "verify" step; happy to build the real flow as its own
// module whenever you want it.

import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context_ext.dart';

class RegistrationSuccessDialog extends StatefulWidget {
  final VoidCallback onContinue;

  const RegistrationSuccessDialog({super.key, required this.onContinue});

  @override
  State<RegistrationSuccessDialog> createState() => _RegistrationSuccessDialogState();
}

class _RegistrationSuccessDialogState extends State<RegistrationSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve:  Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve:  const Interval(0, 0.4, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  width:  88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: context.colors.accentLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size:  48,
                    color: context.colors.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Welcome to ProFinder!',
              style: context.textStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Please verify your email to activate your account.',
              style: context.textStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                child: const Text('Continue to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}