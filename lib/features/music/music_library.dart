import 'package:hive/hive.dart';

import '../../core/hive/safe_box.dart';
import 'music_track.dart';

/// Anonymous, device-local music data. No account or cloud service is used.
class MusicLibrary {
  MusicLibrary._();

  static final MusicLibrary instance = MusicLibrary._();
  static const String boxName = 'ketsuren_music_library';
  static const String _recentsKey = 'recent_tracks';
  Box<dynamic>? _box;

  Future<Box<dynamic>> _open() async {
    if (_box?.isOpen == true) return _box!;
    _box = Hive.isBoxOpen(boxName)
        ? Hive.box<dynamic>(boxName)
        : await openBoxSafely<dynamic>(boxName);
    return _box!;
  }

  Future<List<MusicTrack>> favorites() async {
    final box = await _open();
    return box.keys
        .whereType<String>()
        .where((key) => key.startsWith('favorite:'))
        .map((key) => _decode(box.get(key)))
        .whereType<MusicTrack>()
        .toList();
  }

  Future<List<MusicTrack>> recents() async {
    final box = await _open();
    final saved = box.get(_recentsKey);
    if (saved is! List) return const [];
    return saved.map(_decode).whereType<MusicTrack>().toList();
  }

  Future<bool> isFavorite(MusicTrack track) async {
    final box = await _open();
    return box.containsKey('favorite:${track.id}');
  }

  Future<void> toggleFavorite(MusicTrack track) async {
    final box = await _open();
    final key = 'favorite:${track.id}';
    if (box.containsKey(key)) {
      await box.delete(key);
    } else {
      await box.put(key, track.toJson());
    }
  }

  Future<void> addRecent(MusicTrack track) async {
    final box = await _open();
    final tracks = List<MusicTrack>.of(await recents());
    tracks.removeWhere((item) => item.id == track.id);
    tracks.insert(0, track);
    await box.put(
      _recentsKey,
      tracks.take(100).map((item) => item.toJson()).toList(),
    );
  }

  MusicTrack? _decode(dynamic value) {
    if (value is! Map) return null;
    try {
      return MusicTrack.fromJson(Map<String, dynamic>.from(value));
    } on Object {
      return null;
    }
  }
}
