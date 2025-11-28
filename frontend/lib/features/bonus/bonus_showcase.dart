import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/features/memes/cardano_memes.dart';
import 'package:propfi/features/ui_enhancements/animations.dart';
import 'package:propfi/features/privacy/zk_privacy.dart';
import 'package:propfi/features/hydra/hydra_trading.dart';

/// Bonus Features Showcase Page
/// Demonstrates all bonus award features in one place!

class BonusFeaturesShowcase extends StatefulWidget {
  const BonusFeaturesShowcase({super.key});

  @override
  State<BonusFeaturesShowcase> createState() => _BonusFeaturesShowcaseState();
}

class _BonusFeaturesShowcaseState extends State<BonusFeaturesShowcase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ZKPrivacyService()),
        ChangeNotifierProvider(create: (_) => HydraService()),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // Background
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
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '👑 Royal Features',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Crestadel Award Showcase',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Celebration button
                        BouncyButton(
                          onPressed: () {
                            setState(() => _showConfetti = true);
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted) setState(() => _showConfetti = false);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🏰', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF0033AD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: '😂 Memes'),
                        Tab(text: '✨ UI/UX'),
                        Tab(text: '🔐 Privacy'),
                        Tab(text: '⚡ Hydra'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _MemesTab(),
                        _UIUXTab(),
                        _PrivacyTab(),
                        _HydraTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Confetti overlay
            if (_showConfetti)
              ConfettiEffect(
                trigger: _showConfetti,
                onComplete: () => setState(() => _showConfetti = false),
              ),
          ],
        ),
      ),
    );
  }
}

// ============== MEMES TAB ==============

class _MemesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Award badge
          _buildAwardBadge(
            'Best Meme Integration',
            'Bringing Cardano culture to life!',
            '😂',
          ),
          const SizedBox(height: 24),

          // Charles Easter Egg demo
          CharlesEasterEgg(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0033AD).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('🧔', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap 5 times to unlock Charles!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '(Easter egg activated)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meme quotes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Royal Wisdom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...CardanoMemes.royalQuotes.take(4).map((quote) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              quote,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Loading spinner demo
          const Center(child: AdaLoadingSpinner()),
          const SizedBox(height: 24),

          // WAGMI button
          Center(
            child: BouncyButton(
              onPressed: () => showWagmiSuccess(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0033AD), Color(0xFF00D9FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🚀 Show WAGMI Success!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Diamond hands badge
          const Center(child: DiamondHandsBadge()),
        ],
      ),
    );
  }
}

// ============== UI/UX TAB ==============

class _UIUXTab extends StatefulWidget {
  @override
  State<_UIUXTab> createState() => _UIUXTabState();
}

class _UIUXTabState extends State<_UIUXTab> {
  double _progressValue = 0.65;
  double _counterValue = 12345;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAwardBadge(
            'Best UI/UX',
            'Intuitive, user-friendly design',
            '✨',
          ),
          const SizedBox(height: 24),

          // Animated gradient border
          AnimatedGradientBorder(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  Icon(Icons.auto_awesome, color: Color(0xFF00D9FF), size: 32),
                  SizedBox(height: 12),
                  Text(
                    'Animated Gradient Border',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Glass card
          const GlassCard(
            child: Column(
              children: [
                Icon(Icons.blur_on, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'Glass Morphism Card',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Animated counter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Animated Counter',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                AnimatedCounter(
                  value: _counterValue,
                  prefix: '₳ ',
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => _counterValue += 1000),
                      child: const Text('+1000'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _counterValue -= 1000),
                      child: const Text('-1000'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Glowing progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Glowing Progress Indicator',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                GlowingProgressIndicator(progress: _progressValue),
                const SizedBox(height: 12),
                Slider(
                  value: _progressValue,
                  onChanged: (v) => setState(() => _progressValue = v),
                  activeColor: const Color(0xFF00D9FF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bouncy buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BouncyButton(
                onPressed: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0033AD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
              BouncyButton(
                onPressed: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ),
              BouncyButton(
                onPressed: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shimmer loading
          ShimmerLoading(
            isLoading: true,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== PRIVACY TAB ==============

class _PrivacyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ZKPrivacyService>(
      builder: (context, zkService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAwardBadge(
                'Privacy in Action',
                'Best use of ZK/privacy logic',
                '🔐',
              ),
              const SizedBox(height: 24),

              // ZK explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0033AD).withValues(alpha: 0.3),
                      const Color(0xFF00D9FF).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'Zero-Knowledge Proofs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prove statements about your data without revealing the data itself. '
                      'Perfect for private purchases and confidential transactions.',
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Private purchase demo button
              Center(
                child: BouncyButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PrivatePurchaseDialog(
                        propertyId: 'demo_property',
                        propertyName: 'Luxury Beach Villa',
                        pricePerFraction: 500,
                        walletBalance: 10000,
                        onPurchaseComplete: (purchase) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Private purchase complete! Commitment: ${purchase.commitment}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0033AD), Color(0xFF00D9FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Try Private Purchase',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Privacy settings
              const PrivacySettingsPanel(),
              const SizedBox(height: 16),

              // Balance proof demo
              if (zkService.balanceProofs.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Balance Proofs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...zkService.balanceProofs.map(
                      (proof) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ZKProofVisualization(proof: proof.proof),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============== HYDRA TAB ==============

class _HydraTab extends StatefulWidget {
  @override
  State<_HydraTab> createState() => _HydraTabState();
}

class _HydraTabState extends State<_HydraTab> {
  bool _demoRunning = false;
  int _demoTxCount = 0;

  Future<void> _runDemo(HydraService hydraService) async {
    setState(() => _demoRunning = true);

    try {
      // Open Hydra Head
      if (!hydraService.isHeadOpen) {
        await hydraService.openHead(
          participants: ['PropFi', 'User Wallet'],
          initialLiquidity: 100000,
        );
      }

      // Simulate burst of transactions
      for (int i = 0; i < 20; i++) {
        await hydraService.submitInstantTransaction(
          type: i % 3 == 0 ? 'sell' : 'buy',
          amount: (50 + (i * 10)).toDouble(),
          propertyId: 'property_${i % 5}',
        );
        setState(() => _demoTxCount = i + 1);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      setState(() => _demoRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HydraService>(
      builder: (context, hydraService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAwardBadge(
                'Best Hydra Implementation',
                'Innovative use of Hydra for scaling',
                '⚡',
              ),
              const SizedBox(height: 24),

              // Hydra explanation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF).withValues(alpha: 0.2),
                      const Color(0xFF0033AD).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🐉', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'Hydra L2 Protocol',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lightning-fast off-chain transactions with instant finality. '
                      'Perfect for high-frequency property trading!',
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Demo button
              Center(
                child: BouncyButton(
                  onPressed: _demoRunning ? null : () => _runDemo(hydraService),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _demoRunning
                          ? LinearGradient(
                              colors: [Colors.grey[700]!, Colors.grey[800]!],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF00D9FF), Color(0xFF0033AD)],
                            ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_demoRunning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.bolt, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _demoRunning
                              ? 'Processing $_demoTxCount/20...'
                              : '⚡ Run Hydra Demo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hydra dashboard
              HydraDashboard(hydraService: hydraService),
            ],
          ),
        );
      },
    );
  }
}

// ============== HELPER WIDGETS ==============

Widget _buildAwardBadge(String title, String subtitle, String emoji) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.emoji_events, color: Colors.black, size: 32),
      ],
    ),
  );
}
