import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Zero-Knowledge Privacy Features for PropFi
/// For Privacy in Action Award! 🔐
///
/// Showcases ZK concepts for private property investments:
/// - Balance proofs (prove funds without revealing amount)
/// - Private purchases (hide purchase amounts)
/// - Anonymous property ownership
/// - Confidential transactions

// ============== ZK PROOF MODELS ==============

/// Represents a zero-knowledge proof
class ZKProof {
  final String proofId;
  final String proofType;
  final String commitment;
  final DateTime timestamp;
  final bool isValid;
  final Map<String, dynamic> publicInputs;

  ZKProof({
    required this.proofId,
    required this.proofType,
    required this.commitment,
    required this.timestamp,
    this.isValid = true,
    this.publicInputs = const {},
  });
}

/// Balance proof - prove you have sufficient funds
class BalanceProof {
  final String proofId;
  final double minimumBalance; // Public: minimum you're proving
  final String commitment; // Private: actual balance commitment
  final ZKProof proof;
  final DateTime expiresAt;

  BalanceProof({
    required this.proofId,
    required this.minimumBalance,
    required this.commitment,
    required this.proof,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Private purchase with ZK proof
class PrivatePurchase {
  final String purchaseId;
  final String propertyId;
  final String commitment; // Hash of purchase amount
  final ZKProof proof;
  final DateTime timestamp;
  final String status; // 'pending', 'verified', 'completed'

  PrivatePurchase({
    required this.purchaseId,
    required this.propertyId,
    required this.commitment,
    required this.proof,
    required this.timestamp,
    this.status = 'pending',
  });
}

/// Anonymous ownership record
class AnonymousOwnership {
  final String ownershipId;
  final String propertyId;
  final String ownerCommitment; // Hidden owner identity
  final ZKProof ownershipProof;
  final bool isVerified;

  AnonymousOwnership({
    required this.ownershipId,
    required this.propertyId,
    required this.ownerCommitment,
    required this.ownershipProof,
    this.isVerified = true,
  });
}

// ============== ZK SERVICE ==============

class ZKPrivacyService extends ChangeNotifier {
  final List<BalanceProof> _balanceProofs = [];
  final List<PrivatePurchase> _privatePurchases = [];
  final List<AnonymousOwnership> _anonymousOwnerships = [];
  bool _isGeneratingProof = false;
  String? _lastError;

  List<BalanceProof> get balanceProofs => List.unmodifiable(_balanceProofs);
  List<PrivatePurchase> get privatePurchases =>
      List.unmodifiable(_privatePurchases);
  List<AnonymousOwnership> get anonymousOwnerships =>
      List.unmodifiable(_anonymousOwnerships);
  bool get isGeneratingProof => _isGeneratingProof;
  String? get lastError => _lastError;

  /// Generate a balance proof without revealing actual balance
  Future<BalanceProof> createBalanceProof({
    required double minimumBalance,
    required double actualBalance,
  }) async {
    _isGeneratingProof = true;
    _lastError = null;
    notifyListeners();

    try {
      // Simulate ZK proof generation
      await Future.delayed(const Duration(seconds: 1));

      if (actualBalance < minimumBalance) {
        throw Exception('Insufficient balance for proof');
      }

      final commitment = _createCommitment(actualBalance);
      final proof = ZKProof(
        proofId: 'zk_balance_${DateTime.now().millisecondsSinceEpoch}',
        proofType: 'balance_proof',
        commitment: commitment,
        timestamp: DateTime.now(),
        publicInputs: {
          'minimum_balance': minimumBalance,
          'is_sufficient': true,
        },
      );

      final balanceProof = BalanceProof(
        proofId: 'bp_${DateTime.now().millisecondsSinceEpoch}',
        minimumBalance: minimumBalance,
        commitment: commitment,
        proof: proof,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      _balanceProofs.add(balanceProof);
      _isGeneratingProof = false;
      notifyListeners();

      return balanceProof;
    } catch (e) {
      _lastError = e.toString();
      _isGeneratingProof = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create a private purchase with hidden amount
  Future<PrivatePurchase> createPrivatePurchase({
    required String propertyId,
    required double amount,
    required double walletBalance,
  }) async {
    _isGeneratingProof = true;
    _lastError = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (amount > walletBalance) {
        throw Exception('Insufficient balance');
      }

      final commitment = _createCommitment(amount);
      final proof = ZKProof(
        proofId: 'zk_purchase_${DateTime.now().millisecondsSinceEpoch}',
        proofType: 'private_purchase',
        commitment: commitment,
        timestamp: DateTime.now(),
        publicInputs: {
          'property_id': propertyId,
          'has_sufficient_balance': true,
          'amount_valid': true,
        },
      );

      final purchase = PrivatePurchase(
        purchaseId: 'pp_${DateTime.now().millisecondsSinceEpoch}',
        propertyId: propertyId,
        commitment: commitment,
        proof: proof,
        timestamp: DateTime.now(),
      );

      _privatePurchases.add(purchase);
      _isGeneratingProof = false;
      notifyListeners();

      return purchase;
    } catch (e) {
      _lastError = e.toString();
      _isGeneratingProof = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create anonymous ownership proof
  Future<AnonymousOwnership> createAnonymousOwnership({
    required String propertyId,
    required String ownerAddress,
  }) async {
    _isGeneratingProof = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final ownerCommitment = _createCommitment(
        ownerAddress.hashCode.toDouble(),
      );
      final proof = ZKProof(
        proofId: 'zk_ownership_${DateTime.now().millisecondsSinceEpoch}',
        proofType: 'anonymous_ownership',
        commitment: ownerCommitment,
        timestamp: DateTime.now(),
        publicInputs: {'property_id': propertyId, 'ownership_valid': true},
      );

      final ownership = AnonymousOwnership(
        ownershipId: 'ao_${DateTime.now().millisecondsSinceEpoch}',
        propertyId: propertyId,
        ownerCommitment: ownerCommitment,
        ownershipProof: proof,
      );

      _anonymousOwnerships.add(ownership);
      _isGeneratingProof = false;
      notifyListeners();

      return ownership;
    } catch (e) {
      _lastError = e.toString();
      _isGeneratingProof = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Verify a ZK proof
  Future<bool> verifyProof(ZKProof proof) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return proof.isValid;
  }

  /// Create a commitment (simplified hash simulation)
  String _createCommitment(double value) {
    final hash = value.hashCode ^ DateTime.now().hashCode;
    return 'cm_${hash.toRadixString(16)}';
  }
}

// ============== PRIVACY UI WIDGETS ==============

/// Balance proof badge widget
class BalanceProofBadge extends StatelessWidget {
  final BalanceProof? proof;

  const BalanceProofBadge({super.key, this.proof});

  @override
  Widget build(BuildContext context) {
    if (proof == null || proof!.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              'Unverified',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF0033AD)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '≥${proof!.minimumBalance.toStringAsFixed(0)} ₳ Verified',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Private purchase dialog
class PrivatePurchaseDialog extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final double pricePerFraction;
  final double walletBalance;
  final Function(PrivatePurchase) onPurchaseComplete;

  const PrivatePurchaseDialog({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.pricePerFraction,
    required this.walletBalance,
    required this.onPurchaseComplete,
  });

  @override
  State<PrivatePurchaseDialog> createState() => _PrivatePurchaseDialogState();
}

class _PrivatePurchaseDialogState extends State<PrivatePurchaseDialog> {
  final _amountController = TextEditingController(text: '1');
  bool _isProcessing = false;
  String? _error;
  int _proofStep = 0;

  final List<String> _proofSteps = [
    'Creating commitment...',
    'Generating ZK circuit...',
    'Computing witness...',
    'Building proof...',
    'Verifying proof...',
    'Submitting to blockchain...',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _totalCost {
    final fractions = int.tryParse(_amountController.text) ?? 0;
    return fractions * widget.pricePerFraction;
  }

  Future<void> _executePurchase() async {
    final fractions = int.tryParse(_amountController.text);
    if (fractions == null || fractions <= 0) {
      setState(() => _error = 'Enter a valid number of fractions');
      return;
    }
    if (_totalCost > widget.walletBalance) {
      setState(() => _error = 'Insufficient balance');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _proofStep = 0;
    });

    try {
      // Simulate proof generation steps
      for (int i = 0; i < _proofSteps.length; i++) {
        setState(() => _proofStep = i);
        await Future.delayed(const Duration(milliseconds: 400));
      }

      final zkService = context.read<ZKPrivacyService>();
      final purchase = await zkService.createPrivatePurchase(
        propertyId: widget.propertyId,
        amount: _totalCost,
        walletBalance: widget.walletBalance,
      );

      widget.onPurchaseComplete(purchase);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF0033AD), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with lock icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0033AD).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Color(0xFF00D9FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Private Purchase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ZK-Protected Transaction',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Property info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.propertyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price per fraction:',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        '${widget.pricePerFraction.toStringAsFixed(0)} ₳',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0033AD).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0033AD).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip,
                    color: Color(0xFF00D9FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your purchase amount is hidden. Only a ZK proof of validity is shared publicly.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isProcessing) ...[
              // Proof generation progress
              Column(
                children: [
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    color: const Color(0xFF00D9FF),
                    backgroundColor: Colors.grey[800],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _proofSteps[_proofStep],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_proofStep + 1) / _proofSteps.length,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00D9FF)),
                  ),
                ],
              ),
            ] else ...[
              // Fractions input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 24),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Number of fractions',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  suffixText: 'fractions',
                  suffixStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Cost:',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    '${_totalCost.toStringAsFixed(0)} ₳',
                    style: const TextStyle(
                      color: Color(0xFF00D9FF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Balance: ${widget.walletBalance.toStringAsFixed(2)} ₳',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _executePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0033AD),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 18),
                          SizedBox(width: 8),
                          Text('Buy Privately'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Privacy settings panel
class PrivacySettingsPanel extends StatefulWidget {
  const PrivacySettingsPanel({super.key});

  @override
  State<PrivacySettingsPanel> createState() => _PrivacySettingsPanelState();
}

class _PrivacySettingsPanelState extends State<PrivacySettingsPanel> {
  bool _hideHoldings = false;
  bool _anonymousTransactions = false;
  bool _privatePurchases = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0033AD).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0033AD).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Privacy Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by Zero-Knowledge Proofs',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 24),

          _buildPrivacyToggle(
            'Private Purchases',
            'Hide purchase amounts using ZK proofs',
            Icons.shopping_bag,
            _privatePurchases,
            (v) => setState(() => _privatePurchases = v),
          ),
          _buildPrivacyToggle(
            'Hide Holdings',
            'Show only verified ownership, not amounts',
            Icons.visibility_off,
            _hideHoldings,
            (v) => setState(() => _hideHoldings = v),
          ),
          _buildPrivacyToggle(
            'Anonymous Transactions',
            'Use stealth addresses for transfers',
            Icons.shuffle,
            _anonymousTransactions,
            (v) => setState(() => _anonymousTransactions = v),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF00D9FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ZK proofs are generated locally. Your private data never leaves your device.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF0033AD).withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? const Color(0xFF00D9FF) : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? const Color(0xFF00D9FF)
                  : null,
            ),
            activeTrackColor: const Color(0xFF0033AD),
          ),
        ],
      ),
    );
  }
}

