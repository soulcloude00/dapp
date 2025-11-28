import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/features/auth/onboarding_page.dart';
import 'package:propfi/features/home/main_layout.dart';
import 'package:propfi/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Simulate splash delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final walletService = Provider.of<WalletService>(context, listen: false);
    // In a real app, we would check if a wallet is connected or token exists.
    // For now, we check if a username is saved in WalletService (which loads from prefs).
    // Note: WalletService loads profile in its constructor or we need to await it.

    // Since WalletService loads profile async in constructor (fire and forget),
    // we might need to verify if it's loaded.
    // For this MVP, let's assume if userName is not empty/default, they are "logged in".
    // But WalletService starts with empty strings.

    // Let's rely on SharedPreferences directly here or add a method in WalletService.
    // Actually, WalletService loads it. Let's wait a bit more or check prefs directly.

    // Better approach: Check if "userName" key exists in SharedPreferences.
    // But to keep it simple and use the service:

    // Check if user has completed onboarding/login
    if (walletService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF1A1A2E),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Crown/Castle Logo
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                      AppTheme.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 60,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
                  ).createShader(bounds),
                  child: const Text(
                    '🏰',
                    style: TextStyle(fontSize: 56),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Crestadel Logo Text
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFE8D5B7), Color(0xFFD4AF37)],
                ).createShader(bounds),
                child: const Text(
                  'CRESTADEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              Text(
                'Acquire the World, Define Your Portfolio',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Crypto', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(' • ', style: TextStyle(color: Colors.grey[600])),
                  Text('Estate', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(' • ', style: TextStyle(color: Colors.grey[600])),
                  Text('Delicacy', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 56),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
