// lib/features/professional/screens/help_support_screen.dart
//
// Static FAQ + contact screen. "Send us an email" button uses url_launcher
// to open the device's mail app — this package is already a common Flutter
// dependency; add `url_launcher` to pubspec.yaml if not already present.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I get verified?',
      'a': 'Add at least one portfolio item with clear photos of your work. '
          'Our admin team reviews submissions within 24-48 hours and adds a '
          'verification badge once approved.',
    },
    {
      'q': 'How do I withdraw my earnings?',
      'a': 'Go to Profile > Wallet & Earnings, add your bank details if you '
          'haven\'t already, then tap "Withdraw" and enter the amount. '
          'Withdrawals are processed within 3-5 business days.',
    },
    {
      'q': 'Why is my booking request still pending?',
      'a': 'New booking requests need your action — accept or reject them '
          'from the Dashboard or Bookings tab. Customers are notified '
          'immediately once you respond.',
    },
    {
      'q': 'How can I improve my profile completion score?',
      'a': 'Add a profile photo, bio, hourly rate, experience, skills, and '
          'at least one portfolio item. Each of these boosts your visibility '
          'in search results.',
    },
    {
      'q': 'How do I change my availability status?',
      'a': 'On your Profile tab, toggle the "Available for Bookings" switch. '
          'This updates instantly and controls whether new customers can '
          'book you.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Help & Support',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildContactCard(context),
          const SizedBox(height: 20),
          Text('Frequently Asked Questions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
          const SizedBox(height: 10),
          ..._faqs.map((faq) => _buildFaqTile(context, faq['q']!, faq['a']!)),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need more help?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Our support team replies within 24 hours',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showContactSheet(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.professionalColor)),
          ),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.professionalColor),
              title: const Text('support@profinder.com'),
              subtitle: const Text('Email us anytime'),
              onTap: () {}, // ⚠️ Wire up url_launcher's launchUrl(Uri(scheme: 'mailto', ...)) here
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.professionalColor),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 9 AM - 6 PM'),
              onTap: () {}, // ⚠️ Hook up to your support chat provider (Intercom, Zendesk, etc.)
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(answer, style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, height: 1.5)),
          ],
        ),
      ),
    );
  }
}