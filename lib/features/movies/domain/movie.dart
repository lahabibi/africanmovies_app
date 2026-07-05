class Movie {
  final String id;
  final String? movieSku;
  final MovieStoreProducts storeProducts;
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
  final double duration;
  final String status;
  final String? releaseYear;
  final String releaseType;
  final double? score;
  final String posterUrl;
  final String bannerUrl;
  final String trailerUrl;
  final String uploadedBy;
  final DateTime? uploadDate;
  final bool isFavorite;
  final bool inWatchlist;

  const Movie({
    required this.id,
    this.movieSku,
    this.storeProducts = const MovieStoreProducts(),
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
    required this.duration,
    required this.status,
    this.releaseYear,
    required this.releaseType,
    this.score,
    required this.posterUrl,
    required this.bannerUrl,
    required this.trailerUrl,
    required this.uploadedBy,
    this.uploadDate,
    this.isFavorite = false,
    this.inWatchlist = false,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      movieSku: _readOptionalCleanString(json['movieSku']),
      storeProducts: MovieStoreProducts.fromJson(json['storeProducts']),
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
      duration: _readDouble(json['duration']),
      status: json['status']?.toString() ?? '',
      releaseYear: json['releaseYear']?.toString(),
      releaseType: json['releaseType']?.toString() ?? 'New Release',
      score: _readOptionalDouble(
        json['score'] ??
            json['movieScore'] ??
            json['averageRating'] ??
            json['ratingScore'],
      ),
      posterUrl: json['moviePictureURL']?.toString() ?? '',
      bannerUrl: json['movieBannerPictureURL']?.toString() ?? '',
      trailerUrl: json['movieTrailerURL']?.toString() ?? '',
      uploadedBy: json['uploadedBy']?.toString() ?? '',
      uploadDate: DateTime.tryParse(json['uploadDate']?.toString() ?? ''),
      isFavorite: json['isFavorite'] == true,
      inWatchlist: json['inWatchlist'] == true,
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

  String? get scoreLabel {
    final value = score;
    if (value == null || value <= 0) return null;

    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'movieSku': movieSku,
      'storeProducts': storeProducts.toJson(),
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
      'duration': duration,
      'status': status,
      'releaseYear': releaseYear,
      'releaseType': releaseType,
      'score': score,
      'moviePictureURL': posterUrl,
      'movieBannerPictureURL': bannerUrl,
      'movieTrailerURL': trailerUrl,
      'uploadedBy': uploadedBy,
      'uploadDate': uploadDate?.toIso8601String(),
      'isFavorite': isFavorite,
      'inWatchlist': inWatchlist,
    };
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _readOptionalDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _readOptionalCleanString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}

enum StoreProductRegistrationStatus { notRegistered, registered, syncFailed }

class MovieStoreProducts {
  final MovieStoreProduct? ios;
  final MovieStoreProduct? android;

  const MovieStoreProducts({this.ios, this.android});

  factory MovieStoreProducts.fromJson(Object? value) {
    if (value is! Map) return const MovieStoreProducts();

    return MovieStoreProducts(
      ios: MovieStoreProduct.fromJson(value['ios']),
      android: MovieStoreProduct.fromJson(value['android']),
    );
  }

  String? get iosProductId => ios?.productId;

  String? get androidProductId => android?.productId;

  bool get hasAnyProductId {
    return iosProductId != null || androidProductId != null;
  }

  Map<String, dynamic> toJson() {
    return {'ios': ios?.toJson(), 'android': android?.toJson()};
  }
}

class MovieStoreProduct {
  final String productId;
  final String productType;
  final StoreProductRegistrationStatus registrationStatus;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const MovieStoreProduct({
    required this.productId,
    required this.productType,
    required this.registrationStatus,
    this.lastSyncedAt,
    this.errorMessage,
  });

  static MovieStoreProduct? fromJson(Object? value) {
    if (value is! Map) return null;

    final productId = value['productId']?.toString().trim() ?? '';
    if (productId.isEmpty) return null;

    return MovieStoreProduct(
      productId: productId,
      productType: value['productType']?.toString() ?? 'consumable',
      registrationStatus: _readRegistrationStatus(value['registrationStatus']),
      lastSyncedAt: DateTime.tryParse(value['lastSyncedAt']?.toString() ?? ''),
      errorMessage: Movie._readOptionalCleanString(value['errorMessage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productType': productType,
      'registrationStatus': switch (registrationStatus) {
        StoreProductRegistrationStatus.registered => 'registered',
        StoreProductRegistrationStatus.syncFailed => 'sync_failed',
        StoreProductRegistrationStatus.notRegistered => 'not_registered',
      },
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  static StoreProductRegistrationStatus _readRegistrationStatus(Object? value) {
    return switch (value?.toString()) {
      'registered' => StoreProductRegistrationStatus.registered,
      'sync_failed' => StoreProductRegistrationStatus.syncFailed,
      _ => StoreProductRegistrationStatus.notRegistered,
    };
  }
}
