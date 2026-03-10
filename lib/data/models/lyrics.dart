import 'package:equatable/equatable.dart';

/// Lyrics response from lyrics API (API-C).
class Lyrics extends Equatable {
  const Lyrics({required this.trackId, required this.text});

  final int trackId;
  final String text;

  factory Lyrics.fromJson(Map<String, dynamic> json, {required int trackId}) {
    final text = json['lyrics'] as String? ??
        json['text'] as String? ??
        json['content'] as String? ??
        '';
    return Lyrics(trackId: trackId, text: text);
  }

  @override
  List<Object?> get props => [trackId, text];
}
