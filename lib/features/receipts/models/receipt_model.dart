import 'package:objectbox/objectbox.dart';

@Entity()
class Receipt {
  // ObjectBox requires an integer ID. Setting it to 0 tells it to auto-increment automatically.
  @Id()
  int id = 0;

  // @Unique() ensures no two receipts can have the same UUID string.
  @Unique()
  late String receiptId;

  late String name;

  late String store;

  // ObjectBox handles dates perfectly, we just tag it so it stores it correctly in the database.
  @Property(type: PropertyType.date)
  late DateTime date;

  String? receiptImg;
}