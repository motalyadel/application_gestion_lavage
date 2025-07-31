import 'package:app_gest_lavage/core/utils/navigator.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:app_gest_lavage/l10n/generated/app_localizations.dart';
import 'package:app_gest_lavage/presentation/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
        // photoUrl: null,
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Inscription", style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.blue),
            onPressed: () {
              final provider =
                  Provider.of<LocaleProvider>(context, listen: false);
              final current = provider.locale;
              final newLocale = current.languageCode == 'en'
                  ? const Locale('fr')
                  : const Locale('en');
              provider.changeLocale(newLocale);
            },
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
                    children: [
                      const Icon(Icons.person_add,
                          size: 64, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        "Créer un compte",
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value != null && value.trim().length >= 3
                                ? null
                                : "Nom invalide",
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value != null && value.trim().length >= 6
                                ? null
                                : "Numéro invalide",
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value != null && value.contains('@')
                                ? null
                                : 'Email invalide',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : 'Mot de passe trop court',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == _passwordController.text
                            ? null
                            : 'Les mots de passe ne correspondent pas',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "S'inscrire",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => AppNavigator.pushReplacement('/login'),
                        child: const Text(
                            "Vous avez déjà un compte ? Se connecter"),
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
