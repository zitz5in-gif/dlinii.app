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

// ==================== أيقونات SVG ====================

const String kLogoSvg =
    '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M16 46C28 46 28 30 40 30C46 30 50 26 50 20" stroke="#7ce0be" stroke-width="6" stroke-linecap="round"/><path d="M14 46L22 39M14 46L22 53" stroke="#7ce0be" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/><path d="M46 8C41 8 37 12 37 17C37 23 46 31 46 31C46 31 55 23 55 17C55 12 51 8 46 8Z" fill="#efbb52"/><circle cx="46" cy="17" r="3.5" fill="#143532"/></svg>';

const String kGreenNavArrowSvg =
    '<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="28" fill="#087e76" fill-opacity="0.22"/><circle cx="32" cy="32" r="20" stroke="#9cdbc0" stroke-width="1.5" stroke-opacity="0.5"/><path d="M32 6L52 54L32 43L12 54L32 6Z" fill="#087e76" stroke="#ffffff" stroke-width="3.5" stroke-linejoin="round"/><path d="M32 12L46 48L32 39.5V12Z" fill="#9cdbc0" fill-opacity="0.65"/></svg>';

const String kGpsTargetSvg =
    '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="18" cy="18" r="10" stroke="#087e76" stroke-width="2.5"/><circle cx="18" cy="18" r="4" fill="#efbb52"/><path d="M18 3V7M18 29V33M3 18H7M29 18H33" stroke="#087e76" stroke-width="2.5" stroke-linecap="round"/></svg>';

const String kDestPinSvg =
    '<svg viewBox="0 0 36 44" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 2C9.5 2 3 8.5 3 17C3 27.5 18 42 18 42C18 42 33 27.5 33 17C33 8.5 26.5 2 18 2Z" fill="#087e76" stroke="#ffffff" stroke-width="2.5"/><circle cx="18" cy="17" r="6.5" fill="#efbb52"/><circle cx="18" cy="17" r="2.5" fill="#142e2d"/></svg>';

const String kReportShieldSvg =
    '<svg viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18 4L32 29H4L18 4Z" fill="#efbb52" stroke="#142e2d" stroke-width="2.2" stroke-linejoin="round"/><path d="M18 13V20" stroke="#142e2d" stroke-width="3" stroke-linecap="round"/><circle cx="18" cy="25" r="1.8" fill="#142e2d"/></svg>';

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
  'excavation':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.18"/><path d="M12 32L18 20L24 28L30 16L36 32" stroke="#d99b26" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/><line x1="10" y1="36" x2="38" y2="36" stroke="#142e2d" stroke-width="3"/></svg>',
  'closed':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#E5484D" fill-opacity="0.16"/><path d="M14 14L34 34M34 14L14 34" stroke="#E5484D" stroke-width="4.5" stroke-linecap="round"/><circle cx="24" cy="24" r="16" stroke="#E5484D" stroke-width="2.5"/></svg>',
  'camera':
      '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#087e76" fill-opacity="0.15"/><rect x="12" y="16" width="24" height="16" rx="3" fill="#087e76" stroke="#9cdbc0" stroke-width="2"/><circle cx="24" cy="24" r="5" fill="#efbb52"/><circle cx="24" cy="24" r="2.5" fill="#142e2d"/><path d="M18 16L20 12H28L30 16" stroke="#9cdbc0" stroke-width="2"/></svg>',
};

// ==================== زر زجاجي ====================

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

// ==================== فئات الاستكشاف ====================

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
      osmQuery: 'restaurant'),
  ExploreCategory(
      id: 'hospitals',
      nameAr: 'مستشفيات',
      nameEn: 'Hospitals',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFdc2626),
      osmQuery: 'hospital'),
  ExploreCategory(
      id: 'fuel',
      nameAr: 'وقود',
      nameEn: 'Fuel',
      icon: Icons.local_gas_station_rounded,
      color: Color(0xFF2563eb),
      osmQuery: 'fuel'),
  ExploreCategory(
      id: 'chargers',
      nameAr: 'شواحن',
      nameEn: 'Chargers',
      icon: Icons.ev_station_rounded,
      color: Color(0xFF16a34a),
      osmQuery: 'charging_station'),
  ExploreCategory(
      id: 'mosques',
      nameAr: 'مساجد',
      nameEn: 'Mosques',
      icon: Icons.mosque_rounded,
      color: Color(0xFF087e76),
      osmQuery: 'mosque'),
  ExploreCategory(
      id: 'banks',
      nameAr: 'بنوك',
      nameEn: 'Banks',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFd99b26),
      osmQuery: 'bank'),
  ExploreCategory(
      id: 'shopping',
      nameAr: 'تسوق',
      nameEn: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF9333ea),
      osmQuery: 'supermarket'),
];

