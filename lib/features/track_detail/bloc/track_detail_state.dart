part of 'track_detail_bloc.dart';

sealed class TrackDetailState extends Equatable {
  const TrackDetailState();

  @override
  List<Object?> get props => [];
}

class TrackDetailInitial extends TrackDetailState {
  const TrackDetailInitial();
}

class TrackDetailLoading extends TrackDetailState {
  const TrackDetailLoading();
}

class TrackDetailSuccess extends TrackDetailState {
  const TrackDetailSuccess({
    required this.trackId,
    this.detail,
    this.lyrics,
  });
  final int trackId;
  final TrackDetail? detail;
  final Lyrics? lyrics;

  @override
  List<Object?> get props => [trackId, detail, lyrics];
}

class TrackDetailError extends TrackDetailState {
  const TrackDetailError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
