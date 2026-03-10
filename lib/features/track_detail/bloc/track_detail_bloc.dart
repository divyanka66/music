import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/api/tracks_api.dart';
import '../../../data/models/lyrics.dart';
import '../../../data/models/track_detail.dart';
import '../../../data/repository/tracks_repository.dart';

part 'track_detail_event.dart';
part 'track_detail_state.dart';

class TrackDetailBloc extends Bloc<TrackDetailEvent, TrackDetailState> {
  TrackDetailBloc({TracksRepository? repository})
      : _repository = repository ?? TracksRepository(),
        super(const TrackDetailInitial()) {
    on<TrackDetailLoad>(_onLoad);
  }

  final TracksRepository _repository;

  Future<void> _onLoad(TrackDetailLoad event, Emitter<TrackDetailState> emit) async {
    emit(const TrackDetailLoading());
    try {
      final detailFuture = _repository.getTrackDetail(event.trackId);
      final lyricsFuture = _repository.getTrackLyrics(event.trackId);
      final results = await Future.wait([detailFuture, lyricsFuture]);
      final detail = results[0] as TrackDetail?;
      final lyrics = results[1] as Lyrics?;
      emit(TrackDetailSuccess(
        trackId: event.trackId,
        detail: detail,
        lyrics: lyrics,
      ));
    } on NoInternetException catch (_) {
      emit(const TrackDetailError('NO INTERNET CONNECTION'));
    } catch (e) {
      emit(TrackDetailError(e.toString()));
    }
  }
}
