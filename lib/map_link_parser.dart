class ParsedMapLocation {
  final double latitude, longitude;
  final String? name;
  final bool locationOnly;
  const ParsedMapLocation(this.latitude, this.longitude,
      {this.name, this.locationOnly = false});
}

ParsedMapLocation? parseMapLocation(String input) {
  var text = input.trim();
  for (var i = 0; i < 2; i++) {
    try {
      final decoded = Uri.decodeFull(text);
      if (decoded == text) break;
      text = decoded;
    } catch (_) {
      break;
    }
  }
  final uri = Uri.tryParse(input.trim());
  final params = uri?.queryParameters ?? <String, String>{};
  final name = params['name'];
  final only = params['mode'] == 'myloc' || text.contains('DLINII_MYLOC:');
  ParsedMapLocation? pair(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^\s*([-+]?\d+(?:\.\d+)?)\s*,\s*([-+]?\d+(?:\.\d+)?)')
        .firstMatch(value);
    if (match == null) return null;
    final lat = double.tryParse(match[1]!), lng = double.tryParse(match[2]!);
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) return null;
    return ParsedMapLocation(lat, lng, name: name, locationOnly: only);
  }

  for (final key in ['destination', 'daddr', 'q', 'query', 'll', 'sll']) {
    final result = pair(params[key]);
    if (result != null) return result;
  }
  final explicit = pair((params['lat'] ?? params['mlat'] ?? '') +
      ',' +
      (params['lng'] ?? params['lon'] ?? params['mlon'] ?? ''));
  if (explicit != null) return explicit;
  final data = RegExp(r'!3d([-\d.]+)!4d([-\d.]+)').firstMatch(text);
  if (data != null) {
    final result = pair(data[1]! + ',' + data[2]!);
    if (result != null) return result;
  }
  for (final pattern in [
    r'DLINII_(?:MYLOC|GUIDE|LOC):([-\d.]+,[-\d.]+)',
    r'geo:([-\d.]+,[-\d.]+)',
    r'@([-\d.]+,[-\d.]+)',
    r'#\d+(?:\.\d+)?/([-\d.]+)/([-\d.]+)'
  ]) {
    final match = RegExp(pattern).firstMatch(text);
    if (match == null) continue;
    final result =
        pair(match.groupCount == 2 ? match[1]! + ',' + match[2]! : match[1]);
    if (result != null) return result;
  }
  return null;
}