// ==================== محافظات العراق ====================

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
      nameAr: '1. محافظة الأنبار',
      nameEn: '1. Al Anbar',
      center: LatLng(33.4258, 43.2995),
      sizeMb: '45 MB'),
  IraqProvince(
      id: 'baghdad',
      nameAr: '2. محافظة بغداد',
      nameEn: '2. Baghdad',
      center: LatLng(33.3152, 44.3661),
      sizeMb: '68 MB'),
  IraqProvince(
      id: 'basra',
      nameAr: '3. محافظة البصرة',
      nameEn: '3. Basra',
      center: LatLng(30.5081, 47.7835),
      sizeMb: '48 MB'),
  IraqProvince(
      id: 'nineveh',
      nameAr: '4. محافظة نينوى',
      nameEn: '4. Nineveh',
      center: LatLng(36.3489, 43.1577),
      sizeMb: '54 MB'),
  IraqProvince(
      id: 'erbil',
      nameAr: '5. محافظة أربيل',
      nameEn: '5. Erbil',
      center: LatLng(36.1901, 44.0091),
      sizeMb: '49 MB'),
  IraqProvince(
      id: 'najaf',
      nameAr: '6. محافظة النجف',
      nameEn: '6. Najaf',
      center: LatLng(32.0000, 44.3333),
      sizeMb: '38 MB'),
  IraqProvince(
      id: 'karbala',
      nameAr: '7. محافظة كربلاء',
      nameEn: '7. Karbala',
      center: LatLng(32.6160, 44.0249),
      sizeMb: '36 MB'),
  IraqProvince(
      id: 'sulaymaniyah',
      nameAr: '8. محافظة السليمانية',
      nameEn: '8. Sulaymaniyah',
      center: LatLng(35.5558, 45.4351),
      sizeMb: '46 MB'),
  IraqProvince(
      id: 'duhok',
      nameAr: '9. محافظة دهوك',
      nameEn: '9. Duhok',
      center: LatLng(36.8669, 42.9503),
      sizeMb: '35 MB'),
  IraqProvince(
      id: 'kirkuk',
      nameAr: '10. محافظة كركوك',
      nameEn: '10. Kirkuk',
      center: LatLng(35.4681, 44.3922),
      sizeMb: '40 MB'),
  IraqProvince(
      id: 'salahaddin',
      nameAr: '11. محافظة صلاح الدين',
      nameEn: '11. Saladin',
      center: LatLng(34.6110, 43.6782),
      sizeMb: '41 MB'),
  IraqProvince(
      id: 'diyala',
      nameAr: '12. محافظة ديالى',
      nameEn: '12. Diyala',
      center: LatLng(33.7485, 44.6436),
      sizeMb: '39 MB'),
  IraqProvince(
      id: 'babil',
      nameAr: '13. محافظة بابل',
      nameEn: '13. Babylon',
      center: LatLng(32.4637, 44.4196),
      sizeMb: '37 MB'),
  IraqProvince(
      id: 'wasit',
      nameAr: '14. محافظة واسط',
      nameEn: '14. Wasit',
      center: LatLng(32.5126, 45.8182),
      sizeMb: '36 MB'),
  IraqProvince(
      id: 'dhiqar',
      nameAr: '15. محافظة ذي قار',
      nameEn: '15. Dhi Qar',
      center: LatLng(31.0439, 46.2573),
      sizeMb: '38 MB'),
  IraqProvince(
      id: 'maysan',
      nameAr: '16. محافظة ميسان',
      nameEn: '16. Maysan',
      center: LatLng(31.8359, 47.1448),
      sizeMb: '34 MB'),
  IraqProvince(
      id: 'qadisiyyah',
      nameAr: '17. محافظة الديوانية',
      nameEn: '17. Al-Qadisiyyah',
      center: LatLng(31.9929, 44.9255),
      sizeMb: '33 MB'),
  IraqProvince(
      id: 'muthanna',
      nameAr: '18. محافظة المثنى',
      nameEn: '18. Al Muthanna',
      center: LatLng(31.3320, 45.2940),
      sizeMb: '32 MB'),
];

// ==================== نظام الصوت الثابت ====================

class VoiceProfile {
  final String id;
  final String nameAr;
  final String nameEn;
  final String locale;
  final String langType;

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
      langType: 'ar'),
  VoiceProfile(
      id: 'en_voice',
      nameAr: 'المساعد الإنجليزي',
      nameEn: 'English Assistant',
      locale: 'en-US',
      langType: 'en'),
];

const String kShareHost = 'dlinii.app';
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

  // الحالة العامة
  bool showSplash = true;
  bool isDark = true;
  bool isEnglish = false;
  bool isFirstPerson3D = false;
  bool showNotifPermissionModal = false;
  bool showModalBox = false;
  bool showRateModal = false;
  bool showVoiceModal = false;
  bool showPlanSheet = false;
  bool showNavSheet = false;
  bool showRepSheet = false;
  bool showExploreModal = false;
  bool showOfflineMapsModal = false;

  // اكتشف ما حولك
  String selectedCategoryId = 'restaurants';
  bool isLoadingCategory = false;
  List<Map<String, dynamic>> nearbyCategoryPlaces = [];
  List<Marker> categoryMapMarkers = [];

  // خرائط بدون نت
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

  // الواجهة
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

  // نظام الصوت الثابت
  bool voiceEnabled = true;
  int selectedVoiceIndex = 0; // 0 = عربي ، 1 = إنجليزي
  int voiceGender = 0; // 0 = فتاة ، 1 = رجل
  int voiceSpeedLevel = 1;
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
      kVoiceProfiles[selectedVoiceIndex.clamp(0, 1)];

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermissionAndStart();
    });

    Future.delayed(const Duration(milliseconds: 2700), () {
      if (!mounted) return;
      setState(() {
        showSplash = false;
        showNotifPermissionModal = true;
      });
      _toast(tr('مرحباً بك في تطبيق دلّيني', 'Welcome to Dlinii'));
      _say(isEnglish
          ? 'Welcome to Dlinii, your smart road companion.'
          : 'مَرْحَبَاً بِكَ فِي تَطْبِيقِ دَلِّينِي، رَفِيقِكَ الذَّكِيِّ عَلَى الطَّرِيقِ.');
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
        setState(() => showNotifPermissionModal = true);
      }
    } catch (_) {
      setState(() => showNotifPermissionModal = true);
    }
  }

  Future<void> _loadSavedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      selectedVoiceIndex = (prefs.getInt('dlini_voice_idx_v6') ?? 0).clamp(0, 1);
      voiceGender = (prefs.getInt('dlini_voice_gender_v6') ?? 0).clamp(0, 1);
      voiceSpeedLevel = (prefs.getInt('dlini_voice_speed_lvl') ?? 1).clamp(0, 2);
      isEnglish = prefs.getBool('dlini_is_en') ?? false;
      isDark = prefs.getBool('dlini_is_dark_default_v2') ?? true;
      downloadedProvinces =
          (prefs.getStringList('dlini_offline_provinces') ?? []).toSet();
      if (mounted) setState(() {});
    } catch (_) {}
    await _applyVoiceProfile();
  }

  Future<void> _applyVoiceProfile() async {
    try {
      final vp = currentVoice;
      await flutterTts.stop();
      await flutterTts.setLanguage(vp.locale);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(voiceGender == 0 ? 1.18 : 0.82);

      double rate;
      if (kIsWeb) {
        rate = voiceSpeedLevel == 0 ? 0.92 : (voiceSpeedLevel == 2 ? 1.18 : 1.05);
      } else {
        rate = voiceSpeedLevel == 0 ? 0.48 : (voiceSpeedLevel == 2 ? 0.65 : 0.54);
      }
      await flutterTts.setSpeechRate(rate);
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
        ? (isEnglish ? 'Female voice selected.' : 'تَمَّ اخْتِيَارُ صَوْتِ الْفَتَاةِ.')
        : (isEnglish ? 'Male voice selected.' : 'تَمَّ اخْتِيَارُ صَوْتِ الرَّجُلِ.'));
  }

  Future<void> _setVoiceSpeedLevel(int level) async {
    setState(() => voiceSpeedLevel = level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_voice_speed_lvl', level);
    await _applyVoiceProfile();
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
    _toast(isEnglish ? 'Language: English' : 'اللغة: العربية');
  }

  void _toggleVoiceState() {
    setState(() => voiceEnabled = !voiceEnabled);
    if (!voiceEnabled) flutterTts.stop();
    _toast(voiceEnabled
        ? tr('تم تفعيل الصوت', 'Voice on')
        : tr('تم كتم الصوت', 'Voice muted'));
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

  String _getReportLabel(String? type, String? fallback) {
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
        return tr('نقطة مرور', 'Police');
      case 'excavation':
        return tr('حفريات', 'Excavation');
      case 'closed':
        return tr('طريق مغلق', 'Road Closed');
      case 'camera':
        return tr('كاميرا مراقبة', 'Camera');
      default:
        return tr('خطر', 'Hazard');
    }
  }

  Widget _buildReportSvg(String? type, {double size = 28}) {
    return SvgPicture.string(
      kReportTypeSvgs[type] ?? kReportTypeSvgs['hazard']!,
      width: size,
      height: size,
    );
  }

  List<Marker> _buildReportMarkers() {
    final List<Marker> markers = [];
    final LatLng center = me ?? mapController.camera.center;

    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final LatLng pt = LatLng(
        ((data['lat'] ?? 33.42) as num).toDouble(),
        ((data['lng'] ?? 43.29) as num).toDouble(),
      );

      if (_distanceMeters(center, pt) > 300) continue;

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
            child: _buildReportSvg(type, size: 34),
          ),
        ),
      );
    }
    return markers;
  }

  List<Polyline> _buildRouteOverlays(
      Map<String, dynamic> selectedRoute, List<LatLng> routePoints) {
    final List<Polyline> overlays = [];
    if (routePoints.length < 2) return overlays;

    // المسار الأساسي أخضر
    overlays.add(Polyline(
      points: routePoints,
      color: const Color(0xFF087e76),
      strokeWidth: 7.5,
    ));

    // تلوين حسب السرعة
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
                if (speedKmh < 16) {
                  overlays.add(Polyline(
                      points: stepPts,
                      color: const Color(0xFFE5484D),
                      strokeWidth: 9.5));
                } else if (speedKmh < 26) {
                  overlays.add(Polyline(
                      points: stepPts,
                      color: const Color(0xFFefbb52),
                      strokeWidth: 8.5));
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    // تلوين قرب البلاغات
    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final LatLng repPt = LatLng(
        ((data['lat'] ?? 33.42) as num).toDouble(),
        ((data['lng'] ?? 43.29) as num).toDouble(),
      );
      final String type = data['type']?.toString() ?? 'hazard';
      final List<LatLng> affected = [];
      for (final p in routePoints) {
        if (_distanceMeters(p, repPt) <= 220) affected.add(p);
      }
      if (affected.length >= 2) {
        final bool isBad = type == 'traffic' || type == 'closed';
        overlays.add(Polyline(
          points: affected,
          color: isBad ? const Color(0xFFE5484D) : const Color(0xFFefbb52),
          strokeWidth: 9.0,
        ));
      }
    }
    return overlays;
  }
  // ==================== الجزء 4 من 8 – الخرائط بدون نت + الوضع الليلي + تخطيط المسار ====================

