// ==================== بداية الجزء 1 من 6 ====================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' as vt;
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

// ==================== فلاتر الألوان للوضع الليلي ====================
const ColorFilter kInstantDarkFilter = ColorFilter.matrix(<double>[
  -0.82, 0.0, 0.0, 0.0, 215.0,
  0.0, -0.80, 0.0, 0.0, 212.0,
  0.0, 0.0, -0.75, 0.0, 208.0,
  0.0, 0.0, 0.0, 1.0, 0.0,
]);

// ==================== أيقونات SVG المخصصة ====================
const String kOriginPinSvg = '''
<svg viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
  <circle cx="20" cy="20" r="14" fill="#087e76" stroke="#ffffff" stroke-width="3.5"/>
  <circle cx="20" cy="20" r="5.5" fill="#efbb52"/>
</svg>
''';

const String kDestPinSvg = '''
<svg viewBox="0 0 44 52" xmlns="http://www.w3.org/2000/svg">
  <path d="M22 2C11.5 2 3 10.5 3 21c0 13.2 19 29 19 29s19-15.8 19-29C41 10.5 32.5 2 22 2z" fill="#087e76" stroke="#ffffff" stroke-width="3"/>
  <circle cx="22" cy="20" r="7.5" fill="#efbb52"/>
</svg>
''';

const String kGreenNavArrowSvg = '''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="26" fill="#087e76" fill-opacity="0.22"/>
  <path d="M32 8L50 52L32 42L14 52L32 8Z" fill="#10b981" stroke="#ffffff" stroke-width="3.5" stroke-linejoin="round"/>
</svg>
''';

const String kMyLocationPulseSvg = '''
<svg viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg">
  <circle cx="30" cy="30" r="24" fill="#10b981" fill-opacity="0.20"/>
  <circle cx="30" cy="30" r="11" fill="#087e76" stroke="#ffffff" stroke-width="3.5"/>
  <circle cx="30" cy="30" r="4.2" fill="#7ce0be"/>
</svg>
''';

const String kGpsTargetSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="7" fill="none" stroke="#7ce0be" stroke-width="2.2"/>
  <circle cx="12" cy="12" r="2.8" fill="#efbb52"/>
  <path d="M12 2v3M12 19v3M2 12h3M19 12h3" stroke="#7ce0be" stroke-width="2.2" stroke-linecap="round"/>
</svg>
''';

const String kReportShieldSvg = '''
<svg viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 2L26 24H2L14 2Z" fill="#efbb52" stroke="#142e2d" stroke-width="2" stroke-linejoin="round"/>
  <rect x="12.8" y="10" width="2.4" height="7" rx="1.2" fill="#142e2d"/>
  <circle cx="14" cy="20.2" r="1.5" fill="#142e2d"/>
</svg>
''';

const String kScenePinSvg = '''
<svg viewBox="0 0 32 38" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 2C8.8 2 3 7.8 3 15c0 9.5 13 21 13 21s13-11.5 13-21c0-7.2-5.8-13-13-13z" fill="#efbb52" stroke="#ffffff" stroke-width="2"/>
  <circle cx="16" cy="15" r="5" fill="#142e2d"/>
</svg>
''';

const String kCarSvg = '''
<svg viewBox="0 0 240 100" xmlns="http://www.w3.org/2000/svg">
  <path d="M42 62 L68 32 C74 26 84 22 96 22 L152 22 C164 22 175 27 182 35 L204 62 Z" fill="#087e76" stroke="#7ce0be" stroke-width="2.5"/>
  <rect x="24" y="54" width="192" height="26" rx="12" fill="#10b981" stroke="#ffffff" stroke-width="2"/>
  <circle cx="66" cy="80" r="14" fill="#142e2d" stroke="#efbb52" stroke-width="3.5"/>
  <circle cx="174" cy="80" r="14" fill="#142e2d" stroke="#efbb52" stroke-width="3.5"/>
