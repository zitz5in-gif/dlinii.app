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
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'permissions_helper.dart';

// ==================== أيقونات الفيكتور الهندسية الاحترافية الخاصة بتطبيق دلّيني ====================

const String kLogoSvg =
    '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M16 46C28 46 28 30 40 30C46 30 50 26 50 20" stroke="#7ce0be" stroke-width="6" stroke-linecap="round"/><path d="M14 46L22 39M14 46L22 53" stroke="#7ce0be" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/><path d="M46 8C41 8 37 12 37 17C37 23 46 31 46 31C46 31 55 23 55 17C55 12 51 8 46 8Z" fill="#efbb52"/><circle cx="46" cy="17" r="3.5" fill="#143532"/></svg>';

const String kGreenNavArrowSvg =
    '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="28" fill="#087e76" fill-opacity="0.22"/><circle cx="32" cy="32" r="20" stroke="#9cdbc0" stroke-width="1.5" stroke-opacity="0.5"/><path d="M32 6L52 54L32 43L12 54L32 6Z" fill="#087e76" stroke="#ffffff" stroke-width="3.5" stroke-linejoin="round"/><path d="M32 12L46 48L32 39.5V12Z" fill="#9cdbc0" fill-opacity="0.65"/></svg>';

const String kMyLocationPulseSvg =
    '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="28" fill="#087e76" fill-opacity="0.22"/><circle cx="32" cy="32" r="19" fill="#087e76" fill-opacity="0.38"/><circle cx="32" cy="32" r="12" fill="#087e76" stroke="#ffffff" stroke-width="3.5"/><circle cx="32" cy="32" r="4.5" fill="#9cdbc0"/></svg>';

const String kGpsTargetSvg =
    '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="18" cy="18" r="10" stroke="#087e76" stroke-width="2.5"/><circle cx="18" cy="18" r="4" fill="#efbb52"/><path d="M18 3V7M18 29V33M3 18H7M29 18H33" stroke="#087e76" stroke-width="2.5" stroke-linecap="round"/></svg>';

const String kOriginPinSvg =
    '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="18" cy="18" r="12" fill="#087e76" fill-opacity="0.15"/><circle cx="18" cy="18" r="7" fill="#087e76" stroke="#9cdbc0" stroke-width="2.5"/><circle cx="18" cy="18" r="2.5" fill="#ffffff"/></svg>';

const String kDestPinSvg =
    '<svg viewBox="0 0 36 44" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 2C9.5 2 3 8.5 3 17C3 27.5 18 42 18 42C18 42 33 27.5 33 17C33 8.5 26.5 2 18 2Z" fill="#087e76" stroke="#ffffff" stroke-width="2.5"/><circle cx="18" cy="17" r="6.5" fill="#efbb52"/><circle cx="18" cy="17" r="2.5" fill="#142e2d"/></svg>';

const String kReportShieldSvg =
    '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 4L32 29H4L18 4Z" fill="#efbb52" stroke="#142e2d" stroke-width="2.2" stroke-linejoin="round"/><path d="M18 13V20" stroke="#142e2d" stroke-width="3" stroke-linecap="round"/><circle cx="18" cy="25" r="1.8" fill="#142e2d"/></svg>';

const String kScenePinSvg =
    '<svg viewBox="0 0 36 44" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 2C9 2 3 8 3 17c0 10 15 24 15 24s15-14 15-24C33 8 27 2 18 2Z" fill="#efbb52"/><circle cx="18" cy="17" r="6" fill="#173c37"/></svg>';

const String kCarSvg =
    '<svg viewBox="0 0 280 120" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="carBody" x1="30" y1="30" x2="240" y2="95" gradientUnits="userSpaceOnUse"><stop offset="0%" stop-color="#8cf0d2"/><stop offset="55%" stop-color="#4ec4a5"/><stop offset="100%" stop-color="#2c8f78"/></linearGradient><linearGradient id="carRoof" x1="70" y1="18" x2="195" y2="55" gradientUnits="userSpaceOnUse"><stop offset="0%" stop-color="#b4faea"/><stop offset="100%" stop-color="#5cd1b3"/></linearGradient><linearGradient id="headBeam" x1="235" y1="68" x2="280" y2="75" gradientUnits="userSpaceOnUse"><stop offset="0%" stop-color="#fff3b0" stop-opacity="0.75"/><stop offset="100%" stop-color="#fff3b0" stop-opacity="0"/></linearGradient></defs><g stroke="#64998e" stroke-width="2.5" stroke-linecap="round"><line x1="6" y1="58" x2="28" y2="58"/><line x1="0" y1="70" x2="22" y2="70"/><line x1="10" y1="80" x2="26" y2="80"/></g><polygon points="236,62 280,50 280,84 236,74" fill="url(#headBeam)"/><ellipse cx="140" cy="98" rx="96" ry="7" fill="#0a1c1b" opacity="0.65"/><path d="M72 52 C86 24, 102 18, 146 18 C178 18, 192 28, 208 52 Z" fill="url(#carRoof)"/><path d="M82 50 C93 29, 105 24, 136 24 L136 50 Z" fill="#183f3c"/><path d="M142 24 C170 24, 182 31, 197 50 L142 50 Z" fill="#183f3c"/><polygon points="98,48 112,26 120,26 106,48" fill="#7ce0be" opacity="0.22"/><polygon points="154,48 168,26 175,26 161,48" fill="#7ce0be" opacity="0.22"/><path d="M38 66 C38 55, 48 50, 66 50 L206 50 C226 51, 242 58, 244 72 C245 81, 240 88, 230 88 L48 88 C40 88, 38 80, 38 66 Z" fill="url(#carBody)"/><path d="M46 82 L234 82 C232 86, 227 88, 220 88 L54 88 C48 88, 46 85, 46 82 Z" fill="#1f6e5c"/><line x1="139" y1="22" x2="139" y2="82" stroke="#1f6e5c" stroke-width="2"/><rect x="116" y="57" width="12" height="3.5" rx="1.75" fill="#184942"/><rect x="150" y="57" width="12" height="3.5" rx="1.75" fill="#184942"/><path d="M196 47 C202 45, 207 48, 205 53 L195 53 Z" fill="#3bb395"/><circle cx="152" cy="70" r="8.5" fill="#fff8e0" stroke="#efbb52" stroke-width="2.5"/><path d="M152 65 C149.5 65, 148 66.8, 148 69 C148 71.8, 152 75.5, 152 75.5 C152 75.5, 156 71.8, 156 69 C156 66.8, 154.5 65, 152 65 Z" fill="#d99b26"/><path d="M38 60 C42 60, 44 63, 44 68 C44 72, 41 74,38 74 Z" fill="#ff5a5f"/><path d="M236 62 C241 62, 244 65, 244 70 C244 73, 240 75, 235 73 Z" fill="#fff7c2"/><path d="M62 88 A24 24 0 0 1 110 88 Z" fill="#0d2422"/><path d="M174 88 A24 24 0 0 1 222 88 Z" fill="#0d2422"/><g transform="translate(86, 88)"><circle r="19" fill="#122927" stroke="#0a1817" stroke-width="3"/><circle r="11.5" fill="#d4efe7"/><circle r="4" fill="#087e76"/></g><g transform="translate(198, 88)"><circle r="19" fill="#122927" stroke="#0a1817" stroke-width="3"/><circle r="11.5" fill="#d4efe7"/><circle r="4" fill="#087e76"/></g></svg>';

const Map<String, String> kReportTypeSvgs = {
  'bump':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.18"/><path d="M8 32H13C15.5 23 20.5 23 24 28C27.5 23 32.5 23 35 32H40" stroke="#d99b26" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><line x1="8" y1="36" x2="40" y2="36" stroke="#142e2d" stroke-width="3" stroke-linecap="round"/></svg>',
  'pothole':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#087e76" fill-opacity="0.15"/><ellipse cx="24" cy="30" rx="14" ry="6" fill="#142e2d"/><path d="M13 28L18 32L24 27L30 32L35 28" stroke="#9cdbc0" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M24 12V21M24 21L20 17M24 21L28 17" stroke="#E5484D" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  'crash':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#E5484D" fill-opacity="0.16"/><path d="M24 8L28 17L38 14L32 23L40 30L30 31L29 40L22 33L13 38L16 28L8 23L18 19L24 8Z" fill="#E5484D" stroke="#ffffff" stroke-width="1.5" stroke-linejoin="round"/><circle cx="24" cy="25" r="5" fill="#efbb52"/></svg>',
  'traffic':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.18"/><rect x="17" y="8" width="14" height="32" rx="7" fill="#142e2d" stroke="#087e76" stroke-width="2"/><circle cx="24" cy="15" r="3.2" fill="#E5484D"/><circle cx="24" cy="24" r="3.2" fill="#efbb52"/><circle cx="24" cy="33" r="3.2" fill="#16a34a"/></svg>',
  'police':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#087e76" fill-opacity="0.16"/><path d="M24 9L36 14V24C36 32 24 39 24 39C24 39 12 32 12 24V14L24 9Z" fill="#087e76" stroke="#9cdbc0" stroke-width="2"/><circle cx="24" cy="23" r="4.5" fill="#efbb52"/></svg>',
  'hazard':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.2"/><path d="M24 10L39 36H9L24 10Z" fill="#efbb52" stroke="#142e2d" stroke-width="2.5" stroke-linejoin="round"/><path d="M24 20V27" stroke="#142e2d" stroke-width="3" stroke-linecap="round"/><circle cx="24" cy="32" r="2" fill="#142e2d"/></svg>',
  // بلاغات جديدة
  'excavation':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.18"/><path d="M12 32L18 20L24 28L30 16L36 32" stroke="#d99b26" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/><line x1="10" y1="36" x2="38" y2="36" stroke="#142e2d" stroke-width="3"/></svg>',
  'closed':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#E5484D" fill-opacity="0.16"/><path d="M14 14L34 34M34 14L14 34" stroke="#E5484D" stroke-width="4.5" stroke-linecap="round"/><circle cx="24" cy="24" r="16" stroke="#E5484D" stroke-width="2.5"/></svg>',
  'camera':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#087e76" fill-opacity="0.15"/><rect x="12" y="16" width="24" height="16" rx="3" fill="#087e76" stroke="#9cdbc0" stroke-width="2"/><circle cx="24" cy="24" r="5" fill="#efbb52"/><circle cx="24" cy="24" r="2.5" fill="#142e2d"/><path d="M18 16L20 12H28L30 16" stroke="#9cdbc0" stroke-width="2"/></svg>',
};

// زر زجاجي بنعومة واستجابة لمسية مطابقة لأزرار الآيفون
class GlassTapButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
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

class _GlassTapButtonState extends State<GlassTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    setState(() => _pressed = true);
    _ctrl.forward();
    HapticFeedback.selectionClick();
  }

  void _up(TapUpDetails _) {
    setState(() => _pressed = false);
    _ctrl.reverse();
    widget.onTap();
  }

  void _cancel() {
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(14);
    final bg = widget.backgroundColor ?? Colors.white.withOpacity(0.86);
    final borderCol =
        widget.borderColor ?? const Color(0xFF087e76).withOpacity(0.28);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: widget.isCircle ? BorderRadius.circular(999) : br,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _pressed
                    ? bg.withOpacity((bg.opacity + 0.14).clamp(0.0, 1.0))
                    : bg,
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle ? null : br,
                border: Border.all(
                  color: _pressed ? const Color(0xFFefbb52) : borderCol,
                  width: _pressed ? 1.6 : 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_pressed ? 0.06 : 0.16),
                    blurRadius: _pressed ? 6 : 14,
                    offset: Offset(0, _pressed ? 2 : 4),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// فئات "اكتشف ما حولك"
class ExploreCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String osmQuery;

  const ExploreCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.osmQuery,
  });
}

