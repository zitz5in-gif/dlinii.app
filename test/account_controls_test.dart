import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dlinii_app/account_sheet.dart';
import 'package:dlinii_app/delete_account_dialog.dart';

void main() {
  testWidgets('guest closes sign in without authenticating', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      Scaffold(body: TextButton(onPressed: () async {
        result = await showModalBottomSheet<bool>(context: context,
          isScrollControlled: true, builder: (_) => const DliniiAccountSheet(english: true));
      }, child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(result, false);
    expect(find.text('Welcome back'), findsNothing);
  });
  testWidgets('account deletion requires password and allows cancellation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: DeleteAccountDialog(english: true))));
    final button = find.widgetWithText(FilledButton, 'Delete permanently');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'example-password');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
