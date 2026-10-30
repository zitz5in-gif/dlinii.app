import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dlinii_brand.dart';

const dliniiPlaceCategories = <String, List<String>>{
  'restaurant': ['مطعم', 'Restaurant', '🍽️'],
  'fast_food': ['وجبات سريعة', 'Fast food', '🍔'],
  'cafe': ['مقهى', 'Cafe', '☕'],
  'bakery': ['مخبز', 'Bakery', '🥐'],
  'sweets': ['حلويات', 'Sweets', '🍰'],
  'juice': ['عصائر', 'Juice bar', '🧃'],
  'supermarket': ['سوبرماركت', 'Supermarket', '🛒'],
  'grocery': ['بقالة', 'Grocery', '🥑'],
  'mall': ['مول', 'Mall', '🏬'],
  'shopping': ['تسوق', 'Shopping', '🛍️'],
  'clothes': ['ملابس', 'Clothing', '👕'],
  'electronics': ['إلكترونيات', 'Electronics', '🎧'],
  'pharmacy': ['صيدلية', 'Pharmacy', '💊'],
  'hospital': ['مركز صحي', 'Healthcare', '🩺'],
  'fuel': ['محطة وقود', 'Fuel station', '⛽'],
  'hotel': ['فندق', 'Hotel', '🛎️'],
  'school': ['تعليم', 'Education', '🎓'],
  'park': ['حديقة', 'Park', '🌿'],
  'gym': ['رياضة', 'Fitness', '🏋️'],
  'car_service': ['خدمات سيارات', 'Car service', '🛞'],
  "clinic": ["عيادة", "Clinic", "🩺"],
  "dentist": ["طبيب أسنان", "Dentist", "🦷"],
  "laboratory": ["مختبر", "Laboratory", "🧪"],
  "charging": ["شحن كهربائي", "EV charging", "🔋"],
  "car_wash": ["غسيل سيارات", "Car wash", "🚿"],
  "bank": ["بنك", "Bank", "🏦"],
  "atm": ["صراف آلي", "ATM", "💳"],
  "bus": ["محطة باصات", "Bus station", "🚌"],
  "taxi": ["تكسي", "Taxi", "🚕"],
  "parking": ["موقف سيارات", "Parking", "🅿️"],
  "stadium": ["ملعب", "Stadium", "🏟️"],
  "guesthouse": ["دار ضيافة", "Guesthouse", "🛏️"],
  "tourism": ["معلم سياحي", "Attraction", "📷"],
  "museum": ["متحف", "Museum", "🏛️"],
  "landmark": ["معلم", "Landmark", "📍"],
  "government": ["دائرة حكومية", "Government office", "🏛️"],
  "police_station": ["مركز شرطة", "Police station", "🛡️"],
  "post": ["بريد", "Post office", "📮"],
  "lawyer": ["محامي", "Lawyer", "⚖️"],
  "accountant": ["محاسب", "Accountant", "🧮"],
  "engineering": ["مكتب هندسي", "Engineering office", "📐"],
  "consulting": ["استشارات", "Consulting", "💼"],
  "translation": ["ترجمة", "Translation", "🌐"],
  "printing": ["طباعة", "Printing", "🖨️"],
  "contractor": ["شركة مقاولات", "Contractor", "🏗️"],
  "builder": ["أستاذ بناء", "Builder", "🧱"],
  "decor": ["ديكور", "Decor", "🎨"],
  "building_materials": ["مواد بناء", "Building materials", "🧱"],
  "ac": ["تكييف", "Air conditioning", "❄️"],
  "electrician": ["كهربائي", "Electrician", "⚡"],
  "plumber": ["سباك", "Plumber", "🔧"],
  "carpenter": ["نجار", "Carpenter", "🪚"],
  "appliance": ["صيانة أجهزة", "Appliance repair", "🛠️"],
  "cleaning": ["تنظيف", "Cleaning", "🧹"],
  "barber": ["حلاقة", "Barber", "✂️"],
  "beauty": ["كوزمتك", "Beauty", "💄"],
  "tailor": ["خياطة", "Tailor", "🧵"],
  "laundry": ["غسيل ومكوى", "Laundry", "🧺"],
  "mobile": ["صيانة موبايلات", "Phone repair", "📱"],
  "software": ["برمجيات", "Software", "💻"],
  "internet": ["شبكات وإنترنت", "Internet & networks", "🌐"],
  "mosque": ["مسجد", "Mosque", "🕌"],
  'other': ['مكان آخر', 'Other place', '📍'],
};

