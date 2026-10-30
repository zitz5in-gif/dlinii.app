import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io' show Directory, File;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'permissions_helper.dart';

// ==================== أيقونات الفيكتور الاحترافية (تصميم iOS) ====================

const String kLogoSvg = '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M16 46C28 46 28 30 40 30C46 30 50 26 50 20" stroke="#7ce0be" stroke-width="6" stroke-linecap="round"/><path d="M14 46L22 39M14 46L22 53" stroke="#7ce0be" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/><path d="M46 8C41 8 37 12 37 17C37 23 46 31 46 31C46 31 55 23 55 17C55 12 51 8 46 8Z" fill="#efbb52"/><circle cx="46" cy="17" r="3.5" fill="#143532"/></svg>';
const String kGreenNavArrowSvg = '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="28" fill="#10b981" fill-opacity="0.25"/><circle cx="32" cy="32" r="21" stroke="#6ee7b7" stroke-width="2" stroke-opacity="0.6"/><path d="M32 6L52 54L32 43L12 54L32 6Z" fill="#059669" stroke="#ffffff" stroke-width="3.5" stroke-linejoin="round"/><path d="M32 12L46 48L32 39.5V12Z" fill="#6ee7b7" fill-opacity="0.75"/></svg>';
const String kMyLocationPulseSvg = '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="28" fill="#10b981" fill-opacity="0.22"/><circle cx="32" cy="32" r="19" fill="#10b981" fill-opacity="0.38"/><circle cx="32" cy="32" r="12" fill="#059669" stroke="#ffffff" stroke-width="3.5"/><circle cx="32" cy="32" r="4.5" fill="#a7f3d0"/></svg>';
const String kGpsTargetSvg = '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="18" cy="18" r="10" stroke="#10b981" stroke-width="2.6"/><circle cx="18" cy="18" r="4.2" fill="#efbb52"/><path d="M18 3V7M18 29V33M3 18H7M29 18H33" stroke="#10b981" stroke-width="2.6" stroke-linecap="round"/></svg>';
const String kOriginPinSvg = '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="18" cy="18" r="12" fill="#10b981" fill-opacity="0.18"/><circle cx="18" cy="18" r="7.5" fill="#059669" stroke="#6ee7b7" stroke-width="2.5"/><circle cx="18" cy="18" r="2.8" fill="#ffffff"/></svg>';
const String kDestPinSvg = '<svg viewBox="0 0 36 44" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 2C9.5 2 3 8.5 3 17C3 27.5 18 42 18 42C18 42 33 27.5 33 17C33 8.5 26.5 2 18 2Z" fill="#059669" stroke="#ffffff" stroke-width="2.5"/><circle cx="18" cy="17" r="6.5" fill="#efbb52"/><circle cx="18" cy="17" r="2.5" fill="#142e2d"/></svg>';
const String kReportShieldSvg = '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 3L33 30H3L18 3Z" fill="#f59e0b" stroke="#ffffff" stroke-width="2.2" stroke-linejoin="round"/><path d="M18 12V20" stroke="#142e2d" stroke-width="3.2" stroke-linecap="round"/><circle cx="18" cy="25.5" r="2" fill="#142e2d"/></svg>';
const String kCarSvg = '<svg viewBox="0 0 280 120" fill="none" xmlns="http://www.w3.org/2000/svg"><ellipse cx="140" cy="98" rx="96" ry="7" fill="#0a1c1b" opacity="0.65"/><path d="M72 52 C86 24, 102 18, 146 18 C178 18, 192 28, 208 52 Z" fill="#5cd1b3"/><path d="M38 66 C38 55, 48 50, 66 50 L206 50 C226 51, 242 58, 244 72 C245 81, 240 88, 230 88 L48 88 C40 88, 38 80, 38 66 Z" fill="#4ec4a5"/><g transform="translate(86, 88)"><circle r="19" fill="#122927"/><circle r="11.5" fill="#d4efe7"/><circle r="4" fill="#087e76"/></g><g transform="translate(198, 88)"><circle r="19" fill="#122927"/><circle r="11.5" fill="#d4efe7"/><circle r="4" fill="#087e76"/></g></svg>';

const Map<String, String> kReportTypeSvgs = {
  'bump': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#f59e0b" fill-opacity="0.22"/><path d="M8 32H13C15.5 22 20.5 22 24 27.5C27.5 22 32.5 22 35 32H40" stroke="#f59e0b" stroke-width="4.2" stroke-linecap="round"/><line x1="8" y1="36" x2="40" y2="36" stroke="#ffffff" stroke-width="3" stroke-linecap="round"/></svg>',
  'pothole': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#06b6d4" fill-opacity="0.2"/><ellipse cx="24" cy="31" rx="14" ry="6" fill="#0f172a"/><path d="M12 29L18 33L24 28L30 33L36 29" stroke="#38bdf8" stroke-width="2.8" stroke-linecap="round"/><path d="M24 11V21M24 21L19.5 16.5M24 21L28.5 16.5" stroke="#f43f5e" stroke-width="3.2" stroke-linecap="round"/></svg>',
  'excavation': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#ea580c" fill-opacity="0.22"/><path d="M24 8L40 36H8L24 8Z" fill="#f97316" stroke="#ffffff" stroke-width="2" stroke-linejoin="round"/><path d="M20 23L28 31M22 21L26 25" stroke="#1e293b" stroke-width="3" stroke-linecap="round"/><circle cx="23" cy="18" r="2.2" fill="#1e293b"/></svg>',
  'road_closed': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#e11d48" fill-opacity="0.22"/><circle cx="24" cy="24" r="14" fill="#e11d48" stroke="#ffffff" stroke-width="2.5"/><rect x="14" y="21.5" width="20" height="5" rx="2.5" fill="#ffffff"/></svg>',
  'camera': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#3b82f6" fill-opacity="0.22"/><rect x="10" y="14" width="22" height="16" rx="4" fill="#2563eb" stroke="#ffffff" stroke-width="2"/><path d="M32 18L39 14V30L32 26V18Z" fill="#60a5fa" stroke="#ffffff" stroke-width="1.8"/><circle cx="21" cy="22" r="4" fill="#ffffff"/></svg>',
  'crash': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#ef4444" fill-opacity="0.22"/><path d="M24 7L28.5 16.5L39 13.5L33 22.5L41 30L30.5 31L29.5 40.5L22 33.5L12.5 38.5L15.5 28L7.5 23L18 19L24 7Z" fill="#ef4444" stroke="#ffffff" stroke-width="1.8"/><circle cx="24" cy="25" r="5.2" fill="#fde047"/></svg>',
  'traffic': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#ef4444" fill-opacity="0.2"/><rect x="16" y="7" width="16" height="34" rx="8" fill="#0f172a" stroke="#ffffff" stroke-width="2"/><circle cx="24" cy="14.5" r="3.6" fill="#ef4444"/><circle cx="24" cy="24" r="3.6" fill="#f59e0b"/><circle cx="24" cy="33.5" r="3.6" fill="#10b981"/></svg>',
  'police': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#059669" fill-opacity="0.22"/><path d="M24 8L37 13.5V24C37 32.5 24 39.5 24 39.5C24 39.5 11 32.5 11 24V13.5L24 8Z" fill="#059669" stroke="#ffffff" stroke-width="2.2"/><circle cx="24" cy="23" r="4.8" fill="#fde047"/></svg>',
  'hazard': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3" width="42" height="42" rx="15" fill="#eab308" fill-opacity="0.22"/><path d="M24 9L40 36H8L24 9Z" fill="#eab308" stroke="#ffffff" stroke-width="2.2"/><path d="M24 19V26.5" stroke="#0f172a" stroke-width="3.2" stroke-linecap="round"/><circle cx="24" cy="31.5" r="2.2" fill="#0f172a"/></svg>',
};

class GlassTapButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width, height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor, borderColor;
  final bool isCircle;

  const GlassTapButton({
    super.key,
    required this.onTap,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.isCircle = false,
  });

  @override
  State<GlassTapButton> createState() => _GlassTapButtonState();
}

class _GlassTapButtonState extends State<GlassTapButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 85));
    _scale = Tween<double>(begin: 1.0, end: 0.91).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(15);
    final bg = widget.backgroundColor ?? Colors.white.withOpacity(0.88);
    final borderCol = widget.borderColor ?? const Color(0xFF10b981).withOpacity(0.32);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _pressed = true);
        _ctrl.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _ctrl.reverse();
      },
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: widget.isCircle ? BorderRadius.circular(999) : br,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _pressed ? bg.withOpacity((bg.opacity + 0.14).clamp(0.0, 1.0)) : bg,
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle ? null : br,
                border: Border.all(color: _pressed ? const Color(0xFFefbb52) : borderCol, width: _pressed ? 1.7 : 1.15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(_pressed ? 0.08 : 0.18), blurRadius: _pressed ? 6 : 14, offset: const Offset(0, 4))],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class ExploreCategory {
  final String id, nameAr, nameEn, osmQuery;
  final IconData icon;
  final Color color;
  const ExploreCategory({required this.id, required this.nameAr, required this.nameEn, required this.icon, required this.color, required this.osmQuery});
}

const List<ExploreCategory> kExploreCategories = [
  ExploreCategory(id: 'restaurants', nameAr: 'مطاعم 🍽️', nameEn: 'Restaurants 🍽️', icon: Icons.restaurant_rounded, color: Color(0xFFea580c), osmQuery: 'restaurant'),
  ExploreCategory(id: 'hospitals', nameAr: 'مستشفيات 🏥', nameEn: 'Hospitals 🏥', icon: Icons.local_hospital_rounded, color: Color(0xFFdc2626), osmQuery: 'hospital'),
  ExploreCategory(id: 'fuel', nameAr: 'وقود ⛽', nameEn: 'Fuel ⛽', icon: Icons.local_gas_station_rounded, color: Color(0xFF2563eb), osmQuery: 'fuel'),
  ExploreCategory(id: 'chargers', nameAr: 'شواحن ⚡', nameEn: 'Chargers ⚡', icon: Icons.ev_station_rounded, color: Color(0xFF16a34a), osmQuery: 'charging_station'),
  ExploreCategory(id: 'mosques', nameAr: 'مساجد 🕌', nameEn: 'Mosques 🕌', icon: Icons.mosque_rounded, color: Color(0xFF087e76), osmQuery: 'mosque'),
  ExploreCategory(id: 'banks', nameAr: 'بنوك 🏦', nameEn: 'Banks 🏦', icon: Icons.account_balance_wallet_rounded, color: Color(0xFFd99b26), osmQuery: 'bank'),
  ExploreCategory(id: 'shopping', nameAr: 'تسوق 🛍️', nameEn: 'Shopping 🛍️', icon: Icons.shopping_bag_rounded, color: Color(0xFF9333ea), osmQuery: 'supermarket'),
];

