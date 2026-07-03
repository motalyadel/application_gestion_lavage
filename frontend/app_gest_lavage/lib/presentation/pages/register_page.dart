import 'package:app_gest_lavage/core/utils/navigator.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/presentation/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/washops_header.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactController = TextEditingController();
  final ClientService _authService = ClientService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _authService.registerAndConfirmClient(
        name: _nameController.text.trim(),
        contact: _contactController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        start_date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      if (success) {
        AppNavigator.pushReplacement('/login');
      } else {
        setState(() => _error = "Erreur lors de l'inscription.");
      }
    } catch (e) {
      setState(() => _error = "Erreur : ${e.toString()}");
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 420 : 500),
                  child: Container(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'WashOps Pro',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: WashTheme.navy,
                                ),
                              ),
                              _buildLanguageToggle(context),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: WashTheme.chipBlueBg,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.person_add_alt_1,
                                  size: 28, color: WashTheme.chipBlueText),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Créer un compte',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: WashTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Rejoignez l'élite du lavage automobile intelligent.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: WashTheme.textSecondary),
                          ),
                          const SizedBox(height: 26),
                          _buildLabel('Nom Complet'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            decoration: _fieldDecoration(
                              hint: 'Jean Dupont',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) =>
                                value != null && value.trim().length >= 3
                                    ? null
                                    : 'Nom invalide',
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Contact'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _contactController,
                            keyboardType: TextInputType.phone,
                            decoration: _fieldDecoration(
                              hint: '+222 00 00 00 00',
                              icon: Icons.phone_outlined,
                            ),
                            validator: (value) =>
                                value != null && value.trim().length >= 6
                                    ? null
                                    : 'Numéro invalide',
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Email'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _fieldDecoration(
                              hint: 'jean.dupont@exemple.com',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) =>
                                value != null && value.contains('@')
                                    ? null
                                    : 'Email invalide',
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Mot de passe'),
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
                          const SizedBox(height: 16),
                          _buildLabel('Confirmation'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: _fieldDecoration(
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 19,
                                  color: WashTheme.textSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (value) =>
                                value == _passwordController.text
                                    ? null
                                    : 'Les mots de passe ne correspondent pas',
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
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: WashTheme.navy,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      "S'inscrire",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                const Text(
                                  'Vous avez déjà un compte ? ',
                                  style: TextStyle(
                                      color: WashTheme.textSecondary,
                                      fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      AppNavigator.pushReplacement('/login'),
                                  child: const Text(
                                    'Se connecter',
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
          color: WashTheme.chipGrayBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 15, color: WashTheme.navy),
            const SizedBox(width: 5),
            Text(
              isFr ? 'FR' : 'EN',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: WashTheme.navy),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 15, color: WashTheme.navy),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