class DliniiReportIcon extends StatelessWidget {
  final String type;
  final double size;
  const DliniiReportIcon(this.type, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => DliniiIncidentArt(type, size: size);
}

class DliniiSymbol extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const DliniiSymbol(
    this.name, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });
  static const shapes = {
    'food': '<path d="M5 3v7m4-7v7M7 10v11M4 3v5a3 3 0 0 0 6 0V3m9 0c-4 5-4 9 0 9V3zm0 9v9"/>',
    'cafe': '<path d="M4 7h13v7a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5V7zm13 1h2a3 3 0 0 1 0 6h-2M3 22h16M7 2v2m5-2v2"/>',
    'shop': '<path d="M4 8h16l-1 13H5L4 8zm4 0V6a4 4 0 0 1 8 0v2"/>',
    'health': '<rect x="3" y="6" width="18" height="15" rx="4"/><path d="M8 6V3h8v3m-4 5v6m-3-3h6"/>',
    'car': '<path d="m4 10 2-6h12l2 6M3 10h18v9H3v-9zm3 5h2m8 0h2M5 19v2m14-2v2"/>',
    'fuel': '<path d="M4 21V3h10v18M2 21h14M6 6h6v5H6zm8 8h3v4a2 2 0 0 0 4 0V8l-3-3"/>',
    'bank': '<path d="m2 7 10-5 10 5H2zm2 14h16M6 10v8m6-8v8m6-8v8"/>',
    'park': '<path d="M12 21v-8m0 3-4-4m4 2 4-4"/><path d="M7 16a5 5 0 0 1-2-9 7 7 0 0 1 14 0 5 5 0 0 1-2 9"/>',
    'hotel':
        '<path d="M3 21V6m18 15V9M3 17h18M3 10h7v7m0-6h8a3 3 0 0 1 3 3v3"/>',
    'camera':
        '<path d="M3 7h4l2-3h6l2 3h4v14H3V7z"/><circle cx="12" cy="14" r="4"/>',
    'tools': '<path d="m14 4 3 3 4-4a6 6 0 0 1-7 8l-8 9a2 2 0 0 1-3-3l9-8a6 6 0 0 1 2-5z"/>',
    'tech': '<rect x="3" y="3" width="18" height="14" rx="2"/><path d="M12 17v4m-4 0h8M8 8l-2 2 2 2m8-4 2 2-2 2"/>',
    'pin': '<path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 0 1 14 0z"/><circle cx="12" cy="10" r="2"/>',
    'target': '<circle cx="12" cy="12" r="7"/><path d="M12 1v5m0 12v5M1 12h5m12 0h5"/>',
    'down': '<path d="m6 9 6 6 6-6"/>',
    'plus': '<path d="M12 4v16M4 12h16"/>',
  };
  @override
  Widget build(BuildContext context) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><g fill="none" stroke="#' +
          hex +
          '" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' +
          (shapes[name] ?? shapes['pin']!) +
          '</g></svg>',
      width: size,
      height: size,
    );
  }
}

class DliniiPlaceBadge extends StatelessWidget {
  final String category;
  final double size;
  const DliniiPlaceBadge(this.category, {super.key, this.size = 42});
  String get group {
    if (['restaurant', 'fast_food'].contains(category)) return 'food';
    if (['cafe', 'bakery', 'sweets', 'juice'].contains(category)) return 'cafe';
    if ([
      'supermarket',
      'grocery',
      'mall',
      'shopping',
      'clothes',
      'electronics',
      'barber',
      'beauty',
      'tailor',
      'laundry',
    ].contains(category))
      return 'shop';
    if ([
      'pharmacy',
      'hospital',
      'clinic',
      'dentist',
      'laboratory',
    ].contains(category))
      return 'health';
    if ([
      'car_service',
      'car_wash',
      'charging',
      'bus',
      'taxi',
      'parking',
    ].contains(category))
      return 'car';
    if (category == 'fuel') return 'fuel';
    if ([
      'bank',
      'atm',
      'government',
      'police_station',
      'post',
      'school',
      'lawyer',
      'accountant',
      'engineering',
      'consulting',
      'translation',
    ].contains(category))
      return 'bank';
    if (['park', 'gym', 'stadium'].contains(category)) return 'park';
    if (['hotel', 'guesthouse'].contains(category)) return 'hotel';
    if (['tourism', 'museum', 'landmark'].contains(category)) return 'camera';
    if (['mobile', 'software', 'internet', 'printing'].contains(category))
      return 'tech';
    if ([
      'contractor',
      'builder',
      'decor',
      'building_materials',
      'ac',
      'electrician',
      'plumber',
      'carpenter',
      'appliance',
      'cleaning',
    ].contains(category))
      return 'tools';
    return 'pin';
  }

  @override
  Widget build(BuildContext context) {
    const colors = {
      'food': Color(0xFFF18639),
      'cafe': Color(0xFFAF733D),
      'shop': Color(0xFF527E9D),
      'health': Color(0xFFC6676B),
      'car': Color(0xFF428CBD),
      'fuel': Color(0xFF288DA1),
      'bank': Color(0xFF647E9C),
      'park': Color(0xFF409C68),
      'hotel': Color(0xFFD95E91),
      'camera': Color(0xFF20A0B7),
      'tech': Color(0xFF487E8E),
      'tools': Color(0xFF3B9588),
      'pin': Color(0xFF087E76),
    };
    final tint = colors[group]!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(tint, Colors.white, .18)!, tint],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * .35),
          topRight: Radius.circular(size * .18),
          bottomLeft: Radius.circular(size * .18),
          bottomRight: Radius.circular(size * .35),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: .15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DliniiSymbol(group, size: size * .56),
    );
  }
}
