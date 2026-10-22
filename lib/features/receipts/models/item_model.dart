class Item {
  late String itemId;
  late String receiptId;

  late String itemName;
  late double itemPrice;
  late int itemQty;

  late String splitType;
  late List<String> assignedPersonIds;

  Item({
    required this.itemId,
    required this.receiptId,
    required this.itemName,
    required this.itemPrice,
    required this.itemQty,
    required this.splitType,
    required this.assignedPersonIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'receiptId': receiptId,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'itemQty': itemQty,
      'splitType': splitType,
      'assignedPersonIds': assignedPersonIds,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      itemId: map['itemId'] as String,
      receiptId: map['receiptId'] as String,
      itemName: map['itemName'] as String,
      itemPrice: map['itemPrice'] as double,
      itemQty: map['itemQty'] as int,
      splitType: map['splitType'] as String,
      assignedPersonIds: List<String>.from(map['assignedPersonIds']),
    );
  }
}