class Receipt {
  String receiptId;
  String name;
  String store;
  DateTime date;
  String? rawOcrText;

  Receipt({
    required this.receiptId,
    required this.name,
    required this.store,
    required this.date,
    this.rawOcrText, String? receiptImg,
  });

  Map<String, dynamic> toMap() {
    return {
      'receiptId': receiptId,
      'name': name,
      'store': store,
      'date': date.toIso8601String(),
      'rawOcrText': rawOcrText,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      receiptId: map['receiptId'] as String,
      name: map['name'] as String,
      store: map['store'] as String,
      date: DateTime.parse(map['date'] as String),
      rawOcrText: map['rawOcrText'] as String?,
    );
  }
}