</svg>
''';

// ==================== نماذج البيانات الأساسية ====================
class VoiceProfile {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descAr;
  final String descEn;
  final String langType; // 'ar' or 'en'

  const VoiceProfile({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
    required this.langType,
  });
}

const List<VoiceProfile> kVoiceProfiles = [
  VoiceProfile(
    id: 'ar_iraq_fusha',
    nameAr: 'المساعد العربي الفصيح',
    nameEn: 'Arabic Voice Assistant',
    descAr: 'توجيه صوتي عربي واضح ودقيق',
    descEn: 'Clear Arabic voice navigation',
    langType: 'ar',
  ),
  VoiceProfile(
    id: 'en_intl',
    nameAr: 'المساعد الإنجليزي العالمي',
    nameEn: 'English Voice Assistant',
    descAr: 'توجيه صوتي باللغة الإنجليزية',
    descEn: 'Clear English voice navigation',
    langType: 'en',
  ),
];

class ExploreCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String osmKey;
  final String osmVal;

  const ExploreCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.osmKey,
    required this.osmVal,
  });
}

const List<ExploreCategory> kExploreCategories = [
  ExploreCategory(
    id: 'fuel',
    nameAr: 'محطات وقود',
    nameEn: 'Gas Stations',
    icon: Icons.local_gas_station_rounded,
    color: Color(0xFFf59e0b),
    osmKey: 'amenity',
    osmVal: 'fuel',
  ),
  ExploreCategory(
    id: 'hospital',
    nameAr: 'مستشفيات وصحة',
    nameEn: 'Hospitals',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFef4444),
    osmKey: 'amenity',
    osmVal: 'hospital',
  ),
  ExploreCategory(
    id: 'pharmacy',
    nameAr: 'صيدليات',
    nameEn: 'Pharmacies',
    icon: Icons.medication_rounded,
    color: Color(0xFF10b981),
    osmKey: 'amenity',
    osmVal: 'pharmacy',
  ),
  ExploreCategory(
    id: 'restaurant',
    nameAr: 'مطاعم وكافيهات',
    nameEn: 'Restaurants',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFec4899),
    osmKey: 'amenity',
    osmVal: 'restaurant',
  ),
  ExploreCategory(
    id: 'mosque',
    nameAr: 'مساجد وجوامع',
    nameEn: 'Mosques',
    icon: Icons.mosque_rounded,
    color: Color(0xFF087e76),
    osmKey: 'amenity',
    osmVal: 'place_of_worship',
  ),
  ExploreCategory(
    id: 'atm',
    nameAr: 'مصارف وصراف آلي',
    nameEn: 'Banks & ATMs',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF3b82f6),
    osmKey: 'amenity',
    osmVal: 'bank',
  ),
];

class IraqProvince {
  final String id;
  final String nameAr;
  final String nameEn;
  final LatLng center;
  final String sizeMb;

  const IraqProvince({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.center,
    required this.sizeMb,
  });
}

const List<IraqProvince> kIraqProvinces = [
  IraqProvince(id: 'anbar', nameAr: 'الأنبار (الرمادي والفلوجة وحديثة)', nameEn: 'Al Anbar (Ramadi)', center: LatLng(33.4258, 43.2995), sizeMb: '18 MB'),
  IraqProvince(id: 'baghdad', nameAr: 'بغداد', nameEn: 'Baghdad', center: LatLng(33.3152, 44.3661), sizeMb: '24 MB'),
  IraqProvince(id: 'basra', nameAr: 'البصرة', nameEn: 'Basra', center: LatLng(30.5081, 47.7835), sizeMb: '19 MB'),
  IraqProvince(id: 'nineveh', nameAr: 'نينوى (الموصل)', nameEn: 'Nineveh (Mosul)', center: LatLng(36.3489, 43.1577), sizeMb: '21 MB'),
  IraqProvince(id: 'erbil', nameAr: 'أربيل', nameEn: 'Erbil', center: LatLng(36.1901, 44.0091), sizeMb: '17 MB'),
  IraqProvince(id: 'sulaymaniyah', nameAr: 'السليمانية', nameEn: 'Sulaymaniyah', center: LatLng(35.5613, 45.4306), sizeMb: '16 MB'),
  IraqProvince(id: 'duhok', nameAr: 'دهوك', nameEn: 'Duhok', center: LatLng(36.8679, 42.9503), sizeMb: '14 MB'),
  IraqProvince(id: 'kirkuk', nameAr: 'كركوك', nameEn: 'Kirkuk', center: LatLng(35.4681, 44.3922), sizeMb: '15 MB'),
  IraqProvince(id: 'salahaddin', nameAr: 'صلاح الدين (تكريت)', nameEn: 'Saladin (Tikrit)', center: LatLng(34.6158, 43.6782), sizeMb: '16 MB'),
  IraqProvince(id: 'diyala', nameAr: 'ديالى (بعقوبة)', nameEn: 'Diyala (Baqubah)', center: LatLng(33.7485, 44.6436), sizeMb: '15 MB'),
  IraqProvince(id: 'babil', nameAr: 'بابل (الحلة)', nameEn: 'Babylon (Hillah)', center: LatLng(32.4722, 44.4217), sizeMb: '15 MB'),
  IraqProvince(id: 'karbala', nameAr: 'كربلاء', nameEn: 'Karbala', center: LatLng(32.6160, 44.0249), sizeMb: '14 MB'),
  IraqProvince(id: 'najaf', nameAr: 'النجف', nameEn: 'Najaf', center: LatLng(31.9985, 44.3396), sizeMb: '15 MB'),
  IraqProvince(id: 'qadisiyyah', nameAr: 'القادسية (الديوانية)', nameEn: 'Al-Qadisiyyah', center: LatLng(31.9879, 44.9247), sizeMb: '13 MB'),
  IraqProvince(id: 'wasit', nameAr: 'واسط (الكوت)', nameEn: 'Wasit (Kut)', center: LatLng(32.5128, 45.8182), sizeMb: '14 MB'),
  IraqProvince(id: 'maysan', nameAr: 'ميسان (العمارة)', nameEn: 'Maysan (Amarah)', center: LatLng(31.8359, 47.1448), sizeMb: '14 MB'),
  IraqProvince(id: 'dhiqar', nameAr: 'ذي قار (الناصرية)', nameEn: 'Dhi Qar (Nasiriyah)', center: LatLng(31.0439, 46.2573), sizeMb: '15 MB'),
  IraqProvince(id: 'muthanna', nameAr: 'المثنى (السماوة)', nameEn: 'Al Muthanna (Samawah)', center: LatLng(31.3320, 45.2940), sizeMb: '13 MB'),
];

// قائمة التسميات العربية الواضحة لمدن ومناطق العراق لمنع أي نقص في الأسماء على الخريطة
class IraqiCityLabel {
  final String nameAr;
  final String nameEn;
  final LatLng point;
  final double minZoom;
  final bool isMajor;

  const IraqiCityLabel({
    required this.nameAr,
    required this.nameEn,
    required this.point,
    this.minZoom = 6.0,
    this.isMajor = true,
  });
}

const List<IraqiCityLabel> kIraqiCityLabels = [
  IraqiCityLabel(nameAr: 'الرمادي', nameEn: 'Ramadi', point: LatLng(33.4258, 43.2995), minZoom: 7.0, isMajor: true),
  IraqiCityLabel(nameAr: 'الفلوجة', nameEn: 'Fallujah', point: LatLng(33.3538, 43.7850), minZoom: 8.5, isMajor: true),
  IraqiCityLabel(nameAr: 'حديثة', nameEn: 'Haditha', point: LatLng(34.1366, 42.3772), minZoom: 8.5, isMajor: true),
  IraqiCityLabel(nameAr: 'هيت', nameEn: 'Hit', point: LatLng(33.6366, 42.8277), minZoom: 9.0, isMajor: false),
  IraqiCityLabel(nameAr: 'القائم', nameEn: 'Al Qaim', point: LatLng(34.3883, 41.0708), minZoom: 8.5, isMajor: false),
  IraqiCityLabel(nameAr: 'عنة', nameEn: 'Anah', point: LatLng(34.3686, 41.9819), minZoom: 9.5, isMajor: false),
  IraqiCityLabel(nameAr: 'راوة', nameEn: 'Rawa', point: LatLng(34.4828, 41.9169), minZoom: 9.5, isMajor: false),
  IraqiCityLabel(nameAr: 'الرطبة', nameEn: 'Rutba', point: LatLng(33.0371, 40.2858), minZoom: 8.5, isMajor: false),
  IraqiCityLabel(nameAr: 'الخالدية', nameEn: 'Khaldiyah', point: LatLng(33.3833, 43.5167), minZoom: 10.0, isMajor: false),
  IraqiCityLabel(nameAr: 'الحبانية', nameEn: 'Habbaniyah', point: LatLng(33.3806, 43.5889), minZoom: 10.0, isMajor: false),
  IraqiCityLabel(nameAr: 'بغداد', nameEn: 'Baghdad', point: LatLng(33.3152, 44.3661), minZoom: 6.0, isMajor: true),
  IraqiCityLabel(nameAr: 'البصرة', nameEn: 'Basra', point: LatLng(30.5081, 47.7835), minZoom: 6.0, isMajor: true),
  IraqiCityLabel(nameAr: 'الموصل', nameEn: 'Mosul', point: LatLng(36.3489, 43.1577), minZoom: 6.0, isMajor: true),
  IraqiCityLabel(nameAr: 'أربيل', nameEn: 'Erbil', point: LatLng(36.1901, 44.0091), minZoom: 6.5, isMajor: true),
  IraqiCityLabel(nameAr: 'كركوك', nameEn: 'Kirkuk', point: LatLng(35.4681, 44.3922), minZoom: 7.0, isMajor: true),
  IraqiCityLabel(nameAr: 'النجف', nameEn: 'Najaf', point: LatLng(31.9985, 44.3396), minZoom: 7.0, isMajor: true),
  IraqiCityLabel(nameAr: 'كربلاء', nameEn: 'Karbala', point: LatLng(32.6160, 44.0249), minZoom: 7.0, isMajor: true),
  IraqiCityLabel(nameAr: 'تكريت', nameEn: 'Tikrit', point: LatLng(34.6158, 43.6782), minZoom: 7.5, isMajor: true),
  IraqiCityLabel(nameAr: 'الحلة', nameEn: 'Hillah', point: LatLng(32.4722, 44.4217), minZoom: 7.5, isMajor: true),
  IraqiCityLabel(nameAr: 'بعقوبة', nameEn: 'Baqubah', point: LatLng(33.7485, 44.6436), minZoom: 7.5, isMajor: true),
];
// ==================== نهاية الجزء 1 من 6 ====================
// ==================== بداية الجزء 2 من 6 ====================
// ==================== مزود الخرائط الأوفلاين الذكي ====================
class _OfflineTileProvider extends TileProvider {
  String? baseDirPath;

  _OfflineTileProvider({this.baseDirPath});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (!kIsWeb && baseDirPath != null && baseDirPath!.isNotEmpty) {
      final file = File(
          '$baseDirPath/tiles/${coordinates.z}_${coordinates.x}_${coordinates.y}.png');
      if (file.existsSync() && file.lengthSync() > 100) {
        return FileImage(file);
      }
    }
    return NetworkImage(getTileUrl(coordinates, options));
  }
}

// ==================== زر الزجاج التفاعلي ====================
class GlassTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;

  const GlassTapButton({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(10),
    this.backgroundColor = const Color(0xFF152928),
    this.borderColor = const Color(0xFF284e4b),
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<GlassTapButton> createState() => _GlassTapButtonState();
}

class _GlassTapButtonState extends State<GlassTapButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            border: Border.all(color: widget.borderColor, width: 1.1),
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

// ==================== الكلاسات الأساسية للشاشة ====================
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
  static const String webAppDomain = 'https://dlinii.vercel.app';
  static const LatLng kDefaultCenter = LatLng(33.4258, 43.2995);

  static const MethodChannel _deepLinkChannel =
      MethodChannel('com.dlinii.app/deeplink');

  bool showSplash = true,
      isDark = true,
      isEnglish = false,
      follow = true,
      isFirstPerson3D = false,
      isNavigating = false,
      showPlanSheet = false,
      showNavSheet = false,
      showReportModal = false,
      showAddPlaceModal = false,
      showOfflineModal = false,
      showVoiceModal = false,
      showRateModal = false,
      // يبدأ false دائماً ولا يظهر إلا بعد فحص الذاكرة والتأكد أن المستخدم جديد ولم يمنح الإذن
      showNotifPermissionModal = false,
      isSearching = false,
      isListeningVoice = false,
      isCalculatingRoute = false,
      _forceOffline = false,
      _hasAskedPermission = false;

  int selectedVoiceIndex = 0,
      voiceSpeedLevel = 1,
      selectedRouteIndex = 0,
      currentStepIndex = 0,
      lastSpokenStep = -1,
      selectedStars = 5;

  double currentSpeedKmh = 0.0,
      currentBearing = 0.0,
      currentMapZoom = 14.2,
      downloadProgress = 0.0;

  String? downloadingProvinceId, activeCategoryId;
  Set<String> downloadedProvinces = {};
  Set<String> warnedReports = {};

  LatLng? me, origin, dest, pickedPlacePoint;
  String destTitle = '';

  List<dynamic> routes = [];
  List<dynamic> navSteps = [];
  List<LatLng> navCoords = [];
  List<Map<String, dynamic>> searchResults = [];
  List<Marker> categoryMapMarkers = [];
  List<QueryDocumentSnapshot> cloudReports = [];
  List<QueryDocumentSnapshot> customPlaces = [];

  String navRemKm = '0.0',
      navRemMins = '0',
      navEta = '--:--',
      hudArrow = '⬆️',
      hudInstruction = '',
      hudStreet = '';

  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController destController = TextEditingController();
  final TextEditingController placeNameController = TextEditingController();
  String selectedPlaceCategory = 'محل تجاري';

  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  List<dynamic> _availableVoices = [];
  final Map<String, int> _voiceSlot = {};
  final Map<String, int> _pinnedSlot = {};

  vtr.Theme? vectorThemeDark;
  vtr.Theme? vectorThemeLight;
  vt.TileProviders? vectorTileProviders;

  late _OfflineTileProvider _offlineTileProvider;
  String? _offlineBaseDir;

  StreamSubscription<Position>? positionStream;
  StreamSubscription<QuerySnapshot>? reportsSub;
  StreamSubscription<QuerySnapshot>? placesSub;
  Timer? simTimer;
  Timer? searchDebounce;
  Timer? _pulseTimer;

  AnimationController? _glideCtrl;
  LatLng _glideFromPos = kDefaultCenter;
  LatLng _glideToPos = kDefaultCenter;
  double _glideFromBearing = 0.0;
  double _glideToBearing = 0.0;
  int _lastFixMs = 0;

  final ValueNotifier<_DispState> _dispState =
      ValueNotifier<_DispState>(const _DispState(kDefaultCenter, 0.0));
  final ValueNotifier<double> _pulseNotifier = ValueNotifier<double>(0.0);

  VoiceProfile get currentVoice =>
      kVoiceProfiles[selectedVoiceIndex.clamp(0, kVoiceProfiles.length - 1)];

  String tr(String ar, String en) => isEnglish ? en : ar;

  @override
  void initState() {
    super.initState();
    _offlineTileProvider = _OfflineTileProvider();
    _initGlideController();
    _initOfflineDir();
    _loadSavedPrefs();
    _initVectorStyle();
    _listenFirestoreStreams();
    _initDeepLinks();

    _pulseTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _pulseNotifier.value = (_pulseNotifier.value + 0.18) % (math.pi * 2);
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    reportsSub?.cancel();
    placesSub?.cancel();
    simTimer?.cancel();
    searchDebounce?.cancel();
    _pulseTimer?.cancel();
    _glideCtrl?.dispose();
    searchController.dispose();
    destController.dispose();
    placeNameController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _initGlideController() {
    _glideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() {
        final double t = Curves.easeOutCubic.transform(_glideCtrl!.value);
        final double lat = _glideFromPos.latitude +
            (_glideToPos.latitude - _glideFromPos.latitude) * t;
        final double lng = _glideFromPos.longitude +
            (_glideToPos.longitude - _glideFromPos.longitude) * t;
        final double b =
            _lerpAngle(_glideFromBearing, _glideToBearing, t);
        final pos = LatLng(lat, lng);
        _dispState.value = _DispState(pos, b);

        if (follow && mounted) {
          if (isNavigating && isFirstPerson3D) {
            mapController.moveAndRotate(_lookAhead(pos, b, 28), 17.8, -b);
          } else {
            mapController.move(pos, mapController.camera.zoom);
          }
        }
      });
  }

  Future<void> _initOfflineDir() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _offlineBaseDir = dir.path;
      _offlineTileProvider = _OfflineTileProvider(baseDirPath: _offlineBaseDir);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ==================== استقبال الروابط العميقة و"فتح باستخدام" ====================
  Future<void> _initDeepLinks() async {
    // 1. إذا كان يفتح من المتصفح (dlinii.vercel.app/?lat=...&lng=...)
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('lat') &&
          uri.queryParameters.containsKey('lng')) {
        _handleIncomingLink(uri.toString());
      }
      return;
    }

    // 2. استقبال الروابط أثناء عمل التطبيق في الخلفية
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink' && call.arguments != null) {
        _handleIncomingLink(call.arguments.toString());
      }
    });

    // 3. استقبال الرابط الذي فتح التطبيق لأول مرة (من تيليجرام أو واتساب أو المتصفح)
    try {
      final String? initialUrl =
          await _deepLinkChannel.invokeMethod<String>('getInitialLink');
      if (initialUrl != null && initialUrl.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 900), () {
          _handleIncomingLink(initialUrl);
        });
      }
    } catch (_) {}
  }

  void _handleIncomingLink(String rawLink) {
    try {
      double? lat;
      double? lng;
      String placeLabel = tr('موقع مشترك', 'Shared Location');

      final Uri? uri = Uri.tryParse(rawLink);
      if (uri != null) {
        if (uri.queryParameters['name'] != null &&
            uri.queryParameters['name']!.trim().isNotEmpty) {
          placeLabel = Uri.decodeComponent(uri.queryParameters['name']!);
        } else if (uri.queryParameters['q'] != null) {
          final qVal = uri.queryParameters['q']!;
          if (qVal.contains('(') && qVal.contains(')')) {
            final start = qVal.indexOf('(') + 1;
            final end = qVal.indexOf(')');
            if (end > start) placeLabel = qVal.substring(start, end);
          }
        }

        if (uri.queryParameters['lat'] != null &&
            uri.queryParameters['lng'] != null) {
          lat = double.tryParse(uri.queryParameters['lat']!);
          lng = double.tryParse(uri.queryParameters['lng']!);
        }
      }

      // التقاط إحداثيات روابط geo:33.42,43.29 أو روابط Google Maps
      if (lat == null || lng == null) {
        final RegExp coordRegex =
            RegExp(r'(-?\d{1,2}\.\d{3,12})\s*,\s*(-?\d{1,3}\.\d{3,12})');
        final match = coordRegex.firstMatch(Uri.decodeFull(rawLink));
        if (match != null) {
          lat = double.tryParse(match.group(1)!);
          lng = double.tryParse(match.group(2)!);
        }
      }

      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {
        final target = LatLng(lat, lng);
        setState(() {
          showSplash = false;
          follow = false;
        });
        mapController.move(target, 16.0);
        _toast(tr('تم فتح الموقع في دلّيني 📍', 'Location opened in Dlinii 📍'));
        _selectDestination(target, placeLabel);
      }
    } catch (_) {}
  }

  // ==================== إصلاح المربعات الفارغة تحت الأسماء في الخريطة ====================
  Map<String, dynamic> _fixStyleForArabic(Map<String, dynamic> styleJson) {
    final copy = jsonDecode(jsonEncode(styleJson)) as Map<String, dynamic>;
    if (copy['layers'] is List) {
      for (final layer in (copy['layers'] as List)) {
        if (layer is Map && layer['layout'] is Map) {
          final layout = layer['layout'] as Map<String, dynamic>;
          // توحيد الخط لمنع ظهور مربعات ▯▯▯▯▯▯▯ تحت Ramadi وغيرها
          if (layout.containsKey('text-font')) {
            layout['text-font'] = ['Noto Sans Regular'];
          }
          // إجبار الخريطة على إظهار الاسم العربي أولاً ثم الإنجليزي بوضوح
          if (layout.containsKey('text-field')) {
            layout['text-field'] = [
              'coalesce',
              ['get', 'name:ar'],
              ['get', 'name'],
              ['get', 'name:en']
            ];
          }
        }
      }
    }
    return copy;
  }

  Future<void> _initVectorStyle() async {
    try {
      final resDark = await http
          .get(Uri.parse('https://tiles.openfreemap.org/styles/dark'))
          .timeout(const Duration(seconds: 7));
      final resLight = await http
          .get(Uri.parse('https://tiles.openfreemap.org/styles/positron'))
          .timeout(const Duration(seconds: 7));

      if (resDark.statusCode == 200 && resLight.statusCode == 200) {
        final darkMap =
            _fixStyleForArabic(jsonDecode(resDark.body) as Map<String, dynamic>);
        final lightMap =
            _fixStyleForArabic(jsonDecode(resLight.body) as Map<String, dynamic>);

        final styleDark = await vt.StyleReader(
          uri: 'https://tiles.openfreemap.org/styles/dark',
          logger: const vtr.Logger.noop(),
        ).read();

        vectorThemeDark = vtr.ThemeReader(logger: const vtr.Logger.noop())
            .read(darkMap);
        vectorThemeLight = vtr.ThemeReader(logger: const vtr.Logger.noop())
            .read(lightMap);
        vectorTileProviders = styleDark.providers;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  // ==================== حفظ الإعدادات وفحص إذن الموقع لعدم تكرار النافذة ====================
  Future<void> _loadSavedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getInt('dlini_voice_idx_v5') ?? 0;
      final savedSpeed = prefs.getInt('dlini_voice_speed_lvl') ?? 1;
      final savedLang = prefs.getBool('dlini_is_en') ?? false;
      final savedDark = prefs.getBool('dlini_is_dark_default_v2') ?? true;
      final savedProvs = prefs.getStringList('dlini_offline_provinces') ?? [];
      bool alreadyAsked = prefs.getBool('dlini_perm_asked_v3') ?? false;

      // فحص إذن نظام التشغيل الفعلي: إذا كان المستخدم قد سمح بالموقع سابقاً، لا نظهر النافذة أبداً
      try {
        final LocationPermission sysPerm = await Geolocator.checkPermission();
        if (sysPerm == LocationPermission.always ||
            sysPerm == LocationPermission.whileInUse) {
          alreadyAsked = true;
          await prefs.setBool('dlini_perm_asked_v3', true);
        }
      } catch (_) {}

      downloadedProvinces = savedProvs.toSet();
      _hasAskedPermission = alreadyAsked;

      for (final vp in kVoiceProfiles) {
        final slot = prefs.getInt('dlini_slot_${vp.id}') ?? 0;
        _voiceSlot[vp.id] = slot.clamp(0, 1);
        final pinned = prefs.getInt('dlini_pinned_slot_${vp.id}');
        if (pinned != null) {
          _pinnedSlot[vp.id] = pinned.clamp(0, 1);
          _voiceSlot[vp.id] = pinned.clamp(0, 1);
        }
      }

      if (mounted) {
        setState(() {
          selectedVoiceIndex = savedVoice.clamp(0, kVoiceProfiles.length - 1);
          voiceSpeedLevel = savedSpeed.clamp(0, 2);
          isEnglish = savedLang;
          isDark = savedDark;
          showNotifPermissionModal = !alreadyAsked;
        });
      }

      // إذا كان قد سمح سابقاً، نشغل تتبع الموقع تلقائياً بالخلفية بدون إزعاجه بأي نافذة
      if (alreadyAsked) {
        _initLocationTracking(userInitiated: false);
      }
    } catch (_) {}
    await _loadAvailableVoicesOnce();
    await _applyVoiceProfile();
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dlini_voice_idx_v5', selectedVoiceIndex);
      await prefs.setInt('dlini_voice_speed_lvl', voiceSpeedLevel);
      await prefs.setBool('dlini_is_en', isEnglish);
      await prefs.setBool('dlini_is_dark_default_v2', isDark);
      await prefs.setStringList(
          'dlini_offline_provinces', downloadedProvinces.toList());
    } catch (_) {}
  }
// ==================== نهاية الجزء 2 من 6 ====================
// ==================== بداية الجزء 3 من 6 ====================
  // ==================== إعدادات ونظام التوجيه الصوتي (TTS) ====================
  Future<void> _loadAvailableVoicesOnce() async {
    try {
      final voices = await flutterTts.getVoices;
      if (voices is List) {
        _availableVoices = voices;
      }
    } catch (_) {}
  }

  Future<void> _applyVoiceProfile() async {
    try {
      final vp = currentVoice;
      final bool wantAr = vp.langType == 'ar';
      await flutterTts.setLanguage(wantAr ? 'ar-SA' : 'en-US');

      double rate = 0.50;
      if (voiceSpeedLevel == 0) rate = 0.42;
      if (voiceSpeedLevel == 2) rate = 0.58;

      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);

      if (_availableVoices.isNotEmpty) {
        final matching = _availableVoices.where((v) {
          if (v is Map) {
            final loc = (v['locale'] ?? '').toString().toLowerCase();
            return wantAr ? loc.startsWith('ar') : loc.startsWith('en');
          }
          return false;
        }).toList();

        if (matching.isNotEmpty) {
          final slot = (_voiceSlot[vp.id] ?? 0).clamp(0, matching.length - 1);
          final chosen = matching[slot];
          if (chosen is Map && chosen['name'] != null && chosen['locale'] != null) {
            await flutterTts.setVoice({
              'name': chosen['name'].toString(),
              'locale': chosen['locale'].toString(),
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _applyVoiceProfile();
      await flutterTts.stop();
      await flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> _cycleVoiceSlot(VoiceProfile vp) async {
    final current = _voiceSlot[vp.id] ?? 0;
    final next = (current + 1) % 2;
    setState(() {
      _voiceSlot[vp.id] = next;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_slot_${vp.id}', next);
    await _applyVoiceProfile();
    _speak(vp.langType == 'ar'
        ? 'مرحباً بك في تطبيق دلّيني، نتمنى لك قيادة آمنة'
        : 'Welcome to Dlinii navigation, drive safely');
  }

  Future<void> _togglePinSlot(VoiceProfile vp) async {
    final prefs = await SharedPreferences.getInstance();
    final curSlot = _voiceSlot[vp.id] ?? 0;
    if (_pinnedSlot[vp.id] == curSlot) {
      setState(() => _pinnedSlot.remove(vp.id));
      await prefs.remove('dlini_pinned_slot_${vp.id}');
      _toast(tr('تم إلغاء تثبيت النبرة', 'Voice tone unpinned'));
    } else {
      setState(() => _pinnedSlot[vp.id] = curSlot);
      await prefs.setInt('dlini_pinned_slot_${vp.id}', curSlot);
      _toast(tr('تم تثبيت هذه النبرة الصوتية 📌', 'Voice tone pinned 📌'));
    }
  }

  // ==================== الاتصال بـ Firestore (البلاغات والأماكن) ====================
  void _listenFirestoreStreams() {
    try {
      if (Firebase.apps.isEmpty) return;
      reportsSub = FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(120)
          .snapshots()
          .listen((snap) {
        if (mounted) {
          setState(() => cloudReports = snap.docs);
        }
      }, onError: (_) {});

      placesSub = FirebaseFirestore.instance
          .collection('custom_places')
          .limit(200)
          .snapshots()
          .listen((snap) {
        if (mounted) {
          setState(() => customPlaces = snap.docs);
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _sendReport(String typeAr, String typeEn, String emoji) async {
    final LatLng pt = me ?? mapController.camera.center;
    setState(() => showReportModal = false);
    _toast(tr('تم إرسال البلاغ لتحذير السائقين ($typeAr) $emoji',
        'Report submitted ($typeEn) $emoji'));
    _speak(tr('تم تسجيل بلاغ $typeAr، شكراً لمساهمتك',
        '$typeEn report submitted, thank you'));

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('reports').add({
          'type': typeAr,
          'typeEn': typeEn,
          'emoji': emoji,
          'lat': pt.latitude,
          'lng': pt.longitude,
          'endVotes': 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> _voteReportEnded(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final int votes = (data['endVotes'] as num?)?.toInt() ?? 0;
      if (votes + 1 >= endVotesThreshold) {
        await doc.reference.delete();
        _toast(tr('تم إزالة البلاغ لانتهاء الحالة ✅', 'Report removed ✅'));
      } else {
        await doc.reference.update({'endVotes': FieldValue.increment(1)});
        _toast(tr('تم تسجيل تصويتك بانتهاء الحالة 👍', 'Vote recorded 👍'));
      }
    } catch (_) {}
  }

  Future<void> _submitNewCustomPlace() async {
    final name = placeNameController.text.trim();
    if (name.isEmpty) {
      _toast(tr('يرجى كتابة اسم المكان أولاً', 'Please enter place name'));
      return;
    }
    final pt = pickedPlacePoint ?? me ?? mapController.camera.center;
    setState(() => showAddPlaceModal = false);
    placeNameController.clear();
    _toast(tr('تمت إضافة "$name" على الخريطة بنجاح 📍',
        '"$name" added to map successfully 📍'));

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('custom_places').add({
          'name': name,
          'category': selectedPlaceCategory,
          'lat': pt.latitude,
          'lng': pt.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  // ==================== تتبع الموقع الجغرافي (GPS) ====================
  Future<void> _initLocationTracking({required bool userInitiated}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (userInitiated) {
          _toast(tr('يرجى تشغيل موقع الهاتف (GPS)', 'Please enable device GPS'));
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        if (userInitiated) {
          perm = await Geolocator.requestPermission();
        } else {
          return;
        }
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (userInitiated) {
          _toast(tr('لم يتم منح صلاحية الوصول للموقع',
              'Location permission denied'));
        }
        return;
      }

      // حفظ أن المستخدم منح الإذن نهائياً حتى لا تظهر نافذة الطلب مرة أخرى أبداً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dlini_perm_asked_v3', true);
      if (mounted && showNotifPermissionModal) {
        setState(() => showNotifPermissionModal = false);
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _onPositionUpdate(pos, moveCameraImmediately: userInitiated);

      await positionStream?.cancel();
      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen((Position p) {
        _onPositionUpdate(p, moveCameraImmediately: false);
      });
    } catch (_) {}
  }

  void _onPositionUpdate(Position pos, {bool moveCameraImmediately = false}) {
    if (!mounted) return;
    if (simTimer != null && simTimer!.isActive) return;

    final rawLatLng = LatLng(pos.latitude, pos.longitude);
    double spd = (pos.speed * 3.6).clamp(0.0, 220.0);
    if (spd < 1.8) spd = 0.0;

    double brg = pos.heading;
    if (brg.isNaN || brg < 0 || spd < 2.0) {
      if (me != null && _distMeters(me!, rawLatLng) > 3.0) {
        brg = _bearingBetween(me!, rawLatLng);
      } else {
        brg = currentBearing;
      }
    }

    LatLng finalPos = rawLatLng;
    double finalBrg = brg;

    if (isNavigating && navCoords.length >= 2) {
      final snap = _snapToPolyline(rawLatLng, navCoords);
      if (_distMeters(rawLatLng, snap.point) <= 42.0) {
        finalPos = snap.point;
        if (spd >= 2.0) finalBrg = snap.bearing;
      }
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int dt = (nowMs - _lastFixMs).clamp(180, 1200);
    _lastFixMs = nowMs;

    _glideFromPos = _dispState.value.pos;
    _glideToPos = finalPos;
    _glideFromBearing = _dispState.value.bearing;
    _glideToBearing = finalBrg;

    setState(() {
      me = finalPos;
      origin ??= finalPos;
      currentSpeedKmh = spd;
      currentBearing = finalBrg;
    });

    _glideCtrl?.duration = Duration(milliseconds: dt);
    _glideCtrl?.forward(from: 0.0);

    if (moveCameraImmediately) {
      mapController.move(finalPos, 15.8);
    }

    if (isNavigating) {
      _updateNavigationState(finalPos, spd, finalBrg);
    }
  }

  void _centerOnMe() {
    setState(() => follow = true);
    if (me != null) {
      if (isNavigating && isFirstPerson3D) {
        mapController.moveAndRotate(
            _lookAhead(me!, currentBearing, 28), 17.8, -currentBearing);
      } else {
        mapController.moveAndRotate(me!, 15.8, 0.0);
      }
    } else {
      _initLocationTracking(userInitiated: true);
    }
  }

  // ==================== الدوال الهندسية وحساب الزوايا ====================
  double _distMeters(LatLng a, LatLng b) {
    const Distance d = Distance();
    return d.as(LengthUnit.Meter, a, b);
  }

  double _bearingBetween(LatLng a, LatLng b) {
    final double lat1 = a.latitude * math.pi / 180.0;
    final double lat2 = b.latitude * math.pi / 180.0;
    final double dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final double brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  double _lerpAngle(double a, double b, double t) {
    double diff = ((b - a + 540.0) % 360.0) - 180.0;
    return (a + diff * t + 360.0) % 360.0;
  }

  LatLng _lookAhead(LatLng pos, double bearingDeg, double distMeters) {
    final double rad = bearingDeg * math.pi / 180.0;
    final double dLat = (distMeters * math.cos(rad)) / 111320.0;
    final double dLng = (distMeters * math.sin(rad)) /
        (111320.0 * math.cos(pos.latitude * math.pi / 180.0));
    return LatLng(pos.latitude + dLat, pos.longitude + dLng);
  }

  _Snap _snapToPolyline(LatLng p, List<LatLng> line) {
    double bestDist = double.infinity;
    LatLng bestPt = p;
    double bestBrg = currentBearing;

    for (int i = 0; i < line.length - 1; i++) {
      final a = line[i];
      final b = line[i + 1];
      final double dx = b.longitude - a.longitude;
      final double dy = b.latitude - a.latitude;
      final double lenSq = dx * dx + dy * dy;
      double t = 0.0;
      if (lenSq > 1e-12) {
        t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
            lenSq;
        t = t.clamp(0.0, 1.0);
      }
      final proj = LatLng(a.latitude + t * dy, a.longitude + t * dx);
      final d = _distMeters(p, proj);
      if (d < bestDist) {
        bestDist = d;
        bestPt = proj;
        bestBrg = _bearingBetween(a, b);
      }
    }
    return _Snap(bestPt, bestBrg);
  }

  // ==================== البحث الصوتي والنصي واستكشاف الفئات ====================
  void _onSearchChanged(String val) {
    searchDebounce?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }
    searchDebounce = Timer(const Duration(milliseconds: 380), () {
      _performSearch(val.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => isSearching = true);
    final List<Map<String, dynamic>> combined = [];

    // 1. البحث في الأماكن المحلية المضافة من المستخدمين
    for (final doc in customPlaces) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final name = (data['name'] ?? '').toString();
      if (name.toLowerCase().contains(query.toLowerCase())) {
        combined.add({
          'display_name': '$name (${data['category'] ?? ''})',
          'lat': (data['lat'] as num).toDouble(),
          'lon': (data['lng'] as num).toDouble(),
        });
      }
    }

    // 2. البحث في مدن ومحافظات العراق المخزنة محلياً (يعمل حتى بدون إنترنت)
    for (final city in kIraqiCityLabels) {
      if (city.nameAr.contains(query) ||
          city.nameEn.toLowerCase().contains(query.toLowerCase())) {
        combined.add({
          'display_name': '${city.nameAr} - ${city.nameEn}',
          'lat': city.point.latitude,
          'lon': city.point.longitude,
        });
      }
    }

    // 3. البحث السحابي الشامل في العراق عبر Nominatim
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&countrycodes=iq&format=json&limit=8&accept-language=${isEnglish ? 'en' : 'ar'}');
      final res = await http.get(uri, headers: {
        'User-Agent': 'DliniiIraqNavigation/2.0 (com.dlinii.app)'
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List;
        for (final item in data) {
          combined.add({
            'display_name': item['display_name'].toString(),
            'lat': double.tryParse(item['lat'].toString()) ?? 33.4258,
            'lon': double.tryParse(item['lon'].toString()) ?? 43.2995,
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        searchResults = combined;
        isSearching = false;
      });
    }
  }

  Future<void> _toggleVoiceSearch() async {
    if (isListeningVoice) {
      await speech.stop();
      setState(() => isListeningVoice = false);
      return;
    }
    try {
      final avail = await speech.initialize();
      if (!avail) {
        _toast(tr('البحث الصوتي غير مدعوم على هذا الجهاز',
            'Voice search not available'));
        return;
      }
      setState(() => isListeningVoice = true);
      await speech.listen(
        localeId: isEnglish ? 'en_US' : 'ar_IQ',
        onResult: (res) {
          if (res.recognizedWords.isNotEmpty) {
            searchController.text = res.recognizedWords;
            _onSearchChanged(res.recognizedWords);
          }
          if (res.finalResult && mounted) {
            setState(() => isListeningVoice = false);
          }
        },
      );
    } catch (_) {
      setState(() => isListeningVoice = false);
    }
  }

  // ==================== مشاركة الموقع وميزة "دلّي صديق" عبر موقعك ====================
  Future<void> _shareFriendLocation({LatLng? target, String? label}) async {
    final LatLng pt = target ?? dest ?? me ?? mapController.camera.center;
    final String placeName = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : (destTitle.isNotEmpty
            ? destTitle
            : tr('موقعي على الخريطة', 'My Location'));

    final String latStr = pt.latitude.toStringAsFixed(6);
    final String lngStr = pt.longitude.toStringAsFixed(6);
    final String encodedName = Uri.encodeComponent(placeName);

    // الرابط الرسمي لموقعك على Vercel الذي يفتح تطبيق دلّيني مباشرة
    final String dliniiWebUrl =
        '$webAppDomain/?lat=$latStr&lng=$lngStr&name=$encodedName';

    final String message = isEnglish
        ? '📍 Open "$placeName" directly in Dlinii App:\n$dliniiWebUrl'
        : '📍 افتح الموقع "$placeName" مباشرة عبر تطبيق دلّيني:\n$dliniiWebUrl';

    await Clipboard.setData(ClipboardData(text: message));
    _toast(tr('تم نسخ رابط "دلّي صديق" ($webAppDomain) 📋',
        'Dlinii share link copied 📋'));

    final Uri waUrl =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
// ==================== نهاية الجزء 3 من 6 ====================
// ==================== بداية الجزء 4 من 6 ====================
  // ==================== استكشاف الخدمات والفئات على الخريطة ====================
  Future<void> _selectExploreCategory(ExploreCategory cat) async {
    if (activeCategoryId == cat.id) {
      setState(() {
        activeCategoryId = null;
        categoryMapMarkers = [];
      });
      return;
    }

    setState(() {
      activeCategoryId = cat.id;
      categoryMapMarkers = [];
    });

    final center = mapController.camera.center;
    _toast(tr('جاري البحث عن ${cat.nameAr} القريبة...',
        'Searching nearby ${cat.nameEn}...'));

    final List<Marker> foundMarkers = [];

    // 1. فحص الأماكن المضافة محلياً من المستخدمين أولاً
    for (final doc in customPlaces) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final name = (data['name'] ?? '').toString();
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final pt = LatLng(lat, lng);
        if (_distMeters(center, pt) <= 15000) {
          foundMarkers.add(_buildPoiMarker(pt, name, cat.color, cat.icon));
        }
      }
    }

    // 2. البحث عبر Overpass API في المنطقة المحيطة
    try {
      final double d = 0.08;
      final String bbox =
          '${center.latitude - d},${center.longitude - d},${center.latitude + d},${center.longitude + d}';
      final String query =
          '[out:json][timeout:8];(node["${cat.osmKey}"="${cat.osmVal}"]($bbox);way["${cat.osmKey}"="${cat.osmVal}"]($bbox););out center 25;';
      final res = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final List elements = (data['elements'] as List?) ?? [];
        for (final el in elements) {
          double? lat = (el['lat'] as num?)?.toDouble();
          double? lon = (el['lon'] as num?)?.toDouble();
          if (lat == null && el['center'] is Map) {
            lat = (el['center']['lat'] as num?)?.toDouble();
            lon = (el['center']['lon'] as num?)?.toDouble();
          }
          if (lat != null && lon != null) {
            final tags = (el['tags'] as Map?) ?? {};
            final String title = (tags['name:ar'] ??
                    tags['name'] ??
                    tags['name:en'] ??
                    tr(cat.nameAr, cat.nameEn))
                .toString();
            final pt = LatLng(lat, lon);
            foundMarkers.add(_buildPoiMarker(pt, title, cat.color, cat.icon));
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        categoryMapMarkers = foundMarkers;
      });
      if (foundMarkers.isEmpty) {
        _toast(tr('لم يتم العثور على ${cat.nameAr} قريبة في هذا النطاق',
            'No nearby ${cat.nameEn} found in this area'));
      }
    }
  }

  Marker _buildPoiMarker(
      LatLng pt, String title, Color color, IconData iconData) {
    return Marker(
      point: pt,
      width: 110,
      height: 62,
      child: GestureDetector(
        onTap: () => _selectDestination(pt, title),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6)
                ],
              ),
              child: Icon(iconData, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== اختيار الوجهة وحساب المسارات (أونلاين وأوفلاين) ====================
  Future<void> _selectDestination(LatLng pt, String title) async {
    FocusScope.of(context).unfocus();
    final LatLng startPt = me ?? origin ?? mapController.camera.center;

    setState(() {
      origin = startPt;
      dest = pt;
      destTitle = title.isNotEmpty
          ? title
          : tr('موقع محدد على الخريطة', 'Selected Map Location');
      destController.text = destTitle;
      searchResults = [];
      showPlanSheet = true;
      showNavSheet = false;
      isNavigating = false;
      selectedRouteIndex = 0;
    });

    await _calculateRoutes();
  }

  Map<String, dynamic> _buildOfflineFallbackRoute(LatLng start, LatLng end) {
    final List<LatLng> pts = [];
    const int segments = 24;
    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double lat = start.latitude + (end.latitude - start.latitude) * t;
      final double lng = start.longitude + (end.longitude - start.longitude) * t;
      pts.add(LatLng(lat, lng));
    }

    final double distM = _distMeters(start, end) * 1.18;
    final double durS = (distM / 13.5).clamp(60.0, 86400.0);

    return {
      'distance': distM,
      'duration': durS,
      'geometry': {
        'coordinates': pts.map((p) => [p.longitude, p.latitude]).toList(),
      },
      'legs': [
        {
          'steps': [
            {
              'distance': distM,
              'duration': durS,
              'name': destTitle,
              'maneuver': {
                'type': 'depart',
                'modifier': 'straight',
                'location': [start.longitude, start.latitude],
              }
            },
            {
              'distance': 0.0,
              'duration': 0.0,
              'name': destTitle,
              'maneuver': {
                'type': 'arrive',
                'modifier': 'straight',
                'location': [end.longitude, end.latitude],
              }
            }
          ]
        }
      ]
    };
  }

  Future<void> _calculateRoutes() async {
    if (origin == null || dest == null) return;
    setState(() => isCalculatingRoute = true);

    List<dynamic> fetchedRoutes = [];

    if (!_forceOffline) {
      try {
        final String coordsStr =
            '${origin!.longitude},${origin!.latitude};${dest!.longitude},${dest!.latitude}';
        final Uri url = Uri.parse(
            'https://router.project-osrm.org/route/v1/driving/$coordsStr?overview=full&geometries=geojson&alternatives=true&steps=true');

        final res = await http.get(url).timeout(const Duration(seconds: 7));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if (data['routes'] is List && (data['routes'] as List).isNotEmpty) {
            fetchedRoutes = data['routes'] as List;
          }
        }
      } catch (_) {}
    }

    // في حال انقطاع الإنترنت نستخدم التوجيه المحلي الأوفلاين تلقائياً
    if (fetchedRoutes.isEmpty) {
      fetchedRoutes = [_buildOfflineFallbackRoute(origin!, dest!)];
    }

    if (mounted) {
      setState(() {
        routes = fetchedRoutes;
        selectedRouteIndex = 0;
        isCalculatingRoute = false;
      });
      _fitRouteBounds();
    }
  }

  void _fitRouteBounds() {
    if (origin == null || dest == null) return;
    try {
      final bounds = LatLngBounds.fromPoints([origin!, dest!]);
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(55, 130, 55, 260),
          maxZoom: 16.0,
        ),
      );
    } catch (_) {}
  }

  // ==================== تلوين مقاطع البلاغات الفعلية فقط (إصلاح الخط الأصفر) ====================
  // المسار الأساسي يكون أخضر دائماً، ولا يتلون بالأصفر أو الأحمر إلا في موقع البلاغ الفعلي!
  List<Polyline> _buildRealTrafficAndHazardOverlays(
      Map<String, dynamic> route, List<LatLng> fullPoints) {
    final List<Polyline> overlays = [];
    if (fullPoints.length < 2 || cloudReports.isEmpty) return overlays;

    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final double? rLat = (data['lat'] as num?)?.toDouble();
      final double? rLng = (data['lng'] as num?)?.toDouble();
      if (rLat == null || rLng == null) continue;

      final LatLng reportPt = LatLng(rLat, rLng);
      final String typeAr = (data['type'] ?? '').toString();
      final String typeEn = (data['typeEn'] ?? '').toString().toLowerCase();

      // تحديد اللون حسب نوع البلاغ الحقيقي:
      // أحمر: للازدحام المروري أو الحوادث أو الطرق المغلقة
      // أصفر: للمطبات أو الحفريات أو السيطرات أو الرادار أو التنبيهات
      final bool isRedSeverity = typeAr.contains('ازدحام') ||
          typeAr.contains('حادث') ||
          typeAr.contains('مغلق') ||
          typeEn.contains('traffic') ||
          typeEn.contains('accident') ||
          typeEn.contains('closed');

      final Color segColor = isRedSeverity
          ? const Color(0xFFef4444) // أحمر للازدحام والحوادث
          : const Color(0xFFf59e0b); // أصفر للبلاغات التحذيرية والمطبات والسيطرات

      // تلوين المقطع القريب من البلاغ فقط (ضمن 130 متر عن خط المسار)
      final List<LatLng> affectedSegment = [];
      for (int i = 0; i < fullPoints.length; i++) {
        if (_distMeters(fullPoints[i], reportPt) <= 130.0) {
          if (affectedSegment.isEmpty && i > 0) {
            affectedSegment.add(fullPoints[i - 1]);
          }
          affectedSegment.add(fullPoints[i]);
        } else if (affectedSegment.length >= 2) {
          overlays.add(
            Polyline(
              points: List<LatLng>.from(affectedSegment),
              color: segColor,
              strokeWidth: 7.5,
            ),
          );
          affectedSegment.clear();
        } else {
          affectedSegment.clear();
        }
      }

      if (affectedSegment.length >= 2) {
        overlays.add(
          Polyline(
            points: List<LatLng>.from(affectedSegment),
            color: segColor,
            strokeWidth: 7.5,
          ),
        );
      }
    }

    return overlays;
  }

  // ==================== بدء الملاحة الحقيقية والمحاكاة ====================
  void _startNav() {
    if (routes.isEmpty) return;
    simTimer?.cancel();

    final route = routes[selectedRouteIndex] as Map<String, dynamic>;
    final List<dynamic> coords = route['geometry']['coordinates'] as List;
    navCoords = coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    final legs = (route['legs'] as List?) ?? [];
    navSteps = legs.isNotEmpty ? ((legs[0]['steps'] as List?) ?? []) : [];
    currentStepIndex = 0;
    lastSpokenStep = -1;
    warnedReports.clear();

    final startPos = me ?? origin ?? (navCoords.isNotEmpty ? navCoords.first : kDefaultCenter);
    final initBrg = navCoords.length >= 2
        ? _bearingBetween(navCoords[0], navCoords[1])
        : currentBearing;

    setState(() {
      isNavigating = true;
      showPlanSheet = false;
      showNavSheet = true;
      follow = true;
      isFirstPerson3D = true;
      currentBearing = initBrg;
    });

    _dispState.value = _DispState(startPos, initBrg);
    mapController.moveAndRotate(_lookAhead(startPos, initBrg, 28), 17.8, -initBrg);

    _updateNavigationState(startPos, currentSpeedKmh, initBrg);
    _speak(tr('بدأت الرحلة عبر تطبيق دلّيني، رافقتك السلامة',
        'Navigation started with Dlinii, drive safely'));
  }

  void _startSimulation() {
    if (routes.isEmpty) return;
    _startNav();

    int simIdx = 0;
    simTimer?.cancel();
    simTimer = Timer.periodic(const Duration(milliseconds: 520), (timer) {
      if (!mounted || !isNavigating || simIdx >= navCoords.length - 1) {
        timer.cancel();
        if (mounted && isNavigating) {
          _speak(tr('لقد وصلت إلى وجهتك بنجاح', 'You have arrived at your destination'));
          _stopNav();
        }
        return;
      }

      final cur = navCoords[simIdx];
      final nxt = navCoords[simIdx + 1];
      final brg = _bearingBetween(cur, nxt);

      _glideFromPos = _dispState.value.pos;
      _glideToPos = nxt;
      _glideFromBearing = _dispState.value.bearing;
      _glideToBearing = brg;

      setState(() {
        me = nxt;
        currentSpeedKmh = 54.0;
        currentBearing = brg;
      });

      _glideCtrl?.duration = const Duration(milliseconds: 480);
      _glideCtrl?.forward(from: 0.0);

      _updateNavigationState(nxt, 54.0, brg);
      simIdx++;
    });
  }

  void _stopNav() {
    simTimer?.cancel();
    setState(() {
      isNavigating = false;
      showNavSheet = false;
      showPlanSheet = false;
      isFirstPerson3D = false;
      routes = [];
      navCoords = [];
      navSteps = [];
      dest = null;
      destTitle = '';
      currentSpeedKmh = 0.0;
    });
    if (me != null) {
      mapController.moveAndRotate(me!, 15.0, 0.0);
    }
  }

  void _updateNavigationState(LatLng pos, double spdKmh, double brg) {
    if (dest == null) return;

    final double remMeters = _distMeters(pos, dest!);
    final double remKm = remMeters / 1000.0;
    final int remMins =
        (remMeters / ((spdKmh > 15 ? spdKmh : 40.0) * 16.66)).ceil().clamp(1, 999);
    final DateTime etaTime = DateTime.now().add(Duration(minutes: remMins));
    final String etaStr =
        '${etaTime.hour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')}';

    String arrow = '⬆️';
    String instr = tr('استمر بالسير في طريقك', 'Continue straight ahead');
    String street = destTitle;

    if (navSteps.isNotEmpty) {
      for (int i = currentStepIndex; i < navSteps.length; i++) {
        final step = navSteps[i] as Map<String, dynamic>;
        final man = (step['maneuver'] as Map<String, dynamic>?) ?? {};
        final loc = (man['location'] as List?) ?? [];
        if (loc.length >= 2) {
          final stepPt =
              LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
          final d = _distMeters(pos, stepPt);
          if (d < 32.0 && i < navSteps.length - 1) {
            currentStepIndex = i + 1;
          }
          break;
        }
      }

      final curStep =
          navSteps[currentStepIndex.clamp(0, navSteps.length - 1)] as Map<String, dynamic>;
      final formatted = _formatStepInstruction(curStep);
      arrow = formatted['arrow']!;
      instr = formatted['text']!;
      street = formatted['street']!;

      if (lastSpokenStep != currentStepIndex) {
        lastSpokenStep = currentStepIndex;
        _speak(instr);
      }
    }

    // تنبيه صوتي تلقائي عند الاقتراب من أي بلاغ على الطريق (ضمن 220 متر)
    for (final doc in cloudReports) {
      if (warnedReports.contains(doc.id)) continue;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final rLat = (data['lat'] as num?)?.toDouble();
      final rLng = (data['lng'] as num?)?.toDouble();
      if (rLat != null && rLng != null) {
        final d = _distMeters(pos, LatLng(rLat, rLng));
        if (d <= 220.0) {
          warnedReports.add(doc.id);
          final tAr = (data['type'] ?? 'تنبيه').toString();
          final tEn = (data['typeEn'] ?? 'Hazard').toString();
          _speak(tr('انتبه، يوجد بلاغ $tAr أمامك على بعد مئتي متر',
              'Caution, $tEn reported two hundred meters ahead'));
        }
      }
    }

    if (remMeters <= 35.0) {
      _speak(tr('لقد وصلت إلى وجهتك، الحمد لله على السلامة',
          'You have arrived at your destination'));
      _stopNav();
      return;
    }

    setState(() {
      navRemKm = remKm.toStringAsFixed(1);
      navRemMins = remMins.toString();
      navEta = etaStr;
      hudArrow = arrow;
      hudInstruction = instr;
      hudStreet = street;
    });
  }

  Map<String, String> _formatStepInstruction(Map<String, dynamic> step) {
    final man = (step['maneuver'] as Map<String, dynamic>?) ?? {};
    final String type = (man['type'] ?? '').toString();
    final String mod = (man['modifier'] ?? '').toString();
    final String rawName = (step['name'] ?? '').toString().trim();
    final String streetName = rawName.isNotEmpty ? rawName : destTitle;

    String arrow = '⬆️';
    String actionAr = 'استمر بالسير للأمام';
    String actionEn = 'Continue straight';

    if (type == 'arrive') {
      arrow = '🏁';
      actionAr = 'ستصل إلى وجهتك';
      actionEn = 'You will arrive at';
    } else if (type == 'roundabout' || type == 'rotary') {
      arrow = '🔄';
      actionAr = 'ادخل الفلكة (الدوار) ثم اتجه نحو';
      actionEn = 'Enter the roundabout towards';
    } else if (mod.contains('left')) {
      arrow = '⬅️';
      actionAr = mod.contains('slight') ? 'انحرف قليلاً لليسار نحو' : 'انعطف يساراً نحو';
      actionEn = mod.contains('slight') ? 'Keep left onto' : 'Turn left onto';
    } else if (mod.contains('right')) {
      arrow = '➡️';
      actionAr = mod.contains('slight') ? 'انحرف قليلاً لليمين نحو' : 'انعطف يميناً نحو';
      actionEn = mod.contains('slight') ? 'Keep right onto' : 'Turn right onto';
    } else if (mod.contains('uturn')) {
      arrow = '↩️';
      actionAr = 'قم بالاستدارة للخلف (يو تيرن) نحو';
      actionEn = 'Make a U-turn onto';
    }

    return {
      'arrow': arrow,
      'text': isEnglish ? '$actionEn $streetName' : '$actionAr $streetName',
      'street': streetName,
    };
  }

  // ==================== تحميل خرائط المحافظات الـ 18 للعمل بدون إنترنت ====================
  Future<void> _downloadProvinceOffline(IraqProvince prov) async {
    if (downloadingProvinceId != null) return;

    setState(() {
      downloadingProvinceId = prov.id;
      downloadProgress = 0.05;
    });

    try {
      final List<TileCoordinates> tilesToFetch = [];
      for (int z = 11; z <= 13; z++) {
        final centerTile = _latLngToTile(prov.center, z);
        final int radius = z == 11 ? 2 : (z == 12 ? 3 : 4);
        for (int dx = -radius; dx <= radius; dx++) {
          for (int dy = -radius; dy <= radius; dy++) {
            tilesToFetch.add(TileCoordinates(centerTile.x + dx, centerTile.y + dy, z));
          }
        }
      }

      Directory? tilesDir;
      if (!kIsWeb && _offlineBaseDir != null) {
        tilesDir = Directory('$_offlineBaseDir/tiles');
        if (!tilesDir.existsSync()) {
          tilesDir.createSync(recursive: true);
        }
      }

      int completed = 0;
      for (final tc in tilesToFetch) {
        if (!mounted) break;
        if (tilesDir != null) {
          final file = File('${tilesDir.path}/${tc.z}_${tc.x}_${tc.y}.png');
          if (!file.existsSync()) {
            try {
              final url = Uri.parse(
                  'https://a.basemaps.cartocdn.com/rastertiles/voyager/${tc.z}/${tc.x}/${tc.y}.png');
              final res = await http.get(url).timeout(const Duration(seconds: 4));
              if (res.statusCode == 200 && res.bodyBytes.length > 100) {
                await file.writeAsBytes(res.bodyBytes);
              }
            } catch (_) {}
          }
        } else {
          await Future.delayed(const Duration(milliseconds: 15));
        }

        completed++;
        if (mounted && completed % 5 == 0) {
          setState(() {
            downloadProgress = (completed / tilesToFetch.length).clamp(0.05, 1.0);
          });
        }
      }

      setState(() {
        downloadedProvinces.add(prov.id);
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });
      await _savePrefs();
      _toast(tr('تم حفظ خريطة ${prov.nameAr} للعمل بدون إنترنت ✅',
          '${prov.nameEn} offline map saved ✅'));
    } catch (_) {
      if (mounted) {
        setState(() {
          downloadingProvinceId = null;
          downloadProgress = 0.0;
        });
      }
    }
  }

  math.Point<int> _latLngToTile(LatLng pt, int zoom) {
    final double n = math.pow(2.0, zoom).toDouble();
    final int x = ((pt.longitude + 180.0) / 360.0 * n).floor();
    final double latRad = pt.latitude * math.pi / 180.0;
    final int y =
        ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
                2.0 *
                n)
            .floor();
    return math.Point<int>(x, y);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF087e76),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }
// ==================== نهاية الجزء 4 من 6 ====================
// ==================== بداية الجزء 5 من 6 ====================
  @override
  Widget build(BuildContext context) {
    if (showSplash) {
      return Scaffold(
        backgroundColor: const Color(0xFF0b1918),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF087e76),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF7ce0be), blurRadius: 24)
                  ],
                ),
                child: SvgPicture.string(kGreenNavArrowSvg),
              ),
              const SizedBox(height: 24),
              const Text(
                'دلّيني | Dlinii',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('رفيقك الذكي للطرق والرحلات في العراق',
                    'Your smart navigation companion in Iraq'),
                style: const TextStyle(
                  color: Color(0xFF94a3b8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 36),
              const CircularProgressIndicator(
                color: Color(0xFF7ce0be),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0b1918) : const Color(0xFFf0fdfa),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildMainMap(),
          _buildTopSearchBar(),
          _buildFloatingControls(),
          if (showPlanSheet) _buildRoutePlanSheet(),
          if (showNavSheet) _buildActiveNavigationHud(),
        ],
      ),
    );
  }

  // ==================== الخريطة الرئيسية وتوابعها ====================
  Widget _buildMainMap() {
    final ofmLayer = (isDark ? vectorThemeDark : vectorThemeLight) != null &&
            vectorTileProviders != null
        ? vt.VectorTileLayer(
            tileProviders: vectorTileProviders!,
            theme: (isDark ? vectorThemeDark : vectorThemeLight)!,
            maximumZoom: 20,
          )
        : null;

    final List<Polyline> polylines = [];

    // 1. رسم مسارات البدائل إن وجدت
    if (routes.isNotEmpty) {
      for (int i = 0; i < routes.length; i++) {
        if (i == selectedRouteIndex) continue;
        final route = routes[i] as Map<String, dynamic>;
        final List<dynamic> coords =
            (route['geometry']['coordinates'] as List?) ?? [];
        final pts = coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        if (pts.length >= 2) {
          polylines.add(
            Polyline(
              points: pts,
              color: isDark ? Colors.white24 : Colors.black26,
              strokeWidth: 4.0,
            ),
          );
        }
      }

      // 2. رسم المسار الرئيسي المحدد مع مقاطع البلاغات الفعلية (أصفر/أحمر)
      final mainRoute = routes[selectedRouteIndex] as Map<String, dynamic>;
      final List<dynamic> mainCoords =
          (mainRoute['geometry']['coordinates'] as List?) ?? [];
      final mainPts = mainCoords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      if (mainPts.length >= 2) {
        polylines.add(
          Polyline(
            points: mainPts,
            color: isDark ? const Color(0xFF6ee7b7) : const Color(0xFF087e76),
            strokeWidth: 5.5,
          ),
        );

        // مقاطع التحذيرات والبلاغات الموضعية على المسار
        polylines.addAll(_buildRealTrafficAndHazardOverlays(mainRoute, mainPts));
      }
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: kDefaultCenter,
        initialZoom: currentMapZoom,
        maxZoom: 20.0,
        minZoom: 4.0,
        onPositionChanged: (pos, hasGesture) {
          if (hasGesture && follow) {
            setState(() => follow = false);
          }
          currentMapZoom = pos.zoom;
        },
        onTap: (_, pt) {
          if (!isNavigating) {
            setState(() {
              pickedPlacePoint = pt;
              showAddPlaceModal = true;
            });
          }
        },
      ),
      children: [
        if (ofmLayer != null && !_forceOffline)
          ofmLayer
        else
          ColorFiltered(
            key: ValueKey<String>(isDark ? 'raster_dark' : 'raster_light'),
            colorFilter: isDark
                ? kInstantDarkFilter
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              maxZoom: 20,
              userAgentPackageName: 'com.dlinii.app',
              tileProvider: _offlineTileProvider,
            ),
          ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(
          markers: [
            ...categoryMapMarkers,
            // دبابيس البلاغات السحابية على الخريطة
            ...cloudReports.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
              final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
              final emoji = (data['emoji'] ?? '⚠️').toString();
              final type = (data['type'] ?? '').toString();
              return Marker(
                point: LatLng(lat, lng),
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => _voteReportEnded(doc),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142e2d),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFefbb52), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 6)
                      ],
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              );
            }),
            // دبابيس الأماكن المضافة محلياً
            ...customPlaces.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
              final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
              final name = (data['name'] ?? '').toString();
              return Marker(
                point: LatLng(lat, lng),
                width: 90,
                height: 54,
                child: GestureDetector(
                  onTap: () => _selectDestination(LatLng(lat, lng), name),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF087e76),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.place_rounded,
                            color: Colors.white, size: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          name,
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // تسميات المدن والمناطق العراقية الثابتة بوضوح لمنع المربعات
            ...kIraqiCityLabels.where((c) => currentMapZoom >= c.minZoom).map(
                  (c) => Marker(
                    point: c.point,
                    width: 120,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _selectDestination(c.point, c.nameAr),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF7ce0be).withOpacity(0.4),
                              width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c.nameAr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            if (origin != null)
              Marker(
                point: origin!,
                width: 44,
                height: 44,
                child: SvgPicture.string(kOriginPinSvg),
              ),
            if (dest != null)
              Marker(
                point: dest!,
                width: 48,
                height: 56,
                child: SvgPicture.string(kDestPinSvg),
              ),
            if (me != null)
              Marker(
                point: me!,
                width: 64,
                height: 64,
                child: ValueListenableBuilder<_DispState>(
                  valueListenable: _dispState,
                  builder: (context, st, _) {
                    return Transform.rotate(
                      angle: isNavigating && isFirstPerson3D
                          ? 0.0
                          : (st.bearing * math.pi / 180.0),
                      child: SvgPicture.string(
                          isNavigating ? kGreenNavArrowSvg : kMyLocationPulseSvg),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
// ==================== نهاية الجزء 5 من 6 ====================
// ==================== بداية الجزء 6 والأخير ====================
  // ==================== شريط البحث العلوي والفئات السريعة ====================
  Widget _buildTopSearchBar() {
    return Positioned(
      top: 48,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF142e2d) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark ? const Color(0xFF284e4b) : const Color(0xFF7ce0be),
                  width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu_rounded,
                      color: isDark ? const Color(0xFF7ce0be) : const Color(0xFF087e76)),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: tr('إلى أين تريد الذهاب في العراق؟',
                          'Where to in Iraq?'),
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF94a3b8) : Colors.black45,
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isListeningVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: isListeningVoice
                        ? Colors.redAccent
                        : (isDark ? const Color(0xFF7ce0be) : const Color(0xFF087e76)),
                  ),
                  onPressed: _toggleVoiceSearch,
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
            ),
          ),
          if (searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142e2d) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF284e4b), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10)
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final item = searchResults[index];
                  final String name = item['display_name'] ?? '';
                  final double lat = item['lat'];
                  final double lon = item['lon'];
                  return ListTile(
                    leading: const Icon(Icons.location_on_rounded,
                        color: Color(0xFF7ce0be)),
                    title: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => _selectDestination(LatLng(lat, lon), name),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: kExploreCategories.map((cat) {
                final bool active = activeCategoryId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ActionChip(
                    avatar: Icon(cat.icon, color: Colors.white, size: 15),
                    label: Text(
                      tr(cat.nameAr, cat.nameEn),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    backgroundColor: active ? const Color(0xFF087e76) : cat.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onPressed: () => _selectExploreCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== أزرار التحكم الطافية على الخريطة ====================
  Widget _buildFloatingControls() {
    return Positioned(
      right: 16,
      bottom: isNavigating ? 140 : 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'btn_report',
            backgroundColor: const Color(0xFFefbb52),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFF142e2d)),
            onPressed: () => setState(() => showReportModal = true),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'btn_offline',
            backgroundColor: const Color(0xFF152928),
            child: const Icon(Icons.offline_bolt_rounded,
                color: Color(0xFF7ce0be)),
            onPressed: () => setState(() => showOfflineModal = true),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'btn_gps',
            backgroundColor: const Color(0xFF087e76),
            child: SvgPicture.string(kGpsTargetSvg, width: 22, height: 22),
            onPressed: _centerOnMe,
          ),
        ],
      ),
    );
  }

  // ==================== نافذة خطة الرحلة وبدء الملاحة ====================
  Widget _buildRoutePlanSheet() {
    final route = routes.isNotEmpty
        ? (routes[selectedRouteIndex] as Map<String, dynamic>)
        : null;
    final double distKm = route != null ? ((route['distance'] as num?) ?? 0) / 1000.0 : 0.0;
    final double durMin = route != null ? (((route['duration'] as num?) ?? 0) / 60.0).ceil().toDouble() : 0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF142e2d) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(
              color: isDark ? const Color(0xFF284e4b) : const Color(0xFF7ce0be),
              width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place_rounded, color: Color(0xFF7ce0be)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => setState(() {
                    showPlanSheet = false;
                    dest = null;
                    routes = [];
                  }),
                ),
              ],
            ),
            const Divider(color: Color(0xFF284e4b)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCard(Icons.timer_rounded, '${durMin.toInt()} دقيقة',
                    '${distKm.toStringAsFixed(1)} كم'),
                _infoCard(Icons.speed_rounded, tr('الأسرع', 'Fastest Route'),
                    tr('عبر الطرق الآمنة', 'Safe Corridor')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassTapButton(
                    backgroundColor: const Color(0xFF152928),
                    borderColor: const Color(0xFF7ce0be),
                    onTap: _startSimulation,
                    child: Text(
                      tr('محاكاة الرحلة', 'Simulate'),
                      style: const TextStyle(
                          color: Color(0xFF7ce0be),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GlassTapButton(
                    backgroundColor: const Color(0xFF087e76),
                    borderColor: const Color(0xFF7ce0be),
                    onTap: _startNav,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          tr('انطلاق الرحلة', 'Start Navigation'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GlassTapButton(
              backgroundColor: const Color(0xFF262B33),
              borderColor: Colors.transparent,
              onTap: () => _shareFriendLocation(target: dest, label: destTitle),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_location_rounded,
                      color: Color(0xFFefbb52), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    tr('دلّي صديق (مشاركة موقع عبر رابط موقعك)',
                        'Share with Friend (Dlinii Link)'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String val, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0b1918) : const Color(0xFFf0fdfa),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF284e4b), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7ce0be), size: 18),
          const SizedBox(height: 4),
          Text(val,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
          Text(sub,
              style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 10)),
        ],
      ),
    );
  }

  // ==================== نافذة الملاحة النشطة أثناء القيادة ====================
  Widget _buildActiveNavigationHud() {
    return Positioned(
      top: 112,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF142e2d),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7ce0be), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF087e76),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(hudArrow, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hudInstruction,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hudStreet,
                        style: const TextStyle(
                            color: Color(0xFF7ce0be),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.stop_rounded, color: Colors.redAccent, size: 30),
                  onPressed: _stopNav,
                ),
              ],
            ),
            const Divider(color: Color(0xFF284e4b), height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr('المسافة:', 'Dist:')} $navRemKm ${tr('كم', 'km')} | ${tr('الوقت:', 'Time:')} $navRemMins ${tr('دقيقة', 'min')} | ETA: $navEta',
                  style: const TextStyle(
                      color: Color(0xFFefbb52),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  '${currentSpeedKmh.toStringAsFixed(0)} كم/س',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== القائمة الجانبية (Drawer) والنافذة الجانبية ====================
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0b1918) : Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF087e76),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: SvgPicture.string(kGreenNavArrowSvg, width: 30, height: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('دلّيني | Dlinii',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    Text(webAppDomain,
                        style: const TextStyle(
                            color: Color(0xFF7ce0be), fontSize: 11)),
                  ],
                ),
              ],
            ),
            const Divider(color: Color(0xFF284e4b), height: 28),
            ListTile(
              leading: const Icon(Icons.offline_bolt_rounded, color: Color(0xFF7ce0be)),
              title: Text(tr('خرائط بدون نت (18 محافظة)', 'Offline Maps (18 Provinces)'),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                setState(() => showOfflineModal = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_rounded, color: Color(0xFFefbb52)),
              title: Text(tr('إعدادات الصوت والنبرة', 'Voice Settings'),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                setState(() => showVoiceModal = true);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_rounded, color: Color(0xFF7ce0be)),
              title: Text(tr('الوضع الليلي', 'Dark Mode'),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700)),
              value: isDark,
              onChanged: (val) {
                setState(() => isDark = val);
                _savePrefs();
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.language_rounded, color: Color(0xFFefbb52)),
              title: const Text('English Language',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              value: isEnglish,
              onChanged: (val) {
                setState(() => isEnglish = val);
                _savePrefs();
              },
            ),
            const Divider(color: Color(0xFF284e4b), height: 28),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Color(0xFF7ce0be)),
              title: Text(tr('مشاركة موقعي (دلّي صديق)', 'Share My Location'),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _shareFriendLocation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Color(0xFFefbb52)),
              title: Text(tr('قيم التطبيق', 'Rate App'),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                setState(() => showRateModal = true);
              },
            ),
          ],
        ),
      ),
    );
  }
// ==================== نهاية الجزء السادس والأخير ====================