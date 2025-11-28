import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/wallet_service.dart';
import 'dart:math' as math;

/// Analytics dashboard with portfolio performance and market statistics
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeframe = '1M';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, walletService, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Analytics'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: const [
                    Tab(text: 'Portfolio'),
                    Tab(text: 'Market'),
                    Tab(text: 'Properties'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPortfolioTab(walletService),
                    _buildMarketTab(),
                    _buildPropertiesTab(walletService),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioTab(WalletService walletService) {
    final portfolioValue = walletService.portfolioValue;
    final holdings = walletService.holdings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Value Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Portfolio Value',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${portfolioValue.toStringAsFixed(0)} ₳',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '+12.5%',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Timeframe selector
                Row(
                  children: ['1W', '1M', '3M', '1Y', 'ALL'].map((tf) {
                    final isSelected = _selectedTimeframe == tf;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTimeframe = tf),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[700]!,
                            ),
                          ),
                          child: Text(
                            tf,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Chart
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: LineChartPainter(
                      data: _generateChartData(),
                      lineColor: AppTheme.primaryColor,
                      fillColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Holdings Distribution
          const Text(
            'Holdings Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (holdings.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: AppTheme.glassDecoration,
              child: Center(
                child: Text(
                  'No holdings yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration,
              child: Row(
                children: [
                  // Pie Chart
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: PieChartPainter(
                        values: holdings.map((h) => h.currentValue).toList(),
                        colors: _generateColors(holdings.length),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: holdings.asMap().entries.map((entry) {
                        final index = entry.key;
                        final holding = entry.value;
                        final color = _generateColors(holdings.length)[index];
                        final percentage = portfolioValue > 0
                            ? (holding.currentValue / portfolioValue * 100)
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  holding.propertyName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Performance Stats
          const Text(
            'Performance',
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
                child: _buildStatCard(
                  'Total Invested',
                  '${holdings.fold(0.0, (sum, h) => sum + h.purchasePrice).toStringAsFixed(0)} ₳',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Return',
                  '+${(portfolioValue - holdings.fold(0.0, (sum, h) => sum + h.purchasePrice)).toStringAsFixed(0)} ₳',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Properties',
                  '${holdings.length}',
                  Icons.apartment,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Fractions',
                  '${holdings.fold(0, (sum, h) => sum + h.fractionsOwned)}',
                  Icons.grid_view,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMarketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Market Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Market Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildMarketStat(
                        'Total Value Locked',
                        '2.4M ₳',
                        '+8.3%',
                        true,
                      ),
                    ),
                    Expanded(
                      child: _buildMarketStat(
                        '24h Volume',
                        '156K ₳',
                        '+12.1%',
                        true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMarketStat(
                        'Active Listings',
                        '24',
                        '+3',
                        true,
                      ),
                    ),
                    Expanded(
                      child: _buildMarketStat(
                        'Total Investors',
                        '1,842',
                        '+156',
                        true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Volume Chart
          const Text(
            'Trading Volume',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration,
            child: SizedBox(
              height: 160,
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: BarChartPainter(
                  values: _generateVolumeData(),
                  barColor: AppTheme.secondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Trending Properties
          const Text(
            'Trending Properties',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendingItem('Lagos Heights', '+24.5%', 1),
          _buildTrendingItem('Abuja Towers', '+18.2%', 2),
          _buildTrendingItem('Port Harcourt Estate', '+15.8%', 3),
          _buildTrendingItem('Ibadan Gardens', '+12.3%', 4),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab(WalletService walletService) {
    final listings = walletService.listings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Properties',
                  '${listings.length}',
                  Icons.home_work,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg. APY',
                  '8.2%',
                  Icons.percent,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Property Performance
          const Text(
            'Property Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (listings.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: AppTheme.glassDecoration,
              child: Center(
                child: Text(
                  'No properties listed',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ...listings.take(5).map((listing) => _buildPropertyPerformanceItem(
                  listing.propertyName,
                  listing.location,
                  listing.fundedPercentage,
                  8.5, // Mock APY
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStat(
    String label,
    String value,
    String change,
    bool isPositive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          change,
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingItem(String name, String change, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rank <= 3 ? AppTheme.primaryColor : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              change,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyPerformanceItem(
    String name,
    String location,
    double funded,
    double apy,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      location,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${apy.toStringAsFixed(1)}% APY',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: funded,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation(
                      funded >= 0.8 ? Colors.green : AppTheme.secondaryColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(funded * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _generateChartData() {
    final random = math.Random(42);
    return List.generate(30, (i) => 50 + random.nextDouble() * 50 + i * 2);
  }

  List<double> _generateVolumeData() {
    final random = math.Random(42);
    return List.generate(12, (i) => 20 + random.nextDouble() * 80);
  }

  List<Color> _generateColors(int count) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return List.generate(count, (i) => colors[i % colors.length]);
  }
}

/// Custom line chart painter
class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - ((data[i] - minValue) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Draw line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw end point
    final lastX = size.width;
    final lastY =
        size.height - ((data.last - minValue) / range * size.height);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom pie chart painter
class PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final total = values.reduce((a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw center hole
    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()..color = AppTheme.backgroundColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom bar chart painter
class BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color barColor;

  BarChartPainter({required this.values, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxValue = values.reduce(math.max);
    final barWidth = size.width / values.length - 8;

    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxValue) * size.height;
      final x = i * (size.width / values.length) + 4;
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        rect,
        Paint()..color = barColor.withValues(alpha: 0.3 + (i / values.length) * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
