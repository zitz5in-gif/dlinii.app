String _normVoice(String s) => s.toLowerCase().replaceAll('_', '-');

// فحص دقيق جداً لتحديد ما إذا كان الصوت في المحرك أنثوياً (في جوجل، سامسونج، أبل، ومايكروسوفت)
bool _isEngineVoiceFemale(Map<String, String> v) {
  final name = _normVoice(v['name'] ?? '');
  final g = _normVoice(v['gender'] ?? '');
  if (g == 'female' || g == 'f') return true;
  if (g == 'male' || g == 'm') return false;
  const femaleTokens = [
    'female',
    '#female',
    'salma',
    'zariyah',
    'fatima',
    'amany',
    'rana',
    'hoda',
    'laila',
    'mariam',
    'noura',
    'hala',
    'lana',
    'amal',
    'zira',
    'aria',
    'jenny',
    'michelle',
    'microsoft ana',
    'clara',
    'sonia',
    'samantha',
    'victoria',
    'karen',
    'natasha',
    'hazel',
    'susan',
    'ar-xa-x-arc',
    'ar-xa-x-are',
    '-tpf',
    '-sfg',
    '-enc',
    '-ene',
    '-enf',
  ];
  for (final t in femaleTokens) {
    if (RegExp('(^|[^a-z])' + RegExp.escape(t) + r'([^a-z]|$)').hasMatch(name))
      return true;
  }
  return false;
}

bool _isEngineVoiceMale(Map<String, String> v) {
  final name = _normVoice(v['name'] ?? '');
  final g = _normVoice(v['gender'] ?? '');
  if (g == 'male' || g == 'm') return true;
  if (g == 'female' || g == 'f') return false;
  if (_isEngineVoiceFemale(v)) return false;
  const maleTokens = [
    '#male',
    '-male',
    ' male',
    'shakir',
    'hamed',
    'naayf',
    'maged',
    'tarik',
    'hamdan',
    'omar',
    'fahed',
    'moaz',
    'rami',
    'bassel',
    'david',
    'microsoft mark',
    'mark ',
    'guy',
    'christopher',
    'eric',
    'steffan',
    'roger',
    'george',
    'daniel',
    'alex',
    'oliver',
    'ryan',
    'andrew',
    'brian',
    'ar-xa-x-ard',
    'ar-xa-x-arb',
    '-iol',
    '-end',
    '-enb',
    '-iom',
  ];
  for (final t in maleTokens) {
    if (RegExp('(^|[^a-z])' + RegExp.escape(t) + r'([^a-z]|$)').hasMatch(name))
      return true;
  }
  return false;
}

Map<String, String>? selectDliniiVoice(
  List<Map<String, String>> voices, {
  required String language,
  required bool female,
  String? savedIdentity,
}) {
  final matches = voices
      .where(
        (v) =>
            (_normVoice(v['locale'] ?? '').startsWith(language)) &&
            (female ? _isEngineVoiceFemale(v) : _isEngineVoiceMale(v)),
      )
      .toList();
  matches.sort(
    (a, b) => ('${a['locale']}/${a['name']}').compareTo(
      '${b['locale']}/${b['name']}',
    ),
  );
  for (final v in matches) {
    if ('${v['locale']}/${v['name']}' == savedIdentity) return v;
  }
  for (final v in matches) {
    if (RegExp(
      'natural|online|wavenet',
      caseSensitive: false,
    ).hasMatch(v['name'] ?? ''))
      return v;
  }
  return matches.isEmpty ? null : matches.first;
}
