import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/washops_header.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<void> redirect() async {
    await Future.delayed(const Duration(seconds: 3));
    await AuthController().redirect();
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    redirect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WashTheme.navy,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône logo dans un carré arrondi semi-transparent
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.local_car_wash,
                        size: 46, color: Colors.white),
                  ),
                  const SizedBox(height: 28),

                  // ✅ AJOUT : "WashOps" blanc + "Pro" en bleu clair, comme le design
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'WashOps ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Pro',
                          style: TextStyle(color: Color(0xFF93B5F2)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ENTERPRISE MANAGEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 3,
                      color: Colors.white.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),

                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'INITIALIZING SYSTEMS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: Colors.white.withOpacity(0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ✅ AJOUT : footer "vX.X.X" décoratif, en bas de l'écran
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}