// ---------- نظام الخرائط بدون نت ----------
class _TileRange {
  final int x0, x1, y0, y1;
  const _TileRange(this.x0, this.x1, this.y0, this.y1);
  bool covers(int x, int y) => x >= x0 && x <= x1 && y >= y0 && y <= y1;
}

class _OfflineTiles {
  static Directory? dir;
  static const List<int> zooms = [10, 11, 12, 13, 14];

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      final base = await getApplicationDocumentsDirectory();
      final d = Directory('${base.path}/offline_tiles');
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

  static _TileRange _range(IraqProvince p, int z) {
    final double n = p.center.latitude + p.radiusDeg;
    final double s = p.center.latitude - p.radiusDeg;
    final double w = p.center.longitude - p.radiusDeg;
    final double e = p.center.longitude + p.radiusDeg;
    return _TileRange(_tx(w, z), _tx(e, z), _ty(n, z), _ty(s, z));
  }

  static int tileCount(IraqProvince p) {
    int t = 0;
    for (final z in zooms) {
      final r = _range(p, z);
      t += (r.x1 - r.x0 + 1) * (r.y1 - r.y0 + 1);
    }
    return t;
  }

  static Future<bool> _fetch(http.Client c, int z, int x, int y) async {
    final String sub = const ['a', 'b', 'c', 'd'][(x + y) % 4];
    final Uri url = Uri.parse('https://$sub.basemaps.cartocdn.com/rastertiles/voyager/$z/$x/$y.png');
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await c.get(url, headers: {'User-Agent': 'com.dlinii.app'})
            .timeout(const Duration(seconds: 15));
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          final f = file(z, x, y);
          await f.parent.create(recursive: true);
          await f.writeAsBytes(r.bodyBytes);
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<bool> downloadProvince(IraqProvince p, {required void Function(double) onProgress}) async {
    if (dir == null) await init();
    if (dir == null) return false;

    final List<List<int>> jobs = [];
    for (final z in zooms) {
      final r = _range(p, z);
      for (int x = r.x0; x <= r.x1; x++) {
        for (int y = r.y0; y <= r.y1; y++) {
          if (!file(z, x, y).existsSync()) jobs.add([z, x, y]);
        }
      }
    }

    final int total = tileCount(p);
    int done = total - jobs.length;
    int failed = 0;
    int next = 0;
    final client = http.Client();

    try {
      Future<void> worker() async {
        while (true) {
          final int i = next++;
          if (i >= jobs.length) return;
          final j = jobs[i];
          if (!await _fetch(client, j[0], j[1], j[2])) failed++;
          done++;
          if (done % 8 == 0 || done == total) {
            onProgress((done / total).clamp(0.02, 1.0));
          }
        }
      }
      await Future.wait(List.generate(6, (_) => worker()));
    } finally {
      client.close();
    }
    return failed <= total * 0.05;
  }

  static Future<void> deleteProvince(IraqProvince p, Set<String> otherDownloadedIds) async {
    if (dir == null) await init();
    if (dir == null) return;

    final others = kIraqProvinces
        .where((o) => o.id != p.id && otherDownloadedIds.contains(o.id))
        .toList();

    for (final z in zooms) {
      final r = _range(p, z);
      final otherRanges = others.map((o) => _range(o, z)).toList();
      for (int x = r.x0; x <= r.x1; x++) {
        for (int y = r.y0; y <= r.y1; y++) {
          if (otherRanges.any((o) => o.covers(x, y))) continue;
          final f = file(z, x, y);
          if (f.existsSync()) {
            try { f.deleteSync(); } catch (_) {}
          }
        }
      }
    }
  }
}

class _OfflineTileProvider extends TileProvider {
  _OfflineTileProvider() : super(headers: {'User-Agent': 'com.dlinii.app'});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (_OfflineTiles.dir != null) {
      final f = _OfflineTiles.file(coordinates.z, coordinates.x, coordinates.y);
      if (f.existsSync()) return FileImage(f);
    }
    return NetworkImage(getTileUrl(coordinates, options), headers: headers);
  }
}

