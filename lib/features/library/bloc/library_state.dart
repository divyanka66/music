part of 'library_bloc.dart';

/// One item in the virtual list: either a section header or a track.
class LibraryListItem extends Equatable {
  const LibraryListItem._({this.headerLetter, this.track});

  factory LibraryListItem.header(String letter) =>
      LibraryListItem._(headerLetter: letter);

  factory LibraryListItem.track(Track track) =>
      LibraryListItem._(track: track);

  final String? headerLetter;
  final Track? track;

  bool get isHeader => headerLetter != null;
  bool get isTrack => track != null;

  @override
  List<Object?> get props => [headerLetter, track];
}

class LibraryState extends Equatable {
  const LibraryState({
    this.sections = const [],
    this.flattenedItems = const [],
    this.queryCharIndex = 0,
    this.searchQuery,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.error,
    this.groupByArtist = false,
  });

  final List<LibrarySection> sections;
  final List<LibraryListItem> flattenedItems;
  final int queryCharIndex;
  final String? searchQuery;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? error;
  final bool groupByArtist;

  factory LibraryState.initial() => const LibraryState();

  LibraryState copyWith({
    List<LibrarySection>? sections,
    List<LibraryListItem>? flattenedItems,
    int? queryCharIndex,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    Object? error = _keepError,
    bool? groupByArtist,
  }) {
    return LibraryState(
      sections: sections ?? this.sections,
      flattenedItems: flattenedItems ?? this.flattenedItems,
      queryCharIndex: queryCharIndex ?? this.queryCharIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      error: identical(error, _keepError) ? this.error : error as String?,
      groupByArtist: groupByArtist ?? this.groupByArtist,
    );
  }

  @override
  List<Object?> get props => [
        sections,
        flattenedItems,
        queryCharIndex,
        searchQuery,
        isLoading,
        isLoadingMore,
        hasReachedEnd,
        error,
        groupByArtist,
      ];
}
