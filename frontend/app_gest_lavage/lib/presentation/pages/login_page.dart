// import 'dart:convert';

import 'package:app_gest_lavage/core/utils/navigator.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/l10n/generated/app_localizations.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 25, 118, 210);
  static const Color primaryDark = Color.fromARGB(255, 13, 71, 161);
  static const Color primaryLight = Color.fromARGB(255, 187, 222, 251);
  static const Color secondary = Color.fromARGB(255, 67, 160, 71);
  static const Color accent = Color.fromARGB(255, 251, 140, 0);
  static const Color error = Color.fromARGB(255, 229, 57, 53);
  static const Color background = Color.fromARGB(255, 245, 245, 245);
  static const Color surface = Color.fromARGB(255, 255, 255, 255);
  static const Color textPrimary = Color.fromARGB(255, 33, 33, 33);
  static const Color textSecondary = Color.fromARGB(255, 117, 117, 117);
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
    final ClientService _authService = ClientService();


  // bool _passwordVisible = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      AppNavigator.pushReplacement('/home');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final authResponse = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('AuthResponse data: ${authResponse!.user}');

      if (authResponse.user == null) {
        setState(() {
          _error = 'Échec de la connexion : utilisateur non trouvé.';
        });
        return;
      }

      final user = await _authService.getUser();

      if (user == null) {
        setState(() {
          _error = 'Impossible de récupérer les informations de l\'utilisateur.';
        });
        return;
      }

      AuthController().redirect();
    } catch (e) {
      setState(() {
        if (e.toString().contains('Email not confirmed')) {
          _error = 'Veuillez confirmer votre adresse e-mail pour vous connecter.';
        } else if (e.toString().contains('Invalid login credentials')) {
          _error = 'E-mail ou mot de passe incorrect.';
        } else {
          _error = 'Erreur de connexion : ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.language,
                color: AppColors.primary,
              ),
              onPressed: () {
                final provider =
                    Provider.of<LocaleProvider>(context, listen: false);
                final currentLocale = provider.locale;
                final newLocale = currentLocale.languageCode == 'en'
                    ? const Locale('ar')
                    : const Locale('en');
                provider.changeLocale(newLocale);
              },
              tooltip: 'Change Language',
            ),
          ],
        ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 400 : 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text("Connexion", style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email),
                        validator: (value) => value != null && value.contains('@')
                            ? null
                            : 'Email invalide',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.password),
                        obscureText: true,
                        validator: (value) =>
                            value != null && value.length >= 6
                                ? null
                                : 'Mot de passe trop court',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login, child: Text("Se connecter")),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
