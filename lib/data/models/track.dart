import 'package:equatable/equatable.dart';

/// Track model from /tracks API.
class Track extends Equatable {
  const Track({
    required this.id,
    required this.title,
    required this.artistName,
    this.duration,
    this.albumTitle,
    this.previewUrl,
  });

  final int id;
  final String title;
  final String artistName;
  final int? duration;
  final String? albumTitle;
  final String? previewUrl;

  factory Track.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'];
    final artistName = artist is Map
        ? (artist['name'] as String? ?? '')
        : (json['artist_name'] as String? ?? '');
    return Track(
      id: _parseInt(json['id']),
      title: json['title'] as String? ?? '',
      artistName: artistName,
      duration: _parseInt(json['duration']),
      albumTitle: json['album'] is Map
          ? (json['album']['title'] as String?)
          : (json['album_title'] as String?),
      previewUrl: json['preview'] as String?,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// First character for grouping (by title or artist).
  String groupKey({bool byArtist = false}) {
    final s = (byArtist ? artistName : title).trim().toUpperCase();
    if (s.isEmpty) return '#';
    final c = s[0];
    return (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ||
            (c.compareTo('0') >= 0 && c.compareTo('9') <= 0)
        ? c
        : '#';
  }

  @override
  List<Object?> get props => [id, title, artistName];
}
