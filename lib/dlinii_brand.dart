import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class DliniiBrand {
  static const teal = Color(0xFF087E76);
  static const midnight = Color(0xFF09272E);
  static const glow = Color(0xFF58D8CC);
  static const mist = Color(0xFFF1F7F6);
  static Color surface(bool dark) =>
      dark ? const Color(0xFF141E22) : Colors.white;
  static Color ink(bool dark) => dark ? const Color(0xFFF1FAF9) : midnight;
  static Color muted(bool dark) =>
      dark ? const Color(0xFF9AB9BC) : const Color(0xFF57767B);
  static Color stroke(bool dark) =>
      dark ? const Color(0xFF26474E) : const Color(0xFFD9E8E6);
  static const cardShape = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(14),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(24),
  );
}

/// Own road motif, derived from the curve and broken centreline in Dlinii's mark.
class DliniiRoadMotif extends StatelessWidget {
  final Color color;
  const DliniiRoadMotif({super.key, this.color = DliniiBrand.glow});
  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: CustomPaint(painter: _RoadPainter(color)));
}

class _RoadPainter extends CustomPainter {
  final Color color;
  const _RoadPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .65, size.height * 1.15)
      ..cubicTo(
        size.width * .08,
        size.height * .45,
        size.width * 1.25,
        size.height * .72,
        size.width * .84,
        -20,
      );
    final road = Paint()
      ..color = color.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35;
    canvas.drawPath(path, road);
    road
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: .30);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 16) {
        canvas.drawPath(metric.extractPath(d, d + 7), road);
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.color != color;
}

