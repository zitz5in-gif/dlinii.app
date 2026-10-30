import 'delete_account_dialog.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'offline_tile_platform.dart';

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
import 'map_link_parser.dart';
import 'place_design.dart';
import 'place_editor.dart';
import 'dlinii_motion.dart';
import 'dlinii_brand.dart';
import 'dlinii_sheet.dart';
import 'public_places.dart';
import 'account_sheet.dart';
import 'voice_selection.dart';

import 'package:firebase_auth/firebase_auth.dart';

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
const Map<String, String> kReportTypeSvgs = {
  'bump': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.18"/><path d="M8 32H13C15.5 23 20.5 23 24 28C27.5 23 32.5 23 35 32H40" stroke="#d99b26" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><line x1="8" y1="36" x2="40" y2="36" stroke="#142e2d" stroke-width="3" stroke-linecap="round"/></svg>',
  'pothole': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#087e76" fill-opacity="0.15"/><ellipse cx="24" cy="30" rx="14" ry="6" fill="#142e2d"/><path d="M13 28L18 32L24 27L30 32L35 28" stroke="#9cdbc0" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M24 12V21M24 21L20 17M24 21L28 17" stroke="#E5484D" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  'crash': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#E5484D" fill-opacity="0.16"/><path d="M24 8L28 17L38 14L32 23L40 30L30 31L29 40L22 33L13 38L16 28L8 23L18 19L24 8Z" fill="#E5484D" stroke="#ffffff" stroke-width="1.5" stroke-linejoin="round"/><circle cx="24" cy="25" r="5" fill="#efbb52"/></svg>',
  'traffic': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.18"/><rect x="17" y="8" width="14" height="32" rx="7" fill="#142e2d" stroke="#087e76" stroke-width="2"/><circle cx="24" cy="15" r="3.2" fill="#E5484D"/><circle cx="24" cy="24" r="3.2" fill="#efbb52"/><circle cx="24" cy="33" r="3.2" fill="#16a34a"/></svg>',
  'police': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#087e76" fill-opacity="0.16"/><path d="M24 9L36 14V24C36 32 24 39 24 39C24 39 12 32 12 24V14L24 9Z" fill="#087e76" stroke="#9cdbc0" stroke-width="2"/><circle cx="24" cy="23" r="4.5" fill="#efbb52"/></svg>',
  'roadworks': '<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg"><path d="M24 5L45 42H3Z" fill="#efbb52"/><path d="M13 32L23 23L32 32M23 23V15" fill="none" stroke="#142e2d" stroke-width="4"/></svg>',
  'closed': '<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg"><circle cx="24" cy="24" r="21" fill="#E5484D"/><path d="M11 24H37" stroke="white" stroke-width="7"/></svg>',
  'camera': '<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="13" width="40" height="29" rx="8" fill="#087e76"/><path d="M15 13L19 6H29L33 13" fill="#087e76"/><circle cx="24" cy="27" r="9" fill="#efbb52"/></svg>',
  'hazard': '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="40" height="40" rx="14" fill="#efbb52" fill-opacity="0.2"/><path d="M24 10L39 36H9L24 10Z" fill="#efbb52" stroke="#142e2d" stroke-width="2.5" stroke-linejoin="round"/><path d="M24 20V27" stroke="#142e2d" stroke-width="3" stroke-linecap="round"/><circle cx="24" cy="32" r="2" fill="#142e2d"/></svg>',
};

// زر زجاجي بنعومة واستجابة لمسية مطابقة لأزرار الآيفون (iOS Spring Physics)
class DliniiAppIcon extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final double? size;
  const DliniiAppIcon(this.icon, {super.key, this.color, this.size});
  @override
  Widget build(BuildContext context) {
    final paths = <IconData, String>{
      Icons.layers_rounded:
          'm12 2 10 6-10 6L2 8zm-10 10 10 6 10-6M2 17l10 6 10-6',
      Icons.home_rounded: 'm2 11 10-9 10 9M5 9v12h5v-7h4v7h5V9',
      Icons.work_rounded: 'M8 6V3h8v3M3 6h18v15H3zM3 12h18M10 11v3h4v-3',
      Icons.tune_rounded:
          'M3 6h4m4 0h10M3 12h10m4 0h4M3 18h4m4 0h10M7 3v6m6 0v6M7 15v6',
      Icons.menu_rounded: 'M4 6h16M4 12h16M4 18h16',
      Icons.close_rounded: 'm6 6 12 12M18 6 6 18',
      Icons.add_rounded: 'M12 4v16M4 12h16',
      Icons.remove_rounded: 'M4 12h16',
      Icons.arrow_forward_ios_rounded: 'm9 5 7 7-7 7',
      Icons.content_paste_go_rounded:
          'M8 4H5v18h14V4h-3M8 2h8v5H8zM8 13h8M8 17h6',
      Icons.route_rounded:
          'M5 19V7a3 3 0 0 1 6 0v10a3 3 0 0 0 6 0V5M14 8l3-3 3 3',
      Icons.navigation_rounded: 'm12 3 9 18-9-4-9 4z',
      Icons.play_circle_fill_rounded:
          'M9 7v10l8-5zM22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
      Icons.share_rounded: 'M7 11l10-6M7 13l10 6M7 12a2 2 0 1 1-4 0 2 2 0 0 1 4 0M21 4a2 2 0 1 1-4 0 2 2 0 0 1 4 0M21 20a2 2 0 1 1-4 0 2 2 0 0 1 4 0',
      Icons.share_location_rounded:
          'M12 3v4M12 17v4M3 12h4M17 12h4M19 12a7 7 0 1 1-14 0 7 7 0 0 1 14 0',
      Icons.my_location_rounded: 'M12 2v4M12 18v4M2 12h4M18 12h4M19 12a7 7 0 1 1-14 0 7 7 0 0 1 14 0M14 12a2 2 0 1 1-4 0 2 2 0 0 1 4 0',
      Icons.location_off_rounded:
          'm3 3 18 18M9 4a7 7 0 0 1 10 6c0 5-7 12-7 12S5 15 5 10',
      Icons.cloud_download_rounded: 'M7 17H5a4 4 0 0 1 0-8 7 7 0 0 1 13-2 5 5 0 0 1 1 10h-2M12 11v11m-4-4 4 4 4-4',
      Icons.download_rounded: 'M12 3v13m-5-5 5 5 5-5M4 17v4h16v-4',
      Icons.wb_sunny_rounded: 'M12 2v2M12 20v2M2 12h2M20 12h2M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2M17 12a5 5 0 1 1-10 0 5 5 0 0 1 10 0',
      Icons.dark_mode_rounded: 'M21 14a9 9 0 0 1-11-11 9 9 0 1 0 11 11',
      Icons.check_circle_rounded:
          'm7 12 3 3 7-7M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
      Icons.swap_horiz_rounded: 'M3 8h18m-4-4 4 4-4 4M21 16H3m4-4-4 4 4 4',
      Icons.send_rounded: 'm3 3 19 9-19 9 4-9zM7 12h15',
      Icons.info_outline_rounded:
          'M12 11v6M12 7v1M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0',
      Icons.map_rounded: 'm3 5 6-2 6 2 6-2v16l-6 2-6-2-6 2zM9 3v16M15 5v16',
      Icons.pin_drop_rounded: 'M12 21s7-7 7-12a7 7 0 0 0-14 0c0 5 7 12 7 12M15 9a3 3 0 1 1-6 0 3 3 0 0 1 6 0',
      Icons.push_pin_rounded: 'M8 3h8l-1 6 4 5H5l4-5zM12 14v8',
      Icons.shield_rounded: 'm12 2 9 4v6c0 6-9 10-9 10S3 18 3 12V6z',
      Icons.verified_user_rounded:
          'm12 2 9 4v6c0 6-9 10-9 10S3 18 3 12V6zM7 12l3 3 7-7',
      Icons.translate_rounded: 'M3 5h12M9 2v3M5 5c0 6 5 9 9 10M13 5c0 6-5 9-9 10M14 21l4-10 4 10M16 17h4',
      Icons.record_voice_over_rounded: 'M12 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0M2 22v-3a6 6 0 0 1 12 0v3M17 5a7 7 0 0 1 0 10M20 2a11 11 0 0 1 0 16',
      Icons.notifications_active_rounded:
          'M5 17h14l-2-4V8a5 5 0 0 0-10 0v5zM10 21h4M3 4 1 8M21 4l2 4',
      Icons.star_rounded: 'm12 2 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z',
      Icons.stars_rounded: 'm12 2 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z',
    };
    if (icon == Icons.face_3_rounded || icon == Icons.face_6_rounded) {
      return Text(
        icon == Icons.face_3_rounded ? '👩' : '👨',
        style: TextStyle(fontSize: size ?? 24),
      );
    }
    final path = paths[icon];
    if (path == null) return Icon(icon, color: color, size: size);
    final effectiveColor =
        color ?? IconTheme.of(context).color ?? const Color(0xFF7CE0BE);
    final hex = effectiveColor
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#' +
          hex +
          '" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="' +
          path +
          '"/></svg>',
      width: size ?? 24,
      height: size ?? 24,
    );
  }
}

class DliniiControlIcon extends StatelessWidget {
  final String kind;
  final double size;
  final Color color;
  const DliniiControlIcon(
    this.kind, {
    super.key,
    this.size = 24,
    this.color = const Color(0xFF7CE0BE),
  });
  @override
  Widget build(BuildContext context) {
    const shapes = <String, String>{
      'mic': '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11v1a7 7 0 0 0 14 0v-1M12 19v3M8 22h8"/>',
      'down': '<path d="m5 9 7 7 7-7"/>',
      'up': '<path d="m5 15 7-7 7 7"/>',
      'menu': '<path d="M4 6h16M4 12h16M4 18h16"/>',
      'paste': '<rect x="5" y="5" width="14" height="17" rx="3"/><rect x="8" y="2" width="8" height="6" rx="2"/><path d="M9 13h6M9 17h6"/>',
      'sound': '<path d="M4 9h4l5-5v16l-5-5H4zM16 8a6 6 0 0 1 0 8M19 5a10 10 0 0 1 0 14"/>',
      'mute': '<path d="M4 9h4l5-5v16l-5-5H4zM17 9l5 6M22 9l-5 6"/>',
    };
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#$hex" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
          (shapes[kind] ?? shapes['menu']!) +
          '</svg>',
      width: size,
      height: size,
    );
  }
}

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
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
    final bg = Color.alphaBlend(
      widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      Theme.of(context).colorScheme.surface,
    );
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
            filter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _pressed
                    ? bg.withValues(alpha: (bg.a + 0.14).clamp(0.0, 1.0))
                    : bg,
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle ? null : br,
                border: Border.all(
                  color: _pressed ? const Color(0xFFefbb52) : borderCol,
                  width: _pressed ? 1.6 : 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _pressed ? 0.02 : 0.04,
                    ),
                    blurRadius: _pressed ? 2 : 4,
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

// جميع محافظات العراق الـ 18 كاملة للتحميل والعمل بدون إنترنت
class IraqProvince {
  final String id;
  final String nameAr;
  final String nameEn;
  final LatLng center;
  final String sizeMb;

  /// نصف المنطقة المحمّلة حول مركز المحافظة بالدرجات (0.30 تقريباً 33 كم)
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
    sizeMb: '45 MB',
  ),
  IraqProvince(
    id: 'baghdad',
    nameAr: '2. محافظة بغداد',
    nameEn: '2. Baghdad Governorate',
    center: LatLng(33.3152, 44.3661),
    sizeMb: '68 MB',
  ),
  IraqProvince(
    id: 'basra',
    nameAr: '3. محافظة البصرة',
    nameEn: '3. Basra Governorate',
    center: LatLng(30.5081, 47.7835),
    sizeMb: '48 MB',
  ),
  IraqProvince(
    id: 'nineveh',
    nameAr: '4. محافظة نينوى (الموصل)',
    nameEn: '4. Nineveh Governorate',
    center: LatLng(36.3489, 43.1577),
    sizeMb: '54 MB',
  ),
  IraqProvince(
    id: 'erbil',
    nameAr: '5. محافظة أربيل',
    nameEn: '5. Erbil Governorate',
    center: LatLng(36.1901, 44.0091),
    sizeMb: '49 MB',
  ),
  IraqProvince(
    id: 'najaf',
    nameAr: '6. محافظة النجف الأشرف',
    nameEn: '6. Najaf Governorate',
    center: LatLng(32.0000, 44.3333),
    sizeMb: '38 MB',
  ),
  IraqProvince(
    id: 'karbala',
    nameAr: '7. محافظة كربلاء المقدسة',
    nameEn: '7. Karbala Governorate',
    center: LatLng(32.6160, 44.0249),
    sizeMb: '36 MB',
  ),
  IraqProvince(
    id: 'sulaymaniyah',
    nameAr: '8. محافظة السليمانية',
    nameEn: '8. Sulaymaniyah Governorate',
    center: LatLng(35.5558, 45.4351),
    sizeMb: '46 MB',
  ),
  IraqProvince(
    id: 'duhok',
    nameAr: '9. محافظة دهوك',
    nameEn: '9. Duhok Governorate',
    center: LatLng(36.8669, 42.9503),
    sizeMb: '35 MB',
  ),
  IraqProvince(
    id: 'kirkuk',
    nameAr: '10. محافظة كركوك',
    nameEn: '10. Kirkuk Governorate',
    center: LatLng(35.4681, 44.3922),
    sizeMb: '40 MB',
  ),
  IraqProvince(
    id: 'salahaddin',
    nameAr: '11. محافظة صلاح الدين (تكريت وسامراء)',
    nameEn: '11. Saladin Governorate',
    center: LatLng(34.6110, 43.6782),
    sizeMb: '41 MB',
  ),
  IraqProvince(
    id: 'diyala',
    nameAr: '12. محافظة ديالى (بعقوبة)',
    nameEn: '12. Diyala Governorate',
    center: LatLng(33.7485, 44.6436),
    sizeMb: '39 MB',
  ),
  IraqProvince(
    id: 'babil',
    nameAr: '13. محافظة بابل (الحلة)',
    nameEn: '13. Babylon Governorate',
    center: LatLng(32.4637, 44.4196),
    sizeMb: '37 MB',
  ),
  IraqProvince(
    id: 'wasit',
    nameAr: '14. محافظة واسط (الكوت)',
    nameEn: '14. Wasit Governorate',
    center: LatLng(32.5126, 45.8182),
    sizeMb: '36 MB',
  ),
  IraqProvince(
    id: 'dhiqar',
    nameAr: '15. محافظة ذي قار (الناصرية)',
    nameEn: '15. Dhi Qar Governorate',
    center: LatLng(31.0439, 46.2573),
    sizeMb: '38 MB',
  ),
  IraqProvince(
    id: 'maysan',
    nameAr: '16. محافظة ميسان (العمارة)',
    nameEn: '16. Maysan Governorate',
    center: LatLng(31.8359, 47.1448),
    sizeMb: '34 MB',
  ),
  IraqProvince(
    id: 'qadisiyyah',
    nameAr: '17. محافظة الديوانية (القادسية)',
    nameEn: '17. Al-Qadisiyyah Governorate',
    center: LatLng(31.9929, 44.9255),
    sizeMb: '33 MB',
  ),
  IraqProvince(
    id: 'muthanna',
    nameAr: '18. محافظة المثنى (السماوة)',
    nameEn: '18. Al Muthanna Governorate',
    center: LatLng(31.3320, 45.2940),
    sizeMb: '32 MB',
  ),
];

class VoiceProfile {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descAr;
  final String descEn;
  final String locale;
  final String langType;

  const VoiceProfile({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
    required this.locale,
    required this.langType,
  });
}

const List<VoiceProfile> kVoiceProfiles = [
  VoiceProfile(
    id: 'ar_voice',
    nameAr: 'المساعد الصوتي العربي',
    nameEn: 'Arabic Voice Assistant',
    descAr: 'يتضمن صوتي (فتاة ورجل) بنطق مشكّل بالحركات',
    descEn: 'Includes both Female & Male clear Arabic voices',
    locale: 'ar-SA',
    langType: 'ar',
  ),
  VoiceProfile(
    id: 'en_voice',
    nameAr: 'المساعد الصوتي الأجنبي (English)',
    nameEn: 'English Voice Assistant',
    descAr: 'يتضمن صوتي (فتاة ورجل) باللغة الإنجليزية',
    descEn: 'Includes both Female & Male clear English voices',
    locale: 'en-US',
    langType: 'en',
  ),
];

// ==================== إعدادات وأدوات الميزات الجديدة ====================

/// دومين روابط المشاركة (App Links). يجب أن يكون دومين تملكه وعليه ملف assetlinks.json
const String kShareHost = 'dlinii.vercel.app';

/// فلتر ليلي فوري: يحوّل الخريطة الفاتحة إلى ليلية (أرض داكنة، طرق أغمق، نهر أزرق فاتح)
const ColorFilter kInstantDarkFilter = ColorFilter.matrix(<double>[
  -0.14,
  -0.28,
  -0.08,
  0,
  150,
  -0.14,
  -0.28,
  -0.08,
  0,
  158,
  -0.14,
  -0.28,
  -0.08,
  0,
  164,
  0,
  0,
  0,
  1,
  0,
]);
const ColorFilter kSoftDayFilter = ColorFilter.matrix(<double>[
  .2126,
  .7152,
  .0722,
  0,
  0,
  .2126,
  .7152,
  .0722,
  0,
  2,
  .2126,
  .7152,
  .0722,
  0,
  4,
  0,
  0,
  0,
  1,
  0,
]);

class _TileRange {
  final int x0, x1, y0, y1;
  const _TileRange(this.x0, this.x1, this.y0, this.y1);
  bool covers(int x, int y) => x >= x0 && x <= x1 && y >= y0 && y <= y1;
}

/// تخزين بلاطات الخرائط محلياً على الجهاز (للعمل بدون إنترنت)
class _OfflineTiles {
  static String? dir;
  static const List<int> zooms = [10, 11, 12, 13, 14];

  static Future<void> init() async {
    dir = await OfflineTilePlatform.createDirectory();
  }

  static String file(int z, int x, int y) => '$dir/$z/$x/$y.png';

