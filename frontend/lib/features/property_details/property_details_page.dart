import 'package:flutter/material.dart';
import 'package:propfi/theme/app_theme.dart';

class PropertyDetailsPage extends StatefulWidget {
  final String title;
  final double price;
  final double apy;

  const PropertyDetailsPage({
    super.key,
    required this.title,
    required this.price,
    required this.apy,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  double _investmentAmount = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.title),
              background: Container(
                color: Colors.grey[900],
                child: Center(
                  child: Icon(
                    Icons.apartment,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailStat('APY', '${widget.apy}%'),
                      _buildDetailStat(
                        'Target',
                        '\$${widget.price.toStringAsFixed(0)}',
                      ),
                      _buildDetailStat('Min. Inv', '\$50'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Description
                  Text(
                    'About this Property',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This premium asset offers high yield potential through fractionalized ownership. Located in a prime district, it is managed by top-tier property managers.',
                    style: TextStyle(color: Colors.grey[400], height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  // Investment Slider
                  Text(
                    'Investment Amount',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassDecoration,
                    child: Column(
                      children: [
                        Text(
                          '\$${_investmentAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: _investmentAmount,
                          min: 50,
                          max: 10000,
                          activeColor: AppTheme.primaryColor,
                          inactiveColor: Colors.grey[800],
                          onChanged: (value) {
                            setState(() {
                              _investmentAmount = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Show success dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceColor,
                                  title: const Text(
                                    'Investment Successful',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    'You have successfully invested \$${_investmentAmount.toStringAsFixed(0)} in ${widget.title}.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('INVEST NOW'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
