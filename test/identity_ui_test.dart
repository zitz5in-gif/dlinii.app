import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/dlinii_brand.dart';
import '../lib/place_design.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Tajawal')..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    await loader.load();
  });
  for (final english in [false, true]) {
    testWidgets('menu occupies physical right edge in ${english ? "English" : "Arabic"}', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey<ScaffoldState>();
      var invoked = false;
      final menu = DliniiSideMenu(dark: true, english: english,
        onClose: () { if (english) { key.currentState!.closeEndDrawer(); } else { key.currentState!.closeDrawer(); } },
        entries: [
          DliniiMenuEntry(label: english ? 'My places' : 'أماكني ورحلاتي', icon: const DliniiSymbol('pin', color: DliniiBrand.glow), onTap: () => invoked = true),
          DliniiMenuEntry(label: english ? 'Guide a friend' : 'دلّي صديق', detail: english ? 'Your destination. Dlinii directions.' : 'مكان منك… والطريق من دلّيني', icon: const DliniiSymbol('target', color: DliniiBrand.glow), onTap: () {}),
          DliniiMenuEntry(label: english ? 'Saved maps' : 'خرائطي المحفوظة', icon: const DliniiSymbol('bank', color: DliniiBrand.glow), onTap: () {}),
        ]);
      await tester.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'Tajawal'), home: Directionality(
        textDirection: english ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(key: key, drawer: english ? null : menu, endDrawer: english ? menu : null, body: const SizedBox()))));
      if (english) { key.currentState!.openEndDrawer(); } else { key.currentState!.openDrawer(); }
      await tester.pumpAndSettle();
      await tester.runAsync(() => precacheImage(const AssetImage('assets/images/dlinii_icon.png'), tester.element(find.byType(Scaffold))));
      await tester.pumpAndSettle();
      expect(tester.getTopRight(find.byType(Drawer)).dx, closeTo(390, .1));
      expect(tester.getTopLeft(find.byType(Drawer)).dx, greaterThan(0));
      await tester.tap(find.text(english ? 'My places' : 'أماكني ورحلاتي'));
      expect(invoked, isTrue);
      expect(tester.takeException(), isNull);
      if (!english) await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/dlinii-side-menu.png'));
    });
  }

  testWidgets('branded report and explore cards render at phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    const types = {'bump':'مطب', 'pothole':'حفرة', 'crash':'حادث', 'traffic':'ازدحام', 'police':'نقطة مرور', 'hazard':'خطر آخر', 'roadworks':'حفريات', 'closed':'طريق مغلق', 'camera':'كاميرا سرعة'};
    await tester.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'Tajawal'), home: Directionality(textDirection: TextDirection.rtl,
      child: Scaffold(backgroundColor: const Color(0xFF071E25), body: SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [
        const DliniiBrandHeader(compact: true),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: DliniiExploreTile(dark: true, label: 'مطاعم', hint: 'اعرض الأقرب', icon: const DliniiPlaceBadge('restaurant', size: 38), onTap: () => taps++)),
          const SizedBox(width: 10), Expanded(child: DliniiExploreTile(dark: true, label: 'وقود', hint: 'اعرض الأقرب', icon: const DliniiPlaceBadge('fuel', size: 38), onTap: () {}))]),
        const SizedBox(height: 24),
        const Align(alignment: Alignment.centerRight, child: Text('خلّي الطريق أوضح', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55,
          children: [for (final entry in types.entries) DliniiReportTile(type: entry.key, label: entry.value, dark: true, onTap: () => taps++)]),
      ]))))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مطاعم')); await tester.tap(find.text('مطب'));
    expect(taps, 2);
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/dlinii-cards.png'));
  });
}
