import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../features/music/music_track.dart';

/// Bridges just_audio playback into Android's media session and notification.
/// Search uses InnerTube; stream URLs are resolved with youtube_explode_dart.
class MusicAudioHandler extends BaseAudioHandler with SeekHandler, RepeatModeHandler {
  MusicAudioHandler({AudioPlayer? player, YoutubeExplode? youtube})
    : _player = player ?? AudioPlayer(),
      _youtube = youtube ?? YoutubeExplode() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  final AudioPlayer _player;
  final YoutubeExplode _youtube;
  final List<MusicTrack> _queue = [];
  int _queueIndex = 0;

  Future<void> playTrack(MusicTrack track) async {
    _queue
      ..clear()
      ..add(track);
    _queueIndex = 0;
    await _loadCurrent(autoplay: true);
  }

  Future<void> addToQueue(MusicTrack track) async {
    _queue.add(track);
    queue.add(_queue.map(_mediaItem).toList());
    if (_queue.length == 1) {
      _queueIndex = 0;
      await _loadCurrent(autoplay: true);
    }
  }

  Future<void> _loadCurrent({required bool autoplay}) async {
    if (_queue.isEmpty) return;
    final track = _queue[_queueIndex];
    final item = _mediaItem(track);
    mediaItem.add(item);
    queue.add(_queue.map(_mediaItem).toList());
    final manifest = await _youtube.videos.streams.getManifest(track.id);
    final stream = manifest.audioOnly.withHighestBitrate();
    await _player.setAudioSource(
      AudioSource.uri(stream.url, tag: item),
      preload: true,
    );
    if (autoplay) await _player.play();
  }

  MediaItem _mediaItem(MusicTrack track) => MediaItem(
    id: track.id,
    title: track.title,
    artist: track.artist,
    album: track.album,
    artUri: track.thumbnailUrl == null
        ? null
        : Uri.tryParse(track.thumbnailUrl!),
    duration: track.durationSeconds == null
        ? null
        : Duration(seconds: track.durationSeconds!),
  );

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processing = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processing,
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
        queueIndex: _queue.isEmpty ? null : _queueIndex,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_queueIndex + 1 >= _queue.length) return;
    _queueIndex++;
    await _loadCurrent(autoplay: true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queueIndex == 0) {
      await _player.seek(Duration.zero);
      return;
    }
    _queueIndex--;
    await _loadCurrent(autoplay: true);
  }

  @override
  Future<void> onTaskRemoved() => stop();
}

class MusicPlayback {
  MusicPlayback._();

  static Future<AudioHandler>? _initializing;
  static MusicAudioHandler? _handler;

  static Future<AudioHandler> init() => _initializing ??= AudioService.init(
    builder: () => _handler = MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.rxmdyrems.ketsuren.playback',
      androidNotificationChannelName: 'Ketsurēn playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  static MusicAudioHandler? get handler => _handler;

  static Future<void> play(MusicTrack track) async {
    await init();
    await _handler!.playTrack(track);
  }

  static Future<void> addToQueue(MusicTrack track) async {
    await init();
    await _handler!.addToQueue(track);
  }
}
