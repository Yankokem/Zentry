import 'package:flutter/material.dart';
import 'package:zentry/config/theme.dart';

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I reset my password?',
      answer: 'Go to the login screen and tap "Forgot Password" to reset your password via email.',
    ),
    FAQItem(
      question: 'How do I report a bug?',
      answer: 'Use the "Report a Bug" section in Help & Support to submit details about the issue.',
    ),
    FAQItem(
      question: 'How do I contact support?',
      answer: 'Use the "Contact Support" option in Help & Support to send us a message.',
    ),
    FAQItem(
      question: 'Is my data secure?',
      answer: 'Yes, we use industry-standard encryption to protect your data.',
    ),
    FAQItem(
      question: 'How do I update my profile?',
      answer: 'Navigate to the Profile screen and edit your information there.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9ED69),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FAQ',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ExpansionTile(
              title: Text(
                faq.question,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    faq.answer,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
