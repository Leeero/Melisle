import 'package:cross_platform_music_player/presentation/widgets/loading_play_pause_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading feedback while playback is buffering', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingPlayPauseButton(
            isLoading: true,
            isPlaying: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('正在准备播放'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });
}