class IraqProvince {
  final String id, nameAr, nameEn, sizeMb;
  final LatLng center;
  final double radiusDeg;
  const IraqProvince({required this.id, required this.nameAr, required this.nameEn, required this.center, required this.sizeMb, this.radiusDeg = 0.28});

  List<LatLng> buildRing({double scale = 1.0, int segments = 40}) {
    final List<LatLng> pts = [];
    final double latR = radiusDeg * 0.92 * scale;
    final double lngR = radiusDeg * 1.12 * scale;
    for (int i = 0; i <= segments; i++) {
      final double ang = (i / segments) * 2 * math.pi;
      final double wave = 1.0 + 0.05 * math.sin(ang * 5) + 0.03 * math.cos(ang * 3);
      pts.add(LatLng(center.latitude + latR * wave * math.sin(ang), center.longitude + lngR * wave * math.cos(ang)));
    }
    return pts;
  }
}

const List<IraqProvince> kIraqProvinces = [
  IraqProvince(id: 'anbar', nameAr: '1. محافظة الأنبار (الرمادي والفلوجة والقائم)', nameEn: '1. Al Anbar Governorate', center: LatLng(33.4258, 43.2995), sizeMb: '45 MB', radiusDeg: 0.35),
  IraqProvince(id: 'baghdad', nameAr: '2. محافظة بغداد', nameEn: '2. Baghdad Governorate', center: LatLng(33.3152, 44.3661), sizeMb: '68 MB', radiusDeg: 0.26),
  IraqProvince(id: 'basra', nameAr: '3. محافظة البصرة', nameEn: '3. Basra Governorate', center: LatLng(30.5081, 47.7835), sizeMb: '48 MB'),
  IraqProvince(id: 'nineveh', nameAr: '4. محافظة نينوى (الموصل)', nameEn: '4. Nineveh Governorate', center: LatLng(36.3489, 43.1577), sizeMb: '54 MB'),
  IraqProvince(id: 'erbil', nameAr: '5. محافظة أربيل', nameEn: '5. Erbil Governorate', center: LatLng(36.1901, 44.0091), sizeMb: '49 MB'),
  IraqProvince(id: 'najaf', nameAr: '6. محافظة النجف الأشرف', nameEn: '6. Najaf Governorate', center: LatLng(32.0000, 44.3333), sizeMb: '38 MB'),
  IraqProvince(id: 'karbala', nameAr: '7. محافظة كربلاء المقدسة', nameEn: '7. Karbala Governorate', center: LatLng(32.6160, 44.0249), sizeMb: '36 MB'),
  IraqProvince(id: 'sulaymaniyah', nameAr: '8. محافظة السليمانية', nameEn: '8. Sulaymaniyah Governorate', center: LatLng(35.5558, 45.4351), sizeMb: '46 MB'),
  IraqProvince(id: 'duhok', nameAr: '9. محافظة دهوك', nameEn: '9. Duhok Governorate', center: LatLng(36.8669, 42.9503), sizeMb: '35 MB'),
  IraqProvince(id: 'kirkuk', nameAr: '10. محافظة كركوك', nameEn: '10. Kirkuk Governorate', center: LatLng(35.4681, 44.3922), sizeMb: '40 MB'),
  IraqProvince(id: 'salahaddin', nameAr: '11. محافظة صلاح الدين (تكريت وسامراء)', nameEn: '11. Saladin Governorate', center: LatLng(34.6110, 43.6782), sizeMb: '41 MB'),
  IraqProvince(id: 'diyala', nameAr: '12. محافظة ديالى (بعقوبة)', nameEn: '12. Diyala Governorate', center: LatLng(33.7485, 44.6436), sizeMb: '39 MB'),
  IraqProvince(id: 'babil', nameAr: '13. محافظة بابل (الحلة)', nameEn: '13. Babylon Governorate', center: LatLng(32.4637, 44.4196), sizeMb: '37 MB'),
  IraqProvince(id: 'wasit', nameAr: '14. محافظة واسط (الكوت)', nameEn: '14. Wasit Governorate', center: LatLng(32.5126, 45.8182), sizeMb: '36 MB'),
  IraqProvince(id: 'dhiqar', nameAr: '15. محافظة ذي قار (الناصرية)', nameEn: '15. Dhi Qar Governorate', center: LatLng(31.0439, 46.2573), sizeMb: '38 MB'),
  IraqProvince(id: 'maysan', nameAr: '16. محافظة ميسان (العمارة)', nameEn: '16. Maysan Governorate', center: LatLng(31.8359, 47.1448), sizeMb: '34 MB'),
  IraqProvince(id: 'qadisiyyah', nameAr: '17. محافظة الديوانية (القادسية)', nameEn: '17. Al-Qadisiyyah Governorate', center: LatLng(31.9929, 44.9255), sizeMb: '33 MB'),
  IraqProvince(id: 'muthanna', nameAr: '18. محافظة المثنى (السماوة)', nameEn: '18. Al Muthanna Governorate', center: LatLng(31.3320, 45.2940), sizeMb: '32 MB'),
];

class VoiceProfile {
  final String id, nameAr, nameEn, descAr, descEn, locale, langType;
  const VoiceProfile({required this.id, required this.nameAr, required this.nameEn, required this.descAr, required this.descEn, required this.locale, required this.langType});
}

const List<VoiceProfile> kVoiceProfiles = [
  VoiceProfile(id: 'ar_voice', nameAr: 'المساعد الصوتي العربي 🇮🇶', nameEn: 'Arabic Voice Assistant 🇮🇶', descAr: 'صوتان ثابتان فقط (فتاة / رجل)', descEn: '2 fixed voices (Female / Male)', locale: 'ar-SA', langType: 'ar'),
  VoiceProfile(id: 'en_voice', nameAr: 'المساعد الصوتي الإنجليزي (English)', nameEn: 'English Voice Assistant', descAr: 'صوتان ثابتان فقط (فتاة / رجل)', descEn: '2 fixed voices (Female / Male)', locale: 'en-US', langType: 'en'),
];

const String kShareHost = 'dlinii.vercel.app';

const ColorFilter kFastDarkMapFilter = ColorFilter.matrix(<double>[
  -0.82, 0.0, 0.0, 0, 215,
  0.0, -0.78, 0.0, 0, 210,
  0.0, 0.0, -0.68, 0, 205,
  0.0, 0.0, 0.0, 1, 0,
]);

class _CarPlayAndroidAutoBridge {
  static const MethodChannel _ch = MethodChannel('com.dlinii.app/car_integration');
  static Future<void> sync({required bool active, required String instruction, required String street, required String arrow, required String km, required String mins, required String eta, required int speed}) async {
    if (kIsWeb) return;
    try {
      await _ch.invokeMethod('updateCarDisplay', {'isNavigating': active, 'instruction': instruction, 'street': street, 'arrow': arrow, 'remKm': km, 'remMins': mins, 'eta': eta, 'speedKmh': speed});
    } catch (_) {}
  }
}

class _OfflineTiles {
  static Directory? dir;
  static final Map<String, Uint8List<dynamic> memoryTiles = {};
  static const List<int> zooms = [10, 11, 12, 13];

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      final base = await getApplicationDocumentsDirectory();
      final d = Directory('${base.path}/offline_tiles_ar');
      if (!d.existsSync()) d.createSync(recursive: true);
      dir = d;
    } catch (_) {}
  }

  static File file(int z, int x, int y) => File('${dir!.path}/$z/$x/$y.png');
  static int _tx(double lon, int z) => ((lon + 180) / 360 * (1 << z)).floor();
  static int _ty(double lat, int z) {
    final double r = lat * math.pi / 180;
    return ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * (1 << z)).floor();
  }

  static Future<bool> downloadProvince(IraqProvince p, {required void Function(double) onProgress}) async {
    if (!kIsWeb && dir == null) await init();
    final List<List<int>> jobs = [];
    for (final z in zooms) {
      final x0 = _tx(p.center.longitude - p.radiusDeg, z), x1 = _tx(p.center.longitude + p.radiusDeg, z);
      final y0 = _ty(p.center.latitude + p.radiusDeg, z), y1 = _ty(p.center.latitude - p.radiusDeg, z);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          jobs.add([z, x, y]);
        }
      }
    }
    final activeJobs = kIsWeb ? jobs.take(90).toList() : jobs.take(250).toList();
    final int total = math.max(1, activeJobs.length);
    int done = 0, next = 0;
    final client = http.Client();
    try {
      Future<void> worker() async {
        while (true) {
          final int i = next++;
          if (i >= activeJobs.length) return;
          final j = activeJobs[i];
          final int srv = (j[1] + j[2]) % 4;
          try {
            final r = await client.get(Uri.parse('https://mt$srv.google.com/vt/lyrs=m&hl=ar&gl=IQ&x=${j[1]}&y=${j[2]}&z=${j[0]}')).timeout(const Duration(seconds: 7));
            if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
              if (kIsWeb) {
                memoryTiles['${j[0]}/${j[1]}/${j[2]}'] = r.bodyBytes;
              } else if (dir != null) {
                final f = file(j[0], j[1], j[2]);
                await f.parent.create(recursive: true);
                await f.writeAsBytes(r.bodyBytes);
              }
            }
          } catch (_) {}
          done++;
          onProgress((done / total).clamp(0.05, 1.0).toDouble());
        }
      }
      await Future.wait(List.generate(6, (_) => worker()));
    } finally {
      client.close();
    }
    return true;
  }
}

