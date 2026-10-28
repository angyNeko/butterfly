class Person {
  String personId;
  String name;
  bool active;

  Person({
    required this.personId,
    required this.name,
    this.active = true,
  });

  // Convert object to Map for Sembast
  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'name': name,
      'active': active,
    };
  }

  // Convert Map back to Person object
  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      personId: map['personId'] as String,
      name: map['name'] as String,
      // If 'active' is null (like in older data), default to true
      active: map['active'] as bool,
    );
  }
}