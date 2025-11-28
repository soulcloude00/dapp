import 'package:flutter/material.dart';
import 'package:propfi/theme/app_theme.dart';

class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;
  final String title;
  final String location;
  final String imageUrl;
  final double price;
  final double pricePerFraction;
  final int totalFractions;
  final int fractionsAvailable;
  final double apy;
  final String sellerAddress;
  final VoidCallback? onBuy;

  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.price,
    required this.pricePerFraction,
    required this.totalFractions,
    required this.fractionsAvailable,
    required this.apy,
    required this.sellerAddress,
    this.onBuy,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFractions = 1;

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

  double get fundedPercentage =>
      (widget.totalFractions - widget.fractionsAvailable) / widget.totalFractions;
  int get fractionsSold => widget.totalFractions - widget.fractionsAvailable;
  double get fundsRaised => fractionsSold * widget.pricePerFraction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[900],
                            child: Icon(Icons.apartment, size: 80, color: Colors.grey[700]),
                          ),
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: Icon(Icons.apartment, size: 80, color: Colors.grey[700]),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Property info overlay
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              widget.location,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share link copied!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites')),
                  );
                },
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  _buildStatsRow(),
                  const SizedBox(height: 20),

                  // Funding Progress
                  _buildFundingProgress(),
                  const SizedBox(height: 24),

                  // Tab Bar
                  Container(
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
                        Tab(text: 'Overview'),
                        Tab(text: 'Financials'),
                        Tab(text: 'Documents'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildFinancialsTab(),
                        _buildDocumentsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBuySection(),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('APY', '${widget.apy.toStringAsFixed(1)}%', Icons.trending_up),
        _buildStatItem('Price/Fraction', '${widget.pricePerFraction.toStringAsFixed(0)} ₳', Icons.paid),
        _buildStatItem('Fractions', '${widget.totalFractions}', Icons.grid_view),
        _buildStatItem('Available', '${widget.fractionsAvailable}', Icons.inventory_2),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFundingProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Funding Progress',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              Text(
                '${(fundedPercentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fundedPercentage,
              minHeight: 10,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(
                fundedPercentage >= 0.8 ? Colors.green : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fundsRaised.toStringAsFixed(0)} ₳ raised',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                'of ${widget.price.toStringAsFixed(0)} ₳',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$fractionsSold of ${widget.totalFractions} fractions sold',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this Property',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This premium real estate asset offers exceptional investment potential through tokenized fractionalized ownership on the Cardano blockchain. Located in a prime district, it is professionally managed by certified property managers with a proven track record.',
            style: TextStyle(color: Colors.grey[400], height: 1.6),
          ),
          const SizedBox(height: 24),

          const Text(
            'Key Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.security, 'Blockchain-secured ownership'),
          _buildFeatureItem(Icons.account_balance, 'Regulated investment'),
          _buildFeatureItem(Icons.swap_horiz, 'Tradeable on secondary market'),
          _buildFeatureItem(Icons.payments, 'Quarterly dividend payouts'),
          _buildFeatureItem(Icons.support_agent, 'Professional property management'),

          const SizedBox(height: 24),
          const Text(
            'Owner Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Property Owner',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.sellerAddress.substring(0, 12)}...${widget.sellerAddress.substring(widget.sellerAddress.length - 8)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildFinancialsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Investment Returns',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Returns chart (simplified)
          Container(
            height: 150,
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildReturnItem('1 Year', '+${widget.apy.toStringAsFixed(1)}%'),
                    _buildReturnItem('3 Years', '+${(widget.apy * 2.5).toStringAsFixed(1)}%'),
                    _buildReturnItem('5 Years', '+${(widget.apy * 4).toStringAsFixed(1)}%'),
                  ],
                ),
                const Spacer(),
                // Simple bar chart
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(12, (i) {
                    final height = 20.0 + (i * 3) + (i % 3 == 0 ? 10 : 0);
                    return Container(
                      width: 16,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3 + (i * 0.05)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Financial Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildFinancialRow('Property Value', '${widget.price.toStringAsFixed(0)} ₳'),
          _buildFinancialRow('Price per Fraction', '${widget.pricePerFraction.toStringAsFixed(2)} ₳'),
          _buildFinancialRow('Expected Annual Yield', '${widget.apy.toStringAsFixed(1)}%'),
          _buildFinancialRow('Management Fee', '1.5%'),
          _buildFinancialRow('Dividend Frequency', 'Quarterly'),
          _buildFinancialRow('Lockup Period', 'None'),
        ],
      ),
    );
  }

  Widget _buildReturnItem(String period, String value) {
    return Column(
      children: [
        Text(period, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legal Documents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDocumentItem('Property Deed', 'PDF • 2.4 MB', Icons.description),
          _buildDocumentItem('Investment Agreement', 'PDF • 1.8 MB', Icons.gavel),
          _buildDocumentItem('Property Valuation', 'PDF • 856 KB', Icons.assessment),
          _buildDocumentItem('Insurance Certificate', 'PDF • 412 KB', Icons.verified_user),
          const SizedBox(height: 24),

          const Text(
            'Property Reports',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDocumentItem('Inspection Report', 'PDF • 3.2 MB', Icons.home_repair_service),
          _buildDocumentItem('Financial Projections', 'PDF • 1.1 MB', Icons.show_chart),
          _buildDocumentItem('Market Analysis', 'PDF • 2.7 MB', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String name, String meta, IconData icon) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red[300], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white)),
                Text(meta, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download, color: Colors.grey[400]),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading $name...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBuySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: _selectedFractions > 1
                            ? () => setState(() => _selectedFractions--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_selectedFractions',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _selectedFractions < widget.fractionsAvailable
                            ? () => setState(() => _selectedFractions++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${(_selectedFractions * widget.pricePerFraction).toStringAsFixed(2)} ₳',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: widget.fractionsAvailable > 0
                  ? () {
                      if (widget.onBuy != null) {
                        widget.onBuy!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please connect wallet from marketplace'),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
