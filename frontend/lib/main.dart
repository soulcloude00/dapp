import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/services/admin_service.dart';
import 'package:propfi/services/notification_service.dart';
import 'package:propfi/services/hydra_service.dart';
import 'package:propfi/features/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => HydraService()),
      ],
      child: MaterialApp(
        title: 'Crestadel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashPage(),
      ),
    );
  }
}
