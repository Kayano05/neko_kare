import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/saving_record.dart';
import '../services/database_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Book> _books = [];
  Map<int, double> _bookTotals = {};

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await _databaseService.getAllBooks();
    final Map<int, double> totals = {};
    
    // 获取所有汇率
    final rates = await _databaseService.getAllExchangeRates();
    final ratesMap = {for (var rate in rates) rate.currency: rate.rate};

    // 计算每个账本的总金额（转换为人民币）
    for (var book in books) {
      final records = await _databaseService.getRecordsForBook(book.id);
      double total = 0;
      for (var record in records) {
        // 转换为人民币
        total += record.amount * (ratesMap[record.currency] ?? 1.0);
      }
      totals[book.id] = total;
    }

    setState(() {
      _books = books;
      _bookTotals = totals;
    });
  }

  void _showCreateBookDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createNewBook),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.bookName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (nameController.text.isNotEmpty) {
                await _databaseService.createBook(
                  nameController.text,
                  descriptionController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadBooks();
                }
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showEditBookDialog(Book book) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: book.name);
    final descriptionController = TextEditingController(text: book.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editBook),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.bookName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (nameController.text.isNotEmpty) {
                await _databaseService.updateBook(
                  Book(
                    id: book.id,
                    name: nameController.text,
                    description: descriptionController.text,
                    createdAt: book.createdAt,
                  ),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadBooks();
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(Book book) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteBookConfirm(book.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseService.deleteBook(book.id);
      _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.myBooks),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          final isCurrentBook = book.id == DatabaseService.currentBookId;
          final bookTotal = _bookTotals[book.id] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Text(
                        book.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentBook) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.current,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (book.description != null) ...[
                        const SizedBox(height: 8),
                        Text(book.description!),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.totalAmount}: ¥${bookTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    position: PopupMenuPosition.under,
                    itemBuilder: (context) => [
                      if (!isCurrentBook)
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF4CAF50),
                            ),
                            title: Text(l10n.setAsCurrent),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () {
                            setState(() {
                              DatabaseService.currentBookId = book.id;
                            });
                            _loadBooks();
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/',
                                (route) => false,
                              );
                            }
                          },
                        ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF4CAF50),
                          ),
                          title: Text(l10n.edit),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () => Future(() => _showEditBookDialog(book)),
                      ),
                      if (!isCurrentBook)
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: Text(
                              l10n.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () => Future(() => _deleteBook(book)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBookDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 