import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/features/marketplace/marketplace_page.dart';

/// Portfolio page showing user's owned fractions and transaction history
class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, walletService, child) {
        final holdings = walletService.holdings;
        final transactions = walletService.transactionHistory;
        final totalValue = walletService.portfolioValue;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.3),
                          AppTheme.secondaryColor.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'My Portfolio',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Value',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${totalValue.toStringAsFixed(0)} ₳',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '+12.5%',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Holdings Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Holdings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${holdings.length} Properties',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Holdings List
              if (holdings.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyHoldings(context),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final holding = holdings[index];
                      return _buildHoldingCard(context, holding);
                    },
                    childCount: holdings.length,
                  ),
                ),

              // Transaction History Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction History',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Show all transactions
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Transactions List
              if (transactions.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyTransactions(context),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = transactions[index];
                      return _buildTransactionCard(context, tx);
                    },
                    childCount: transactions.length > 5 ? 5 : transactions.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyHoldings(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Holdings Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start investing in real estate by buying property fractions',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to marketplace
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketplacePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Explore Properties'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 12),
          Text(
            'No Transactions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingCard(BuildContext context, PropertyHolding holding) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.glassDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Property Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              clipBehavior: Clip.antiAlias,
              child: holding.imageUrl.isNotEmpty
                  ? Image.network(
                      holding.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.apartment,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.apartment,
                      color: Colors.grey[600],
                      size: 32,
                    ),
            ),
            const SizedBox(width: 16),
            // Property Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.propertyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holding.location,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildHoldingChip(
                        '${holding.fractionsOwned} Fractions',
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildHoldingChip(
                        '${holding.ownershipPercentage.toStringAsFixed(2)}%',
                        AppTheme.secondaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${holding.currentValue.toStringAsFixed(0)} ₳',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: holding.profitLoss >= 0
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${holding.profitLoss >= 0 ? '+' : ''}${holding.profitLoss.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: holding.profitLoss >= 0 ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionRecord tx) {
    final isBuy = tx.type == TransactionType.buy;

    IconData icon;
    Color iconColor;
    String typeLabel;

    switch (tx.type) {
      case TransactionType.buy:
        icon = Icons.shopping_cart;
        iconColor = AppTheme.primaryColor;
        typeLabel = 'Bought';
        break;
      case TransactionType.sell:
        icon = Icons.sell;
        iconColor = Colors.orange;
        typeLabel = 'Sold';
        break;
      case TransactionType.receive:
        icon = Icons.arrow_downward;
        iconColor = Colors.green;
        typeLabel = 'Received';
        break;
      case TransactionType.send:
        icon = Icons.arrow_upward;
        iconColor = Colors.red;
        typeLabel = 'Sent';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Text(
              typeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (tx.propertyName != null) ...[
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tx.propertyName!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              _formatDate(tx.timestamp),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(width: 8),
            if (tx.txHash != null)
              GestureDetector(
                onTap: () {
                  // Open in explorer
                },
                child: Text(
                  '${tx.txHash!.substring(0, 8)}...',
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isBuy ? '-' : '+'}${tx.amount.toStringAsFixed(0)} ₳',
              style: TextStyle(
                color: isBuy ? Colors.white : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (tx.fractions != null)
              Text(
                '${tx.fractions} fractions',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
