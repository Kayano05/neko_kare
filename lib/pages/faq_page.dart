import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/faq.dart';

class FAQPage extends StatelessWidget {
  FAQPage({super.key});

  List<FAQ> _getFAQs(AppLocalizations l10n) => [
    FAQ(
      question: l10n.faqAddRecord,
      answer: l10n.faqAddRecordAnswer,
    ),
    FAQ(
      question: l10n.faqEditRecord,
      answer: l10n.faqEditRecordAnswer,
    ),
    FAQ(
      question: l10n.faqDeleteRecord,
      answer: l10n.faqDeleteRecordAnswer,
    ),
    FAQ(
      question: l10n.faqSetExchangeRate,
      answer: l10n.faqSetExchangeRateAnswer,
    ),
    FAQ(
      question: l10n.faqChangeLanguage,
      answer: l10n.faqChangeLanguageAnswer,
    ),
    FAQ(
      question: l10n.faqRestoreRecord,
      answer: l10n.faqRestoreRecordAnswer,
    ),
    FAQ(
      question: l10n.faqSupportedCurrencies,
      answer: l10n.faqSupportedCurrenciesAnswer,
    ),
    FAQ(
      question: l10n.faqDataLoss,
      answer: l10n.faqDataLossAnswer,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = _getFAQs(l10n);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.faq),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFAQCard(faqs[index]),
          );
        },
      ),
    );
  }

  Widget _buildFAQCard(FAQ faq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          splashColor: const Color(0xFF4CAF50).withOpacity(0.1),
          highlightColor: const Color(0xFF4CAF50).withOpacity(0.05),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedAlignment: Alignment.topLeft,
          maintainState: true,
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: child,
                  ),
                );
              },
              child: Text(
                faq.answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
          iconColor: const Color(0xFF4CAF50),
          collapsedIconColor: const Color(0xFF4CAF50),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    );
  }
} 