class DliniiBrandHeader extends StatelessWidget {
  final bool compact, english;
  const DliniiBrandHeader({
    super.key,
    this.compact = false,
    this.english = false,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Container(
      height: compact ? 104 : 164,
      color: DliniiBrand.midnight,
      child: Stack(
        children: [
          const Positioned.fill(child: DliniiRoadMotif()),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(
                    'assets/images/dlinii_icon.png',
                    width: compact ? 38 : 54,
                    height: compact ? 38 : 54,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        english ? 'Dlinii' : 'دلّيني',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        english
                            ? 'Your companion on the road'
                            : 'رفيقك على طريقك',
                        style: const TextStyle(
                          color: Color(0xFFB6DEDA),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class DliniiMenuEntry {
  final String label, detail;
  final Widget icon;
  final VoidCallback onTap;
  const DliniiMenuEntry({
    required this.label,
    this.detail = '',
    required this.icon,
    required this.onTap,
  });
}

class DliniiSideMenu extends StatelessWidget {
  final bool dark, english;
  final List<DliniiMenuEntry> entries;
  final VoidCallback onClose;
  const DliniiSideMenu({
    super.key,
    required this.dark,
    required this.english,
    required this.entries,
    required this.onClose,
  });
  @override
  Widget build(BuildContext context) => Drawer(
    width: (MediaQuery.sizeOf(context).width * .88).clamp(280, 370).toDouble(),
    backgroundColor: dark ? const Color(0xFF0B242B) : DliniiBrand.mist,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
    ),
    child: SafeArea(
      child: Directionality(
        textDirection: english ? TextDirection.ltr : TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      english ? 'Your Dlinii' : 'دلّيني وياك',
                      style: TextStyle(
                        color: DliniiBrand.ink(dark),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onClose,
                    child: Text(
                      english ? 'Close' : 'إغلاق',
                      style: TextStyle(color: DliniiBrand.muted(dark)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: DliniiBrandHeader(english: english),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final entry = entries[i];
                  return Material(
                    color: DliniiBrand.surface(dark),
                    borderRadius: DliniiBrand.cardShape,
                    child: InkWell(
                      onTap: entry.onTap,
                      borderRadius: DliniiBrand.cardShape,
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: DliniiBrand.teal.withValues(
                                  alpha: dark ? .24 : .08,
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: entry.icon,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.label,
                                    style: TextStyle(
                                      color: DliniiBrand.ink(dark),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (entry.detail.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.detail,
                                      style: TextStyle(
                                        color: DliniiBrand.muted(dark),
                                        fontSize: 11,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: DliniiBrand.teal.withValues(alpha: .5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DliniiExploreTile extends StatelessWidget {
  final bool dark;
  final String label, hint;
  final Widget icon;
  final VoidCallback onTap;
  const DliniiExploreTile({
    super.key,
    required this.dark,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: DliniiBrand.surface(dark),
    borderRadius: DliniiBrand.cardShape,
    child: InkWell(
      onTap: onTap,
      borderRadius: DliniiBrand.cardShape,
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: DliniiBrand.cardShape,
          border: Border.all(color: DliniiBrand.stroke(dark)),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: DliniiBrand.ink(dark),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: TextStyle(
                      color: DliniiBrand.muted(dark),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Original vector illustrations; no downloaded emoji, font glyphs or remote assets.
class DliniiIncidentArt extends StatelessWidget {
  final String type;
  final double size;
  const DliniiIncidentArt(this.type, {super.key, this.size = 56});
  static const art = <String, String>{
    'bump': '<path d="M12 46h40L46 30H18z" fill="#163C44"/><path d="M16 42c5-22 27-22 32 0" fill="#F1B85A" stroke="#09272E" stroke-width="3"/><path d="M26 31v10m12-10v10" stroke="#09272E" stroke-width="4"/>',
    'pothole': '<path d="m17 14-8 38h46l-8-38" fill="#234852"/><path d="M32 16v7m0 22v6" stroke="#D7F4EC" stroke-width="2"/><ellipse cx="32" cy="34" rx="15" ry="8" fill="#071D26" stroke="#DCA567" stroke-width="3"/><path d="m15 26 5 4-3 6m28-9-4 3 4 7" fill="none" stroke="#DCA567" stroke-width="2"/>',
    'crash': '<g stroke="#09272E" stroke-width="2.5" stroke-linejoin="round"><path d="m7 31 6-12h15l6 12v17H7z" fill="#41BEB2"/><path d="m30 35 7-12h14l6 12v17H30z" fill="#F17C70"/><path d="M15 23h10l3 8H11zm24 4h9l4 8H35z" fill="#E4F8F7"/><path d="m30 10 2 7 7-3-3 8 8 2-9 3" fill="#F5C069"/></g>',
    'traffic': '<g stroke="#09272E" stroke-width="2.5"><rect x="24" y="8" width="23" height="27" rx="7" fill="#E9AF60"/><path d="M29 13h13v8H29z" fill="#E7F6F3"/><rect x="8" y="22" width="24" height="31" rx="7" fill="#47BFB2"/><path d="M13 28h14v9H13z" fill="#E7F6F3"/><rect x="33" y="32" width="23" height="25" rx="7" fill="#E7796A"/><path d="M38 37h13v7H38z" fill="#E7F6F3"/></g>',
    'police': '<path d="m32 8 21 9v15c0 12-21 23-21 23S11 44 11 32V17z" fill="#247E99" stroke="#09272E" stroke-width="3"/><path d="m32 17 4 8 9 1-7 7 2 9-8-4-8 4 2-9-7-7 9-1z" fill="#E2F6EC"/><path d="M17 18 32 12" stroke="#77D4CC" stroke-width="3"/>',
    'hazard': '<path d="M28 11a5 5 0 0 1 8 0l23 39H5z" fill="#EDB65D" stroke="#09272E" stroke-width="3" stroke-linejoin="round"/><path d="M32 23v13" stroke="#173640" stroke-width="5" stroke-linecap="round"/><circle cx="32" cy="43" r="3" fill="#173640"/>',
    'roadworks': '<path d="m19 12 12 35H7z" fill="#EEAB5D" stroke="#173840" stroke-width="3"/><path d="M16 22h7m-11 13h15" stroke="#F5F9EF" stroke-width="5"/><path d="M5 51h29m5-39 13 7m-6-4L34 40q-4 13 7 14l9-10-11-5" fill="none" stroke="#1E5E67" stroke-width="5" stroke-linecap="round"/>',
    'closed': '<path d="M14 34v21m36-21v21" stroke="#17434B" stroke-width="5"/><rect x="7" y="24" width="50" height="19" rx="4" fill="#EFF7F2" stroke="#173E47" stroke-width="3"/><path d="m14 25 9 17m5-17 9 17m5-17 9 17" stroke="#E77E69" stroke-width="6"/><circle cx="32" cy="15" r="10" fill="#D7645F" stroke="#173E47" stroke-width="2"/><path d="M26 15h12" stroke="#FFF" stroke-width="3"/>',
    'camera': '<path d="M30 42v15m-8 0h19" stroke="#19434A" stroke-width="5"/><path d="M11 20h42v25H11z" fill="#55B9AD" stroke="#103941" stroke-width="3"/><path d="m15 20 5-8h17l6 8" fill="#C0E5DC" stroke="#103941" stroke-width="3"/><circle cx="33" cy="32" r="9" fill="#103941"/><circle cx="33" cy="32" r="4" fill="#99DFD1"/><circle cx="17" cy="25" r="2" fill="#F7B561"/><path d="m49 10 7-4m-4 12h8" stroke="#E3AC58" stroke-width="3" stroke-linecap="round"/>',
  };
  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><ellipse cx="32" cy="55" rx="24" ry="5" fill="#082F35" opacity=".10"/>' +
        (art[type] ?? art['hazard']!) +
        '</svg>',
    width: size,
    height: size,
  );
}

class DliniiReportTile extends StatelessWidget {
  final String type, label;
  final bool dark;
  final VoidCallback onTap;
  const DliniiReportTile({
    super.key,
    required this.type,
    required this.label,
    required this.dark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: DliniiBrand.surface(dark),
    borderRadius: DliniiBrand.cardShape,
    child: InkWell(
      onTap: onTap,
      borderRadius: DliniiBrand.cardShape,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: DliniiBrand.stroke(dark)),
          borderRadius: DliniiBrand.cardShape,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F2EE),
                borderRadius: BorderRadius.circular(17),
              ),
              child: DliniiIncidentArt(type, size: 46),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: DliniiBrand.ink(dark),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
