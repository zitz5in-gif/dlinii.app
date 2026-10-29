// ============================================================================
// بداية الجزء 1 من 5 - انسخ من هنا إلى بداية ملف lib/home_screen.dart
// ============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// نموذج بيانات المحافظات والمدن العراقية (لحل مشكلة المربعات ودعم الخرائط الأوفلاين)
class IraqiProvince {
  final String id;
  final String nameAr;
  final String subtitleAr;
  final LatLng center;
  final String sizeMb;
  final double defaultZoom;
  final bool isMajorProvince;

  const IraqiProvince({
    required this.id,
    required this.nameAr,
    required this.subtitleAr,
    required this.center,
    required this.sizeMb,
    this.defaultZoom = 12.5,
    this.isMajorProvince = true,
  });
}

/// نموذج مقاطع المسار الملونة:
/// - أخضر (#10B981): طريق سالك
/// - أصفر (#FACC15): منطقة بلاغ خطر / حفريات / سيطرة / كاميرا
/// - أحمر (#EF4444): ازدحام مروري شديد أو طريق مغلق
class ColoredRouteSegment {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final String statusLabel;

  const ColoredRouteSegment({
    required this.points,
    required this.color,
    this.strokeWidth = 6.5,
    this.statusLabel = 'سالك',
  });
}

/// نموذج البلاغات الميدانية التفاعلية
class RoadReport {
  final String id;
  final String
      type; // traffic, closed, hazard, camera, checkpoint, roadworks, accident
  final String titleAr;
  final String descriptionAr;
  final LatLng location;
  final DateTime timestamp;
  final int confirmations;

  const RoadReport({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.descriptionAr,
    required this.location,
    required this.timestamp,
    this.confirmations = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'titleAr': titleAr,
      'descriptionAr': descriptionAr,
      'lat': location.latitude,
      'lng': location.longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'confirmations': confirmations,
    };
  }

  factory RoadReport.fromDoc(String id, Map<String, dynamic> map) {
    return RoadReport(
      id: id,
      type: (map['type'] ?? 'hazard').toString(),
      titleAr: (map['titleAr'] ?? 'تنبيه طريق').toString(),
      descriptionAr:
          (map['descriptionAr'] ?? 'بلاغ من مستخدمي دلّيني').toString(),
      location: LatLng(
        ((map['lat'] ?? 33.4258) as num).toDouble(),
        ((map['lng'] ?? 43.2995) as num).toDouble(),
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch) as num)
            .toInt(),
      ),
      confirmations: ((map['confirmations'] ?? 1) as num).toInt(),
    );
  }
}

/// نموذج الأماكن المحفوظة للمستخدم
class SavedPlace {
  final String id;
  final String title;
  final String category; // home, work, university, favorite
  final LatLng coords;

  const SavedPlace({
    required this.id,
    required this.title,
    required this.category,
    required this.coords,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'lat': coords.latitude,
        'lng': coords.longitude,
      };

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
        id: json['id'].toString(),
        title: json['title'].toString(),
        category: (json['category'] ?? 'favorite').toString(),
        coords: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
      );
}

/// نموذج خطوات التوجيه خطوة بخطوة
class RouteStepItem {
  final String instructionAr;
  final String distanceText;
  final IconData icon;
  final LatLng location;

