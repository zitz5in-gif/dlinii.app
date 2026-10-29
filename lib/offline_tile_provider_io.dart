import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class OfflineTileProvider extends TileProvider {
  final String? baseDirPath;

  OfflineTileProvider({this.baseDirPath});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final basePath = baseDirPath;
    if (basePath != null && basePath.isNotEmpty) {
      final file = File(
        '$basePath/tiles/${coordinates.z}_${coordinates.x}_${coordinates.y}.png',
      );
      if (file.existsSync() && file.lengthSync() > 100) {
        return FileImage(file);
      }
    }
    return NetworkImage(getTileUrl(coordinates, options));
  }
}

Future<void> prepareOfflineTilesDirectory(String basePath) async {
  final directory = Directory('$basePath/tiles');
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
}

Future<bool> offlineTileExists(String basePath, String fileName) async {
  return File('$basePath/tiles/$fileName').existsSync();
}

Future<void> writeOfflineTile(
  String basePath,
  String fileName,
  List<int> bytes,
) async {
  await File('$basePath/tiles/$fileName').writeAsBytes(bytes, flush: true);
}
