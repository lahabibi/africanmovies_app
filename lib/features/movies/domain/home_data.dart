import 'movie.dart';
import 'movie_genre.dart';

class HomeData {
  final List<Movie> movies;
  final List<MovieGenre> genres;
  final MovieLongevity? longevity;
  final List<HomeOrder> orders;

  const HomeData({
    required this.movies,
    required this.genres,
    this.longevity,
    required this.orders,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      movies: _readMapList(json['movies']).map(Movie.fromJson).toList(),
      genres: _readMapList(json['genres']).map(MovieGenre.fromJson).toList(),
      longevity: json['longevity'] is Map
          ? MovieLongevity.fromJson(
              Map<String, dynamic>.from(json['longevity'] as Map),
            )
          : null,
      orders: _readMapList(json['orders']).map(HomeOrder.fromJson).toList(),
    );
  }

  List<Movie> get bannerMovies {
    return movies
        .where((movie) => movie.isBanner && movie.displayBannerUrl.isNotEmpty)
        .take(5)
        .toList();
  }

  List<Movie> get latestUploadedMovies {
    final sortedMovies = [...movies];
    sortedMovies.sort((left, right) {
      final leftDate =
          left.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);

      return rightDate.compareTo(leftDate);
    });

    return sortedMovies.take(15).toList();
  }

  List<Movie> moviesByGenre(String genre) {
    final normalizedGenre = genre.trim().toLowerCase();

    return movies
        .where((movie) => movie.genre.trim().toLowerCase() == normalizedGenre)
        .toList();
  }

  List<Movie> get continueWatchingMovies {
    return orders
        .where((order) => order.movie != null)
        .map((order) => order.movie!)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'movies': movies.map((movie) => movie.toJson()).toList(),
      'genres': genres.map((genre) => genre.toJson()).toList(),
      'longevity': longevity?.toJson(),
      'orders': orders.map((order) => order.toJson()).toList(),
    };
  }

  static List<Map<String, dynamic>> _readMapList(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class MovieLongevity {
  final int days;
  final bool playOnHover;
  final bool slidesAsBanner;

  const MovieLongevity({
    required this.days,
    required this.playOnHover,
    required this.slidesAsBanner,
  });

  factory MovieLongevity.fromJson(Map<String, dynamic> json) {
    return MovieLongevity(
      days: int.tryParse(json['longevity']?.toString() ?? '') ?? 0,
      playOnHover: json['playOnHover'] == true,
      slidesAsBanner: json['slidesAsBanner'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longevity': days,
      'playOnHover': playOnHover,
      'slidesAsBanner': slidesAsBanner,
    };
  }
}

class HomeOrder {
  final String id;
  final String movieId;
  final double currentTime;
  final DateTime? expiryDate;
  final bool startWatch;
  final bool paid;
  final Movie? movie;

  const HomeOrder({
    required this.id,
    required this.movieId,
    required this.currentTime,
    this.expiryDate,
    required this.startWatch,
    required this.paid,
    this.movie,
  });

  factory HomeOrder.fromJson(Map<String, dynamic> json) {
    final rawMovie = json['movieId'];
    final movie = rawMovie is Map
        ? Movie.fromJson(Map<String, dynamic>.from(rawMovie))
        : null;

    return HomeOrder(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      movieId: rawMovie is Map
          ? rawMovie['_id']?.toString() ?? ''
          : rawMovie?.toString() ?? '',
      currentTime: double.tryParse(json['currentTime']?.toString() ?? '') ?? 0,
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? ''),
      startWatch: json['startWatch'] == true,
      paid: json['paid'] == true,
      movie: movie,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'movieId': movie?.toJson() ?? movieId,
      'currentTime': currentTime,
      'expiryDate': expiryDate?.toIso8601String(),
      'startWatch': startWatch,
      'paid': paid,
    };
  }
}