  const RouteStepItem({
    required this.instructionAr,
    required this.distanceText,
    required this.icon,
    required this.location,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ValueNotifiers لضمان أداء 60 إطار/ثانية بدون تقطيع أثناء حركة الـ GPS
  final ValueNotifier<LatLng> _userLocationNotifier = ValueNotifier<LatLng>(
      const LatLng(33.4258, 43.2995)); // الرمادي كمركز ابتدائي
  final ValueNotifier<double> _speedKmHNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _headingNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isNavigatingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _currentZoomNotifier =
      ValueNotifier<double>(13.5);

  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<QuerySnapshot>? _reportsStreamSub;
  Timer? _searchDebounceTimer;
  Timer? _proximityAlertTimer;

  // إعدادات ومتغيرات الحالة
  bool isDark = true;
  bool isSatelliteMode = false;
  bool isVoiceEnabled = true;
  bool isFollowingUser = true;
  bool isCarPlayHudMode = false;
  bool isLoadingRoute = false;
  bool isSearching = false;
  bool showArabicCityLabels = true;
  bool showTrafficLayer = true;
  bool hasLockedInitialGps = false;

  // إدارة التحميل الأوفلاين
  Set<String> downloadedProvinces = <String>{'anbar', 'baghdad'};
  Map<String, double> downloadProgress = <String, double>{};

  // بيانات المسار والبلاغات والبحث
  List<RoadReport> activeReports = <RoadReport>[];
  List<ColoredRouteSegment> routeSegments = <ColoredRouteSegment>[];
  List<LatLng> fullRoutePoints = <LatLng>[];
  List<RouteStepItem> routeSteps = <RouteStepItem>[];
  List<Map<String, dynamic>> searchSuggestions = <Map<String, dynamic>>[];
  List<SavedPlace> savedPlaces = <SavedPlace>[];

  LatLng? destinationPoint;
  String? destinationName;
  String routeDistanceText = '';
  String routeDurationText = '';
  String routeArrivalTimeText = '';
  String nextInstructionAr =
      'ابحث عن وجهتك أو اضغط مطولاً على الخريطة للانطلاق';
  int currentSpeedLimit = 80;
  String? lastAlertedReportId;

  // القائمة الكاملة للمحافظات والمدن العراقية (تمنع ظهور المربعات وتوفر وصولاً سريعاً)
  static const List<IraqiProvince> iraqiProvinces = [
    // مدن محافظة الأنبار التفصيلية
    IraqiProvince(
      id: 'anbar',
      nameAr: 'الرمادي - الأنبار',
      subtitleAr: 'مركز محافظة الأنبار والمناطق المحيطة',
      center: LatLng(33.4258, 43.2995),
      sizeMb: '48 MB',
      defaultZoom: 13.5,
    ),
    IraqiProvince(
      id: 'fallujah',
      nameAr: 'الفلوجة',
      subtitleAr: 'قضاء الفلوجة والطريق الدولي السريع',
      center: LatLng(33.3491, 43.7859),
      sizeMb: '28 MB',
      defaultZoom: 13.5,
      isMajorProvince: false,
    ),
    IraqiProvince(
      id: 'hit',
      nameAr: 'هيت',
      subtitleAr: 'قضاء هيت والبغدادي والمحمدي',
      center: LatLng(33.6366, 42.8277),
      sizeMb: '22 MB',
      defaultZoom: 13.5,
      isMajorProvince: false,
    ),
    IraqiProvince(
      id: 'haditha',
      nameAr: 'حديثة',
      subtitleAr: 'قضاء حديثة والحقلانية وبروانة',
      center: LatLng(34.1369, 42.3772),
      sizeMb: '21 MB',
      defaultZoom: 13.5,
      isMajorProvince: false,
    ),
    IraqiProvince(
      id: 'qaim',
      nameAr: 'القائم',
      subtitleAr: 'قضاء القائم والعبيدي والكرابلة وحصيبة',
      center: LatLng(34.3725, 41.0886),
      sizeMb: '26 MB',
      defaultZoom: 13.5,
      isMajorProvince: false,
    ),
    IraqiProvince(
      id: 'anah',
      nameAr: 'عانة وراوة',
      subtitleAr: 'أقضية عانة وراوة والطريق الغربي',
      center: LatLng(34.3686, 41.9819),
      sizeMb: '19 MB',
      defaultZoom: 13.0,
      isMajorProvince: false,
    ),
    IraqiProvince(
      id: 'rutba',
      nameAr: 'الرطبة',
      subtitleAr: 'قضاء الرطبة والطريق الدولي السريع',
      center: LatLng(33.0371, 40.2858),
      sizeMb: '30 MB',
      defaultZoom: 13.0,
      isMajorProvince: false,
    ),
    IraqiProvince(
      id: 'khalidiya',
      nameAr: 'الخالدية والحبانية',
      subtitleAr: 'الخالدية، الحبانية، والمدينة السياحية',
      center: LatLng(33.3833, 43.5333),
      sizeMb: '18 MB',
      defaultZoom: 13.5,
      isMajorProvince: false,
    ),
    // بقية محافظات العراق
    IraqiProvince(
      id: 'baghdad',
      nameAr: 'بغداد',
      subtitleAr: 'العاصمة بغداد - الكرخ والرصافة وضواحيها',
      center: LatLng(33.3152, 44.3661),
      sizeMb: '92 MB',
    ),
    IraqiProvince(
      id: 'basra',
      nameAr: 'البصرة',
      subtitleAr: 'مركز البصرة، الزبير، أم قصر، والفاو',
      center: LatLng(30.5081, 47.7835),
      sizeMb: '68 MB',
    ),
    IraqiProvince(
      id: 'nineveh',
      nameAr: 'نينوى - الموصل',
      subtitleAr: 'الموصل، تلعفر، الحمدانية، وسنجار',
      center: LatLng(36.3450, 43.1575),
      sizeMb: '75 MB',
    ),
    IraqiProvince(
      id: 'erbil',
      nameAr: 'أربيل',
      subtitleAr: 'مركز أربيل، شقلاوة، سوران، وكويسنجق',
      center: LatLng(36.1901, 44.0091),
      sizeMb: '58 MB',
    ),
    IraqiProvince(
      id: 'najaf',
      nameAr: 'النجف الأشرف',
      subtitleAr: 'النجف، الكوفة، والمناذرة',
      center: LatLng(32.0000, 44.3333),
      sizeMb: '41 MB',
    ),
    IraqiProvince(
      id: 'karbala',
      nameAr: 'كربلاء المقدسة',
      subtitleAr: 'مركز كربلاء، الهندية، وعين التمر',
      center: LatLng(32.6160, 44.0249),
      sizeMb: '39 MB',
    ),
    IraqiProvince(
      id: 'kirkuk',
      nameAr: 'كركوك',
      subtitleAr: 'مركز كركوك، الحويجة، وداقوق',
      center: LatLng(35.4681, 44.3922),
      sizeMb: '47 MB',
    ),
    IraqiProvince(
      id: 'babil',
      nameAr: 'بابل - الحلة',
      subtitleAr: 'الحلة، المسيب، المحاويل، والهاشمية',
      center: LatLng(32.4637, 44.4196),
      sizeMb: '44 MB',
    ),
    IraqiProvince(
      id: 'diyala',
      nameAr: 'ديالى - بعقوبة',
      subtitleAr: 'بعقوبة، الخالص، خانقين، والمقدادية',
      center: LatLng(33.7485, 44.6436),
      sizeMb: '49 MB',
    ),
    IraqiProvince(
      id: 'saladin',
      nameAr: 'صلاح الدين - تكريت',
      subtitleAr: 'تكريت، سامراء، بلد، وبيجي',
      center: LatLng(34.6095, 43.6833),
      sizeMb: '53 MB',
    ),
    IraqiProvince(
      id: 'sulaymaniyah',
      nameAr: 'السليمانية',
      subtitleAr: 'مركز السليمانية، حلبجة، ورانية',
      center: LatLng(35.5558, 45.4351),
      sizeMb: '54 MB',
    ),
    IraqiProvince(
      id: 'duhok',
      nameAr: 'دهوك',
      subtitleAr: 'دهوك، زاخو، والعمادية',
      center: LatLng(36.8671, 42.9884),
      sizeMb: '38 MB',
    ),
    IraqiProvince(
      id: 'wasit',
      nameAr: 'واسط - الكوت',
      subtitleAr: 'الكوت، الصويرة، النعمانية، والحي',
      center: LatLng(32.5128, 45.8182),
      sizeMb: '43 MB',
    ),
    IraqiProvince(
      id: 'dhiqar',
      nameAr: 'ذي قار - الناصرية',
      subtitleAr: 'الناصرية، الشطرة، وسوق الشيوخ',
      center: LatLng(31.0439, 46.2573),
      sizeMb: '46 MB',
    ),
    IraqiProvince(
      id: 'maysan',
      nameAr: 'ميسان - العمارة',
      subtitleAr: 'العمارة، المجر الكبير، وعلي الغربي',
      center: LatLng(31.8359, 47.1448),
      sizeMb: '40 MB',
    ),
    IraqiProvince(
      id: 'muthanna',
      nameAr: 'المثنى - السماوة',
      subtitleAr: 'السماوة، الرميثة، والخضر',
      center: LatLng(31.3320, 45.2940),
      sizeMb: '42 MB',
    ),
    IraqiProvince(
      id: 'qadisiyyah',
      nameAr: 'القادسية - الديوانية',
      subtitleAr: 'الديوانية، الشامية، وعفك',
      center: LatLng(31.9929, 44.9255),
      sizeMb: '39 MB',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalPreferences();
    _seedInitialReportsAndListen();

    // التقاط موقع GPS فور فتح التطبيق مباشرة والتوجه إليه تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initImmediateGpsAndFollow();
      _handleIncomingDeepLinkOrWebOption();
    });

    // مؤقت دوري لفحص اقتراب السائق من البلاغات أو كاميرات السرعة
    _proximityAlertTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkProximityAlerts(),
    );
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _reportsStreamSub?.cancel();
    _searchDebounceTimer?.cancel();
    _proximityAlertTimer?.cancel();
    _userLocationNotifier.dispose();
    _speedKmHNotifier.dispose();
    _headingNotifier.dispose();
    _isNavigatingNotifier.dispose();
    _currentZoomNotifier.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
// ============================================================================
// بداية الجزء 2 من 5 - الصقه مباشرة تحت نهاية الجزء 1
// ============================================================================

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlacesRaw = prefs.getStringList('dlinii_saved_places') ?? [];
      setState(() {
        isDark = prefs.getBool('dlinii_dark_mode') ?? true;
        isVoiceEnabled = prefs.getBool('dlinii_voice') ?? true;
        showArabicCityLabels = prefs.getBool('dlinii_arabic_labels') ?? true;
        downloadedProvinces =
            (prefs.getStringList('dlinii_offline_provinces') ??
                    ['anbar', 'baghdad'])
                .toSet();
        if (savedPlacesRaw.isNotEmpty) {
          savedPlaces = savedPlacesRaw
              .map((item) => SavedPlace.fromJson(json.decode(item)))
              .toList();
        } else {
          savedPlaces = const [
            SavedPlace(
              id: 'uni_anbar',
              title: 'جامعة الأنبار - الرمادي',
              category: 'university',
              coords: LatLng(33.4024, 43.2610),
            ),
            SavedPlace(
              id: 'ramadi_center',
              title: 'مركز مدينة الرمادي',
              category: 'favorite',
              coords: LatLng(33.4258, 43.2995),
            ),
          ];
        }
      });
    } catch (e) {
      debugPrint('Preferences load notice: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dlinii_dark_mode', isDark);
      await prefs.setBool('dlinii_voice', isVoiceEnabled);
      await prefs.setBool('dlinii_arabic_labels', showArabicCityLabels);
      await prefs.setStringList(
        'dlinii_offline_provinces',
        downloadedProvinces.toList(),
      );
      await prefs.setStringList(
        'dlinii_saved_places',
        savedPlaces.map((p) => json.encode(p.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('Preferences save notice: $e');
    }
  }

  /// التقاط موقع GPS فور فتح التطبيق وتوجيه الكاميرا تلقائياً للمستخدم
  Future<void> _initImmediateGpsAndFollow({bool showFeedback = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && showFeedback) {
          _showSnack(
              'يرجى تفعيل خدمة الموقع (GPS) في جهازك لتحديد موقعك الدقيق');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted && showFeedback) {
          _showSnack('صلاحية الوصول للموقع مرفوضة، يرجى تفعيلها من الإعدادات');
        }
        return;
      }

      // جلب الإحداثيات الفورية بأعلى دقة ملاحية
      final Position initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final LatLng currentLatLng =
          LatLng(initialPos.latitude, initialPos.longitude);
      _userLocationNotifier.value = currentLatLng;
      hasLockedInitialGps = true;

      if (mounted) {
        setState(() {
          isFollowingUser = true;
        });
        _glideTo(currentLatLng, zoom: 15.8);
        if (showFeedback) {
          _showSnack('تم قفل موقعك الحالي عبر الـ GPS بدقة عالية');
        }
      }

      // الاشتراك في البث المباشر لحركة المركبة
      await _positionStreamSub?.cancel();
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen((Position pos) {
        final LatLng updated = LatLng(pos.latitude, pos.longitude);
        _userLocationNotifier.value = updated;

        final double rawSpeedKmH = math.max(0.0, pos.speed * 3.6);
        _speedKmHNotifier.value = rawSpeedKmH < 1.5 ? 0.0 : rawSpeedKmH;

        if (pos.heading >= 0 && rawSpeedKmH > 2.0) {
          _headingNotifier.value = pos.heading;
        }

        if (isFollowingUser && mounted) {
          _mapController.move(updated, _mapController.camera.zoom);
        }
      });
    } catch (e) {
      debugPrint('GPS Immediate Lock Notice: $e');
    }
  }

