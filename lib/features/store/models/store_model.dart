class Store {
  String storeId;
  String name;

  Store({
    required this.storeId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'personId': storeId,
      'name': name,
    };
  }

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      storeId: map['storeId'] as String,
      name: map['name'] as String,
    );
  }
}