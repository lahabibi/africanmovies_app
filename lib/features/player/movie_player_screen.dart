import 'package:flutter/material.dart';

import 'domain/movie_playback.dart';
import 'trailer_player_screen.dart';

class MoviePlayerScreen extends StatelessWidget {
  final MoviePlayback playback;

  const MoviePlayerScreen({super.key, required this.playback});

  @override
  Widget build(BuildContext context) {
    return TrailerPlayerScreen(
      title: playback.title,
      videoUrl: playback.playbackUrl,
      badgeLabel: 'MOVIE',
      loadingLabel: 'Preparing your movie...',
      unavailableTitle: 'Movie unavailable',
      fallbackErrorMessage: 'Could not start this movie. Please try again.',
      initialPosition: playback.startPosition,
    );
  }
}
