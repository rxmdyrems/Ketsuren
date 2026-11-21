import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/audio/music_audio_handler.dart';
import '../../core/innertube/innertube_client.dart';
import '../../core/theme/app_colors.dart';
import 'music_library.dart';
import 'music_player_screen.dart';
import 'music_detail_screen.dart';
import 'music_track.dart';

/// Music-first home/search/library surface shared by phone and Android TV.
class MusicHomeScreen extends StatefulWidget {
  const MusicHomeScreen({
    super.key,
    this.searchMode = false,
    this.libraryMode = false,
    this.downloadsMode = false,
  });

  final bool searchMode;
  final bool libraryMode;
  final bool downloadsMode;

  @override
  State<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends State<MusicHomeScreen> {
  final _client = InnerTubeClient();
  final _queryController = TextEditingController();
  List<MusicTrack> _tracks = const [];
  bool _loading = false;
  String? _error;
  int _libraryTab = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.searchMode && !widget.libraryMode) {
      unawaited(_search('trending music'));
    }
    unawaited(
      MusicPlayback.init()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tracks = await _client.search(query);
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _loading = false;
        if (tracks.isEmpty) _error = 'No songs found. Try another search.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Music search is unavailable right now.';
      });
      debugPrint('Ketsuren music search failed: $error');
    }
  }

  Future<void> _favorite(MusicTrack track) async {
    await MusicLibrary.instance.toggleFavorite(track);
    if (mounted) setState(() {});
  }

  Future<void> _enqueue(MusicTrack track) async {
    try {
      await MusicPlayback.addToQueue(track);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added “${track.title}” to the queue.')),
        );
      }
    } on Object catch (error) {
      debugPrint('Ketsuren queue update failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.downloadsMode
        ? 'Offline music'
        : widget.libraryMode
        ? 'Your library'
        : widget.searchMode
        ? 'Search music'
        : 'Music';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icon/logo_mark.png',
                    width: 42,
                    height: 42,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.music_note_rounded,
                      color: AppColors.accent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!widget.libraryMode)
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () =>
                          FocusScope.of(context).requestFocus(_searchFocusNode),
                      icon: const Icon(Icons.search_rounded),
                      color: AppColors.textPrimary,
                    ),
                ],
              ),
            ),
            if (!widget.libraryMode && !widget.downloadsMode) _searchField(),
            Expanded(
              child: widget.downloadsMode
                  ? _downloadsContent()
                  : widget.libraryMode
                  ? _libraryContent()
                  : _musicContent(),
            ),
            _miniPlayer(),
            const SizedBox(height: 112),
          ],
        ),
      ),
    );
  }

  final FocusNode _searchFocusNode = FocusNode();

  Widget _searchField() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
    child: TextField(
      controller: _queryController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: _search,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Songs, artists, albums',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: IconButton(
          tooltip: 'Search',
          onPressed: () => _search(_queryController.text),
          icon: Icon(Icons.arrow_forward_rounded, color: AppColors.accent),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _musicContent() {
    if (widget.searchMode && _tracks.isEmpty && !_loading && _error == null) {
      return const Center(
        child: Text(
          'Search YouTube Music to find songs.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        if (!widget.searchMode) _hero(),
        if (!widget.searchMode) ...[
          const SizedBox(height: 22),
          _sectionTitle('Trending music'),
        ],
        if (_loading)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ..._tracks.map((track) => _trackRow(track)),
      ],
    );
  }

  Widget _hero() => Container(
    height: 150,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: [AppColors.accent.withValues(alpha: 0.75), AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Listen without limits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Search and stream music. No account required.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.86)),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _trackRow(MusicTrack track) => FutureBuilder<bool>(
    future: MusicLibrary.instance.isFavorite(track),
    builder: (context, snapshot) {
      final liked = snapshot.data ?? false;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 54,
            height: 54,
            child: track.thumbnailUrl == null
                ? ColoredBox(
                    color: AppColors.surface,
                    child: Icon(
                      Icons.music_note_rounded,
                      color: AppColors.accent,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: track.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => ColoredBox(color: AppColors.surface),
                    errorWidget: (_, _, _) => ColoredBox(
                      color: AppColors.surface,
                      child: Icon(
                        Icons.music_note_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: Text(
          [
            track.artist,
            if (track.durationSeconds != null)
              _duration(track.durationSeconds!),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: liked ? 'Remove from favourites' : 'Add to favourites',
              onPressed: () => _favorite(track),
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Track actions',
              onSelected: (value) {
                if (value == 'queue') _enqueue(track);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'queue', child: Text('Add to queue')),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MusicDetailScreen(track: track),
          ),
        ),
      );
    },
  );

  Widget _libraryContent() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Liked songs')),
            ButtonSegment(value: 1, label: Text('Recently played')),
          ],
          selected: {_libraryTab},
          onSelectionChanged: (selection) =>
              setState(() => _libraryTab = selection.first),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: FutureBuilder<List<MusicTrack>>(
          future: _libraryTab == 0
              ? MusicLibrary.instance.favorites()
              : MusicLibrary.instance.recents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }
            final tracks = snapshot.data!;
            if (tracks.isEmpty) {
              return Center(
                child: Text(
                  _libraryTab == 0
                      ? 'Your liked songs will appear here.'
                      : 'Songs you play will appear here.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: tracks.map(_trackRow).toList(),
            );
          },
        ),
      ),
    ],
  );

  Widget _downloadsContent() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'Offline audio downloads are not available yet. Streaming remains available while online.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    ),
  );

  Widget _miniPlayer() {
    final handler = MusicPlayback.handler;
    if (handler == null) return const SizedBox.shrink();
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.hairline),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MusicPlayerScreen(),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      Text(
                        item.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  builder: (context, state) => IconButton(
                    onPressed: () => state.data?.playing == true
                        ? handler.pause()
                        : handler.play(),
                    icon: Icon(
                      state.data?.playing == true
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _duration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }
}
