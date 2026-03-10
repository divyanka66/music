part of 'track_detail_bloc.dart';

sealed class TrackDetailEvent extends Equatable {
  const TrackDetailEvent();

  @override
  List<Object?> get props => [];
}

class TrackDetailLoad extends TrackDetailEvent {
  const TrackDetailLoad(this.trackId);
  final int trackId;

  @override
  List<Object?> get props => [trackId];
}
