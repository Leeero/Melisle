import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/audio_quality.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../infrastructure/media/custom_media_source_resolver.dart';
import 'app_settings_state.dart';

/// Owns the user-facing application settings (theme, default audio quality,
/// custom artwork/lyrics source, gap preferences). Persists via
/// [SettingsRepository].
class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(
    this._repository,
    this._mediaSourceResolver, {
    Future<void> Function()? clearTemporaryCache,
  }) : _clearTemporaryCache = clearTemporaryCache,
       super(const AppSettingsState.initial());

  final SettingsRepository _repository;
  final CustomMediaSourceResolver _mediaSourceResolver;
  final Future<void> Function()? _clearTemporaryCache;

  Future<void> clearCache() async {
    final clear = _clearTemporaryCache;
    if (clear == null) {
      emit(
        state.copyWith(
          feedback: const SettingsFeedback(
            SettingsFeedbackKind.failure,
            '当前缓存服务不可用，请稍后重试。',
          ),
        ),
      );
      return;
    }

    try {
      await clear();
      emit(
        state.copyWith(
          feedback: const SettingsFeedback(
            SettingsFeedbackKind.success,
            '缓存已清理，已下载的离线曲目未受影响。',
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          feedback: const SettingsFeedback(
            SettingsFeedbackKind.failure,
            '清理缓存失败，请稍后重试。',
          ),
        ),
      );
    }
  }

  Future<void> load() async {
    final snap = await _repository.load();
    _mediaSourceResolver.updateSettings(snap);
    emit(
      AppSettingsState(
        themeMode: snap.themeMode,
        defaultQuality: snap.defaultQuality,
        gapBetweenTracks: snap.gapBetweenTracks,
        lyricSyncOffset: snap.lyricSyncOffset,
        menuBarLyricsEnabled: snap.menuBarLyricsEnabled,
        customArtworkSourceEnabled: snap.customArtworkSourceEnabled,
        customArtworkSourceUrl: snap.customArtworkSourceUrl,
        customLyricsSourceEnabled: snap.customLyricsSourceEnabled,
        customLyricsSourceUrl: snap.customLyricsSourceUrl,
        isLoading: false,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _repository.saveThemeMode(mode);
  }

  Future<void> setDefaultQuality(AudioQuality quality) async {
    emit(state.copyWith(defaultQuality: quality));
    await _repository.saveDefaultQuality(quality);
  }

  Future<void> setGapBetweenTracks(Duration gap) async {
    emit(state.copyWith(gapBetweenTracks: gap));
    await _repository.saveGapBetweenTracks(gap);
  }

  Future<void> setLyricSyncOffset(Duration offset) async {
    emit(state.copyWith(lyricSyncOffset: offset));
    await _repository.saveLyricSyncOffset(offset);
  }

  Future<void> setMenuBarLyricsEnabled(bool enabled) async {
    emit(state.copyWith(menuBarLyricsEnabled: enabled));
    await _repository.saveMenuBarLyricsEnabled(enabled);
  }

  Future<void> setCustomArtworkSourceEnabled(bool enabled) async {
    final nextState = state.copyWith(
      customArtworkSourceEnabled: enabled,
      artworkSourceTest: const SourceTestState(),
    );
    _applyMediaSettings(nextState);
    await _repository.saveCustomArtworkSourceEnabled(enabled);
  }

  Future<void> setCustomArtworkSourceUrl(String url) async {
    if (url == state.customArtworkSourceUrl) return;
    final nextState = state.copyWith(
      customArtworkSourceUrl: url,
      artworkSourceTest: const SourceTestState(),
    );
    _applyMediaSettings(nextState);
    await _repository.saveCustomArtworkSourceUrl(url.trim());
  }

  Future<void> setCustomLyricsSourceEnabled(bool enabled) async {
    final nextState = state.copyWith(
      customLyricsSourceEnabled: enabled,
      lyricsSourceTest: const SourceTestState(),
    );
    _applyMediaSettings(nextState);
    await _repository.saveCustomLyricsSourceEnabled(enabled);
  }

  Future<void> setCustomLyricsSourceUrl(String url) async {
    if (url == state.customLyricsSourceUrl) return;
    final nextState = state.copyWith(
      customLyricsSourceUrl: url,
      lyricsSourceTest: const SourceTestState(),
    );
    _applyMediaSettings(nextState);
    await _repository.saveCustomLyricsSourceUrl(url.trim());
  }

  Future<void> saveCustomMediaSources() async {
    try {
      await Future.wait([
        _repository.saveCustomArtworkSourceEnabled(
          state.customArtworkSourceEnabled,
        ),
        _repository.saveCustomArtworkSourceUrl(state.customArtworkSourceUrl),
        _repository.saveCustomLyricsSourceEnabled(
          state.customLyricsSourceEnabled,
        ),
        _repository.saveCustomLyricsSourceUrl(state.customLyricsSourceUrl),
      ]);
      emit(
        state.copyWith(
          feedback: const SettingsFeedback(
            SettingsFeedbackKind.success,
            '自定义媒体来源已保存。',
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          feedback: const SettingsFeedback(
            SettingsFeedbackKind.failure,
            '保存失败，请稍后重试。',
          ),
        ),
      );
    }
  }

  Future<void> testCustomArtworkSource() async {
    final rawAddress = state.customArtworkSourceUrl.trim();
    final validationError = _validateSourceAddress(rawAddress);
    if (validationError != null) {
      emit(
        state.copyWith(
          artworkSourceTest: SourceTestState(
            status: SourceTestStatus.failure,
            message: validationError,
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        artworkSourceTest: const SourceTestState(
          status: SourceTestStatus.testing,
          message: '正在测试封面地址…',
        ),
      ),
    );

    final result = await _mediaSourceResolver.testArtworkSource(rawAddress);
    if (state.customArtworkSourceUrl.trim() != rawAddress) return;

    emit(
      state.copyWith(
        artworkSourceTest: SourceTestState(
          status: result.isSuccess
              ? SourceTestStatus.success
              : SourceTestStatus.failure,
          message: result.message,
          resolvedUrl: result.resolvedUrl,
        ),
      ),
    );
  }

  Future<void> testCustomLyricsSource() async {
    final rawAddress = state.customLyricsSourceUrl.trim();
    final validationError = _validateSourceAddress(rawAddress);
    if (validationError != null) {
      emit(
        state.copyWith(
          lyricsSourceTest: SourceTestState(
            status: SourceTestStatus.failure,
            message: validationError,
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        lyricsSourceTest: const SourceTestState(
          status: SourceTestStatus.testing,
          message: '正在测试歌词地址…',
        ),
      ),
    );

    final result = await _mediaSourceResolver.testLyricsSource(rawAddress);
    if (state.customLyricsSourceUrl.trim() != rawAddress) return;

    emit(
      state.copyWith(
        lyricsSourceTest: SourceTestState(
          status: result.isSuccess
              ? SourceTestStatus.success
              : SourceTestStatus.failure,
          message: result.message,
          resolvedUrl: result.resolvedUrl,
        ),
      ),
    );
  }

  void _applyMediaSettings(AppSettingsState nextState) {
    _mediaSourceResolver.updateSettings(nextState.toSnapshot());
    emit(nextState);
  }

  String? _validateSourceAddress(String value) {
    if (value.isEmpty) {
      return '请先输入自定义地址。';
    }

    final normalized = value.replaceAll(RegExp(r'\{[a-zA-Z0-9_]+\}'), 'sample');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return '请输入合法的 http/https URL。';
    }
    return null;
  }
}
