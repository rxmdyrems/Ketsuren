import 'package:flutter/material.dart';

/// Animated presentation of the supplied Ketsurēn emblem.
///
/// The emblem is an authored raster asset rather than a reconstruction of the
/// retired upstream geometry. Keeping the motion here deliberately small makes
/// the same brand treatment usable on phone and Android TV first frames.
class KetsurenSplash extends StatelessWidget {
  const KetsurenSplash({super.key, required this.progress, this.size = 220});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final glow = Curves.easeOut.transform((progress * 1.35).clamp(0.0, 1.0));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: glow * 0.22,
            child: Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF80C19),
                    blurRadius: size * 0.20,
                    spreadRadius: size * 0.035,
                  ),
                ],
              ),
            ),
          ),
          Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.78 + (0.22 * t),
              child: Image.asset(
                'assets/brand/ketsuren-emblem-source.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
