import 'package:flutter/material.dart';
import '../models/saving_record.dart';
import '../services/database_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<SavingRecord> _deletedRecords = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedRecords();
  }

  Future<void> _loadDeletedRecords() async {
    final records = await _databaseService.getDeletedRecords();
    setState(() {
      _deletedRecords = records;
    });
  }

  Future<void> _restoreRecord(SavingRecord record) async {
    await _databaseService.restoreRecord(record.id);
    _loadDeletedRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已恢复')),
      );
    }
  }

  Future<void> _permanentlyDeleteRecord(SavingRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除'),
        content: const Text('此操作无法撤销，确定要永久删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseService.permanentlyDeleteRecord(record.id);
      _loadDeletedRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已永久删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.trash),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _deletedRecords.isEmpty
          ? Center(child: Text(l10n.emptyTrash))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _deletedRecords.length,
              itemBuilder: (context, index) {
                final record = _deletedRecords[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      '${record.currency} ${record.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (record.note != null) ...[
                          const SizedBox(height: 4),
                          Text(record.note!),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore),
                          onPressed: () => _restoreRecord(record),
                          tooltip: '恢复',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever),
                          onPressed: () => _permanentlyDeleteRecord(record),
                          tooltip: '永久删除',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 