import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/hydra_trading_service.dart';
import 'real_hydra_trading_widget.dart';

/// Dedicated Hydra Trading Page
class HydraPage extends StatelessWidget {
  const HydraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050505),
              Color(0xFF0a1628),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
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
                    const Icon(Icons.bolt, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Hydra L2 Trading',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'INSTANT',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              const Expanded(
                child: RealHydraTradingWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Hydra status card for the home page
class HydraQuickStatus extends StatelessWidget {
  const HydraQuickStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // Use global provider instead of creating new instance
    return Consumer<HydraTradingService>(
      builder: (context, service, _) {
        final state = service.state;
        final isConnected = state.isConnected;
        final isOpen = state.isOpen;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HydraPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOpen
                      ? [Colors.green.shade900, Colors.green.shade700]
                      : isConnected
                          ? [Colors.blue.shade900, Colors.blue.shade700]
                          : [Colors.grey.shade900, Colors.grey.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isOpen ? Colors.green : Colors.blue).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isOpen ? Icons.bolt : Icons.water_drop,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hydra L2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOpen
                              ? 'Head Open • Instant Trades'
                              : isConnected
                                  ? 'Connected • ${state.status}'
                                  : 'Tap to connect',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOpen) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${state.stats.currentTps.toStringAsFixed(1)} TPS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.stats.averageLatencyMs.toStringAsFixed(0)}ms',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      );
  }
}
