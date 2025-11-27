import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/features/landing/landing_page.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/services/admin_service.dart';

void main() {
  runApp(const PropFiApp());
}

class PropFiApp extends StatelessWidget {
  const PropFiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
      ],
      child: MaterialApp(
        title: 'PropFi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LandingPage(),
      ),
    );
  }
}
