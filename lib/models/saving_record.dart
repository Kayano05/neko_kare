class SavingRecord {
  final int id;
  final double amount;
  final String currency;
  final DateTime date;
  final String? note;

  SavingRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory SavingRecord.fromMap(Map<String, dynamic> map) {
    return SavingRecord(
      id: map['id'] as int,
      amount: map['amount'] as double,
      currency: map['currency'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
} 