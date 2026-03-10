import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lyrics.dart';
import '../models/track.dart';
import '../models/track_detail.dart';
import '../../core/constants.dart';

/// Thrown when there is no internet or request fails due to network.
class NoInternetException implements Exception {
  NoInternetException([this.message = 'NO INTERNET CONNECTION']);
  final String message;
  @override
  String toString() => message;
}

/// API client for Deezer Track Fetcher and track details/lyrics.
class TracksApi {
  TracksApi({http.Client? client, String baseUrl = AppConstants.baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// GET /tracks?q=&index=&limit=
  Future<TracksResponse> getTracks({
    String q = 'a',
    int index = 0,
    int limit = AppConstants.pageSize,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      path: '/tracks',
      queryParameters: {'q': q, 'index': index.toString(), 'limit': limit.toString()},
    );
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw NoInternetException(),
      );
      if (response.statusCode != 200) {
        throw NoInternetException('Request failed: ${response.statusCode}');
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final list = map['tracks'];
      final tracks = list is List
          ? list
              .map((e) => Track.fromJson(e as Map<String, dynamic>))
              .where((t) => t.id > 0)
              .toList()
          : <Track>[];
      return TracksResponse(
        tracks: tracks,
        query: map['query'] as String? ?? q,
        index: (map['index'] as num?)?.toInt() ?? index,
        limit: (map['limit'] as num?)?.toInt() ?? limit,
      );
    } on http.ClientException catch (_) {
      throw NoInternetException();
    } on NoInternetException {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network')) {
        throw NoInternetException();
      }
      rethrow;
    }
  }

  /// GET /track/:id (details - API-B)
  Future<TrackDetail?> getTrackDetail(int trackId) async {
    final uri = Uri.parse('$_baseUrl/track/$trackId');
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw NoInternetException(),
      );
      if (response.statusCode == 404 || response.statusCode != 200) {
        return null;
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return TrackDetail.fromJson(map);
    } on http.ClientException catch (_) {
      throw NoInternetException();
    } catch (e) {
      if (e is NoInternetException) rethrow;
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network')) {
        throw NoInternetException();
      }
      return null;
    }
  }

  /// GET /track/:id/lyrics (lyrics - API-C)
  Future<Lyrics?> getTrackLyrics(int trackId) async {
    final uri = Uri.parse('$_baseUrl/track/$trackId/lyrics');
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw NoInternetException(),
      );
      if (response.statusCode == 404 || response.statusCode != 200) {
        return null;
      }
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return Lyrics.fromJson(map, trackId: trackId);
    } on http.ClientException catch (_) {
      throw NoInternetException();
    } catch (e) {
      if (e is NoInternetException) rethrow;
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('network')) {
        throw NoInternetException();
      }
      return null;
    }
  }
}

class TracksResponse {
  const TracksResponse({
    required this.tracks,
    required this.query,
    required this.index,
    required this.limit,
  });
  final List<Track> tracks;
  final String query;
  final int index;
  final int limit;
}
