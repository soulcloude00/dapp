import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/features/auth/setup_profile_page.dart';
import 'package:propfi/features/home/main_layout.dart';
import 'package:propfi/services/wallet_service.dart';
import 'dart:ui';

class AuthLandingPage extends StatefulWidget {
  const AuthLandingPage({super.key});

  @override
  State<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage> {
  List<CardanoWallet> _availableWallets = [];

  /// Show wallet selector dialog
  /// Works on web browsers (desktop Chrome, mobile wallet dApp browsers)
  Future<void> _showConnectWalletDialog() async {
    final walletService = context.read<WalletService>();
    _availableWallets = await walletService.detectWallets();

    if (!mounted) return;

    if (_availableWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No Cardano wallets detected. Please install a wallet extension or open this page in your wallet\'s dApp browser.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      // Demo mode fallback for testing
      _connectWallet(CardanoWallet.nami);
      return;
    }

    await showModalBottomSheet<CardanoWallet>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect Wallet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a wallet to connect',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ..._availableWallets.map(
              (wallet) => ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                ),
                title: Text(
                  wallet.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _connectWallet(wallet);
                },
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.cyan),
              title: const Text(
                'Mobile Wallet (P2P)',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Connect via CIP-45 (Vespr, Eternl)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _connectMobileWallet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectMobileWallet() async {
    final walletService = context.read<WalletService>();
    final qrData = await walletService.connectMobileWallet();

    if (!mounted) return;

    if (qrData != null) {
      // Start waiting for connection in background
      final connectionFuture = walletService.waitForMobileConnection();
      bool dialogOpen = true;

      // Show QR Code Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A0B2E),
          title: const Text(
            'Scan to Connect',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(qrData)}',
                  width: 200,
                  height: 200,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan with your mobile wallet (Vespr, Eternl) to connect.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ).then((_) => dialogOpen = false);

      // Wait for connection to complete
      final success = await connectionFuture;

      if (!mounted) return;

      if (success) {
        // Close dialog if still open
        if (dialogOpen) {
          Navigator.of(context).pop();
        }

        // Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize Peer Connect'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _connectWallet(CardanoWallet wallet) async {
    final walletService = context.read<WalletService>();
    final success = await walletService.connectWallet(wallet);

    if (!mounted) return;

    if (success) {
      await walletService.completeLogin();
      if (!mounted) return;
      // Navigate to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${walletService.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image/Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF1A0B2E),
                  Color(0xFF050505),
                ],
              ),
            ),
          ),

          // Glass Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo/Brand - Crestadel Crown
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.2),
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Text('🏰', style: TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: 32),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFD4AF37),
                        Color(0xFFFFD700),
                        Color(0xFFD4AF37),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Welcome to\nCrestadel',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acquire the World, Define Your Portfolio',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The royal court of decentralized real estate. Join the crypto nobility today.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[400],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Buttons
                  _buildButton(
                    context,
                    'CONNECT WALLET',
                    Icons.account_balance_wallet,
                    AppTheme.primaryColor,
                    Colors.black,
                    _showConnectWalletDialog,
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    context,
                    'JOIN THE REALM',
                    Icons.person_add,
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SetupProfilePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed:
                          _showConnectWalletDialog, // Login also triggers wallet connect
                      child: Text(
                        'Already have an account? Login',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: bgColor == AppTheme.primaryColor
                ? BorderSide.none
                : BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          elevation: bgColor == AppTheme.primaryColor ? 10 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
