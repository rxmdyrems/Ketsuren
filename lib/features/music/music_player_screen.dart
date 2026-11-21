import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/audio/music_audio_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../features/music/music_library.dart';
import '../../features/music/music_track.dart';

/// Full-screen music player — expanded from the mini-player on [MusicHomeScreen].
///
/// Mirrors the existing video player's design language: adaptive artwork
/// background, playback controls, queue, shuffle/repeat, like, and lyrics
/// placeholder. Uses [MusicAudioHandler] / [MusicPlayback] for playback.
class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  StreamSubscription<MediaItem?>? _itemSub;
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<double>? _positionSub;
  StreamSubscription<double>? _bufferedSub;

  MediaItem? _item;
  PlaybackState? _state;
  double _position = 0;
  double _buffered = 0;
  bool _shuffle = false;
  int _repeatMode = 0; // 0=off, 1=one, 2=all
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _item = MusicPlayback.handler?.mediaItem.value;
    _state = MusicPlayback.handler?.playbackState.value;
    _position = _state?.position.inMilliseconds.toDouble() ?? 0;
    _buffered = _state?.bufferedPosition.inMilliseconds.toDouble() ?? 0;
    _loadLiked();

    final handler = MusicPlayback.handler;
    if (handler != null) {
      _itemSub = handler.mediaItem.listen((item) {
        if (!mounted) return;
        setState(() {
          _item = item;
        });
        _loadLiked();
      });
      _stateSub = handler.playbackState.listen((s) {
        if (!mounted) return;
        setState(() {
          _state = s;
          _position = s.position.inMilliseconds.toDouble();
          _buffered = s.bufferedPosition.inMilliseconds.toDouble();
        });
      });
    }
  }

  Future<void> _loadLiked() async {
    if (_item == null) return;
    final liked = await MusicLibrary.instance.isFavorite(_trackFromMediaItem(_item!));
    if (mounted) setState(() => _liked = liked);
  }

  @override
  void dispose() {
    _itemSub?.cancel();
    _stateSub?.cancel();
    _positionSub?.cancel();
    _bufferedSub?.cancel();
    super.dispose();
  }

  MusicTrack _trackFromMediaItem(MediaItem item) => MusicTrack(
        id: item.id,
        title: item.title,
        artist: item.artist ?? '',
        album: item.album,
        thumbnailUrl: item.artUri?.toString(),
        durationSeconds: item.duration?.inSeconds,
      );

  @override
  Widget build(BuildContext context) {
    final handler = MusicPlayback.handler;
    final item = _item;
    if (handler == null || item == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Adaptive artwork background — same approach as detail pages.
          if (item.artUri != null)
            Positioned.fill(
              child: CachedNetworkImageWrapper(
                imageUrl: item.artUri!.toString(),
              ),
            ),
          // Scrim so text reads over the artwork.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Close + queue controls.
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded,
                          color: Colors.white),
                      onPressed: _showQueue,
                    ),
                  ],
                ),
                const Spacer(flex: 2),

                // Artwork.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: item.artUri != null
                          ? CachedNetworkImage(
                              imageUrl: item.artUri!.toString(),
                              width: 260,
                              height: 260,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                width: 260,
                                height: 260,
                                color: AppColors.surface,
                              ),
                              errorWidget: (_, _, _) => Container(
                                width: 260,
                                height: 260,
                                color: AppColors.surface,
                                child: Icon(Icons.music_note_rounded,
                                    color: AppColors.accent, size: 64),
                              ),
                            )
                          : Container(
                              width: 260,
                              height: 260,
                              color: AppColors.surface,
                              child: Icon(Icons.music_note_rounded,
                                  color: AppColors.accent, size: 64),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title / artist / album.
                Text(
                  item.title,
                  style: AppText.headline.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item.artist ?? '',
                  style: AppText.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (item.album != null && item.album!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.album!,
                    style: AppText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),

                // Progress bar.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.accent,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.3),
                          thumbColor: AppColors.accent,
                          overlayColor: AppColors.accent.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          min: 0,
                          max: item.duration?.inMilliseconds.toDouble() ?? 1,
                          value: _position.clamp(
                            0,
                            item.duration?.inMilliseconds.toDouble() ?? 1,
                          ),
                          onChanged: (v) => handler.seek(Duration(milliseconds: v.toInt())),
                          onChangeEnd: (_) {},
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position.toInt()),
                            style: AppText.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            _formatDuration(
                              (item.duration?.inMilliseconds ?? 0).toInt(),
                            ),
                            style: AppText.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Playback controls.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shuffle.
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: _shuffle ? AppColors.accent : Colors.white70,
                      ),
                      onPressed: () => setState(() => _shuffle = !_shuffle),
                    ),
                    const SizedBox(width: 12),
                    // Previous.
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 40),
                      onPressed: () => handler.skipToPrevious(),
                    ),
                    const SizedBox(width: 24),
                    // Play / pause.
                    IconButton(
                      icon: Icon(
                        (_state?.playing ?? false)
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                      onPressed: () =>
                          (_state?.playing ?? false)
                              ? handler.pause()
                              : handler.play(),
                    ),
                    const SizedBox(width: 24),
                    // Next.
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 40),
                      onPressed: () => handler.skipToNext(),
                    ),
                    const SizedBox(width: 12),
                    // Repeat.
                    IconButton(
                      icon: Icon(
                        _repeatIcons[_repeatMode],
                        color: _repeatMode == 0
                            ? Colors.white70
                            : AppColors.accent,
                      ),
                      onPressed: _cycleRepeat,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Like + extras row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _liked ? AppColors.accent : Colors.white70,
                      ),
                      onPressed: _toggleLike,
                    ),
                    const SizedBox(width: 28),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded,
                          color: Colors.white70),
                      onPressed: _showQueue,
                    ),
                  ],
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cycleRepeat() {
    setState(() {
      _repeatMode = (_repeatMode + 1) % 3;
    });
    MusicPlayback.handler?.setLoopMode(_repeatMode);
  }

  void _toggleLike() {
    if (_item == null) return;
    final track = _trackFromMediaItem(_item!);
    MusicLibrary.instance.toggleFavorite(track).then((_) {
      if (mounted) setState(() => _liked = !_liked);
    }).catchError((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t toggle favorite.')),
        );
      }
    });
  }

  void _showQueue() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => _QueueSheet(item: _item),
    );
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }
}

