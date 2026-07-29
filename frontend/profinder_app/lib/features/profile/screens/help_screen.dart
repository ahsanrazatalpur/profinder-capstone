// lib/features/profile/screens/help_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I book a professional?',
      'a': 'Search or browse categories, open a professional\'s profile, choose a time slot and confirm your booking.',
    },
    {
      'q': 'How do I cancel a booking?',
      'a': 'Go to Bookings, open the booking and tap Cancel. Cancellation policies may vary by professional.',
    },
    {
      'q': 'How do refunds work?',
      'a': 'Approved refunds appear in Payments within a few business days, matched to your original payment method.',
    },
    {
      'q': 'How do I become a verified professional?',
      'a': 'Verification is reviewed and granted by our admin team after checking your submitted credentials.',
    },
    {
      'q': 'Is my payment information secure?',
      'a': 'Yes — payments are processed through secure, encrypted channels. We never store your card details.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Help & Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
            ),
            child: Row(children: [
              const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Need a hand?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Reach our support team anytime', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _contactTile(context, Icons.email_outlined, 'Email Us', 'support@profinder.app')),
            const SizedBox(width: 10),
            Expanded(child: _contactTile(context, Icons.chat_bubble_outline_rounded, 'Live Chat', 'Mon–Sat, 9am–6pm')),
          ]),
          const SizedBox(height: 20),
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 10),
          ..._faqs.map((f) => _faqTile(context, f['q']!, f['a']!)),
        ],
      ),
    );
  }

  Widget _contactTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary, size: 22),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _faqTile(BuildContext context, String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(q, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a, style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}