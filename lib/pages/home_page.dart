import 'package:flutter/material.dart';
import '../models/saving_record.dart';
import '../models/exchange_rate.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import 'add_record_page.dart';
import 'books_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _databaseService = DatabaseService();
  List<SavingRecord> _records = [];
  String _displayCurrency = 'CNY';
  double _totalAmount = 0;
  Map<String, double> _rates = {};
  String _currentBookName = '默认账本';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookName = await _databaseService.getCurrentBookName();
    setState(() {
      _currentBookName = bookName;
    });
    // 加载汇率
    final rates = await _databaseService.getAllExchangeRates();
    final ratesMap = {for (var rate in rates) rate.currency: rate.rate};
    
    // 加载记录
    final records = await _databaseService.getRecords();
    
    // 计算总金额（转换为显示货币）
    double total = 0;
    for (var record in records) {
      // 先转换为人民币
      double amountInCNY = record.amount * (ratesMap[record.currency] ?? 1.0);
      // 再转换为显示货币
      total += amountInCNY / (ratesMap[_displayCurrency] ?? 1.0);
    }

    setState(() {
      _rates = ratesMap;
      _records = records;
      _totalAmount = total;
    });
  }

  void _showCurrencyPicker() {
    final l10n = AppLocalizations.of(context)!;
    final List<Map<String, String>> currencies = [
      {'code': 'CNY', 'symbol': '¥'},
      {'code': 'JPY', 'symbol': '¥'},
      {'code': 'USD', 'symbol': '\$'},
      {'code': 'EUR', 'symbol': '€'},
      {'code': 'AUD', 'symbol': 'A\$'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.selectDisplayCurrency,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...currencies.map((currency) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    currency['symbol']!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                title: Text(_getCurrencyName(currency['code']!)),
                subtitle: Text(currency['code']!),
                selected: _displayCurrency == currency['code'],
                onTap: () {
                  setState(() {
                    _displayCurrency = currency['code']!;
                  });
                  _loadData();
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
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

  void _addRecord() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRecordPage(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      try {
        final newRecord = SavingRecord(
          id: 0,
          amount: result['amount'],
          currency: result['currency'],
          date: result['date'],
          note: result['note'],
        );

        await _databaseService.insertRecord(newRecord);
        if (mounted) {
          await _loadData();
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存记录失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteRecord(SavingRecord record) async {
    await _databaseService.deleteRecord(record.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String currencySymbol = {
      'CNY': '¥',
      'JPY': '¥',
      'USD': '\$',
      'EUR': '€',
      'AUD': 'A\$',
    }[_displayCurrency] ?? '¥';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BooksPage()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4CAF50),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentBookName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.totalSavings,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _showCurrencyPicker,
                      child: Text(
                        _displayCurrency,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _records.isEmpty
                ? Center(
                    child: Text(
                      l10n.noRecords,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return Dismissible(
                        key: Key(record.id.toString()),
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final bool? result = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(l10n.confirmDelete),
                                content: Text(l10n.deleteRecordConfirm(
                                  '${record.currency} ${record.amount.toStringAsFixed(2)}'
                                )),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: Text(l10n.delete),
                                  ),
                                ],
                              );
                            },
                          );
                          if (result == true) {
                            await _deleteRecord(record);
                          }
                          return result;
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.savings,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              '${record.currency} ${record.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            subtitle: record.note?.isNotEmpty == true
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      record.note!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : null,
                            trailing: Text(
                              '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddRecordPage()),
        ),
        child: const Icon(Icons.add),
        tooltip: l10n.addRecord,
      ),
    );
  }
} 