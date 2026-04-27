import 'package:cross_platform_music_player/domain/entities/search_results.dart';

enum SearchStatus { idle, loading, success, failure }

class SearchState {
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results = SearchResults.empty,
    this.recentQueries = const [],
    this.errorMessage,
  });

  final SearchStatus status;
  final String query;
  final SearchResults results;
  final List<String> recentQueries;
  final String? errorMessage;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    SearchResults? results,
    List<String>? recentQueries,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      recentQueries: recentQueries ?? this.recentQueries,
      errorMessage: errorMessage,
    );
  }
}
