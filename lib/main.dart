import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'home_screen.dart';
import 'firebase_bootstrap.dart';

import 'package:flutter/services.dart';

import 'dlinii_brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final font = FontLoader('Tajawal')
    ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
  await font.load();
  await initializeDliniiFirebase();

  if (!kIsWeb) {
    // 1. تفعيل سجل الفحص لمعرفة حالة الاتصال بالترمنال
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // 2. تهيئة ون سجنل بمعرف التطبيق الخاص بك
    OneSignal.initialize("6499f5ad-5514-4560-bc2c-39d2356c044a");

    // 3. انتظار موافقة المستخدم على إذن الإشعارات
    // Request notifications from an explicit user action, after first frame.

    // 4. إجبار الإشعار على الظهور من الأعلى حتى لو كان التطبيق مفتوحاً على الشاشة
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // 5. طباعة معرف الجهاز في الترمنال بمجرد تسجيله للتأكد من الربط
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint("OneSignal Subscription ID: ${state.current.id}");
      debugPrint("OneSignal OptedIn: ${state.current.optedIn}");
    });
  }

  runApp(const DliniiApp());
}

class DliniiApp extends StatelessWidget {
  const DliniiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '\u062F\u0644\u0651\u064A\u0646\u064A | Dlinii',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Tajawal',
        fontFamilyFallback: const ['Cairo'],
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DliniiBrand.teal,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.standard,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(borderRadius: DliniiBrand.cardShape),
            textStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(space: 24, thickness: 1),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
