class ExchangeRate {
  final String currency;
  final double rate;  // 相对于人民币的汇率

  ExchangeRate({
    required this.currency,
    required this.rate,
  });

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'rate': rate,
    };
  }

  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    return ExchangeRate(
      currency: map['currency'] as String,
      rate: map['rate'] as double,
    );
  }
} 