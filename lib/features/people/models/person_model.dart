class Person {
  String personId;
  String name;

  Person({
    required this.personId,
    required this.name,
  });

  // Convert object to Map for Sembast
  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'name': name,
    };
  }

  // Convert Map back to Person object
  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      personId: map['personId'] as String,
      name: map['name'] as String,
    );
  }
}