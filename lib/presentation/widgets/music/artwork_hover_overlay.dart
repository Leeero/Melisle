import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class ArtworkHoverOverlay extends StatelessWidget {
  const ArtworkHoverOverlay({
    super.key,
    required this.visible,
    required this.icon,
  });

  final bool visible;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.fast;

    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.standard,
        color: Colors.black.withValues(alpha: visible ? 0.12 : 0),
        alignment: Alignment.center,
        child: AnimatedOpacity(
          duration: duration,
          curve: AppMotion.standard,
          opacity: visible ? 1 : 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.62),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: 44,
              child: Icon(icon, size: 24, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
