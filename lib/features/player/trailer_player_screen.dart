import 'dart:async';

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import 'video_url_resolver.dart';

class TrailerPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String badgeLabel;
  final String loadingLabel;
  final String unavailableTitle;
  final String fallbackErrorMessage;
  final Duration initialPosition;

  const TrailerPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    this.badgeLabel = 'TRAILER',
    this.loadingLabel = 'Preparing your trailer...',
    this.unavailableTitle = 'Trailer unavailable',
    this.fallbackErrorMessage =
        'Could not start this trailer. Please try again.',
    this.initialPosition = Duration.zero,
  });

  @override
  State<TrailerPlayerScreen> createState() => _TrailerPlayerScreenState();
}

class _TrailerPlayerScreenState extends State<TrailerPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  Timer? _controlsTimer;
  Timer? _fatalErrorTimer;

  bool _controlsVisible = true;
  bool _isOpening = true;
  bool _hasPlayableMedia = false;
  bool _orientationWasChanged = false;
  double _lastAudibleVolume = 100;
  String? _pendingErrorMessage;
  String? _fatalErrorMessage;

  @override
  void initState() {
    super.initState();

    _player = Player();
    _controller = VideoController(_player);
    _listenToPlayer();
    _startTrailer();
  }

  void _listenToPlayer() {
    _errorSubscription = _player.stream.error.listen((message) {
      if (!mounted) return;
      _handlePlaybackError(message);
    });

    _completedSubscription = _player.stream.completed.listen((completed) {
      if (!mounted || !completed) return;
      setState(() => _controlsVisible = true);
    });

    _playingSubscription = _player.stream.playing.listen((playing) {
      if (!mounted || !playing) return;
      _markMediaPlayable();
      _scheduleControlsHide();
    });

    _durationSubscription = _player.stream.duration.listen((duration) {
      if (!mounted || duration <= Duration.zero) return;
      _markMediaPlayable();
    });

    _positionSubscription = _player.stream.position.listen((position) {
      if (!mounted || position <= Duration.zero) return;
      _markMediaPlayable();
    });
  }

  Future<void> _startTrailer() async {
    try {
      _isOpening = true;
      _hasPlayableMedia = false;
      _pendingErrorMessage = null;
      _fatalErrorMessage = null;

      final playableUrl = resolvePlayableVideoUrl(widget.videoUrl);
      if (playableUrl.isEmpty) {
        throw StateError('Missing trailer URL.');
      }

      await _prepareAudioOutput();
      await _player.open(Media(playableUrl));
      await _selectDefaultAudioTrack();
      if (widget.initialPosition > Duration.zero) {
        await _player.seek(widget.initialPosition);
      }
      if (_hasPlayableState) _markMediaPlayable();
      _scheduleControlsHide();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _fatalErrorMessage = widget.fallbackErrorMessage;
        _isOpening = false;
        _controlsVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _errorSubscription?.cancel();
    _completedSubscription?.cancel();
    _playingSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _fatalErrorTimer?.cancel();
    _player.dispose();
    if (_orientationWasChanged) {
      unawaited(_enterPortraitMode());
    }
    super.dispose();
  }

  void _toggleControls() {
    if (_fatalErrorMessage != null) return;

    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    if (!_player.state.playing || _fatalErrorMessage != null) return;

    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    if (_controlsVisible) {
      _scheduleControlsHide();
      return;
    }

    setState(() => _controlsVisible = true);
    _scheduleControlsHide();
  }

  Future<void> _togglePlayPause() async {
    _showControls();
    await _player.playOrPause();
  }

  Future<void> _skipBackward10() async {
    await _skipBy(const Duration(seconds: -10));
  }

  Future<void> _skipForward10() async {
    await _skipBy(const Duration(seconds: 10));
  }

  Future<void> _skipBy(Duration offset) async {
    _showControls();

    final duration = _player.state.duration;
    final currentPosition = _player.state.position;
    var targetPosition = currentPosition + offset;

    if (targetPosition < Duration.zero) {
      targetPosition = Duration.zero;
    } else if (duration > Duration.zero && targetPosition > duration) {
      targetPosition = duration;
    }

    await _player.seek(targetPosition);
  }

  Future<void> _seekTo(double milliseconds) async {
    _showControls();
    await _player.seek(Duration(milliseconds: milliseconds.round()));
  }

  Future<void> _setVolume(double volume) async {
    _showControls();

    final nextVolume = volume.clamp(0, 100).toDouble();
    if (nextVolume > 0) _lastAudibleVolume = nextVolume;

    await _player.setVolume(nextVolume);
  }

  Future<void> _toggleMute() async {
    _showControls();

    final currentVolume = _player.state.volume;
    if (currentVolume > 0) {
      _lastAudibleVolume = currentVolume;
      await _player.setVolume(0);
      return;
    }

    await _player.setVolume(_lastAudibleVolume > 0 ? _lastAudibleVolume : 100);
  }

  Future<void> _toggleOrientation() async {
    _showControls();

    _orientationWasChanged = true;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      await _enterPortraitMode();
      return;
    }

    await _enterLandscapeMode();
  }

  Future<void> _handleBack() async {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      _showControls();
      _orientationWasChanged = true;
      await _enterPortraitMode();
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _enterLandscapeMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _enterPortraitMode() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _prepareAudioOutput() async {
    try {
      final session = await audio_session.AudioSession.instance;
      await session.configure(
        const audio_session.AudioSessionConfiguration.music(),
      );
      await session.setActive(true);
    } catch (_) {
      // Unsupported platforms can ignore audio-session setup.
    }

    try {
      await _player.setAudioDevice(AudioDevice.auto());
      _lastAudibleVolume = 100;
      await _player.setVolume(100);
    } catch (_) {
      // Keep video playback available even if the device audio route is absent.
    }
  }

  Future<void> _selectDefaultAudioTrack() async {
    try {
      await _player.setAudioTrack(AudioTrack.auto());
    } catch (_) {
      // Some streams/platforms resolve the automatic track without this call.
    }
  }

  bool get _hasPlayableState {
    return _player.state.playing ||
        _player.state.duration > Duration.zero ||
        _player.state.position > Duration.zero;
  }

  void _markMediaPlayable() {
    _fatalErrorTimer?.cancel();
    _pendingErrorMessage = null;

    if (_hasPlayableMedia && !_isOpening && _fatalErrorMessage == null) {
      return;
    }

    setState(() {
      _hasPlayableMedia = true;
      _isOpening = false;
      _fatalErrorMessage = null;
    });
  }

  void _handlePlaybackError(String message) {
    final normalizedMessage = message.trim();

    if (_isAudioDeviceWarning(normalizedMessage)) return;

    if (_hasPlayableState || _hasPlayableMedia) {
      _markMediaPlayable();
      return;
    }

    _pendingErrorMessage = normalizedMessage.isEmpty
        ? 'Unable to play trailer.'
        : normalizedMessage;

    _fatalErrorTimer?.cancel();
    _fatalErrorTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _hasPlayableState || _hasPlayableMedia) return;

      setState(() {
        _fatalErrorMessage = _friendlyPlaybackError(_pendingErrorMessage);
        _isOpening = false;
        _controlsVisible = true;
      });
    });
  }

  bool _isAudioDeviceWarning(String message) {
    final value = message.toLowerCase();

    return value.contains('audio device') || value.contains('no sound');
  }

  String _friendlyPlaybackError(String? message) {
    final value = message?.toLowerCase() ?? '';

    if (value.contains('403') ||
        value.contains('401') ||
        value.contains('forbidden') ||
        value.contains('unauthorized')) {
      return widget.unavailableTitle == 'Trailer unavailable'
          ? 'This trailer is not available right now.'
          : 'This movie is not available right now.';
    }

    if (value.contains('network') ||
        value.contains('tcp:') ||
        value.contains('http')) {
      return 'Check your connection and try again.';
    }

    return widget.fallbackErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: Video(
                controller: _controller,
                controls: NoVideoControls,
                fit: BoxFit.contain,
                fill: Colors.black,
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _controlsVisible ? 1 : 0,
                  child: _TrailerControlsOverlay(
                    title: widget.title,
                    badgeLabel: widget.badgeLabel,
                    player: _player,
                    isLoading: _isOpening && !_hasPlayableMedia,
                    errorMessage: _fatalErrorMessage,
                    loadingLabel: widget.loadingLabel,
                    unavailableTitle: widget.unavailableTitle,
                    onBack: _handleBack,
                    onPlayPause: _togglePlayPause,
                    onSkipBackward: _skipBackward10,
                    onSkipForward: _skipForward10,
                    onSeek: _seekTo,
                    onVolumeChanged: _setVolume,
                    onMuteTap: _toggleMute,
                    onOrientationToggle: _toggleOrientation,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailerControlsOverlay extends StatelessWidget {
  final String title;
  final String badgeLabel;
  final Player player;
  final bool isLoading;
  final String? errorMessage;
  final String loadingLabel;
  final String unavailableTitle;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onMuteTap;
  final VoidCallback onOrientationToggle;

  const _TrailerControlsOverlay({
    required this.title,
    required this.badgeLabel,
    required this.player,
    required this.isLoading,
    required this.errorMessage,
    required this.loadingLabel,
    required this.unavailableTitle,
    required this.onBack,
    required this.onPlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onMuteTap,
    required this.onOrientationToggle,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _PlayerControlMetrics.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: metrics.screenPadding,
            child: Column(
              children: [
                _TopControls(
                  title: title,
                  badgeLabel: badgeLabel,
                  metrics: metrics,
                  onBack: onBack,
                  onOrientationToggle: onOrientationToggle,
                ),
                const Spacer(),
                _CenterControls(
                  player: player,
                  metrics: metrics,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  loadingLabel: loadingLabel,
                  unavailableTitle: unavailableTitle,
                  onPlayPause: onPlayPause,
                  onSkipBackward: onSkipBackward,
                  onSkipForward: onSkipForward,
                ),
                const Spacer(),
                _VolumeControls(
                  player: player,
                  metrics: metrics,
                  onVolumeChanged: onVolumeChanged,
                  onMuteTap: onMuteTap,
                ),
                SizedBox(height: metrics.bottomControlGap),
                _ProgressControls(
                  player: player,
                  metrics: metrics,
                  onSeek: onSeek,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopControls extends StatelessWidget {
  final String title;
  final String badgeLabel;
  final _PlayerControlMetrics metrics;
  final VoidCallback onBack;
  final VoidCallback onOrientationToggle;

  const _TopControls({
    required this.title,
    required this.badgeLabel,
    required this.metrics,
    required this.onBack,
    required this.onOrientationToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Row(
      children: [
        _CircleControlButton(
          icon: Icons.arrow_back_rounded,
          semanticLabel: 'Back',
          onTap: onBack,
          size: metrics.backButtonSize,
          iconSize: metrics.backIconSize,
        ),
        SizedBox(width: metrics.headerGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: metrics.badgePadding,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: metrics.badgeFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(height: metrics.titleTopGap),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: metrics.titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: metrics.headerGap),
        _AssetControlButton(
          asset: AppAssets.screen,
          semanticLabel: isLandscape
              ? 'Switch to portrait'
              : 'Switch to landscape',
          onTap: onOrientationToggle,
          size: metrics.utilityButtonSize,
          iconSize: metrics.utilityIconSize,
        ),
      ],
    );
  }
}

class _CenterControls extends StatelessWidget {
  final Player player;
  final _PlayerControlMetrics metrics;
  final bool isLoading;
  final String? errorMessage;
  final String loadingLabel;
  final String unavailableTitle;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;

  const _CenterControls({
    required this.player,
    required this.metrics,
    required this.isLoading,
    required this.errorMessage,
    required this.loadingLabel,
    required this.unavailableTitle,
    required this.onPlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _PlayerMessage(
        icon: Icons.error_outline_rounded,
        metrics: metrics,
        title: unavailableTitle,
        subtitle: errorMessage!,
      );
    }

    return StreamBuilder<bool>(
      stream: player.stream.buffering,
      initialData: player.state.buffering,
      builder: (context, bufferingSnapshot) {
        final buffering = bufferingSnapshot.data ?? false;

        if (isLoading || buffering) {
          return _LoadingControl(
            metrics: metrics,
            label: isLoading ? loadingLabel : 'Keeping playback smooth...',
          );
        }

        return StreamBuilder<bool>(
          stream: player.stream.playing,
          initialData: player.state.playing,
          builder: (context, playingSnapshot) {
            final playing = playingSnapshot.data ?? false;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircleControlButton(
                  icon: Icons.replay_10_rounded,
                  semanticLabel: 'Back 10 seconds',
                  onTap: onSkipBackward,
                  size: metrics.skipButtonSize,
                  iconSize: metrics.skipIconSize,
                ),
                SizedBox(width: metrics.centerControlGap),
                _CircleControlButton(
                  icon: playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  semanticLabel: playing ? 'Pause' : 'Play',
                  onTap: onPlayPause,
                  size: metrics.primaryButtonSize,
                  iconSize: metrics.primaryIconSize,
                  color: AppColors.heroButton,
                ),
                SizedBox(width: metrics.centerControlGap),
                _CircleControlButton(
                  icon: Icons.forward_10_rounded,
                  semanticLabel: 'Forward 10 seconds',
                  onTap: onSkipForward,
                  size: metrics.skipButtonSize,
                  iconSize: metrics.skipIconSize,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LoadingControl extends StatelessWidget {
  final _PlayerControlMetrics metrics;
  final String label;

  const _LoadingControl({required this.metrics, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: metrics.loadingPadding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: metrics.loadingSpinnerSize,
            height: metrics.loadingSpinnerSize,
            child: const CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: metrics.loadingGap),
          Text(
            label,
            style: TextStyle(
              fontSize: metrics.loadingFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeControls extends StatelessWidget {
  final Player player;
  final _PlayerControlMetrics metrics;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onMuteTap;

  const _VolumeControls({
    required this.player,
    required this.metrics,
    required this.onVolumeChanged,
    required this.onMuteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: StreamBuilder<double>(
        stream: player.stream.volume,
        initialData: player.state.volume,
        builder: (context, volumeSnapshot) {
          final volume = (volumeSnapshot.data ?? 100).clamp(0, 100).toDouble();
          final muted = volume <= 0;

          return Container(
            padding: metrics.volumePadding,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.44),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircleControlButton(
                  icon: muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  semanticLabel: muted ? 'Unmute' : 'Mute',
                  onTap: onMuteTap,
                  size: metrics.utilityButtonSize,
                  iconSize: metrics.utilityIconSize,
                ),
                SizedBox(width: metrics.volumeGap),
                SizedBox(
                  width: metrics.volumeSliderWidth,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: metrics.volumeTrackHeight,
                      activeTrackColor: AppColors.heroButton,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.24),
                      thumbColor: Colors.white,
                      overlayColor: AppColors.heroButton.withValues(
                        alpha: 0.18,
                      ),
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: metrics.volumeThumbRadius,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: metrics.volumeOverlayRadius,
                      ),
                    ),
                    child: Slider(
                      min: 0,
                      max: 100,
                      value: volume,
                      onChanged: onVolumeChanged,
                    ),
                  ),
                ),
                SizedBox(width: metrics.volumeGap),
                SizedBox(
                  width: metrics.volumeValueWidth,
                  child: Text(
                    '${volume.round()}%',
                    textAlign: TextAlign.right,
                    style: metrics.volumeTextStyle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressControls extends StatelessWidget {
  final Player player;
  final _PlayerControlMetrics metrics;
  final ValueChanged<double> onSeek;

  const _ProgressControls({
    required this.player,
    required this.metrics,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.duration,
      initialData: player.state.duration,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final max = duration.inMilliseconds <= 0
                ? 1.0
                : duration.inMilliseconds.toDouble();
            final value = _sliderValue(position, duration);

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: metrics.sliderTrackHeight,
                    activeTrackColor: AppColors.heroButton,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
                    thumbColor: Colors.white,
                    overlayColor: AppColors.heroButton.withValues(alpha: 0.20),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: metrics.sliderThumbRadius,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: metrics.sliderOverlayRadius,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: max,
                    value: value,
                    onChanged: duration.inMilliseconds <= 0 ? null : onSeek,
                  ),
                ),
                Padding(
                  padding: metrics.timePadding,
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: metrics.timeTextStyle,
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(duration),
                        style: metrics.timeTextStyle,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static double _sliderValue(Duration position, Duration duration) {
    if (duration.inMilliseconds <= 0) return 0;

    final positionMs = position.inMilliseconds;
    final durationMs = duration.inMilliseconds;
    if (positionMs < 0) return 0;
    if (positionMs > durationMs) return durationMs.toDouble();
    return positionMs.toDouble();
  }
}

class _PlayerMessage extends StatelessWidget {
  final IconData icon;
  final _PlayerControlMetrics metrics;
  final String title;
  final String subtitle;

  const _PlayerMessage({
    required this.icon,
    required this.metrics,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: metrics.messageMaxWidth),
      padding: metrics.messagePadding,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: metrics.messageIconSize),
          SizedBox(height: metrics.messageTitleGap),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: metrics.messageTitleFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: metrics.messageSubtitleGap),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: metrics.messageSubtitleFontSize,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleControlButton extends StatelessWidget {
  final IconData icon;
  final String? semanticLabel;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? color;

  const _CircleControlButton({
    required this.icon,
    this.semanticLabel,
    required this.onTap,
    required this.size,
    required this.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.black.withValues(alpha: 0.46),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _AssetControlButton extends StatelessWidget {
  final String asset;
  final String? semanticLabel;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _AssetControlButton({
    required this.asset,
    this.semanticLabel,
    required this.onTap,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.46),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              asset,
              width: iconSize,
              height: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerControlMetrics {
  final EdgeInsets screenPadding;
  final EdgeInsets badgePadding;
  final EdgeInsets loadingPadding;
  final EdgeInsets volumePadding;
  final EdgeInsets timePadding;
  final EdgeInsets messagePadding;
  final double backButtonSize;
  final double backIconSize;
  final double headerGap;
  final double badgeFontSize;
  final double titleTopGap;
  final double titleFontSize;
  final double primaryButtonSize;
  final double primaryIconSize;
  final double skipButtonSize;
  final double skipIconSize;
  final double centerControlGap;
  final double loadingSpinnerSize;
  final double loadingGap;
  final double loadingFontSize;
  final double utilityButtonSize;
  final double utilityIconSize;
  final double volumeGap;
  final double volumeSliderWidth;
  final double volumeTrackHeight;
  final double volumeThumbRadius;
  final double volumeOverlayRadius;
  final double volumeValueWidth;
  final double bottomControlGap;
  final double sliderTrackHeight;
  final double sliderThumbRadius;
  final double sliderOverlayRadius;
  final double messageMaxWidth;
  final double messageIconSize;
  final double messageTitleGap;
  final double messageTitleFontSize;
  final double messageSubtitleGap;
  final double messageSubtitleFontSize;
  final TextStyle volumeTextStyle;
  final TextStyle timeTextStyle;

  const _PlayerControlMetrics({
    required this.screenPadding,
    required this.badgePadding,
    required this.loadingPadding,
    required this.volumePadding,
    required this.timePadding,
    required this.messagePadding,
    required this.backButtonSize,
    required this.backIconSize,
    required this.headerGap,
    required this.badgeFontSize,
    required this.titleTopGap,
    required this.titleFontSize,
    required this.primaryButtonSize,
    required this.primaryIconSize,
    required this.skipButtonSize,
    required this.skipIconSize,
    required this.centerControlGap,
    required this.loadingSpinnerSize,
    required this.loadingGap,
    required this.loadingFontSize,
    required this.utilityButtonSize,
    required this.utilityIconSize,
    required this.volumeGap,
    required this.volumeSliderWidth,
    required this.volumeTrackHeight,
    required this.volumeThumbRadius,
    required this.volumeOverlayRadius,
    required this.volumeValueWidth,
    required this.bottomControlGap,
    required this.sliderTrackHeight,
    required this.sliderThumbRadius,
    required this.sliderOverlayRadius,
    required this.messageMaxWidth,
    required this.messageIconSize,
    required this.messageTitleGap,
    required this.messageTitleFontSize,
    required this.messageSubtitleGap,
    required this.messageSubtitleFontSize,
    required this.volumeTextStyle,
    required this.timeTextStyle,
  });

  factory _PlayerControlMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final isLandscape = size.width > size.height;
    final isTablet = shortestSide >= 600;
    final scale = isTablet ? 1.12 : 1.0;

    double value(double base) => base * scale;

    return _PlayerControlMetrics(
      screenPadding: EdgeInsets.fromLTRB(
        value(isLandscape ? 28 : 16),
        value(isLandscape ? 14 : 12),
        value(isLandscape ? 28 : 16),
        value(isLandscape ? 18 : 18),
      ),
      badgePadding: EdgeInsets.symmetric(
        horizontal: value(8),
        vertical: value(3),
      ),
      loadingPadding: EdgeInsets.symmetric(
        horizontal: value(16),
        vertical: value(12),
      ),
      volumePadding: EdgeInsets.symmetric(
        horizontal: value(8),
        vertical: value(6),
      ),
      timePadding: EdgeInsets.symmetric(horizontal: value(4)),
      messagePadding: EdgeInsets.all(value(16)),
      backButtonSize: value(38),
      backIconSize: value(20),
      headerGap: value(12),
      badgeFontSize: value(8),
      titleTopGap: value(6),
      titleFontSize: value(16),
      primaryButtonSize: value(58),
      primaryIconSize: value(32),
      skipButtonSize: value(42),
      skipIconSize: value(24),
      centerControlGap: value(16),
      loadingSpinnerSize: value(22),
      loadingGap: value(11),
      loadingFontSize: value(12),
      utilityButtonSize: value(32),
      utilityIconSize: value(18),
      volumeGap: value(8),
      volumeSliderWidth: value(isLandscape ? 118 : 96),
      volumeTrackHeight: value(2.5),
      volumeThumbRadius: value(5),
      volumeOverlayRadius: value(13),
      volumeValueWidth: value(36),
      bottomControlGap: value(6),
      sliderTrackHeight: value(3),
      sliderThumbRadius: value(5.5),
      sliderOverlayRadius: value(14),
      messageMaxWidth: value(isLandscape ? 260 : 280),
      messageIconSize: value(28),
      messageTitleGap: value(10),
      messageTitleFontSize: value(15),
      messageSubtitleGap: value(5),
      messageSubtitleFontSize: value(11),
      volumeTextStyle: TextStyle(
        fontSize: value(10),
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.86),
      ),
      timeTextStyle: TextStyle(
        fontSize: value(11),
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.84),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
