class Movie {
  final String id;
  final String title;
  final String genre;
  final String? rating;
  final bool isBanner;
  final bool isFree;
  final int viewersLimit;
  final double price;
  final String description;
  final List<String> actors;
  final String countryName;
  final String isoCode;
  final String language;
  final String? videoId;
  final double duration;
  final String status;
  final String? releaseYear;
  final String releaseType;
  final String posterUrl;
  final String bannerUrl;
  final String trailerUrl;
  final String? videoUrl;
  final String uploadedBy;
  final DateTime? uploadDate;

  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    this.rating,
    required this.isBanner,
    required this.isFree,
    required this.viewersLimit,
    required this.price,
    required this.description,
    required this.actors,
    required this.countryName,
    required this.isoCode,
    required this.language,
    this.videoId,
    required this.duration,
    required this.status,
    this.releaseYear,
    required this.releaseType,
    required this.posterUrl,
    required this.bannerUrl,
    required this.trailerUrl,
    this.videoUrl,
    required this.uploadedBy,
    this.uploadDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      genre: json['genre']?.toString() ?? '',
      rating: json['rating']?.toString(),
      isBanner: json['isBanner'] == true,
      isFree: json['isFree'] == true,
      viewersLimit: _readInt(json['viewersLimit']),
      price: _readDouble(json['price']),
      description: json['description']?.toString() ?? '',
      actors: _readStringList(json['actor']),
      countryName: json['countryName']?.toString() ?? '',
      isoCode: json['isocode']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      videoId: json['videoId']?.toString(),
      duration: _readDouble(json['duration']),
      status: json['status']?.toString() ?? '',
      releaseYear: json['releaseYear']?.toString(),
      releaseType: json['releaseType']?.toString() ?? 'New Release',
      posterUrl: json['moviePictureURL']?.toString() ?? '',
      bannerUrl: json['movieBannerPictureURL']?.toString() ?? '',
      trailerUrl: json['movieTrailerURL']?.toString() ?? '',
      videoUrl: json['movieVideoURL']?.toString(),
      uploadedBy: json['uploadedBy']?.toString() ?? '',
      uploadDate: DateTime.tryParse(json['uploadDate']?.toString() ?? ''),
    );
  }

  String get displayPosterUrl {
    return posterUrl.isNotEmpty ? posterUrl : bannerUrl;
  }

  String get displayBannerUrl {
    return bannerUrl.isNotEmpty ? bannerUrl : posterUrl;
  }

  String get yearLabel {
    if (releaseYear != null && releaseYear!.isNotEmpty) return releaseYear!;
    return uploadDate?.year.toString() ?? '';
  }

  String get ageRatingLabel {
    final value = rating?.trim();
    if (value == null || value.isEmpty) return '16+';
    if (value.endsWith('+')) return value;
    return '$value+';
  }

  String get durationLabel {
    if (duration <= 0) return 'N/A';
    final totalMinutes = duration.round();

    if (totalMinutes < 60) return '$totalMinutes min';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';

    return '${hours}h $minutes min';
  }

  String get priceLabel {
    if (isFree) return 'Free';
    final decimals = price % 1 == 0 ? 0 : 2;
    return '\$${price.toStringAsFixed(decimals)}';
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'genre': genre,
      'rating': rating,
      'isBanner': isBanner,
      'isFree': isFree,
      'viewersLimit': viewersLimit,
      'price': price,
      'description': description,
      'actor': actors,
      'countryName': countryName,
      'isocode': isoCode,
      'language': language,
      'videoId': videoId,
      'duration': duration,
      'status': status,
      'releaseYear': releaseYear,
      'releaseType': releaseType,
      'moviePictureURL': posterUrl,
      'movieBannerPictureURL': bannerUrl,
      'movieTrailerURL': trailerUrl,
      'movieVideoURL': videoUrl,
      'uploadedBy': uploadedBy,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
