import 'package:flutter/material.dart';

/// Web keeps raster tiles in the browser cache. Real province downloads are IO-only.
class OfflineTilePlatform {
  static Future<String?> createDirectory() async => null;
  static bool existsSync(String path) => false;
  static Future<void> writeBytes(String path, List<int> bytes) async {}
  static void deleteSync(String path) {}
  static ImageProvider? imageProvider(String path) => null;
}