const List<ExploreCategory> kExploreCategories = [
  ExploreCategory(
    id: 'restaurants',
    nameAr: 'مطاعم',
    nameEn: 'Restaurants',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFea580c),
    osmQuery: 'restaurant',
  ),
  ExploreCategory(
    id: 'hospitals',
    nameAr: 'مستشفيات',
    nameEn: 'Hospitals',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFdc2626),
    osmQuery: 'hospital',
  ),
  ExploreCategory(
    id: 'fuel',
    nameAr: 'وقود',
    nameEn: 'Fuel',
    icon: Icons.local_gas_station_rounded,
    color: Color(0xFF2563eb),
    osmQuery: 'fuel',
  ),
  ExploreCategory(
    id: 'chargers',
    nameAr: 'شواحن',
    nameEn: 'Chargers',
    icon: Icons.ev_station_rounded,
    color: Color(0xFF16a34a),
    osmQuery: 'charging_station',
  ),
  ExploreCategory(
    id: 'mosques',
    nameAr: 'مساجد',
    nameEn: 'Mosques',
    icon: Icons.mosque_rounded,
    color: Color(0xFF087e76),
    osmQuery: 'mosque',
  ),
  ExploreCategory(
    id: 'banks',
    nameAr: 'بنوك',
    nameEn: 'Banks',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFd99b26),
    osmQuery: 'bank',
  ),
  ExploreCategory(
    id: 'shopping',
    nameAr: 'تسوق',
    nameEn: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF9333ea),
    osmQuery: 'supermarket',
  ),
];

// جميع محافظات العراق الـ 18
class IraqProvince {
  final String id;
  final String nameAr;
  final String nameEn;
  final LatLng center;
  final String sizeMb;
  final double radiusDeg;

  const IraqProvince({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.center,
    required this.sizeMb,
    this.radiusDeg = 0.30,
  });
}

const List<IraqProvince> kIraqProvinces = [
  IraqProvince(
      id: 'anbar',
      nameAr: '1. محافظة الأنبار (الرمادي والفلوجة والقائم)',
      nameEn: '1. Al Anbar Governorate',
      center: LatLng(33.4258, 43.2995),
      sizeMb: '45 MB'),
  IraqProvince(
      id: 'baghdad',
      nameAr: '2. محافظة بغداد',
      nameEn: '2. Baghdad Governorate',
      center: LatLng(33.3152, 44.3661),
      sizeMb: '68 MB'),
  IraqProvince(
      id: 'basra',
      nameAr: '3. محافظة البصرة',
      nameEn: '3. Basra Governorate',
      center: LatLng(30.5081, 47.7835),
      sizeMb: '48 MB'),
  IraqProvince(
      id: 'nineveh',
      nameAr: '4. محافظة نينوى (الموصل)',
      nameEn: '4. Nineveh Governorate',
      center: LatLng(36.3489, 43.1577),
      sizeMb: '54 MB'),
  IraqProvince(
      id: 'erbil',
      nameAr: '5. محافظة أربيل',
      nameEn: '5. Erbil Governorate',
      center: LatLng(36.1901, 44.0091),
      sizeMb: '49 MB'),
  IraqProvince(
      id: 'najaf',
      nameAr: '6. محافظة النجف الأشرف',
      nameEn: '6. Najaf Governorate',
      center: LatLng(32.0000, 44.3333),
      sizeMb: '38 MB'),
  IraqProvince(
      id: 'karbala',
      nameAr: '7. محافظة كربلاء المقدسة',
      nameEn: '7. Karbala Governorate',
      center: LatLng(32.6160, 44.0249),
      sizeMb: '36 MB'),
  IraqProvince(
      id: 'sulaymaniyah',
      nameAr: '8. محافظة السليمانية',
      nameEn: '8. Sulaymaniyah Governorate',
      center: LatLng(35.5558, 45.4351),
      sizeMb: '46 MB'),
  IraqProvince(
      id: 'duhok',
      nameAr: '9. محافظة دهوك',
      nameEn: '9. Duhok Governorate',
      center: LatLng(36.8669, 42.9503),
      sizeMb: '35 MB'),
  IraqProvince(
      id: 'kirkuk',
      nameAr: '10. محافظة كركوك',
      nameEn: '10. Kirkuk Governorate',
      center: LatLng(35.4681, 44.3922),
      sizeMb: '40 MB'),
  IraqProvince(
      id: 'salahaddin',
      nameAr: '11. محافظة صلاح الدين (تكريت وسامراء)',
      nameEn: '11. Saladin Governorate',
      center: LatLng(34.6110, 43.6782),
      sizeMb: '41 MB'),
  IraqProvince(
      id: 'diyala',
      nameAr: '12. محافظة ديالى (بعقوبة)',
      nameEn: '12. Diyala Governorate',
      center: LatLng(33.7485, 44.6436),
      sizeMb: '39 MB'),
  IraqProvince(
      id: 'babil',
      nameAr: '13. محافظة بابل (الحلة)',
      nameEn: '13. Babylon Governorate',
      center: LatLng(32.4637, 44.4196),
      sizeMb: '37 MB'),
  IraqProvince(
      id: 'wasit',
      nameAr: '14. محافظة واسط (الكوت)',
      nameEn: '14. Wasit Governorate',
      center: LatLng(32.5126, 45.8182),
      sizeMb: '36 MB'),
  IraqProvince(
      id: 'dhiqar',
      nameAr: '15. محافظة ذي قار (الناصرية)',
      nameEn: '15. Dhi Qar Governorate',
      center: LatLng(31.0439, 46.2573),
      sizeMb: '38 MB'),
  IraqProvince(
      id: 'maysan',
      nameAr: '16. محافظة ميسان (العمارة)',
      nameEn: '16. Maysan Governorate',
      center: LatLng(31.8359, 47.1448),
      sizeMb: '34 MB'),
  IraqProvince(
      id: 'qadisiyyah',
      nameAr: '17. محافظة الديوانية (القادسية)',
      nameEn: '17. Al-Qadisiyyah Governorate',
      center: LatLng(31.9929, 44.9255),
      sizeMb: '33 MB'),
  IraqProvince(
      id: 'muthanna',
      nameAr: '18. محافظة المثنى (السماوة)',
      nameEn: '18. Al Muthanna Governorate',
      center: LatLng(31.3320, 45.2940),
      sizeMb: '32 MB'),
];

// ==================== نظام الصوت الثابت (صوتان فقط) ====================
class VoiceProfile {
  final String id;
  final String nameAr;
  final String nameEn;
  final String locale;
  final String langType; // 'ar' أو 'en'

  const VoiceProfile({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.locale,
    required this.langType,
  });
}

const List<VoiceProfile> kVoiceProfiles = [
  VoiceProfile(
    id: 'ar_voice',
    nameAr: 'المساعد العربي',
    nameEn: 'Arabic Assistant',
    locale: 'ar-SA',
    langType: 'ar',
  ),
  VoiceProfile(
    id: 'en_voice',
    nameAr: 'المساعد الإنجليزي',
    nameEn: 'English Assistant',
    locale: 'en-US',
    langType: 'en',
  ),
];

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

class _Snap {
  final LatLng point;
  final double bearing;
  const _Snap(this.point, this.bearing);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const int endVotesThreshold = 3;
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dlinii.app';
  static const LatLng kDefaultCenter = LatLng(33.4258, 43.2995);

  // ===== الحالة العامة =====
  bool showSplash = true;
  bool isDark = true;
  bool isEnglish = false;
  bool isFirstPerson3D = false;
  bool isPlannerCollapsed = false;
  bool showNotifPermissionModal = false;
  bool showModalBox = false;
  bool showRateModal = false;
  bool showVoiceModal = false;
  bool showPlanSheet = false;
  bool showNavSheet = false;
  bool showRepSheet = false;

  // اكتشف ما حولك
  bool showExploreModal = false;
  String selectedCategoryId = 'restaurants';
  bool isLoadingCategory = false;
  List<Map<String, dynamic>> nearbyCategoryPlaces = [];
  List<Marker> categoryMapMarkers = [];

  // خرائط بدون نت
  bool showOfflineMapsModal = false;
  Set<String> downloadedProvinces = {};
  String? downloadingProvinceId;
  double downloadProgress = 0.0;

  // الاتصال
  bool _forceOffline = false;
  Timer? _connProbeTimer;
  int _exploreReqId = 0;
  final Map<String, List<Map<String, dynamic>>> _exploreCache = {};
  final Map<String, int> _exploreCacheTs = {};
  int _searchReqId = 0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool isListeningVoice = false;
  final _OfflineTileProvider _offlineTileProvider = _OfflineTileProvider();

  IconData modalHeaderIcon = Icons.verified_user_rounded;
  String modalTitle = '';
  List<Map<String, String>> modalSections = [];
  int selectedStars = 5;

  String toastMessage = '';
  bool isToastVisible = false;
  Timer? toastTimer;
  Timer? pulseAnimationTimer;
  double pulseValue = 0.0;

  final MapController mapController = MapController();

  static const String _ofmLightStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  vt.Style? _vtLight;
  vt.Style? _vtDark;
  bool _hasRealFix = false;

  final ValueNotifier<_DispState> _dispState =
      ValueNotifier<_DispState>(const _DispState(kDefaultCenter, 0));
  AnimationController? _glideCtrl;
  LatLng _gStart = kDefaultCenter;
  LatLng _gEnd = kDefaultCenter;
  double _gStartB = 0;
  double _gEndB = 0;
  int _lastFixMs = 0;

  AnimationController? _flyController;
  double currentZoom = 14.5;

  LatLng? me = kDefaultCenter;
  LatLng? origin;
  LatLng? dest;
  LatLng? reportPoint;
  String? pickMode;
  bool follow = true;
  double currentBearing = 0;
  int currentSpeedKmh = 0;
  StreamSubscription<Position>? positionStream;

  final TextEditingController originController = TextEditingController();
  final TextEditingController destController = TextEditingController();
  Timer? searchDebounce;
  String activeSearchField = 'q';
  List<dynamic> searchResults = [];
  bool showSearchList = false;

  List<dynamic> routes = [];
  int selectedRouteIndex = 0;
  String destName = '';
  bool isNavigating = false;
  List<LatLng> navCoords = [];
  List<dynamic> navSteps = [];
  int currentStepIndex = 0;
  int lastSpokenStep = -1;
  Timer? simTimer;

  String hudArrow = '↑';
  String hudInstruction = '—';
  String hudStreet = '';
  String navEta = '—';
  String navRemMins = '—';
  String navRemKm = '—';

