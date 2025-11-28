import 'package:flutter/material.dart';
import 'dart:async';

/// Hydra Integration for High-Throughput Trading
/// For Best Hydra Implementation Award! ⚡
/// 
/// Features:
/// - Hydra Head state management
/// - Instant off-chain transactions
/// - Batch transaction processing
/// - Real-time trading channel

// ============== HYDRA MODELS ==============

/// Hydra Head state
enum HydraHeadState {
  idle,
  initializing,
  open,
  closing,
  closed,
  fanout,
}

/// Transaction in Hydra Head
class HydraTransaction {
  final String txId;
  final String type; // 'buy', 'sell', 'transfer'
  final double amount;
  final String propertyId;
  final DateTime timestamp;
  final String status; // 'pending', 'confirmed', 'settled'
  final int confirmations;

  HydraTransaction({
    required this.txId,
    required this.type,
    required this.amount,
    required this.propertyId,
    required this.timestamp,
    this.status = 'pending',
    this.confirmations = 0,
  });

  HydraTransaction copyWith({
    String? status,
    int? confirmations,
  }) {
    return HydraTransaction(
      txId: txId,
      type: type,
      amount: amount,
      propertyId: propertyId,
      timestamp: timestamp,
      status: status ?? this.status,
      confirmations: confirmations ?? this.confirmations,
    );
  }
}

/// Hydra Head info
class HydraHead {
  final String headId;
  final HydraHeadState state;
  final List<String> participants;
  final double totalLiquidity;
  final int transactionCount;
  final DateTime? openedAt;
  final int currentRound;

  HydraHead({
    required this.headId,
    required this.state,
    required this.participants,
    required this.totalLiquidity,
    this.transactionCount = 0,
    this.openedAt,
    this.currentRound = 0,
  });

  HydraHead copyWith({
    HydraHeadState? state,
    double? totalLiquidity,
    int? transactionCount,
    DateTime? openedAt,
    int? currentRound,
  }) {
    return HydraHead(
      headId: headId,
      state: state ?? this.state,
      participants: participants,
      totalLiquidity: totalLiquidity ?? this.totalLiquidity,
      transactionCount: transactionCount ?? this.transactionCount,
      openedAt: openedAt ?? this.openedAt,
      currentRound: currentRound ?? this.currentRound,
    );
  }
}

// ============== HYDRA SERVICE ==============

class HydraService extends ChangeNotifier {
  HydraHead? _currentHead;
  final List<HydraTransaction> _transactions = [];
  bool _isProcessing = false;
  Timer? _tpsTimer;
  int _tpsCount = 0;
  double _currentTps = 0;

  // Simulated stats
  int _totalTransactionsProcessed = 0;
  double _averageLatency = 0;
  double _peakTps = 0;

  HydraHead? get currentHead => _currentHead;
  List<HydraTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isProcessing => _isProcessing;
  double get currentTps => _currentTps;
  int get totalTransactionsProcessed => _totalTransactionsProcessed;
  double get averageLatency => _averageLatency;
  double get peakTps => _peakTps;

  bool get isHeadOpen => _currentHead?.state == HydraHeadState.open;

