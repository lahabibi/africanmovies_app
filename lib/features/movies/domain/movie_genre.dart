class MovieGenre {
  final String id;
  final String name;
  final String description;
  final String pictureUrl;
  final int positionOnDashboard;

  const MovieGenre({
    required this.id,
    required this.name,
    required this.description,
    required this.pictureUrl,
    required this.positionOnDashboard,
  });

  factory MovieGenre.fromJson(Map<String, dynamic> json) {
    return MovieGenre(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pictureUrl: json['genrePictureURL']?.toString() ?? '',
      positionOnDashboard:
          int.tryParse(json['positionOnDashboard']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'genrePictureURL': pictureUrl,
      'positionOnDashboard': positionOnDashboard,
    };
  }
}
