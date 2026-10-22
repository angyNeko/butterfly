import 'package:objectbox/objectbox.dart';

@Entity()
class Person {
  @Id()
  int id = 0;

  @Unique()
  late String personId;

  late String name;

}