  // ===== نظام الصوت الثابت (صوتان فقط) =====
  bool voiceEnabled = true;
  int selectedVoiceIndex = 0; // 0 = عربي ، 1 = إنجليزي
  int voiceGender = 0; // 0 = فتاة ، 1 = رجل
  int voiceSpeedLevel = 1; // 0 = هادئ ، 1 = طبيعي ، 2 = سريع
  final FlutterTts flutterTts = FlutterTts();

  List<QueryDocumentSnapshot> cloudReports = [];
  String? selectedReportPopupId;
  Map<String, dynamic>? selectedReportPopupData;
  int lastReportTimeMs = 0;
  final Set<String> warnedReports = {};

  late AnimationController splashCarController;
  late AnimationController splashRoadController;
  late AnimationController splashPulseController;

  String tr(String ar, String en) => isEnglish ? en : ar;

  VoiceProfile get currentVoice =>
      kVoiceProfiles[selectedVoiceIndex.clamp(0, kVoiceProfiles.length - 1)];

  Color get panelColor => isDark ? const Color(0xFF14171C) : Colors.white;
  Color get glassColor => isDark
      ? const Color(0xFF14171C).withOpacity(0.93)
      : Colors.white.withOpacity(0.92);
  Color get textColor =>
      isDark ? const Color(0xFFF1F5F9) : const Color(0xFF142e2d);
  Color get subColor =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6B7B);
  Color get landColor =>
      isDark ? const Color(0xFF0D1014) : const Color(0xFFedf5f2);
  Color get lineColor =>
      isDark ? const Color(0xFF262B33) : const Color(0xFFd5e6e0);
  Color get accentColor =>
      isDark ? const Color(0xFF63cbb0) : const Color(0xFF087e76);

  // ==================== دورة الحياة ====================

  @override
  void initState() {
    super.initState();
    _loadMapStyles();

    splashCarController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    splashRoadController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat();
    splashPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..forward();

    _loadSavedPrefs();
    _listenToCloudReports();
    _initDeepLinksListener();
    _checkClipboardForSharedLocation();
    _initOfflineTiles();
    _startConnectivityProbe();

    // طلب إذن الموقع فوراً بعد ظهور الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermissionAndStart();
    });

    Future.delayed(const Duration(milliseconds: 2700), () async {
      if (!mounted) return;
      setState(() {
        showSplash = false;
        showNotifPermissionModal = true;
      });
      _toast(tr('مرحباً بك في تطبيق دلّيني – رفيقك على طريقك',
          'Welcome to Dlinii – Your smart road companion'));
      _say(isEnglish
          ? 'Welcome to Dlinii, your smart road companion.'
          : 'مَرْحَبَاً بِكَ فِي تَطْبِيقِ دَلِّينِي، رَفِيقِكَ الذَّكِيِّ عَلَى الطَّرِيقِ.');
    });

    pulseAnimationTimer =
        Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (mounted && routes.isNotEmpty) {
        setState(() => pulseValue = (pulseValue + 0.06) % (2 * math.pi));
      }
    });
  }

  @override
  void dispose() {
    splashCarController.dispose();
    splashRoadController.dispose();
    splashPulseController.dispose();
    _flyController?.dispose();
    pulseAnimationTimer?.cancel();
    positionStream?.cancel();
    simTimer?.cancel();
    searchDebounce?.cancel();
    toastTimer?.cancel();
    originController.dispose();
    destController.dispose();
    _vtLight?.dispose();
    _vtDark?.dispose();
    _glideCtrl?.dispose();
    _dispState.dispose();
    _connProbeTimer?.cancel();
    try {
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  // ==================== إذن الموقع ====================

  Future<void> _requestLocationPermissionAndStart() async {
    if (kIsWeb) return;

    try {
      final res = await PermissionsHelper.ensureLocation();
      if (!mounted) return;

      if (res == LocPermResult.granted) {
        await _initLocationTracking(userInitiated: true);
        if (me != null && _hasRealFix) {
          _flyToMyLocation(me!, targetZoom: 16.0);
        }
      } else {
        // إبقاء النافذة ظاهرة ليوافق المستخدم
        setState(() => showNotifPermissionModal = true);
      }
    } catch (_) {
      setState(() => showNotifPermissionModal = true);
    }
  }

  // ==================== تحميل التفضيلات ====================

  Future<void> _loadSavedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getInt('dlini_voice_idx_v6') ?? 0;
      final savedGender = prefs.getInt('dlini_voice_gender_v6') ?? 0;
      final savedSpeed = prefs.getInt('dlini_voice_speed_lvl') ?? 1;
      final savedLang = prefs.getBool('dlini_is_en') ?? false;
      final savedDark = prefs.getBool('dlini_is_dark_default_v2') ?? true;
      final savedProvs = prefs.getStringList('dlini_offline_provinces') ?? [];

      downloadedProvinces = savedProvs.toSet();

      if (mounted) {
        setState(() {
          selectedVoiceIndex = savedVoice.clamp(0, 1);
          voiceGender = savedGender.clamp(0, 1);
          voiceSpeedLevel = savedSpeed.clamp(0, 2);
          isEnglish = savedLang;
          isDark = savedDark;
        });
      }
    } catch (_) {}

    await _applyVoiceProfile();
  }

  // ==================== نظام الصوت الثابت ====================

  Future<void> _applyVoiceProfile() async {
    try {
      final vp = currentVoice;
      await flutterTts.stop();
      await flutterTts.setLanguage(vp.locale);
      await flutterTts.setVolume(1.0);

      // نبرة ثابتة: فتاة أعلى قليلاً، رجل أقل
      final double pitch = voiceGender == 0 ? 1.18 : 0.82;
      await flutterTts.setPitch(pitch);

      // سرعة ثابتة ومريحة
      double rate;
      if (kIsWeb) {
        rate =
            voiceSpeedLevel == 0 ? 0.92 : (voiceSpeedLevel == 2 ? 1.18 : 1.05);
      } else {
        rate =
            voiceSpeedLevel == 0 ? 0.48 : (voiceSpeedLevel == 2 ? 0.65 : 0.54);
      }
      await flutterTts.setSpeechRate(rate);

      // محاولة اختيار صوت طبيعي إن وجد
      try {
        final dynamic raw = await flutterTts.getVoices;
        if (raw is List) {
          final String targetGender = voiceGender == 0 ? 'female' : 'male';
          for (final v in raw) {
            if (v is! Map) continue;
            final name = (v['name'] ?? '').toString().toLowerCase();
            final loc = (v['locale'] ?? '').toString().toLowerCase();
            final gender = (v['gender'] ?? '').toString().toLowerCase();

            final bool correctLang = vp.langType == 'ar'
                ? loc.startsWith('ar')
                : loc.startsWith('en');

            final bool correctGender = gender.contains(targetGender) ||
                (voiceGender == 0 &&
                    (name.contains('female') ||
                        name.contains('salma') ||
                        name.contains('zira') ||
                        name.contains('aria') ||
                        name.contains('jenny'))) ||
                (voiceGender == 1 &&
                    (name.contains('male') ||
                        name.contains('shakir') ||
                        name.contains('david') ||
                        name.contains('guy') ||
                        name.contains('mark')));

            if (correctLang && correctGender) {
              await flutterTts.setVoice({
                'name': v['name'].toString(),
                'locale': v['locale'].toString(),
              });
              break;
            }
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _say(String text) async {
    if (!voiceEnabled) return;
    try {
      await _applyVoiceProfile();
      await flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> _switchGender() async {
    setState(() => voiceGender = voiceGender == 0 ? 1 : 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_voice_gender_v6', voiceGender);
    await _applyVoiceProfile();

    final label = voiceGender == 0
        ? tr('صوت فتاة', 'Female voice')
        : tr('صوت رجل', 'Male voice');
    _toast(label);

    _say(voiceGender == 0
        ? (isEnglish
            ? 'Female voice selected.'
            : 'تَمَّ اخْتِيَارُ صَوْتِ الْفَتَاةِ.')
        : (isEnglish
            ? 'Male voice selected.'
            : 'تَمَّ اخْتِيَارُ صَوْتِ الرَّجُلِ.'));
  }

  Future<void> _setVoiceSpeedLevel(int level) async {
    setState(() => voiceSpeedLevel = level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_voice_speed_lvl', level);
    await _applyVoiceProfile();
    _say(isEnglish
        ? 'Speech speed updated.'
        : 'تَمَّ ضَبْطُ سُرْعَةِ الصَّوْتِ بِنَجَاحٍ.');
  }

  Future<void> _toggleLanguage() async {
    setState(() {
      isEnglish = !isEnglish;
      selectedVoiceIndex = isEnglish ? 1 : 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dlini_is_en', isEnglish);
    await prefs.setInt('dlini_voice_idx_v6', selectedVoiceIndex);
    await _applyVoiceProfile();
    _toast(isEnglish
        ? 'Language switched to English'
        : 'تم تحويل لغة التطبيق إلى العربية');
  }

  void _toggleVoiceState() {
    setState(() => voiceEnabled = !voiceEnabled);
    if (!voiceEnabled) flutterTts.stop();
    _toast(voiceEnabled
        ? tr('تم تفعيل المساعد الصوتي', 'Voice assistant on')
        : tr('تم كتم المساعد الصوتي', 'Voice muted'));
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
  // ==================== دوال المسافة والاتجاه ====================

  double _distanceMeters(LatLng a, LatLng b) {
    const double R = 6371000;
    const double r = math.pi / 180;
    final double dLat = (b.latitude - a.latitude) * r;
    final double dLon = (b.longitude - a.longitude) * r;
    final double x = math.pow(math.sin(dLat / 2), 2) +
        math.cos(a.latitude * r) *
            math.cos(b.latitude * r) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * R * math.asin(math.sqrt(x));
  }

  double _getBearing(LatLng start, LatLng end) {
    double toRad(double d) => d * math.pi / 180;
    double toDeg(double r) => r * 180 / math.pi;
    final lat1 = toRad(start.latitude);
    final lon1 = toRad(start.longitude);
    final lat2 = toRad(end.latitude);
    final lon2 = toRad(end.longitude);
    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);
    return (toDeg(math.atan2(y, x)) + 360) % 360;
  }

  double _lerpAngle(double a, double b, double t) {
    final double d = ((b - a + 540) % 360) - 180;
    return (a + d * t + 360) % 360;
  }

  LatLng _lookAhead(LatLng p, double bearingDeg, double meters) {
    final double br = bearingDeg * math.pi / 180;
    final double dLat = meters * math.cos(br) / 111320.0;
    final double dLng = meters *
        math.sin(br) /
        (111320.0 * math.max(0.2, math.cos(p.latitude * math.pi / 180)));
    return LatLng(p.latitude + dLat, p.longitude + dLng);
  }

  // ==================== تسميات البلاغات ====================

  String _getReportLabel(String? type, String? fallback) {
    if (!isEnglish && fallback != null && fallback.isNotEmpty) return fallback;
    switch (type) {
      case 'bump':
        return tr('مطب', 'Speed Bump');
      case 'pothole':
        return tr('حفرة', 'Pothole');
      case 'crash':
        return tr('حادث', 'Crash');
      case 'traffic':
        return tr('ازدحام', 'Traffic Jam');
      case 'police':
        return tr('نقطة مرور', 'Police / Patrol');
      case 'excavation':
        return tr('حفريات', 'Excavation');
      case 'closed':
        return tr('طريق مغلق', 'Road Closed');
      case 'camera':
        return tr('كاميرا مراقبة', 'Surveillance Camera');
      default:
        return tr('خطر', 'Road Hazard');
    }
  }

  Widget _buildReportSvg(String? type, {double size = 28}) {
    return SvgPicture.string(
      kReportTypeSvgs[type] ?? kReportTypeSvgs['hazard']!,
      width: size,
      height: size,
    );
  }

  // ==================== فلترة البلاغات (300 متر فقط) ====================

  List<Marker> _buildReportMarkers() {
    final List<Marker> markers = [];
    final LatLng center = me ?? mapController.camera.center;

    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final LatLng pt = LatLng(
        ((data['lat'] ?? 33.42) as num).toDouble(),
        ((data['lng'] ?? 43.29) as num).toDouble(),
      );

      // الشرط الأساسي: فقط داخل 300 متر من المستخدم
      final double dist = _distanceMeters(center, pt);
      if (dist > 300) continue;

      // إذا كان في وضع الملاحة: يظهر فقط إذا كان قريباً من المسار
      if (isNavigating && navCoords.isNotEmpty) {
        bool nearRoute = false;
        for (final p in navCoords) {
          if (_distanceMeters(p, pt) < 90) {
            nearRoute = true;
            break;
          }
        }
        if (!nearRoute) continue;
      }

      final String type = data['type']?.toString() ?? 'hazard';

      markers.add(
        Marker(
          point: pt,
          width: 38,
          height: 38,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedReportPopupId = doc.id;
                selectedReportPopupData = data;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildReportSvg(type, size: 34),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  // ==================== تلوين المسار (أخضر / أصفر / أحمر) ====================

  List<Polyline> _buildRouteOverlays(
      Map<String, dynamic> selectedRoute, List<LatLng> routePoints) {
    final List<Polyline> overlays = [];
    if (routePoints.length < 2) return overlays;

    // 1. المسار الأساسي دائماً أخضر
    overlays.add(
      Polyline(
        points: routePoints,
        color: const Color(0xFF087e76),
        strokeWidth: 7.5,
      ),
    );

    // 2. تلوين أجزاء السرعة البطيئة (ازدحام) بالأحمر
    try {
      final legs = selectedRoute['legs'] as List?;
      if (legs != null && legs.isNotEmpty) {
        final steps = legs[0]['steps'] as List?;
        if (steps != null) {
          for (final st in steps) {
            final double dist = ((st['distance'] ?? 0) as num).toDouble();
            final double dur = ((st['duration'] ?? 0) as num).toDouble();
            if (dist > 40 && dur > 0) {
              final double speedKmh = (dist / dur) * 3.6;
              final geom = st['geometry']?['coordinates'] as List?;
              if (geom != null && geom.length >= 2) {
                final stepPts = geom
                    .map((c) => LatLng(
                        (c[1] as num).toDouble(), (c[0] as num).toDouble()))
                    .toList();

                if (speedKmh < 16.0) {
                  // أحمر قوي للازدحام الشديد
                  overlays.add(Polyline(
                    points: stepPts,
                    color: const Color(0xFFE5484D),
                    strokeWidth: 9.5,
                  ));
                } else if (speedKmh < 26.0) {
                  // أصفر للبطء
                  overlays.add(Polyline(
                    points: stepPts,
                    color: const Color(0xFFefbb52),
                    strokeWidth: 8.5,
                  ));
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    // 3. تلوين أجزاء المسار القريبة من البلاغات
    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final LatLng repPt = LatLng(
        ((data['lat'] ?? 33.42) as num).toDouble(),
        ((data['lng'] ?? 43.29) as num).toDouble(),
      );
      final String type = data['type']?.toString() ?? 'hazard';

      final List<LatLng> affected = [];
      for (final p in routePoints) {
        if (_distanceMeters(p, repPt) <= 220) {
          affected.add(p);
        }
      }

      if (affected.length >= 2) {
        final bool isTraffic = type == 'traffic';
        final bool isClosed = type == 'closed';
        overlays.add(
          Polyline(
            points: affected,
            color: (isTraffic || isClosed)
                ? const Color(0xFFE5484D)
                : const Color(0xFFefbb52),
            strokeWidth: 9.0,
          ),
        );
      }
    }

    return overlays;
  }

  // ==================== تتبع الموقع ====================

  Future<void> _initLocationTracking({bool userInitiated = false}) async {
    try {
      final res = await PermissionsHelper.ensureLocation();
      if (!mounted) return;

      if (res != LocPermResult.granted) {
        if (userInitiated) {
          _toast(res == LocPermResult.serviceOff
              ? tr('شغّل خدمة الموقع (GPS)', 'Turn on location (GPS)')
              : tr('الموقع مرفوض، فعّله من إعدادات التطبيق',
                  'Location denied, enable it in app settings'));
          if (res == LocPermResult.serviceOff) {
            PermissionsHelper.openLocationSettings();
          } else if (res == LocPermResult.deniedForever) {
            PermissionsHelper.openAppSettings();
          }
        }
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _onPositionUpdate(
          LatLng(lastKnown.latitude, lastKnown.longitude),
          lastKnown.speed,
          lastKnown.heading,
          isFirst: true,
        );
      }

      await positionStream?.cancel();
      bool gotFirst = _hasRealFix;

      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen((Position pos) {
        if (simTimer != null) return;
        _onPositionUpdate(
          LatLng(pos.latitude, pos.longitude),
          pos.speed,
          pos.heading,
          isFirst: !gotFirst,
        );
        gotFirst = true;
      }, onError: (_) {});

      try {
        final Position pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 12),
        );
        if (!gotFirst) {
          gotFirst = true;
          _onPositionUpdate(
            LatLng(pos.latitude, pos.longitude),
            pos.speed,
            pos.heading,
            isFirst: true,
          );
        }
      } catch (_) {}
    } catch (_) {}
  }

  void _onPositionUpdate(LatLng rawMe, double speedMps, double heading,
      {bool isFirst = false}) {
    if (!mounted) return;
    _hasRealFix = true;

    LatLng nextMe = rawMe;
    double? routeBearing;

    if (isNavigating) {
      final snap = _snapToRoute(rawMe);
      if (snap != null) {
        nextMe = snap.point;
        routeBearing = snap.bearing;
      }
    }

    double newBearing = currentBearing;
    if (routeBearing != null) {
      newBearing = routeBearing;
    } else if (heading >= 0 && !heading.isNaN) {
      newBearing = heading;
    } else if (me != null && _distanceMeters(me!, nextMe) > 2) {
      newBearing = _getBearing(me!, nextMe);
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int gap = (nowMs - _lastFixMs).clamp(250, 1500).toInt();
    _lastFixMs = nowMs;

    setState(() {
      currentBearing = newBearing;
      me = nextMe;
      currentSpeedKmh = math.max(0, (speedMps * 3.6).round());
    });

    if (isFirst) {
      _glideCtrl?.stop();
      _dispState.value = _DispState(nextMe, newBearing);
      if (!isNavigating) mapController.move(nextMe, 15.5);
    } else {
      _glideTo(nextMe, newBearing, (gap * 1.08).round());
    }

    if (!isNavigating) return;
    _updateNavigationState();
    _checkNearbyReports(nextMe);
  }

  _Snap? _snapToRoute(LatLng p) {
    if (navCoords.length < 2) return null;
    final double cosLat = math.cos(p.latitude * math.pi / 180);
    double best = 1e18;
    LatLng? bp;
    double bb = 0;

    for (int i = 0; i < navCoords.length - 1; i++) {
      final a = navCoords[i];
      final b = navCoords[i + 1];
      final ax = (a.longitude - p.longitude) * cosLat * 111320.0;
      final ay = (a.latitude - p.latitude) * 111320.0;
      final bx = (b.longitude - p.longitude) * cosLat * 111320.0;
      final by = (b.latitude - p.latitude) * 111320.0;
      final dx = bx - ax;
      final dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final double t = len2 == 0
          ? 0.0
          : ((-ax * dx - ay * dy) / len2).clamp(0.0, 1.0).toDouble();
      final px = ax + dx * t;
      final py = ay + dy * t;
      final d = px * px + py * py;
      if (d < best) {
        best = d;
        bp = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
        bb = _getBearing(a, b);
      }
    }
    if (bp == null || best > 35 * 35) return null;
    return _Snap(bp, bb);
  }

  void _glideTo(LatLng target, double targetBearing, int ms) {
    final ctrl = _glideCtrl ??= AnimationController(vsync: this)
      ..addListener(_glideTick);
    _gStart = _dispState.value.pos;
    _gStartB = _dispState.value.bearing;
    _gEnd = target;
    _gEndB = targetBearing;
    ctrl.duration = Duration(milliseconds: ms);
    ctrl.forward(from: 0);
  }

  void _glideTick() {
    final double t = _glideCtrl?.value ?? 1.0;
    final LatLng pos = LatLng(
      _gStart.latitude + (_gEnd.latitude - _gStart.latitude) * t,
      _gStart.longitude + (_gEnd.longitude - _gStart.longitude) * t,
    );
    final double b = _lerpAngle(_gStartB, _gEndB, Curves.easeOut.transform(t));
    _dispState.value = _DispState(pos, b);

    if (follow && (isNavigating || isFirstPerson3D)) {
      final double z = mapController.camera.zoom;
      if (isFirstPerson3D) {
        mapController.moveAndRotate(_lookAhead(pos, b, 28), z, -b);
      } else {
        mapController.move(pos, z);
      }
    }
  }

  // ==================== تنبيه البلاغات القريبة ====================

  void _checkNearbyReports(LatLng currentPos) {
    if (!isNavigating) return;
    final bool enMode = isEnglish || currentVoice.langType == 'en';

    for (var doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final LatLng repPos = LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      );
      final double dist = _distanceMeters(currentPos, repPos);
      final String repId = doc.id;
      final String type = data['type'] ?? '';
      final String label = _getReportLabel(type, data['label']?.toString());

      double alertDist = 160;
      String msg =
          enMode ? 'Caution, $label ahead' : 'اِحْذَرْ، أَمَامَكَ $label';

      if (type == 'bump') {
        alertDist = 110;
        msg = enMode
            ? 'Speed bump 100 meters ahead'
            : 'اِنْتَبِهْ، أَمَامَكَ مَطَبٌّ بَعْدَ مِائَةِ مِتْرٍ';
      } else if (type == 'pothole' || type == 'excavation') {
        alertDist = 150;
        msg = enMode
            ? 'Road works / pothole ahead'
            : 'اِنْتَبِهْ، حُفْرِيَّاتٌ أَوْ حُفْرَةٌ أَمَامَكَ';
      } else if (type == 'crash') {
        alertDist = 200;
        msg =
            enMode ? 'Warning, accident ahead' : 'تَحْذِيرٌ، حَادِثٌ أَمَامَكَ';
      } else if (type == 'police') {
        alertDist = 240;
        msg = enMode
            ? 'Traffic checkpoint ahead'
            : 'اِنْتَبِهْ، نُقْطَةُ مُرُورٍ أَمَامَكَ';
      } else if (type == 'closed') {
        alertDist = 250;
        msg = enMode
            ? 'Road closed ahead'
            : 'تَحْذِيرٌ، الطَّرِيقُ مُغْلَقٌ أَمَامَكَ';
      } else if (type == 'camera') {
        alertDist = 180;
        msg = enMode
            ? 'Surveillance camera ahead'
            : 'كَامِيرَا مُرَاقَبَةٍ أَمَامَكَ';
      } else if (type == 'traffic') {
        alertDist = 220;
        msg =
            enMode ? 'Heavy traffic ahead' : 'اِزْدِحَامٌ مَرُورِيٌّ أَمَامَكَ';
      }

      if (dist <= alertDist && !warnedReports.contains(repId)) {
        warnedReports.add(repId);
        _say(msg);
        _toast(msg);
      }
    }
  }
  // ==================== نظام الخرائط بدون نت ====================

  Future<void> _initOfflineTiles() async {
    await _OfflineTiles.init();
    if (mounted) setState(() {});
  }

  Future<void> _downloadProvinceOfflineMap(IraqProvince prov) async {
    if (downloadingProvinceId != null) return;
    if (kIsWeb) {
      _toast(tr('تحميل الخرائط متاح في تطبيق الهاتف فقط',
          'Offline download is available in the mobile app'));
      return;
    }

    setState(() {
      downloadingProvinceId = prov.id;
      downloadProgress = 0.02;
    });

    bool ok = false;
    try {
      ok = await _OfflineTiles.downloadProvince(prov, onProgress: (p) {
        if (mounted) setState(() => downloadProgress = p);
      });
    } catch (_) {}

    if (!mounted) return;

    if (ok) {
      downloadedProvinces.add(prov.id);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            'dlini_offline_provinces', downloadedProvinces.toList());
      } catch (_) {}

      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });

      _flyToMyLocation(prov.center, targetZoom: 12.8);
      _toast(tr('تم تحميل خريطة «${prov.nameAr}» بنجاح ✅',
          '${prov.nameEn} offline map downloaded ✅'));
    } else {
      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });
      _toast(tr('فشل التحميل، تأكد من الإنترنت وحاول مرة ثانية',
          'Download failed, check connection and retry'));
    }
  }

  Future<void> _deleteProvinceOfflineMap(IraqProvince prov) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      downloadedProvinces.remove(prov.id);
    });
    await prefs.setStringList(
        'dlini_offline_provinces', downloadedProvinces.toList());
    try {
      await _OfflineTiles.deleteProvince(prov, downloadedProvinces);
    } catch (_) {}
    _toast(tr(
        'تم حذف خريطة ${prov.nameAr}', 'Removed ${prov.nameEn} offline map'));
  }

  /// يرسم حدود المحافظة المحمّلة فقط باللون الأخضر
  List<Polyline> _buildProvinceBorders() {
    final List<Polyline> borders = [];
    for (final prov in kIraqProvinces) {
      if (!downloadedProvinces.contains(prov.id)) continue;

      // مستطيل تقريبي حول مركز المحافظة
      final double r = prov.radiusDeg;
      final List<LatLng> rect = [
        LatLng(prov.center.latitude + r, prov.center.longitude - r),
        LatLng(prov.center.latitude + r, prov.center.longitude + r),
        LatLng(prov.center.latitude - r, prov.center.longitude + r),
        LatLng(prov.center.latitude - r, prov.center.longitude - r),
        LatLng(prov.center.latitude + r, prov.center.longitude - r),
      ];

      borders.add(
        Polyline(
          points: rect,
          color: const Color(0xFF087e76),
          strokeWidth: 3.2,
          isDotted: true,
        ),
      );
    }
    return borders;
  }

  // ==================== تبديل الوضع الليلي/النهاري السلس ====================

  Future<void> _toggleTheme() async {
    // تبديل فوري بدون انتظار
    setState(() => isDark = !isDark);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dlini_is_dark_default_v2', isDark);

    // إعادة تحميل الستايل بسرعة
    if (_vtLight == null || _vtDark == null) {
      _loadMapStyles();
    }
  }

  Future<void> _loadMapStyles() async {
    try {
      final light = await vt.StyleReader(uri: _ofmLightStyleUrl).read();
      if (!mounted) {
        light.dispose();
        return;
      }
      setState(() => _vtLight = light);
    } catch (_) {}

    try {
      final res = await http.get(Uri.parse(_ofmLightStyleUrl));
      if (res.statusCode == 200) {
        final Map<String, dynamic> styleJson = json.decode(res.body);
        final List<dynamic> layers = styleJson['layers'] ?? [];

        for (final layer in layers) {
          if (layer is! Map<String, dynamic>) continue;
          final String id = (layer['id'] ?? '').toString().toLowerCase();
          final String type = (layer['type'] ?? '').toString().toLowerCase();
          final Map<String, dynamic> paint =
              (layer['paint'] as Map<String, dynamic>?) ?? {};

          if (type == 'background') {
            paint['background-color'] = '#0D1014';
          } else if (id.contains('water') ||
              id.contains('river') ||
              id.contains('stream') ||
              id.contains('canal')) {
            if (type == 'fill') {
              paint['fill-color'] = '#2578A6';
            } else if (type == 'line') {
              paint['line-color'] = '#2B8CBE';
            }
          } else if (id.contains('park') ||
              id.contains('wood') ||
              id.contains('grass') ||
              id.contains('landcover') ||
              id.contains('landuse')) {
            if (type == 'fill') {
              paint['fill-color'] = '#12171B';
            }
          } else if (id.contains('building')) {
            if (type == 'fill') {
              paint['fill-color'] = '#171B21';
              paint['fill-outline-color'] = '#1F242C';
            }
          } else if (id.contains('road') ||
              id.contains('highway') ||
              id.contains('street') ||
              id.contains('transportation') ||
              id.contains('bridge') ||
              id.contains('tunnel') ||
              id.contains('motorway') ||
              id.contains('trunk') ||
              id.contains('primary') ||
              id.contains('secondary') ||
              id.contains('tertiary')) {
            if (type == 'line') {
              if (id.contains('casing') || id.contains('outline')) {
                paint['line-color'] = '#14181E';
              } else if (id.contains('motorway') ||
                  id.contains('trunk') ||
                  id.contains('primary')) {
                paint['line-color'] = '#343C47';
              } else {
                paint['line-color'] = '#262C35';
              }
            }
          } else if (id.contains('boundary') || id.contains('border')) {
            if (type == 'line') {
              paint['line-color'] = '#2D3540';
            }
          } else if (type == 'symbol') {
            paint['text-color'] = '#CBD5E1';
            paint['text-halo-color'] = '#0D1014';
            paint['text-halo-width'] = 1.5;
          }
          layer['paint'] = paint;
        }

        final darkTheme = vt.ThemeReader().read(styleJson);
        final baseLight =
            _vtLight ?? await vt.StyleReader(uri: _ofmLightStyleUrl).read();
        final customDarkStyle = vt.Style(
          theme: darkTheme,
          providers: baseLight.providers,
          sprites: baseLight.sprites,
          rasterSources: baseLight.rasterSources,
          name: 'dlinii_dark',
          center: baseLight.center,
          zoom: baseLight.zoom,
        );
        if (mounted) {
          setState(() => _vtDark = customDarkStyle);
        }
      }
    } catch (_) {}
  }

  // ==================== تخطيط المسار ====================

  static const String _kRouteCacheKey = 'dlini_route_cache_v1';

  Future<void> _planRoute({LatLng? fromPoint}) async {
    final LatLng o = fromPoint ?? origin ?? me ?? mapController.camera.center;
    if (dest == null) return;
    final LatLng d = dest!;
    List<dynamic>? found;
    String source = 'online';

    // 1) محاولة أونلاين
    if (!_forceOffline) {
      try {
        final url = Uri.parse(
            'https://router.project-osrm.org/route/v1/driving/${o.longitude},${o.latitude};${d.longitude},${d.latitude}?overview=full&geometries=geojson&steps=true&alternatives=true');
        final res = await http.get(url).timeout(const Duration(seconds: 9));
        final data = json.decode(res.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          found = List<dynamic>.from(data['routes'] as List);
          _saveRouteToCache(o, d, found.first);
        } else if (data['code'] == 'NoRoute') {
          _toast(tr('لا يوجد مسار بري متاح إلى هذه الوجهة', 'No route found'));
          return;
        }
      } catch (_) {}
    }

    // 2) بدون إنترنت: مسار محفوظ أو احتياطي
    if (found == null) {
      final Map<String, dynamic>? cachedRoute = await _loadRouteFromCache(o, d);
      if (cachedRoute != null) {
        found = [cachedRoute];
        source = 'cache';
      } else {
        found = [_buildOfflineFallbackRoute(o, d)];
        source = 'fallback';
      }
      _toast(source == 'cache'
          ? tr('لا يوجد إنترنت: تم استخدام مسار محفوظ 🗂️',
              'Offline: using saved route 🗂️')
          : tr('لا يوجد إنترنت: مسار احتياطي تقريبي 🧭',
              'Offline: approximate fallback route 🧭'));
    }

    if (!mounted) return;

    setState(() {
      routes = found!;
      selectedRouteIndex = 0;
      showExploreModal = false;
      if (!isNavigating) showPlanSheet = true;
    });

    final List<dynamic> coordsList = routes[0]['geometry']['coordinates'];
    if (coordsList.isNotEmpty) {
      final points = coordsList
          .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      mapController.rotate(0);
      mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding:
            const EdgeInsets.only(top: 80, bottom: 260, left: 40, right: 40),
      ));
    }
  }

  Map<String, dynamic> _mkStep(String type, String modifier, LatLng loc,
      String name, double dist, double dur) {
    return {
      'maneuver': {
        'type': type,
        'modifier': modifier,
        'location': [loc.longitude, loc.latitude],
      },
      'name': name,
      'distance': dist,
      'duration': dur,
    };
  }

  Future<void> _saveRouteToCache(LatLng o, LatLng d, dynamic route) async {
    try {
      final Map<String, dynamic> copy =
          json.decode(json.encode(route)) as Map<String, dynamic>;
      final legs = copy['legs'];
      if (legs is List) {
        for (final leg in legs) {
          if (leg is Map && leg['steps'] is List) {
            for (final st in leg['steps'] as List) {
              if (st is Map) {
                st.remove('geometry');
                st.remove('intersections');
                st.remove('driving_side');
              }
            }
          }
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kRouteCacheKey);
      final List<dynamic> list =
          raw != null ? (json.decode(raw) as List<dynamic>) : <dynamic>[];
      list.removeWhere((e) =>
          e is Map &&
          _distanceMeters(
                  LatLng((e['oLat'] as num).toDouble(),
                      (e['oLng'] as num).toDouble()),
                  o) <
              150 &&
          _distanceMeters(
                  LatLng((e['dLat'] as num).toDouble(),
                      (e['dLng'] as num).toDouble()),
                  d) <
              150);
      list.insert(0, {
        'oLat': o.latitude,
        'oLng': o.longitude,
        'dLat': d.latitude,
        'dLng': d.longitude,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'route': copy,
      });
      while (list.length > 8) {
        list.removeLast();
      }
      await prefs.setString(_kRouteCacheKey, json.encode(list));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadRouteFromCache(LatLng o, LatLng d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kRouteCacheKey);
      if (raw == null) return null;
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      for (final e in list) {
        if (e is! Map) continue;
        final LatLng cd = LatLng(
            (e['dLat'] as num).toDouble(), (e['dLng'] as num).toDouble());
        if (_distanceMeters(cd, d) > 400) continue;
        final Map<String, dynamic> route =
            Map<String, dynamic>.from(e['route'] as Map);
        final List<dynamic> coords = route['geometry']['coordinates'] as List;
        final pts = coords
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        int bi = 0;
        double bd = 1e18;
        for (int i = 0; i < pts.length; i++) {
          final double dd = _distanceMeters(o, pts[i]);
          if (dd < bd) {
            bd = dd;
            bi = i;
          }
        }
        if (bd > 350) continue;
        return _trimRouteFrom(route, pts, bi, o);
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _trimRouteFrom(
      Map<String, dynamic> route, List<LatLng> pts, int from, LatLng o) {
    final List<LatLng> rest = [o, ...pts.sublist(from)];
    double remain = 0;
    for (int i = 0; i < rest.length - 1; i++) {
      remain += _distanceMeters(rest[i], rest[i + 1]);
    }
    double fullLen = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      fullLen += _distanceMeters(pts[i], pts[i + 1]);
    }
    final double totalD = ((route['distance'] ?? 0) as num).toDouble();
    final double totalT = ((route['duration'] ?? 0) as num).toDouble();
    final double ratio =
        fullLen > 0 ? (remain / fullLen).clamp(0.0, 1.0).toDouble() : 1.0;

    final List<dynamic> oldSteps = [];
    final legs = route['legs'];
    if (legs is List && legs.isNotEmpty && legs[0]['steps'] is List) {
      oldSteps.addAll(legs[0]['steps'] as List);
    }
    final List<dynamic> steps = [_mkStep('depart', 'straight', o, '', 0, 0)];
    for (final st in oldSteps) {
      final loc = st['maneuver']?['location'];
      if (loc is! List || st['maneuver']['type'] == 'depart') continue;
      final LatLng p =
          LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
      int idx = from;
      double bd = 1e18;
      for (int i = from; i < pts.length; i++) {
        final double dd = _distanceMeters(p, pts[i]);
        if (dd < bd) {
          bd = dd;
          idx = i;
        }
      }
      if (bd < 40 && idx > from) steps.add(st);
    }
    final lastType = (steps.last['maneuver']['type'] ?? '').toString();
    if (lastType != 'arrive') {
      steps.add(_mkStep('arrive', 'straight', pts.last, '', 0, 0));
    }

    return {
      'distance': totalD * ratio,
      'duration': totalT * ratio,
      'geometry': {
        'type': 'LineString',
        'coordinates': rest.map((p) => [p.longitude, p.latitude]).toList(),
      },
      'legs': [
        {
          'steps': steps,
          'distance': totalD * ratio,
          'duration': totalT * ratio,
        }
      ],
      'dlinii_source': 'cache',
    };
  }

  Map<String, dynamic> _buildOfflineFallbackRoute(LatLng o, LatLng d) {
    final double straight = _distanceMeters(o, d);
    final double roadMeters = straight * 1.3;
    final double speedMps = (straight > 15000 ? 70.0 : 40.0) / 3.6;
    final double durSec = roadMeters / speedMps;
    final int n = math.max(2, (straight / 150).ceil());
    final List<List<double>> coords = [];
    for (int i = 0; i <= n; i++) {
      final double t = i / n;
      coords.add([
        o.longitude + (d.longitude - o.longitude) * t,
        o.latitude + (d.latitude - o.latitude) * t,
      ]);
    }
    final List<dynamic> steps = [_mkStep('depart', 'straight', o, '', 0, 0)];
    final int mids = (straight / 2500).floor();
    for (int k = 1; k <= mids; k++) {
      final double t = k / (mids + 1);
      final LatLng p = LatLng(o.latitude + (d.latitude - o.latitude) * t,
          o.longitude + (d.longitude - o.longitude) * t);
      steps.add(_mkStep('continue', 'straight', p, '', roadMeters / (mids + 1),
          durSec / (mids + 1)));
    }
    steps.add(_mkStep('arrive', 'straight', d, '', 0, 0));
    return {
      'distance': roadMeters,
      'duration': durSec,
      'geometry': {'type': 'LineString', 'coordinates': coords},
      'legs': [
        {'steps': steps, 'distance': roadMeters, 'duration': durSec}
      ],
      'dlinii_source': 'fallback',
    };
  }

  // ==================== بدء وإنهاء الملاحة ====================

  void _startNav() {
    if (routes.isEmpty) return;
    final r = routes[selectedRouteIndex];
    final List<dynamic> rawCoords = r['geometry']['coordinates'];
    navCoords = rawCoords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    me ??= origin ??
        (navCoords.isNotEmpty ? navCoords.first : mapController.camera.center);
    navSteps = r['legs'][0]['steps'];
    currentStepIndex = 0;
    lastSpokenStep = -1;
    if (navCoords.length > 1) {
      currentBearing = _getBearing(navCoords[0], navCoords[1]);
    }
    setState(() {
      isNavigating = true;
      isFirstPerson3D = true;
      follow = true;
      showPlanSheet = false;
      showNavSheet = true;
    });
    _glideCtrl?.stop();
    _dispState.value = _DispState(me!, currentBearing);
    mapController.moveAndRotate(
        _lookAhead(me!, currentBearing, 28), 17.8, -currentBearing);

    final initialStep = navSteps.length > 1 ? navSteps[1] : navSteps[0];
    final info = _getManeuverText(initialStep);
    final startPrefix = (isEnglish || currentVoice.langType == 'en')
        ? 'Starting navigation. '
        : 'بَدَأَتِ الرِّحْلَةُ، رَافَقَتْكَ السَّلَامَةُ. ';
    _say('$startPrefix${info[0]}');
    _updateNavigationState();
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
    mapController.rotate(0);
    if (me != null) mapController.move(me!, 14.5);

    if (arrived) {
      final msg = tr('الحمد لله على سلامتك، لقد وصلت إلى وجهتك بالسلامة',
          'Thank God for your safety, you have arrived safely');
      _toast(msg);
      _say(isEnglish
          ? 'Thank God for your safety, you have arrived at your destination safely.'
          : 'الْحَمْدُ لِلَّهِ عَلَى سَلَامَتِكَ، لَقَدْ وَصَلْتَ إِلَى وِجْهَتِكَ بِالسَّلَامَةِ.');
      setState(() {
        selectedStars = 5;
        showRateModal = true;
      });
    }
  }

  void _flyToMyLocation(LatLng target, {double targetZoom = 16.8}) {
    _flyController?.dispose();
    final startCenter = mapController.camera.center;
    final startZoom = mapController.camera.zoom;
    final startRot = mapController.camera.rotation;
    final endRot = isFirstPerson3D ? -currentBearing : 0.0;

    final dist = _distanceMeters(startCenter, target);
    final double highPeakZoom = dist > 5000
        ? math.min(startZoom, 11.2)
        : (dist > 500
            ? math.min(startZoom, 13.5)
            : math.max(startZoom - 2.2, 12.8));

    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1450));
    _flyController = ctrl;

    ctrl.addListener(() {
      final t = ctrl.value;
      final easePos = Curves.easeInOutCubic.transform(t);
      final lat = startCenter.latitude +
          (target.latitude - startCenter.latitude) * easePos;
      final lng = startCenter.longitude +
          (target.longitude - startCenter.longitude) * easePos;

      double z;
      if (t < 0.42) {
        final p1 = Curves.easeOutQuad.transform(t / 0.42);
        z = startZoom + (highPeakZoom - startZoom) * p1;
      } else {
        final p2 = Curves.easeInOutCubic.transform((t - 0.42) / 0.58);
        z = highPeakZoom + (targetZoom - highPeakZoom) * p2;
      }

      final rot = startRot + (endRot - startRot) * easePos;
      mapController.moveAndRotate(LatLng(lat, lng), z, rot);
      currentZoom = z;
    });

    ctrl.forward();
  }
  // ==================== التوجيه الصوتي ====================

  List<String> _getManeuverText(Map<String, dynamic>? step) {
    final bool enMode = isEnglish || currentVoice.langType == 'en';
    if (step == null || step['maneuver'] == null) {
      return [
        enMode ? 'Continue straight ahead' : 'تَابِعِ السَّيْرَ لِلْأَمَامِ',
        '↑'
      ];
    }
    final m = step['maneuver'];
    final String type = m['type'] ?? '';
    final String modifier = m['modifier'] ?? '';
    final String rawName =
        (step['name'] != null && step['name'].toString().isNotEmpty)
            ? step['name'].toString()
            : '';

    if (enMode) {
      final String onto = rawName.isNotEmpty ? ' onto $rawName' : '';
      const Map<String, List<String>> enMod = {
        'left': ['left', '↰'],
        'right': ['right', '↱'],
        'slight left': ['slightly left', '↖'],
        'slight right': ['slightly right', '↗'],
        'sharp left': ['sharply left', '↰'],
        'sharp right': ['sharply right', '↱'],
        'straight': ['straight', '↑'],
        'uturn': ['make a U-turn', '↶'],
      };
      final mod = enMod[modifier] ?? ['ahead', '↑'];
      if (type == 'arrive') {
        return ['you will reach your destination, God willing', '●'];
      }
      if (type == 'depart') return ['Start driving now$onto', '↑'];
      if (modifier == 'uturn') return ['Make a safe U-turn ahead', '↶'];
      if (type == 'roundabout' || type == 'rotary') {
        return ['Enter the roundabout and take exit ${m['exit'] ?? ''}', '⟳'];
      }
      if (type == 'merge') return ['Merge onto the main road$onto', mod[1]];
      if (type == 'fork') return ['At the fork, keep ${mod[0]}', mod[1]];
      if (type == 'turn' || type == 'end of road') {
        return ['Turn ${mod[0]}$onto', mod[1]];
      }
      return ['Continue ${mod[0]}$onto', mod[1]];
    }

    final String streetName = rawName.isNotEmpty ? ' بِاتِّجَاهِ $rawName' : '';
    const Map<String, List<String>> modMap = {
      'left': ['يَسَارَاً', '↰'],
      'right': ['يَمِينَاً', '↱'],
      'slight left': ['قَلِيلَاً إِلَى الْيَسَارِ', '↖'],
      'slight right': ['قَلِيلَاً إِلَى الْيَمِينِ', '↗'],
      'sharp left': ['بِحِدَّةٍ إِلَى الْيَسَارِ', '↰'],
      'sharp right': ['بِحِدَّةٍ إِلَى الْيَمِينِ', '↱'],
      'straight': ['مُبَاشَرَةً لِلْأَمَامِ', '↑'],
      'uturn': ['اِسْتَدِرْ لِلْخَلْفِ', '↶'],
    };

    final mod = modMap[modifier] ?? ['لِلْأَمَامِ', '↑'];
    if (type == 'arrive') {
      return ['سَتَصِلُ إِلَى وِجْهَتِكَ إِنْ شَاءَ اللَّهُ', '●'];
    }
    if (type == 'depart') {
      return ['تَوَكَّلْ عَلَى اللَّهِ وَانْطَلِقِ الْآنَ$streetName', '↑'];
    }
    if (modifier == 'uturn') {
      return ['اِسْتَدِرْ لِلْخَلْفِ بِحَذَرٍ', '↶'];
    }
    if (type == 'roundabout' || type == 'rotary') {
      return [
        'اُدْخُلِ الدَّوَّارَ وَخُذِ الْمَخْرَجَ رَقْمَ ${m['exit'] ?? ''}',
        '⟳'
      ];
    }
    if (type == 'turn' || type == 'end of road') {
      return ['اِنْعَطِفْ ${mod[0]}$streetName', mod[1]];
    }
    return ['تَابِعِ السَّيْرَ ${mod[0]}$streetName', mod[1]];
  }

  void _updateNavigationState() {
    if (me == null || navCoords.isEmpty) return;
    int closestIdx = 0;
    double minDistance = 1e9;
    for (int i = 0; i < navCoords.length; i++) {
      final d = _distanceMeters(me!, navCoords[i]);
      if (d < minDistance) {
        minDistance = d;
        closestIdx = i;
      }
    }
    double remainingMeters = 0;
    for (int i = closestIdx; i < navCoords.length - 1; i++) {
      remainingMeters += _distanceMeters(navCoords[i], navCoords[i + 1]);
    }
    final r = routes[selectedRouteIndex];
    final double totalDist = (r['distance'] as num).toDouble();
    final double totalDur = (r['duration'] as num).toDouble();
    final int mins = math.max(
        1,
        ((totalDur * (remainingMeters / (totalDist > 0 ? totalDist : 1))) / 60)
            .round());
    final DateTime etaTime = DateTime.now().add(Duration(minutes: mins));
    final String etaStr =
        '${etaTime.hour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')}';

    final nx = (currentStepIndex + 1 < navSteps.length)
        ? navSteps[currentStepIndex + 1]
        : navSteps[currentStepIndex];
    if (nx == null) return;
    final List<dynamic> locArr = nx['maneuver']['location'];
    final LatLng stepLoc =
        LatLng((locArr[1] as num).toDouble(), (locArr[0] as num).toDouble());
    final double distToStep = _distanceMeters(me!, stepLoc);
    final info = _getManeuverText(nx);

    if (distToStep < 25 && currentStepIndex < navSteps.length - 1) {
      currentStepIndex++;
      return;
    }
    if (remainingMeters < 30) {
      _endNav(arrived: true);
      return;
    }

    final bool enMode = isEnglish || currentVoice.langType == 'en';
    final String distFormatted = distToStep >= 1000
        ? '${(distToStep / 1000).toStringAsFixed(1)} ${tr('كم', 'km')}'
        : '${((distToStep / 10).round() * 10)} ${tr('م', 'm')}';

    setState(() {
      navRemKm = (remainingMeters / 1000).toStringAsFixed(1);
      navRemMins = mins.toString();
      navEta = etaStr;
      hudArrow = info[1];
      hudInstruction =
          tr('بعد $distFormatted: ${info[0]}', 'In $distFormatted: ${info[0]}');
      hudStreet = (nx['name'] != null && nx['name'].toString().isNotEmpty)
          ? nx['name']
          : tr('الطريق الرئيسي', 'Main Road');
    });

    if (distToStep < 200 && lastSpokenStep != currentStepIndex) {
      lastSpokenStep = currentStepIndex;
      final roundedM = math.max(10, (distToStep / 50).round() * 50);
      _say(enMode
          ? 'In $roundedM meters, ${info[0]}'
          : 'بَعْدَ $roundedM مِتْرَاً، ${info[0]}');
    }
  }

  // ==================== البحث والمشاركة ====================

  void _onSearchChanged(String val, String field) {
    searchDebounce?.cancel();
    activeSearchField = field;
    if (field == 'origin') origin = null;

    final trimmed = val.trim();
    if (_parseAndOpenSharedText(trimmed)) {
      setState(() => showSearchList = false);
      return;
    }

    if (trimmed.length < 2) {
      setState(() => showSearchList = false);
      return;
    }
    searchDebounce = Timer(
        const Duration(milliseconds: 450), () => _searchPlaceGlobal(trimmed));
  }

  Future<void> _searchPlaceGlobal(String query) async {
    final int reqId = ++_searchReqId;
    final LatLng center = me ?? mapController.camera.center;
    try {
      final lang = isEnglish ? 'en' : 'ar';
      const double delta = 1.5;
      final String viewbox =
          '${center.longitude - delta},${center.latitude + delta},${center.longitude + delta},${center.latitude - delta}';
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&viewbox=$viewbox&bounded=0&accept-language=$lang&limit=10');
      final res = await http.get(url, headers: {
        'User-Agent': 'com.dlinii.global.app'
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && reqId == _searchReqId) {
        final List<dynamic> data = json.decode(res.body);
        for (final r in data) {
          if (r is! Map) continue;
          final la = double.tryParse(r['lat']?.toString() ?? '');
          final lo = double.tryParse(r['lon']?.toString() ?? '');
          r['_distKm'] = (la != null && lo != null)
              ? Geolocator.distanceBetween(
                      center.latitude, center.longitude, la, lo) /
                  1000.0
              : 1e9;
        }
        data.sort((a, b) => ((a['_distKm'] ?? 1e9) as num)
            .compareTo((b['_distKm'] ?? 1e9) as num));
        if (mounted) {
          setState(() {
            searchResults = data.take(8).toList();
            showSearchList = true;
          });
        }
      }
    } catch (_) {}
  }

  String _fmtSearchDist(dynamic item) {
    final dynamic d = item is Map ? item['_distKm'] : null;
    if (d is! num || d >= 1e8) return '';
    return d < 1
        ? '${(d * 1000).round()} ${tr('م', 'm')} · '
        : '${d.toStringAsFixed(1)} ${tr('كم', 'km')} · ';
  }

  String _buildShareLink(LatLng p, {required bool myLoc, String? name}) {
    final q = <String, String>{
      'lat': p.latitude.toStringAsFixed(6),
      'lng': p.longitude.toStringAsFixed(6),
      'mode': myLoc ? 'myloc' : 'guide',
    };
    if (name != null && name.isNotEmpty) q['name'] = name;
    return Uri.https(kShareHost, '/s', q).toString();
  }

  Future<void> _shareMyCurrentLocation() async {
    LatLng pt = me ?? mapController.camera.center;
    try {
      final Position fresh = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 8));
      pt = LatLng(fresh.latitude, fresh.longitude);
      me = pt;
      _hasRealFix = true;
    } catch (_) {}

    final lat = pt.latitude.toStringAsFixed(6);
    final lng = pt.longitude.toStringAsFixed(6);
    final ofmLink = _buildShareLink(pt, myLoc: true);

    final msg = tr(
      '📍 موقعي الحالي عبر تطبيق دلّيني:\n\n'
          '🔗 اضغط لفتح موقعي:\n$ofmLink\n\n'
          '🧭 كود دلّيني:\nDLINII_MYLOC:$lat,$lng\n\n'
          '📲 تحميل التطبيق:\n$playStoreUrl',
      '📍 My live location via Dlinii:\n\n'
          '🔗 Open in Dlinii:\n$ofmLink\n\n'
          '🧭 Direct code:\nDLINII_MYLOC:$lat,$lng\n\n'
          '📲 Download:\n$playStoreUrl',
    );
    Share.share(msg);
  }

  void _shareCustomSpot(LatLng pt, String spotTitle) {
    final lat = pt.latitude.toStringAsFixed(6);
    final lng = pt.longitude.toStringAsFixed(6);
    final cleanName = spotTitle.isNotEmpty
        ? spotTitle
        : tr('موقع محدد على الخريطة', 'Pinned Location');
    final ofmLink = _buildShareLink(pt, myLoc: false, name: cleanName);

    final msg = tr(
      '🧭 دلّيتك على مكان «$cleanName» عبر دلّيني:\n\n'
          '🔗 اضغط ليرسم لك المسار:\n$ofmLink\n\n'
          '🧭 كود المسار:\nDLINII_GUIDE:$lat,$lng\n\n'
          '📲 تحميل التطبيق:\n$playStoreUrl',
      '🧭 Guided spot "$cleanName" via Dlinii:\n\n'
          '🔗 Open to plot route:\n$ofmLink\n\n'
          '🧭 Direct code:\nDLINII_GUIDE:$lat,$lng\n\n'
          '📲 Download:\n$playStoreUrl',
    );
    Share.share(msg);
  }

  bool _parseAndOpenSharedText(String text, {bool clearClipboard = false}) {
    if (text.trim().isEmpty) return false;
    final bool isMyLocOnly =
        text.contains('DLINII_MYLOC:') || text.contains('mode=myloc');
    double? lat, lng;
    String? sharedName;

    final mName = RegExp(r'[?&]name=([^&#\s]+)').firstMatch(text);
    if (mName != null) {
      try {
        sharedName = Uri.decodeComponent(mName.group(1)!.replaceAll('+', ' '));
      } catch (_) {}
    }

    final reg1 = RegExp(r'DLINII_(?:MYLOC|GUIDE|LOC):([-\d.]+),([-\d.]+)');
    final m1 = reg1.firstMatch(text);
    if (m1 != null) {
      lat = double.tryParse(m1.group(1) ?? '');
      lng = double.tryParse(m1.group(2) ?? '');
    } else {
      final regOfm = RegExp(r'#\d+(?:\.\d+)?/([-\d.]+)/([-\d.]+)');
      final mOfm = regOfm.firstMatch(text);
      if (mOfm != null) {
        lat = double.tryParse(mOfm.group(1) ?? '');
        lng = double.tryParse(mOfm.group(2) ?? '');
      } else {
        final reg2 = RegExp(
            r'(?:q=|mlat=|lat=|geo:)([-\d.]+)[,&\s/]+(?:mlon=|lng=)?([-\d.]+)');
        final m2 = reg2.firstMatch(text);
        if (m2 != null) {
          lat = double.tryParse(m2.group(1) ?? '');
          lng = double.tryParse(m2.group(2) ?? '');
        }
      }
    }

    if (lat != null && lng != null) {
      if (clearClipboard) {
        Clipboard.setData(const ClipboardData(text: ''));
      }
      final pt = LatLng(lat, lng);
      setState(() {
        showSplash = false;
        dest = pt;
        destName = isMyLocOnly
            ? tr('موقع صديقك الحالي', 'Friend Current Location')
            : ((sharedName != null && sharedName.isNotEmpty)
                ? sharedName
                : tr('وجهة مرسلة عبر دلّي صديق', 'Guided Spot via Dlinii'));
        destController.text = destName;
      });
      if (isMyLocOnly) {
        _flyToMyLocation(pt, targetZoom: 16.5);
        _toast(tr('تم فتح موقع صديقك على الخريطة', 'Showing friend location'));
      } else {
        _toast(tr('تم التقاط الوجهة، جاري رسم المسار...',
            'Destination detected, plotting route...'));
        _planRoute();
      }
      return true;
    }
    return false;
  }

  void _initDeepLinksListener() {
    try {
      final appLinks = AppLinks();
      appLinks.uriLinkStream.listen((uri) {
        _handleIncomingUri(uri);
      }, onError: (_) {});
    } catch (_) {}
  }

  void _handleIncomingUri(Uri uri) {
    final fullStr = uri.toString();
    if (_parseAndOpenSharedText(fullStr)) return;

    double? lat = double.tryParse(
        uri.queryParameters['lat'] ?? uri.queryParameters['mlat'] ?? '');
    double? lng = double.tryParse(
        uri.queryParameters['lng'] ?? uri.queryParameters['mlon'] ?? '');
    final String mode = uri.queryParameters['mode'] ?? 'guide';
    final nameStr = uri.queryParameters['name'];

    if (lat != null && lng != null) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        final pt = LatLng(lat, lng);
        setState(() {
          showSplash = false;
          dest = pt;
          destName = (nameStr != null && nameStr.isNotEmpty)
              ? Uri.decodeComponent(nameStr)
              : (mode == 'myloc'
                  ? tr('موقع صديقك الحالي', 'Friend Current Location')
                  : tr('وجهة مرسلة عبر دلّي صديق', 'Guided Spot via Dlinii'));
          destController.text = destName;
        });
        if (mode == 'myloc') {
          _flyToMyLocation(pt, targetZoom: 16.5);
        } else {
          _planRoute();
        }
      });
    }
  }

  Future<void> _checkClipboardForSharedLocation() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.contains('DLINII_') ||
          text.contains('openfreemap.org') ||
          text.contains(kShareHost) ||
          text.contains('geo:')) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (!mounted) return;
          _parseAndOpenSharedText(text, clearClipboard: true);
        });
      }
    } catch (_) {}
  }

  // ==================== فحص الاتصال ====================

  void _startConnectivityProbe() {
    if (kIsWeb) return;
    _probeConnectivity();
    _connProbeTimer = Timer.periodic(
        const Duration(seconds: 25), (_) => _probeConnectivity());
  }

  Future<void> _probeConnectivity() async {
    bool online = true;
    try {
      final r = await http
          .get(Uri.parse('https://tiles.openfreemap.org/planet'))
          .timeout(const Duration(seconds: 5));
      online = r.statusCode < 500;
    } catch (_) {
      online = false;
    }
    if (!mounted) return;
    if (_forceOffline == online) {
      setState(() => _forceOffline = !online);
      _toast(online
          ? tr('عاد الاتصال بالإنترنت ✅', 'Back online ✅')
          : tr('لا يوجد إنترنت: تم التحويل للخرائط المحفوظة',
              'Offline: using saved maps'));
    }
  }

  // ==================== البلاغات السحابية ====================

  void _listenToCloudReports() {
    try {
      FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;
        final List<QueryDocumentSnapshot> validDocs = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final int endVotes = ((data['endVotes'] ?? 0) as num).toInt();
          if (endVotes >= endVotesThreshold) {
            FirebaseFirestore.instance
                .collection('reports')
                .doc(doc.id)
                .delete()
                .catchError((_) {});
            continue;
          }
          validDocs.add(doc);
        }
        setState(() => cloudReports = validDocs);
      });
    } catch (_) {}
  }

  void _onReportButtonTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastReportTimeMs < 5 * 60 * 1000) {
      final remMin =
          ((5 * 60 * 1000 - (now - lastReportTimeMs)) / 60000).ceil();
      _toast(tr('يرجى الانتظار $remMin دقيقة قبل إرسال بلاغ آخر',
          'Please wait $remMin min before reporting again'));
      return;
    }
    final targetPt = reportPoint ?? me ?? mapController.camera.center;
    me ??= targetPt;
    if (_distanceMeters(me!, targetPt) > 300) {
      _toast(tr('يرجى الاقتراب من موقع الحدث (ضمن 300 متر)',
          'Please get closer to the incident'));
      return;
    }
    setState(() {
      reportPoint = me;
      showRepSheet = true;
    });
  }

  Future<void> _submitCloudReport(String type, String label) async {
    final pt = reportPoint ?? me ?? mapController.camera.center;
    lastReportTimeMs = DateTime.now().millisecondsSinceEpoch;
    setState(() => showRepSheet = false);
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': type,
        'label': label,
        'lat': pt.latitude,
        'lng': pt.longitude,
        'confirmations': 1,
        'endVotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _toast(tr('تم نشر بلاغ «$label»', 'Report "$label" published'));
    } catch (_) {
      _toast(tr('تعذر نشر البلاغ', 'Could not publish report'));
    }
  }

  // ==================== أدوات مساعدة ====================

  void _zoomIn() {
    final nextZoom = (mapController.camera.zoom + 1.0).clamp(3.0, 19.5);
    mapController.move(mapController.camera.center, nextZoom);
    setState(() => currentZoom = nextZoom);
  }

  void _zoomOut() {
    final nextZoom = (mapController.camera.zoom - 1.0).clamp(3.0, 19.5);
    mapController.move(mapController.camera.center, nextZoom);
    setState(() => currentZoom = nextZoom);
  }

  void _toggle3DPerspective() {
    setState(() => isFirstPerson3D = !isFirstPerson3D);
    if (isFirstPerson3D) {
      if (me != null) {
        mapController.moveAndRotate(
            me!, math.max(mapController.camera.zoom, 17.5), -currentBearing);
      }
      _toast(tr('تم تفعيل منظور القيادة (3D)', '3D Driving View Enabled'));
    } else {
      mapController.rotate(0);
      _toast(tr('تم العودة للمنظور المسطح (2D)', '2D Top-Down View Enabled'));
    }
  }

  // ==================== build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: landColor,
      drawer: _buildStandardAppDrawer(),
      body: Stack(
        children: [
          // الخريطة
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: me ?? kDefaultCenter,
              initialZoom: 14.5,
              minZoom: 4,
              maxZoom: 19.5,
              onTap: (tapPos, latLng) {
                if (pickMode == 'dest') {
                  setState(() {
                    dest = latLng;
                    destName = tr('موقع محدد على الخريطة', 'Pinned Location');
                    destController.text = destName;
                    pickMode = null;
                  });
                  _planRoute();
                } else if (pickMode == 'share_spot') {
                  _shareCustomSpot(latLng, tr('موقع محدد', 'Pinned Spot'));
                  setState(() => pickMode = null);
                } else if (pickMode == 'report') {
                  setState(() {
                    reportPoint = latLng;
                    pickMode = null;
                    showRepSheet = true;
                  });
                }
              },
            ),
            children: [
              // طبقة البلاطات
              if (isDark && _vtDark != null)
                vt.VectorTileLayer(
                  theme: _vtDark!.theme,
                  tileProviders: _vtDark!.providers,
                )
              else if (_vtLight != null)
                vt.VectorTileLayer(
                  theme: _vtLight!.theme,
                  tileProviders: _vtLight!.providers,
                )
              else
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.dlinii.app',
                  tileProvider: _offlineTileProvider,
                ),

              // حدود المحافظات المحمّلة
              PolylineLayer(polylines: _buildProvinceBorders()),

              // المسارات
              if (routes.isNotEmpty)
                PolylineLayer(
                  polylines: _buildRouteOverlays(
                    routes[selectedRouteIndex],
                    (routes[selectedRouteIndex]['geometry']['coordinates']
                            as List)
                        .map((c) => LatLng(
                            (c[1] as num).toDouble(), (c[0] as num).toDouble()))
                        .toList(),
                  ),
                ),

              // علامات البلاغات (فقط داخل 300 م)
              MarkerLayer(markers: _buildReportMarkers()),

              // علامات الفئة
              if (categoryMapMarkers.isNotEmpty)
                MarkerLayer(markers: categoryMapMarkers),

              // موقعي
              if (me != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: me!,
                      width: 48,
                      height: 48,
                      child: Transform.rotate(
                        angle: currentBearing * math.pi / 180,
                        child: SvgPicture.string(kGreenNavArrowSvg,
                            width: 42, height: 42),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // باقي الواجهة (الأزرار + الشيتات + النوافذ)
          // ... هنا ضع باقي واجهة المستخدم من الملف الأصلي مع التعديلات
          // (الأزرار الجانبية، شريط البحث، شيت التخطيط، شيت الملاحة، نوافذ البلاغات، إلخ)

          // توست
          if (isToastVisible)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.42,
              left: 28,
              right: 28,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142e2d).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF7ce0be).withOpacity(0.3)),
                    ),
                    child: Text(
                      toastMessage,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== الدرج الجانبي ====================

  Widget _buildStandardAppDrawer() {
    return Drawer(
      backgroundColor: panelColor,
      width: 285,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF087e76), Color(0xFF12302d)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/dlinii_icon.png',
                      width: 44, height: 44, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('تطبيق دلّيني', 'Dlinii App'),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr('رفيقك الذكي على الطريق', 'Your Smart Road Guide'),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9cdbc0),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerTile(
                  icon: Icons.cloud_download_rounded,
                  iconColor: const Color(0xFF10b981),
                  title: tr('خرائط بدون نت (18 محافظة)',
                      'Offline Maps (18 Provinces)'),
                  subtitle: tr(
                      'حمل خريطة محافظتك (${downloadedProvinces.length}/18)',
                      'Download governorate map'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => showOfflineMapsModal = true);
                  },
                ),
                const Divider(height: 16),
                _buildDrawerTile(
                  icon: Icons.my_location_rounded,
                  iconColor: const Color(0xFF087e76),
                  title: tr('مشاركة موقعي الحالي', 'Share My Location'),
                  subtitle: tr('إرسال موقعك المباشر', 'Share live location'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareMyCurrentLocation();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.pin_drop_rounded,
                  iconColor: const Color(0xFFd99b26),
                  title: tr('دلّي صديق على مكان', 'Guide a Friend'),
                  subtitle: tr('حدد وجهة ليرسم له المسار', 'Pick a spot'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      pickMode = 'share_spot';
                      showSearchList = false;
                    });
                    _toast(tr('اضغط على المكان في الخريطة',
                        'Tap the spot on the map'));
                  },
                ),
                const Divider(height: 16),
                _buildDrawerTile(
                  icon: Icons.record_voice_over_rounded,
                  iconColor: const Color(0xFF087e76),
                  title: tr('المساعد الصوتي', 'Voice Assistant'),
                  subtitle: voiceGender == 0
                      ? tr('صوت فتاة', 'Female voice')
                      : tr('صوت رجل', 'Male voice'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => showVoiceModal = true);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.translate_rounded,
                  iconColor: const Color(0xFF2563eb),
                  title: tr('لغة التطبيق', 'App Language'),
                  subtitle: isEnglish ? 'English' : 'العربية',
                  onTap: () {
                    Navigator.of(context).pop();
                    _toggleLanguage();
                  },
                ),
                _buildDrawerTile(
                  icon:
                      isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                  iconColor: isDark
                      ? const Color(0xFFefbb52)
                      : const Color(0xFF087e76),
                  title: isDark
                      ? tr('الوضع النهاري', 'Light Mode')
                      : tr('الوضع الليلي', 'Dark Mode'),
                  subtitle: tr('تغيير مظهر الخريطة', 'Switch map theme'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _toggleTheme();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
      subtitle:
          Text(subtitle, style: TextStyle(fontSize: 11.5, color: subColor)),
      onTap: onTap,
    );
  }
}
