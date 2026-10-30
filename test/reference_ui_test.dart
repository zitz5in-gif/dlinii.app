import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/place_editor.dart';
import '../lib/place_category_picker.dart';
import '../lib/dlinii_motion.dart';

void main() {
  testWidgets('category picker fits narrow Arabic screen and returns choice', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () async {
        result = await showModalBottomSheet<String>(context: context, isScrollControlled: true,
          builder: (_) => const DliniiCategoryPicker(dark: true, english: false, selected: 'other'));
      }, child: const Text('open'))))));
    await tester.tap(find.text('open')); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'برمجيات'); await tester.pumpAndSettle();
    await tester.tap(find.text('برمجيات').last); await tester.pumpAndSettle();
    expect(result, 'software');
    expect(tester.takeException(), isNull);
  });

  testWidgets('place form preserves existing fields when selecting another map point', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () async {
        result = await showModalBottomSheet<Map<String, dynamic>>(context: context, isScrollControlled: true,
          builder: (_) => const DliniiPlaceEditor(latitude: 33.45, longitude: 43.26, dark: false, english: true,
            draft: {'id': 'saved-id', 'name': 'Palm Cafe', 'category': 'cafe', 'phone': '123', 'aliases': 'Palm', 'hoursMode': 'all_day'}));
      }, child: const Text('open'))))));
    await tester.tap(find.text('open')); await tester.pumpAndSettle();
    await tester.tap(find.text('Choose location on the map')); await tester.pumpAndSettle();
    expect(result?['_action'], 'pick');
    expect(result?['id'], 'saved-id');
    expect(result?['name'], 'Palm Cafe');
    expect(result?['aliases'], 'Palm');
    expect(result?['hoursMode'], 'all_day');
    expect(result?['hours'], 'Open 24 hours');
    expect(tester.takeException(), isNull);
  });

  testWidgets('D loader respects reduced motion and disposes its ticker', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(data: MediaQueryData(disableAnimations: true),
      child: Scaffold(body: DliniiLoader()))));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving waits for storage and blocks duplicate submissions', (tester) async {
    final pending = Completer<void>();
    var saves = 0;
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () async {
        result = await showModalBottomSheet<Map<String, dynamic>>(context: context, isScrollControlled: true,
          builder: (_) => DliniiPlaceEditor(latitude: 33.45, longitude: 43.26, dark: true, english: true,
            draft: const {'name': 'Home', 'category': 'other', 'shortcut': 'home'},
            onSave: (_) { saves++; return pending.future; }));
      }, child: const Text('open'))))));
    await tester.tap(find.text('open')); await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton)); await tester.pump();
    expect(find.byType(DliniiLoader), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(saves, 1);
    expect(result, isNull);
    pending.complete(); await tester.pumpAndSettle();
    expect(result?['_action'], 'saved');
    expect(result?['shortcut'], 'home');
    expect(tester.takeException(), isNull);
  });
}
