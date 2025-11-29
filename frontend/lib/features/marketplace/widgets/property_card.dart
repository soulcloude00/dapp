import 'package:flutter/material.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/hydra_trading_service.dart';

class PropertyCard extends StatelessWidget {
  final String title;
  final String location;
  final String imageUrl;
  final double price;
  final double apy;
  final double fundedPercentage;
  final double? fundsRaised; // Funds raised in ADA
  final double? targetAmount; // Target amount in ADA
  final VoidCallback? onTap;
  final HydraFraction? hydraFraction; // If present, enables Hydra "Instant Buy"

  const PropertyCard({
    super.key,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.price,
    required this.apy,
    required this.fundedPercentage,
    this.fundsRaised,
    this.targetAmount,
    this.onTap,
    this.hydraFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassDecoration,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Container(
              height: 125,
              width: double.infinity,
              color: Colors.grey[900],
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 125,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppTheme.primaryColor,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.apartment,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.apartment,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                  // Hydra Badge
                  if (hydraFraction != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bolt, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Instant Buy',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar
                  LinearProgressIndicator(
                    value: fundedPercentage,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(fundedPercentage * 100).toInt()}% Funded',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      Text(
                        '\$${price.toStringAsFixed(0)} Target',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Show funds raised if available
                  if (fundsRaised != null && fundsRaised! > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: AppTheme.secondaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${fundsRaised!.toStringAsFixed(0)} ₳ raised',
                                style: TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (targetAmount != null)
                            Text(
                              'of ${targetAmount!.toStringAsFixed(0)} ₳',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
