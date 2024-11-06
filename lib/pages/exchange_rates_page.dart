import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../models/exchange_rate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExchangeRatesPage extends StatefulWidget {
  const ExchangeRatesPage({super.key});

  @override
  State<ExchangeRatesPage> createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends State<ExchangeRatesPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<ExchangeRate> _rates = [];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final rates = await _databaseService.getAllExchangeRates();
    setState(() {
      _rates = rates;
    });
  }

  void _showEditRateDialog(ExchangeRate rate) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: rate.rate.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setRate(_getCurrencyName(rate.currency))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('1 ${rate.currency} = ? CNY'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.rateInputHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newRate = double.tryParse(controller.text);
              if (newRate != null && newRate > 0) {
                await _databaseService.updateExchangeRate(rate.currency, newRate);
                if (mounted) {
                  Navigator.pop(context);
                  _loadRates();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.rateUpdated)),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  String _getCurrencyName(String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'CNY':
        return l10n.currencyCNY;
      case 'USD':
        return l10n.currencyUSD;
      case 'EUR':
        return l10n.currencyEUR;
      case 'JPY':
        return l10n.currencyJPY;
      case 'AUD':
        return l10n.currencyAUD;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.exchangeRates),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
            child: Column(
              children: _rates.map((rate) => Column(
                children: [
                  ListTile(
                    title: Text(_getCurrencyName(rate.currency)),
                    subtitle: Text('1 ${rate.currency} = ${rate.rate} CNY'),
                    trailing: rate.currency != 'CNY'
                        ? IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFF4CAF50),
                            ),
                            onPressed: () => _showEditRateDialog(rate),
                          )
                        : null,
                  ),
                  if (_rates.indexOf(rate) != _rates.length - 1)
                    const Divider(height: 1),
                ],
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.note,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.currencySettingsHint,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 