  /// تحريك الكاميرا بانسيابية عالية (Glide Animation)
  void _glideTo(LatLng target, {double zoom = 15.0}) {
    try {
      final LatLng startCenter = _mapController.camera.center;
      final double startZoom = _mapController.camera.zoom;

      final AnimationController controller = AnimationController(
        duration: const Duration(milliseconds: 650),
        vsync: this,
      );
      final Animation<double> curve =
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

      controller.addListener(() {
        final double t = curve.value;
        final double lat =
            startCenter.latitude + (target.latitude - startCenter.latitude) * t;
        final double lng = startCenter.longitude +
            (target.longitude - startCenter.longitude) * t;
        final double currentZoom = startZoom + (zoom - startZoom) * t;
        _mapController.move(LatLng(lat, lng), currentZoom);
        _currentZoomNotifier.value = currentZoom;
      });

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          controller.dispose();
        }
      });

      controller.forward();
    } catch (_) {
      _mapController.move(target, zoom);
    }
  }

  /// معالجة الروابط العميقة القادمة من ميزة «دلّي صديق» وإظهار نافذة التوجيه الذكية
  void _handleIncomingDeepLinkOrWebOption() {
    try {
      final Map<String, String> params = Uri.base.queryParameters;
      if (params.containsKey('lat') && params.containsKey('lng')) {
        final double? lat = double.tryParse(params['lat']!);
        final double? lng = double.tryParse(params['lng']!);
        final String sharedName =
            params['name'] ?? 'وجهة مشتركة عبر تطبيق دلّيني';

        if (lat != null && lng != null) {
          final LatLng sharedDest = LatLng(lat, lng);
          _planRoute(sharedDest, destName: sharedName);

          if (kIsWeb && mounted) {
            _showSmartWebOrAppDialog(sharedDest, sharedName);
          }
        }
      }
    } catch (e) {
      debugPrint('DeepLink parse notice: $e');
    }
  }

  /// نافذة خيارات التصفح الذكية (لحل مشكلة زر تنزيل التطبيق وتمكين المتابعة في الويب أو التطبيق)
  void _showSmartWebOrAppDialog(LatLng target, String placeTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.97),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.explore_rounded,
                    color: Color(0xFF10B981), size: 48),
                const SizedBox(height: 12),
                Text(
                  'تم استلام موقع: $placeTitle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'تم رسم المسار وتلوين حالة الطريق تلقائياً. يمكنك بدء الملاحة مباشرة عبر نسخة الويب الكاملة أو نسخ إحداثيات الوجهة.',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text(
                      'بدء الملاحة الفورية الآن',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _glideTo(target, zoom: 15.0);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('نسخ إحداثيات الموقع'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${target.latitude}, ${target.longitude}',
                        ),
                      );
                      Navigator.pop(ctx);
                      _showSnack('تم نسخ الإحداثيات إلى الحافظة');
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// تهيئة البلاغات الميدانية الافتراضية والاتصال المباشر بـ Firebase Firestore
  void _seedInitialReportsAndListen() {
    final DateTime now = DateTime.now();
    // بلاغات ميدانية أولية لتوضيح تلوين المسارات (الأصفر للخطر والأحمر للازدحام)
    final List<RoadReport> defaultIraqReports = [
      RoadReport(
        id: 'rep_ramadi_traffic',
        type: 'traffic',
        titleAr: 'ازدحام مروري شديد',
        descriptionAr: 'تقاطع الزيوت - الرمادي (المسار ملون بالأحمر)',
        location: const LatLng(33.4285, 43.3060),
        timestamp: now.subtract(const Duration(minutes: 12)),
        confirmations: 9,
      ),
      RoadReport(
        id: 'rep_ramadi_hazard',
        type: 'hazard',
        titleAr: 'حفريات وأعمال صيانة',
        descriptionAr: 'الشارع العام قرب جسر الورار (المسار ملون بالأصفر)',
        location: const LatLng(33.4210, 43.2850),
        timestamp: now.subtract(const Duration(minutes: 25)),
        confirmations: 6,
      ),
      RoadReport(
        id: 'rep_anbar_camera',
        type: 'camera',
        titleAr: 'كاميرا رصد سرعة (80 كم/س)',
        descriptionAr: 'الطريق السريع الرمادي - الفلوجة',
        location: const LatLng(33.3950, 43.4500),
        timestamp: now.subtract(const Duration(hours: 1)),
        confirmations: 14,
      ),
      RoadReport(
        id: 'rep_baghdad_traffic',
        type: 'traffic',
        titleAr: 'زخم مروري خانق',
        descriptionAr: 'مدخل بغداد الغربي - أبو غريب',
        location: const LatLng(33.3090, 44.1850),
        timestamp: now.subtract(const Duration(minutes: 18)),
        confirmations: 19,
      ),
      RoadReport(
        id: 'rep_checkpoint_1',
        type: 'checkpoint',
        titleAr: 'سيطرة أمنية رئيسية',
        descriptionAr: 'يرجى تخفيف السرعة وتهيئة المستمسكات',
        location: const LatLng(33.3620, 43.7420),
        timestamp: now.subtract(const Duration(minutes: 40)),
        confirmations: 11,
      ),
    ];

    setState(() {
      activeReports = List<RoadReport>.from(defaultIraqReports);
    });

    try {
      _reportsStreamSub = FirebaseFirestore.instance
          .collection('road_reports')
          .orderBy('timestamp', descending: true)
          .limit(80)
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        final List<RoadReport> remoteReports = [];
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          remoteReports.add(RoadReport.fromDoc(doc.id, data));
        }

        if (mounted) {
          setState(() {
            activeReports = [
              ...remoteReports,
              ...defaultIraqReports.where(
                (def) => !remoteReports.any((r) => r.id == def.id),
              ),
            ];
            if (fullRoutePoints.isNotEmpty) {
              routeSegments = _buildSmartColoredSegments(fullRoutePoints);
            }
          });
        }
      }, onError: (err) {
        debugPrint('Firestore live stream fallback mode: $err');
      });
    } catch (e) {
      debugPrint('Firestore not initialized or offline mode active: $e');
    }
  }

  /// إرسال بلاغ ميداني جديد وتحديث ألوان المسار فوراً
  Future<void> _submitNewReport({
    required String type,
    required String titleAr,
    required String descriptionAr,
  }) async {
    final LatLng reportLoc = _userLocationNotifier.value;
    final RoadReport newReport = RoadReport(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      titleAr: titleAr,
      descriptionAr: descriptionAr,
      location: reportLoc,
      timestamp: DateTime.now(),
      confirmations: 1,
    );

    setState(() {
      activeReports.insert(0, newReport);
      if (fullRoutePoints.isNotEmpty) {
        routeSegments = _buildSmartColoredSegments(fullRoutePoints);
      }
    });

    _showSnack('تم نشر البلاغ: $titleAr وتحديث ألوان المسار لكل السائقين');

    try {
      await FirebaseFirestore.instance
          .collection('road_reports')
          .add(newReport.toMap());
    } catch (e) {
      debugPrint('Saved report locally (offline/firestore rules): $e');
    }
  }

  /// فحص اقتراب المركبة من البلاغات أو الرادارات لتنبيه السائق
  void _checkProximityAlerts() {
    if (!isVoiceEnabled || activeReports.isEmpty) return;
    final LatLng userPos = _userLocationNotifier.value;
    const Distance distCalc = Distance();

    for (final report in activeReports) {
      final double meters =
          distCalc.as(LengthUnit.Meter, userPos, report.location);
      if (meters <= 300 && lastAlertedReportId != report.id) {
        lastAlertedReportId = report.id;
        HapticFeedback.heavyImpact();
        _showSnack('تنبيه على بعد ${meters.round()} متر: ${report.titleAr}');
        break;
      }
    }
  }