  static int _tx(double lon, int z) => ((lon + 180) / 360 * (1 << z)).floor();
  static int _ty(double lat, int z) {
    final double r = lat * math.pi / 180;
    return ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) /
            2 *
            (1 << z))
        .floor();
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
    final Uri url = Uri.parse(
      'https://$sub.basemaps.cartocdn.com/rastertiles/voyager/$z/$x/$y.png',
    );
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await c
            .get(url, headers: {'User-Agent': 'com.dlinii.app'})
            .timeout(const Duration(seconds: 15));
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          await OfflineTilePlatform.writeBytes(file(z, x, y), r.bodyBytes);
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// ينزّل بلاطات المحافظة فعلياً على الجهاز. يرجع true عند النجاح.
  static Future<bool> downloadProvince(
    IraqProvince p, {
    required void Function(double) onProgress,
  }) async {
    if (dir == null) await init();
    if (dir == null) return false;

    final List<List<int>> jobs = [];
    for (final z in zooms) {
      final r = _range(p, z);
      for (int x = r.x0; x <= r.x1; x++) {
        for (int y = r.y0; y <= r.y1; y++) {
          if (!OfflineTilePlatform.existsSync(file(z, x, y)))
            jobs.add([z, x, y]);
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
          if (done % 10 == 0 || done == total) {
            onProgress((done / total).clamp(0.02, 1.0).toDouble());
          }
        }
      }

      await Future.wait(List.generate(8, (_) => worker()));
    } finally {
      client.close();
    }
    return failed == 0;
  }

  /// يحذف بلاطات المحافظة ويُبقي المشتركة مع محافظات أخرى محمّلة
  static Future<void> deleteProvince(
    IraqProvince p,
    Set<String> otherDownloadedIds,
  ) async {
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
          if (OfflineTilePlatform.existsSync(f)) {
            try {
              OfflineTilePlatform.deleteSync(f);
            } catch (_) {}
          }
        }
      }
    }
  }
}

