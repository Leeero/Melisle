import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/search_results.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  static const maxQueryLength = 100;
  static const debounceDuration = Duration(milliseconds: 320);

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
    final normalized = _normalizeQuery(query);
    final trimmed = normalized.trim();
    if (trimmed.isEmpty) {
      _requestId++;
      emit(
        state.copyWith(
          status: SearchStatus.idle,
          query: normalized,
          results: SearchResults.empty,
          errorMessage: null,
        ),
      );
      return;
    }
    _requestId++;
    emit(
      state.copyWith(
        status: SearchStatus.input,
        query: normalized,
        results: SearchResults.empty,
        errorMessage: null,
      ),
    );
    _debounce = Timer(debounceDuration, () => _run(trimmed));
  }

  /// Run immediately — e.g. the user hit the keyboard submit button.
  Future<void> submit(String query) async {
    _debounce?.cancel();
    final trimmed = _normalizeQuery(query).trim();
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

  Future<void> removeRecent(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    await _database?.deleteSearchHistory(normalized);
    emit(
      state.copyWith(
        recentQueries: [
          for (final recent in state.recentQueries)
            if (recent != normalized) recent,
        ],
      ),
    );
  }

  Future<void> restoreRecent(List<String> queries) async {
    final normalized = [
      for (final query in queries)
        if (query.trim().isNotEmpty) query.trim(),
    ];
    if (normalized.isEmpty) return;
    final db = _database;
    if (db != null) {
      await db.clearSearchHistory();
      for (final query in normalized.reversed) {
        await db.touchSearchHistory(query);
      }
      await _loadRecentQueries();
      return;
    }
    emit(state.copyWith(recentQueries: normalized));
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

  static String _normalizeQuery(String query) {
    if (query.length <= maxQueryLength) return query;
    return query.substring(0, maxQueryLength);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
