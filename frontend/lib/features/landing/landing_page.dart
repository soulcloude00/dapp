import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/features/marketplace/marketplace_page.dart';
import 'package:propfi/features/marketplace/widgets/property_card.dart';
import 'package:propfi/features/notifications/notifications_page.dart';
import 'package:propfi/features/analytics/analytics_page.dart';
import 'package:propfi/features/bonus/bonus_showcase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Fetch listings and refresh balance when home page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletService = context.read<WalletService>();
      walletService.fetchListings();
      // Refresh balance if connected
      if (walletService.isConnected) {
        walletService.refreshBalance();
      }
    });
  }

  Future<void> _refreshBalance() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      await context.read<WalletService>().refreshBalance();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletService>(context);
    final listings = walletService.listings;
    final featuredListings = listings
        .take(5)
        .toList(); // Take first 5 as featured

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF050505),
                  Color(0xFF1A0B2E),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            walletService.userName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Bonus Features button
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BonusFeaturesShowcase(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.emoji_events,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                          // Analytics button
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AnalyticsPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                            ),
                          ),
                          // Notifications button
                          NotificationBell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Profile avatar with logout menu
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await context.read<WalletService>().disconnectWallet();
                                if (context.mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                }
                              }
                            },
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: const Color(0xFF1a1a2e),
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'wallet',
                                enabled: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      walletService.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${walletService.balance.toStringAsFixed(2)} ₳',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Disconnect Wallet',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF1a1a2e),
                                child: Text('👑', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Portfolio Summary Card - Crestadel Royal Theme
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1a1a2e),
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Royal Treasury',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '🏰 CRESTADEL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Balance display with refresh
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
                                    ).createShader(bounds),
                                    child: Text(
                                      '\$${(walletService.balance * 0.35).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${walletService.balance.toStringAsFixed(2)} ₳',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Refresh button
                            if (walletService.isConnected)
                              IconButton(
                                onPressed: _isRefreshing ? null : _refreshBalance,
                                icon: _isRefreshing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFD4AF37),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh,
                                        color: Color(0xFFD4AF37),
                                      ),
                                tooltip: 'Refresh Balance',
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem(
                              'Daily Yield',
                              '+\$0.00',
                              Icons.trending_up,
                            ),
                            _buildSummaryItem(
                              'Estates',
                              '${walletService.holdings.length}',
                              Icons.apartment,
                            ),
                            _buildSummaryItem(
                              'Crown Rank',
                              'Lvl ${walletService.userLevel}',
                              Icons.military_tech,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  const Text(
                    'Royal Commands',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Acquire',
                          Icons.add_business,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Trade',
                          Icons.swap_horiz,
                          Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Claim',
                          Icons.savings,
                          Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Featured Properties
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Properties',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MarketplacePage(),
                            ),
                          );
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280, // Increased height for PropertyCard
                    child: featuredListings.isEmpty
                        ? Center(
                            child: Text(
                              'No featured properties',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: featuredListings.length,
                            itemBuilder: (context, index) {
                              final listing = featuredListings[index];
                              return Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 16),
                                child: PropertyCard(
                                  title: listing.propertyName,
                                  location: listing.location,
                                  imageUrl: listing.imageUrl,
                                  price: listing.price,
                                  apy: 8.5 + index, // Mock APY
                                  fundedPercentage: listing.fundedPercentage,
                                  fundsRaised: listing.fundsRaised,
                                  targetAmount: listing.targetAmount,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MarketplacePage(),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 80), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        if (label == 'Invest' || label == 'Trade') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MarketplacePage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: color == AppTheme.primaryColor
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
