class Receipt {
  String receiptId;
  String name;
  String store;
  DateTime date;
  String? rawOcrText;
  String? receiptImg;
  String? currency;

  Receipt({
    required this.receiptId,
    required this.name,
    required this.store,
    required this.date,
    this.rawOcrText,
    this.receiptImg,
    this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'receiptId': receiptId,
      'name': name,
      'store': store,
      'date': date.toIso8601String(),
      'rawOcrText': rawOcrText,
      'receiptImg': receiptImg,
      'currency': currency,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      receiptId: map['receiptId'] as String,
      name: map['name'] as String,
      store: map['store'] as String,
      date: DateTime.parse(map['date'] as String),
      rawOcrText: map['rawOcrText'] as String?,
      receiptImg: map['receiptImg'] as String?,
      currency: map['currency'] as String?,
    );
  }
}
