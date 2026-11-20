class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnailUrl;
  final int? durationSeconds;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': durationSeconds,
  };

  factory MusicTrack.fromJson(Map<String, dynamic> json) => MusicTrack(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Unknown track',
    artist: json['artist'] as String? ?? 'Unknown artist',
    album: json['album'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  );

  @override
  bool operator ==(Object other) => other is MusicTrack && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