// ---------- دوال الجزء 4 داخل الكلاس _HomeScreenState ----------

  Future<void> _initOfflineTiles() async {
    await _OfflineTiles.init();
    if (mounted) setState(() {});
  }

  Future<void> _downloadProvinceOfflineMap(IraqProvince prov) async {
    if (downloadingProvinceId != null || kIsWeb) {
      if (kIsWeb) _toast(tr('التحميل متاح على الهاتف فقط', 'Download available on mobile only'));
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dlini_offline_provinces', downloadedProvinces.toList());
      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });
      _flyToMyLocation(prov.center, targetZoom: 12.8);
      _toast(tr('تم تحميل خريطة ${prov.nameAr} بنجاح ✅', '${prov.nameEn} downloaded ✅'));
    } else {
      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });
      _toast(tr('فشل التحميل، تأكد من الإنترنت', 'Download failed, check internet'));
    }
  }

  Future<void> _deleteProvinceOfflineMap(IraqProvince prov) async {
    downloadedProvinces.remove(prov.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dlini_offline_provinces', downloadedProvinces.toList());
    try {
      await _OfflineTiles.deleteProvince(prov, downloadedProvinces);
    } catch (_) {}
    setState(() {});
    _toast(tr('تم حذف خريطة ${prov.nameAr}', 'Removed ${prov.nameEn}'));
  }

  List<Polyline> _buildProvinceBorders() {
    final List<Polyline> borders = [];
    for (final prov in kIraqProvinces) {
      if (!downloadedProvinces.contains(prov.id)) continue;
      final double r = prov.radiusDeg;
      final List<LatLng> rect = [
        LatLng(prov.center.latitude + r, prov.center.longitude - r),
        LatLng(prov.center.latitude + r, prov.center.longitude + r),
        LatLng(prov.center.latitude - r, prov.center.longitude + r),
        LatLng(prov.center.latitude - r, prov.center.longitude - r),
        LatLng(prov.center.latitude + r, prov.center.longitude - r),
      ];
      borders.add(Polyline(
        points: rect,
        color: const Color(0xFF087e76),
        strokeWidth: 3.0,
        isDotted: true,
      ));
    }
    return borders;
  }

  Future<void> _toggleTheme() async {
    setState(() => isDark = !isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dlini_is_dark_default_v2', isDark);
  }

  Future<void> _loadMapStyles() async {
    try {
      final light = await vt.StyleReader(uri: _ofmLightStyleUrl).read();
      if (mounted) setState(() => _vtLight = light);
    } catch (_) {}
  }

  static const String _kRouteCacheKey = 'dlini_route_cache_v1';

  Future<void> _planRoute({LatLng? fromPoint}) async {
    final LatLng o = fromPoint ?? origin ?? me ?? mapController.camera.center;
    if (dest == null) return;
    final LatLng d = dest!;
    List<dynamic>? found;

    if (!_forceOffline) {
      try {
        final url = Uri.parse(
            'https://router.project-osrm.org/route/v1/driving/${o.longitude},${o.latitude};${d.longitude},${d.latitude}?overview=full&geometries=geojson&steps=true&alternatives=true');
        final res = await http.get(url).timeout(const Duration(seconds: 9));
        final data = json.decode(res.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          found = List<dynamic>.from(data['routes']);
          _saveRouteToCache(o, d, found.first);
        }
      } catch (_) {}
    }

    if (found == null) {
      final cached = await _loadRouteFromCache(o, d);
      found = cached != null ? [cached] : [_buildOfflineFallbackRoute(o, d)];
      _toast(tr('وضع بدون إنترنت: مسار تقريبي', 'Offline: approximate route'));
    }

    if (!mounted) return;
    setState(() {
      routes = found!;
      selectedRouteIndex = 0;
      showPlanSheet = true;
    });

    final coords = routes[0]['geometry']['coordinates'] as List;
    if (coords.isNotEmpty) {
      final points = coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 260),
      ));
    }
  }

  Map<String, dynamic> _mkStep(String type, String modifier, LatLng loc, String name, double dist, double dur) {
    return {
      'maneuver': {'type': type, 'modifier': modifier, 'location': [loc.longitude, loc.latitude]},
      'name': name,
      'distance': dist,
      'duration': dur,
    };
  }

  Future<void> _saveRouteToCache(LatLng o, LatLng d, dynamic route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRouteCacheKey);
      final list = raw != null ? (json.decode(raw) as List) : [];
      list.insert(0, {
        'oLat': o.latitude,
        'oLng': o.longitude,
        'dLat': d.latitude,
        'dLng': d.longitude,
        'route': route,
      });
      if (list.length > 8) list.removeLast();
      await prefs.setString(_kRouteCacheKey, json.encode(list));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadRouteFromCache(LatLng o, LatLng d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRouteCacheKey);
      if (raw == null) return null;
      final list = json.decode(raw) as List;
      for (final e in list) {
        if (e is! Map) continue;
        final cd = LatLng((e['dLat'] as num).toDouble(), (e['dLng'] as num).toDouble());
        if (_distanceMeters(cd, d) < 400) {
          return Map<String, dynamic>.from(e['route']);
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _buildOfflineFallbackRoute(LatLng o, LatLng d) {
    final double dist = _distanceMeters(o, d) * 1.3;
    final double dur = dist / ((dist > 15000 ? 70 : 40) / 3.6);
    final int n = math.max(2, (dist / 200).ceil());
    final List<List<double>> coords = [];
    for (int i = 0; i <= n; i++) {
      final t = i / n;
      coords.add([
        o.longitude + (d.longitude - o.longitude) * t,
        o.latitude + (d.latitude - o.latitude) * t,
      ]);
    }
    return {
      'distance': dist,
      'duration': dur,
      'geometry': {'type': 'LineString', 'coordinates': coords},
      'legs': [{
        'steps': [
          _mkStep('depart', 'straight', o, '', 0, 0),
          _mkStep('arrive', 'straight', d, '', 0, 0),
        ],
        'distance': dist,
        'duration': dur,
      }],
      'dlinii_source': 'fallback',
    };
  }
    // ==================== الملاحة ====================

  void _startNav() {
    if (routes.isEmpty) return;
    final r = routes[selectedRouteIndex];
    final rawCoords = r['geometry']['coordinates'] as List;
    navCoords = rawCoords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    me ??= navCoords.isNotEmpty ? navCoords.first : mapController.camera.center;
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
    mapController.moveAndRotate(
        _lookAhead(me!, currentBearing, 28), 17.8, -currentBearing);
    final info = _getManeuverText(navSteps.length > 1 ? navSteps[1] : navSteps[0]);
    _say((isEnglish ? 'Starting navigation. ' : 'بَدَأَتِ الرِّحْلَةُ. ') + info[0]);
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
      _toast(tr('الحمد لله على سلامتك، وصلت إلى وجهتك',
          'You have arrived safely'));
      _say(isEnglish
          ? 'You have arrived at your destination safely.'
          : 'الْحَمْدُ لِلَّهِ، لَقَدْ وَصَلْتَ بِالسَّلَامَةِ.');
      setState(() => showRateModal = true);
    }
  }

  List<String> _getManeuverText(Map<String, dynamic>? step) {
    final bool en = isEnglish || currentVoice.langType == 'en';
    if (step == null || step['maneuver'] == null) {
      return [en ? 'Continue straight' : 'تَابِعِ السَّيْرَ لِلْأَمَامِ', '↑'];
    }
    final m = step['maneuver'];
    final type = m['type'] ?? '';
    final modifier = m['modifier'] ?? '';

    if (type == 'arrive') {
      return [
        en ? 'You will reach your destination' : 'سَتَصِلُ إِلَى وِجْهَتِكَ إِنْ شَاءَ اللَّهُ',
        '●'
      ];
    }
    if (type == 'depart') {
      return [en ? 'Start driving' : 'تَوَكَّلْ عَلَى اللَّهِ وَانْطَلِقْ', '↑'];
    }

    final Map<String, List<String>> arMap = {
      'left': ['يَسَارَاً', '↰'],
      'right': ['يَمِينَاً', '↱'],
      'slight left': ['قَلِيلَاً لِلْيَسَارِ', '↖'],
      'slight right': ['قَلِيلَاً لِلْيَمِينِ', '↗'],
      'straight': ['مُبَاشَرَةً', '↑'],
      'uturn': ['اِسْتَدِرْ لِلْخَلْفِ', '↶'],
    };
    final Map<String, List<String>> enMap = {
      'left': ['left', '↰'],
      'right': ['right', '↱'],
      'slight left': ['slightly left', '↖'],
      'slight right': ['slightly right', '↗'],
      'straight': ['straight', '↑'],
      'uturn': ['U-turn', '↶'],
    };

    final mod = (en ? enMap : arMap)[modifier] ??
        (en ? ['ahead', '↑'] : ['لِلْأَمَامِ', '↑']);
    if (type == 'turn' || type == 'end of road') {
      return [en ? 'Turn ${mod[0]}' : 'اِنْعَطِفْ ${mod[0]}', mod[1]];
    }
    return [en ? 'Continue ${mod[0]}' : 'تَابِعْ ${mod[0]}', mod[1]];
  }

  void _updateNavigationState() {
    if (me == null || navCoords.isEmpty) return;

    int closest = 0;
    double minD = 1e9;
    for (int i = 0; i < navCoords.length; i++) {
      final d = _distanceMeters(me!, navCoords[i]);
      if (d < minD) {
        minD = d;
        closest = i;
      }
    }

    double remaining = 0;
    for (int i = closest; i < navCoords.length - 1; i++) {
      remaining += _distanceMeters(navCoords[i], navCoords[i + 1]);
    }

    if (remaining < 30) {
      _endNav(arrived: true);
      return;
    }

    final r = routes[selectedRouteIndex];
    final totalDist = (r['distance'] as num).toDouble();
    final totalDur = (r['duration'] as num).toDouble();
    final mins = math.max(1, ((totalDur * (remaining / totalDist)) / 60).round());
    final eta = DateTime.now().add(Duration(minutes: mins));

    final nextStep = currentStepIndex + 1 < navSteps.length
        ? navSteps[currentStepIndex + 1]
        : navSteps[currentStepIndex];
    final info = _getManeuverText(nextStep);
    final loc = nextStep['maneuver']['location'];
    final stepPt = LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
    final distToStep = _distanceMeters(me!, stepPt);

    setState(() {
      navRemKm = (remaining / 1000).toStringAsFixed(1);
      navRemMins = mins.toString();
      navEta =
          '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
      hudArrow = info[1];
      hudInstruction = tr('بعد ${(distToStep / 10).round() * 10} م: ${info[0]}',
          'In ${(distToStep / 10).round() * 10} m: ${info[0]}');
    });

    if (distToStep < 180 && lastSpokenStep != currentStepIndex) {
      lastSpokenStep = currentStepIndex;
      _say(isEnglish
          ? 'In ${(distToStep / 50).round() * 50} meters, ${info[0]}'
          : 'بَعْدَ ${(distToStep / 50).round() * 50} مِتْر، ${info[0]}');
    }
  }

  // ==================== البحث والمشاركة ====================

  void _onSearchChanged(String val, String field) {
    searchDebounce?.cancel();
    activeSearchField = field;
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      setState(() => showSearchList = false);
      return;
    }
    if (_parseAndOpenSharedText(trimmed)) return;
    searchDebounce =
        Timer(const Duration(milliseconds: 450), () => _searchPlaceGlobal(trimmed));
  }

  Future<void> _searchPlaceGlobal(String query) async {
    final reqId = ++_searchReqId;
    final center = me ?? mapController.camera.center;
    try {
      final lang = isEnglish ? 'en' : 'ar';
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&accept-language=$lang&limit=8');
      final res = await http
          .get(url, headers: {'User-Agent': 'com.dlinii.app'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && reqId == _searchReqId) {
        final data = json.decode(res.body) as List;
        if (mounted) {
          setState(() {
            searchResults = data;
            showSearchList = true;
          });
        }
      }
    } catch (_) {}
  }

  String _buildShareLink(LatLng p, {required bool myLoc, String? name}) {
    final q = {
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
      final pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 6));
      pt = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
    final link = _buildShareLink(pt, myLoc: true);
    final msg = tr(
      '📍 موقعي عبر دلّيني:\n$link\n\n📲 $playStoreUrl',
      '📍 My location via Dlinii:\n$link\n\n📲 $playStoreUrl',
    );
    Share.share(msg);
  }

  void _shareCustomSpot(LatLng pt, String title) {
    final link = _buildShareLink(pt, myLoc: false, name: title);
    final msg = tr(
      '🧭 دلّيتك على «$title»:\n$link\n\n📲 $playStoreUrl',
      '🧭 Guided to "$title":\n$link\n\n📲 $playStoreUrl',
    );
    Share.share(msg);
  }

  bool _parseAndOpenSharedText(String text, {bool clearClipboard = false}) {
    double? lat, lng;
    final reg = RegExp(r'DLINII_(?:MYLOC|GUIDE|LOC):([-\d.]+),([-\d.]+)');
    final m = reg.firstMatch(text);
    if (m != null) {
      lat = double.tryParse(m.group(1)!);
      lng = double.tryParse(m.group(2)!);
    }
    if (lat == null || lng == null) {
      final reg2 = RegExp(r'[?&]lat=([-\d.]+).*[?&]lng=([-\d.]+)');
      final m2 = reg2.firstMatch(text);
      if (m2 != null) {
        lat = double.tryParse(m2.group(1)!);
        lng = double.tryParse(m2.group(2)!);
      }
    }
    if (lat != null && lng != null) {
      final pt = LatLng(lat, lng);
      setState(() {
        dest = pt;
        destName = tr('وجهة من صديق', 'Friend destination');
        destController.text = destName;
      });
      _planRoute();
      return true;
    }
    return false;
  }

  void _initDeepLinksListener() {
    try {
      AppLinks().uriLinkStream.listen((uri) {
        _parseAndOpenSharedText(uri.toString());
      });
    } catch (_) {}
  }

  Future<void> _checkClipboardForSharedLocation() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.contains('DLINII_') || text.contains(kShareHost)) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _parseAndOpenSharedText(text, clearClipboard: true);
        });
      }
    } catch (_) {}
  }
    // ==================== تتبع الموقع ====================

  Future<void> _initLocationTracking({bool userInitiated = false}) async {
    try {
      final res = await PermissionsHelper.ensureLocation();
      if (res != LocPermResult.granted) {
        if (userInitiated) {
          _toast(tr('يرجى تفعيل خدمة الموقع', 'Please enable location'));
        }
        return;
      }

      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _onPositionUpdate(LatLng(last.latitude, last.longitude), last.speed,
            last.heading,
            isFirst: true);
      }

      await positionStream?.cancel();
      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((pos) {
        if (simTimer != null) return;
        _onPositionUpdate(
            LatLng(pos.latitude, pos.longitude), pos.speed, pos.heading);
      });
    } catch (_) {}
  }

  void _onPositionUpdate(LatLng raw, double speed, double heading,
      {bool isFirst = false}) {
    if (!mounted) return;
    _hasRealFix = true;

    LatLng next = raw;
    double? routeBearing;
    if (isNavigating) {
      final snap = _snapToRoute(raw);
      if (snap != null) {
        next = snap.point;
        routeBearing = snap.bearing;
      }
    }

    double newBearing = currentBearing;
    if (routeBearing != null) {
      newBearing = routeBearing;
    } else if (heading >= 0) {
      newBearing = heading;
    }

    setState(() {
      me = next;
      currentBearing = newBearing;
      currentSpeedKmh = math.max(0, (speed * 3.6).round());
    });

    if (isFirst) {
      _dispState.value = _DispState(next, newBearing);
      if (!isNavigating) mapController.move(next, 15.5);
    } else {
      _glideTo(next, newBearing, 600);
    }

    if (isNavigating) {
      _updateNavigationState();
      _checkNearbyReports(next);
    }
  }

  _Snap? _snapToRoute(LatLng p) {
    if (navCoords.length < 2) return null;
    double best = 1e18;
    LatLng? bp;
    double bb = 0;
    for (int i = 0; i < navCoords.length - 1; i++) {
      final a = navCoords[i];
      final b = navCoords[i + 1];
      final d = _distanceMeters(p, a);
      if (d < best) {
        best = d;
        bp = a;
        bb = _getBearing(a, b);
      }
    }
    if (bp == null || best > 40) return null;
    return _Snap(bp, bb);
  }

  void _glideTo(LatLng target, double bearing, int ms) {
    final ctrl = _glideCtrl ??= AnimationController(vsync: this)
      ..addListener(() {
        final t = _glideCtrl!.value;
        final pos = LatLng(
          _gStart.latitude + (_gEnd.latitude - _gStart.latitude) * t,
          _gStart.longitude + (_gEnd.longitude - _gStart.longitude) * t,
        );
        final b = _lerpAngle(_gStartB, _gEndB, t);
        _dispState.value = _DispState(pos, b);
        if (follow && isNavigating) {
          mapController.moveAndRotate(
              _lookAhead(pos, b, 28), mapController.camera.zoom, -b);
        }
      });
    _gStart = _dispState.value.pos;
    _gStartB = _dispState.value.bearing;
    _gEnd = target;
    _gEndB = bearing;
    ctrl.duration = Duration(milliseconds: ms);
    ctrl.forward(from: 0);
  }

  void _checkNearbyReports(LatLng pos) {
    if (!isNavigating) return;
    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final pt = LatLng(
          (data['lat'] as num).toDouble(), (data['lng'] as num).toDouble());
      final dist = _distanceMeters(pos, pt);
      final id = doc.id;
      final type = data['type'] ?? '';
      if (dist > 200 || warnedReports.contains(id)) continue;

      warnedReports.add(id);
      final label = _getReportLabel(type, null);
      final msg = isEnglish
          ? 'Caution, $label ahead'
          : 'اِحْذَرْ، أَمَامَكَ $label';
      _say(msg);
      _toast(msg);
    }
  }

  void _listenToCloudReports() {
    try {
      FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        final valid = <QueryDocumentSnapshot>[];
        for (final doc in snap.docs) {
          final endVotes = ((doc.data() as Map)['endVotes'] ?? 0) as int;
          if (endVotes >= endVotesThreshold) {
            doc.reference.delete();
          } else {
            valid.add(doc);
          }
        }
        setState(() => cloudReports = valid);
      });
    } catch (_) {}
  }

  void _onReportButtonTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastReportTimeMs < 5 * 60 * 1000) {
      _toast(tr('انتظر قليلاً قبل بلاغ جديد', 'Please wait before new report'));
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
      _toast(tr('تم نشر البلاغ', 'Report published'));
    } catch (_) {
      _toast(tr('فشل نشر البلاغ', 'Failed to publish'));
    }
  }

  void _flyToMyLocation(LatLng target, {double targetZoom = 16.5}) {
    mapController.move(target, targetZoom);
  }

  void _zoomIn() {
    mapController.move(
        mapController.camera.center, (mapController.camera.zoom + 1).clamp(4.0, 19.0));
  }

  void _zoomOut() {
    mapController.move(
        mapController.camera.center, (mapController.camera.zoom - 1).clamp(4.0, 19.0));
  }

  void _toggle3DPerspective() {
    setState(() => isFirstPerson3D = !isFirstPerson3D);
    if (isFirstPerson3D && me != null) {
      mapController.moveAndRotate(me!, 17.5, -currentBearing);
    } else {
      mapController.rotate(0);
    }
  }

  void _startConnectivityProbe() {
    if (kIsWeb) return;
    Timer.periodic(const Duration(seconds: 30), (_) async {
      bool online = true;
      try {
        final r = await http
            .get(Uri.parse('https://tiles.openfreemap.org/planet'))
            .timeout(const Duration(seconds: 4));
        online = r.statusCode < 500;
      } catch (_) {
        online = false;
      }
      if (_forceOffline == online && mounted) {
        setState(() => _forceOffline = !online);
      }
    });
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: landColor,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // ==================== الخريطة ====================
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: me ?? kDefaultCenter,
              initialZoom: 14.5,
              minZoom: 5,
              maxZoom: 19,
              onTap: (tapPosition, point) {
                if (pickMode == 'dest') {
                  setState(() {
                    dest = point;
                    destName = tr('موقع محدد', 'Pinned location');
                    destController.text = destName;
                    pickMode = null;
                  });
                  _planRoute();
                } else if (pickMode == 'share_spot') {
                  _shareCustomSpot(point, tr('موقع محدد', 'Pinned spot'));
                  setState(() => pickMode = null);
                } else if (pickMode == 'report') {
                  setState(() {
                    reportPoint = point;
                    pickMode = null;
                    showRepSheet = true;
                  });
                }
              },
            ),
            children: [
              // طبقة البلاطات
              if (_vtLight != null)
                vt.VectorTileLayer(
                  theme: isDark && _vtDark != null
                      ? _vtDark!.theme
                      : _vtLight!.theme,
                  tileProviders: _vtLight!.providers,
                )
              else
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.dlinii.app',
                ),

              // حدود المحافظات المحمّلة
              PolylineLayer(polylines: _buildProvinceBorders()),

              // المسارات
              if (routes.isNotEmpty)
                PolylineLayer(
                  polylines: _buildRouteOverlays(
                    routes[selectedRouteIndex],
                    (routes[selectedRouteIndex]['geometry']['coordinates'] as List)
                        .map((c) => LatLng(
                            (c[1] as num).toDouble(), (c[0] as num).toDouble()))
                        .toList(),
                  ),
                ),

              // علامات البلاغات (فقط داخل 300 متر)
              MarkerLayer(markers: _buildReportMarkers()),

              // موقعي الحالي
              if (me != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: me!,
                      width: 46,
                      height: 46,
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

          // ==================== الأزرار الجانبية ====================
          Positioned(
            right: 14,
            bottom: isNavigating ? 130 : 110,
            child: Column(
              children: [
                _circleBtn(Icons.add, _zoomIn),
                const SizedBox(height: 10),
                _circleBtn(Icons.remove, _zoomOut),
                const SizedBox(height: 10),
                _circleBtn(
                  isFirstPerson3D ? Icons.view_in_ar : Icons.map,
                  _toggle3DPerspective,
                  active: isFirstPerson3D,
                ),
              ],
            ),
          ),

          // زر البلاغ + موقعي
          Positioned(
            left: 14,
            bottom: isNavigating ? 130 : 24,
            child: Row(
              children: [
                _circleBtn(null, _onReportButtonTap,
                    svg: kReportShieldSvg, size: 52),
                const SizedBox(width: 10),
                _circleBtn(null, () {
                  setState(() => follow = true);
                  _initLocationTracking(userInitiated: true);
                  if (me != null) _flyToMyLocation(me!);
                }, svg: kGpsTargetSvg, size: 52),
              ],
            ),
          ),

          // شريط البحث العلوي
          if (!isNavigating) _buildSearchBar(),

          // شيتات
          if (showPlanSheet) _buildPlanSheet(),
          if (isNavigating) _buildNavHUD(),
          if (showRepSheet) _buildReportSheet(),

          // النوافذ المنبثقة
          if (showVoiceModal) _buildVoiceModal(),
          if (showOfflineMapsModal) _buildOfflineMapsModal(),
          if (showNotifPermissionModal) _buildPermissionModal(),
          if (showRateModal) _buildRateModal(),

          // توست
          if (isToastVisible)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.42,
              left: 30,
              right: 30,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142e2d).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF7ce0be).withOpacity(0.3)),
                  ),
                  child: Text(
                    toastMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData? icon, VoidCallback onTap,
      {String? svg, double size = 44, bool active = false}) {
    return GlassTapButton(
      width: size,
      height: size,
      isCircle: true,
      backgroundColor: active ? const Color(0xFF087e76) : glassColor,
      borderColor: active ? const Color(0xFF7ce0be) : lineColor,
      onTap: onTap,
      child: svg != null
          ? SvgPicture.string(svg, width: size * 0.48, height: size * 0.48)
          : Icon(icon, size: 22, color: active ? Colors.white : accentColor),
    );
  }

  // ==================== شريط البحث ====================

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 14,
      right: 14,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: lineColor),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: accentColor),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: TextField(
                    controller: destController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    onChanged: (v) => _onSearchChanged(v, 'q'),
                    decoration: InputDecoration(
                      hintText: tr('ابحث عن مكان...', 'Search place...'),
                      hintStyle: TextStyle(color: subColor),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.mic,
                      color: isListeningVoice
                          ? const Color(0xFFE5484D)
                          : accentColor),
                  onPressed: () {}, // يمكن ربط البحث الصوتي لاحقاً
                ),
              ],
            ),
          ),
          if (showSearchList && searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lineColor),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (_, i) {
                  final item = searchResults[i];
                  final name = item['display_name'] ?? '';
                  return ListTile(
                    dense: true,
                    title: Text(name,
                        maxLines: 2,
                        style: TextStyle(fontSize: 13, color: textColor)),
                    onTap: () {
                      final lat = double.tryParse(item['lat'].toString());
                      final lon = double.tryParse(item['lon'].toString());
                      if (lat != null && lon != null) {
                        setState(() {
                          dest = LatLng(lat, lon);
                          destName = name.split(',').first;
                          destController.text = destName;
                          showSearchList = false;
                        });
                        _planRoute();
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ==================== الدرج الجانبي ====================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: panelColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF087e76), Color(0xFF12302d)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('دلّيني', 'Dlinii'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(tr('رفيقك على الطريق', 'Your road companion'),
                      style: const TextStyle(color: Color(0xFF9cdbc0))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_download,
                        color: Color(0xFF10b981)),
                    title: Text(tr('خرائط بدون نت', 'Offline Maps')),
                    subtitle: Text('${downloadedProvinces.length}/18'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => showOfflineMapsModal = true);
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.my_location, color: Color(0xFF087e76)),
                    title: Text(tr('مشاركة موقعي', 'Share My Location')),
                    onTap: () {
                      Navigator.pop(context);
                      _shareMyCurrentLocation();
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.pin_drop, color: Color(0xFFd99b26)),
                    title: Text(tr('دلّي صديق', 'Guide a Friend')),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => pickMode = 'share_spot');
                      _toast(tr('اضغط على الخريطة لتحديد المكان',
                          'Tap map to choose location'));
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.record_voice_over,
                        color: Color(0xFF087e76)),
                    title: Text(tr('المساعد الصوتي', 'Voice Assistant')),
                    subtitle: Text(voiceGender == 0
                        ? tr('صوت فتاة', 'Female')
                        : tr('صوت رجل', 'Male')),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => showVoiceModal = true);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.translate, color: Color(0xFF2563eb)),
                    title: Text(tr('اللغة', 'Language')),
                    subtitle: Text(isEnglish ? 'English' : 'العربية'),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleLanguage();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                        isDark ? Icons.wb_sunny : Icons.dark_mode,
                        color: isDark
                            ? const Color(0xFFefbb52)
                            : const Color(0xFF087e76)),
                    title: Text(isDark
                        ? tr('الوضع النهاري', 'Light Mode')
                        : tr('الوضع الليلي', 'Dark Mode')),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleTheme();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
    // ==================== شيت التخطيط ====================

  Widget _buildPlanSheet() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: glassColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: lineColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SvgPicture.string(kDestPinSvg, width: 20, height: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(destName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => _endNav(arrived: false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (routes.isNotEmpty)
              Text(
                '${((routes[0]['duration'] as num) / 60).round()} ${tr('دقيقة', 'min')}  •  ${((routes[0]['distance'] as num) / 1000).toStringAsFixed(1)} ${tr('كم', 'km')}',
                style: TextStyle(color: subColor, fontSize: 14),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087e76),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _startNav,
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: Text(tr('انطلاق الرحلة', 'Start Journey'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HUD الملاحة ====================

  Widget _buildNavHUD() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF102826).withOpacity(0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7ce0be).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(hudArrow,
                style: const TextStyle(
                    fontSize: 28, color: Color(0xFF9cdbc0))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(hudInstruction,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== شيت البلاغات ====================

  Widget _buildReportSheet() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: lineColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr('إرسال تنبيه', 'Send Alert'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => setState(() => showRepSheet = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.15,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _repBtn('bump', tr('مطب', 'Bump')),
                _repBtn('pothole', tr('حفرة', 'Pothole')),
                _repBtn('crash', tr('حادث', 'Crash')),
                _repBtn('traffic', tr('ازدحام', 'Traffic')),
                _repBtn('police', tr('نقطة مرور', 'Police')),
                _repBtn('excavation', tr('حفريات', 'Excavation')),
                _repBtn('closed', tr('طريق مغلق', 'Closed')),
                _repBtn('camera', tr('كاميرا', 'Camera')),
                _repBtn('hazard', tr('خطر', 'Hazard')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _repBtn(String type, String label) {
    return GlassTapButton(
      onTap: () => _submitCloudReport(type, label),
      backgroundColor: landColor,
      borderColor: lineColor,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildReportSvg(type, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ==================== نافذة الصوت ====================

  Widget _buildVoiceModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('المساعد الصوتي', 'Voice Assistant'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedVoiceIndex == 0
                            ? const Color(0xFF087e76)
                            : landColor,
                      ),
                      onPressed: () async {
                        setState(() => selectedVoiceIndex = 0);
                        final p = await SharedPreferences.getInstance();
                        await p.setInt('dlini_voice_idx_v6', 0);
                        await _applyVoiceProfile();
                      },
                      child: Text('العربية',
                          style: TextStyle(
                              color: selectedVoiceIndex == 0
                                  ? Colors.white
                                  : textColor)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedVoiceIndex == 1
                            ? const Color(0xFF087e76)
                            : landColor,
                      ),
                      onPressed: () async {
                        setState(() => selectedVoiceIndex = 1);
                        final p = await SharedPreferences.getInstance();
                        await p.setInt('dlini_voice_idx_v6', 1);
                        await _applyVoiceProfile();
                      },
                      child: Text('English',
                          style: TextStyle(
                              color: selectedVoiceIndex == 1
                                  ? Colors.white
                                  : textColor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: voiceGender == 0
                            ? const Color(0xFF087e76)
                            : landColor,
                      ),
                      onPressed: _switchGender,
                      icon: Icon(Icons.face_3,
                          color: voiceGender == 0 ? Colors.white : accentColor),
                      label: Text(tr('فتاة', 'Female'),
                          style: TextStyle(
                              color: voiceGender == 0
                                  ? Colors.white
                                  : textColor)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: voiceGender == 1
                            ? const Color(0xFF087e76)
                            : landColor,
                      ),
                      onPressed: _switchGender,
                      icon: Icon(Icons.face_6,
                          color: voiceGender == 1 ? Colors.white : accentColor),
                      label: Text(tr('رجل', 'Male'),
                          style: TextStyle(
                              color: voiceGender == 1
                                  ? Colors.white
                                  : textColor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => showVoiceModal = false),
                child: Text(tr('إغلاق', 'Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== نافذة الخرائط بدون نت ====================

  Widget _buildOfflineMapsModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(tr('خرائط بدون نت', 'Offline Maps'),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () =>
                          setState(() => showOfflineMapsModal = false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: kIraqProvinces.length,
                  itemBuilder: (_, i) {
                    final p = kIraqProvinces[i];
                    final saved = downloadedProvinces.contains(p.id);
                    final loading = downloadingProvinceId == p.id;
                    return ListTile(
                      title: Text(isEnglish ? p.nameEn : p.nameAr,
                          style: TextStyle(color: textColor, fontSize: 13.5)),
                      subtitle: Text(saved
                          ? tr('محمّلة', 'Downloaded')
                          : p.sizeMb),
                      trailing: loading
                          ? Text('${(downloadProgress * 100).round()}%')
                          : saved
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteProvinceOfflineMap(p),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download,
                                      color: Color(0xFF087e76)),
                                  onPressed: () =>
                                      _downloadProvinceOfflineMap(p),
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

  // ==================== نافذة الإذن ====================

  Widget _buildPermissionModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 42, color: Color(0xFFefbb52)),
              const SizedBox(height: 12),
              Text(tr('تفعيل الموقع', 'Enable Location'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 8),
              Text(
                tr('يحتاج دلّيني إلى إذن الموقع لعرض موقعك وتوجيهك.',
                    'Dlinii needs location permission to show your position.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => showNotifPermissionModal = false),
                      child: Text(tr('لاحقاً', 'Later')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF087e76)),
                      onPressed: () {
                        setState(() => showNotifPermissionModal = false);
                        _initLocationTracking(userInitiated: true);
                      },
                      child: Text(tr('السماح', 'Allow'),
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== نافذة التقييم ====================

  Widget _buildRateModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 42, color: Color(0xFFefbb52)),
              const SizedBox(height: 10),
              Text(tr('تقييم دلّيني', 'Rate Dlinii'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087e76)),
                onPressed: () {
                  launchUrl(Uri.parse(playStoreUrl));
                  setState(() => showRateModal = false);
                },
                child: Text(tr('تقييم على المتجر', 'Rate on Store'),
                    style: const TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => showRateModal = false),
                child: Text(tr('إغلاق', 'Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // نهاية الكلاس _HomeScreenState