class _OfflineTileProvider extends TileProvider {
  _OfflineTileProvider() : super(headers: {'User-Agent': 'com.dlinii.app'});
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final String key = '${coordinates.z}/${coordinates.x}/${coordinates.y}';
    if (kIsWeb && _OfflineTiles.memoryTiles.containsKey(key)) {
      return MemoryImage(_OfflineTiles.memoryTiles[key]!);
    }
    if (!kIsWeb && _OfflineTiles.dir != null) {
      final f = _OfflineTiles.file(coordinates.z, coordinates.x, coordinates.y);
      if (f.existsSync()) return FileImage(f);
    }
    return NetworkImage(getTileUrl(coordinates, options), headers: headers);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _DispState {
  final LatLng pos;
  final double bearing;
  const _DispState(this.pos, this.bearing);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const int endVotesThreshold = 3;
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.dlinii.app';
  static const LatLng kDefaultCenter = LatLng(33.4258, 43.2995);

  bool showSplash = true, isDark = true, isEnglish = false, isFirstPerson3D = false, isPlannerCollapsed = false;
  bool showNotifPermissionModal = false, showModalBox = false, showRateModal = false, showVoiceModal = false;
  bool showPlanSheet = false, showNavSheet = false, showRepSheet = false;

  // نافذة الهبوط عند مشاركة الموقع أو "دلّي صديق"
  bool showSharedLandingModal = false;
  LatLng? sharedIncomingPoint;
  String sharedIncomingTitle = '';
  bool sharedIncomingIsMyLoc = false;

  bool showExploreModal = false, isLoadingCategory = false;
  String selectedCategoryId = 'restaurants';
  List<dynamic> nearbyCategoryPlaces = [];
  List<Marker> categoryMapMarkers = [];

  bool showOfflineMapsModal = false;
  Set<String> downloadedProvinces = {};
  String? downloadingProvinceId;
  double downloadProgress = 0.0;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false, isListeningVoice = false;
  final _OfflineTileProvider _offlineTileProvider = _OfflineTileProvider();

  String modalTitle = '', toastMessage = '';
  List<dynamic> modalSections = [];
  bool isToastVisible = false;
  Timer? toastTimer;

  final MapController mapController = MapController();
  bool _hasRealFix = false;
  final ValueNotifier<_DispState> _dispState = ValueNotifier<_DispState>(const _DispState(kDefaultCenter, 0));
  AnimationController? _flyController;
  double currentZoom = 14.5, currentBearing = 0;
  int currentSpeedKmh = 0;

  LatLng? me = kDefaultCenter, origin, dest, reportPoint;
  String? pickMode;
  bool follow = true;
  StreamSubscription<Position>? positionStream;

  final TextEditingController originController = TextEditingController();
  final TextEditingController destController = TextEditingController();
  Timer? searchDebounce;
  String activeSearchField = 'q', destName = '';
  List<dynamic> searchResults = [], routes = [], navSteps = [];
  bool showSearchList = false, isNavigating = false;
  int selectedRouteIndex = 0, currentStepIndex = 0, lastSpokenStep = -1;
  List<LatLng> navCoords = [];
  Timer? simTimer;

  String hudArrow = '↑', hudInstruction = '—', hudStreet = '', navEta = '—', navRemMins = '—', navRemKm = '—';

  // نظام الصوت الثابت: 0 = فتاة، 1 = رجل
  bool voiceEnabled = true;
  int selectedVoiceIndex = 0, voiceSpeedLevel = 1;
  final FlutterTts flutterTts = FlutterTts();
  List<dynamic> _availableVoices = [];
  final Map<String, int> _voiceSlot = {'ar_voice': 0, 'en_voice': 0};
  final Map<String, int> _pinnedSlot = {};

  List<QueryDocumentSnapshot> cloudReports = [];
  String? selectedReportPopupId;
  Map<String, dynamic>? selectedReportPopupData;
  final Set<String> warnedReports = {};

  String tr(String ar, String en) => isEnglish ? en : ar;
  VoiceProfile get currentVoice => kVoiceProfiles[selectedVoiceIndex.clamp(0, kVoiceProfiles.length - 1)];

  Color get panelColor => isDark ? const Color(0xFF14171C) : Colors.white;
  Color get glassColor => isDark ? const Color(0xFF14171C).withOpacity(0.93) : Colors.white.withOpacity(0.92);
  Color get textColor => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF142e2d);
  Color get subColor => isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6B7B);
  Color get landColor => isDark ? const Color(0xFF0D1014) : const Color(0xFFedf5f2);
  Color get lineColor => isDark ? const Color(0xFF262B33) : const Color(0xFFd5e6e0);
  Color get accentColor => isDark ? const Color(0xFF63cbb0) : const Color(0xFF087e76);

  @override
  void initState() {
    super.initState();
    _loadSavedPrefs();
    _listenToCloudReports();
    _initDeepLinksListener();
    _checkInitialWebUrlForSharedSpot();
    _checkClipboardForSharedLocation();
    _OfflineTiles.init();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        showSplash = false;
        if (!showSharedLandingModal) showNotifPermissionModal = true;
      });
      _say(isEnglish ? 'Welcome to Dlinii, your smart road companion.' : 'مَرْحَبَاً بِكَ فِي تَطْبِيقِ دَلِّينِي، رَفِيقِكَ الذَّكِيِّ عَلَى الطَّرِيقِ.');
    });
  }

  @override
  void dispose() {
    _flyController?.dispose();
    positionStream?.cancel();
    simTimer?.cancel();
    searchDebounce?.cancel();
    toastTimer?.cancel();
    originController.dispose();
    destController.dispose();
    _dispState.dispose();
    super.dispose();
  }

  void _checkInitialWebUrlForSharedSpot() {
    try {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('lat') && uri.queryParameters.containsKey('lng')) {
        _handleIncomingUri(uri, showLandingCard: true);
      } else if (uri.fragment.contains('lat=')) {
        _handleIncomingUri(Uri.parse('https://$kShareHost/${uri.fragment}'), showLandingCard: true);
      }
    } catch (_) {}
  }

  void _initDeepLinksListener() {
    try {
      AppLinks().uriLinkStream.listen((uri) => _handleIncomingUri(uri, showLandingCard: true), onError: (_) {});
    } catch (_) {}
  }

  void _handleIncomingUri(Uri uri, {bool showLandingCard = true}) {
    final double? lat = double.tryParse(uri.queryParameters['lat'] ?? uri.queryParameters['mlat'] ?? '');
    final double? lng = double.tryParse(uri.queryParameters['lng'] ?? uri.queryParameters['mlon'] ?? '');
    final String mode = uri.queryParameters['mode'] ?? 'guide';
    final String? nameStr = uri.queryParameters['name'];

    if (lat != null && lng != null) {
      final pt = LatLng(lat, lng);
      final title = (nameStr != null && nameStr.isNotEmpty)
          ? Uri.decodeComponent(nameStr)
          : (mode == 'myloc' ? tr('موقع صديقك المباشر 📍', 'Friend Live Location 📍') : tr('وجهة مرسلة عبر دلّي صديق 🧭', 'Guided Spot via Dlinii 🧭'));
      setState(() {
        showSplash = false;
        sharedIncomingPoint = pt;
        sharedIncomingTitle = title;
        sharedIncomingIsMyLoc = (mode == 'myloc');
        dest = pt;
        destName = title;
        destController.text = title;
        showSharedLandingModal = showLandingCard;
        if (showLandingCard) showNotifPermissionModal = false;
      });
      if (!showLandingCard) _proceedWithSharedLocationOnWebOrApp();
    } else {
      _parseAndOpenSharedText(uri.toString(), showLandingCard: showLandingCard);
    }
  }

  bool _parseAndOpenSharedText(String text, {bool clearClipboard = false, bool showLandingCard = false}) {
    if (text.trim().isEmpty) return false;
    final bool isMyLoc = text.contains('DLINII_MYLOC:') || text.contains('mode=myloc');
    double? lat, lng;
    final m1 = RegExp(r'DLINII_(?:MYLOC|GUIDE|LOC):([-\d.]+),([-\d.]+)').firstMatch(text);
    if (m1 != null) {
      lat = double.tryParse(m1.group(1) ?? '');
      lng = double.tryParse(m1.group(2) ?? '');
    } else {
      final m2 = RegExp(r'(?:q=|mlat=|lat=|geo:)([-\d.]+)[,&\s/]+(?:mlon=|lng=)?([-\d.]+)').firstMatch(text);
      if (m2 != null) {
        lat = double.tryParse(m2.group(1) ?? '');
        lng = double.tryParse(m2.group(2) ?? '');
      }
    }
    if (lat != null && lng != null) {
      if (clearClipboard) Clipboard.setData(const ClipboardData(text: ''));
      final pt = LatLng(lat, lng);
      final title = isMyLoc ? tr('موقع صديقك المباشر 📍', 'Friend Live Location 📍') : tr('وجهة مرسلة عبر دلّي صديق 🧭', 'Guided Spot via Dlinii 🧭');
      setState(() {
        showSplash = false;
        sharedIncomingPoint = pt;
        sharedIncomingTitle = title;
        sharedIncomingIsMyLoc = isMyLoc;
        dest = pt;
        destName = title;
        destController.text = title;
        showSharedLandingModal = showLandingCard || kIsWeb;
      });
      if (!showSharedLandingModal) _proceedWithSharedLocationOnWebOrApp();
      return true;
    }
    return false;
  }

  void _proceedWithSharedLocationOnWebOrApp() {
    final pt = sharedIncomingPoint ?? dest ?? kDefaultCenter;
    setState(() {
      showSharedLandingModal = false;
      dest = pt;
      if (sharedIncomingTitle.isNotEmpty) {
        destName = sharedIncomingTitle;
        destController.text = destName;
      }
    });
    _initLocationTracking(userInitiated: true);
    _flyToMyLocation(pt, targetZoom: 16.0);
    _planRoute();
  }

  Future<void> _openInNativeDliniiAppOrStore() async {
    final pt = sharedIncomingPoint ?? dest ?? me ?? kDefaultCenter;
    final Uri deepLink = Uri.parse('dlinii://open?lat=${pt.latitude}&lng=${pt.longitude}&mode=${sharedIncomingIsMyLoc ? 'myloc' : 'guide'}');
    try {
      final ok = await launchUrl(deepLink, mode: LaunchMode.externalNonBrowserApplication);
      if (!ok) await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkClipboardForSharedLocation() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.contains('DLINII_') || text.contains(kShareHost)) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _parseAndOpenSharedText(text, clearClipboard: true, showLandingCard: true);
        });
      }
    } catch (_) {}
  }

  void _flyToMyLocation(LatLng target, {double targetZoom = 16.5}) {
    _flyController?.dispose();
    final startCenter = mapController.camera.center;
    final startZoom = mapController.camera.zoom;
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
    _flyController = ctrl;
    ctrl.addListener(() {
      final t = Curves.easeInOutCubic.transform(ctrl.value);
      final lat = startCenter.latitude + (target.latitude - startCenter.latitude) * t;
      final lng = startCenter.longitude + (target.longitude - startCenter.longitude) * t;
      final z = startZoom + (targetZoom - startZoom) * t;
      mapController.move(LatLng(lat, lng), z);
      currentZoom = z;
    });
    ctrl.forward();
  }

  String _buildShareLink(LatLng p, {required bool myLoc, String? name}) {
    final q = <String, String>{'lat': p.latitude.toStringAsFixed(6), 'lng': p.longitude.toStringAsFixed(6), 'mode': myLoc ? 'myloc' : 'guide'};
    if (name != null && name.isNotEmpty) q['name'] = name;
    return Uri.https(kShareHost, '/', q).toString();
  }

  Future<void> _shareMyCurrentLocation() async {
    await _initLocationTracking(userInitiated: true);
    LatLng pt = me ?? mapController.camera.center;
    try {
      final fresh = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 6));
      pt = LatLng(fresh.latitude, fresh.longitude);
      me = pt;
    } catch (_) {}
    final link = _buildShareLink(pt, myLoc: true);
    Share.share(tr(
      '📍 موقعي الحالي المباشر عبر تطبيق دلّيني:\n\n🔗 افتح الرابط (ويب أو تطبيق):\n$link\n\n🧭 كود الفتح السريع:\nDLINII_MYLOC:${pt.latitude.toStringAsFixed(6)},${pt.longitude.toStringAsFixed(6)}\n\n📲 تحميل دلّيني من متجر بلي:\n$playStoreUrl',
      '📍 My live location via Dlinii:\n$link\n\n📲 Download Dlinii:\n$playStoreUrl',
    ));
  }

  void _shareCustomSpot(LatLng pt, String spotTitle) {
    final cleanName = spotTitle.isNotEmpty ? spotTitle : tr('موقع محدد على الخريطة', 'Pinned Location');
    final link = _buildShareLink(pt, myLoc: false, name: cleanName);
    Share.share(tr(
      '🧭 دلّيتك على مكان «$cleanName» عبر تطبيق دلّيني:\n\n🔗 افتح الرابط ليرسم لك المسار مباشرة (ويب أو تطبيق):\n$link\n\n🧭 كود المسار:\nDLINII_GUIDE:${pt.latitude.toStringAsFixed(6)},${pt.longitude.toStringAsFixed(6)}\n\n📲 تحميل دلّيني من متجر بلي:\n$playStoreUrl',
      '🧭 Guided spot "$cleanName" via Dlinii:\n$link\n\n📲 Download Dlinii:\n$playStoreUrl',
    ));
  }

  Future<void> _downloadProvinceOfflineMap(IraqProvince prov) async {
    if (downloadingProvinceId != null) return;
    setState(() {
      downloadingProvinceId = prov.id;
      downloadProgress = 0.05;
    });
    final ok = await _OfflineTiles.downloadProvince(prov, onProgress: (p) {
      if (mounted) setState(() => downloadProgress = p);
    });
    if (!mounted) return;
    if (ok) {
      downloadedProvinces.add(prov.id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dlini_offline_provinces', downloadedProvinces.toList());
      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
        showOfflineMapsModal = false;
      });
      _flyToMyLocation(prov.center, targetZoom: 11.2);
      _toast(tr('تم تحميل «${prov.nameAr}» وتحديد حدودها بالمسار الأخضر وإخفاء باقي المحافظات ✅', '${prov.nameEn} downloaded with green border ✅'));
    } else {
      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });
    }
  }

  Future<void> _loadSavedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getInt('dlini_voice_idx_v5') ?? 0;
      final savedSpeed = prefs.getInt('dlini_voice_speed_lvl') ?? 1;
      final savedLang = prefs.getBool('dlini_is_en') ?? false;
      final savedDark = prefs.getBool('dlini_is_dark_default_v2') ?? true;
      downloadedProvinces = (prefs.getStringList('dlini_offline_provinces') ?? []).toSet();
      for (final vp in kVoiceProfiles) {
        final slot = (prefs.getInt('dlini_slot_${vp.id}') ?? 0).clamp(0, 1);
        _voiceSlot[vp.id] = slot;
        final pinned = prefs.getInt('dlini_pinned_slot_${vp.id}');
        if (pinned != null) {
          _pinnedSlot[vp.id] = pinned.clamp(0, 1);
          _voiceSlot[vp.id] = pinned.clamp(0, 1);
        }
      }
      if (mounted) {
        setState(() {
          selectedVoiceIndex = savedVoice.clamp(0, 1);
          voiceSpeedLevel = savedSpeed.clamp(0, 2);
          isEnglish = savedLang;
          isDark = savedDark;
        });
      }
    } catch (_) {}
    await _applyVoiceProfile();
  }

  /// يضبط الصوتين الثابتين فقط: (Slot 0 = فتاة، Slot 1 = رجل) للعربي والإنجليزي بدون أي لخبطة
  Future<void> _applyVoiceProfile() async {
    try {
      if (_availableVoices.isEmpty) {
        final dynamic raw = await flutterTts.getVoices;
        if (raw is List) {
          _availableVoices = raw.whereType().map((v) => {'name': v['name']?.toString() ?? '', 'locale': v['locale']?.toString() ?? '', 'gender': v['gender']?.toString() ?? ''}).toList();
        }
      }
      final vp = currentVoice;
      final int activeSlot = _pinnedSlot[vp.id] ?? (_voiceSlot[vp.id] ?? 0);
      final bool wantFemale = (activeSlot == 0);

      await flutterTts.stop();
      await flutterTts.setLanguage(vp.locale);

      final langVoices = _availableVoices.where((v) {
        final loc = (v['locale'] ?? '').toLowerCase();
        return vp.langType == 'ar' ? loc.startsWith('ar') : loc.startsWith('en');
      }).toList();

      bool matchedEngineGender = false;
      if (langVoices.isNotEmpty) {
        final matches = langVoices.where((v) {
          final n = '${v['name']} ${v['gender']}'.toLowerCase();
          return wantFemale
              ? (n.contains('female') || n.contains('salma') || n.contains('zariyah') || n.contains('hoda') || n.contains('zira') || n.contains('aria') || n.contains('jenny') || n.contains('samantha'))
              : (n.contains('male') || n.contains('shakir') || n.contains('hamed') || n.contains('maged') || n.contains('david') || n.contains('guy') || n.contains('mark') || n.contains('daniel'));
        }).toList();

        final chosen = matches.isNotEmpty ? matches.first : (langVoices.length >= 2 ? (wantFemale ? langVoices.first : langVoices.last) : langVoices.first);
        matchedEngineGender = matches.isNotEmpty;
        try {
          await flutterTts.setVoice({'name': chosen['name']!, 'locale': chosen['locale']!.isNotEmpty ? chosen['locale']! : vp.locale});
        } catch (_) {}
      }

      final double pitch = matchedEngineGender ? (wantFemale ? 1.15 : 0.82) : (wantFemale ? 1.38 : 0.62);
      final double rate = kIsWeb ? (voiceSpeedLevel == 0 ? 0.90 : (voiceSpeedLevel == 2 ? 1.18 : 1.02)) : (voiceSpeedLevel == 0 ? 0.48 : (voiceSpeedLevel == 2 ? 0.65 : 0.55));
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(pitch);
      await flutterTts.setSpeechRate(rate);
    } catch (_) {}
  }

  Future<void> _selectFixedVoice(int langIdx, int genderSlot) async {
    final vp = kVoiceProfiles[langIdx.clamp(0, 1)];
    setState(() {
      selectedVoiceIndex = langIdx;
      _voiceSlot[vp.id] = genderSlot;
      if (_pinnedSlot.containsKey(vp.id)) _pinnedSlot[vp.id] = genderSlot;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_voice_idx_v5', langIdx);
    await prefs.setInt('dlini_slot_${vp.id}', genderSlot);
    await _applyVoiceProfile();
    _say(vp.langType == 'en'
        ? (genderSlot == 0 ? 'Hello, I am the female voice assistant on Dlinii.' : 'Hello, I am the male voice assistant on Dlinii.')
        : (genderSlot == 0 ? 'مَرْحَبَاً بِكَ فِي دَلِّينِي، أَنَا الْمُسَاعِدَةُ الصَّوْتِيَّةُ لِتَوْجِيهِكَ.' : 'مَرْحَبَاً بِكَ فِي دَلِّينِي، أَنَا الْمُسَاعِدُ الصَّوْتِيُّ لِتَوْجِيهِكَ.'));
  }

  Future<void> _togglePinCurrentVoice() async {
    final vp = currentVoice;
    final prefs = await SharedPreferences.getInstance();
    if (_pinnedSlot.containsKey(vp.id)) {
      setState(() => _pinnedSlot.remove(vp.id));
      await prefs.remove('dlini_pinned_slot_${vp.id}');
      _toast(tr('تم إلغاء تثبيت الصوت', 'Voice unpinned'));
    } else {
      final slot = _voiceSlot[vp.id] ?? 0;
      setState(() => _pinnedSlot[vp.id] = slot);
      await prefs.setInt('dlini_pinned_slot_${vp.id}', slot);
      _toast(tr('تم تثبيت الصوت بنجاح 📌', 'Voice pinned permanently 📌'));
    }
  }

  Future<void> _say(String text) async {
    if (!voiceEnabled) return;
    try {
      await _applyVoiceProfile();
      await flutterTts.speak(text);
    } catch (_) {}
  }

  void _toast(String msg) {
    toastTimer?.cancel();
    setState(() {
      toastMessage = msg;
      isToastVisible = true;
    });
    toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => isToastVisible = false);
    });
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const double R = 6371000, r = math.pi / 180;
    final double dLat = (b.latitude - a.latitude) * r, dLon = (b.longitude - a.longitude) * r;
    final double x = math.pow(math.sin(dLat / 2), 2) + math.cos(a.latitude * r) * math.cos(b.latitude * r) * math.pow(math.sin(dLon / 2), 2);
    return 2 * R * math.asin(math.sqrt(x));
  }

  double _getBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180, lon1 = start.longitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180, lon2 = end.longitude * math.pi / 180;
    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);
    return ((math.atan2(y, x) * 180 / math.pi) + 360) % 360;
  }

  /// يطلب إذن الموقع رسمياً من المتصفح أو الهاتف ويظهر الموقع الحالي فوراً
  Future<void> _initLocationTracking({bool userInitiated = false}) async {
    try {
      if (kIsWeb) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          if (userInitiated) _toast(tr('يرجى السماح بإذن الموقع من المتصفح لتحديد موقعك 📍', 'Please allow browser GPS permission 📍'));
          return;
        }
      } else {
        final res = await PermissionsHelper.ensureLocation();
        if (res != LocPermResult.granted) {
          if (userInitiated) _toast(tr('يرجى تفعيل خدمة الموقع (GPS) 📍', 'Please enable GPS location 📍'));
          return;
        }
      }

      await positionStream?.cancel();
      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
      ).listen((pos) {
        if (simTimer == null) _onPositionUpdate(LatLng(pos.latitude, pos.longitude), pos.speed, pos.heading);
      }, onError: (_) {});

      final pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 8));
      if (mounted) {
        _onPositionUpdate(LatLng(pos.latitude, pos.longitude), pos.speed, pos.heading, isFirst: true);
        if (userInitiated) _flyToMyLocation(LatLng(pos.latitude, pos.longitude), targetZoom: 16.5);
      }
    } catch (_) {}
  }

  void _onPositionUpdate(LatLng rawMe, double speedMps, double heading, {bool isFirst = false}) {
    if (!mounted) return;
    _hasRealFix = true;
    final double newBearing = (heading >= 0 && !heading.isNaN) ? heading : (me != null && _distanceMeters(me!, rawMe) > 2 ? _getBearing(me!, rawMe) : currentBearing);
    setState(() {
      currentBearing = newBearing;
      me = rawMe;
      currentSpeedKmh = math.max(0, (speedMps * 3.6).round());
    });
    _dispState.value = _DispState(rawMe, newBearing);
    if (isFirst && !isNavigating) mapController.move(rawMe, 15.5);
    _checkNearbyReports(rawMe);
    if (isNavigating) _updateNavigationState();
  }

  /// فلترة البلاغات: تظهر فقط ضمن 300 متر حول المستخدم أو على امتداد مساره المرسوم
  bool _isReportRelevantToUser(LatLng repPt) {
    final LatLng userPt = me ?? kDefaultCenter;
    if (_distanceMeters(userPt, repPt) <= 300.0) return true;
    if (routes.isNotEmpty) {
      final List<dynamic> coords = routes[selectedRouteIndex]['geometry']['coordinates'] as List;
      for (int i = 0; i < coords.length; i += 2) {
        final c = coords[i];
        if (_distanceMeters(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()), repPt) <= 200.0) return true;
      }
    }
    return false;
  }

  double _getReportRadiusMeters(String type) {
    switch (type) {
      case 'bump': return 75.0;
      case 'pothole': return 90.0;
      case 'camera': return 115.0;
      case 'excavation': return 170.0;
      case 'crash': return 195.0;
      case 'road_closed': return 240.0;
      case 'traffic': return 320.0;
      default: return 135.0;
    }
  }

  /// المسار: أخضر للطرق السالكة، أصفر للبلاغات حسب أبعادها، وأحمر للازدحام فقط
  List<Polyline> _buildRealTrafficAndHazardOverlays(Map<String, dynamic> selectedRoute, List<LatLng> routePoints) {
    final List<Polyline> overlays = [];
    if (routePoints.length < 2) return overlays;
    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final repPt = LatLng(((data['lat'] ?? 33.4258) as num).toDouble(), ((data['lng'] ?? 43.2995) as num).toDouble());
      final String type = data['type']?.toString() ?? 'hazard';
      final double radiusM = _getReportRadiusMeters(type);
      final List<LatLng> seg = routePoints.where((p) => _distanceMeters(p, repPt) <= radiusM).toList();
      if (seg.length >= 2) {
        final bool isRed = (type == 'traffic' || type == 'road_closed');
        overlays.add(Polyline(points: seg, color: isRed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), strokeWidth: 9.8));
      }
    }
    return overlays;
  }

  /// أي مكان به بلاغ ازدحام على الخريطة يتم تلوين الطريق فيه باللون الأحمر
  List<Polyline> _buildLiveTrafficJamRoadSegments() {
    final List<Polyline> reds = [];
    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final String type = data['type']?.toString() ?? '';
      if (type != 'traffic' && type != 'road_closed') continue;
      final LatLng c = LatLng(((data['lat'] ?? 33.4258) as num).toDouble(), ((data['lng'] ?? 43.2995) as num).toDouble());
      if (!_isReportRelevantToUser(c)) continue;
      const double d = 0.0013;
      reds.add(Polyline(
        points: [LatLng(c.latitude - d, c.longitude - d * 0.7), c, LatLng(c.latitude + d, c.longitude + d * 0.7)],
        color: const Color(0xFFEF4444),
        strokeWidth: 9.0,
        borderColor: const Color(0xFF7F1D1D),
        borderStrokeWidth: 2.0,
      ));
    }
    return reds;
  }

  /// يحدد حدود المحافظة المحمّلة بمسار أخضر ويخفي باقي المحافظات غير المحمّلة
  List<Polyline> _buildDownloadedProvinceBordersAndMask() {
    if (downloadedProvinces.isEmpty) return [];
    final List<Polyline> layers = [];
    for (final pid in downloadedProvinces) {
      final prov = kIraqProvinces.firstWhere((p) => p.id == pid, orElse: () => kIraqProvinces.first);
      // حلقات إخفاء داكنة تحجب المحافظات الخارجية غير المحمّلة
      for (final double s in [1.35, 1.85, 2.50, 3.40]) {
        layers.add(Polyline(points: prov.buildRing(scale: s), color: const Color(0xFF07090C).withOpacity(0.92), strokeWidth: 140.0));
      }
      // المسار الأخضر المضيء لحدود المحافظة المحمّلة
      layers.add(Polyline(points: prov.buildRing(scale: 1.0), color: const Color(0xFF10b981), strokeWidth: 5.0, borderColor: const Color(0xFFa7f3d0), borderStrokeWidth: 2.0));
    }
    return layers;
  }

  void _listenToCloudReports() {
    try {
      FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true).snapshots().listen((snap) {
        if (!mounted) return;
        setState(() => cloudReports = snap.docs.where((d) => (((d.data()['endVotes'] ?? 0) as num).toInt() < endVotesThreshold)).toList());
      });
    } catch (_) {}
  }

  String _getReportLabel(String? type, String? fallback) {
    switch (type) {
      case 'bump': return tr('مطب 🚧', 'Speed Bump 🚧');
      case 'pothole': return tr('حفرة 🕳️', 'Pothole 🕳️');
      case 'excavation': return tr('حفريات 🚜', 'Excavation 🚜');
      case 'road_closed': return tr('طريق مغلق ⛔', 'Road Closed ⛔');
      case 'camera': return tr('كاميرا مراقبة 📸', 'Speed Camera 📸');
      case 'crash': return tr('حادث 💥', 'Crash 💥');
      case 'traffic': return tr('ازدحام 🚦', 'Traffic Jam 🚦');
      case 'police': return tr('نقطة مرور 🚓', 'Police 🚓');
      default: return tr('خطر طريق ⚠️', 'Road Hazard ⚠️');
    }
  }

  Widget _buildReportSvg(String? type, {double size = 28}) => SvgPicture.string(kReportTypeSvgs[type] ?? kReportTypeSvgs['hazard']!, width: size, height: size);

  void _checkNearbyReports(LatLng pos) {
    final bool en = isEnglish || currentVoice.langType == 'en';
    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final repPos = LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble());
      final double dist = _distanceMeters(pos, repPos);
      if (dist <= 220 && !warnedReports.contains(doc.id)) {
        warnedReports.add(doc.id);
        final label = _getReportLabel(data['type']?.toString(), null);
        final msg = en ? 'Caution, $label ahead on your route' : 'اِنْتَبِهْ، أَمَامَكَ $label فِي مَسَارِكَ';
        _say(msg);
        _toast(msg);
      }
    }
  }

  Future<void> _submitCloudReport(String type, String label) async {
    final pt = reportPoint ?? me ?? mapController.camera.center;
    setState(() => showRepSheet = false);
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': type, 'label': label, 'lat': pt.latitude, 'lng': pt.longitude,
        'confirmations': 1, 'endVotes': 0, 'createdAt': FieldValue.serverTimestamp(),
      });
      _toast(tr('تم نشر بلاغ «$label» ضمن مدى 300 متر ومسار السائقين ✅', 'Report "$label" published ✅'));
    } catch (_) {}
  }

  Future<void> _searchPlaceGlobal(String query) async {
    final center = me ?? mapController.camera.center;
    try {
      final lang = isEnglish ? 'en' : 'ar';
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&accept-language=$lang&limit=8');
      final res = await http.get(url, headers: {'User-Agent': 'com.dlinii.app'}).timeout(const Duration(seconds: 9));
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          searchResults = data;
          showSearchList = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _openAndFetchCategory(ExploreCategory cat) async {
    final center = me ?? mapController.camera.center;
    setState(() {
      selectedCategoryId = cat.id;
      showExploreModal = true;
      isLoadingCategory = true;
      nearbyCategoryPlaces = [];
    });
    try {
      final lang = isEnglish ? 'en' : 'ar';
      const double d = 0.20;
      final vb = '${center.longitude - d},${center.latitude + d},${center.longitude + d},${center.latitude - d}';
      final res = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(cat.osmQuery)}&viewbox=$vb&bounded=1&accept-language=$lang&limit=15')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> raw = json.decode(res.body);
        final List<dynamic> list = [];
        for (final r in raw) {
          final la = double.tryParse(r['lat']?.toString() ?? ''), lo = double.tryParse(r['lon']?.toString() ?? '');
          if (la == null || lo == null) continue;
          list.add({'title': r['name']?.toString().isNotEmpty == true ? r['name'] : r['display_name'].toString().split(',').first, 'lat': la, 'lng': lo, 'distKm': _distanceMeters(center, LatLng(la, lo)) / 1000.0});
        }
        list.sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));
        setState(() {
          nearbyCategoryPlaces = list;
          isLoadingCategory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingCategory = false);
    }
  }

  Future<void> _planRoute() async {
    final o = origin ?? me ?? mapController.camera.center;
    if (dest == null) return;
    final d = dest!;
    try {
      final res = await http.get(Uri.parse('https://router.project-osrm.org/route/v1/driving/${o.longitude},${o.latitude};${d.longitude},${d.latitude}?overview=full&geometries=geojson&steps=true')).timeout(const Duration(seconds: 9));
      final data = json.decode(res.body);
      if (data['routes'] != null && (data['routes'] as List).isNotEmpty && mounted) {
        setState(() {
          routes = List<dynamic>.from(data['routes'] as List);
          selectedRouteIndex = 0;
          if (!isNavigating) showPlanSheet = true;
        });
        final pts = (routes[0]['geometry']['coordinates'] as List).map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(65)));
      }
    } catch (_) {}
  }

  void _startNav() {
    if (routes.isEmpty) return;
    final r = routes[selectedRouteIndex];
    navCoords = (r['geometry']['coordinates'] as List).map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
    navSteps = r['legs'][0]['steps'] as List;
    currentStepIndex = 0;
    lastSpokenStep = -1;
    setState(() {
      isNavigating = true;
      isFirstPerson3D = true;
      showPlanSheet = false;
      showNavSheet = true;
    });
    _say(isEnglish ? 'Starting navigation.' : 'بَدَأَتِ الرِّحْلَةُ، رَافَقَتْكَ السَّلَامَةُ.');
    _updateNavigationState();
  }

  void _updateNavigationState() {
    if (me == null || navCoords.isEmpty) return;
    final double remM = _distanceMeters(me!, navCoords.last);
    if (remM < 35) {
      _endNav(arrived: true);
      return;
    }
    final int mins = math.max(1, (remM / 650).round());
    final eta = DateTime.now().add(Duration(minutes: mins));
    setState(() {
      navRemKm = (remM / 1000).toStringAsFixed(1);
      navRemMins = mins.toString();
      navEta = '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
      hudInstruction = tr('تابع السير على المسار الأخضر (${navRemKm} كم)', 'Follow green route ($navRemKm km)');
      hudStreet = destName;
    });
    _CarPlayAndroidAutoBridge.sync(active: true, instruction: hudInstruction, street: hudStreet, arrow: hudArrow, km: navRemKm, mins: navRemMins, eta: navEta, speed: currentSpeedKmh);
  }

  void _endNav({bool arrived = false}) {
    simTimer?.cancel();
    simTimer = null;
    flutterTts.stop();
    setState(() {
      isNavigating = false;
      isFirstPerson3D = false;
      showPlanSheet = false;
      showNavSheet = false;
      dest = null;
      routes = [];
      destController.clear();
    });
    _CarPlayAndroidAutoBridge.sync(active: false, instruction: '', street: '', arrow: '', km: '0', mins: '0', eta: '', speed: 0);
    if (arrived) {
      _say(isEnglish ? 'You have arrived safely.' : 'الْحَمْدُ لِلَّهِ عَلَى سَلَامَتِكَ، لَقَدْ وَصَلْتَ إِلَى وِجْهَتِكَ بِالسَّلَامَةِ.');
      setState(() => showRateModal = true);
    }
  }

  void _startSimulation() {
    _startNav();
    if (navCoords.length < 2) return;
    int idx = 0;
    simTimer?.cancel();
    simTimer = Timer.periodic(const Duration(milliseconds: 650), (t) {
      if (idx >= navCoords.length - 1) {
        t.cancel();
        _endNav(arrived: true);
        return;
      }
      _onPositionUpdate(navCoords[idx], 14.0, _getBearing(navCoords[idx], navCoords[idx + 1]));
      idx++;
    });
  }

  Widget _buildAppIcon({double size = 44}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/images/dlinii_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFF143532),
          padding: const EdgeInsets.all(6),
          child: SvgPicture.string(kLogoSvg),
        ),
      ),
    );
  }

  Widget _buildStandardAppDrawer() {
    final vp = currentVoice;
    final int slot = _pinnedSlot[vp.id] ?? (_voiceSlot[vp.id] ?? 0);
    return Drawer(
      backgroundColor: panelColor,
      width: 290,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 18, right: 18),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF087e76), Color(0xFF0d2624)])),
            child: Row(
              children: [
                _buildAppIcon(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('تطبيق دلّيني', 'Dlinii App'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(tr('يدعم CarPlay و Android Auto 🚘', 'CarPlay & Android Auto 🚘'), style: const TextStyle(fontSize: 11, color: Color(0xFF9cdbc0), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_download_rounded, color: Color(0xFF10b981)),
                  title: Text(tr('خرائط بدون نت (18 محافظة) 🗺️', 'Offline Maps (18 Provinces)'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  subtitle: Text(tr('تحديد الحدود بالأخضر (${downloadedProvinces.length}/18)', 'Green border (${downloadedProvinces.length}/18)'), style: TextStyle(fontSize: 11, color: subColor)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => showOfflineMapsModal = true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.my_location_rounded, color: Color(0xFF087e76)),
                  title: Text(tr('مشاركة موقعي الحالي 📍', 'Share My Location 📍'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _shareMyCurrentLocation();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pin_drop_rounded, color: Color(0xFFd99b26)),
                  title: Text(tr('دلّي صديق على مكان 🧭', 'Guide a Friend 🧭'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => pickMode = 'share_spot');
                    _toast(tr('اضغط على المكان في الخريطة لإرساله لصديقك 🧭', 'Tap spot on map to share 🧭'));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF10b981)),
                  title: Text(tr('صفحة رابط المشاركة (ويب / تطبيق) 🌐', 'Share Landing Page Preview 🌐'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  subtitle: Text(tr('خيارات الاستمرار بالويب أو فتح/تحميل التطبيق', 'Continue on Web or Open/Get App'), style: TextStyle(fontSize: 11, color: subColor)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      sharedIncomingPoint = me ?? kDefaultCenter;
                      sharedIncomingTitle = tr('موقع مشارك عبر تطبيق دلّيني 📍', 'Shared Spot via Dlinii 📍');
                      showSharedLandingModal = true;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF38BDF8)),
                  title: Text(tr('ربط شاشة السيارة (CarPlay / Auto) 🚘', 'CarPlay & Android Auto 🚘'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _CarPlayAndroidAutoBridge.sync(active: isNavigating, instruction: hudInstruction, street: hudStreet, arrow: hudArrow, km: navRemKm, mins: navRemMins, eta: navEta, speed: currentSpeedKmh);
                    _toast(tr('تم تفعيل الربط التلقائي مع شاشة السيارة CarPlay & Android Auto 🚘', 'CarPlay & Android Auto synced 🚘'));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF087e76)),
                  title: Text(tr('المساعد الصوتي (فتاة / رجل) 🎙️', 'Voice Assistant 🎙️'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  subtitle: Text('${isEnglish ? vp.nameEn : vp.nameAr} • ${slot == 0 ? tr('صوت فتاة 👩', 'Female 👩') : tr('صوت رجل 👨', 'Male 👨')}', style: TextStyle(fontSize: 11, color: subColor)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => showVoiceModal = true);
                  },
                ),
                ListTile(
                  leading: Icon(isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded, color: const Color(0xFFefbb52)),
                  title: Text(tr(isDark ? 'الوضع النهاري (سريع ☀️)' : 'الوضع الليلي (سريع 🌙)', isDark ? 'Light Mode ☀️' : 'Dark Mode 🌙'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() => isDark = !isDark);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('dlini_is_dark_default_v2', isDark);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.translate_rounded, color: Color(0xFF2563eb)),
                  title: Text(tr('تغيير اللغة (العربية / English)', 'Switch Language'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor)),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      isEnglish = !isEnglish;
                      selectedVoiceIndex = isEnglish ? 1 : 0;
                    });
                    await _applyVoiceProfile();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Matrix4 perspectiveMatrix = isFirstPerson3D
        ? (Matrix4.identity()..setEntry(3, 2, 0.00085)..rotateX(-0.50)..scale(1.18))
        : Matrix4.identity();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: landColor,
      drawer: _buildStandardAppDrawer(),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            transformAlignment: Alignment.center,
            transform: perspectiveMatrix,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                backgroundColor: isDark ? const Color(0xFF0D1014) : const Color(0xFFedf5f2),
                initialCenter: me ?? kDefaultCenter,
                initialZoom: currentZoom,
                onTap: (tapPos, point) {
                  if (selectedReportPopupId != null) setState(() => selectedReportPopupId = null);
                  if (pickMode == null) return;
                  final mode = pickMode;
                  setState(() => pickMode = null);
                  if (mode == 'dest') {
                    setState(() {
                      dest = point;
                      destName = tr('موقع محدد على الخريطة', 'Pinned Location');
                      destController.text = destName;
                    });
                    _planRoute();
                  } else if (mode == 'share_spot') {
                    _shareCustomSpot(point, tr('موقع محدد على الخريطة', 'Pinned Location'));
                  }
                },
              ),
              children: [
                // خريطة معرّبة بالكامل للرمادي والعراق بدون مربعات + تبديل ليلي/نهاري لحظي 0ms
                ColorFiltered(
                  colorFilter: isDark ? kFastDarkMapFilter : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: TileLayer(
                    urlTemplate: isEnglish
                        ? 'https://mt{s}.google.com/vt/lyrs=m&hl=en&gl=IQ&x={x}&y={y}&z={z}'
                        : 'https://mt{s}.google.com/vt/lyrs=m&hl=ar&gl=IQ&x={x}&y={y}&z={z}',
                    subdomains: const ['0', '1', '2', '3'],
                    maxZoom: 20,
                    userAgentPackageName: 'com.dlinii.app',
                    tileProvider: _offlineTileProvider,
                  ),
                ),

                // حدود المحافظات المحمّلة بالمسار الأخضر وإخفاء باقي المحافظات + الطرق المزدحمة بالأحمر
                PolylineLayer<Object>(
                  polylines: [
                    ..._buildDownloadedProvinceBordersAndMask(),
                    ..._buildLiveTrafficJamRoadSegments(),
                  ],
                ),

                // المسار الأخضر الصافي + الأصفر للبلاغات حسب أبعادها + الأحمر للازدحام
                if (routes.isNotEmpty)
                  PolylineLayer<Object>(
                    polylines: [
                      Polyline(
                        points: (routes[selectedRouteIndex]['geometry']['coordinates'] as List).map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList(),
                        color: const Color(0xFF10b981),
                        strokeWidth: 9.2,
                        borderColor: const Color(0xFF064e3b),
                        borderStrokeWidth: 2.2,
                      ),
                      ..._buildRealTrafficAndHazardOverlays(
                        routes[selectedRouteIndex] as Map<String, dynamic>,
                        (routes[selectedRouteIndex]['geometry']['coordinates'] as List).map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList(),
                      ),
                    ],
                  ),

                // البلاغات تظهر فقط ضمن 300 متر حولك أو في مسارك
                MarkerLayer(
                  markers: [
                    ...categoryMapMarkers,
                    if (origin != null) Marker(point: origin!, width: 38, height: 38, child: SvgPicture.string(kOriginPinSvg)),
                    if (dest != null) Marker(point: dest!, width: 42, height: 48, child: SvgPicture.string(kDestPinSvg)),
                    ...cloudReports.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _isReportRelevantToUser(LatLng(((data['lat'] ?? 33.4258) as num).toDouble(), ((data['lng'] ?? 43.2995) as num).toDouble()));
                    }).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final pt = LatLng(((data['lat'] ?? 33.4258) as num).toDouble(), ((data['lng'] ?? 43.2995) as num).toDouble());
                      final String rType = data['type']?.toString() ?? 'hazard';
                      final bool isRed = (rType == 'traffic' || rType == 'road_closed' || rType == 'crash');
                      return Marker(
                        point: pt,
                        width: 46,
                        height: 46,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            selectedReportPopupId = doc.id;
                            selectedReportPopupData = data;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: panelColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: isRed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), width: 2.3),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 10)],
                            ),
                            child: _buildReportSvg(rType, size: 28),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                ValueListenableBuilder<_DispState>(
                  valueListenable: _dispState,
                  builder: (context, v, _) => MarkerLayer(
                    markers: [
                      Marker(
                        point: (_hasRealFix || isNavigating) ? v.pos : (me ?? kDefaultCenter),
                        width: 58,
                        height: 58,
                        child: isNavigating
                            ? Transform.rotate(angle: v.bearing * math.pi / 180, child: SvgPicture.string(kGreenNavArrowSvg))
                            : SvgPicture.string(kMyLocationPulseSvg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // الشريط العلوي وبحث الوجهات بتصميم آيفون زجاجي
          if (!isNavigating && !showPlanSheet)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 14,
              left: 14,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: glassColor, border: Border.all(color: lineColor), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            GlassTapButton(
                              width: 37, height: 37, backgroundColor: landColor, borderColor: lineColor,
                              onTap: () => _scaffoldKey.currentState?.openDrawer(),
                              child: Icon(Icons.menu_rounded, color: accentColor, size: 20),
                            ),
                            const SizedBox(width: 8),
                            _buildAppIcon(size: 36),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('دلّيني', 'Dlinii'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.0, color: accentColor)),
                                  Text(tr('رفيقك على طريقك', 'Your road companion'), style: TextStyle(fontSize: 9.5, color: subColor, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            GlassTapButton(
                              width: 37, height: 37, backgroundColor: landColor, borderColor: lineColor,
                              onTap: () => setState(() => showOfflineMapsModal = true),
                              child: const Icon(Icons.cloud_download_rounded, color: Color(0xFFefbb52), size: 18),
                            ),
                            const SizedBox(width: 5),
                            GlassTapButton(
                              width: 37, height: 37, backgroundColor: landColor, borderColor: lineColor,
                              onTap: _shareMyCurrentLocation,
                              child: Icon(Icons.share_location_rounded, color: accentColor, size: 18),
                            ),
                            const SizedBox(width: 5),
                            GlassTapButton(
                              width: 37, height: 37, backgroundColor: landColor, borderColor: lineColor,
                              onTap: () async {
                                setState(() => isDark = !isDark);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('dlini_is_dark_default_v2', isDark);
                              },
                              child: Icon(isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded, color: isDark ? const Color(0xFFefbb52) : accentColor, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: glassColor, border: Border.all(color: lineColor), borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: landColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: lineColor)),
                              child: Row(
                                children: [
                                  SvgPicture.string(kDestPinSvg, width: 15, height: 19),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 28,
                                      child: TextField(
                                        controller: destController,
                                        style: TextStyle(fontSize: 12.5, color: textColor),
                                        onChanged: (v) {
                                          searchDebounce?.cancel();
                                          if (v.trim().length >= 2) {
                                            searchDebounce = Timer(const Duration(milliseconds: 400), () => _searchPlaceGlobal(v.trim()));
                                          } else {
                                            setState(() => showSearchList = false);
                                          }
                                        },
                                        decoration: InputDecoration(hintText: tr('ابحث عن منطقة أو الصق رابط موقع...', 'Search place or paste link...'), hintStyle: TextStyle(fontSize: 12, color: subColor), border: InputBorder.none, isDense: true),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (showSearchList && searchResults.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                constraints: const BoxConstraints(maxHeight: 150),
                                decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: lineColor)),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, idx) {
                                    final item = searchResults[idx];
                                    final String title = item['name']?.toString().isNotEmpty == true ? item['name'] : item['display_name'].toString().split(',').first;
                                    return ListTile(
                                      dense: true,
                                      title: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor)),
                                      subtitle: Text(item['display_name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: subColor)),
                                      onTap: () {
                                        final pt = LatLng(double.parse(item['lat'].toString()), double.parse(item['lon'].toString()));
                                        setState(() {
                                          showSearchList = false;
                                          dest = pt;
                                          destName = title;
                                          destController.text = title;
                                        });
                                        _planRoute();
                                      },
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GlassTapButton(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: landColor, borderColor: lineColor,
                                    onTap: () {
                                      setState(() => pickMode = 'dest');
                                      _toast(tr('اضغط على الخريطة لتحديد الوجهة 📍', 'Tap map to set destination 📍'));
                                    },
                                    child: Text(tr('تحديد وجهة 📍', 'Pick Dest 📍'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: GlassTapButton(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: const Color(0xFF087e76), borderColor: Colors.transparent,
                                    onTap: () {
                                      if (dest != null) {
                                        _shareCustomSpot(dest!, destName);
                                      } else {
                                        setState(() => pickMode = 'share_spot');
                                        _toast(tr('اضغط على أي مكان بالخريطة لإرساله عبر دلّي صديق 🧭', 'Tap map spot to guide a friend 🧭'));
                                      }
                                    },
                                    child: Text(tr('دلّي صديق 🧭', 'Guide Friend 🧭'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 34,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: kExploreCategories.length,
                                itemBuilder: (context, i) {
                                  final cat = kExploreCategories[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: GlassTapButton(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      backgroundColor: landColor, borderColor: lineColor,
                                      onTap: () => _openAndFetchCategory(cat),
                                      child: Text(isEnglish ? cat.nameEn : cat.nameAr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // أزرار التقريب والتبعيد والـ 3D
          Positioned(
            right: 16,
            bottom: 165,
            child: Column(
              children: [
                GlassTapButton(width: 42, height: 42, backgroundColor: glassColor, borderColor: lineColor, onTap: () => mapController.move(mapController.camera.center, (mapController.camera.zoom + 1).clamp(3.0, 19.5)), child: Icon(Icons.add_rounded, size: 21, color: accentColor)),
                const SizedBox(height: 8),
                GlassTapButton(width: 42, height: 42, backgroundColor: glassColor, borderColor: lineColor, onTap: () => mapController.move(mapController.camera.center, (mapController.camera.zoom - 1).clamp(3.0, 19.5)), child: Icon(Icons.remove_rounded, size: 21, color: accentColor)),
                const SizedBox(height: 8),
                GlassTapButton(
                  width: 42, height: 42,
                  backgroundColor: isFirstPerson3D ? const Color(0xFF087e76) : glassColor,
                  borderColor: lineColor,
                  onTap: () => setState(() => isFirstPerson3D = !isFirstPerson3D),
                  child: Text(isFirstPerson3D ? '3D' : '2D', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: isFirstPerson3D ? Colors.white : accentColor)),
                ),
              ],
            ),
          ),

          // أزرار البلاغات وموقعي الحالي
          Positioned(
            left: 16,
            bottom: isNavigating ? 105 : 24,
            child: Row(
              children: [
                GlassTapButton(
                  width: 52, height: 52, isCircle: true,
                  backgroundColor: glassColor, borderColor: const Color(0xFFefbb52),
                  onTap: () => setState(() {
                    reportPoint = me ?? mapController.camera.center;
                    showRepSheet = true;
                  }),
                  child: SvgPicture.string(kReportShieldSvg, width: 24, height: 24),
                ),
                const SizedBox(width: 10),
                GlassTapButton(
                  width: 52, height: 52, isCircle: true,
                  backgroundColor: glassColor, borderColor: accentColor,
                  onTap: () {
                    setState(() => follow = true);
                    _initLocationTracking(userInitiated: true);
                  },
                  child: SvgPicture.string(kGpsTargetSvg, width: 24, height: 24),
                ),
              ],
            ),
          ),

          // شيت انطلاق الرحلة
          if (showPlanSheet)
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: glassColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: lineColor)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(destName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor))),
                            GlassTapButton(width: 32, height: 32, backgroundColor: landColor, borderColor: lineColor, onTap: () => _endNav(arrived: false), child: Icon(Icons.close_rounded, color: textColor, size: 17)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GlassTapButton(
                          width: double.infinity, height: 44, backgroundColor: const Color(0xFF087e76), borderColor: Colors.transparent,
                          onTap: _startNav,
                          child: Text(tr('انطلاق الرحلة الآن 🚘', 'Start Journey 🚘'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        GlassTapButton(
                          width: double.infinity, height: 36, backgroundColor: landColor, borderColor: lineColor,
                          onTap: _startSimulation,
                          child: Text(tr('محاكاة الرحلة ▶️', 'Simulate Journey ▶️'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // واجهة الملاحة الحية
          if (isNavigating)
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: glassColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: lineColor)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$navEta (${tr('الوصول', 'ETA')})', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor)),
                        Text('$navRemMins ${tr('د', 'm')} • $navRemKm ${tr('كم', 'km')}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: accentColor)),
                        GlassTapButton(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), backgroundColor: const Color(0xFFE5484D), borderColor: Colors.transparent, onTap: () => _endNav(arrived: false), child: Text(tr('إنهاء', 'End'), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // شيت البلاغات الـ 9 (يتضمن حفريات، طريق مغلق، كاميرا مراقبة)
          if (showRepSheet)
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: lineColor)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('إرسال تنبيه طريق (ضمن 300م ومسارك) ⚠️', 'Road Alert ⚠️'), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: textColor)),
                            GlassTapButton(width: 32, height: 32, backgroundColor: landColor, borderColor: lineColor, onTap: () => setState(() => showRepSheet = false), child: Icon(Icons.close_rounded, color: textColor, size: 17)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3, shrinkWrap: true, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1,
                          children: [
                            _buildRepGridBtn('bump', tr('مطب 🚧', 'Bump')),
                            _buildRepGridBtn('pothole', tr('حفرة 🕳️', 'Pothole')),
                            _buildRepGridBtn('excavation', tr('حفريات 🚜', 'Excavation')),
                            _buildRepGridBtn('road_closed', tr('طريق مغلق ⛔', 'Closed')),
                            _buildRepGridBtn('camera', tr('كاميرا 📸', 'Camera')),
                            _buildRepGridBtn('crash', tr('حادث 💥', 'Crash')),
                            _buildRepGridBtn('traffic', tr('ازدحام 🚦', 'Traffic')),
                            _buildRepGridBtn('police', tr('نقطة مرور 🚓', 'Police')),
                            _buildRepGridBtn('hazard', tr('خطر آخر ⚠️', 'Hazard')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // نافذة الصوتين الثابتين فقط (صوت فتاة 👩 / صوت رجل 👨) للعربي والإنجليزي
          if (showVoiceModal)
            GestureDetector(
              onTap: () => setState(() => showVoiceModal = false),
              child: Container(
                color: Colors.black.withOpacity(0.55),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(18),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 385),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: lineColor)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('المساعد الصوتي (صوتان ثابتان فقط) 🎙️', 'Voice Assistant (2 Fixed Voices) 🎙️'), style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w900)),
                            GestureDetector(onTap: () => setState(() => showVoiceModal = false), child: Icon(Icons.close_rounded, color: textColor, size: 20)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GlassTapButton(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor: selectedVoiceIndex == 0 ? const Color(0xFF087e76) : landColor,
                                borderColor: accentColor,
                                onTap: () => _selectFixedVoice(0, _voiceSlot['ar_voice'] ?? 0),
                                child: Text(tr('العربية 🇮🇶', 'Arabic 🇮🇶'), style: TextStyle(color: selectedVoiceIndex == 0 ? Colors.white : textColor, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GlassTapButton(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor: selectedVoiceIndex == 1 ? const Color(0xFF087e76) : landColor,
                                borderColor: accentColor,
                                onTap: () => _selectFixedVoice(1, _voiceSlot['en_voice'] ?? 0),
                                child: Text('English 🇬🇧', style: TextStyle(color: selectedVoiceIndex == 1 ? Colors.white : textColor, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GlassTapButton(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: (_voiceSlot[currentVoice.id] ?? 0) == 0 ? accentColor.withOpacity(0.22) : landColor,
                                borderColor: (_voiceSlot[currentVoice.id] ?? 0) == 0 ? accentColor : lineColor,
                                onTap: () => _selectFixedVoice(selectedVoiceIndex, 0),
                                child: Text(tr('صوت فتاة 👩', 'Female Voice 👩'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GlassTapButton(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: (_voiceSlot[currentVoice.id] ?? 0) == 1 ? accentColor.withOpacity(0.22) : landColor,
                                borderColor: (_voiceSlot[currentVoice.id] ?? 0) == 1 ? accentColor : lineColor,
                                onTap: () => _selectFixedVoice(selectedVoiceIndex, 1),
                                child: Text(tr('صوت رجل 👨', 'Male Voice 👨'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GlassTapButton(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: _pinnedSlot.containsKey(currentVoice.id) ? const Color(0xFFefbb52) : landColor,
                          borderColor: const Color(0xFFefbb52),
                          onTap: _togglePinCurrentVoice,
                          child: Text(
                            _pinnedSlot.containsKey(currentVoice.id) ? tr('الصوت مثبّت حالياً 📌 (اضغط لإلغاء التثبيت)', 'Pinned 📌 (Tap to Unpin)') : tr('تثبيت هذا الصوت دائماً 📌', 'Pin This Voice Permanently 📌'),
                            style: TextStyle(color: _pinnedSlot.containsKey(currentVoice.id) ? const Color(0xFF142e2d) : textColor, fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // نافذة تحميل خرائط الـ 18 محافظة بدون نت + تحديد الحدود بالمسار الأخضر
          if (showOfflineMapsModal)
            GestureDetector(
              onTap: () => setState(() => showOfflineMapsModal = false),
              child: Container(
                color: Colors.black.withOpacity(0.55),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(18),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 390, maxHeight: 540),
                    decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: lineColor)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF087e76), Color(0xFF0d2624)]), borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tr('خرائط بدون نت (الـ 18 محافظة) 🗺️', 'Offline Maps (18 Provinces) 🗺️'), style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
                              GestureDetector(onTap: () => setState(() => showOfflineMapsModal = false), child: const Icon(Icons.close_rounded, color: Colors.white, size: 19)),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: kIraqProvinces.length,
                            itemBuilder: (context, idx) {
                              final prov = kIraqProvinces[idx];
                              final bool isSaved = downloadedProvinces.contains(prov.id);
                              final bool isDownloading = downloadingProvinceId == prov.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: landColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSaved ? accentColor : lineColor)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(isEnglish ? prov.nameEn : prov.nameAr, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textColor)),
                                          Text(isSaved ? tr('محملة بحدود خضراء بدون نت ✅ (${prov.sizeMb})', 'Downloaded with green border ✅') : prov.sizeMb, style: TextStyle(fontSize: 10.5, color: isSaved ? accentColor : subColor)),
                                        ],
                                      ),
                                    ),
                                    if (isDownloading)
                                      Text('${(downloadProgress * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w900, color: accentColor))
                                    else if (isSaved)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE5484D)),
                                        onPressed: () async {
                                          setState(() => downloadedProvinces.remove(prov.id));
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setStringList('dlini_offline_provinces', downloadedProvinces.toList());
                                        },
                                      )
                                    else
                                      GlassTapButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        backgroundColor: const Color(0xFF087e76), borderColor: Colors.transparent,
                                        onTap: () => _downloadProvinceOfflineMap(prov),
                                        child: Text(tr('تحميل', 'Download'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // صفحة الهبوط عند فتح رابط مشاركة الموقع أو "دلّي صديق" (بنفس أيقونة الواجهة الرئيسية)
          if (showSharedLandingModal)
            Container(
              color: Colors.black.withOpacity(0.78),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(22),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171C),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF7ce0be).withOpacity(0.45)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAppIcon(size: 72),
                    const SizedBox(height: 14),
                    Text(sharedIncomingTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(tr('تمت مشاركة هذا الموقع معك عبر تطبيق دلّيني، اختر طريقة المتابعة:', 'Shared via Dlinii, choose how to continue:'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF9cdbc0))),
                    const SizedBox(height: 18),
                    GlassTapButton(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF087e76),
                      borderColor: const Color(0xFF7ce0be),
                      onTap: _openInNativeDliniiAppOrStore,
                      child: Text(tr('فتح في تطبيق دلّيني 🚘', 'Open in Dlinii App 🚘'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    GlassTapButton(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      backgroundColor: const Color(0xFF262B33),
                      borderColor: Colors.transparent,
                      onTap: _proceedWithSharedLocationOnWebOrApp,
                      child: Text(tr('الاستمرار مع الويب 🌐', 'Continue with Web 🌐'), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    GlassTapButton(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: Colors.transparent,
                      borderColor: const Color(0xFFefbb52),
                      onTap: () => launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication),
                      child: Text(tr('غير محمّل لديك؟ حمل التطبيق من متجر بلي 📥', 'Download App from Google Play 📥'), style: const TextStyle(color: Color(0xFFefbb52), fontSize: 11.5, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),

          // نافذة إذن الموقع الجغرافي للمستخدم ليظهر موقعه الحالي
          if (showNotifPermissionModal)
            Container(
              color: Colors.black.withOpacity(0.68),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 355),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171C),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF7ce0be).withOpacity(0.38)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAppIcon(size: 60),
                    const SizedBox(height: 12),
                    Text(tr('السماح بإذن الموقع الجغرافي (GPS) 📍', 'Allow GPS Location Permission 📍'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(tr('يرجى الموافقة على إذن الموقع ليظهر موقعك الحالي على الخريطة ويتم تنبيهك على البلاغات ضمن 300 متر ومسارك.', 'Allow location permission to show your current position and nearby road alerts.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF9cdbc0), height: 1.4)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GlassTapButton(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: const Color(0xFF262B33), borderColor: Colors.transparent,
                            onTap: () => setState(() => showNotifPermissionModal = false),
                            child: Text(tr('لاحقاً', 'Later'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassTapButton(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: const Color(0xFF087e76), borderColor: const Color(0xFF7ce0be),
                            onTap: () {
                              setState(() => showNotifPermissionModal = false);
                              _initLocationTracking(userInitiated: true);
                            },
                            child: Text(tr('موافقة وإظهار موقعي 📍', 'Allow & Show GPS 📍'), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (showSplash)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(gradient: RadialGradient(radius: 1.05, colors: [Color(0xFF1d4642), Color(0xFF132d2b), Color(0xFF0b1c1b)])),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAppIcon(size: 80),
                    const SizedBox(height: 14),
                    Text(tr('دلّيني', 'Dlinii'), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(tr('كل طريق… إله دليل', 'Every road has a guide'), style: const TextStyle(fontSize: 15, color: Color(0xFF9cdbc0))),
                    const SizedBox(height: 24),
                    SizedBox(width: 220, height: 95, child: SvgPicture.string(kCarSvg)),
                  ],
                ),
              ),
            ),

          if (isToastVisible)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              left: 30, right: 30,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(color: const Color(0xFF142e2d).withOpacity(0.95), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF7ce0be).withOpacity(0.3))),
                    child: Text(toastMessage, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRepGridBtn(String type, String label) {
    return GlassTapButton(
      onTap: () => _submitCloudReport(type, label),
      backgroundColor: landColor,
      borderColor: lineColor,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildReportSvg(type, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }
}

