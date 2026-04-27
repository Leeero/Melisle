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

  Future<void> toggle(String itemId, {required bool currentValue}) async {
    final desired = !currentValue;
    // Optimistic update.
    final next = Map<String, bool>.from(state.entries)..[itemId] = desired;
    emit(state.copyWith(entries: next, pending: {...state.pending, itemId}));
    try {
      await _repository.setFavorite(itemId, desired);
    } catch (_) {
      // Roll back on failure.
      final rolled = Map<String, bool>.from(state.entries)
        ..[itemId] = currentValue;
      emit(state.copyWith(entries: rolled));
    } finally {
      final pending = {...state.pending}..remove(itemId);
      emit(state.copyWith(pending: pending));
    }
  }
}

class FavoritesState {
  const FavoritesState({required this.entries, required this.pending});

  const FavoritesState.initial()
    : entries = const {},
      pending = const {};

  final Map<String, bool> entries;
  final Set<String> pending;

  FavoritesState copyWith({
    Map<String, bool>? entries,
    Set<String>? pending,
  }) {
    return FavoritesState(
      entries: entries ?? this.entries,
      pending: pending ?? this.pending,
    );
  }
}
