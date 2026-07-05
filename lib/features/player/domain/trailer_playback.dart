class TrailerPlayback {
  final String title;
  final String posterUrl;
  final String playbackUrl;

  const TrailerPlayback({
    required this.title,
    required this.posterUrl,
    required this.playbackUrl,
  });

  bool get canPlay => playbackUrl.trim().isNotEmpty;

  factory TrailerPlayback.fromJson(Map<String, dynamic> json) {
    final directUrl = json['playbackUrl']?.toString().trim() ?? '';
    final playbackToken = json['playbackToken']?.toString().trim() ?? '';

    return TrailerPlayback(
      title: json['title']?.toString().trim() ?? '',
      posterUrl: json['poster']?.toString().trim() ?? '',
      playbackUrl: directUrl.isNotEmpty
          ? directUrl
          : playbackToken.isNotEmpty
          ? 'https://videodelivery.net/$playbackToken/manifest/video.m3u8'
          : '',
    );
  }
}
