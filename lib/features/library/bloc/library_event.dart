part of 'library_bloc.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Load first page (and first query char when not searching).
class LibraryLoadInitial extends LibraryEvent {
  const LibraryLoadInitial();
}

/// Load more when user scrolls to end.
class LibraryLoadMore extends LibraryEvent {
  const LibraryLoadMore();
}

/// User typed in search; debounced then triggers fetch.
class LibrarySearch extends LibraryEvent {
  const LibrarySearch(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Internal event after debounce to perform search fetch.
class _LibrarySearchSubmitted extends LibraryEvent {
  const _LibrarySearchSubmitted(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Clear search and reload browse mode.
class LibraryClearSearch extends LibraryEvent {
  const LibraryClearSearch();
}

/// Toggle grouping by track name vs artist.
class LibrarySetGroupBy extends LibraryEvent {
  const LibrarySetGroupBy({required this.byArtist});
  final bool byArtist;

  @override
  List<Object?> get props => [byArtist];
}
