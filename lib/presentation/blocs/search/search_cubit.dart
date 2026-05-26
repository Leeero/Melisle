import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository, {AppDatabase? database})
    : _database = database,
      super(const SearchState()) {
    _loadRecentQueries();
  }

  final MusicRepository _repository;
  final AppDatabase? _database;
  Timer? _debounce;
  int _requestId = 0;

  /// Called on every keystroke — debounces then hits the backend.
  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _requestId++;
      emit(
        state.copyWith(
          status: SearchStatus.idle,
          query: query,
          results: SearchResults.empty,
          errorMessage: null,
        ),
      );
      return;
    }
    _requestId++;
    emit(
      state.copyWith(
        status: SearchStatus.loading,
        query: query,
        errorMessage: null,
      ),
    );
    _debounce = Timer(const Duration(milliseconds: 320), () => _run(trimmed));
  }

  /// Run immediately — e.g. the user hit the keyboard submit button.
  Future<void> submit(String query) async {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    emit(state.copyWith(query: trimmed));
    await _run(trimmed, persist: true);
  }

  Future<void> retry() async {
    final trimmed = state.query.trim();
    if (trimmed.isEmpty) return;
    await submit(trimmed);
  }

  Future<void> _run(String query, {bool persist = false}) async {
    final id = ++_requestId;
    emit(state.copyWith(status: SearchStatus.loading, errorMessage: null));
    try {
      final results = await _repository.search(query);
      if (id != _requestId) return; // superseded by newer request
      emit(state.copyWith(status: SearchStatus.success, results: results));
      if (persist) {
        await _database?.touchSearchHistory(query);
        await _loadRecentQueries();
      }
    } catch (error) {
      if (id != _requestId) return;
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: '搜索失败：$error',
        ),
      );
    }
  }

  Future<void> clearRecent() async {
    await _database?.clearSearchHistory();
    emit(state.copyWith(recentQueries: const []));
  }

  Future<void> _loadRecentQueries() async {
    final db = _database;
    if (db == null) return;
    try {
      final rows = await db.recentSearches(limit: 10);
      emit(state.copyWith(recentQueries: [for (final r in rows) r.query]));
    } catch (_) {
      /* ignore */
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
