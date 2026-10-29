import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class OfflineTilePlatform {
  static Future<String?> createDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory('${base.path}/offline_tiles');
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return directory.path;
  }

  static bool existsSync(String path) => File(path).existsSync();

  static Future<void> writeBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  static void deleteSync(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  static ImageProvider? imageProvider(String path) => FileImage(File(path));
}
