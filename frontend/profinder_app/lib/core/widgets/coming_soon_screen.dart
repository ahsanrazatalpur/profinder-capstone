// lib/core/widgets/coming_soon_screen.dart
//
// Shared, honest placeholder for features that aren't built yet
// (e.g. Messaging). Never fakes data or interactivity — just tells
// the user clearly what's coming.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme_context_ext.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    this.title   = 'Coming Soon',
    this.message = "We're working on this feature. Check back soon!",
    this.icon    = Icons.rocket_launch_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(color: context.colors.primaryLight, shape: BoxShape.circle),
                child: Icon(icon, color: context.colors.primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}