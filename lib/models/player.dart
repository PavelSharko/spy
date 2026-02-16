
enum Role {
  spy,
  local,
}

class Player {
  final String id;
  final String name;
  final Role role;
  final String? locationId; // Null if spy (usually), or if global location logic covers it

  Player({
    required this.id,
    required this.name,
    required this.role,
    this.locationId,
  });

  bool get isSpy => role == Role.spy;
  
  // Factory for DB compatibility later
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      role: Role.values.firstWhere((e) => e.toString() == json['role']),
      locationId: json['locationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.toString(),
      'locationId': locationId,
    };
  }
}
