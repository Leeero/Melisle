import 'dart:ui' as ui;

import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/artwork_hover_overlay.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_album_cards.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('album grid hover uses artwork overlay without card wash', (
    tester,
  ) async {
    tester.view.physicalSize = const ui.Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final resolver = CustomMediaSourceResolver();
    final settingsCubit = AppSettingsCubit(_SettingsRepository(), resolver);
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      RepositoryProvider<CustomMediaSourceResolver>.value(
        value: resolver,
        child: BlocProvider<AppSettingsCubit>.value(
          value: settingsCubit,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 180,
                  height: 250,
                  child: MusicAlbumGridCard(
                    album: const MusicAlbum(
                      id: 'album-1',
                      title: '测试专辑',
                      artistName: '测试歌手',
                      artworkUrl: '',
                      trackCount: 10,
                    ),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final card = find.byType(InkWell);
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(card));
    await tester.pumpAndSettle();

    final overlay = find.byType(ArtworkHoverOverlay);
    expect(tester.widget<ArtworkHoverOverlay>(overlay).visible, isTrue);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(tester.widget<InkWell>(card).hoverColor, Colors.transparent);
    await mouse.removePointer();
  });
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<AppSettingsSnapshot> load() async => const AppSettingsSnapshot();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
