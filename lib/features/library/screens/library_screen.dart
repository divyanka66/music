import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/library_bloc.dart';
import '../../track_detail/bloc/track_detail_bloc.dart';
import '../../track_detail/screens/track_detail_screen.dart';
import '../../../data/models/track.dart';
import '../../../core/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryBloc()..add(const LibraryLoadInitial()),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.97),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              const _SearchBar(),
              Expanded(
                child: BlocConsumer<LibraryBloc, LibraryState>(
                  listenWhen: (a, b) => a.error != b.error,
                  listener: (context, state) {
                    if (state.error != null && state.error!.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error!),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  buildWhen: (a, b) =>
                      a.flattenedItems != b.flattenedItems ||
                      a.isLoading != b.isLoading ||
                      a.isLoadingMore != b.isLoadingMore,
                  builder: (context, state) {
                    if (state.isLoading && state.flattenedItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading your library...',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state.flattenedItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_off_rounded,
                              size: 64,
                              color: AppTheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.error ?? 'No tracks',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return _TrackList(items: state.flattenedItems);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
            ).createShader(bounds),
            child: const Icon(Icons.library_music_rounded, size: 28),
          ),
          const SizedBox(width: 10),
          Text(
            'Music Library',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
          const Spacer(),
          BlocBuilder<LibraryBloc, LibraryState>(
            buildWhen: (a, b) => a.groupByArtist != b.groupByArtist,
            builder: (context, state) {
              return SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Title')),
                  ButtonSegment(value: true, label: Text('Artist')),
                ],
                selected: {state.groupByArtist},
                onSelectionChanged: (v) {
                  context.read<LibraryBloc>().add(
                        LibrarySetGroupBy(byArtist: v.first),
                      );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        decoration: InputDecoration(
          hintText: 'Search tracks or artists...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primary.withValues(alpha: 0.8),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controller.clear();
                    context.read<LibraryBloc>().add(const LibraryClearSearch());
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<LibraryBloc>().add(LibrarySearch(value));
        },
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.items});

  final List<LibraryListItem> items;

  List<Widget> _buildSlivers(BuildContext context) {
    final slivers = <Widget>[];
    List<Track>? currentTracks;
    String? currentLetter;

    for (final item in items) {
      if (item.isHeader) {
        if (currentLetter != null && currentTracks != null) {
          slivers.add(
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                letter: currentLetter,
                child: _SectionHeader(letter: currentLetter),
              ),
            ),
          );
          slivers.add(
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _TrackTile(track: currentTracks![i]),
                childCount: currentTracks.length,
              ),
            ),
          );
        }
        currentLetter = item.headerLetter!;
        currentTracks = [];
      } else {
        currentTracks?.add(item.track!);
      }
    }
    if (currentLetter != null && currentTracks != null) {
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            letter: currentLetter,
            child: _SectionHeader(letter: currentLetter),
          ),
        ),
      );
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _TrackTile(track: currentTracks![i]),
            childCount: currentTracks.length,
          ),
        ),
      );
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            context.read<LibraryBloc>().add(const LibraryLoadMore());
          }
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          ..._buildSlivers(context),
          SliverToBoxAdapter(
            child: BlocBuilder<LibraryBloc, LibraryState>(
              buildWhen: (a, b) =>
                  a.isLoadingMore != b.isLoadingMore ||
                  a.hasReachedEnd != b.hasReachedEnd,
              builder: (context, state) {
                if (state.hasReachedEnd) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                            color: AppTheme.secondary.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You\'ve reached the end',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state.isLoadingMore) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.letter, required this.child});

  final String letter;
  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.25),
            AppTheme.primary.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is _StickyHeaderDelegate &&
        oldDelegate.letter != letter;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        letter,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder<void>(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    BlocProvider(
                  create: (context) => TrackDetailBloc()
                    ..add(TrackDetailLoad(track.id)),
                  child: TrackDetailScreen(trackId: track.id),
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.4),
                        AppTheme.secondary.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${track.artistName} · #${track.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.primary.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
