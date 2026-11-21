import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui/poster_palette.dart';
import '../../features/music/music_library.dart';
import '../../features/music/music_player_screen.dart';
import '../../features/music/music_track.dart';

/// Detail page for a music entity — song, album, artist, or playlist.
///
/// Mirrors the existing Anime/Manga/Novel detail page design:
/// artwork background with adaptive colors, info section, action buttons,
/// and a track/episode list below. Reuses [PosterCard]-style layout patterns
/// so Music feels like part of the same app.
class MusicDetailScreen extends StatefulWidget {
  const MusicDetailScreen({super.key, required this.track});

  final MusicTrack track;

  @override
  State<MusicDetailScreen> createState() => _MusicDetailScreenState();
}

class _MusicDetailScreenState extends State<MusicDetailScreen> {
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _refreshLiked();
  }

  Future<void> _refreshLiked() async {
    final liked = await MusicLibrary.instance.isFavorite(widget.track);
    if (mounted) setState(() => _liked = liked);
  }

  Future<void> _toggleLike() async {
    await MusicLibrary.instance.toggleFavorite(widget.track);
    if (mounted) setState(() => _liked = !_liked);
    // Also add to recents.
    await MusicLibrary.instance.addRecent(widget.track);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Artwork background with adaptive dark scrim — same as detail pages.
          if (widget.track.thumbnailUrl != null && widget.track.thumbnailUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                widget.track.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: AppColors.surface),
                loadingBuilder: (_, _, __) => Container(color: AppColors.surface),
              ),
            )
          else
            Positioned.fill(
              child: Container(color: AppColors.surface),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.scrim,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button.
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Artwork + title row.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.track.thumbnailUrl != null &&
                                      widget.track.thumbnailUrl!.isNotEmpty
                                  ? Image.network(
                                      widget.track.thumbnailUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 120,
                                        height: 120,
                                        color: AppColors.surface2,
                                        child: const Icon(
                                            Icons.music_note_rounded,
                                            color: AppColors.accent,
                                            size: 40),
                                      ),
                                    )
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      color: AppColors.surface2,
                                      child: const Icon(
                                          Icons.music_note_rounded,
                                          color: AppColors.accent,
                                          size: 40),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.track.title,
                                    style: AppText.headline.copyWith(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.track.artist,
                                    style: AppText.body.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.track.album != null &&
                                      widget.track.album!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.track.album!,
                                      style: AppText.caption.copyWith(
                                        color: Colors.white.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                  if (widget.track.durationSeconds != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDuration(
                                          widget.track.durationSeconds! * 1000),
                                      style: AppText.caption.copyWith(
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                _liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _liked
                                    ? AppColors.accent
                                    : Colors.white70,
                              ),
                              onPressed: _toggleLike,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Action buttons row.
                        Row(
                          children: [
                            _actionButton(
                              icon: Icons.play_arrow_rounded,
                              label: 'Play',
                              color: Colors.black,
                              onPressed: () async {
                                // Add to recents and start playback.
                                await MusicLibrary.instance.addRecent(widget.track);
                                // Navigate to full-screen player.
                                if (!mounted) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const MusicPlayerScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _actionButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Add to Queue',
                              color: Colors.white.withValues(alpha: 0.9),
                              onPressed: _addToQueue,
                            ),
                            const SizedBox(width: 10),
                            _actionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              color: Colors.white.withValues(alpha: 0.9),
                              onPressed: _shareTrack,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Track info section.
                        const Text(
                          'Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Title', widget.track.title),
                        _infoRow('Artist', widget.track.artist),
                        if (widget.track.album != null &&
                            widget.track.album!.isNotEmpty)
                          _infoRow('Album', widget.track.album!),
                        if (widget.track.durationSeconds != null)
                          _infoRow('Duration', _formatDuration(
                              widget.track.durationSeconds! * 1000)),
                        _infoRow('ID', widget.track.trackIdDisplay),
                        const SizedBox(height: 28),

                        // Recently played / related placeholder.
                        const Text(
                          'Recently Played',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No recent tracks yet. Play some music to see them here.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100), // room for mini-player
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToQueue() async {
    // MusicPlayback.addToQueue is available via the audio handler.
    try {
      await MusicPlayback.init();
      await MusicPlayback.addToQueue(widget.track);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${widget.track.title}" to queue.'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Couldn\'t add to queue.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _shareTrack() async {
    // Placeholder — share via system share sheet when share_plus is wired.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share "${widget.track.title}" — coming soon.'),
          backgroundColor: Colors.white.withValues(alpha: 0.1),
        ),
      );
    }
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }
}

extension _TrackDisplay on MusicTrack {
  String get trackIdDisplay => id.length > 8 ? '${id.substring(0, 8)}…' : id;
}
