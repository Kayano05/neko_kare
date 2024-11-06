import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import '../services/language_service.dart';
import '../services/database_helper.dart';
import 'exchange_rates_page.dart';
import 'trash_page.dart';
import 'faq_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LanguageService _languageService = LanguageService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 语言设置卡片
          _buildCard(
            child: ListTile(
              leading: const Icon(
                Icons.language,
                color: Color(0xFF4CAF50),
              ),
              title: Text(
                l10n.language,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              onTap: () => _showLanguageDialog(context),
            ),
          ),
          const SizedBox(height: 12),

          // 汇率设置卡片
          _buildCard(
            child: ListTile(
              leading: const Icon(
                Icons.currency_exchange,
                color: Color(0xFF4CAF50),
              ),
              title: Text(
                l10n.exchangeRates,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(l10n.exchangeRatesSubtitle),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExchangeRatesPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 回收站卡片
          _buildCard(
            child: ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFF4CAF50),
              ),
              title: Text(
                l10n.trash,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(l10n.trashSubtitle),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrashPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 常见问题卡片
          _buildCard(
            child: ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: Color(0xFF4CAF50),
              ),
              title: Text(
                l10n.faq,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(l10n.faqSubtitle),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FAQPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
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
      child: child,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.language),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(l10n.english, 'en'),
              _buildLanguageOption(l10n.japanese, 'ja'),
              _buildLanguageOption(l10n.german, 'de'),
              _buildLanguageOption(l10n.chinese, 'zh'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String title, String code) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: () => _changeLanguage(code),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF4CAF50),
      ),
    );
  }

  void _changeLanguage(String languageCode) async {
    await _languageService.setLocale(languageCode);
    if (mounted) {
      Navigator.of(context).pop();
      Phoenix.rebirth(context);
    }
  }
} 