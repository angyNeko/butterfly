class StoreRecord {
  String storeId;
  String name;

  StoreRecord({required this.storeId, required this.name});

  Map<String, dynamic> toMap() => {
    'storeId': storeId,
    'name': name,
  };

  factory StoreRecord.fromMap(Map<String, dynamic> map) {
    return StoreRecord(
      storeId: map['storeId'] as String,
      name: map['name'] as String,
    );
  }
}