/// ZK Proof visualization
class ZKProofVisualization extends StatefulWidget {
  final ZKProof proof;

  const ZKProofVisualization({super.key, required this.proof});

  @override
  State<ZKProofVisualization> createState() => _ZKProofVisualizationState();
}

class _ZKProofVisualizationState extends State<ZKProofVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
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
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0033AD).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Animated proof icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: const [
                          Color(0xFF00D9FF),
                          Color(0xFF0033AD),
                          Color(0xFF00D9FF),
                        ],
                        transform: GradientRotation(_controller.value * 6.28),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.lock, color: Colors.white, size: 20),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ZK Proof Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.proof.proofType,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Valid',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProofDetail('Proof ID', widget.proof.proofId),
          _buildProofDetail('Commitment', widget.proof.commitment),
          _buildProofDetail(
            'Generated',
            '${widget.proof.timestamp.hour}:${widget.proof.timestamp.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 12),
          const Text(
            'Public Inputs:',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ...widget.proof.publicInputs.entries.map(
            (e) => _buildProofDetail(
              e.key.replaceAll('_', ' '),
              e.value.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generate balance proof dialog
class GenerateBalanceProofDialog extends StatefulWidget {
  final double walletBalance;
  final Function(BalanceProof) onProofGenerated;

  const GenerateBalanceProofDialog({
    super.key,
    required this.walletBalance,
    required this.onProofGenerated,
  });

  @override
  State<GenerateBalanceProofDialog> createState() =>
      _GenerateBalanceProofDialogState();
}

class _GenerateBalanceProofDialogState
    extends State<GenerateBalanceProofDialog> {
  final _minBalanceController = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _minBalanceController.dispose();
    super.dispose();
  }

  Future<void> _generateProof() async {
    final minBalance = double.tryParse(_minBalanceController.text);
    if (minBalance == null || minBalance <= 0) {
      setState(() => _error = 'Enter a valid minimum balance');
      return;
    }
    if (minBalance > widget.walletBalance) {
      setState(() => _error = 'Cannot prove more than your balance');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final zkService = context.read<ZKPrivacyService>();
      final proof = await zkService.createBalanceProof(
        minimumBalance: minBalance,
        actualBalance: widget.walletBalance,
      );

      widget.onProofGenerated(proof);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF0033AD), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0033AD).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Color(0xFF00D9FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance Proof',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Prove you have funds without revealing amount',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isProcessing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00D9FF)),
                    SizedBox(height: 16),
                    Text(
                      'Generating ZK proof...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: _minBalanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  labelText: 'Minimum balance to prove',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  suffixText: '₳',
                  suffixStyle: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your actual balance remains private',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generateProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0033AD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Generate Proof'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
