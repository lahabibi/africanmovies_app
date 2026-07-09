import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/player_providers.dart';
import 'domain/movie_playback.dart';
import 'trailer_player_screen.dart';
import 'video_url_resolver.dart';

class MoviePlayerScreen extends ConsumerWidget {
  final MoviePlayback playback;

  const MoviePlayerScreen({super.key, required this.playback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = playback.orderId.trim();

    return TrailerPlayerScreen(
      title: playback.title,
      videoUrl: resolveDashVideoUrl(playback.playbackUrl),
      badgeLabel: 'MOVIE',
      loadingLabel: 'Preparing your movie...',
      bufferingLabel: 'Loading movie...',
      unavailableTitle: 'Movie unavailable',
      fallbackErrorMessage: 'Could not start this movie. Please try again.',
      initialPosition: playback.startPosition,
      expectedDuration: playback.expectedDuration,
      onProgressChanged: orderId.isEmpty
          ? null
          : (position) {
              return ref
                  .read(playerRepositoryProvider)
                  .savePlaybackProgress(orderId: orderId, position: position);
            },
      onPlaybackCompleted: orderId.isEmpty
          ? null
          : (position) {
              return ref
                  .read(playerRepositoryProvider)
                  .completePlayback(orderId: orderId, position: position);
            },
    );
  }
}
