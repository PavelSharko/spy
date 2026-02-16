class Location {
  final String id;
  final String name;
  final String category;
  final String imageAsset; // Path to image if needed later

  Location({
    required this.id,
    required this.name,
    required this.category,
    this.imageAsset = '',
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      category: json['category'],
    );
  }
}