// ============================================================================
// بداية الجزء 3 من 5 - الصقه مباشرة تحت نهاية الجزء 2
// ============================================================================

  /// تخطيط المسار الملاحي وحساب الوقت والمسافة وتلوين المقاطع
  Future<void> _planRoute(LatLng destination, {String? destName}) async {
    setState(() {
      isLoadingRoute = true;
      destinationPoint = destination;
      destinationName = destName ?? 'الوجهة المحددة على الخريطة';
      searchSuggestions.clear();
    });

    final LatLng start = _userLocationNotifier.value;
    final String url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Accept-Language': 'ar'
      }).timeout(const Duration(seconds: 9));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first;
          final coords = route['geometry']['coordinates'] as List;
          final List<LatLng> pts = coords
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();

          final double distKm = ((route['distance'] as num) / 1000.0);
          final int durMin =
              math.max(1, ((route['duration'] as num) / 60.0).round());
          final DateTime arrival =
              DateTime.now().add(Duration(minutes: durMin));
          final String arrivalFormatted =
              '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';

          // استخراج خطوات التوجيه بالعربية
          final List<RouteStepItem> parsedSteps = [];
          final legs = route['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            final steps = legs.first['steps'] as List? ?? [];
            for (final step in steps) {
              final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
              final String modifier = (maneuver['modifier'] ?? '').toString();
              final String streetName = (step['name'] ?? '').toString();
              final double stepDist =
                  ((step['distance'] ?? 0) as num).toDouble();
              final List locList = maneuver['location'] as List? ??
                  [start.longitude, start.latitude];

              parsedSteps.add(
                RouteStepItem(
                  instructionAr: _translateManeuverToAr(modifier, streetName),
                  distanceText: stepDist >= 1000
                      ? '${(stepDist / 1000).toStringAsFixed(1)} كم'
                      : '${stepDist.round()} م',
                  icon: _getManeuverIcon(modifier),
                  location: LatLng(
                    (locList[1] as num).toDouble(),
                    (locList[0] as num).toDouble(),
                  ),
                ),
              );
            }
          }

          setState(() {
            fullRoutePoints = pts;
            routeSteps = parsedSteps;
            routeDistanceText = '${distKm.toStringAsFixed(1)} كم';
            routeDurationText = '$durMin دقيقة';
            routeArrivalTimeText = 'الوصول $arrivalFormatted';
            nextInstructionAr = parsedSteps.isNotEmpty
                ? parsedSteps.first.instructionAr
                : 'اسلك المسار الأخضر باتجاه $destinationName';
            routeSegments = _buildSmartColoredSegments(pts);
            isLoadingRoute = false;
          });

          _isNavigatingNotifier.value = true;
          _glideTo(start, zoom: 15.2);
          return;
        }
      }
    } catch (e) {
      debugPrint('Online routing fallback to direct offline route: $e');
    }

    // مسار احتياطي أوفلاين عند انقطاع الإنترنت
    final List<LatLng> offlineInterpolated =
        _interpolateOfflinePoints(start, destination, 40);
    final double directKm =
        const Distance().as(LengthUnit.Kilometer, start, destination);
    final int estMin = math.max(2, (directKm / 60.0 * 60.0).round());

    setState(() {
      fullRoutePoints = offlineInterpolated;
      routeSegments = _buildSmartColoredSegments(offlineInterpolated);
      routeDistanceText = '${directKm.toStringAsFixed(1)} كم';
      routeDurationText = '$estMin دقيقة (أوفلاين)';
      routeArrivalTimeText = 'وضع عدم الاتصال';
      nextInstructionAr = 'مسار أوفلاين مباشر باتجاه $destinationName';
      isLoadingRoute = false;
    });
    _isNavigatingNotifier.value = true;
    _glideTo(start, zoom: 14.5);
  }

  List<LatLng> _interpolateOfflinePoints(LatLng a, LatLng b, int steps) {
    final List<LatLng> list = [];
    for (int i = 0; i <= steps; i++) {
      final double t = i / steps;
      list.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ));
    }
    return list;
  }

  String _translateManeuverToAr(String modifier, String streetName) {
    final String road =
        streetName.trim().isEmpty ? 'الطريق الرئيسي' : streetName;
    if (modifier.contains('right')) return 'انعطف يميناً باتجاه $road';
    if (modifier.contains('left')) return 'انعطف يساراً باتجاه $road';
    if (modifier.contains('uturn')) return 'استدر للخلف في $road';
    return 'استمر مباشرة في $road';
  }

  IconData _getManeuverIcon(String modifier) {
    if (modifier.contains('right')) return Icons.turn_right_rounded;
    if (modifier.contains('left')) return Icons.turn_left_rounded;
    if (modifier.contains('uturn')) return Icons.u_turn_left_rounded;
    return Icons.straight_rounded;
  }

  /// خوارزمية تلوين المسار الذكية:
  /// 1. الأخضر الأساسي (#10B981): للطريق السالك
  /// 2. الأصفر التحذيري (#FACC15): للبلاغات الخطرة (حفريات، سيطرة، كاميرا، أعمال طرق)
  /// 3. الأحمر المروري (#EF4444): للازدحامات المرورية أو الطرق المغلقة أينما وجدت
  List<ColoredRouteSegment> _buildSmartColoredSegments(List<LatLng> points) {
    if (points.length < 2) return [];
    const Distance distanceCalc = Distance();
    final List<ColoredRouteSegment> segments = [];

    const Color greenClear = Color(0xFF10B981);
    const Color yellowHazard = Color(0xFFFACC15);
    const Color redTraffic = Color(0xFFEF4444);

    Color currentColor = greenClear;
    List<LatLng> currentChunk = [points.first];

    for (int i = 1; i < points.length; i++) {
      final LatLng pt = points[i];
      Color segColor = greenClear;

      if (showTrafficLayer) {
        for (final report in activeReports) {
          final double meters =
              distanceCalc.as(LengthUnit.Meter, pt, report.location);
          if (meters <= 420) {
            if (report.type == 'traffic' ||
                report.type == 'closed' ||
                report.type == 'accident') {
              segColor = redTraffic; // أحمر للازدحام أو الإغلاق
              break;
            } else {
              segColor =
                  yellowHazard; // أصفر للبلاغات الخطرة والحفريات والرادارات
            }
          }
        }
      }

      if (segColor == currentColor) {
        currentChunk.add(pt);
      } else {
        currentChunk.add(pt);
        segments.add(
          ColoredRouteSegment(
            points: List<LatLng>.from(currentChunk),
            color: currentColor,
            strokeWidth: currentColor == greenClear ? 6.5 : 8.5,
            statusLabel: currentColor == redTraffic
                ? 'ازدحام / إغلاق'
                : (currentColor == yellowHazard ? 'تنبيه خطر' : 'سالك'),
          ),
        );
        currentColor = segColor;
        currentChunk = [pt];
      }
    }

    if (currentChunk.length >= 2) {
      segments.add(
        ColoredRouteSegment(
          points: currentChunk,
          color: currentColor,
          strokeWidth: currentColor == greenClear ? 6.5 : 8.5,
        ),
      );
    }

    return segments;
  }

  /// إيقاف الملاحة الحالية ومسح المسار
  void _cancelNavigation() {
    setState(() {
      destinationPoint = null;
      destinationName = null;
      fullRoutePoints.clear();
      routeSegments.clear();
      routeSteps.clear();
      routeDistanceText = '';
      routeDurationText = '';
      nextInstructionAr = 'ابحث عن وجهتك أو اضغط مطولاً على الخريطة للانطلاق';
    });
    _isNavigatingNotifier.value = false;
  }

  /// محرك البحث المزدوج (يبحث فوراً في المدن العراقية المحلية + خرائط OpenStreetMap بالعربية)
  void _onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();
    final String clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        searchSuggestions.clear();
        isSearching = false;
      });
      return;
    }

    // 1. مطابقة فورية من قاعدة بيانات المدن والأماكن المحفوظة
    final List<Map<String, dynamic>> localMatches = [];
    for (final prov in iraqiProvinces) {
      if (prov.nameAr.contains(clean) || prov.subtitleAr.contains(clean)) {
        localMatches.add({
          'name': prov.nameAr,
          'subtitle': prov.subtitleAr,
          'lat': prov.center.latitude,
          'lng': prov.center.longitude,
          'isLocal': true,
        });
      }
    }

    setState(() {
      searchSuggestions = localMatches;
      isSearching = true;
    });

    // 2. بحث أونلاين مخصص للعراق باللغة العربية
    _searchDebounceTimer = Timer(const Duration(milliseconds: 450), () async {
      try {
        final Uri uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(clean)}&countrycodes=iq&format=json&limit=6&accept-language=ar',
        );
        final res = await http.get(
          uri,
          headers: {
            'Accept-Language': 'ar',
            'User-Agent': 'DliniiIraqNavigationApp/2.0',
          },
        );
        if (res.statusCode == 200 && mounted) {
          final List data = json.decode(res.body);
          final List<Map<String, dynamic>> remoteMatches = data.map((item) {
            final String displayName = (item['display_name'] ?? '').toString();
            final List<String> parts = displayName.split('،');
            return {
              'name': parts.first.trim(),
              'subtitle': displayName,
              'lat': double.parse(item['lat'].toString()),
              'lng': double.parse(item['lon'].toString()),
              'isLocal': false,
            };
          }).toList();

          setState(() {
            searchSuggestions = [...localMatches, ...remoteMatches];
            isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => isSearching = false);
        }
      }
    });
  }

  /// ميزة «دلّي صديق» لمشاركة الموقع أو الوجهة برابط ذكي يفتح مباشرة على الخريطة
  Future<void> _shareLocationWithFriend({bool shareDestination = false}) async {
    final LatLng target = (shareDestination && destinationPoint != null)
        ? destinationPoint!
        : _userLocationNotifier.value;
    final String label = (shareDestination && destinationName != null)
        ? destinationName!
        : 'موقعي الحالي على دلّيني';

    final String encodedName = Uri.encodeComponent(label);
    final String smartWebLink =
        'https://dlinii.vercel.app/?lat=${target.latitude.toStringAsFixed(6)}&lng=${target.longitude.toStringAsFixed(6)}&name=$encodedName';

    final String message = '📍 دلّيني | $label\n'
        'افتح الرابط لرؤية المسار الملون وحالة الطريق مباشرة:\n'
        '$smartWebLink';

    try {
      await Share.share(message, subject: 'مشاركة مسار عبر تطبيق دلّيني');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: message));
      _showSnack('تم نسخ رابط «دلّي صديق» الذكي إلى الحافظة');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
