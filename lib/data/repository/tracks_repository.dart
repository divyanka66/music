import 'package:connectivity_plus/connectivity_plus.dart';

import '../api/tracks_api.dart';
import '../models/lyrics.dart';
import '../models/track_detail.dart';
import '../../core/constants.dart';

/// Repository for tracks, details, and lyrics. Handles offline detection.
class TracksRepository {
  TracksRepository({TracksApi? api, Connectivity? connectivity})
      : _api = api ?? TracksApi(),
        _connectivity = connectivity ?? Connectivity();

  final TracksApi _api;
  final Connectivity _connectivity;

  Future<bool> get hasConnection async {
    final result = await _connectivity.checkConnectivity();
    return result.any((c) =>
        c == ConnectivityResult.mobile ||
        c == ConnectivityResult.wifi ||
        c == ConnectivityResult.ethernet);
  }

  /// Fetch a page of tracks. Throws [NoInternetException] when offline.
  Future<TracksResponse> getTracks({
    String q = 'a',
    int index = 0,
    int limit = AppConstants.pageSize,
  }) async {
    final connected = await hasConnection;
    if (!connected) throw NoInternetException();
    return _api.getTracks(q: q, index: index, limit: limit);
  }

  /// Fetch track details. Throws [NoInternetException] when offline.
  Future<TrackDetail?> getTrackDetail(int trackId) async {
    final connected = await hasConnection;
    if (!connected) throw NoInternetException();
    return _api.getTrackDetail(trackId);
  }

  /// Fetch lyrics. Throws [NoInternetException] when offline.
  Future<Lyrics?> getTrackLyrics(int trackId) async {
    final connected = await hasConnection;
    if (!connected) throw NoInternetException();
    return _api.getTrackLyrics(trackId);
  }
}
