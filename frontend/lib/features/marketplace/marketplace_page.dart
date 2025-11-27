import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/features/marketplace/widgets/property_card.dart';
import 'package:propfi/features/admin/admin_page.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/services/admin_service.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  bool _isLoading = false;
  bool _isBuying = false; // Guard against double-tap on Buy button
  String? _error;
  List<CardanoWallet> _availableWallets = [];

  @override
  void initState() {
    super.initState();
    _initializeMarketplace();
  }

  Future<void> _initializeMarketplace() async {
    // Wait a bit for wallets to inject (they load after page)
    await Future.delayed(const Duration(milliseconds: 500));

    // Check for wallets
    if (mounted) {
      final walletService = context.read<WalletService>();
      _availableWallets = await walletService.detectWallets();
      setState(() {});
    }

    // Load listings
    await _loadListings();
  }

  Future<void> _loadListings() async {
    if (!mounted) return;

    final walletService = context.read<WalletService>();
    final adminService = context.read<AdminService>();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Refresh on-chain properties first
      await adminService.refresh();
      
      // Pass admin's listed properties to wallet service (includes on-chain)
      final listedProperties = adminService.listedProperties;
      await walletService.fetchListings(adminProperties: listedProperties);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showConnectWalletDialog() async {
    final walletService = context.read<WalletService>();

    // Refresh available wallets (in case they loaded late)
    _availableWallets = walletService.getAvailableWallets();

    if (_availableWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No Cardano wallets detected. Please install Nami, Eternl, or another wallet.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      // For demo, allow simulated connection
      await _connectWallet(CardanoWallet.nami);
      return;
    }

    await showModalBottomSheet<CardanoWallet>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect Wallet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a wallet to connect',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ..._availableWallets.map(
              (wallet) => ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                ),
                title: Text(
                  wallet.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _connectWallet(wallet);
                },
              ),
            ),
            if (_availableWallets.isEmpty)
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                ),
                title: const Text(
                  'Nami (Demo Mode)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _connectWallet(CardanoWallet.nami);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectWallet(CardanoWallet wallet) async {
    final walletService = context.read<WalletService>();

    final success = await walletService.connectWallet(wallet);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${wallet.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${walletService.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBuyDialog(MarketplaceListing listing) async {
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

    int selectedAmount = 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('Buy Fractions', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.propertyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(listing.location, style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              Text(
                'Price per fraction: ${listing.pricePerFraction.toStringAsFixed(2)} ADA',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Amount: ', style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: selectedAmount > 1
                        ? () => setDialogState(() => selectedAmount--)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$selectedAmount',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: selectedAmount < listing.fractionsAvailable
                        ? () => setDialogState(() => selectedAmount++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Total: ${(listing.pricePerFraction * selectedAmount).toStringAsFixed(2)} ADA',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment will be sent to property owner',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isBuying ? null : () async {
                Navigator.pop(context); // Close the dialog first
                await _executeBuy(listing, selectedAmount);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text(_isBuying ? 'Processing...' : 'Buy', style: const TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeBuy(MarketplaceListing listing, int amount) async {
    // Prevent double-tap
    if (_isBuying) {
      debugPrint('Buy already in progress, ignoring duplicate tap');
      return;
    }
    
    setState(() {
      _isBuying = true;
    });

    final walletService = context.read<WalletService>();
    final adminService = context.read<AdminService>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      // Use the new real transaction method
      final txHash = await walletService.buyFractionsReal(
        propertyId: listing.id,
        amount: amount,
        pricePerFraction: listing.pricePerFraction,
        ownerWalletAddress: listing.sellerAddress,
        onSuccess: (propertyId, fractionsBought) {
          // Update admin service to record the sale
          adminService.recordSale(propertyId, fractionsBought);
        },
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaction submitted! TX Hash: ${txHash.substring(0, 16)}...',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Refresh listings
        await _loadListings();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuying = false;
        });
      }
    }
  }

  void _navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WalletService, AdminService>(
      builder: (context, walletService, adminService, child) {
        // Listen to admin service changes and refresh listings
        return Scaffold(
          appBar: AppBar(
            title: const Text('Marketplace'),
            actions: [
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: _navigateToAdmin,
                tooltip: 'Admin Panel',
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadListings),
            ],
          ),
          body: Column(
            children: [
              // Header with wallet connection
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Marketplace',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    _buildWalletButton(walletService),
                  ],
                ),
              ),

              // Listings
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading listings',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadListings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadListings,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Featured Section
                            Text(
                              'Featured Properties',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            if (walletService.listings.isNotEmpty)
                              PropertyCard(
                                title:
                                    walletService.listings.first.propertyName,
                                location: walletService.listings.first.location,
                                imageUrl: walletService.listings.first.imageUrl,
                                price: walletService.listings.first.price,
                                apy: 8.5,
                                fundedPercentage: walletService
                                    .listings
                                    .first
                                    .fundedPercentage,
                                onTap: () => _showBuyDialog(
                                  walletService.listings.first,
                                ),
                              ),

                            const SizedBox(height: 24),

                            // All Listings
                            Text(
                              'All Listings',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            if (walletService.listings.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.home_work_outlined,
                                        size: 64,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No listings available',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.1,
                                    ),
                                itemCount: walletService.listings.length,
                                itemBuilder: (context, index) {
                                  final listing = walletService.listings[index];
                                  return PropertyCard(
                                    title: listing.propertyName,
                                    location: listing.location,
                                    imageUrl: listing.imageUrl,
                                    price: listing.price,
                                    apy: 7.2 + index,
                                    fundedPercentage: listing.fundedPercentage,
                                    onTap: () => _showBuyDialog(listing),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletButton(WalletService walletService) {
    if (walletService.status == WalletConnectionStatus.connecting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
      );
    }

    if (walletService.isConnected) {
      return PopupMenuButton<String>(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                _truncateAddress(walletService.walletAddress ?? ''),
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'address',
            child: Row(
              children: [
                const Icon(Icons.content_copy, size: 16),
                const SizedBox(width: 8),
                Text('Copy Address'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'disconnect',
            child: Row(
              children: [
                const Icon(Icons.logout, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Disconnect', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'disconnect') {
            walletService.disconnectWallet();
          } else if (value == 'address') {
            // Copy to clipboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address copied to clipboard')),
            );
          }
        },
      );
    }

    return ElevatedButton.icon(
      onPressed: _showConnectWalletDialog,
      icon: const Icon(Icons.account_balance_wallet, size: 18),
      label: const Text('Connect Wallet'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 15) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }
}
