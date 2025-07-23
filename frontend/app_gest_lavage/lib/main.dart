import 'package:app_gest_lavage/core/utils/navigator.dart';
import 'package:app_gest_lavage/l10n/generated/app_localizations.dart';
import 'package:app_gest_lavage/presentation/pages/home_page.dart';
import 'package:app_gest_lavage/presentation/pages/login_page.dart';
import 'package:app_gest_lavage/presentation/pages/splash_screen.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://uccmvdjhmpcmfjjygwgo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjY212ZGpobXBjbWZqanlnd2dvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzNDc2MzMsImV4cCI6MjA2NzkyMzYzM30.7xbpDdDSV2uCdXxx6QSZA01kUHD1hl9YFtrJjbfPKv4',
  );

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider.value(value: AuthController()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(builder: (context, localeProvider, child) {
      return MaterialApp(
        title: 'Gestion LAVAGE',
        debugShowCheckedModeBanner: false,
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        locale: localeProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorKey: AppNavigator.globalKey,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          // '/register': (_) => const RegisterPage(),
          '/home': (_) => const HomePage(),
        },
      );
    });
  }
}
