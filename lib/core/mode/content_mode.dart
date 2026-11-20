import 'package:flutter/material.dart';
import 'package:zangetsu_source_bridge/zangetsu_source_bridge.dart';

import '../mangayomi/mangayomi_source_id.dart';
import '../models/provider_info.dart';

/// The app-wide content mode. Music is primary; the existing video, manga,
/// and novel modes remain available as secondary experiences.
enum ContentMode { anime, manga, novel, music }

bool sourceIdMatchesContentMode(String sourceId, ContentMode mode) {
  final mangayomiType = mangayomiContentTypeOf(sourceId);
  if (mangayomiType != null) {
    return switch (mode) {
      ContentMode.anime => mangayomiType == MangayomiContentType.video,
      ContentMode.manga => mangayomiType == MangayomiContentType.manga,
      ContentMode.novel => mangayomiType == MangayomiContentType.novel,
      ContentMode.music => false,
    };
  }
  return switch (mode) {
    ContentMode.anime =>
      !sourceId.startsWith('mihon:') && !sourceId.startsWith('lnr:'),
    ContentMode.manga => sourceId.startsWith('mihon:'),
    ContentMode.novel => sourceId.startsWith('lnr:'),
    ContentMode.music => false,
  };
}

extension ContentModeX on ContentMode {
  String get label => switch (this) {
    // "Streaming", not "Anime": this mode covers all video — anime, movies and
    // series — so the switcher/history read "Streaming" rather than the narrower
    // "Anime". (The enum value stays `anime` — only the user-facing label moved.)
    ContentMode.anime => 'Streaming',
    ContentMode.manga => 'Manga',
    ContentMode.novel => 'Novel',
    ContentMode.music => 'Music',
  };

  IconData get icon => switch (this) {
    ContentMode.anime => Icons.play_circle_outline_rounded,
    ContentMode.manga => Icons.auto_stories_outlined,
    ContentMode.novel => Icons.menu_book_outlined,
    ContentMode.music => Icons.music_note_rounded,
  };

  bool get isReading => this == ContentMode.manga || this == ContentMode.novel;

  /// Which provider types belong to this mode. Anime mode keeps both video
  /// types so today's mixed anime/movie source list is unchanged.
  bool matchesProvider(ProviderType t) => switch (this) {
    ContentMode.anime => t == ProviderType.anime || t == ProviderType.movie,
    ContentMode.manga => t == ProviderType.manga,
    ContentMode.novel => t == ProviderType.novel,
    ContentMode.music => false,
  };
}

/// Filters a source map to the entries visible in [mode]. In anime mode this
/// is a no-op over an anime/movie-only source set — the hard requirement that
/// today's anime-mode source list never changes.
Map<String, T> filterSourcesForMode<T>(
  Map<String, T> sources,
  ContentMode mode,
  ProviderType Function(T) typeOf,
) => Map.fromEntries(
  sources.entries.where((e) => mode.matchesProvider(typeOf(e.value))),
);
