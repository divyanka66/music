import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/constants.dart';
import '../../../data/api/tracks_api.dart';
import '../../../data/models/track.dart';
import '../../../data/repository/tracks_repository.dart';

part 'library_event.dart';
part 'library_state.dart';

const _keepError = Object();

/// Maximum list items to keep in memory for stable memory usage.
const int _maxListItems = 4000;

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({TracksRepository? repository})
      : _repository = repository ?? TracksRepository(),
        super(LibraryState.initial()) {
    on<LibraryLoadInitial>(_onLoadInitial);
    on<LibraryLoadMore>(_onLoadMore);
    on<LibrarySearch>(_onSearch);
    on<_LibrarySearchSubmitted>(_onSearchSubmitted);
    on<LibraryClearSearch>(_onClearSearch);
    on<LibrarySetGroupBy>(_onSetGroupBy);
  }

  final TracksRepository _repository;
  Timer? _searchDebounce;

  Future<void> _onLoadInitial(
    LibraryLoadInitial event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await _repository.getTracks(
        q: AppConstants.queryChars.first,
        index: 0,
        limit: AppConstants.pageSize,
      );
      final sections = <LibrarySection>[
        LibrarySection(
          letter: AppConstants.queryChars.first.toUpperCase(),
          tracks: response.tracks,
          nextIndex: response.tracks.length < AppConstants.pageSize
              ? null
              : response.index + response.tracks.length,
        ),
      ];
      final items = _buildFlattenedItems(sections, state.groupByArtist);
      emit(state.copyWith(
        isLoading: false,
        sections: sections,
        flattenedItems: items,
        queryCharIndex: 0,
        searchQuery: null,
        error: null,
      ));
    } on NoInternetException catch (_) {
      emit(state.copyWith(
        isLoading: false,
        error: 'NO INTERNET CONNECTION',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMore(
    LibraryLoadMore event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd) return;
    final sections = List<LibrarySection>.from(state.sections);
    if (sections.isEmpty) return;

    emit(state.copyWith(isLoadingMore: true, error: null));
    final last = sections.last;
    final queryCharIndex = state.queryCharIndex;
    final searchQuery = state.searchQuery;

    try {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search mode: next page for same query
        final nextIndex = last.nextIndex ?? 0;
        final response = await _repository.getTracks(
          q: searchQuery,
          index: nextIndex,
          limit: AppConstants.pageSize,
        );
        if (response.tracks.isEmpty) {
          emit(state.copyWith(isLoadingMore: false, hasReachedEnd: true));
          return;
        }
        final updatedLast = LibrarySection(
          letter: last.letter,
          tracks: [...last.tracks, ...response.tracks],
          nextIndex: response.tracks.length < AppConstants.pageSize
              ? null
              : response.index + response.tracks.length,
        );
        sections[sections.length - 1] = updatedLast;
      } else {
        // Browse mode: next page for current char or next char
        if (last.nextIndex != null) {
          final q = AppConstants.queryChars[queryCharIndex];
          final response = await _repository.getTracks(
            q: q,
            index: last.nextIndex!,
            limit: AppConstants.pageSize,
          );
          final updatedLast = LibrarySection(
            letter: last.letter,
            tracks: [...last.tracks, ...response.tracks],
            nextIndex: response.tracks.length < AppConstants.pageSize
                ? null
                : response.index + response.tracks.length,
          );
          sections[sections.length - 1] = updatedLast;
        } else {
          // Move to next query char
          if (queryCharIndex + 1 >= AppConstants.queryChars.length) {
            emit(state.copyWith(isLoadingMore: false, hasReachedEnd: true));
            return;
          }
          final nextChar = AppConstants.queryChars[queryCharIndex + 1];
          final response = await _repository.getTracks(
            q: nextChar,
            index: 0,
            limit: AppConstants.pageSize,
          );
          if (response.tracks.isEmpty &&
              queryCharIndex + 1 >= AppConstants.queryChars.length - 1) {
            emit(state.copyWith(isLoadingMore: false, hasReachedEnd: true));
            return;
          }
          sections.add(LibrarySection(
            letter: nextChar.toUpperCase(),
            tracks: response.tracks,
            nextIndex: response.tracks.length < AppConstants.pageSize
                ? null
                : response.tracks.length,
          ));
          emit(state.copyWith(queryCharIndex: queryCharIndex + 1));
        }
      }

      var items = _buildFlattenedItems(sections, state.groupByArtist);
      if (items.length > _maxListItems) {
        final capped = _capSectionsAndItems(sections, state.groupByArtist, _maxListItems);
        sections.clear();
        sections.addAll(capped.sections);
        items = capped.items;
      }
      emit(state.copyWith(
        isLoadingMore: false,
        sections: sections,
        flattenedItems: items,
        hasReachedEnd: _checkReachedEnd(sections),
      ));
    } on NoInternetException catch (_) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: 'NO INTERNET CONNECTION',
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }

  void _onSearch(LibrarySearch event, Emitter<LibraryState> emit) {
    _searchDebounce?.cancel();
    if (event.query.trim().isEmpty) {
      add(LibraryClearSearch());
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      add(_LibrarySearchSubmitted(event.query.trim()));
    });
  }

  Future<void> _onSearchSubmitted(
    _LibrarySearchSubmitted event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, searchQuery: event.query));
    try {
      final response = await _repository.getTracks(
        q: event.query,
        index: 0,
        limit: AppConstants.pageSize,
      );
      final letter = event.query.isEmpty
          ? '#'
          : event.query.trim().toUpperCase().substring(0, 1);
      final sections = <LibrarySection>[
        LibrarySection(
          letter: letter,
          tracks: response.tracks,
          nextIndex: response.tracks.length >= AppConstants.pageSize
              ? response.tracks.length
              : null,
        ),
      ];
      final items = _buildFlattenedItems(sections, state.groupByArtist);
      emit(state.copyWith(
        isLoading: false,
        sections: sections,
        flattenedItems: items,
        queryCharIndex: 0,
        error: null,
      ));
    } on NoInternetException catch (_) {
      emit(state.copyWith(
        isLoading: false,
        error: 'NO INTERNET CONNECTION',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onClearSearch(LibraryClearSearch event, Emitter<LibraryState> emit) {
    _searchDebounce?.cancel();
    add(const LibraryLoadInitial());
  }

  void _onSetGroupBy(LibrarySetGroupBy event, Emitter<LibraryState> emit) {
    if (event.byArtist == state.groupByArtist) return;
    emit(state.copyWith(groupByArtist: event.byArtist));
    final items = _buildFlattenedItems(state.sections, event.byArtist);
    emit(state.copyWith(flattenedItems: items));
  }

  List<LibraryListItem> _buildFlattenedItems(
      List<LibrarySection> sections, bool byArtist) {
    final toFlatten = byArtist ? _regroupByArtist(sections) : sections;
    return _flatten(toFlatten);
  }

  List<LibrarySection> _regroupByArtist(List<LibrarySection> sections) {
    final allTracks = sections.expand((s) => s.tracks).toList();
    final map = <String, List<Track>>{};
    for (final t in allTracks) {
      final key = t.groupKey(byArtist: true);
      map.putIfAbsent(key, () => []).add(t);
    }
    final keys = map.keys.toList()..sort();
    return keys.map((k) => LibrarySection(letter: k, tracks: map[k]!, nextIndex: null)).toList();
  }

  List<LibraryListItem> _flatten(List<LibrarySection> sections) {
    final result = <LibraryListItem>[];
    for (final section in sections) {
      result.add(LibraryListItem.header(section.letter));
      for (final t in section.tracks) {
        result.add(LibraryListItem.track(t));
      }
    }
    return result;
  }

  /// Cap sections and flattened list to avoid unbounded memory; drop from start.
  _CapResult _capSectionsAndItems(List<LibrarySection> sections, bool byArtist, int maxItems) {
    final items = _buildFlattenedItems(sections, byArtist);
    if (items.length <= maxItems) return _CapResult(sections, items);
    int toDrop = items.length - maxItems;
    final newSections = <LibrarySection>[];
    for (final section in sections) {
      if (toDrop <= 0) {
        newSections.add(section);
        continue;
      }
      final sectionItemCount = 1 + section.tracks.length;
      if (toDrop >= sectionItemCount) {
        toDrop -= sectionItemCount;
        continue;
      }
      if (toDrop > 0) {
        newSections.add(LibrarySection(
          letter: section.letter,
          tracks: section.tracks.sublist(toDrop),
          nextIndex: section.nextIndex,
        ));
        toDrop = 0;
      }
    }
    return _CapResult(newSections, _buildFlattenedItems(newSections, byArtist));
  }

  bool _checkReachedEnd(List<LibrarySection> sections) {
    if (state.searchQuery != null) {
      final last = sections.isNotEmpty ? sections.last : null;
      return last != null && last.nextIndex == null;
    }
    final last = sections.isNotEmpty ? sections.last : null;
    if (last == null || last.nextIndex != null) return false;
    return state.queryCharIndex >= AppConstants.queryChars.length - 1;
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}

/// Internal section for grouping tracks (by query letter or artist letter).
class LibrarySection {
  LibrarySection({
    required this.letter,
    required this.tracks,
    this.nextIndex,
  });
  final String letter;
  final List<Track> tracks;
  final int? nextIndex;
}

class _CapResult {
  _CapResult(this.sections, this.items);
  final List<LibrarySection> sections;
  final List<LibraryListItem> items;
}
