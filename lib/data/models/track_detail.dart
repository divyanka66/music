import 'package:equatable/equatable.dart';

/// Track details from details API (API-B).
class TrackDetail extends Equatable {
  const TrackDetail({
    required this.id,
    required this.title,
    required this.artistName,
    this.duration,
    this.albumTitle,
    this.previewUrl,
    this.releaseDate,
    this.link,
  });

  final int id;
  final String title;
  final String artistName;
  final int? duration;
  final String? albumTitle;
  final String? previewUrl;
  final String? releaseDate;
  final String? link;

  factory TrackDetail.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'];
    final artistName = artist is Map
        ? (artist['name'] as String? ?? '')
        : (json['artist_name'] as String? ?? '');
    return TrackDetail(
      id: _parseInt(json['id']),
      title: json['title'] as String? ?? '',
      artistName: artistName,
      duration: json['duration'] != null ? int.tryParse(json['duration'].toString()) : null,
      albumTitle: json['album'] is Map
          ? (json['album']['title'] as String?)
          : (json['album_title'] as String?),
      previewUrl: json['preview'] as String?,
      releaseDate: json['release_date'] as String?,
      link: json['link'] as String?,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [id, title, artistName];
}
