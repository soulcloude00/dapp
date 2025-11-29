import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/services/admin_service.dart';
import 'package:propfi/services/wallet_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _totalValueController = TextEditingController();
  final _totalFractionsController = TextEditingController(text: '1000');
  final _pricePerFractionController = TextEditingController();
  final _legalDocCIDController = TextEditingController();

  bool _isSubmitting = false;
  bool _useConnectedWallet = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _totalValueController.dispose();
    _totalFractionsController.dispose();
    _pricePerFractionController.dispose();
    _legalDocCIDController.dispose();
    super.dispose();
  }

  void _calculatePricePerFraction() {
    final totalValue = double.tryParse(_totalValueController.text) ?? 0;
    final totalFractions = int.tryParse(_totalFractionsController.text) ?? 1000;
    if (totalValue > 0 && totalFractions > 0) {
      final pricePerFraction = totalValue / totalFractions;
      _pricePerFractionController.text = pricePerFraction.toStringAsFixed(2);
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    final walletService = context.read<WalletService>();
    final adminService = context.read<AdminService>();

    // Get owner wallet address
    String ownerWallet;
    if (_useConnectedWallet) {
      if (!walletService.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect your wallet first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      ownerWallet = walletService.walletAddress!;
    } else {
      ownerWallet = adminService.adminWalletAddress ?? '';
      if (ownerWallet.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set an admin wallet address'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final property = await adminService.addProperty(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        totalValue: double.parse(_totalValueController.text),
        totalFractions: int.parse(_totalFractionsController.text),
        pricePerFraction: double.parse(_pricePerFractionController.text),
        ownerWalletAddress: ownerWallet,
        legalDocumentCID: _legalDocCIDController.text.trim().isEmpty
            ? null
            : _legalDocCIDController.text.trim(),
      );

      // Clear form
      _nameController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _imageUrlController.clear();
      _totalValueController.clear();
      _totalFractionsController.text = '1000';
      _pricePerFractionController.clear();
      _legalDocCIDController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property "${property.name}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<WalletService>();
    final adminService = context.watch<AdminService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Admin - Add Property'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (walletService.isConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${walletService.walletAddress?.substring(0, 12)}...',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Connection Section
            _buildWalletSection(walletService),
            const SizedBox(height: 32),

            // Property Form
            _buildPropertyForm(walletService),

            const SizedBox(height: 32),

            // Existing Properties List
            _buildPropertiesList(adminService),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection(WalletService walletService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your wallet to receive payments when users buy fractions',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (!walletService.isConnected)
            ElevatedButton.icon(
              onPressed: () => _showConnectWalletDialog(walletService),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Connect Wallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connected: ${walletService.connectedWallet?.displayName ?? "Wallet"}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              walletService.walletAddress ?? '',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        onPressed: walletService.disconnectWallet,
                        tooltip: 'Disconnect',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: _useConnectedWallet,
                      onChanged: (v) => setState(() => _useConnectedWallet = v),
                      thumbColor: MaterialStateProperty.resolveWith(
                        (states) => states.contains(MaterialState.selected)
                            ? const Color(0xFF6C63FF)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Use connected wallet for payments',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyForm(WalletService walletService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Property',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Property Name
            _buildTextField(
              controller: _nameController,
              label: 'Property Name',
              hint: 'e.g., Luxury Penthouse Manhattan',
              icon: Icons.home,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe the property...',
              icon: Icons.description,
              maxLines: 3,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'e.g., New York, NY',
              icon: Icons.location_on,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Image URL
            _buildTextField(
              controller: _imageUrlController,
              label: 'Image URL',
              hint: 'https://... or ipfs://...',
              icon: Icons.image,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Total Value and Fractions Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _totalValueController,
                    label: 'Total Value (USD)',
                    hint: 'e.g., 1000000',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculatePricePerFraction(),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _totalFractionsController,
                    label: 'Total Fractions',
                    hint: 'e.g., 1000',
                    icon: Icons.pie_chart,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculatePricePerFraction(),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Required';
                      if (int.tryParse(v!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price Per Fraction (auto-calculated)
            _buildTextField(
              controller: _pricePerFractionController,
              label: 'Price Per Fraction (ADA)',
              hint: 'Auto-calculated',
              icon: Icons.currency_exchange,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty == true) return 'Required';
                if (double.tryParse(v!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Legal Document CID (optional)
            _buildTextField(
              controller: _legalDocCIDController,
              label: 'Legal Document IPFS CID (Optional)',
              hint: 'QmXxx... or bafyxxx...',
              icon: Icons.gavel,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProperty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Add Property',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildPropertiesList(AdminService adminService) {
    if (adminService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (adminService.properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No properties added yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first property using the form above',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Properties',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  '${adminService.onChainProperties.length} on-chain, ${adminService.localProperties.length} local',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: () => adminService.refresh(),
                  tooltip: 'Refresh from blockchain',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...adminService.properties.map(
          (property) => _buildPropertyCard(property, adminService),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(Property property, AdminService adminService) {
    final bool isOnChain = property.isOnChain;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnChain
              ? Colors.blue.withValues(alpha: 0.3)
              : property.isListed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  property.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[800],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isOnChain)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.link, size: 12, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  'ON-CHAIN',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (property.isListed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LISTED',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DRAFT',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.location,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${property.totalValue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${property.fractionsAvailable}/${property.totalFractions} fractions',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (property.txHash != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'TX: ${property.txHash!.substring(0, 20)}...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  if (!isOnChain)
                    IconButton(
                      icon: const Icon(Icons.cloud_upload, color: Colors.blue),
                      onPressed: () => _listOnChain(property, adminService),
                      tooltip: 'List On-Chain (Decentralized)',
                    ),
                  if (!isOnChain)
                    IconButton(
                      icon: Icon(
                        property.isListed
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: property.isListed ? Colors.orange : Colors.green,
                      ),
                      onPressed: () {
                        if (property.isListed) {
                          adminService.unlistProperty(property.id);
                        } else {
                          adminService.listProperty(property.id);
                        }
                      },
                      tooltip: property.isListed
                          ? 'Unlist'
                          : 'List on Marketplace',
                    ),
                  if (!isOnChain)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(property, adminService),
                      tooltip: 'Delete',
                    ),
                  if (isOnChain && property.txHash != null) ...[
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.grey),
                      onPressed: () => _viewOnExplorer(property.txHash!),
                      tooltip: 'View on Explorer',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: () =>
                          _resetFailedListing(property, adminService),
                      tooltip: 'Reset (TX Failed)',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _listOnChain(
    Property property,
    AdminService adminService,
  ) async {
    final walletService = context.read<WalletService>();

    if (!walletService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your wallet first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue),
            SizedBox(width: 8),
            Text('List On-Chain?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will list "${property.name}" on the blockchain.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ Property metadata stored on Cardano',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '✓ Decentralized and immutable',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '✓ Requires ~2 ADA for transaction',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('List On-Chain'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Listing property on-chain...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );
    }

    final txHash = await adminService.listPropertyOnChain(property.id);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (txHash != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Property listed on-chain! TX: ${txHash.substring(0, 20)}...',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => _viewOnExplorer(txHash),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${adminService.lastError ?? "Unknown error"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewOnExplorer(String txHash) {
    // Open Cardano explorer for preprod
    final url = 'https://preprod.cardanoscan.io/transaction/$txHash';
    // Use url_launcher or similar
    debugPrint('View TX: $url');
    // For now just show in snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Explorer: $url'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Copy to clipboard
          },
        ),
      ),
    );
  }

  Future<void> _resetFailedListing(
    Property property,
    AdminService adminService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text(
          'Reset Failed Listing?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will clear the transaction hash for "${property.name}" so you can try listing again.\n\nOnly use this if the transaction failed to confirm on the blockchain.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await adminService.resetOnChainStatus(property.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property reset to draft. You can try listing again.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    Property property,
    AdminService adminService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text(
          'Delete Property?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${property.name}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      adminService.deleteProperty(property.id);
    }
  }

  Future<void> _showConnectWalletDialog(WalletService walletService) async {
    final availableWallets = await walletService.detectWallets();

    if (!mounted) return;

    if (availableWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No Cardano wallets detected. Please install Nami, Eternl, or another wallet.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect Wallet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...availableWallets.map(
              (wallet) => ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF6C63FF),
                ),
                title: Text(
                  wallet.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await walletService.connectWallet(wallet);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