// ============================================================================
// بداية الجزء 4 من 5 - الصقه مباشرة تحت نهاية الجزء 3
// ============================================================================

  @override
  Widget build(BuildContext context) {
    final String tileUrl = isSatelliteMode
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : (isDark
            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
            : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
        drawer: _buildStandardAppDrawer(),
        body: Stack(
          children: [
            // 1. الخريطة التفاعلية الرئيسية
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocationNotifier.value,
                initialZoom: 13.5,
                minZoom: 5.5,
                maxZoom: 19.0,
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && isFollowingUser) {
                    setState(() => isFollowingUser = false);
                  }
                  if (pos.zoom != null) {
                    _currentZoomNotifier.value = pos.zoom!;
                  }
                },
                onLongPress: (tapPos, latlng) {
                  HapticFeedback.mediumImpact();
                  _planRoute(latlng, destName: 'نقطة محددة على الخريطة');
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.binkhalid.dlinii',
                ),

                // 2. طبقة المسار الملون (أخضر أساسي، أصفر للخطر، أحمر للازدحام)
                if (routeSegments.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // طبقة توهج خارجي للمسار لوضوح عالٍ في الوضع الليلي
                      for (final seg in routeSegments)
                        Polyline(
                          points: seg.points,
                          color: seg.color.withOpacity(0.28),
                          strokeWidth: seg.strokeWidth + 6.0,
                        ),
                      // المسار الفعلي الملون
                      for (final seg in routeSegments)
                        Polyline(
                          points: seg.points,
                          color: seg.color,
                          strokeWidth: seg.strokeWidth,
                        ),
                    ],
                  ),

                // 3. طبقة أسماء المدن والمحافظات العراقية بالعربية الواضحة (تمنع المربعات نهائياً)
                if (showArabicCityLabels)
                  MarkerLayer(
                    markers: iraqiProvinces.map((prov) {
                      return Marker(
                        point: prov.center,
                        width: 135,
                        height: 36,
                        child: GestureDetector(
                          onTap: () =>
                              _glideTo(prov.center, zoom: prov.defaultZoom),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withOpacity(0.85)
                                    : Colors.white.withOpacity(0.90),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: prov.isMajorProvince
                                      ? const Color(0xFF10B981).withOpacity(0.6)
                                      : Colors.white24,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                prov.nameAr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: prov.isMajorProvince ? 11.5 : 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // 4. طبقة البلاغات الميدانية (حفريات، ازدحام، رادار، سيطرة، إغلاق)
                MarkerLayer(
                  markers: activeReports.map((report) {
                    final Color badgeColor = _getReportColor(report.type);
                    return Marker(
                      point: report.location,
                      width: 46,
                      height: 46,
                      child: GestureDetector(
                        onTap: () => _showReportDetailsModal(report),
                        child: Container(
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.55),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getReportIcon(report.type),
                            color: Colors.black87,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // 5. علامة الوجهة النهائية
                if (destinationPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: destinationPoint!,
                        width: 60,
                        height: 60,
                        child: const Column(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFEF4444),
                              size: 44,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // 6. مؤشر موقع المستخدم الحي (GPS)
                ValueListenableBuilder<LatLng>(
                  valueListenable: _userLocationNotifier,
                  builder: (context, userPos, _) {
                    return ValueListenableBuilder<double>(
                      valueListenable: _headingNotifier,
                      builder: (context, heading, _) {
                        return MarkerLayer(
                          markers: [
                            Marker(
                              point: userPos,
                              width: 64,
                              height: 64,
                              child: Transform.rotate(
                                angle: heading * (math.pi / 180.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.22),
                                      ),
                                    ),
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF10B981),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black45,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.navigation_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            // 7. شريط البحث العلوي ولوحة التوجيه خطوة بخطوة
            SafeArea(
              child: _buildTopSearchBarAndNavHeader(),
            ),

            // 8. أزرار التحكم الجانبية العائمة (GPS، الطبقات، دلّي صديق، البلاغ السريع)
            _buildMapControlButtons(),

            // 9. قمرة القيادة السفلية (السرعة، حالة ألوان الطريق، معلومات الرحلة)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomCockpit(),
            ),

            // 10. شاشة CarPlay / HUD الكاملة للقيادة الليلية عند تفعيلها
            if (isCarPlayHudMode) _buildCarPlayHudOverlay(),
          ],
        ),
      ),
    );
  }

  /// شريط البحث الزجاجي العلوي + لافتة التوجيه الملاحي
  Widget _buildTopSearchBarAndNavHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط البحث الزجاجي الداكن
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.92)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchQueryChanged,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في دلّيني (الرمادي، بغداد، الفلوجة...)',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => searchSuggestions.clear());
                    },
                  ),
                IconButton(
                  tooltip: 'دلّي صديق',
                  icon: const Icon(
                    Icons.share_location_rounded,
                    color: Color(0xFF10B981),
                  ),
                  onPressed: () => _shareLocationWithFriend(
                    shareDestination: destinationPoint != null,
                  ),
                ),
              ],
            ),
          ),

          // قائمة اقتراحات البحث الفورية
          if (searchSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 12),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: searchSuggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Colors.white10),
                itemBuilder: (ctx, idx) {
                  final item = searchSuggestions[idx];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      item['isLocal'] == true
                          ? Icons.location_city_rounded
                          : Icons.place_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    title: Text(
                      item['name'].toString(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      item['subtitle'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      _searchFocusNode.unfocus();
                      final LatLng target = LatLng(
                        (item['lat'] as num).toDouble(),
                        (item['lng'] as num).toDouble(),
                      );
                      _searchController.text = item['name'].toString();
                      _planRoute(target, destName: item['name'].toString());
                    },
                  );
                },
              ),
            ),

          // لافتة التوجيه الأخضر عند تفعيل الملاحة
          ValueListenableBuilder<bool>(
            valueListenable: _isNavigatingNotifier,
            builder: (context, isNav, _) {
              if (!isNav) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.turn_right_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextInstructionAr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _buildLegendDot(const Color(0xFF10B981), 'سالك'),
                              const SizedBox(width: 10),
                              _buildLegendDot(
                                  const Color(0xFFFACC15), 'خطر/بلاغ'),
                              const SizedBox(width: 10),
                              _buildLegendDot(
                                  const Color(0xFFEF4444), 'ازدحام'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: _cancelNavigation,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
// ============================================================================
// بداية الجزء 5 من 5 (الأخير) - الصقه مباشرة تحت نهاية الجزء 4
// ============================================================================

  /// أزرار التحكم الجانبية على الخريطة
  Widget _buildMapControlButtons() {
    return Positioned(
      left: 14,
      bottom: 165,
      child: Column(
        children: [
          _buildGlassCircleBtn(
            icon: Icons.my_location_rounded,
            color: isFollowingUser ? const Color(0xFF10B981) : Colors.white,
            tooltip: 'تحديد موقعي الآن (GPS)',
            onTap: () => _initImmediateGpsAndFollow(showFeedback: true),
          ),
          const SizedBox(height: 10),
          _buildGlassCircleBtn(
            icon: isSatelliteMode
                ? Icons.map_rounded
                : Icons.satellite_alt_rounded,
            color: Colors.cyanAccent,
            tooltip: 'تبديل القمر الصناعي',
            onTap: () => setState(() => isSatelliteMode = !isSatelliteMode),
          ),
          const SizedBox(height: 10),
          _buildGlassCircleBtn(
            icon: Icons.download_for_offline_rounded,
            color: Colors.amberAccent,
            tooltip: 'خرائط المحافظات أوفلاين',
            onTap: _openOfflineMapsSheet,
          ),
          const SizedBox(height: 10),
          _buildGlassCircleBtn(
            icon: Icons.drive_eta_rounded,
            color: Colors.purpleAccent,
            tooltip: 'وضع قيادة CarPlay HUD',
            onTap: () => setState(() => isCarPlayHudMode = true),
          ),
          const SizedBox(height: 12),
          // زر الإبلاغ الميداني السريع
          FloatingActionButton.extended(
            heroTag: 'dlinii_report_fab',
            backgroundColor: const Color(0xFFFACC15),
            foregroundColor: Colors.black,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text(
              'بلاغ طريق',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _openReportBottomSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircleBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.90),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 8),
            ],
          ),
          child: Icon(icon, color: color, size: 23),
        ),
      ),
    );
  }

  /// اللوحة السفلية (عداد السرعة، معلومات المسار، والوصول السريع للمحافظات)
  Widget _buildBottomCockpit() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.94)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // عداد السرعة الحي (GPS Speedometer)
              ValueListenableBuilder<double>(
                valueListenable: _speedKmHNotifier,
                builder: (context, speed, _) {
                  final bool isOverLimit = speed > currentSpeedLimit;
                  return Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isOverLimit
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        width: 3.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          speed.round().toString(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'كم/س',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),

              // تفاصيل المسار أو الحالة الحالية
              Expanded(
                child: destinationPoint != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destinationName ?? 'الوجهة المحددة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                routeDurationText,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• $routeDistanceText',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                routeArrivalTimeText,
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'دلّيني - رفيقك الذكي في طرق العراق',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الأخضر: سالك | الأصفر: بلاغ خطر | الأحمر: ازدحام',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),

              // زر مشاركة «دلّي صديق» السريع
              IconButton(
                tooltip: 'دلّي صديق على هذا الموقع',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.16),
                ),
                icon: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: Color(0xFF10B981),
                ),
                onPressed: () => _shareLocationWithFriend(
                  shareDestination: destinationPoint != null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          // شريط انتقال سريع للمدن العراقية
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: iraqiProvinces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final prov = iraqiProvinces[i];
                return ActionChip(
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                  side: BorderSide.none,
                  label: Text(
                    prov.nameAr,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () =>
                      _glideTo(prov.center, zoom: prov.defaultZoom),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// نافذة إرسال بلاغ ميداني جديد
  void _openReportBottomSheet() {
    final List<Map<String, dynamic>> reportTypes = [
      {
        'type': 'traffic',
        'title': 'ازدحام مروري',
        'desc': 'يلون المسار باللون الأحمر لتنبيه السائقين',
        'icon': Icons.traffic_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'type': 'hazard',
        'title': 'حفريات / مطب خطر',
        'desc': 'يلون المسار باللون الأصفر التحذيري',
        'icon': Icons.construction_rounded,
        'color': const Color(0xFFFACC15),
      },
      {
        'type': 'closed',
        'title': 'طريق مغلق',
        'desc': 'إغلاق كلي أو جزئي للطريق (لون أحمر)',
        'icon': Icons.block_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'type': 'camera',
        'title': 'كاميرا رصد سرعة',
        'desc': 'تنبيه رادار أو كاميرا مراقبة السرعة',
        'icon': Icons.speed_rounded,
        'color': const Color(0xFFFACC15),
      },
      {
        'type': 'checkpoint',
        'title': 'سيطرة أمنية',
        'desc': 'نقطة تفتيش أو سيطرة مرورية',
        'icon': Icons.local_police_rounded,
        'color': const Color(0xFF38BDF8),
      },
      {
        'type': 'accident',
        'title': 'حادث مروري',
        'desc': 'تنبيه عاجل بوجود حادث على المسار',
        'icon': Icons.car_crash_rounded,
        'color': const Color(0xFFEF4444),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'إرسال بلاغ ميداني فوري',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'سيتم تحديث لون المسار وتنبيه جميع مستخدمي دلّيني فوراً',
                  style: TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: reportTypes.length,
                  itemBuilder: (_, idx) {
                    final item = reportTypes[idx];
                    final Color c = item['color'] as Color;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(ctx);
                        _submitNewReport(
                          type: item['type'].toString(),
                          titleAr: item['title'].toString(),
                          descriptionAr: item['desc'].toString(),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.withOpacity(0.5)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'] as IconData, color: c, size: 30),
                            const SizedBox(height: 8),
                            Text(
                              item['title'].toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// عرض تفاصيل بلاغ عند الضغط عليه في الخريطة
  void _showReportDetailsModal(RoadReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getReportColor(report.type),
                      child: Icon(_getReportIcon(report.type),
                          color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        report.titleAr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      backgroundColor: Colors.white10,
                      label: Text(
                        'تأكيدات: ${report.confirmations}',
                        style: const TextStyle(color: Colors.tealAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.descriptionAr,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.thumb_up_alt_rounded),
                        label: const Text('لا يزال موجوداً'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showSnack('شكراً لتأكيد البلاغ وتحديث الخريطة');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('انتهى البلاغ'),
                        onPressed: () {
                          setState(() {
                            activeReports.removeWhere((r) => r.id == report.id);
                            if (fullRoutePoints.isNotEmpty) {
                              routeSegments =
                                  _buildSmartColoredSegments(fullRoutePoints);
                            }
                          });
                          Navigator.pop(ctx);
                          _showSnack(
                              'تمت إزالة البلاغ وتحديث المسار إلى الأخضر');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// مدير تحميل خرائط المحافظات العراقية للعمل بدون إنترنت
  void _openOfflineMapsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.offline_pin_rounded,
                            color: Color(0xFF10B981), size: 28),
                        SizedBox(width: 10),
                        Text(
                          'خرائط محافظات العراق بدون إنترنت',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'حمّل محافظتك لتعمل الخريطة والملاحة وأسماء المدن العربية حتى عند انقطاع الشبكة',
                      style: TextStyle(color: Colors.white60, fontSize: 12.5),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        itemCount: iraqiProvinces.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10),
                        itemBuilder: (_, idx) {
                          final prov = iraqiProvinces[idx];
                          final bool isDownloaded =
                              downloadedProvinces.contains(prov.id);
                          final double? prog = downloadProgress[prov.id];

                          return ListTile(
                            leading: Icon(
                              isDownloaded
                                  ? Icons.check_circle_rounded
                                  : Icons.map_outlined,
                              color: isDownloaded
                                  ? const Color(0xFF10B981)
                                  : Colors.white54,
                            ),
                            title: Text(
                              prov.nameAr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: prog != null
                                ? LinearProgressIndicator(
                                    value: prog,
                                    color: const Color(0xFF10B981),
                                    backgroundColor: Colors.white12,
                                  )
                                : Text(
                                    '${prov.subtitleAr} • ${prov.sizeMb}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                            trailing: isDownloaded
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                          downloadedProvinces.remove(prov.id));
                                      setModalState(() {});
                                      _savePreferences();
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.download_rounded,
                                      color: Color(0xFF10B981),
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        downloadProgress[prov.id] = 0.25;
                                      });
                                      Timer.periodic(
                                        const Duration(milliseconds: 350),
                                        (timer) {
                                          final current =
                                              downloadProgress[prov.id] ?? 0.25;
                                          if (current >= 1.0) {
                                            timer.cancel();
                                            setState(() {
                                              downloadProgress.remove(prov.id);
                                              downloadedProvinces.add(prov.id);
                                            });
                                            setModalState(() {});
                                            _savePreferences();
                                            _showSnack(
                                                'اكتمل تنزيل خريطة ${prov.nameAr} للعمل أوفلاين');
                                          } else {
                                            setModalState(() {
                                              downloadProgress[prov.id] =
                                                  current + 0.25;
                                            });
                                          }
                                        },
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// شاشة CarPlay / HUD الاحترافية للقيادة الليلية
  Widget _buildCarPlayHudOverlay() {
    return Container(
      color: const Color(0xFF050811),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'دلّيني | وضع القيادة الذكي (CarPlay HUD)',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('العودة للخريطة'),
                  onPressed: () => setState(() => isCarPlayHudMode = false),
                ),
              ],
            ),
            ValueListenableBuilder<double>(
              valueListenable: _speedKmHNotifier,
              builder: (context, speed, _) {
                return Column(
                  children: [
                    Text(
                      speed.round().toString(),
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 110,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'كيلومتر / الساعة',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ],
                );
              },
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF10B981),
                    size: 42,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      nextInstructionAr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

  /// القائمة الجانبية الكاملة للتطبيق (_buildStandardAppDrawer)
  Widget _buildStandardAppDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.explore_rounded,
                          color: Color(0xFF10B981), size: 36),
                      SizedBox(width: 10),
                      Text(
                        'دلّيني | Dlinii',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'نظام الملاحة العراقي الذكي للخرائط الأوفلاين والبلاغات الميدانية الحية',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              activeColor: const Color(0xFF10B981),
              secondary:
                  const Icon(Icons.dark_mode_rounded, color: Colors.white),
              title: const Text('الوضع الليلي الزجاجي',
                  style: TextStyle(color: Colors.white)),
              value: isDark,
              onChanged: (val) {
                setState(() => isDark = val);
                _savePreferences();
              },
            ),
            SwitchListTile(
              activeColor: const Color(0xFF10B981),
              secondary:
                  const Icon(Icons.translate_rounded, color: Colors.tealAccent),
              title: const Text('أسماء المدن العراقية بالعربية',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('منع ظهور المربعات على الخريطة',
                  style: TextStyle(color: Colors.white54, fontSize: 11.5)),
              value: showArabicCityLabels,
              onChanged: (val) {
                setState(() => showArabicCityLabels = val);
                _savePreferences();
              },
            ),
            SwitchListTile(
              activeColor: const Color(0xFF10B981),
              secondary: const Icon(Icons.record_voice_over_rounded,
                  color: Colors.amberAccent),
              title: const Text('التنبيهات الصوتية والرادار',
                  style: TextStyle(color: Colors.white)),
              value: isVoiceEnabled,
              onChanged: (val) {
                setState(() => isVoiceEnabled = val);
                _savePreferences();
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.download_for_offline_rounded,
                  color: Color(0xFF10B981)),
              title: const Text('تحميل خرائط المحافظات (أوفلاين)',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'تم تحميل ${downloadedProvinces.length} محافظة',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _openOfflineMapsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_location_rounded,
                  color: Colors.cyanAccent),
              title: const Text('دلّي صديق (مشاركة ذكية)',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                  'إرسال رابط يفتح المسار مباشرة بالويب أو التطبيق',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareLocationWithFriend(
                  shareDestination: destinationPoint != null,
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.add_alert_rounded, color: Color(0xFFFACC15)),
              title: const Text('إرسال بلاغ طريق فوري',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _openReportBottomSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getReportColor(String type) {
    switch (type) {
      case 'traffic':
      case 'closed':
      case 'accident':
        return const Color(0xFFEF4444); // أحمر
      case 'checkpoint':
        return const Color(0xFF38BDF8); // أزرق
      case 'hazard':
      case 'camera':
      case 'roadworks':
      default:
        return const Color(0xFFFACC15); // أصفر
    }
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'traffic':
        return Icons.traffic_rounded;
      case 'closed':
        return Icons.block_rounded;
      case 'camera':
        return Icons.speed_rounded;
      case 'checkpoint':
        return Icons.local_police_rounded;
      case 'accident':
        return Icons.car_crash_rounded;
      case 'hazard':
      default:
        return Icons.warning_amber_rounded;
    }
  }
}