/// Cached network image with fallback — used for the background wash.
class CachedNetworkImageWrapper extends StatelessWidget {
  final String imageUrl;
  const CachedNetworkImageWrapper({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppColors.surface),
      errorWidget: (_, _, _) => Container(color: AppColors.surface),
    );
  }
}

final List<IconData> _repeatIcons = [
  Icons.repeat_outlined, // off
  Icons.repeat_one_rounded, // one
  Icons.repeat_rounded, // all
];

/// Queue bottom sheet.
class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.item});

  final MediaItem? item;

  @override
  Widget build(BuildContext context) {
    final handler = MusicPlayback.handler;
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Queue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<MediaItem>>(
              stream: handler?.queue ?? Stream.value(const <MediaItem>[]),
              builder: (context, snapshot) {
                final queue = snapshot.data ?? const <MediaItem>[];
                if (queue.isEmpty) {
                  return const Center(
                    child: Text(
                      'Queue is empty.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (_, i) {
                    final item = queue[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: AppColors.surface2,
                          child: item.artUri != null
                              ? CachedNetworkImage(
                                  imageUrl: item.artUri!.toString(),
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.music_note_rounded,
                                  color: AppColors.accent),
                        ),
                      ),
                      title: Text(item.title,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(item.artist ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      trailing: this.item != null && item.id == this.item!.id
                          ? Icon(Icons.radio_button_on_rounded,
                              color: AppColors.accent)
                          : null,
                      onTap: () {
                        // Jump to track — not yet supported by handler API;
                        // would need skipToPrevious/next in a loop.
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
