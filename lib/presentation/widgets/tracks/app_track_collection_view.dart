import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/widgets/music/music_track_table.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

typedef AppTrackCollectionItemBuilder =
    Widget Function(
      BuildContext context,
      MusicTrack track,
      int index,
      String? currentTrackId,
    );

class AppTrackCollectionView extends StatelessWidget {
  const AppTrackCollectionView({
    super.key,
    required this.tracks,
    required this.currentTrackId,
    required this.horizontalPadding,
    required this.mobileItemBuilder,
    required this.onTrackTap,
    this.scrollController,
    this.mobileHeader,
    this.desktopTrailingBuilder,
    this.footer,
    this.edgeToEdgeMobileItems = false,
    this.mobileBottomPadding = 24,
  });

  final List<MusicTrack> tracks;
  final String? currentTrackId;
  final double horizontalPadding;
  final ScrollController? scrollController;
  final Widget? mobileHeader;
  final MusicTrackTableTrailingBuilder? desktopTrailingBuilder;
  final AppTrackCollectionItemBuilder mobileItemBuilder;
  final ValueChanged<int> onTrackTap;
  final Widget? footer;
  final bool edgeToEdgeMobileItems;
  final double mobileBottomPadding;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.usesWideContent(context)) {
      return ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          24,
        ),
        children: [
          MusicTrackTable(
            tracks: tracks,
            currentTrackId: currentTrackId,
            showActionBar: false,
            onTrackTap: (index, _) => onTrackTap(index),
            trailingBuilder: desktopTrailingBuilder,
          ),
          ...?(footer == null ? null : <Widget>[footer!]),
        ],
      );
    }

    final headerCount = mobileHeader == null ? 0 : 1;
    final footerCount = footer == null ? 0 : 1;
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        edgeToEdgeMobileItems ? 0 : horizontalPadding,
        0,
        edgeToEdgeMobileItems ? 0 : horizontalPadding,
        mobileBottomPadding,
      ),
      itemCount: headerCount + tracks.length + footerCount,
      itemBuilder: (context, index) {
        if (mobileHeader != null && index == 0) {
          return edgeToEdgeMobileItems
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: mobileHeader!,
                )
              : mobileHeader!;
        }
        final trackIndex = index - headerCount;
        if (trackIndex == tracks.length) {
          return edgeToEdgeMobileItems
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: footer!,
                )
              : footer!;
        }
        return mobileItemBuilder(
          context,
          tracks[trackIndex],
          trackIndex,
          currentTrackId,
        );
      },
    );
  }
}
