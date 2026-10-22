import 'package:objectbox/objectbox.dart';

@Entity()
class Item {
  @Id()
  int id = 0;

  @Unique()
  late String itemId;
  late String receiptId;

  late String itemName;
  late double itemPrice;
  late int itemQty;

  late String splitType;
  late List<String> assignedPersonIds;
}