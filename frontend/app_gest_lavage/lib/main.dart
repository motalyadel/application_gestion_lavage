import 'package:app_gest_lavage/core/utils/app_massenger.dart';
import 'package:app_gest_lavage/core/utils/navigator.dart';
import 'package:app_gest_lavage/l10n/generated/app_localizations.dart';
import 'package:app_gest_lavage/presentation/pages/admin/admin_home_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/admin_reservations_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/admin_services_page.dart';
import 'package:app_gest_lavage/presentation/pages/admin/manage_users_page.dart';
import 'package:app_gest_lavage/presentation/pages/cars/cars_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/client_detail_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/client_home_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/client_reservations_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/client_services_page.dart';
import 'package:app_gest_lavage/presentation/pages/client/profile_page.dart';
import 'package:app_gest_lavage/presentation/pages/create_reservation_page.dart';
import 'package:app_gest_lavage/presentation/pages/login_page.dart';
import 'package:app_gest_lavage/presentation/pages/register_page.dart';
import 'package:app_gest_lavage/presentation/pages/splash_screen.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:app_gest_lavage/presentation/providers/client_management_controller.dart';
import 'package:app_gest_lavage/presentation/providers/create_reservation_provider.dart';
import 'package:app_gest_lavage/presentation/providers/locale_provider.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:app_gest_lavage/presentation/providers/service_management_controller.dart';
import 'package:app_gest_lavage/presentation/providers/update_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    // url: 'https://yassmpfkbvpiewxviwys.supabase.co',
    url: dotenv.env["SUPABASE_URL"]!,
    anonKey:
        // 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlhc3NtcGZrYnZwaWV3eHZpd3lzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2Mjc2MDEsImV4cCI6MjA5MjIwMzYwMX0.-cgtIb6iE1WGL9uzBligEd2uaJSihxAysyI0irgvPi8',
        dotenv.env["SUPABASE_ANON_KEY"]!,
  );

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider(create: (_) => ClientManagementController()),
    ChangeNotifierProvider(create: (_) => CarManagementController()),
    ChangeNotifierProvider(create: (_) => ClientUpdateController()),
    ChangeNotifierProvider(create: (_) => ServiceManagementController()),
    ChangeNotifierProvider(create: (_) => ReservationManagementController()),
    ChangeNotifierProvider(create: (_) => CreateReservationProvider()),
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
        scaffoldMessengerKey: AppMessenger.messengerKey,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const RegisterPage(),
          '/admin_home': (_) => const AdminHomePage(),
          '/client_home': (_) => const ClientHomePage(),
          '/manage_users': (_) => const ManageUsersPage(),
          '/client_detail': (_) => const ClientDetailPage(),
          '/admin/services': (context) => const AdminServicesPage(),
          '/client/services': (context) => const ClientServicesPage(),
          '/admin/reservations': (context) => const AdminReservationsPage(),
          '/client/reservations': (context) => const ClientReservationsPage(),
          '/cars': (_) => const CarsPage(),
          '/create-reservation': (context) => const CreateReservationPage(),
          '/profile': (context) => const ProfilePage(),
        },
      );
    });
  }
}
