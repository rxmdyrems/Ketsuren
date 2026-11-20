import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ketsuren/core/innertube/innertube_client.dart';
import 'package:ketsuren/features/music/music_library.dart';
import 'package:ketsuren/features/music/music_track.dart';

void main() {
  group('MusicTrack', () {
    test('round-trips JSON and compares by video id', () {
      const track = MusicTrack(
        id: 'video-1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        thumbnailUrl: 'https://example.test/thumb.jpg',
        durationSeconds: 187,
      );

      expect(MusicTrack.fromJson(track.toJson()), track);
      expect(
        MusicTrack.fromJson({'id': 'video-2'}),
        const MusicTrack(
          id: 'video-2',
          title: 'Unknown track',
          artist: 'Unknown artist',
        ),
      );
      expect(
        track,
        isNot(const MusicTrack(id: 'other', title: 'Song', artist: 'Artist')),
      );
    });
  });

  group('MusicLibrary', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('ketsuren-music-test-');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('stores favorites and de-duplicates recents newest-first', () async {
      const first = MusicTrack(id: 'one', title: 'One', artist: 'A');
      const second = MusicTrack(id: 'two', title: 'Two', artist: 'B');

      await MusicLibrary.instance.toggleFavorite(first);
      expect(await MusicLibrary.instance.isFavorite(first), isTrue);
      expect(await MusicLibrary.instance.favorites(), [first]);

      await MusicLibrary.instance.addRecent(first);
      await MusicLibrary.instance.addRecent(second);
      await MusicLibrary.instance.addRecent(first);
      expect(await MusicLibrary.instance.recents(), [first, second]);

      await MusicLibrary.instance.toggleFavorite(first);
      expect(await MusicLibrary.instance.isFavorite(first), isFalse);
      expect(await MusicLibrary.instance.favorites(), isEmpty);
    });
  });

  group('InnerTubeClient', () {
    test('normalizes queries and parses unique song renderers', () async {
      var getCount = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.method == 'GET') {
                getCount++;
                handler.resolve(
                  Response<String>(
                    requestOptions: options,
                    data:
                        '"INNERTUBE_API_KEY":"api-key",'
                        '"INNERTUBE_CLIENT_VERSION":"1.2.3"',
                  ),
                );
                return;
              }
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  data: {
                    'contents': [
                      _renderer(
                        id: 'video-1',
                        title: '  Track  ',
                        detail: 'Artist • Album • 3:07',
                        thumbnail: 'https://example.test/a.jpg',
                      ),
                      _renderer(
                        id: 'video-1',
                        title: 'Duplicate',
                        detail: 'Artist • 3:07',
                        thumbnail: 'https://example.test/b.jpg',
                      ),
                      _renderer(
                        id: 'video-2',
                        title: 'Second',
                        detail: 'Artist • 1:02:03',
                        thumbnail: 'https://example.test/c.jpg',
                      ),
                    ],
                  },
                ),
              );
            },
          ),
        );
      final client = InnerTubeClient(dio: dio);

      expect(await client.search('   '), isEmpty);
      final tracks = await client.search('  music query  ');

      expect(getCount, 1);
      expect(tracks, hasLength(2));
      expect(tracks.first.id, 'video-1');
      expect(tracks.first.title, 'Track');
      expect(tracks.first.artist, 'Artist');
      expect(tracks.first.album, 'Album');
      expect(tracks.first.durationSeconds, 187);
      expect(tracks.first.thumbnailUrl, 'https://example.test/a.jpg');
      expect(tracks.last.durationSeconds, 3723);
    });
  });
}

Map<String, Object?> _renderer({
  required String id,
  required String title,
  required String detail,
  required String thumbnail,
}) => {
  'musicResponsiveListItemRenderer': {
    'flexColumns': [
      {
        'musicResponsiveListItemFlexColumnRenderer': {
          'text': {
            'runs': [
              {'text': title},
            ],
          },
        },
      },
      {
        'musicResponsiveListItemFlexColumnRenderer': {
          'text': {'simpleText': detail},
        },
      },
    ],
    'playlistItemData': {'videoId': id},
    'thumbnail': {
      'musicThumbnailRenderer': {
        'thumbnail': {
          'thumbnails': [
            {'url': thumbnail},
          ],
        },
      },
    },
  },
};