  /// Initialize and open a Hydra Head
  Future<HydraHead> openHead({
    required List<String> participants,
    required double initialLiquidity,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Simulate head initialization
      _currentHead = HydraHead(
        headId: 'hydra_${DateTime.now().millisecondsSinceEpoch}',
        state: HydraHeadState.initializing,
        participants: participants,
        totalLiquidity: initialLiquidity,
      );
      notifyListeners();

      // Simulate initialization phases
      await Future.delayed(const Duration(milliseconds: 800));
      _currentHead = _currentHead!.copyWith(state: HydraHeadState.open, openedAt: DateTime.now());

      // Start TPS monitoring
      _startTpsMonitoring();

      _isProcessing = false;
      notifyListeners();
      return _currentHead!;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Submit an instant transaction through Hydra
  Future<HydraTransaction> submitInstantTransaction({
    required String type,
    required double amount,
    required String propertyId,
  }) async {
    if (!isHeadOpen) {
      throw Exception('Hydra Head is not open');
    }

    final tx = HydraTransaction(
      txId: 'htx_${DateTime.now().millisecondsSinceEpoch}_${_transactions.length}',
      type: type,
      amount: amount,
      propertyId: propertyId,
      timestamp: DateTime.now(),
      status: 'pending',
    );

    _transactions.insert(0, tx);
    _tpsCount++;
    notifyListeners();

    // Simulate instant confirmation (sub-second)
    await Future.delayed(Duration(milliseconds: 50 + (amount * 2).toInt()));

    final confirmedTx = tx.copyWith(status: 'confirmed', confirmations: 1);
    final index = _transactions.indexWhere((t) => t.txId == tx.txId);
    if (index >= 0) {
      _transactions[index] = confirmedTx;
    }

    _totalTransactionsProcessed++;
    _averageLatency = (_averageLatency * (_totalTransactionsProcessed - 1) + 75) / _totalTransactionsProcessed;

    _currentHead = _currentHead!.copyWith(
      transactionCount: _currentHead!.transactionCount + 1,
      currentRound: _currentHead!.currentRound + 1,
    );

    notifyListeners();
    return confirmedTx;
  }

  /// Submit batch transactions for maximum throughput
  Future<List<HydraTransaction>> submitBatchTransactions(
    List<Map<String, dynamic>> txData,
  ) async {
    if (!isHeadOpen) {
      throw Exception('Hydra Head is not open');
    }

    final List<HydraTransaction> results = [];

    for (final data in txData) {
      final tx = await submitInstantTransaction(
        type: data['type'] as String,
        amount: data['amount'] as double,
        propertyId: data['propertyId'] as String,
      );
      results.add(tx);
    }

    return results;
  }

  /// Close the Hydra Head and settle on L1
  Future<void> closeHead() async {
    if (_currentHead == null) return;

    _isProcessing = true;
    _currentHead = _currentHead!.copyWith(state: HydraHeadState.closing);
    notifyListeners();

    // Stop TPS monitoring
    _tpsTimer?.cancel();

    // Simulate fanout
    await Future.delayed(const Duration(seconds: 1));
    _currentHead = _currentHead!.copyWith(state: HydraHeadState.fanout);
    notifyListeners();

    // Mark all transactions as settled
    for (int i = 0; i < _transactions.length; i++) {
      _transactions[i] = _transactions[i].copyWith(status: 'settled');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _currentHead = _currentHead!.copyWith(state: HydraHeadState.closed);

    _isProcessing = false;
    notifyListeners();
  }

  void _startTpsMonitoring() {
    _tpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTps = _tpsCount.toDouble();
      if (_currentTps > _peakTps) {
        _peakTps = _currentTps;
      }
      _tpsCount = 0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tpsTimer?.cancel();
    super.dispose();
  }
}

// ============== HYDRA UI WIDGETS ==============

/// Hydra Head status indicator
class HydraStatusIndicator extends StatelessWidget {
  final HydraHead? head;

  const HydraStatusIndicator({super.key, this.head});

  @override
  Widget build(BuildContext context) {
    if (head == null) {
      return _buildStatusChip('No Head', Colors.grey, Icons.remove_circle_outline);
    }

    switch (head!.state) {
      case HydraHeadState.idle:
        return _buildStatusChip('Idle', Colors.grey, Icons.pause_circle_outline);
      case HydraHeadState.initializing:
        return _buildStatusChip('Initializing...', Colors.orange, Icons.hourglass_top);
      case HydraHeadState.open:
        return _buildStatusChip('Open ⚡', Colors.green, Icons.bolt);
      case HydraHeadState.closing:
        return _buildStatusChip('Closing...', Colors.orange, Icons.hourglass_bottom);
      case HydraHeadState.closed:
        return _buildStatusChip('Closed', Colors.grey, Icons.check_circle);
      case HydraHeadState.fanout:
        return _buildStatusChip('Settling on L1...', Colors.blue, Icons.sync);
    }
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Real-time TPS counter
class TpsCounter extends StatefulWidget {
  final double tps;

  const TpsCounter({super.key, required this.tps});

  @override
  State<TpsCounter> createState() => _TpsCounterState();
}

class _TpsCounterState extends State<TpsCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(TpsCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tps != widget.tps) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D9FF).withValues(alpha: 0.2),
            const Color(0xFF0033AD).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, color: Color(0xFF00D9FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Throughput',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.1),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFFFFFFFF)],
                  ).createShader(bounds),
                  child: Text(
                    '${widget.tps.toStringAsFixed(0)} TPS',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Instant Finality ⚡',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hydra transaction feed
class HydraTransactionFeed extends StatelessWidget {
  final List<HydraTransaction> transactions;
  final int maxItems;

  const HydraTransactionFeed({
    super.key,
    required this.transactions,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    final displayTxs = transactions.take(maxItems).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Color(0xFF00D9FF), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Live',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayTxs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...displayTxs.map((tx) => _TransactionItem(tx: tx)),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatefulWidget {
  final HydraTransaction tx;

  const _TransactionItem({required this.tx});

  @override
  State<_TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<_TransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - _animation.value) * 50, 0),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(widget.tx.status).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(widget.tx.type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(widget.tx.type),
                color: _getTypeColor(widget.tx.type),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.tx.type.toUpperCase()} ${widget.tx.amount.toStringAsFixed(2)} ₳',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.tx.txId.substring(0, 20),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.tx.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.tx.status,
                    style: TextStyle(
                      color: _getStatusColor(widget.tx.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '<1s',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'buy':
        return Icons.add_shopping_cart;
      case 'sell':
        return Icons.sell;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'settled':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}

/// Hydra dashboard panel
class HydraDashboard extends StatelessWidget {
  final HydraService hydraService;

  const HydraDashboard({super.key, required this.hydraService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Hydra branding
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0033AD).withValues(alpha: 0.3),
                const Color(0xFF00D9FF).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Hydra logo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🐉', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hydra L2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'High-Throughput Trading Channel',
                          style: TextStyle(
                            color: Color(0xFF00D9FF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HydraStatusIndicator(head: hydraService.currentHead),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TpsCounter(tps: hydraService.currentTps)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            Expanded(child: _buildStatCard('Total TXs', '${hydraService.totalTransactionsProcessed}', Icons.receipt_long)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Avg Latency', '${hydraService.averageLatency.toStringAsFixed(0)}ms', Icons.timer)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Peak TPS', '${hydraService.peakTps.toStringAsFixed(0)}', Icons.trending_up)),
          ],
        ),
        const SizedBox(height: 16),

        // Transaction feed
        HydraTransactionFeed(transactions: hydraService.transactions),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00D9FF), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// Quick trade button for Hydra
class HydraQuickTradeButton extends StatefulWidget {
  final String propertyId;
  final double amount;
  final String type;
  final VoidCallback? onTrade;

  const HydraQuickTradeButton({
    super.key,
    required this.propertyId,
    required this.amount,
    required this.type,
    this.onTrade,
  });

  @override
  State<HydraQuickTradeButton> createState() => _HydraQuickTradeButtonState();
}

class _HydraQuickTradeButtonState extends State<HydraQuickTradeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _executeTrade() async {
    setState(() => _isProcessing = true);
    _controller.repeat();

    try {
      // Simulate trade execution
      await Future.delayed(const Duration(milliseconds: 200));
      widget.onTrade?.call();
    } finally {
      setState(() => _isProcessing = false);
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isProcessing ? null : _executeTrade,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.type == 'buy'
                    ? [Colors.green, Colors.green.shade700]
                    : [Colors.red, Colors.red.shade700],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isProcessing
                  ? [
                      BoxShadow(
                        color: (widget.type == 'buy' ? Colors.green : Colors.red)
                            .withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.8)),
                    ),
                  )
                else
                  const Icon(Icons.bolt, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _isProcessing
                      ? 'Processing...'
                      : '⚡ ${widget.type.toUpperCase()} ${widget.amount.toStringAsFixed(0)} ₳',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
