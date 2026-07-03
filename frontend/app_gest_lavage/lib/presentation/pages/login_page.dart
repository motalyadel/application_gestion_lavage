import 'package:app_gest_lavage/core/utils/navigator.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/l10n/generated/app_localizations.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/washops_header.dart';

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

  bool _isLoading = false;
  bool _obscurePassword = true;
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

      if (authResponse!.user == null) {
        setState(() => _error = 'Échec de la connexion : utilisateur non trouvé.');
        return;
      }

      final user = await _authService.getUser();
      if (user == null) {
        setState(() =>
            _error = 'Impossible de récupérer les informations de l\'utilisateur.');
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 420 : 500),
                  child: Column(
                    children: [
                      // Sélecteur de langue
                      Align(
                        alignment: Alignment.topRight,
                        child: _buildLanguageToggle(context),
                      ),
                      const SizedBox(height: 12),

                      // Icône logo
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: WashTheme.navy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.local_car_wash,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: WashTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gérez votre centre WashOps Pro en toute simplicité',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: WashTheme.textSecondary),
                      ),
                      const SizedBox(height: 28),

                      // Carte formulaire
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: WashTheme.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel('EMAIL'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _fieldDecoration(
                                  hint: 'name@gmail.com',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) =>
                                    value != null && value.contains('@')
                                        ? null
                                        : 'Email invalide',
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel('MOT DE PASSE'),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: navigation "mot de passe oublié"
                                    },
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap),
                                    child: const Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: WashTheme.navy),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: _fieldDecoration(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 19,
                                      color: WashTheme.textSecondary,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) =>
                                    value != null && value.length >= 6
                                        ? null
                                        : 'Mot de passe trop court',
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],

                              const SizedBox(height: 22),
                              SizedBox(
                                height: 52,
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: WashTheme.navy))
                                    : ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: WashTheme.navy,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'SE CONNECTER',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward, size: 18),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 18),
                              const Divider(color: WashTheme.border),
                              const SizedBox(height: 14),
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    const Text(
                                      "Vous n'avez pas de compte ? ",
                                      style: TextStyle(
                                          color: WashTheme.textSecondary,
                                          fontSize: 14),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          AppNavigator.pushReplacement('/signup'),
                                      child: const Text(
                                        "S'inscrire",
                                        style: TextStyle(
                                          color: WashTheme.navy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '© 2026 WASHOPS PRO SYSTEM. TOUS DROITS RÉSERVÉS.',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: WashTheme.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final isFr = provider.locale.languageCode == 'fr';
    return GestureDetector(
      onTap: () {
        final newLocale = isFr ? const Locale('en') : const Locale('fr');
        provider.changeLocale(newLocale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WashTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WashTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16, color: WashTheme.navy),
            const SizedBox(width: 6),
            Text(
              isFr ? 'FR' : 'EN',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: WashTheme.navy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: WashTheme.textSecondary,
        ),
      );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: WashTheme.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, size: 19, color: WashTheme.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: WashTheme.chipGrayBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }
}