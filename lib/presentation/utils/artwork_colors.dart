import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 从封面图片提取的颜色方案。
///
/// 用于创建动态背景渐变和强调色。
class ArtworkColorScheme {
  const ArtworkColorScheme({
    required this.dominant,
    required this.vibrant,
    required this.muted,
    required this.darkVibrant,
    required this.lightVibrant,
  });

  /// 默认的中性配色方案。
  factory ArtworkColorScheme.neutral(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ArtworkColorScheme(
      dominant: isDark ? const Color(0xFF1A1F22) : const Color(0xFFF5F5F5),
      vibrant: isDark ? const Color(0xFF2A3035) : const Color(0xFFE0E0E0),
      muted: isDark ? const Color(0xFF22282C) : const Color(0xFFEEEEEE),
      darkVibrant: isDark ? const Color(0xFF141818) : const Color(0xFFE8E8E8),
      lightVibrant: isDark ? const Color(0xFF323940) : const Color(0xFFFAFAFA),
    );
  }

  /// 主色调。
  final Color dominant;

  /// 高饱和色。
  final Color vibrant;

  /// 低饱和色。
  final Color muted;

  /// 深色变体。
  final Color darkVibrant;

  /// 浅色变体。
  final Color lightVibrant;

  /// 创建从顶部深色到基底色的渐变。
  Gradient backgroundGradient(Color scaffoldColor) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        darkVibrant.withValues(alpha: 0.6),
        darkVibrant.withValues(alpha: 0.3),
        scaffoldColor,
      ],
      stops: const [0.0, 0.4, 1.0],
    );
  }

  /// 创建氛围渐变（用于播放器背景）。
  Gradient ambientGradient(Color scaffoldColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        vibrant.withValues(alpha: 0.15),
        muted.withValues(alpha: 0.08),
        scaffoldColor,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
}

/// 封面取色缓存。
///
/// 避免重复解析同一张封面的颜色。
class ArtworkColorCache {
  static final Map<String, ArtworkColorScheme> _cache = {};
  static const int _maxCacheSize = 50;

  static ArtworkColorScheme? get(String imageUrl) => _cache[imageUrl];

  static void put(String imageUrl, ArtworkColorScheme scheme) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[imageUrl] = scheme;
  }

  static void clear() => _cache.clear();
}

/// 从封面图片提取颜色方案。
///
/// 使用简化的颜色量化算法，提取主要颜色。
Future<ArtworkColorScheme> extractArtworkColors(
  ui.Image image, {
  Brightness brightness = Brightness.dark,
}) async {
  // 获取图片像素数据
  final byteData = await image.toByteData(ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return ArtworkColorScheme.neutral(brightness);
  }

  final pixels = byteData.buffer.asUint8List();
  final width = image.width;
  final height = image.height;

  // 采样像素（每隔 N 个像素采样一次，提高性能）
  final sampleStep = 4;
  final colorCounts = <int, int>{};
  final colorValues = <int, Color>{};

  for (var y = 0; y < height; y += sampleStep) {
    for (var x = 0; x < width; x += sampleStep) {
      final offset = (y * width + x) * 4;
      if (offset + 3 >= pixels.length) continue;

      final r = pixels[offset];
      final g = pixels[offset + 1];
      final b = pixels[offset + 2];
      final a = pixels[offset + 3];

      // 跳过透明像素
      if (a < 128) continue;

      // 量化颜色（减少颜色数量）
      final qr = (r ~/ 32) * 32;
      final qg = (g ~/ 32) * 32;
      final qb = (b ~/ 32) * 32;
      final colorKey = (qr << 16) | (qg << 8) | qb;

      colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
      colorValues[colorKey] = Color.fromARGB(255, r, g, b);
    }
  }

  if (colorCounts.isEmpty) {
    return ArtworkColorScheme.neutral(brightness);
  }

  // 按频率排序
  final sortedColors = colorCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // 提取主要颜色
  Color dominant = colorValues[sortedColors.first.key] ?? Colors.grey;
  Color vibrant = dominant;
  Color muted = dominant;
  Color darkVibrant = dominant;
  Color lightVibrant = dominant;

  // 查找高饱和色
  for (final entry in sortedColors.take(10)) {
    final color = colorValues[entry.key] ?? dominant;
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation > 0.4 && hsl.lightness > 0.3 && hsl.lightness < 0.7) {
      vibrant = color;
      break;
    }
  }

  // 查找低饱和色
  for (final entry in sortedColors.take(10)) {
    final color = colorValues[entry.key] ?? dominant;
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.3) {
      muted = color;
      break;
    }
  }

  // 查找深色变体
  for (final entry in sortedColors.take(10)) {
    final color = colorValues[entry.key] ?? dominant;
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness < 0.3) {
      darkVibrant = color;
      break;
    }
  }

  // 查找浅色变体
  for (final entry in sortedColors.take(10)) {
    final color = colorValues[entry.key] ?? dominant;
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness > 0.6) {
      lightVibrant = color;
      break;
    }
  }

  return ArtworkColorScheme(
    dominant: dominant,
    vibrant: vibrant,
    muted: muted,
    darkVibrant: darkVibrant,
    lightVibrant: lightVibrant,
  );
}