/// يقرأ البلاطة من الجهاز إذا كانت محمّلة، وإلا يجلبها من الإنترنت
class _OfflineTileProvider extends TileProvider {
  _OfflineTileProvider() : super(headers: {'User-Agent': 'com.dlinii.app'});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (_OfflineTiles.dir != null) {
      final f = _OfflineTiles.file(coordinates.z, coordinates.x, coordinates.y);
      if (OfflineTilePlatform.existsSync(f)) {
        final image = OfflineTilePlatform.imageProvider(f);
        if (image != null) return image;
      }
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

class _Snap {
  final LatLng point;
  final double bearing;
  const _Snap(this.point, this.bearing);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const int endVotesThreshold = 3;
  static const String playStoreUrl = 'https://dlinii.vercel.app';
  static const LatLng kDefaultCenter = LatLng(33.4258, 43.2995);

  bool isDark = true,
      isEnglish = false,
      isFirstPerson3D = false,
      isPlannerCollapsed = false;
  bool showNotifPermissionModal = false;
  bool showModalBox = false, showRateModal = false, showVoiceModal = false;
  bool showPlanSheet = false, showNavSheet = false, showRepSheet = false;

  // حالة "اكتشف ما حولك"
  bool showExploreModal = false;
  String selectedCategoryId = 'restaurants';
  bool isLoadingCategory = false;
  List<Map<String, dynamic>> nearbyCategoryPlaces = [];
  List<Marker> categoryMapMarkers = [];

  // حالة "خرائط بدون نت (الـ 18 محافظة)"
  bool showOfflineMapsModal = false;
  Set<String> downloadedProvinces = {};
  String? downloadingProvinceId;
  double downloadProgress = 0.0;

  // حالة الاتصال والميزات الجديدة
  bool _forceOffline = false; // true = لا يوجد إنترنت فعلياً
  Timer? _connProbeTimer;
  int _exploreReqId = 0; // رقم آخر طلب في "اكتشف حولك" (لإلغاء القديم)
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
  Timer? toastTimer, pulseAnimationTimer;
  double pulseValue = 0.0;

  final MapController mapController = MapController();

  static const String _ofmLightStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  vt.Style? _vtLight;
  vt.Style? _vtDark;
  bool _hasRealFix = false;

  final ValueNotifier<_DispState> _dispState = ValueNotifier<_DispState>(
    const _DispState(kDefaultCenter, 0),
  );
  AnimationController? _glideCtrl;
  LatLng _gStart = kDefaultCenter, _gEnd = kDefaultCenter;
  double _gStartB = 0, _gEndB = 0;
  int _lastFixMs = 0;

  double _lerpAngle(double a, double b, double t) {
    final double d = ((b - a + 540) % 360) - 180;
    return (a + d * t + 360) % 360;
  }

  LatLng _lookAhead(LatLng p, double bearingDeg, double meters) {
    final double br = bearingDeg * math.pi / 180;
    final double dLat = meters * math.cos(br) / 111320.0;
    final double dLng =
        meters *
        math.sin(br) /
        (111320.0 * math.max(0.2, math.cos(p.latitude * math.pi / 180)));
    return LatLng(p.latitude + dLat, p.longitude + dLng);
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

  _Snap? _snapToRoute(LatLng p) {
    if (navCoords.length < 2) return null;
    final double cosLat = math.cos(p.latitude * math.pi / 180);
    double best = 1e18;
    LatLng? bp;
    double bb = 0;
    for (int i = 0; i < navCoords.length - 1; i++) {
      final a = navCoords[i], b = navCoords[i + 1];
      final ax = (a.longitude - p.longitude) * cosLat * 111320.0;
      final ay = (a.latitude - p.latitude) * 111320.0;
      final bx = (b.longitude - p.longitude) * cosLat * 111320.0;
      final by = (b.latitude - p.latitude) * 111320.0;
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final double t = len2 == 0
          ? 0.0
          : ((-ax * dx - ay * dy) / len2).clamp(0.0, 1.0).toDouble();
      final px = ax + dx * t, py = ay + dy * t;
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

  Future<void> _loadMapStyles() async {
    try {
      final response = await http
          .get(Uri.parse(_ofmLightStyleUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final original = json.decode(response.body) as Map<String, dynamic>;
      final base = await const vt.StyleReader(uri: _ofmLightStyleUrl).read();
      vt.Style themed(bool dark) {
        final data = json.decode(json.encode(original)) as Map<String, dynamic>;
        for (final layer in data['layers'] as List) {
          final id = (layer['id'] ?? '').toString().toLowerCase();
          final type = layer['type'];
          final paint = Map<String, dynamic>.from(layer['paint'] ?? {});
          if (type == 'background')
            paint['background-color'] = dark ? '#10191D' : '#ffffff';
          if (type == 'fill') {
            if (id.contains('water')) {
              paint['fill-color'] = dark ? '#244957' : '#aed6e4';
            } else if (id.contains('park') ||
                id.contains('landcover') ||
                id.contains('landuse')) {
              paint['fill-color'] = dark ? '#203930' : '#dce9df';
            } else if (id.contains('building')) {
              paint['fill-color'] = dark ? '#26363e' : '#dce3e7';
            }
          }
          if (type == 'line' &&
              (id.contains('road') ||
                  id.contains('transportation') ||
                  id.contains('highway') ||
                  id.contains('bridge') ||
                  id.contains('tunnel'))) {
            paint['line-color'] = id.contains('casing')
                ? (dark ? '#273740' : '#c6d1d7')
                : (dark ? '#70828d' : '#ffffff');
          }
          if (type == 'symbol') {
            final layout = Map<String, dynamic>.from(layer['layout'] ?? {});
            layout['text-font'] = ['Tajawal'];
            final field = layout['text-field'];
            if (field != null && (json.encode(field).contains('name'))) {
              layout['text-field'] = [
                'coalesce',
                ['get', 'name:ar'],
                ['get', 'name_ar'],
                ['get', 'name'],
                ['get', 'name:latin'],
              ];
            }
            layer['layout'] = layout;
            paint['text-color'] = dark ? '#e4edf2' : '#344854';
            paint['text-halo-color'] = dark ? '#172329' : '#f6f9fa';
            paint['text-halo-width'] = 1.2;
          }
          layer['paint'] = paint;
        }
        return vt.Style(
          theme: vt.ThemeReader().read(
            data,
            id: dark ? 'dlinii_night_v3' : 'dlinii_day_v3',
          ),
          providers: base.providers,
          attributions: base.attributions,
          sprites: base.sprites,
          rasterSources: base.rasterSources,
          name: dark ? 'dlinii_night' : 'dlinii_day',
          center: base.center,
          zoom: base.zoom,
        );
      }

      final light = themed(false), dark = themed(true);
      if (!mounted) {
        base.dispose();
        return;
      }
      setState(() {
        _vtLight = light;
        _vtDark = dark;
      });
    } catch (error) {
      debugPrint('Map style: $error');
    }
  }

  AnimationController? _flyController;
  double currentZoom = 14.5;

  LatLng? me = kDefaultCenter;
  LatLng? origin, dest, reportPoint;
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
  int currentStepIndex = 0, lastSpokenStep = -1;
  Timer? simTimer;

  String hudArrow = '↑', hudInstruction = '—', hudStreet = '';
  String navEta = '—', navRemMins = '—', navRemKm = '—';

  // نظام الصوت المزدوج النقي (0 = صوت فتاة، 1 = صوت رجل) لكل من العربي والإنجليزي
  bool voiceEnabled = true;
  int selectedVoiceIndex = 0; // 0 = عربي، 1 = أجنبي
  int voiceSpeedLevel = 1; // 0 = هادئ، 1 = طبيعي، 2 = سريع
  final FlutterTts flutterTts = FlutterTts();
  List<Map<String, String>> _availableVoices = [];
  bool _voicesLoadedOnce = false;
  final Map<String, int> _voiceSlot = {
    'ar_voice': 0, // 0: فتاة ، 1: رجل
    'en_voice': 0, // 0: فتاة ، 1: رجل
  };
  final Map<String, int> _pinnedSlot = {};

  List<QueryDocumentSnapshot> cloudReports = [];
  String? selectedReportPopupId;
  Map<String, dynamic>? selectedReportPopupData;
  int lastReportTimeMs = 0;
  final Set<String> warnedReports = {};

  String tr(String ar, String en) => isEnglish ? en : ar;
  VoiceProfile get currentVoice =>
      kVoiceProfiles[selectedVoiceIndex.clamp(0, kVoiceProfiles.length - 1)];

  Color get panelColor => DliniiBrand.surface(isDark);
  Color get glassColor => isDark
      ? const Color(0xFF102F36).withOpacity(0.93)
      : Colors.white.withOpacity(0.92);
  Color get textColor =>
      isDark ? const Color(0xFFF1F5F9) : const Color(0xFF142e2d);
  Color get subColor =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6B7B);
  Color get landColor =>
      isDark ? const Color(0xFF0D161A) : const Color(0xFFF6F8FA);
  Color get lineColor =>
      isDark ? const Color(0xFF26474E) : const Color(0xFFE0E9EE);
  Color get accentColor =>
      isDark ? const Color(0xFF58D8CC) : const Color(0xFF087e76);

  @override
  void initState() {
    super.initState();
    _loadMapStyles();

    _loadSavedPrefs();
    _loadPlaces();
    _listenToPublicPlaces();
    _listenToCloudReports();
    _initDeepLinksListener();
    _checkClipboardForSharedLocation();
    _initOfflineTiles();
    _startConnectivityProbe();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        _initLocationTracking(userInitiated: true);
      } else {
        setState(() => showNotifPermissionModal = true);
      }
    });

    pulseAnimationTimer = Timer.periodic(const Duration(milliseconds: 60), (
      timer,
    ) {
      if (mounted && routes.isNotEmpty) {
        setState(() => pulseValue = (pulseValue + 0.06) % (2 * math.pi));
      }
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _flyController?.dispose();
    pulseAnimationTimer?.cancel();
    positionStream?.cancel();
    simTimer?.cancel();
    searchDebounce?.cancel();
    toastTimer?.cancel();
    originController.dispose();
    destController.dispose();
    _vtLight?.dispose();

    _glideCtrl?.dispose();
    _dispState.dispose();
    _connProbeTimer?.cancel();
    _publicPlacesSubscription?.cancel();
    try {
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  StreamSubscription<Uri>? _deepLinkSubscription;

  void _initDeepLinksListener() {
    try {
      final appLinks = AppLinks();
      if (kIsWeb) _handleIncomingUri(Uri.base);
      appLinks
          .getInitialLink()
          .then((uri) {
            if (mounted && uri != null) _handleIncomingUri(uri);
          })
          .catchError((Object _) {});
      _deepLinkSubscription = appLinks.uriLinkStream.listen((uri) {
        if (!mounted) return;
        _handleIncomingUri(uri);
      }, onError: (_) {});
    } catch (_) {}
  }

  bool _parseAndOpenSharedText(String text, {bool clearClipboard = false}) {
    final parsed = parseMapLocation(text);
    if (parsed == null) return false;
    final double? lat = parsed.latitude, lng = parsed.longitude;
    final sharedName = parsed.name;
    final isMyLocOnly = parsed.locationOnly;

    if (lat != null && lng != null) {
      if (clearClipboard) {
        Clipboard.setData(const ClipboardData(text: ''));
      }
      final pt = LatLng(lat, lng);
      setState(() {
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
        _toast(
          tr(
            'تم فتح موقع صديقك الحالي على الخريطة 📍',
            'Showing friend location on map 📍',
          ),
        );
      } else {
        _toast(
          tr(
            'تم التقاط وجهة «دلّي صديق»، جاري رسم المسار... 🧭',
            'Guided destination detected, plotting route... 🧭',
          ),
        );
        _planRoute();
      }
      return true;
    }
    return false;
  }

  Future<void> _checkClipboardForSharedLocation() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.contains('DLINII_') ||
          text.contains('openfreemap.org') ||
          text.contains(kShareHost) ||
          text.contains('geo:') ||
          text.contains('maps.google') ||
          text.contains('maps.app.goo.gl') ||
          text.contains('waze.com') ||
          text.contains('maps.apple.com')) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (!mounted) return;
          _parseAndOpenSharedText(text, clearClipboard: true);
        });
      }
    } catch (_) {}
  }

  String? _lastIncomingLink;
  DateTime? _lastIncomingAt;
  bool _mapReady = false;
  Uri? _pendingMapLink;
  void _handleIncomingUri(Uri uri) {
    if (!mounted) return;
    final text = uri.toString();
    if (!_mapReady) {
      _pendingMapLink = uri;
      return;
    }
    if (_lastIncomingLink == text &&
        _lastIncomingAt != null &&
        DateTime.now().difference(_lastIncomingAt!).inSeconds < 2)
      return;
    _lastIncomingLink = text;
    _lastIncomingAt = DateTime.now();
    if (!_parseAndOpenSharedText(text)) _resolveMapLink(uri);
  }

  Future<bool> _resolveMapLink(Uri uri) async {
    final client = http.Client();
    bool trusted(Uri value) =>
        value.scheme == 'https' &&
        (value.host == 'maps.app.goo.gl' ||
            value.host == 'goo.gl' ||
            value.host == 'maps.google.com' ||
            value.host == 'www.google.com' ||
            value.host == 'google.com' ||
            value.host == 'waze.com' ||
            value.host == 'www.waze.com' ||
            value.host == 'maps.apple.com');
    try {
      var current = uri;
      for (var attempt = 0; attempt < 5 && trusted(current); attempt++) {
        if (!mounted) return false;
        if (_parseAndOpenSharedText(current.toString())) return true;
        final request = http.Request('GET', current)..followRedirects = false;
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 8));
        final redirect = response.headers['location'];
        await response.stream.drain<void>().timeout(const Duration(seconds: 8));
        if (redirect == null) break;
        current = current.resolve(redirect);
      }
      if (mounted)
        _toast(
          tr(
            'لم يمكن استخراج إحداثيات الرابط. شارك رابط الموقع الكامل أو الصق الإحداثيات.',
            'Cannot read this link. Share the full location URL or paste coordinates.',
          ),
        );
    } catch (_) {
      if (mounted)
        _toast(
          tr(
            'تعذّر فتح رابط الموقع. تحقق من الإنترنت أو استخدم رابطاً كاملاً.',
            'Cannot open location link. Check your connection or use a full URL.',
          ),
        );
    } finally {
      client.close();
    }
    return false;
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
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    _flyController = ctrl;

    ctrl.addListener(() {
      final t = ctrl.value;
      final easePos = Curves.easeInOutCubic.transform(t);
      final lat =
          startCenter.latitude +
          (target.latitude - startCenter.latitude) * easePos;
      final lng =
          startCenter.longitude +
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

  Future<void> _shareMyCurrentLocation() async {
    LatLng pt = me ?? mapController.camera.center;
    try {
      final Position fresh = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 8),
      );
      pt = LatLng(fresh.latitude, fresh.longitude);
      me = pt;
      _hasRealFix = true;
    } catch (_) {}
    if (!_hasRealFix) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          pt = LatLng(last.latitude, last.longitude);
          me = pt;
          _hasRealFix = true;
        }
      } catch (_) {}
    }

    final lat = pt.latitude.toStringAsFixed(6);
    final lng = pt.longitude.toStringAsFixed(6);
    final ofmLink = _buildShareLink(pt, myLoc: true);

    final msg = tr(
      '📍 موقعي الحالي المباشر عبر تطبيق دلّيني:\n\n'
          '🔗 اضغط لفتح موقعي في تطبيق «دلّيني» (أو انسخ الرسالة وافتح دلّيني):\n'
          '$ofmLink\n\n'
          '🧭 كود الفتح المباشر داخل دلّيني:\n'
          'DLINII_MYLOC:$lat,$lng\n\n'
          '🌐 افتح دلّيني:\n$playStoreUrl',
      '📍 My live location via Dlinii App:\n\n'
          '🔗 Tap link to open in "Dlinii" (or copy message & open Dlinii):\n'
          '$ofmLink\n\n'
          '🧭 Direct Dlinii Code:\n'
          'DLINII_MYLOC:$lat,$lng\n\n'
          '🌐 Open Dlinii:\n$playStoreUrl',
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
      '🧭 دلّيتك على مكان «$cleanName» عبر تطبيق دلّيني:\n\n'
          '🔗 اضغط ليفتح تطبيق «دلّيني» ويرسم لك المسار مباشرة (أو انسخ الرسالة وافتح دلّيني):\n'
          '$ofmLink\n\n'
          '🧭 كود رسم المسار التلقائي داخل دلّيني:\n'
          'DLINII_GUIDE:$lat,$lng\n\n'
          '🌐 افتح دلّيني:\n$playStoreUrl',
      '🧭 Guided spot "$cleanName" via Dlinii:\n\n'
          '🔗 Tap link to plot route in "Dlinii" (or copy message & open Dlinii):\n'
          '$ofmLink\n\n'
          '🧭 Direct Route Code:\n'
          'DLINII_GUIDE:$lat,$lng\n\n'
          '🌐 Open Dlinii:\n$playStoreUrl',
    );
    Share.share(msg);
  }

  Future<void> _downloadProvinceOfflineMap(IraqProvince prov) async {
    if (downloadingProvinceId != null) return;
    if (kIsWeb) {
      _toast(
        tr(
          'تحميل الخرائط متاح في تطبيق الهاتف (أندرويد / آيفون)',
          'Offline download is available in the mobile app',
        ),
      );
      return;
    }
    setState(() {
      downloadingProvinceId = prov.id;
      downloadProgress = 0.02;
    });

    bool ok = false;
    try {
      ok = await _OfflineTiles.downloadProvince(
        prov,
        onProgress: (p) {
          if (mounted) setState(() => downloadProgress = p);
        },
      );
    } catch (_) {}
    if (!mounted) return;

    if (ok) {
      downloadedProvinces.add(prov.id);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'dlini_offline_provinces',
          downloadedProvinces.toList(),
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });
      _flyToMyLocation(prov.center, targetZoom: 13.5);
      _toast(
        tr(
          'تم تحميل خريطة «${prov.nameAr}» للعمل بدون إنترنت بنجاح ✅',
          '${prov.nameEn} offline map downloaded ✅',
        ),
      );
    } else {
      setState(() {
        downloadingProvinceId = null;
        downloadProgress = 0.0;
      });
      _toast(
        tr(
          'فشل التحميل، تأكد من الإنترنت وحاول مرة ثانية',
          'Download failed, check your connection and retry',
        ),
      );
    }
  }

  Future<void> _deleteProvinceOfflineMap(IraqProvince prov) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      downloadedProvinces.remove(prov.id);
    });
    await prefs.setStringList(
      'dlini_offline_provinces',
      downloadedProvinces.toList(),
    );
    try {
      await _OfflineTiles.deleteProvince(prov, downloadedProvinces);
    } catch (_) {}
    _toast(
      tr(
        'تم حذف خريطة ${prov.nameAr} المحفوظة',
        'Removed ${prov.nameEn} offline map',
      ),
    );
  }

  Future<void> _loadSavedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getInt('dlini_voice_idx_v5') ?? 0;
      final savedSpeed = prefs.getInt('dlini_voice_speed_lvl') ?? 1;
      final savedLang = prefs.getBool('dlini_is_en') ?? false;
      final savedDark = prefs.getBool('dlini_is_dark_default_v2') ?? true;
      final savedProvs = prefs.getStringList('dlini_offline_provinces') ?? [];
      downloadedProvinces = savedProvs.toSet();

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
        });
      }
    } catch (_) {}
    await _loadAvailableVoicesOnce();
    await _applyVoiceProfile();
  }

  Future<void> _loadAvailableVoicesOnce() async {
    if (_voicesLoadedOnce && _availableVoices.isNotEmpty) return;
    try {
      final dynamic raw = await flutterTts.getVoices;
      if (raw is List) {
        final List<Map<String, String>> list = [];
        for (final v in raw) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final loc = v['locale']?.toString() ?? '';
            final gender = v['gender']?.toString() ?? '';
            if (name.isNotEmpty) {
              list.add({'name': name, 'locale': loc, 'gender': gender});
            }
          }
        }
        _availableVoices = list;
        _voicesLoadedOnce = true;
      }
    } catch (_) {}
  }

  double _computeEffectiveSpeechRate() {
    if (kIsWeb) {
      if (voiceSpeedLevel == 0) return 0.92;
      if (voiceSpeedLevel == 2) return 1.20;
      return 1.05;
    } else {
      if (voiceSpeedLevel == 0) return 0.50;
      if (voiceSpeedLevel == 2) return 0.68;
      return 0.56;
    }
  }

  Future<void> _setVoiceSpeedLevel(int level) async {
    setState(() => voiceSpeedLevel = level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_voice_speed_lvl', level);
    await _applyVoiceProfile();
    _say(
      isEnglish
          ? 'Speech speed updated.'
          : 'تَمَّ ضَبْطُ سُرْعَةِ الصَّوْتِ بِنَجَاحٍ.',
    );
  }

  bool _voiceAvailable = false;
  Future<void> _applyVoiceProfile() async {
    _voiceAvailable = false;
    try {
      // إعادة فحص الأصوات لأن المتصفح يحمل الأصوات السحابية بعد ثانية من الفتح
      if (_availableVoices.length < 5) {
        _voicesLoadedOnce = false;
        await _loadAvailableVoicesOnce();
      }
      final vp = currentVoice;
      final int activeSlot = _pinnedSlot[vp.id] ?? (_voiceSlot[vp.id] ?? 0);
      // Slot zero is female; slot one is male. Never infer gender from list order.
      final bool wantFemale = (activeSlot == 0);

      await flutterTts.stop();

      final prefs = await SharedPreferences.getInstance();
      final identityKey = 'dlinii_engine_gender_v3_${vp.id}_$activeSlot';
      final savedIdentity = prefs.getString(identityKey);
      final matchedVoice = selectDliniiVoice(
        _availableVoices,
        language: vp.langType,
        female: wantFemale,
        savedIdentity: savedIdentity,
      );

      if (matchedVoice != null) {
        await prefs.setString(
          identityKey,
          '${matchedVoice['locale']}/${matchedVoice['name']}',
        );
      }

      if (matchedVoice != null && (matchedVoice['name'] ?? '').isNotEmpty) {
        final String vLoc = (matchedVoice['locale'] ?? '').isNotEmpty
            ? matchedVoice['locale']!
            : vp.locale;
        await flutterTts.setLanguage(vLoc);
        try {
          await flutterTts.setVoice({
            'name': matchedVoice['name']!,
            'locale': vLoc,
          });
          _voiceAvailable = true;
        } catch (_) {
          _voiceAvailable = false;
        }
      } else {
        await flutterTts.setLanguage(vp.locale);
      }

      final double targetPitch = 1.0;

      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(targetPitch);
      await flutterTts.setSpeechRate(_computeEffectiveSpeechRate());
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // 1. الضغط على البطاقة يختار اللغة فقط ولا يبدل الصوت
  Future<void> _onTapVoiceCardOnly(int index) async {
    setState(() => selectedVoiceIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_voice_idx_v5', index);
    await _applyVoiceProfile();

    final vp = currentVoice;
    final int slot = _pinnedSlot[vp.id] ?? (_voiceSlot[vp.id] ?? 0);
    final String voiceTypeLabel = slot == 0
        ? tr('صوت فتاة', 'Female')
        : tr('صوت رجل', 'Male');

    final String sample = vp.langType == 'en'
        ? 'Hello, welcome to Dlinii navigation system. I am ready to guide you.'
        : 'مَرْحَبَاً بِكَ فِي تَطْبِيقِ دَلِّينِي، أَنَا مُسَاعِدُكَ الصَّوْتِيُّ لِتَوْجِيهِكَ عَلَى الطَّرِيقِ بِكُلِّ وُضُوحٍ.';
    _say(sample);
    _toast(
      tr(
        'تم اختيار: ${vp.nameAr} ($voiceTypeLabel)',
        'Selected: ${vp.nameEn} ($voiceTypeLabel)',
      ),
    );
  }

  // 2. الضغط على الزر الأخضر بالأسفل يبدل فوراً بين (صوت فتاة ⇄ صوت رجل) سواء كنت بالعربي أو الإنجليزي
  Future<void> _onTapSwitchVoiceButton() async {
    final vp = currentVoice;
    final int currentSlot = _voiceSlot[vp.id] ?? 0;
    final int nextSlot = currentSlot == 0 ? 1 : 0;

    setState(() {
      _pinnedSlot.remove(vp.id);
      _voiceSlot[vp.id] = nextSlot;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dlini_slot_${vp.id}', nextSlot);
    await _applyVoiceProfile();

    final String voiceTypeLabel = nextSlot == 0
        ? tr('الصوت الأول: فتاة واضح ونقي', 'Voice 1: Clear Female')
        : tr('الصوت الثاني: رجل واضح ونقي', 'Voice 2: Clear Male');

    final String sample = vp.langType == 'en'
        ? (nextSlot == 0
              ? 'Hello, this is the female voice assistant on Dlinii.'
              : 'Hello, this is the male voice assistant on Dlinii.')
        : (nextSlot == 0
              ? 'مَرْحَبَاً بِكَ فِي تَطْبِيقِ دَلِّينِي، هَذَا الصَّوْتُ الأَوَّلُ بِصَوْتِ فَتَاةٍ وَاضِحٍ وَنَقِيٍّ.'
              : 'مَرْحَبَاً بِكَ فِي تَطْبِيقِ دَلِّينِي، هَذَا الصَّوْتُ الثَّانِي بِصَوْتِ رَجُلٍ وَاضِحٍ وَنَقِيٍّ.');

    _say(sample);
    _toast(voiceTypeLabel);
  }

  // 3. تثبيت الصوت المختار للأبد
  Future<void> _togglePinCurrentVoice() async {
    final vp = currentVoice;
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyPinned = _pinnedSlot.containsKey(vp.id);

    if (alreadyPinned) {
      setState(() {
        _pinnedSlot.remove(vp.id);
      });
      await prefs.remove('dlini_pinned_slot_${vp.id}');
      _toast(
        tr(
          'تم إلغاء تثبيت الصوت، يمكنك الآن التبديل بحرية',
          'Voice unpinned, you can switch freely',
        ),
      );
    } else {
      final int slotToPin = _voiceSlot[vp.id] ?? 0;
      setState(() {
        _pinnedSlot[vp.id] = slotToPin;
      });
      await prefs.setInt('dlini_voice_idx_v5', selectedVoiceIndex);
      await prefs.setInt('dlini_slot_${vp.id}', slotToPin);
      await prefs.setInt('dlini_pinned_slot_${vp.id}', slotToPin);
      HapticFeedback.mediumImpact();
      final String label = slotToPin == 0
          ? tr('صوت فتاة', 'Female')
          : tr('صوت رجل', 'Male');
      _toast(
        tr(
          'تم تثبيت ($label) بنجاح 📌 سيبقى ثابتاً دائماً حتى تغيره بنفسك',
          'Pinned ($label) permanently 📌',
        ),
      );
    }
  }

  Future<void> _openAndFetchCategory(ExploreCategory cat) async {
    // كل ضغطة تأخذ رقم طلب جديد، وأي ردّ قديم يتأخر يُهمَل تلقائياً
    final int reqId = ++_exploreReqId;
    final LatLng center = me ?? mapController.camera.center;
    final String cacheKey =
        '${cat.id}_${isEnglish ? 'en' : 'ar'}_${center.latitude.toStringAsFixed(2)}_${center.longitude.toStringAsFixed(2)}';
    final List<Map<String, dynamic>>? cached = _exploreCache[cacheKey];
    final bool fresh =
        cached != null &&
        DateTime.now().millisecondsSinceEpoch -
                (_exploreCacheTs[cacheKey] ?? 0) <
            5 * 60 * 1000;

    setState(() {
      selectedCategoryId = cat.id;
      showExploreModal = true;
      if (fresh) {
        nearbyCategoryPlaces = cached!;
        isLoadingCategory = false;
      } else {
        isLoadingCategory = true;
        nearbyCategoryPlaces = [];
      }
    });
    if (fresh) return;

    try {
      final lang = isEnglish ? 'en' : 'ar';
      const double delta = 0.20;
      final String viewbox =
          '${center.longitude - delta},${center.latitude + delta},${center.longitude + delta},${center.latitude - delta}';
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(cat.osmQuery)}&viewbox=$viewbox&bounded=1&accept-language=$lang&limit=20',
      );

      final res = await http
          .get(url, headers: {'User-Agent': 'com.dlinii.global.app'})
          .timeout(const Duration(seconds: 12));

      // وصل ردّ متأخر لفئة قديمة: تجاهله
      if (reqId != _exploreReqId) return;

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final List<Map<String, dynamic>> items = [];
        for (final raw in data) {
          final lat = double.tryParse(raw['lat']?.toString() ?? '');
          final lon = double.tryParse(raw['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;
          final pt = LatLng(lat, lon);
          final distKm = _distanceMeters(center, pt) / 1000.0;
          final display = raw['display_name']?.toString() ?? '';
          final parts = display.split(',');
          final title =
              (raw['name'] != null && raw['name'].toString().trim().isNotEmpty)
              ? raw['name'].toString().trim()
              : parts.first.trim();
          final sub = parts.length > 1
              ? parts.skip(1).take(2).join('، ').trim()
              : (isEnglish ? cat.nameEn : cat.nameAr);

          items.add({
            'title': title,
            'subtitle': sub,
            'lat': lat,
            'lng': lon,
            'distKm': distKm,
          });
        }
        items.sort(
          (a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double),
        );

        _exploreCache[cacheKey] = items;
        _exploreCacheTs[cacheKey] = DateTime.now().millisecondsSinceEpoch;

        if (mounted && reqId == _exploreReqId) {
          setState(() {
            nearbyCategoryPlaces = items;
            isLoadingCategory = false;
          });
        }
      } else {
        if (mounted && reqId == _exploreReqId) {
          setState(() => isLoadingCategory = false);
        }
      }
    } catch (_) {
      if (mounted && reqId == _exploreReqId) {
        setState(() => isLoadingCategory = false);
      }
    }
  }

  // ---------- أدوات الميزات الجديدة ----------

  Future<void> _initOfflineTiles() async {
    await _OfflineTiles.init();
    if (mounted) setState(() {});
  }

  /// يفحص وجود إنترنت فعلي كل 25 ثانية، وعند انقطاعه يتحول التطبيق للخرائط
  /// المحفوظة والمسارات المحلية تلقائياً.
  void _startConnectivityProbe() {
    if (kIsWeb) return;
    _probeConnectivity();
    _connProbeTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _probeConnectivity(),
    );
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
      _toast(
        online
            ? tr('عاد الاتصال بالإنترنت ✅', 'Back online ✅')
            : tr(
                'لا يوجد إنترنت: تم التحويل للخرائط المحفوظة والمسارات المحلية',
                'Offline: using saved maps & local routing',
              ),
      );
    }
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

  String _fmtSearchDist(dynamic item) {
    final dynamic d = item is Map ? item['_distKm'] : null;
    if (d is! num || d >= 1e8) return '';
    return d < 1
        ? '${(d * 1000).round()} ${tr('م', 'm')} · '
        : '${d.toStringAsFixed(1)} ${tr('كم', 'km')} · ';
  }

  /// البحث الصوتي بالمايكروفون (يفضّل اللهجة العراقية ar_IQ)
  Future<void> _toggleVoiceSearch() async {
    if (isListeningVoice) {
      try {
        await _speech.stop();
      } catch (_) {}
      if (mounted) setState(() => isListeningVoice = false);
      return;
    }
    if (!_speechReady) {
      try {
        _speechReady = await _speech.initialize(
          onStatus: (st) {
            if ((st == 'done' || st == 'notListening') &&
                mounted &&
                isListeningVoice) {
              setState(() => isListeningVoice = false);
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() => isListeningVoice = false);
              _toast(
                tr(
                  'تعذر التعرف على الصوت، حاول مرة ثانية',
                  'Could not recognize speech, try again',
                ),
              );
            }
          },
        );
      } catch (_) {
        _speechReady = false;
      }
    }
    if (!_speechReady) {
      _toast(
        tr(
          'المايكروفون غير متاح أو لم تسمح بإذن الصوت',
          'Microphone unavailable or permission denied',
        ),
      );
      return;
    }

    String? localeId;
    try {
      final locales = await _speech.locales();
      String? pick(bool Function(String) test) {
        for (final l in locales) {
          if (test(l.localeId.toLowerCase().replaceAll('-', '_'))) {
            return l.localeId;
          }
        }
        return null;
      }

      localeId =
          pick((id) => id == 'ar_iq') ??
          pick((id) => id.startsWith('ar_sa')) ??
          pick((id) => id.startsWith('ar'));
    } catch (_) {}
    localeId ??= kIsWeb ? 'ar-IQ' : 'ar_IQ';
    if (kIsWeb) localeId = localeId.replaceAll('_', '-');
    if (!mounted) return;

    setState(() {
      isListeningVoice = true;
      activeSearchField = 'q';
    });
    _toast(
      tr('تكلّم بالعربية… قل اسم المكان', 'Speak Arabic… say the place name'),
    );

    try {
      await _speech.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        onResult: (r) {
          if (!mounted) return;
          final String words = r.recognizedWords.trim();
          setState(() => destController.text = words);
          if (r.finalResult) {
            setState(() => isListeningVoice = false);
            if (words.length >= 2) _searchPlaceGlobal(words);
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() => isListeningVoice = false);
    }
  }

  void _showCategoryResultsOnMap() {
    final cat = kExploreCategories.firstWhere(
      (c) => c.id == selectedCategoryId,
      orElse: () => kExploreCategories.first,
    );
    final List<Marker> mList = [];

    for (final place in nearbyCategoryPlaces) {
      final pt = LatLng(place['lat'] as double, place['lng'] as double);
      mList.add(
        Marker(
          point: pt,
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () {
              setState(() {
                dest = pt;
                destName = place['title'].toString();
                destController.text = destName;
              });
              _planRoute();
            },
            child: Container(
              decoration: BoxDecoration(
                color: cat.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: DliniiAppIcon(cat.icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }

    setState(() {
      categoryMapMarkers = mList;
      showExploreModal = false;
    });

    if (nearbyCategoryPlaces.isNotEmpty) {
      final firstPt = LatLng(
        nearbyCategoryPlaces.first['lat'] as double,
        nearbyCategoryPlaces.first['lng'] as double,
      );
      _flyToMyLocation(firstPt, targetZoom: 14.5);
      _toast(
        tr(
          'تم عرض ${nearbyCategoryPlaces.length} موقع على الخريطة',
          'Showing ${nearbyCategoryPlaces.length} spots on map',
        ),
      );
    }
  }

  List<Polyline> _buildRealTrafficAndHazardOverlays(
    Map<String, dynamic> selectedRoute,
    List<LatLng> routePoints,
  ) {
    final List<Polyline> overlays = [];
    if (routePoints.length < 2) return overlays;

    try {
      final legs = selectedRoute['legs'] as List?;
      if (legs != null && legs.isNotEmpty) {
        final steps = legs[0]['steps'] as List?;
        if (steps != null) {
          for (final st in steps) {
            final double dist = ((st['distance'] ?? 0) as num).toDouble();
            final double dur = ((st['duration'] ?? 0) as num).toDouble();
            if (dist > 45 && dur > 0) {
              final double speedKmh = (dist / dur) * 3.6;
              final geom = st['geometry']?['coordinates'] as List?;
              if (geom != null && geom.length >= 2) {
                final stepPts = geom
                    .map(
                      (c) => LatLng(
                        (c[1] as num).toDouble(),
                        (c[0] as num).toDouble(),
                      ),
                    )
                    .toList();
                if (stepPts.length < 2) continue;
                if (speedKmh < 18.0) {
                  overlays.add(
                    Polyline(
                      points: stepPts,
                      color: const Color(0xFFE5484D),
                      strokeWidth: 9.2,
                    ),
                  );
                } else if (speedKmh < 28.0) {
                  overlays.add(
                    Polyline(
                      points: stepPts,
                      color: const Color(0xFFefbb52),
                      strokeWidth: 9.0,
                    ),
                  );
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    for (final doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      final repPt = LatLng(
        ((data['lat'] ?? 33.4258) as num).toDouble(),
        ((data['lng'] ?? 43.2995) as num).toDouble(),
      );
      final String type = data['type']?.toString() ?? 'hazard';

      final List<LatLng> affectedSegment = [];
      for (final p in routePoints) {
        if (_distanceMeters(p, repPt) <= 280) {
          affectedSegment.add(p);
        }
      }

      if (affectedSegment.length >= 2) {
        final bool isTrafficJam = type == 'traffic';
        overlays.add(
          Polyline(
            points: affectedSegment,
            color: isTrafficJam
                ? const Color(0xFFE5484D)
                : const Color(0xFFefbb52),
            strokeWidth: 9.5,
          ),
        );
      }
    }

    return overlays;
  }

  Future<void> _toggleLanguage() async {
    setState(() {
      isEnglish = !isEnglish;
      selectedVoiceIndex = isEnglish ? 1 : 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dlini_is_en', isEnglish);
    await prefs.setInt('dlini_voice_idx_v5', selectedVoiceIndex);
    await _applyVoiceProfile();
    _toast(
      isEnglish
          ? 'Language switched to English'
          : 'تم تحويل لغة التطبيق إلى العربية',
    );
  }

  Future<void> _say(String text) async {
    if (!voiceEnabled) return;
    try {
      await _applyVoiceProfile();
      if (!_voiceAvailable) {
        _toast(
          tr(
            'الصوت المحدد غير متوفر على جهازك. اختر صوتاً متوفراً أو ثبّت أصوات النظام.',
            'Selected voice is unavailable. Install a matching system voice.',
          ),
        );
        return;
      }
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
          me!,
          math.max(mapController.camera.zoom, 17.5),
          -currentBearing,
        );
      }
      _toast(tr('تم تفعيل منظور القيادة (3D)', '3D Driving View Enabled'));
    } else {
      mapController.rotate(0);
      _toast(tr('تم العودة للمنظور المسطح (2D)', '2D Top-Down View Enabled'));
    }
  }

  Widget _buildReportSvg(String? type, {double size = 28}) =>
      DliniiReportIcon(type ?? 'hazard', size: size);

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
      case 'roadworks':
        return tr('حفريات 🚜', 'Roadworks');
      case 'closed':
        return tr('طريق مغلق ⛔', 'Road closed');
      case 'camera':
        return tr('كاميرا مراقبة 📸', 'Traffic camera');
      case 'police':
        return tr('نقطة مرور', 'Police / Patrol');
      default:
        return tr('خطر آخر', 'Road Hazard');
    }
  }

  bool _reportIsVisible(Map<String, dynamic> data) {
    final lat = data['lat'], lng = data['lng'];
    if (lat is! num || lng is! num) return false;
    final point = LatLng(lat.toDouble(), lng.toDouble());
    if (_hasRealFix && me != null && _distanceMeters(me!, point) <= 300)
      return true;
    return isNavigating && _snapToRoute(point) != null;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const double R = 6371000;
    const double r = math.pi / 180;
    final double dLat = (b.latitude - a.latitude) * r;
    final double dLon = (b.longitude - a.longitude) * r;
    final double x =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(a.latitude * r) *
            math.cos(b.latitude * r) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * R * math.asin(math.sqrt(x));
  }

  double _getBearing(LatLng start, LatLng end) {
    double toRad(double d) => d * math.pi / 180;
    double toDeg(double r) => r * 180 / math.pi;
    final lat1 = toRad(start.latitude),
        lon1 = toRad(start.longitude),
        lat2 = toRad(end.latitude),
        lon2 = toRad(end.longitude);
    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);
    return (toDeg(math.atan2(y, x)) + 360) % 360;
  }

  Future<void> _initLocationTracking({bool userInitiated = false}) async {
    try {
      final res = await PermissionsHelper.ensureLocation();
      if (!mounted) return;
      if (res != LocPermResult.granted) {
        if (userInitiated) {
          _toast(
            res == LocPermResult.serviceOff
                ? tr('شغّل خدمة الموقع (GPS)', 'Turn on location (GPS)')
                : tr(
                    'الموقع مرفوض، فعّله من إعدادات التطبيق',
                    'Location denied, enable it in app settings',
                  ),
          );
          if (res == LocPermResult.serviceOff) {
            PermissionsHelper.openLocationSettings();
          } else if (res == LocPermResult.deniedForever) {
            PermissionsHelper.openAppSettings();
          }
        }
        return;
      }
      final lastKnown = kIsWeb ? null : await Geolocator.getLastKnownPosition();
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
      positionStream =
          Geolocator.getPositionStream(
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

  void _checkOffRoute(LatLng rawPosition) {
    if (!isNavigating ||
        dest == null ||
        navCoords.length < 2 ||
        simTimer != null)
      return;
    if (_snapToRoute(rawPosition) != null) {
      _offRouteFixes = 0;
      return;
    }
    _offRouteFixes++;
    if (_offRouteFixes < 3 ||
        _rerouting ||
        (_lastReroute != null &&
            DateTime.now().difference(_lastReroute!).inSeconds < 12))
      return;
    _rerouting = true;
    _lastReroute = DateTime.now();
    _toast(
      tr(
        'جاري تحديث المسار من موقعك الحالي…',
        'Updating route from your location…',
      ),
    );
    _planRoute(
      fromPoint: rawPosition,
      rerouting: true,
    ).whenComplete(() => _rerouting = false);
  }

  void _onPositionUpdate(
    LatLng rawMe,
    double speedMps,
    double heading, {
    bool isFirst = false,
  }) {
    if (!mounted) return;
    _hasRealFix = true;
    _checkOffRoute(rawMe);

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
      if (!isNavigating && _mapReady) mapController.move(nextMe, 15.5);
    } else {
      _glideTo(nextMe, newBearing, (gap * 1.08).round());
    }
    if (!isNavigating) return;
    _updateNavigationState();
    _syncCarHud();
    _checkNearbyReports(nextMe);
  }

  void _listenToCloudReports() {
    if (!PublicPlaces.ready) return;
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
                continue;
              }
              validDocs.add(doc);
            }
            setState(() => cloudReports = validDocs);
          });
    } catch (_) {}
  }

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
      const Duration(milliseconds: 450),
      () => _searchPlaceGlobal(trimmed),
    );
  }

  Future<void> _searchPlaceGlobal(String query) async {
    final int reqId = ++_searchReqId;
    final LatLng center = me ?? mapController.camera.center;
    try {
      final lang = isEnglish ? 'en' : 'ar';
      // نميل بالنتائج نحو موقعك (بدون حصر) ثم نرتبها من الأقرب للأبعد
      const double delta = 1.5;
      final String viewbox =
          '${center.longitude - delta},${center.latitude + delta},${center.longitude + delta},${center.latitude - delta}';
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&viewbox=$viewbox&bounded=0&accept-language=$lang&limit=10',
      );
      final res = await http
          .get(url, headers: {'User-Agent': 'com.dlinii.global.app'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && reqId == _searchReqId) {
        final List<dynamic> data = json.decode(res.body);
        for (final r in data) {
          if (r is! Map) continue;
          final la = double.tryParse(r['lat']?.toString() ?? '');
          final lo = double.tryParse(r['lon']?.toString() ?? '');
          r['_distKm'] = (la != null && lo != null)
              ? Geolocator.distanceBetween(
                      center.latitude,
                      center.longitude,
                      la,
                      lo,
                    ) /
                    1000.0
              : 1e9;
        }
        data.sort(
          (a, b) => ((a['_distKm'] ?? 1e9) as num).compareTo(
            (b['_distKm'] ?? 1e9) as num,
          ),
        );
        if (mounted) {
          setState(() {
            searchResults = data.take(8).toList();
            showSearchList = true;
          });
        }
      }
    } catch (_) {}
  }

  static const String _kRouteCacheKey = 'dlini_route_cache_v1';

  List<Map<String, dynamic>> _places = [];

  Future<void> _loadPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data =
          json.decode(prefs.getString('dlinii_places_v1') ?? '[]') as List;
      final valid = data
          .whereType<Map>()
          .where(
            (p) => p['lat'] is num && p['lng'] is num && p['name'] is String,
          )
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      if (mounted) setState(() => _places = valid);
    } catch (_) {}
  }

  Future<void> _persistPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dlinii_places_v1', json.encode(_places));
  }

  Future<void> _rememberPlace(
    LatLng point,
    String name, {
    bool saved = false,
    Map<String, dynamic>? details,
  }) async {
    final existing = _places.where((place) {
      if (details?['id'] != null && place['id'] == details!['id']) return true;
      return place['name'].toString().trim().toLowerCase() ==
              name.trim().toLowerCase() &&
          _distanceMeters(
                point,
                LatLng(
                  (place['lat'] as num).toDouble(),
                  (place['lng'] as num).toDouble(),
                ),
              ) <
              25;
    }).toList();
    final pinned = saved || existing.any((p) => p['saved'] == true);
    setState(() {
      _places.removeWhere((p) => existing.contains(p));
      _places.insert(0, {
        if (existing.isNotEmpty) ...existing.first,
        if (details != null) ...details,
        'id':
            details?['id'] ??
            (existing.isNotEmpty ? existing.first['id'] : null) ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        'name': name.isEmpty ? tr('مكان محفوظ', 'Saved place') : name,
        'lat': point.latitude,
        'lng': point.longitude,
        'saved': pinned,
        'visited': DateTime.now().toIso8601String(),
      });
    });
    await _persistPlaces();
  }

  List<Map<String, dynamic>> _publicPlaces = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _publicPlacesSubscription;
  void _listenToPublicPlaces() {
    if (!PublicPlaces.publishingEnabled) return;
    _publicPlacesSubscription = PublicPlaces.collection
        .orderBy('updatedAt', descending: true)
        .limit(1000)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(
              () => _publicPlaces = snapshot.docs
                  .where(
                    (d) =>
                        d.data()['lat'] is num &&
                        d.data()['lng'] is num &&
                        d.data()['name'] is String,
                  )
                  .map((d) => <String, dynamic>{...d.data(), 'publicId': d.id})
                  .toList(),
            );
          },
          onError: (Object error) {
            debugPrint('Public places unavailable: $error');
          },
        );
  }

  Future<bool> _requireAccount() async {
    if (!PublicPlaces.ready) {
      _toast(
        tr(
          'النشر العام يحتاج إكمال إعداد Firebase أولاً',
          'Public publishing needs Firebase configuration first',
        ),
      );
      return false;
    }
    if (PublicPlaces.uid != null) return true;
    final signedIn = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: panelColor,
      builder: (_) => Theme(
        data: _interfaceTheme,
        child: DliniiAccountSheet(english: isEnglish),
      ),
    );
    return signedIn == true && PublicPlaces.uid != null;
  }

  Future<void> _accountAction() async {
    if (PublicPlaces.uid == null) {
      await _requireAccount();
      if (mounted) setState(() {});
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('حسابي', 'My account')),
        content: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(c).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(c, 'delete'),
            child: Text(tr('حذف الحساب', 'Delete account')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'close'),
            child: Text(tr('إغلاق', 'Close')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'logout'),
            child: Text(tr('تسجيل الخروج', 'Sign out')),
          ),
        ],
      ),
    );
    if (action == 'delete' && mounted) {
      final deleted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Theme(
          data: _interfaceTheme,
          child: DeleteAccountDialog(english: isEnglish),
        ),
      );
      if (deleted == true && mounted) {
        setState(() {});
        _toast(
          tr(
            'حُذف حسابك؛ تتابع الآن كزائر',
            'Account deleted. Continuing as guest',
          ),
        );
      }
    }
    if (action == 'logout') {
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() {});
    }
  }

  Map<String, dynamic>? _placeDraft;
  Future<void> _namePlace(LatLng point, {Map<String, dynamic>? initial}) async {
    if (PublicPlaces.publishingEnabled &&
        (!await _requireAccount() || !mounted))
      return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DliniiPlaceEditor(
        onSave: (data) async {
          if (PublicPlaces.publishingEnabled) {
            final publicId = await PublicPlaces.save(
              data,
              publicId:
                  initial?['publicId'] as String? ??
                  _placeDraft?['publicId'] as String?,
            );
            data['publicId'] = publicId;
            data['ownerUid'] = PublicPlaces.uid;
          }
          await _rememberPlace(
            LatLng(
              (data['lat'] as num).toDouble(),
              (data['lng'] as num).toDouble(),
            ),
            data['name'] as String,
            saved: true,
            details: data,
          );
        },
        latitude: point.latitude,
        longitude: point.longitude,
        dark: isDark,
        english: isEnglish,
        draft: initial == null
            ? _placeDraft
            : {
                ...initial,
                'id':
                    initial['id'] ??
                    initial['lat'].toString() + ',' + initial['lng'].toString(),
              },
      ),
    );
    if (!mounted) return;
    if (result == null) {
      _placeDraft = null;
      return;
    }
    if (result['_action'] == 'saved') {
      _placeDraft = null;
      _toast(
        PublicPlaces.publishingEnabled
            ? tr('تم نشر المكان وحفظه في أماكنك', 'Place published and saved')
            : tr(
                'محفوظ على هذا الجهاز فقط؛ النشر العام غير مفعّل بعد',
                'Saved on this device only; public publishing is not enabled yet',
              ),
      );
      return;
    }
    if (result['_action'] == 'pick') {
      _placeDraft = Map<String, dynamic>.from(result)..remove('_action');
      setState(() => pickMode = 'save_place');
      _toast(
        tr(
          'المس نقطة المكان على الخريطة؛ ستبقى التفاصيل محفوظة',
          'Tap the location on the map; your draft is kept',
        ),
      );
      return;
    }
    final data = Map<String, dynamic>.from(result)..remove('_action');
    _placeDraft = null;
    final selectedPoint = LatLng(
      (data['lat'] as num).toDouble(),
      (data['lng'] as num).toDouble(),
    );
    await _rememberPlace(
      selectedPoint,
      data['name'] as String,
      saved: true,
      details: data,
    );
    _toast(
      tr(
        'تم حفظ المكان وتفاصيله في أماكني',
        'Place details saved to My Places',
      ),
    );
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    place['id'] ??= place['lat'].toString() + ',' + place['lng'].toString();
    final category =
        dliniiPlaceCategories[place['category']] ??
        dliniiPlaceCategories['other']!;
    final point = LatLng(
      (place['lat'] as num).toDouble(),
      (place['lng'] as num).toDouble(),
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category[2] + '  ' + (place['name'] as String),
                style: TextStyle(
                  color: textColor,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category[isEnglish ? 1 : 0],
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              for (final entry in <String, String>{
                'address': tr('العنوان', 'Address'),
                'about': tr('عن المكان', 'About'),
                'phone': tr('التواصل', 'Contact'),
                'website': tr('الرابط', 'Website'),
                'hours': tr('ساعات العمل', 'Opening hours'),
              }.entries)
                if ((place[entry.key]?.toString() ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(color: subColor, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          place[entry.key].toString(),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              SelectableText(
                point.latitude.toStringAsFixed(6) +
                    ', ' +
                    point.longitude.toStringAsFixed(6),
                textDirection: TextDirection.ltr,
                style: TextStyle(color: subColor),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() {
                          dest = point;
                          destName = place['name'] as String;
                          destController.text = destName;
                        });
                        _planRoute();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: isDark
                            ? const Color(0xFF10242B)
                            : Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(tr('انطلق إلى المكان', 'Navigate')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (place['publicId'] == null || PublicPlaces.owns(place))
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _namePlace(point, initial: place);
                      },
                      child: Text(
                        tr(
                          place['publicId'] == null ? 'نشر' : 'تعديل',
                          place['publicId'] == null ? 'Publish' : 'Edit',
                        ),
                      ),
                    ),
                  if (PublicPlaces.owns(place))
                    IconButton(
                      tooltip: tr(
                        'حذف المكان المنشور',
                        'Delete published place',
                      ),
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(
                              tr(
                                'حذف المكان للجميع؟',
                                'Delete this public place?',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(tr('إلغاء', 'Cancel')),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(tr('حذف', 'Delete')),
                              ),
                            ],
                          ),
                        );
                        if (yes != true) return;
                        try {
                          await PublicPlaces.delete(place);
                          if (!mounted) return;
                          setState(
                            () => _places.removeWhere(
                              (p) => p['publicId'] == place['publicId'],
                            ),
                          );
                          await _persistPlaces();
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        } catch (_) {
                          if (mounted)
                            _toast(
                              tr(
                                'تعذر الحذف؛ تحقق من الاتصال والصلاحيات',
                                'Could not delete. Check connection and permissions',
                              ),
                            );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaces() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: panelColor,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .65,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(
                            'أماكني والوجهات السابقة',
                            'My places & recent destinations',
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() => pickMode = 'save_place');
                          _toast(
                            tr(
                              'المس موقع المكان على الخريطة لحفظه',
                              'Tap the map to save a place',
                            ),
                          );
                        },
                        child: Text(tr('+ مكان', '+ Place')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _places.isEmpty
                      ? Center(
                          child: Text(
                            tr(
                              'ابدأ رحلة أو أضف مكاناً ليظهر هنا',
                              'Start a trip or save a place',
                            ),
                            style: TextStyle(color: subColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _places.length,
                          itemBuilder: (context, index) {
                            final place = _places[index];
                            return ListTile(
                              leading: IconButton(
                                tooltip: tr('تفاصيل المكان', 'Place details'),
                                onPressed: () => _showPlaceDetails(place),
                                icon: Text(
                                  (dliniiPlaceCategories[place['category']] ??
                                      dliniiPlaceCategories['other']!)[2],
                                  style: const TextStyle(fontSize: 25),
                                ),
                              ),
                              title: Text(
                                place['name'] as String,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                place['saved'] == true
                                    ? tr('مكان محفوظ', 'Saved place')
                                    : tr('وجهة سابقة', 'Recent destination'),
                                style: TextStyle(color: subColor),
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  setState(() => _places.remove(place));
                                  updateSheet(() {});
                                  await _persistPlaces();
                                },
                                child: Text(
                                  tr('إزالة من سجلي', 'Remove from history'),
                                  style: const TextStyle(
                                    color: Color(0xFFFF767C),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                setState(() {
                                  dest = LatLng(
                                    (place['lat'] as num).toDouble(),
                                    (place['lng'] as num).toDouble(),
                                  );
                                  destName = place['name'] as String;
                                  destController.text = destName;
                                });
                                _planRoute();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _routeRequest = 0;
  bool _rerouting = false;
  int _offRouteFixes = 0;
  DateTime? _lastReroute;

  int _pendingRouteLoads = 0;
  Future<void> _planRoute({LatLng? fromPoint, bool rerouting = false}) async {
    _pendingRouteLoads++;
    if (mounted) setState(() => _routeBusy = true);
    try {
      await _calculateRoute(fromPoint: fromPoint, rerouting: rerouting);
    } catch (_) {
      if (mounted)
        _toast(
          tr(
            'تعذر تجهيز المسار، حاول مجدداً',
            'Could not prepare route. Try again.',
          ),
        );
    } finally {
      _pendingRouteLoads--;
      if (mounted) setState(() => _routeBusy = _pendingRouteLoads > 0);
    }
  }

  Future<void> _calculateRoute({
    LatLng? fromPoint,
    bool rerouting = false,
  }) async {
    final request = ++_routeRequest;
    final LatLng o = fromPoint ?? origin ?? me ?? mapController.camera.center;
    if (dest == null) return;
    final LatLng d = dest!;
    List<dynamic>? found;

    // 1) المحاولة الأونلاين (إذا لم ينقطع الإنترنت)
    if (!_forceOffline) {
      try {
        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${o.longitude},${o.latitude};${d.longitude},${d.latitude}?overview=full&geometries=geojson&steps=true&alternatives=true',
        );
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

    // 2) بدون إنترنت: مسار محفوظ من رحلة سابقة، وإلا مسار احتياطي محلي
    if (found == null && rerouting) {
      _toast(
        tr(
          'تعذّر تحديث المسار، ستتم المحاولة مجدداً',
          'Unable to reroute; retrying shortly',
        ),
      );
      return;
    }
    if (found == null) {
      final Map<String, dynamic>? cachedRoute = await _loadRouteFromCache(o, d);
      if (cachedRoute != null) {
        found = [cachedRoute];
      } else {
        _toast(
          tr(
            'لا يوجد اتصال ولا مسار محفوظ لهذه الرحلة. اتصل بالإنترنت لتجهيز طريق صالح.',
            'No connection or saved route for this trip. Connect to prepare a road route.',
          ),
        );
        return;
      }
      _toast(
        tr(
          'لا يوجد اتصال: تم استخدام مسار محفوظ لهذه الرحلة',
          'Offline: using a saved route for this trip',
        ),
      );
    }
    if (!mounted) return;

    if (request != _routeRequest || dest != d) return;
    final List<dynamic> finalRoutes = found.where((route) {
      if (route is! Map || route['geometry'] is! Map) return false;
      final coords = route['geometry']['coordinates'];
      return coords is List &&
          coords.length >= 2 &&
          coords.every(
            (c) =>
                c is List &&
                c.length >= 2 &&
                c[0] is num &&
                c[1] is num &&
                (c[0] as num).isFinite &&
                (c[1] as num).isFinite &&
                (c[0] as num).abs() <= 180 &&
                (c[1] as num).abs() <= 90,
          ) &&
          route['legs'] is List &&
          (route['legs'] as List).isNotEmpty &&
          route['legs'][0]['steps'] is List &&
          (route['legs'][0]['steps'] as List).isNotEmpty;
    }).toList();
    if (finalRoutes.isEmpty) {
      _toast(tr('تعذّر رسم مسار صالح لهذه الوجهة', 'No valid route geometry'));
      return;
    }
    setState(() {
      routes = finalRoutes;
      selectedRouteIndex = 0;
      showExploreModal = false;
      if (!isNavigating) showPlanSheet = true;
    });
    final List<dynamic> coordsList = routes[0]['geometry']['coordinates'];
    if (isNavigating) {
      navCoords = coordsList
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
      navSteps = routes[0]['legs'][0]['steps'];
      currentStepIndex = 0;
      lastSpokenStep = -1;
      _offRouteFixes = 0;
      _updateNavigationState();
      if (rerouting)
        _say(
          tr(
            'تم تحديث المسار، تابع القيادة',
            'Route updated. Continue driving.',
          ),
        );
      return;
    }
    if (coordsList.length >= 2) {
      final points = coordsList
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
      mapController.rotate(0);
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.only(
            top: 80,
            bottom: 260,
            left: 40,
            right: 40,
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _mkStep(
    String type,
    String modifier,
    LatLng loc,
    String name,
    double dist,
    double dur,
  ) {
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

  /// يحفظ آخر الرحلات الناجحة ليعاد استخدامها عند انقطاع الإنترنت
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
      final List<dynamic> list = raw != null
          ? (json.decode(raw) as List<dynamic>)
          : <dynamic>[];
      list.removeWhere(
        (e) =>
            e is Map &&
            _distanceMeters(
                  LatLng(
                    (e['oLat'] as num).toDouble(),
                    (e['oLng'] as num).toDouble(),
                  ),
                  o,
                ) <
                150 &&
            _distanceMeters(
                  LatLng(
                    (e['dLat'] as num).toDouble(),
                    (e['dLng'] as num).toDouble(),
                  ),
                  d,
                ) <
                150,
      );
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

  /// يبحث عن مسار محفوظ لنفس الوجهة وموقعك قريب منه، ويقتطع الجزء المتبقي
  Future<Map<String, dynamic>?> _loadRouteFromCache(LatLng o, LatLng d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kRouteCacheKey);
      if (raw == null) return null;
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      for (final e in list) {
        if (e is! Map) continue;
        final LatLng cd = LatLng(
          (e['dLat'] as num).toDouble(),
          (e['dLng'] as num).toDouble(),
        );
        if (_distanceMeters(cd, d) > 40) continue;
        final Map<String, dynamic> route = Map<String, dynamic>.from(
          e['route'] as Map,
        );
        final List<dynamic> coords = route['geometry']['coordinates'] as List;
        final pts = coords
            .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
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
        if (bd > 45) continue; // موقعك بعيد عن المسار المحفوظ
        return _trimRouteFrom(route, pts, bi, o);
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _trimRouteFrom(
    Map<String, dynamic> route,
    List<LatLng> pts,
    int from,
    LatLng o,
  ) {
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
    final double ratio = fullLen > 0
        ? (remain / fullLen).clamp(0.0, 1.0).toDouble()
        : 1.0;

    final List<dynamic> oldSteps = [];
    final legs = route['legs'];
    if (legs is List && legs.isNotEmpty && legs[0]['steps'] is List) {
      oldSteps.addAll(legs[0]['steps'] as List);
    }
    final List<dynamic> steps = [_mkStep('depart', 'straight', o, '', 0, 0)];
    for (final st in oldSteps) {
      final loc = st['maneuver']?['location'];
      if (loc is! List || st['maneuver']['type'] == 'depart') continue;
      final LatLng p = LatLng(
        (loc[1] as num).toDouble(),
        (loc[0] as num).toDouble(),
      );
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
        },
      ],
      'dlinii_source': 'cache',
    };
  }

  // تعديل جملة ما قبل الوصول لتصبح: «ستصل إلى وجهتك إن شاء الله» بدلاً من «وصلت إلى وجهتك بالسلامة»
  List<String> _getManeuverText(Map<String, dynamic>? step) {
    final bool enMode = isEnglish || currentVoice.langType == 'en';
    if (step == null || step['maneuver'] == null) {
      return [
        enMode ? 'Continue straight ahead' : 'تَابِعِ السَّيْرَ لِلْأَمَامِ',
        '↑',
      ];
    }
    final m = step['maneuver'];
    final String type = m['type'] ?? '', modifier = m['modifier'] ?? '';
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
    // قبل الوصول: يقول «ستصل إلى وجهتك إن شاء الله»
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
        '⟳',
      ];
    }
    if (type == 'turn' || type == 'end of road') {
      return ['اِنْعَطِفْ ${mod[0]}$streetName', mod[1]];
    }
    return ['تَابِعِ السَّيْرَ ${mod[0]}$streetName', mod[1]];
  }

  void _startNav() {
    if (routes.isEmpty) return;
    if (dest != null) _rememberPlace(dest!, destName);
    final r = routes[selectedRouteIndex];
    final List<dynamic> rawCoords = r['geometry']['coordinates'];
    navCoords = rawCoords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    me ??=
        origin ??
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
      _lookAhead(me!, currentBearing, 28),
      17.8,
      -currentBearing,
    );
    final initialStep = navSteps.length > 1 ? navSteps[1] : navSteps[0];
    final info = _getManeuverText(initialStep);
    final startPrefix = (isEnglish || currentVoice.langType == 'en')
        ? 'Starting navigation. '
        : 'بَدَأَتِ الرِّحْلَةُ، رَافَقَتْكَ السَّلَامَةُ. ';
    _say('$startPrefix${info[0]}');
    _updateNavigationState();
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
    final double totalDist = (r['distance'] as num).toDouble(),
        totalDur = (r['duration'] as num).toDouble();
    final int mins = math.max(
      1,
      ((totalDur * (remainingMeters / (totalDist > 0 ? totalDist : 1))) / 60)
          .round(),
    );
    final DateTime etaTime = DateTime.now().add(Duration(minutes: mins));
    final String etaStr =
        '${etaTime.hour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')}';

    final nx = (currentStepIndex + 1 < navSteps.length)
        ? navSteps[currentStepIndex + 1]
        : navSteps[currentStepIndex];
    if (nx == null) return;
    final List<dynamic> locArr = nx['maneuver']['location'];
    final LatLng stepLoc = LatLng(
      (locArr[1] as num).toDouble(),
      (locArr[0] as num).toDouble(),
    );
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
      hudInstruction = tr(
        'بعد $distFormatted: ${info[0]}',
        'In $distFormatted: ${info[0]}',
      );
      hudStreet = (nx['name'] != null && nx['name'].toString().isNotEmpty)
          ? nx['name']
          : tr('الطريق الرئيسي', 'Main Road');
    });

    if (distToStep < 200 && lastSpokenStep != currentStepIndex) {
      lastSpokenStep = currentStepIndex;
      final roundedM = math.max(10, (distToStep / 50).round() * 50);
      _say(
        enMode
            ? 'In $roundedM meters, ${info[0]}'
            : 'بَعْدَ $roundedM مِتْرَاً، ${info[0]}',
      );
    }
  }

  static const MethodChannel _carHudChannel = MethodChannel(
    'com.dlinii.app/car_hud',
  );

  Future<void> _syncCarHud() async {
    if (kIsWeb) return;
    try {
      await _carHudChannel.invokeMethod<void>('updateHud', {
        'instruction': hudInstruction,
        'arrow': hudArrow,
        'street': hudStreet,
        'remainingKm': navRemKm,
        'remainingMinutes': navRemMins,
        'speedKmh': currentSpeedKmh,
        'eta': navEta,
        'isNavigating': isNavigating,
      });
    } on MissingPluginException {
      // No car integration is registered on this platform.
    } on PlatformException catch (error) {
      debugPrint('Car HUD: ${error.code}');
    }
  }

  void _checkNearbyReports(LatLng currentPos) {
    if (!isNavigating) return;
    final bool enMode = isEnglish || currentVoice.langType == 'en';
    for (var doc in cloudReports) {
      final data = doc.data() as Map<String, dynamic>;
      if (!_reportIsVisible(data)) continue;
      final LatLng repPos = LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      );
      final double dist = _distanceMeters(currentPos, repPos);
      final String repId = doc.id,
          type = data['type'] ?? '',
          label = _getReportLabel(type, data['label']?.toString());
      if (_snapToRoute(repPos) == null) continue;
      final bearingToReport = _getBearing(currentPos, repPos);
      if (dist > 25 &&
          ((bearingToReport - currentBearing + 540) % 360 - 180).abs() > 100)
        continue;
      double alertDist = 300;
      String msg = enMode
          ? 'Caution, $label ahead'
          : 'اِحْذَرْ، أَمَامَكَ $label';

      if (type == 'bump') {
        alertDist = 100;
        msg = enMode
            ? 'Speed bump 100 meters ahead'
            : 'اِنْتَبِهْ، أَمَامَكَ مَطَبٌّ بَعْدَ مِائَةِ مِتْرٍ';
      } else if (type == 'pothole') {
        alertDist = 150;
        msg = enMode ? 'Pothole 150 meters ahead' : 'اِنْتَبِهْ، حُفْرَةٌ فِي الطَّرِيقِ بَعْدَ مِائَةٍ وَخَمْسِينَ مِتْرَاً';
      } else if (type == 'crash') {
        alertDist = 200;
        msg = enMode
            ? 'Warning, accident 200 meters ahead'
            : 'تَحْذِيرٌ، حَادِثٌ أَمَامَكَ عَلَى بُعْدِ مِائَتَيْ مِتْرٍ';
      } else if (type == 'police') {
        alertDist = 250;
        msg = enMode ? 'Traffic checkpoint 250 meters ahead' : 'اِنْتَبِهْ، نُقْطَةُ مُرُورٍ أَمَامَكَ بَعْدَ مِائَتَيْنِ وَخَمْسِينَ مِتْرَاً';
      }

      if (dist <= alertDist && !warnedReports.contains(repId)) {
        warnedReports.add(repId);
        _say(msg);
        _toast(msg);
      }
    }
  }

  // عند الوصول النهائي للوجهة: يقول «الحمد لله على سلامتك، لقد وصلت إلى وجهتك بالسلامة»
  void _endNav({bool arrived = false}) {
    simTimer?.cancel();
    simTimer = null;
    if (!kIsWeb) {
      _carHudChannel.invokeMethod<void>('clearHud').catchError((Object _) {});
    }
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
      final msg = tr(
        'الحمد لله على سلامتك، لقد وصلت إلى وجهتك بالسلامة',
        'Thank God for your safety, you have arrived at your destination safely',
      );
      _toast(msg);
      _say(
        isEnglish
            ? 'Thank God for your safety, you have arrived at your destination safely.'
            : 'الْحَمْدُ لِلَّهِ عَلَى سَلَامَتِكَ، لَقَدْ وَصَلْتَ إِلَى وِجْهَتِكَ بِالسَّلَامَةِ.',
      );
      setState(() {
        selectedStars = 5;
        showRateModal = true;
      });
    }
  }

  void _startSimulation() {
    if (routes.isEmpty) return;
    final List<dynamic> rawCoords =
        routes[selectedRouteIndex]['geometry']['coordinates'];
    if (rawCoords.isEmpty) return;
    me = LatLng(
      (rawCoords[0][1] as num).toDouble(),
      (rawCoords[0][0] as num).toDouble(),
    );
    _startNav();
    if (navCoords.length < 2) return;

    final List<double> cum = [0.0];
    for (int i = 1; i < navCoords.length; i++) {
      cum.add(cum.last + _distanceMeters(navCoords[i - 1], navCoords[i]));
    }
    final double total = cum.last;
    const double speedMps = 13.9;
    double travelled = 0;
    int seg = 0;

    LatLng pointAt(double d) {
      while (seg < navCoords.length - 2 && cum[seg + 1] < d) {
        seg++;
      }
      final double segLen = cum[seg + 1] - cum[seg];
      final double t = segLen <= 0
          ? 0.0
          : ((d - cum[seg]) / segLen).clamp(0.0, 1.0).toDouble();
      final a = navCoords[seg], b = navCoords[seg + 1];
      return LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
    }

    simTimer?.cancel();
    _lastFixMs = DateTime.now().millisecondsSinceEpoch;
    simTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      travelled += speedMps;
      if (travelled >= total) {
        timer.cancel();
        _onPositionUpdate(navCoords.last, 0, currentBearing);
        _endNav(arrived: true);
        return;
      }
      final LatLng c = pointAt(travelled);
      final LatLng ahead = pointAt(math.min(total, travelled + 12));
      _onPositionUpdate(c, speedMps, _getBearing(c, ahead));
    });
  }

  void _onReportButtonTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastReportTimeMs < 5 * 60 * 1000) {
      final remMin = ((5 * 60 * 1000 - (now - lastReportTimeMs)) / 60000)
          .ceil();
      _toast(
        tr(
          'يرجى الانتظار $remMin دقيقة قبل إرسال بلاغ آخر',
          'Please wait $remMin min before reporting again',
        ),
      );
      return;
    }
    final targetPt = reportPoint ?? me ?? mapController.camera.center;
    me ??= targetPt;
    if (_distanceMeters(me!, targetPt) > 300) {
      _toast(
        tr(
          'يرجى الاقتراب من موقع الحدث (ضمن 300 متر)',
          'Please get closer to incident',
        ),
      );
      return;
    }
    setState(() {
      reportPoint = me;
      showRepSheet = true;
    });
  }

  Future<void> _submitCloudReport(String type, String label) async {
    if (!await _requireAccount() || !mounted) return;
    final pt = reportPoint ?? me ?? mapController.camera.center;
    setState(() => showRepSheet = false);
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'ownerUid': PublicPlaces.uid,
        'type': type,
        'label': label,
        'lat': pt.latitude,
        'lng': pt.longitude,
        'confirmations': 1,
        'endVotes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      lastReportTimeMs = DateTime.now().millisecondsSinceEpoch;
      _toast(
        tr(
          'تم نشر بلاغ «$label» على الخريطة لجميع السائقين',
          'Report "$label" published',
        ),
      );
    } catch (_) {
      _toast(tr('تعذر نشر البلاغ سحابياً', 'Could not publish report'));
    }
  }

  Future<void> _voteReportYes(String id) => _voteReport(id, 'confirmations');

  Future<void> _voteReportNo(String id, int currentEndVotes) =>
      _voteReport(id, 'endVotes');

  Future<void> _voteReport(String id, String field) async {
    if (!await _requireAccount() || !mounted) return;
    setState(() => selectedReportPopupId = null);
    final uid = PublicPlaces.uid!;
    final db = FirebaseFirestore.instance;
    final report = db.collection('reports').doc(id);
    final vote = report.collection('votes').doc(uid);
    try {
      final recorded = await db.runTransaction<bool>((tx) async {
        final previous = await tx.get(vote);
        final current = await tx.get(report);
        if (previous.exists || !current.exists) return false;
        final data = current.data()!;
        if ((data['endVotes'] as num? ?? 0) >= endVotesThreshold) return false;
        tx.set(vote, {
          'kind': field,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(report, {field: FieldValue.increment(1)});
        return true;
      });
      _toast(
        recorded
            ? tr('تم تسجيل صوتك', 'Vote recorded')
            : tr(
                'صوّتّ مسبقاً أو انتهى البلاغ',
                'Already voted or report ended',
              ),
      );
    } catch (_) {
      _toast(
        tr(
          'تعذر تسجيل التصويت، حاول مجدداً',
          'Could not record vote. Try again',
        ),
      );
    }
  }

  void _toggleVoiceState() {
    setState(() => voiceEnabled = !voiceEnabled);
    if (!voiceEnabled) flutterTts.stop();
    _toast(
      voiceEnabled
          ? tr('تم تفعيل المساعد الصوتي', 'Voice assistant on')
          : tr('تم كتم المساعد الصوتي', 'Voice muted'),
    );
  }

  // سياسة خصوصية وأمان موسعة وشاملة جداً
  void _openPrivacyModal() {
    Navigator.of(context).maybePop();
    setState(() {
      modalHeaderIcon = Icons.shield_rounded;
      modalTitle = tr(
        'سياسة الخصوصية والأمان الشاملة',
        'Comprehensive Privacy & Security Policy',
      );
      modalSections = [
        {
          'title': tr(
            '1. بيانات الموقع الجغرافي الحي (GPS)',
            '1. Real-Time Location Data (GPS)',
          ),
          'body': tr(
            'يعتمد تطبيق "دلّيني" على إحداثيات موقعك الجغرافي (GPS) بشكل لحظي ومحلي داخل جهازك لغرض وحيد هو إظهار موقعك على الخريطة، حساب المسارات بدقة، وتقديم التوجيه الصوتي خطوة بخطوة. لا يتم تخزين سجل تحركاتك أو تتبع مساراتك الشخصية على خوادمنا إطلاقاً، ولا نشارك موقعك مع أي طرف ثالث أو جهات إعلانية.',
            'Dlinii uses your real-time GPS coordinates strictly to display your position, calculate accurate routes, and provide turn-by-turn voice navigation. Your movement history is never stored on our servers or shared with third-party advertisers.',
          ),
        },
        {
          'title': tr(
            '2. نظام البلاغات المرورية التشاركي والمجهول',
            '2. Anonymous Community Road Reports',
          ),
          'body': tr(
            'عندما تقوم بإرسال تنبيه طريق (مثل: مطب، حفرة، حادث، ازدحام مروري، أو نقطة مرور)، يتم رفع نوع البلاغ وإحداثيات الموقع الجغرافي للحدث فقط إلى قاعدة البيانات السحابية لتنبيه السائقين الآخرين، وذلك بشكل مجهول الهوية تماماً (Anonymous) دون إرفاق اسمك أو رقم هاتفك أو أي معرف شخصي.',
            'When you submit a road alert (speed bump, pothole, accident, traffic jam, or checkpoint), only the incident type and coordinates are uploaded anonymously to warn other drivers, without any personal identifiers.',
          ),
        },
        {
          'title': tr(
            '3. التخزين المحلي والخرائط بدون إنترنت',
            '3. Local Storage & Offline Maps',
          ),
          'body': tr(
            'تُحفظ تفضيلاتك الشخصية (مثل: الصوت المفضل المثبّت للمساعد الصوتي، الوضع الليلي أو النهاري، لغة التطبيق، وخرائط المحافظات الـ 18 المحمّلة للعمل بدون إنترنت) محلياً داخل ذاكرة هاتفك الآمنة فقط، ولا يمكن لأي جهة خارجية الاطلاع عليها.',
            'Your preferences (pinned voice assistant, dark/light theme, language, and downloaded offline maps for Iraq\'s 18 governorates) are stored locally on your device.',
          ),
        },
        {
          'title': tr(
            '4. ميزة مشاركة الموقع و "دلّي صديق"',
            '4. Location Sharing & "Guide a Friend"',
          ),
          'body': tr(
            'لا يقوم التطبيق بمشاركة موقعك الجغرافي تلقائياً مع أي شخص. تتم عملية مشاركة موقعك الحالي أو إرسال موقع وجهة عبر ميزة "دلّي صديق" حصرياً بإرادتك الكاملة وعند ضغطك المباشر على زر المشاركة لإرسال الرابط عبر تطبيقات المراسلة التي تختارها أنت.',
            'Dlinii never shares your location automatically. Sharing your current spot or guiding a friend happens strictly when you manually tap the share button.',
          ),
        },
        {
          'title': tr(
            '5. التشفير وأمان الاتصال السحابي',
            '5. Encryption & Cloud Security',
          ),
          'body': tr(
            'جميع الاتصالات بين تطبيق "دلّيني" ومحركات البحث الجغرافي والتوجيه وخوادم البلاغات السحابية تتم عبر بروتوكولات اتصال مشفرة بالكامل (HTTPS / TLS) لضمان حماية بياناتك أثناء النقل من أي اعتراض غير مصرح به.',
            'All communications between Dlinii, routing engines, and cloud report servers are protected using industry-standard HTTPS/TLS encryption.',
          ),
        },
        {
          'title': tr(
            '6. تحكم المستخدم الكامل في الأذونات',
            '6. Full User Control Over Permissions',
          ),
          'body': tr(
            'يمنحك تطبيق "دلّيني" السيطرة الكاملة؛ حيث يمكنك في أي وقت إيقاف صلاحية الوصول إلى الموقع الجغرافي أو الإشعارات من إعدادات هاتفك، أو كتم المساعد الصوتي وحذف الخرائط المحملة من داخل التطبيق بضغطة زر واحدة.',
            'You retain full control at all times. You can revoke GPS or notification permissions from your device settings, mute voice guidance, or delete offline maps with a single tap.',
          ),
        },
      ];
      showModalBox = true;
    });
  }

  // نافذة "عن تطبيق دلّيني" موسعة تشرح كافة الميزات بالتفصيل
  void _openAboutModal() {
    Navigator.of(context).maybePop();
    setState(() {
      modalHeaderIcon = Icons.auto_awesome_rounded;
      modalTitle = tr(
        'عن تطبيق دلّيني ومميزاته الكاملة',
        'About Dlinii & Full Features',
      );
      modalSections = [
        {
          'title': tr(
            'دلّيني – رفيقك الذكي على كل طريق',
            'Dlinii – Your Smart Companion on Every Road',
          ),
          'body': tr(
            'تطبيق "دلّيني" هو نظام ملاحة وخرائط وتنبيهات طرق ذكي صُمم بمعايير عالمية وسلاسة فائقة ليقدم للسائق تجربة قيادة آمنة، عصرية، ومريحة داخل العراق وجميع أنحاء العالم، مع دعم كامل للعمل في كافة الظروف.',
            'Dlinii is an advanced smart navigation, mapping, and road alert system engineered with ultra-smooth performance to deliver a safe and modern driving experience across Iraq and worldwide.',
          ),
        },
        {
          'title': tr(
            '1. خرائط احترافية بالوضع الليلي والنهاري ومنظور 3D',
            '1. Pro Dark/Light Maps & 3D Driving View',
          ),
          'body': tr(
            '• تصميم خريطة ليلي (Dark Mode) فخم ومريح للعين أثناء القيادة الليلية مع إبراز الأنهار باللون الأزرق الفاتح والطرق بتدرجات رصاصية واضحة، مع إمكانية التحويل للخريطة البيضاء النهارية بضغطة زر.\n• دعم منظور القيادة ثلاثي الأبعاد (3D) الذي يميل مع اتجاه حركة السيارة تماماً مثل أرقى أنظمة الملاحة العالمية، مع إمكانية التبديل للمنظور المسطح (2D).',
            '• Custom eye-friendly Dark Mode map with light-blue rivers and distinct dark-grey roads, plus one-tap switching to Light Mode.\n• Smooth 3D first-person driving perspective that rotates with your vehicle, alongside 2D top-down view.',
          ),
        },
        {
          'title': tr(
            '2. المساعد الصوتي الذكي (فتاة / رجل) مع ميزة تثبيت الصوت',
            '2. Smart Voice Assistant (Female/Male) & Voice Pinning',
          ),
          'body': tr(
            '• توجيه صوتي نقي وواضح باللغتين العربية والإنجليزية، مع نطق مشكّل بالحركات الدقيقة لضمان فصاحة ووضوح التوجيهات.\n• إمكانية التبديل الفوري بين (صوت فتاة) و (صوت رجل)، والتحكم بسرعة التحدث (هادئ، طبيعي، سريع).\n• ميزة "تثبيت الصوت 📌" التي تحفظ صوتك المفضل في ذاكرة الهاتف ليظل ثابتاً معك دائماً حتى بعد إغلاق التطبيق.',
            '• Studio-clear voice guidance in both Arabic and English.\n• Instant switching between Female and Male voices with adjustable speech speed.\n• "Pin Voice 📌" feature that permanently locks your favorite voice across app restarts.',
          ),
        },
        {
          'title': tr(
            '3. كشف الازدحامات المرورية وتنبيهات المخاطر الحية',
            '3. Real-Time Traffic & Road Hazard Alerts',
          ),
          'body': tr(
            '• يلوّن التطبيق مقاطع المسار تلقائياً بناءً على البيانات الحقيقية: الأخضر الزمردي للطرق السالكة، الأصفر لمناطق الحوادث والحفريات والمطبات، والأحمر لمناطق الازدحام المروري.\n• نظام بلاغات تشاركي يتيح للسائقين الإبلاغ الفوري عن (مطب، حفرة، حادث، ازدحام، نقطة مرور، أو خطر) مع تنبيه صوتي تلقائي قبل الوصول للخطر، ونظام تصويت ذكي (موجود / منتهي) يحذف البلاغ تلقائياً عند انتهائه.',
            '• Color-coded route segments based on real data: Emerald Green for clear roads, Yellow for hazards/accidents, and Red for traffic jams.\n• Community reporting system for speed bumps, potholes, crashes, and checkpoints with automatic voice warnings and smart crowd-voting.',
          ),
        },
        {
          'title': tr(
            '4. ميزة "اكتشف ما حولك" المرتبة حسب الأقرب إليك',
            '4. "Explore Nearby" Sorted by Closest Distance',
          ),
          'body': tr(
            '• شريط وصول سريع لاكتشاف الخدمات المحيطة بك: (مطاعم، مستشفيات، محطات وقود، شواحن كهربائية، مساجد، بنوك، ومراكز تسوق).\n• يقوم التطبيق بجلب الأماكن المحيطة بموقعك وترتيبها تصاعدياً من الأقرب إليك بالكيلومتر، مع إمكانية عرضها جميعاً على الخريطة أو الانطلاق لأي منها بضغطة واحدة.',
            '• Quick-access bar to discover nearby restaurants, hospitals, fuel stations, EV chargers, mosques, banks, and shopping centers—automatically sorted from closest to farthest.',
          ),
        },
        {
          'title': tr(
            '5. ميزة "دلّي صديق" ومشاركة موقعي وخرائط الـ 18 محافظة بدون نت',
            '5. "Guide a Friend", Live Location & 18 Offline Province Maps',
          ),
          'body': tr(
            '• مشاركة موقعك الحالي المباشر مع أصدقائك، أو استخدام ميزة "دلّي صديق على مكان" لتحديد أي نقطة على الخريطة وإرسالها لصديقك ليرسم له تطبيق "دلّيني" المسار إليها تلقائياً.\n• ميزة تحميل خرائط جميع محافظات العراق الـ 18 كاملة للعمل بكفاءة عالية حتى عند انقطاع اتصال الإنترنت في الطرق الخارجية.',
            '• Share your live GPS spot or use "Guide a Friend" to send any pinned destination so Dlinii plots the route for your friend automatically.\n• Downloadable offline maps for all 18 Iraqi governorates.',
          ),
        },
      ];
      showModalBox = true;
    });
  }

  void _openQuickPlace(String shortcut) {
    for (final place in _places) {
      if (place['shortcut'] == shortcut) {
        setState(() {
          dest = LatLng(
            (place['lat'] as num).toDouble(),
            (place['lng'] as num).toDouble(),
          );
          destName = place['name'].toString();
          destController.text = destName;
        });
        _planRoute();
        return;
      }
    }
    _placeDraft = {
      'shortcut': shortcut,
      'name': shortcut == 'home' ? tr('المنزل', 'Home') : tr('العمل', 'Work'),
      'category': 'other',
    };
    _namePlace(me ?? mapController.camera.center);
  }

  double _homeExtent = .30;

  bool _routeBusy = false;

  void _pickFromHome(String mode) {
    FocusScope.of(context).unfocus();
    setState(() {
      pickMode = mode;
      showSearchList = false;
    });
    _toast(
      tr('المس النقطة المطلوبة على الخريطة', 'Tap the location on the map'),
    );
  }

  Widget _homeRow(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Material(
      color: landColor,
      borderRadius: DliniiBrand.cardShape,
      child: ListTile(
        onTap: action,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DliniiAppIcon(icon, color: accentColor, size: 23),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle, style: TextStyle(color: subColor, fontSize: 12)),
        trailing: DliniiAppIcon(
          Icons.arrow_forward_ios_rounded,
          color: subColor,
          size: 15,
        ),
      ),
    ),
  );

  void _openHomeMenu() {
    FocusScope.of(context).unfocus();
    if (isEnglish) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  ThemeData get _interfaceTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Tajawal',
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DliniiBrand.teal,
      brightness: isDark ? Brightness.dark : Brightness.light,
      surface: panelColor,
    ),
    scaffoldBackgroundColor: panelColor,
  );

  void _openHomeSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, refresh) => Theme(
          data: _interfaceTheme,
          child: ColoredBox(
            color: panelColor,
            child: Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * .80,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _homeRow(
                        tr('حسابي', 'My account'),
                        tr(
                          'البريد وكلمة المرور وملكية الأماكن',
                          'Email, password and place ownership',
                        ),
                        Icons.person_outline,
                        _accountAction,
                      ),
                      Text(
                        tr('الإعدادات', 'Settings'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        tr('اللغة', 'Language'),
                        style: TextStyle(color: textColor, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('العربية')),
                          ButtonSegment(value: true, label: Text('English')),
                        ],
                        selected: {isEnglish},
                        showSelectedIcon: false,
                        onSelectionChanged: (values) async {
                          if (values.first != isEnglish)
                            await _toggleLanguage();
                          if (sheetContext.mounted) refresh(() {});
                        },
                      ),
                      const SizedBox(height: 26),
                      Text(
                        tr('مظهر الخريطة', 'Map appearance'),
                        style: TextStyle(color: textColor, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(tr('نهاري', 'Day')),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(tr('ليلي', 'Night')),
                          ),
                        ],
                        selected: {isDark},
                        showSelectedIcon: false,
                        onSelectionChanged: (values) async {
                          setState(() => isDark = values.first);
                          refresh(() {});
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            'dlini_is_dark_default_v2',
                            isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      SwitchListTile.adaptive(
                        value: voiceEnabled,
                        activeTrackColor: accentColor,
                        title: Text(
                          tr('التوجيه الصوتي', 'Voice guidance'),
                          style: TextStyle(color: textColor),
                        ),
                        onChanged: (_) {
                          _toggleVoiceState();
                          refresh(() {});
                        },
                      ),
                      _homeRow(
                        tr('الصوت وسرعة التحدث', 'Voice & speaking speed'),
                        '',
                        Icons.record_voice_over_rounded,
                        () {
                          Navigator.pop(sheetContext);
                          setState(() => showVoiceModal = true);
                        },
                      ),
                      const SizedBox(height: 20),
                      _homeRow(
                        tr('أماكني والسجل', 'My places & history'),
                        tr(
                          'عرض الأماكن المحفوظة وحذفها',
                          'View and delete saved places',
                        ),
                        Icons.star_rounded,
                        () {
                          Navigator.pop(sheetContext);
                          _showPlaces();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeSheet() =>
      NotificationListener<DraggableScrollableNotification>(
        onNotification: (notice) {
          if ((_homeExtent - notice.extent).abs() > .005)
            setState(() => _homeExtent = notice.extent);
          return false;
        },
        child: DliniiSheet(
          builder: (context, scroll, expand) => Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(color: lineColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 25,
                  ),
                ],
              ),
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: subColor.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: landColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/dlinii_icon.png',
                            width: 30,
                            height: 30,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: destController,
                            style: TextStyle(color: textColor, fontSize: 17),
                            onTap: expand,
                            onChanged: (v) => _onSearchChanged(v, 'q'),
                            decoration: InputDecoration(
                              hintText: tr('وين نوصلك؟', 'Where shall we go?'),
                              hintStyle: TextStyle(color: subColor),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        _compactSearchAction(
                          'mic',
                          tr('بحث صوتي بالعربية', 'Arabic voice search'),
                          _toggleVoiceSearch,
                          active: isListeningVoice,
                        ),
                        _compactSearchAction(
                          'paste',
                          tr('لصق موقع', 'Paste location'),
                          _pasteLocation,
                        ),
                      ],
                    ),
                  ),
                  if (showSearchList) ...[
                    const SizedBox(height: 12),
                    if (searchResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          tr('لا توجد نتائج مطابقة', 'No matching results'),
                          style: TextStyle(color: subColor),
                        ),
                      ),
                    for (final item in searchResults)
                      ListTile(
                        leading: DliniiAppIcon(
                          Icons.pin_drop_rounded,
                          color: accentColor,
                          size: 23,
                        ),
                        title: Text(
                          (item['name'] ?? item['display_name'] ?? '')
                              .toString()
                              .split(',')
                              .first,
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          _fmtSearchDist(item) +
                              (item['display_name'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subColor, fontSize: 12),
                        ),
                        onTap: () {
                          final lat = double.tryParse(item['lat'].toString()),
                              lng = double.tryParse(item['lon'].toString());
                          if (lat == null ||
                              lng == null ||
                              !lat.isFinite ||
                              !lng.isFinite ||
                              lat.abs() > 90 ||
                              lng.abs() > 180)
                            return;
                          FocusScope.of(context).unfocus();
                          if (activeSearchField == 'origin') {
                            setState(() {
                              origin = LatLng(lat, lng);
                              originController.text =
                                  (item['name'] ?? item['display_name'] ?? '')
                                      .toString()
                                      .split(',')
                                      .first;
                              showSearchList = false;
                            });
                            if (dest != null) _planRoute();
                            return;
                          }
                          setState(() {
                            dest = LatLng(lat, lng);
                            destName =
                                (item['name'] ?? item['display_name'] ?? '')
                                    .toString()
                                    .split(',')
                                    .first;
                            destController.text = destName;
                            showSearchList = false;
                          });
                          _planRoute();
                        },
                      ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _placeAction(
                          tr('أماكني', 'My places'),
                          Icons.star_rounded,
                          _showPlaces,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _placeAction(
                          tr('تحديد وجهة', 'Pick destination'),
                          Icons.pin_drop_rounded,
                          () => _pickFromHome('dest'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _placeAction(
                          tr('المنزل', 'Home'),
                          Icons.home_rounded,
                          () => _openQuickPlace('home'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _placeAction(
                          tr('العمل', 'Work'),
                          Icons.work_rounded,
                          () => _openQuickPlace('work'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    tr('محطات على طريقك', 'Stops along your way'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (_, box) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final cat in kExploreCategories)
                          SizedBox(
                            width: box.maxWidth < 280
                                ? box.maxWidth
                                : (box.maxWidth - 10) / 2,
                            child: DliniiExploreTile(
                              dark: isDark,
                              label: isEnglish ? cat.nameEn : cat.nameAr,
                              hint: tr('اعرض الأقرب', 'Find nearby'),
                              icon: DliniiPlaceBadge(
                                const {
                                      'restaurants': 'restaurant',
                                      'hospitals': 'hospital',
                                      'chargers': 'charging',
                                      'mosques': 'mosque',
                                      'banks': 'bank',
                                    }[cat.id] ??
                                    cat.id,
                                size: 38,
                              ),
                              onTap: () => _openAndFetchCategory(cat),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _homeRow(
                    tr('خرائط دون اتصال', 'Offline maps'),
                    tr('إدارة الخرائط المحفوظة', 'Manage saved maps'),
                    Icons.cloud_download_rounded,
                    () => setState(() => showOfflineMapsModal = true),
                  ),
                  _homeRow(
                    tr('إضافة مكان', 'Add a place'),
                    tr(
                      'انشر مكاناً للجميع بحسابك',
                      'Publish a place with your account',
                    ),
                    Icons.add_rounded,
                    () => _namePlace(me ?? mapController.camera.center),
                  ),
                  _homeRow(
                    tr('دلّي صديق', 'Guide a friend'),
                    tr('شارك مكاناً بسهولة', 'Share a destination'),
                    Icons.share_rounded,
                    () => _pickFromHome('share_spot'),
                  ),
                  ExpansionTile(
                    title: Text(
                      tr('نقطة الانطلاق', 'Starting point'),
                      style: TextStyle(color: textColor),
                    ),
                    children: [
                      TextField(
                        controller: originController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: tr('موقعي الحالي', 'Current location'),
                        ),
                        onChanged: (v) => _onSearchChanged(v, 'origin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildStandardAppDrawer() {
    void open(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    DliniiMenuEntry entry(
      String ar,
      String en,
      IconData icon,
      VoidCallback action, [
      String detail = '',
    ]) => DliniiMenuEntry(
      label: tr(ar, en),
      detail: detail,
      icon: DliniiAppIcon(icon, color: accentColor, size: 23),
      onTap: action,
    );
    return DliniiSideMenu(
      dark: isDark,
      english: isEnglish,
      onClose: () => Navigator.of(context).pop(),
      entries: [
        entry(
          'أماكني ورحلاتي',
          'My places & journeys',
          Icons.star_rounded,
          () => open(_showPlaces),
        ),
        entry(
          'إضافة مكان',
          'Add a place',
          Icons.add_rounded,
          () => open(() => _namePlace(me ?? mapController.camera.center)),
        ),
        entry(
          'خرائطي المحفوظة',
          'Saved maps',
          Icons.cloud_download_rounded,
          () => open(() => setState(() => showOfflineMapsModal = true)),
        ),
        entry(
          'دلّي صديق',
          'Guide a friend',
          Icons.send_rounded,
          () => open(() => _pickFromHome('share_spot')),
          tr(
            'مكان منك… والطريق من دلّيني',
            'Your destination. Dlinii directions.',
          ),
        ),
        entry(
          'شارك موقعي',
          'Share my location',
          Icons.share_location_rounded,
          () => open(_shareMyCurrentLocation),
        ),
        entry(
          'افتح رابط موقع',
          'Open a location link',
          Icons.content_paste_go_rounded,
          () => open(_pasteLocation),
        ),
        entry(
          'ضبط رحلتك',
          'Journey settings',
          Icons.tune_rounded,
          () => open(_openHomeSettings),
        ),
        entry(
          'صوت دلّيني',
          'Dlinii voice',
          Icons.record_voice_over_rounded,
          () => open(() => setState(() => showVoiceModal = true)),
        ),
        entry(
          'الخصوصية',
          'Privacy',
          Icons.verified_user_rounded,
          _openPrivacyModal,
        ),
        entry(
          'عن دلّيني',
          'About Dlinii',
          Icons.info_outline_rounded,
          _openAboutModal,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection outerDir = Directionality.of(context);
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: outerDir,
        child: Theme(
          data: _interfaceTheme,
          child: Builder(builder: _buildMain),
        ),
      ),
    );
  }

  Widget _panelShell(
    String title,
    String subtitle,
    Widget body,
    VoidCallback close, {
    double height = .78,
  }) => Positioned.fill(
    child: Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            width: 540,
            height: MediaQuery.sizeOf(context).height * height,
            margin: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: lineColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/dlinii_icon.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: tr('إغلاق', 'Close'),
                        onPressed: close,
                        icon: DliniiAppIcon(
                          Icons.close_rounded,
                          color: textColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 8,
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(color: subColor, height: 1.5),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _explorePanel() {
    final category = kExploreCategories.firstWhere(
      (c) => c.id == selectedCategoryId,
      orElse: () => kExploreCategories.first,
    );
    return _panelShell(
      tr('محطات على طريقك', 'Stops along your way'),
      tr('اختر مكانك التالي', 'Choose your next destination'),
      Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final cat in kExploreCategories)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      selected: cat.id == selectedCategoryId,
                      onSelected: (_) => _openAndFetchCategory(cat),
                      avatar: DliniiAppIcon(
                        cat.icon,
                        color: cat.color,
                        size: 18,
                      ),
                      label: Text(isEnglish ? cat.nameEn : cat.nameAr),
                    ),
                  ),
              ],
            ),
          ),
          if (nearbyCategoryPlaces.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _showCategoryResultsOnMap,
                child: Text(
                  tr('عرض النتائج على الخريطة', 'Show results on map'),
                ),
              ),
            ),
          Expanded(
            child: isLoadingCategory
                ? Center(child: DliniiLoader(color: accentColor, size: 40))
                : nearbyCategoryPlaces.isEmpty
                ? Center(
                    child: Text(
                      tr('لا توجد نتائج قريبة', 'No nearby results'),
                      style: TextStyle(color: subColor),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: nearbyCategoryPlaces.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = nearbyCategoryPlaces[index];
                      return Material(
                        color: landColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: DliniiBrand.cardShape,
                          side: BorderSide(color: lineColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DliniiAppIcon(
                              category.icon,
                              color: category.color,
                              size: 23,
                            ),
                          ),
                          title: Text(
                            item['title'].toString(),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            item['subtitle'].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subColor),
                          ),
                          trailing: Text(
                            '${(item['distKm'] as num).toStringAsFixed(1)} ${tr('كم', 'km')}',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              dest = LatLng(
                                (item['lat'] as num).toDouble(),
                                (item['lng'] as num).toDouble(),
                              );
                              destName = item['title'].toString();
                              destController.text = destName;
                              showExploreModal = false;
                            });
                            _planRoute();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      () => setState(() => showExploreModal = false),
    );
  }

  Widget _offlinePanel() => _panelShell(
    tr('خرائطك المحفوظة', 'Your saved maps'),
    kIsWeb
        ? tr(
            'التنزيل الدائم متاح حالياً على تطبيق الهاتف.',
            'Persistent downloads are currently available in the mobile app.',
          )
        : tr(
            'التنزيل يغطي منطقة حول مركز المحافظة؛ لا يشمل كامل المحافظة أو حساب مسارات جديدة دون اتصال.',
            'Downloads cover the provincial centre area, not the entire province or new offline routes.',
          ),
    ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: kIraqProvinces.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final province = kIraqProvinces[index];
        final saved = downloadedProvinces.contains(province.id);
        final loading = downloadingProvinceId == province.id;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: landColor,
            borderRadius: DliniiBrand.cardShape,
            border: Border.all(color: lineColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  DliniiAppIcon(
                    Icons.map_rounded,
                    color: accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEnglish ? province.nameEn : province.nameAr,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (loading)
                    DliniiLoader(size: 28, color: accentColor)
                  else if (saved)
                    IconButton(
                      tooltip: tr('حذف التنزيل', 'Delete download'),
                      onPressed: () => _deleteProvinceOfflineMap(province),
                      icon: DliniiAppIcon(
                        Icons.delete_outline_rounded,
                        color: subColor,
                        size: 22,
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: kIsWeb || downloadingProvinceId != null
                          ? null
                          : () => _downloadProvinceOfflineMap(province),
                      child: Text(tr('تنزيل', 'Download')),
                    ),
                ],
              ),
              if (loading)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(
                    value: downloadProgress,
                    color: accentColor,
                  ),
                ),
              if (saved)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    tr(
                      'منطقة محفوظة على هذا الجهاز',
                      'Area saved on this device',
                    ),
                    style: TextStyle(color: accentColor, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    ),
    () => setState(() => showOfflineMapsModal = false),
  );

  Widget _permissionPanel() => _panelShell(
    tr('خلّ دلّيني يعرف طريقك', 'Let Dlinii find your way'),
    tr(
      'اسمح بالموقع لعرض موقعك والتوجيه. يمكنك تغيير الإذن من إعدادات جهازك.',
      'Allow location to show your position and directions. You can change this in device settings.',
    ),
    SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () {
              setState(() => showNotifPermissionModal = false);
              _initLocationTracking(userInitiated: true);
            },
            child: Text(tr('السماح بالموقع', 'Allow location')),
          ),
          TextButton(
            onPressed: () => setState(() => showNotifPermissionModal = false),
            child: Text(tr('لاحقاً', 'Later')),
          ),
        ],
      ),
    ),
    () => setState(() => showNotifPermissionModal = false),
    height: .58,
  );

  Widget _buildMain(BuildContext context) {
    final activeVtStyle = isDark ? (_vtDark ?? _vtLight) : _vtLight;
    final Widget? ofmLayer = (activeVtStyle == null || _forceOffline)
        ? null
        : vt.VectorTileLayer(
            key: const ValueKey('dlinii_vector_map'),
            theme: activeVtStyle.theme,
            tileProviders: activeVtStyle.providers,
            rasterSources: activeVtStyle.rasterSources,
            sprites: activeVtStyle.sprites,
          );

    final Matrix4 perspectiveMatrix = isFirstPerson3D
        ? (Matrix4.identity()
            ..setEntry(3, 2, 0.00085)
            ..rotateX(-0.50)
            ..scale(1.18))
        : Matrix4.identity();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: landColor,
      drawer: isEnglish ? null : _buildStandardAppDrawer(),
      endDrawer: isEnglish ? _buildStandardAppDrawer() : null,
      drawerScrimColor: const Color(0xFF041B22).withValues(alpha: .55),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            transformAlignment: Alignment.center,
            transform: perspectiveMatrix,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                onMapReady: () {
                  _mapReady = true;
                  if (_hasRealFix && me != null) mapController.move(me!, 15.5);
                  final pending = _pendingMapLink;
                  _pendingMapLink = null;
                  if (pending != null) _handleIncomingUri(pending);
                },
                backgroundColor: isDark
                    ? const Color(0xFF101814)
                    : const Color(0xFFF3F7FA),
                initialCenter: me ?? kDefaultCenter,
                initialZoom: currentZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && follow) setState(() => follow = false);
                  currentZoom = pos.zoom;
                },
                onLongPress: (tapPos, point) => _namePlace(point),
                onTap: (tapPos, point) {
                  if (selectedReportPopupId != null) {
                    setState(() => selectedReportPopupId = null);
                  }
                  if (pickMode == null) return;
                  final mode = pickMode;
                  setState(() => pickMode = null);
                  if (mode == 'report') {
                    setState(() {
                      reportPoint = point;
                      showRepSheet = true;
                    });
                  } else if (mode == 'save_place') {
                    _namePlace(point);
                  } else if (mode == 'origin') {
                    setState(() {
                      origin = point;
                      originController.text = tr(
                        'نقطة انطلاق محددة',
                        'Selected Origin',
                      );
                    });
                    _toast(tr('تم تحديد نقطة الانطلاق', 'Origin selected'));
                    if (dest != null) _planRoute();
                  } else if (mode == 'dest') {
                    setState(() {
                      dest = point;
                      destName = tr('موقع محدد على الخريطة', 'Pinned Location');
                      destController.text = destName;
                    });
                    _planRoute();
                  } else if (mode == 'share_spot') {
                    _shareCustomSpot(
                      point,
                      tr('موقع محدد على الخريطة', 'Pinned Map Location'),
                    );
                  }
                },
              ),
              children: [
                if (ofmLayer != null)
                  ofmLayer
                else
                  ColorFiltered(
                    key: const ValueKey<String>('dlinii_raster_map'),
                    colorFilter: isDark ? kInstantDarkFilter : kSoftDayFilter,
                    child: TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      maxZoom: 20,
                      userAgentPackageName: 'com.dlinii.app',
                      tileProvider: _offlineTileProvider,
                    ),
                  ),
                if (routes.isNotEmpty)
                  PolylineLayer<Object>(
                    polylines: [
                      ...routes.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final List<dynamic> coords =
                            entry.value['geometry']['coordinates'];
                        final points = coords
                            .map(
                              (c) => LatLng(
                                (c[1] as num).toDouble(),
                                (c[0] as num).toDouble(),
                              ),
                            )
                            .toList();
                        final bool isSelected = idx == selectedRouteIndex;
                        if (!isSelected) {
                          return Polyline(
                            points: points,
                            color: isDark
                                ? const Color(0xFF475569).withOpacity(0.55)
                                : const Color(0xFF94A3B8).withOpacity(0.65),
                            strokeWidth: 5.5,
                          );
                        }
                        return Polyline(
                          points: points,
                          color: isDark
                              ? const Color(0xFF10b981)
                              : const Color(0xFF087e76),
                          strokeWidth: 9.0,
                          borderColor: isDark
                              ? const Color(0xFF042f2e)
                              : const Color(0xFF134e4a),
                          borderStrokeWidth: 2.0,
                        );
                      }),
                      if (routes.isNotEmpty)
                        ...routes
                            .asMap()
                            .entries
                            .where((entry) => entry.key == selectedRouteIndex)
                            .map((entry) {
                              final List<dynamic> coords =
                                  entry.value['geometry']['coordinates'];
                              final points = coords
                                  .map(
                                    (c) => LatLng(
                                      (c[1] as num).toDouble(),
                                      (c[0] as num).toDouble(),
                                    ),
                                  )
                                  .toList();
                              final double flowAlpha =
                                  (0.55 + 0.35 * math.sin(pulseValue)).clamp(
                                    0.25,
                                    0.90,
                                  );
                              return Polyline(
                                points: points,
                                color:
                                    (isDark
                                            ? const Color(0xFF6ee7b7)
                                            : const Color(0xFF99f6e4))
                                        .withOpacity(flowAlpha),
                                strokeWidth: 3.8,
                              );
                            }),
                      if (routes.isNotEmpty)
                        ..._buildRealTrafficAndHazardOverlays(
                          routes[selectedRouteIndex] as Map<String, dynamic>,
                          (routes[selectedRouteIndex]['geometry']['coordinates']
                                  as List)
                              .map(
                                (c) => LatLng(
                                  (c[1] as num).toDouble(),
                                  (c[0] as num).toDouble(),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ...categoryMapMarkers,
                    ...[
                      ..._publicPlaces,
                      ..._places.where(
                        (p) => p['saved'] == true && p['publicId'] == null,
                      ),
                    ].map(
                      (p) => Marker(
                        point: LatLng(
                          (p['lat'] as num).toDouble(),
                          (p['lng'] as num).toDouble(),
                        ),
                        width: 24,
                        height: 24,
                        rotate: true,
                        child: Tooltip(
                          message: p['name'] as String,
                          child: GestureDetector(
                            onTap: () => _showPlaceDetails(p),
                            child: DliniiPlaceBadge(
                              p['category']?.toString() ?? 'other',
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (origin != null)
                      Marker(
                        point: origin!,
                        width: 38,
                        height: 38,
                        child: SvgPicture.string(kOriginPinSvg),
                      ),
                    if (dest != null)
                      Marker(
                        point: dest!,
                        width: 42,
                        height: 48,
                        child: SvgPicture.string(kDestPinSvg),
                      ),
                    ...cloudReports
                        .where(
                          (doc) => _reportIsVisible(
                            doc.data() as Map<String, dynamic>,
                          ),
                        )
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final LatLng pt = LatLng(
                            ((data['lat'] ?? 33.4258) as num).toDouble(),
                            ((data['lng'] ?? 43.2995) as num).toDouble(),
                          );
                          return Marker(
                            point: pt,
                            width: 44,
                            height: 44,
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
                                  border: Border.all(
                                    color: const Color(0xFFefbb52),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.22),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: _buildReportSvg(
                                  data['type']?.toString(),
                                  size: 26,
                                ),
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
                        point: (_hasRealFix || isNavigating)
                            ? v.pos
                            : (me ?? kDefaultCenter),
                        width: 58,
                        height: 58,
                        child: isNavigating
                            ? Transform.rotate(
                                angle: v.bearing * math.pi / 180,
                                child: SvgPicture.string(kGreenNavArrowSvg),
                              )
                            : SvgPicture.string(kMyLocationPulseSvg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isFirstPerson3D)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 110,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        landColor.withOpacity(0.92),
                        landColor.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (selectedReportPopupId != null && selectedReportPopupData != null)
            Positioned(
              top: 160,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: lineColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 22),
                          Row(
                            children: [
                              _buildReportSvg(
                                selectedReportPopupData!['type']?.toString(),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getReportLabel(
                                  selectedReportPopupData!['type']?.toString(),
                                  selectedReportPopupData!['label']?.toString(),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => selectedReportPopupId = null),
                            child: DliniiAppIcon(
                              Icons.close_rounded,
                              size: 19,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tr(
                          'يختفي البلاغ عند $endVotesThreshold أصوات انتهاء',
                          'Hidden at $endVotesThreshold votes',
                        ),
                        style: TextStyle(fontSize: 10.5, color: subColor),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GlassTapButton(
                              onTap: () =>
                                  _voteReportYes(selectedReportPopupId!),
                              backgroundColor: const Color(0xFF16a34a),
                              borderColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              borderRadius: BorderRadius.circular(10),
                              child: Text(
                                '${tr('موجود', 'Exists')} (${selectedReportPopupData!['confirmations'] ?? 1})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GlassTapButton(
                              onTap: () => _voteReportNo(
                                selectedReportPopupId!,
                                ((selectedReportPopupData!['endVotes'] ?? 0)
                                        as num)
                                    .toInt(),
                              ),
                              backgroundColor: const Color(0xFFE5484D),
                              borderColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              borderRadius: BorderRadius.circular(10),
                              child: Text(
                                '${tr('منتهي', 'Ended')} (${selectedReportPopupData!['endVotes'] ?? 0}/$endVotesThreshold)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!isNavigating && !showPlanSheet && pickMode == null)
            Positioned.fill(
              key: const ValueKey('home-planner'),
              child: _buildHomeSheet(),
            ),
          if (!isNavigating && !showPlanSheet)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: 18,
              right: 18,
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassTapButton(
                    width: 52,
                    height: 52,
                    backgroundColor: panelColor,
                    borderColor: lineColor,
                    borderRadius: BorderRadius.circular(19),
                    onTap: _openHomeMenu,
                    child: DliniiControlIcon(
                      'menu',
                      color: textColor,
                      size: 25,
                    ),
                  ),
                  GlassTapButton(
                    width: 52,
                    height: 52,
                    backgroundColor: panelColor,
                    borderColor: lineColor,
                    borderRadius: BorderRadius.circular(19),
                    onTap: _openHomeSettings,
                    child: DliniiAppIcon(
                      Icons.layers_rounded,
                      color: textColor,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          if (pickMode != null && !isNavigating)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _homeRow(
                tr('حدد المكان على الخريطة', 'Choose a map location'),
                tr('إلغاء التحديد', 'Cancel selection'),
                Icons.close_rounded,
                () => setState(() => pickMode = null),
              ),
            ),
          if (_routeBusy)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 82,
              left: 55,
              right: 55,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DliniiLoader(
                        label: tr('جارٍ تجهيز المسار', 'Preparing route'),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          tr('جارٍ تجهيز المسار…', 'Preparing route…'),
                          style: const TextStyle(color: Color(0xFF15241C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: !isNavigating && !showPlanSheet && pickMode == null
                ? MediaQuery.sizeOf(context).height * _homeExtent + 82
                : 165,
            child: Column(
              children: [
                GlassTapButton(
                  width: 42,
                  height: 42,
                  backgroundColor: glassColor,
                  borderColor: lineColor,
                  borderRadius: BorderRadius.circular(13),
                  onTap: _zoomIn,
                  child: DliniiAppIcon(
                    Icons.add_rounded,
                    size: 21,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                GlassTapButton(
                  width: 42,
                  height: 42,
                  backgroundColor: glassColor,
                  borderColor: lineColor,
                  borderRadius: BorderRadius.circular(13),
                  onTap: _zoomOut,
                  child: DliniiAppIcon(
                    Icons.remove_rounded,
                    size: 21,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                GlassTapButton(
                  width: 42,
                  height: 42,
                  backgroundColor: isFirstPerson3D
                      ? const Color(0xFF087e76)
                      : glassColor,
                  borderColor: isFirstPerson3D
                      ? const Color(0xFF7ce0be)
                      : lineColor,
                  borderRadius: BorderRadius.circular(13),
                  onTap: _toggle3DPerspective,
                  child: Text(
                    isFirstPerson3D ? '3D' : '2D',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: isFirstPerson3D ? Colors.white : accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: isNavigating
                ? 105
                : !showPlanSheet && pickMode == null
                ? MediaQuery.sizeOf(context).height * _homeExtent + 14
                : 100,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GlassTapButton(
                    width: 52,
                    height: 52,
                    borderRadius: BorderRadius.circular(19),
                    backgroundColor: const Color(0xFFF7FAF8),
                    borderColor: const Color(0xFFefbb52).withOpacity(0.65),
                    onTap: _onReportButtonTap,
                    child: SvgPicture.string(
                      kReportShieldSvg,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GlassTapButton(
                    width: 52,
                    height: 52,
                    isCircle: true,
                    backgroundColor: glassColor,
                    borderColor: accentColor.withOpacity(0.5),
                    onTap: () {
                      setState(() => follow = true);
                      _initLocationTracking(userInitiated: true);
                      if (me != null) {
                        _flyToMyLocation(
                          me!,
                          targetZoom: isNavigating ? 17.8 : 16.8,
                        );
                      }
                    },
                    child: SvgPicture.string(
                      kGpsTargetSvg,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showOfflineMapsModal) _offlinePanel(),
          if (showExploreModal) _explorePanel(),
          if (showPlanSheet)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: lineColor),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      SvgPicture.string(
                                        kDestPinSvg,
                                        width: 18,
                                        height: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          destName,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (dest != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: GlassTapButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 6,
                                      ),
                                      backgroundColor: landColor,
                                      borderColor: lineColor,
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () =>
                                          _shareCustomSpot(dest!, destName),
                                      child: Row(
                                        children: [
                                          DliniiAppIcon(
                                            Icons.share_rounded,
                                            size: 14,
                                            color: accentColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            tr('دلّي صديق', 'Guide Friend'),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                GlassTapButton(
                                  width: 32,
                                  height: 32,
                                  backgroundColor: landColor,
                                  borderColor: lineColor,
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () => _endNav(arrived: false),
                                  child: DliniiAppIcon(
                                    Icons.close_rounded,
                                    color: textColor,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: routes.length,
                                itemBuilder: (context, i) {
                                  final r = routes[i];
                                  final bool isSelected =
                                      i == selectedRouteIndex;
                                  final int mins = ((r['duration'] as num) / 60)
                                      .round();
                                  final double kms =
                                      (r['distance'] as num) / 1000;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => selectedRouteIndex = i),
                                    child: Container(
                                      width: 115,
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? accentColor
                                              : lineColor,
                                          width: 1.8,
                                        ),
                                        color: isSelected
                                            ? accentColor.withOpacity(0.12)
                                            : landColor.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$mins ${tr('دقيقة', 'min')}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            '${kms.toStringAsFixed(1)} ${tr('كم', 'km')}${r['dlinii_source'] == 'fallback' ? tr(' · تقريبي', ' · Approx') : (r['dlinii_source'] == 'cache' ? tr(' · محفوظ', ' · Saved') : (i == 0 ? tr(' · الأسرع', ' · Fastest') : ''))}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: subColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            GlassTapButton(
                              width: double.infinity,
                              height: 44,
                              backgroundColor: const Color(0xFF087e76),
                              borderColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              onTap: _startNav,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const DliniiAppIcon(
                                    Icons.navigation_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('انطلاق الرحلة', 'Start Journey'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            GlassTapButton(
                              width: double.infinity,
                              height: 36,
                              backgroundColor: landColor,
                              borderColor: lineColor,
                              borderRadius: BorderRadius.circular(10),
                              onTap: _startSimulation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DliniiAppIcon(
                                    Icons.play_circle_fill_rounded,
                                    size: 16,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('محاكاة الرحلة', 'Journey Simulation'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
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
                ),
              ),
            ),
          if (isNavigating) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              left: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102826).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF7ce0be).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9cdbc0)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                hudArrow,
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: Color(0xFF9cdbc0),
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hudInstruction,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hudStreet,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF9cdbc0),
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
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 105,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: panelColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$currentSpeedKmh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: textColor,
                      ),
                    ),
                    Text(
                      tr('كم/س', 'km/h'),
                      style: TextStyle(
                        fontSize: 8.5,
                        color: subColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: lineColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  navEta,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  tr('الوصول', 'ETA'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  navRemMins,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                                Text(
                                  tr('دقيقة', 'min'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  navRemKm,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  tr('كم', 'km'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                            GlassTapButton(
                              width: 38,
                              height: 38,
                              backgroundColor: landColor,
                              borderColor: lineColor,
                              borderRadius: BorderRadius.circular(11),
                              onTap: _toggleVoiceState,
                              child: DliniiControlIcon(
                                voiceEnabled ? 'sound' : 'mute',
                                size: 24,
                                color: voiceEnabled
                                    ? accentColor
                                    : const Color(0xFFFF8589),
                              ),
                            ),
                            GlassTapButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              backgroundColor: const Color(0xFFE5484D),
                              borderColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              onTap: () => _endNav(arrived: false),
                              child: Text(
                                tr('إنهاء', 'End'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (showRepSheet)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .85,
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: lineColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const DliniiReportIcon('hazard', size: 29),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr(
                                        'خلّي الطريق أوضح',
                                        'Make the road clearer',
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                GlassTapButton(
                                  width: 32,
                                  height: 32,
                                  backgroundColor: landColor,
                                  borderColor: lineColor,
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () => setState(() {
                                    showRepSheet = false;
                                    pickMode = null;
                                  }),
                                  child: DliniiAppIcon(
                                    Icons.close_rounded,
                                    color: textColor,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              reportPoint != null
                                  ? '${tr('الموقع:', 'Spot:')} ${reportPoint!.latitude.toStringAsFixed(4)} ، ${reportPoint!.longitude.toStringAsFixed(4)}'
                                  : tr(
                                      'موقع البلاغ: موقعك الحالي عبر GPS',
                                      'Report location: Current GPS',
                                    ),
                              style: TextStyle(fontSize: 11.5, color: subColor),
                            ),
                            const SizedBox(height: 9),
                            GlassTapButton(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              backgroundColor: landColor,
                              borderColor: accentColor,
                              borderRadius: BorderRadius.circular(11),
                              onTap: () {
                                setState(() {
                                  showRepSheet = false;
                                  pickMode = 'report';
                                });
                                _toast(
                                  tr(
                                    'اضغط على مكان البلاغ بالخريطة',
                                    'Tap report spot on map',
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.string(
                                    kGpsTargetSvg,
                                    width: 17,
                                    height: 17,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    tr(
                                      'تحديد موقع البلاغ على الخريطة',
                                      'Pick report spot on map',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.55,
                              children: [
                                _buildRepGridBtn('bump', tr('مطب', 'Bump')),
                                _buildRepGridBtn(
                                  'pothole',
                                  tr('حفرة', 'Pothole'),
                                ),
                                _buildRepGridBtn('crash', tr('حادث', 'Crash')),
                                _buildRepGridBtn(
                                  'traffic',
                                  tr('ازدحام', 'Traffic'),
                                ),
                                _buildRepGridBtn(
                                  'police',
                                  tr('نقطة مرور', 'Police'),
                                ),
                                _buildRepGridBtn(
                                  'hazard',
                                  tr('خطر آخر', 'Hazard'),
                                ),
                                _buildRepGridBtn(
                                  'roadworks',
                                  tr('حفريات', 'Roadworks'),
                                ),
                                _buildRepGridBtn(
                                  'closed',
                                  tr('طريق مغلق', 'Road closed'),
                                ),
                                _buildRepGridBtn(
                                  'camera',
                                  tr('كاميرا سرعة', 'Camera'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (showVoiceModal)
            GestureDetector(
              onTap: () => setState(() => showVoiceModal = false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(18),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 385,
                      maxHeight: 530,
                    ),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: lineColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF142e2d), Color(0xFF087e76)],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const DliniiAppIcon(
                                    Icons.record_voice_over_rounded,
                                    color: Color(0xFFefbb52),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr(
                                      'المساعد الصوتي (عربي / أجنبي)',
                                      'Voice Assistant (AR / EN)',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => showVoiceModal = false),
                                child: const DliniiAppIcon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                            itemCount: kVoiceProfiles.length,
                            itemBuilder: (context, idx) {
                              final vp = kVoiceProfiles[idx];
                              final bool isSelected = idx == selectedVoiceIndex;
                              final bool isPinned = _pinnedSlot.containsKey(
                                vp.id,
                              );
                              final int slot =
                                  _pinnedSlot[vp.id] ??
                                  (_voiceSlot[vp.id] ?? 0);
                              final String slotName = slot == 0
                                  ? tr('الصوت 1: فتاة', 'Voice 1: Female')
                                  : tr('الصوت 2: رجل', 'Voice 2: Male');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassTapButton(
                                  padding: const EdgeInsets.all(14),
                                  backgroundColor: isSelected
                                      ? accentColor.withOpacity(0.15)
                                      : landColor,
                                  borderColor: isSelected
                                      ? accentColor
                                      : lineColor,
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    _onTapVoiceCardOnly(idx);
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? accentColor
                                              : panelColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: accentColor,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: DliniiAppIcon(
                                          slot == 0
                                              ? Icons.face_3_rounded
                                              : Icons.face_6_rounded,
                                          color: isSelected
                                              ? Colors.white
                                              : accentColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    isEnglish
                                                        ? vp.nameEn
                                                        : vp.nameAr,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                if (isPinned)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFefbb52,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      tr(
                                                        'مثبّت 📌',
                                                        'Pinned 📌',
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Color(
                                                          0xFF142e2d,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${isEnglish ? vp.descEn : vp.descAr} ($slotName)',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: subColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        DliniiAppIcon(
                                          Icons.check_circle_rounded,
                                          color: accentColor,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Text(
                                tr('سرعة التحدث:', 'Speech Speed:'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: subColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    _buildSpeedChip(0, tr('هادئ', 'Calm')),
                                    const SizedBox(width: 6),
                                    _buildSpeedChip(1, tr('طبيعي', 'Normal')),
                                    const SizedBox(width: 6),
                                    _buildSpeedChip(2, tr('سريع', 'Fast')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                          child: Column(
                            children: [
                              GlassTapButton(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                backgroundColor: const Color(0xFF087e76),
                                borderColor: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                onTap: _onTapSwitchVoiceButton,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const DliniiAppIcon(
                                      Icons.swap_horiz_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr(
                                        'تبديل الصوت (صوت فتاة ⇄ صوت رجل)',
                                        'Switch Voice (Female ⇄ Male)',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GlassTapButton(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                backgroundColor:
                                    _pinnedSlot.containsKey(currentVoice.id)
                                    ? const Color(0xFFefbb52)
                                    : landColor,
                                borderColor: const Color(0xFFefbb52),
                                borderRadius: BorderRadius.circular(12),
                                onTap: _togglePinCurrentVoice,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    DliniiAppIcon(
                                      Icons.push_pin_rounded,
                                      color:
                                          _pinnedSlot.containsKey(
                                            currentVoice.id,
                                          )
                                          ? const Color(0xFF142e2d)
                                          : const Color(0xFFefbb52),
                                      size: 17,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _pinnedSlot.containsKey(currentVoice.id)
                                          ? tr(
                                              'هذا الصوت مثبّت حالياً (اضغط لإلغاء التثبيت)',
                                              'Voice Pinned (Tap to Unpin)',
                                            )
                                          : tr(
                                              'تثبيت هذا الصوت كافتراضي دائماً 📌',
                                              'Pin This Voice Permanently 📌',
                                            ),
                                      style: TextStyle(
                                        color:
                                            _pinnedSlot.containsKey(
                                              currentVoice.id,
                                            )
                                            ? const Color(0xFF142e2d)
                                            : textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
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
                ),
              ),
            ),
          if (showModalBox)
            GestureDetector(
              onTap: () => setState(() => showModalBox = false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(18),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 395,
                      maxHeight: 540,
                    ),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: lineColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF142e2d), Color(0xFF087e76)],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    DliniiAppIcon(
                                      modalHeaderIcon,
                                      color: const Color(0xFFefbb52),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        modalTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => showModalBox = false),
                                child: const DliniiAppIcon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(14),
                            children: modalSections
                                .map(
                                  (sec) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: landColor,
                                      border: Border.all(color: lineColor),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sec['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: accentColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          sec['body'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: subColor,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showRateModal)
            Container(
              color: Colors.black.withOpacity(0.55),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: lineColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DliniiAppIcon(
                      Icons.stars_rounded,
                      color: Color(0xFFefbb52),
                      size: 44,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('تقييم تطبيق دلّيني', 'Rate Dlinii App'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tr(
                        'شلون كانت تجربتك ويا تطبيق دلّيني؟ اضغط على النجوم لتقييمنا على المتجر:',
                        'How was your experience with Dlinii? Tap stars to rate us:',
                      ),
                      style: TextStyle(fontSize: 12, color: subColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final int val = index + 1;
                        final bool isActive = val <= selectedStars;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedStars = val);
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                launchUrl(Uri.parse(playStoreUrl));
                                if (mounted) {
                                  setState(() => showRateModal = false);
                                }
                              },
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFefbb52).withOpacity(0.18)
                                  : landColor,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: DliniiAppIcon(
                              Icons.star_rounded,
                              size: 26,
                              color: isActive
                                  ? const Color(0xFFefbb52)
                                  : const Color(0xFFcbd5e1),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GlassTapButton(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: const Color(0xFF087e76),
                            borderColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            onTap: () {
                              launchUrl(Uri.parse(playStoreUrl));
                              setState(() => showRateModal = false);
                            },
                            child: Text(
                              tr('تقييم بالمتجر', 'Rate on Store'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GlassTapButton(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: landColor,
                            borderColor: lineColor,
                            borderRadius: BorderRadius.circular(11),
                            onTap: () => setState(() => showRateModal = false),
                            child: Text(
                              tr('إغلاق', 'Close'),
                              style: TextStyle(
                                color: subColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (showNotifPermissionModal) _permissionPanel(),
          if (isToastVisible)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              left: 30,
              right: 30,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142e2d).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF7ce0be).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      toastMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildSpeedChip(int level, String label) {
    final bool active = voiceSpeedLevel == level;
    return Expanded(
      child: GlassTapButton(
        padding: const EdgeInsets.symmetric(vertical: 7),
        backgroundColor: active ? accentColor : landColor,
        borderColor: active ? accentColor : lineColor,
        borderRadius: BorderRadius.circular(9),
        onTap: () => _setVoiceSpeedLevel(level),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  Widget _placeAction(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool primary = false,
  }) => GlassTapButton(
    height: 44,
    onTap: onTap,
    backgroundColor: primary
        ? (isDark ? const Color(0xFF28B9AD) : const Color(0xFF118F8C))
        : (isDark ? const Color(0xFF203136) : const Color(0xFFEAF4F2)),
    borderColor: primary
        ? Colors.transparent
        : accentColor.withValues(alpha: .18),
    borderRadius: DliniiBrand.cardShape,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DliniiAppIcon(
          icon,
          size: 19,
          color: primary ? Colors.white : accentColor,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primary ? Colors.white : accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _compactSearchAction(
    String kind,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 38,
          height: 42,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFF16E82)
                    : accentColor.withValues(alpha: isDark ? .13 : .09),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: active
                      ? const Color(0xFFFFAFBC)
                      : accentColor.withValues(alpha: .18),
                ),
              ),
              child: DliniiControlIcon(
                kind,
                size: 16,
                color: active ? Colors.white : accentColor,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _pasteLocation() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = clipboard?.text?.trim() ?? '';
    if (text.isEmpty) {
      _toast(tr('انسخ رابط موقع أولاً', 'Copy a location link first'));
      return;
    }
    if (!_parseAndOpenSharedText(text))
      await _resolveMapLink(Uri.tryParse(text) ?? Uri());
  }

  Widget _buildRepGridBtn(String type, String label) => DliniiReportTile(
    type: type,
    label: label,
    dark: isDark,
    onTap: () => _submitCloudReport(type, label),
  );
}
