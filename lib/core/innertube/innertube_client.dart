import 'package:dio/dio.dart';

import '../../features/music/music_track.dart';

/// Small anonymous InnerTube client for public YouTube Music search results.
/// The web client's API key and client version are discovered at runtime so a
/// stale embedded key does not break search after a site rollout.
class InnerTubeClient {
  InnerTubeClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  String? _apiKey;
  String? _clientVersion;
  Future<void>? _bootstrap;

  Future<void> _ensureClient() => _bootstrap ??= _loadClient();

  Future<void> _loadClient() async {
    final response = await _dio.get<String>('https://music.youtube.com/');
    final html = response.data ?? '';
    _apiKey = _capture(html, RegExp(r'"INNERTUBE_API_KEY"\s*:\s*"([^"]+)"'));
    _clientVersion = _capture(
      html,
      RegExp(r'"INNERTUBE_CLIENT_VERSION"\s*:\s*"([^"]+)"'),
    );
    if (_apiKey == null || _clientVersion == null) {
      throw const FormatException('YouTube Music client config was not found');
    }
  }

  String? _capture(String text, RegExp pattern) =>
      pattern.firstMatch(text)?.group(1);

  Future<List<MusicTrack>> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];
    await _ensureClient();
    final response = await _dio.post<Map<String, dynamic>>(
      'https://music.youtube.com/youtubei/v1/search',
      queryParameters: {'key': _apiKey, 'prettyPrint': 'false'},
      options: Options(
        headers: const {
          'Content-Type': 'application/json',
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/',
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        },
      ),
      data: {
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': _clientVersion,
            'hl': 'en',
            'gl': 'US',
          },
        },
        'query': normalized,
      },
    );
    final root = response.data;
    if (root == null) return const [];
    final results = <MusicTrack>[];
    final seen = <String>{};
    void visit(dynamic node) {
      if (node is Map) {
        final renderer = node['musicResponsiveListItemRenderer'];
        if (renderer is Map) {
          final track = _trackFromRenderer(Map<String, dynamic>.from(renderer));
          if (track != null && seen.add(track.id)) results.add(track);
        }
        for (final value in node.values) {
          visit(value);
        }
      } else if (node is List) {
        for (final value in node) {
          visit(value);
        }
      }
    }

    visit(root);
    return results;
  }

  MusicTrack? _trackFromRenderer(Map<String, dynamic> renderer) {
    final flex = renderer['flexColumns'];
    if (flex is! List || flex.isEmpty) return null;
    String textAt(int index) {
      if (index >= flex.length) return '';
      final column = flex[index];
      if (column is! Map) return '';
      final flexRenderer = column['musicResponsiveListItemFlexColumnRenderer'];
      if (flexRenderer is! Map) return '';
      final text = flexRenderer['text'];
      if (text is! Map) return '';
      final runs = text['runs'];
      if (runs is List) {
        return runs
            .whereType<Map>()
            .map((run) => run['text']?.toString() ?? '')
            .join();
      }
      return text['simpleText']?.toString() ?? '';
    }

    final title = textAt(0).trim();
    if (title.isEmpty) return null;
    final id = _findVideoId(renderer);
    if (id == null || id.isEmpty) return null;
    final details = textAt(1).split('•').map((part) => part.trim()).toList();
    final artist = details.isEmpty || details.first.isEmpty
        ? 'YouTube Music'
        : details.first;
    final duration = _parseDuration(details);
    final thumbnail = _findThumbnail(renderer);
    return MusicTrack(
      id: id,
      title: title,
      artist: artist,
      album: details.length > 1 ? details[1] : null,
      thumbnailUrl: thumbnail,
      durationSeconds: duration,
    );
  }

  String? _findVideoId(dynamic node) {
    if (node is Map) {
      final direct = node['videoId'];
      if (direct is String && direct.isNotEmpty) return direct;
      for (final value in node.values) {
        final found = _findVideoId(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final value in node) {
        final found = _findVideoId(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _findThumbnail(dynamic node) {
    if (node is Map) {
      final thumbnails = node['thumbnails'];
      if (thumbnails is List && thumbnails.isNotEmpty) {
        final first = thumbnails.last;
        if (first is Map && first['url'] is String) {
          return first['url'] as String;
        }
      }
      for (final value in node.values) {
        final found = _findThumbnail(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final value in node) {
        final found = _findThumbnail(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  int? _parseDuration(List<String> labels) {
    for (final label in labels.reversed) {
      final parts = label.split(':');
      if (parts.length < 2 || parts.any((part) => int.tryParse(part) == null)) {
        continue;
      }
      return parts.map(int.parse).reduce((value, part) => value * 60 + part);
    }
    return null;
  }
}
