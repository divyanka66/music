# Music Library – 50k+ Tracks with Virtualization

Flutter music library app that renders 50,000+ tracks with infinite scroll, grouping with sticky headers, search, and a track details + lyrics screen. Uses **BLoC only** and no third-party virtualization packages.

## Requirements Met

- **50k+ tracks**: Paged loading via `/tracks?q=&index=&limit=50`; list is built lazily with `ListView.builder` / `CustomScrollView` + `SliverList`.
- **Infinite scrolling**: Load more when the user scrolls near the end; next page or next query character (a–z, 0–9).
- **Grouping + sticky headers**: Sections by query letter (or by artist when “By Artist” is selected); headers implemented with `SliverPersistentHeader` (pinned).
- **Search + filtering**: Debounced search (400 ms); search does not block the UI.
- **Stable memory**: In-memory list is capped at 4,000 items; when new data is appended, older sections are dropped from the start so memory does not grow unbounded.
- **Screens**: (1) Library – list, search, group toggle; (2) Track details – details (API-B) + lyrics (API-C) with loading / error / success.
- **Offline**: Shows **"NO INTERNET CONNECTION"** when connectivity is missing or requests fail due to network (list fetch and details/lyrics).

## BLoC Flow Summary

### Library BLoC

| Event | Effect |
|-------|--------|
| `LibraryLoadInitial` | Load first page for first query char (e.g. `q=a`, `index=0`). Resets list. |
| `LibraryLoadMore` | Load next page for current query char, or move to next char (b, c, …). Appends to list; may cap and drop old sections. |
| `LibrarySearch(query)` | Debounce 400 ms, then load `q=query`, `index=0`. Replaces list with search results. |
| `LibraryClearSearch` | Clears search and triggers `LibraryLoadInitial`. |
| `LibrarySetGroupBy(byArtist)` | Toggle group by title (query letter) vs artist (first letter of artist name). Rebuilds flattened list from current sections. |

**States (relevant fields):**

- `sections`: List of `LibrarySection` (letter + tracks + nextIndex).
- `flattenedItems`: List of `LibraryListItem` (header or track) for the list UI.
- `isLoading` / `isLoadingMore` / `hasReachedEnd` / `error` / `searchQuery` / `groupByArtist`.

### Track Detail BLoC

| Event | Effect |
|-------|--------|
| `TrackDetailLoad(trackId)` | Check connectivity; fetch details (`GET /track/:id`) and lyrics (`GET /track/:id/lyrics`) in parallel. |

**States:** `TrackDetailInitial` → `TrackDetailLoading` → `TrackDetailSuccess(detail, lyrics)` or `TrackDetailError(message)` (e.g. **"NO INTERNET CONNECTION"**).

## Design Decisions

1. **Lazy build + paging**  
   Only the current “window” of data is kept. We never load all 50k at once. We page by `(q, index)`: first by query character (a, b, …), then by index 0, 50, 100, … within each. The UI uses `CustomScrollView` + `SliverPersistentHeader` + `SliverList` so only visible (and a small buffer of) items are built. This keeps scroll smooth and memory bounded.

2. **Memory cap (4,000 items)**  
   When the user scrolls and we load more, we append new sections. If total list size would exceed 4,000 items, we drop the earliest sections (by section, to keep headers consistent) and rebuild the list. So memory stays stable even with long scrolling and repeated search/scroll.

3. **Search strategy**  
   Search is debounced (400 ms). On submit we call the same `/tracks?q=<query>&index=0&limit=50` and replace the list. “Load more” in search mode requests the next page for the same query. Search runs in the BLoC (async); the UI only reacts to state, so the UI never freezes.

## Issue Faced + Fix

**Issue:** After implementing “load more” and appending sections, memory kept growing because we never removed old data, so scrolling through 50k+ would accumulate tens of thousands of track objects.

**Fix:** Introduced a cap (e.g. 4,000 items). When appending would exceed the cap, we trim from the start: we drop whole sections (header + its tracks) and rebuild both `sections` and `flattenedItems`. Trimming is done in a single place (`_capSectionsAndItems`), so the list and sections stay in sync and memory stays stable.

## What Would Break at 100k (and What to Optimize Next)

- **More API round-trips**: 100k items at 50 per page = 2,000 requests. The current “next page / next query char” strategy would still work but would take longer to “scan” the full set. **Optimization:** Prefetch or background prefetch of next N pages; or a backend endpoint that returns larger chunks or cursor-based keys to reduce round-trips.

- **Rebuild cost when grouping by artist**: With 100k items, toggling “By Artist” would merge all in-memory tracks and regroup by artist first letter. With a 4k cap this is cheap; if we ever increased the cap or kept more in memory, this could get slow. **Optimization:** Keep a precomputed “by artist” structure updated incrementally as we load, or limit in-memory size and keep the cap.

- **Scroll position after cap trim**: When we drop sections from the start, we don’t adjust scroll offset, so the user can “jump” up. **Optimization:** When trimming from the start, estimate the height of removed items and adjust `ScrollController.offset` so the visible content stays in place (or use `ScrollController.jumpTo` / `animateTo` with the new offset).

## API

- **Base URL:** `http://5.78.43.182:5050`
- **List:** `GET /tracks?q=a&index=0&limit=50`
- **Details:** `GET /track/:id` (API-B)
- **Lyrics:** `GET /track/:id/lyrics` (API-C)

If details/lyrics endpoints are not implemented on the server, the app shows “Details not available” / “Lyrics not available” and still shows **"NO INTERNET CONNECTION"** when offline.

## Run

```bash
flutter pub get
flutter run
```

## Demo Checklist

- Smooth scroll with 50k+ list (paged, lazy).
- Grouping + sticky headers (By Title / By Artist).
- Search without UI freeze (debounced).
- Memory evidence (e.g. DevTools; before/after scroll and search).
- Tap a track → Details screen with details + lyrics.
- Offline → **"NO INTERNET CONNECTION"** (at least for details/lyrics; ideally for list as well).

## Code Ownership

- **Minimum 10 meaningful Git commits** – suggested: project setup, models, API, repository, Library BLoC (events/state), Track Detail BLoC, Library screen (list + search + headers), Track Detail screen, memory cap + README.
- **Screen recording** (1–2 min): scrolling, search, memory, and short code walkthrough (BLoC + repository/service).
