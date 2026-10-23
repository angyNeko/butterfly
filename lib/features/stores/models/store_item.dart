class StoreItem {
  String storeItemId;
  String storeId;
  String name;
  double defaultPrice;

  StoreItem({
    required this.storeItemId,
    required this.storeId,
    required this.name,
    required this.defaultPrice
  });

  Map<String, dynamic> toMap() => {
    'storeItemId': storeItemId,
    'storeId': storeId,
    'name': name,
    'defaultPrice': defaultPrice,
  };

  factory StoreItem.fromMap(Map<String, dynamic> map) {
    return StoreItem(
      storeItemId: map['storeItemId'] as String,
      storeId: map['storeId'] as String,
      name: map['name'] as String,
      defaultPrice: (map['defaultPrice'] as num).toDouble(),
    );
  }
}