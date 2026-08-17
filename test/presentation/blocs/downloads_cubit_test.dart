import 'dart:io';

import 'package:cross_platform_music_player/domain/entities/audio_quality.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/infrastructure/cache/audio_cache_manager.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_state.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('load removes stale downloads and partial files', () async {
    final tempDir = await Directory.systemTemp.createTemp('melisle-downloads-');
    addTearDown(() => tempDir.delete(recursive: true));

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final validFile = File(p.join(tempDir.path, 'valid.mp3'));
    await validFile.writeAsBytes(List<int>.filled(128, 1));
    final partialFile = File(p.join(tempDir.path, 'stale.mp3.part'));
    await partialFile.writeAsBytes(List<int>.filled(32, 1));

    await database.upsertDownload(
      DownloadsCompanion.insert(
        trackId: 'valid',
        filePath: validFile.path,
        fileSize: const Value(999),
        title: 'Valid Track',
        downloadedAtMs: 2,
        status: const Value(0),
      ),
    );
    await database.upsertDownload(
      DownloadsCompanion.insert(
        trackId: 'missing',
        filePath: p.join(tempDir.path, 'missing.mp3'),
        fileSize: const Value(2048),
        title: 'Missing Track',
        downloadedAtMs: 1,
        status: const Value(0),
      ),
    );

    final cubit = DownloadsCubit(
      repository: _FakeMusicRepository(),
      database: database,
      cacheManager: AudioCacheManager(defaultDirectory: () async => tempDir),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.completedTrackIds, {'valid'});
    expect(cubit.state.cachedBytes, 128);
    expect(cubit.state.removedStaleRecords, 0);
    expect(cubit.state.removedPartialFiles, 1);
    expect(await partialFile.exists(), isFalse);
    expect(cubit.state.missingTrackIds, {'missing'});
    expect(await database.findDownload('missing'), isNotNull);
    expect((await database.findDownload('valid'))?.fileSize, 128);
  });

  test(
    'custom directory must exist and be writable before it is saved',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'melisle-downloads-',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final cubit = DownloadsCubit(
        repository: _FakeMusicRepository(),
        database: database,
        cacheManager: AudioCacheManager(defaultDirectory: () async => tempDir),
      );
      addTearDown(cubit.close);

      await expectLater(
        cubit.setDownloadDirectoryPath(p.join(tempDir.path, 'missing')),
        throwsArgumentError,
      );

      expect(
        cubit.state.directoryValidation,
        DownloadDirectoryValidation.invalid,
      );
      expect(cubit.state.directoryValidationMessage, '目录不存在');
    },
  );
}

class _FakeMusicRepository extends Fake implements MusicRepository {
  @override
  Future<String> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.auto,
  }) async {
    return 'https://example.com/$trackId';
  }
}
