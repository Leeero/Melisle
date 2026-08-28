import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/music_repository.dart';

/// Tracks the favorite (⭐) status of items the UI has touched.
///
/// The backend (Emby) is still the source of truth — each entity already
/// carries its `isFavorite` flag. This cubit layers an optimistic, locally
/// mutable view on top so that toggling from any surface (album header, mini
/// player, library list, etc.) updates instantly everywhere.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._repository) : super(const FavoritesState.initial());

  final MusicRepository _repository;
  int _sessionRevision = 0;

  void reset() {
    _sessionRevision += 1;
    emit(const FavoritesState.initial());
  }

  /// Seed with the remote-known state of an item (e.g. from a list response).
  void seed(String itemId, bool isFavorite) {
    if (state.entries[itemId] == isFavorite) return;
    final next = Map<String, bool>.from(state.entries)..[itemId] = isFavorite;
    emit(state.copyWith(entries: next));
  }

  /// Seed multiple items at once from a list payload.
  void seedAll(Map<String, bool> map) {
    if (map.isEmpty) return;
    final next = Map<String, bool>.from(state.entries)..addAll(map);
    emit(state.copyWith(entries: next));
  }

  bool isFavorite(String itemId, {bool fallback = false}) {
    return state.entries[itemId] ?? fallback;
  }

  /// Returns whether the server accepted the requested favorite state.
  Future<bool> toggle(String itemId, {required bool currentValue}) async {
    return _toggle(
      itemId,
      currentValue: currentValue,
      updateRemote: () => _repository.setFavorite(itemId, !currentValue),
    );
  }

  Future<bool> togglePlaylist(
    String playlistId, {
    required bool currentValue,
  }) async {
    final repository = _repository;
    if (repository is! PlaylistFavoritesRepository) return false;
    final playlistFavoritesRepository =
        repository as PlaylistFavoritesRepository;
    if (!await playlistFavoritesRepository.supportsPlaylistFavorites()) {
      return false;
    }
    return _toggle(
      playlistId,
      currentValue: currentValue,
      updateRemote: () => playlistFavoritesRepository.setPlaylistFavorite(
        playlistId,
        !currentValue,
      ),
      isPlaylistFavorite: true,
    );
  }

  Future<bool> _toggle(
    String itemId, {
    required bool currentValue,
    required Future<void> Function() updateRemote,
    bool isPlaylistFavorite = false,
  }) async {
    final sessionRevision = _sessionRevision;
    final desired = !currentValue;
    // Optimistic update.
    final next = Map<String, bool>.from(state.entries)..[itemId] = desired;
    emit(state.copyWith(entries: next, pending: {...state.pending, itemId}));
    try {
      await updateRemote();
      if (sessionRevision != _sessionRevision) return false;
      if (isPlaylistFavorite) {
        emit(
          state.copyWith(
            playlistFavoritesRevision: state.playlistFavoritesRevision + 1,
          ),
        );
      }
      return true;
    } catch (_) {
      if (sessionRevision != _sessionRevision) return false;
      // Roll back on failure.
      final rolled = Map<String, bool>.from(state.entries)
        ..[itemId] = currentValue;
      emit(state.copyWith(entries: rolled));
      return false;
    } finally {
      if (sessionRevision == _sessionRevision) {
        final pending = {...state.pending}..remove(itemId);
        emit(state.copyWith(pending: pending));
      }
    }
  }
}

class FavoritesState {
  const FavoritesState({
    required this.entries,
    required this.pending,
    this.playlistFavoritesRevision = 0,
  });

  const FavoritesState.initial()
    : entries = const {},
      pending = const {},
      playlistFavoritesRevision = 0;

  final Map<String, bool> entries;
  final Set<String> pending;
  final int playlistFavoritesRevision;

  FavoritesState copyWith({
    Map<String, bool>? entries,
    Set<String>? pending,
    int? playlistFavoritesRevision,
  }) {
    return FavoritesState(
      entries: entries ?? this.entries,
      pending: pending ?? this.pending,
      playlistFavoritesRevision:
          playlistFavoritesRevision ?? this.playlistFavoritesRevision,
    );
  }
}
