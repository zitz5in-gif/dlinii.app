import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// نسخة الويب: لا يوجد نظام ملفات محلي، لذلك تُقرأ البلاطات من الشبكة فقط.
class OfflineTileProvider extends TileProvider {
  final String? baseDirPath;

  OfflineTileProvider({this.baseDirPath});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return NetworkImage(getTileUrl(coordinates, options));
  }
}

Future<void> prepareOfflineTilesDirectory(String basePath) async {}

Future<bool> offlineTileExists(String basePath, String fileName) async => false;

Future<void> writeOfflineTile(
  String basePath,
  String fileName,
  List<int> bytes,
) async {}
