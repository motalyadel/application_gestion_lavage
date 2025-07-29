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
          _error =
              'Impossible de récupérer les informations de l\'utilisateur.';
        });
        return;
      }

      AuthController().redirect();
    } catch (e) {
      setState(() {
        if (e.toString().contains('Email not confirmed')) {
          _error =
              'Veuillez confirmer votre adresse e-mail pour vous connecter.';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.primary),
            onPressed: () {
              final provider =
                  Provider.of<LocaleProvider>(context, listen: false);
              final currentLocale = provider.locale;
              final newLocale = currentLocale.languageCode == 'en'
                  ? const Locale('fr')
                  : const Locale('en');
              provider.changeLocale(newLocale);
            },
            tooltip: 'Changer la langue',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 400 : 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo ou icône
                      const Icon(Icons.local_car_wash,
                          size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),

                      // Titre principal
                      Text(
                        "Connexion",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        validator: (value) =>
                            value != null && value.contains('@')
                                ? null
                                : 'Email invalide',
                      ),
                      const SizedBox(height: 20),

                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : 'Mot de passe trop court',
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Bouton de connexion
                      SizedBox(
                        height: 50,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _login,
                                child: Text("Se connecter",
                                    style: theme.textTheme.titleMedium!
                                        .copyWith(color: Colors.white)),
                              ),
                      ),

                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // Ajouter une navigation vers un écran "mot de passe oublié" ?
                        },
                        child: const Text(
                          "Mot de passe oublié ?",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () =>
                            AppNavigator.pushReplacement('/signup'),
                        child: const Text("Vous avez pas un compte ? signUp"),
                      ),
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
