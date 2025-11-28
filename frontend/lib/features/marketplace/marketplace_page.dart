import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/features/marketplace/widgets/property_card.dart';
import 'package:propfi/features/marketplace/widgets/buyer_info_dialog.dart';
import 'package:propfi/features/marketplace/widgets/certificate_success_dialog.dart';
import 'package:propfi/features/admin/admin_page.dart';
import 'package:propfi/services/wallet_service.dart';
import 'package:propfi/services/admin_service.dart';
import 'package:propfi/services/certificate_service.dart';

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

  // Search & Filter state
  String _searchQuery = '';
  double _minPrice = 0;
  double _maxPrice = 100000;
  String _sortBy = 'newest'; // newest, price_low, price_high, funded

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Filter and sort listings based on current criteria
  List<MarketplaceListing> _getFilteredListings(List<MarketplaceListing> listings) {
    var filtered = listings.where((listing) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!listing.propertyName.toLowerCase().contains(query) &&
            !listing.location.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Price filter
      if (listing.price < _minPrice || listing.price > _maxPrice) {
        return false;
      }
      
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'funded':
        filtered.sort((a, b) => b.fundedPercentage.compareTo(a.fundedPercentage));
        break;
      case 'newest':
      default:
        // Keep default order (newest)
        break;
    }

    return filtered;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _minPrice = 0;
                        _maxPrice = 100000;
                        _sortBy = 'newest';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Price Range
              const Text(
                'Price Range (ADA)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 100000,
                divisions: 20,
                labels: RangeLabels(
                  '${_minPrice.toInt()} ₳',
                  '${_maxPrice.toInt()} ₳',
                ),
                onChanged: (values) {
                  setSheetState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_minPrice.toInt()} ₳', style: TextStyle(color: Colors.grey[400])),
                  Text('${_maxPrice.toInt()} ₳', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 24),
              
              // Sort By
              const Text(
                'Sort By',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSortChip('Newest', 'newest', setSheetState),
                  _buildSortChip('Price: Low', 'price_low', setSheetState),
                  _buildSortChip('Price: High', 'price_high', setSheetState),
                  _buildSortChip('Most Funded', 'funded', setSheetState),
                ],
              ),
              const SizedBox(height: 24),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Refresh main page
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, StateSetter setSheetState) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setSheetState(() => _sortBy = value);
        }
      },
      selectedColor: Colors.amber,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
      ),
      backgroundColor: Colors.grey[800],
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || 
           _minPrice > 0 || 
           _maxPrice < 100000 || 
           _sortBy != 'newest';
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
              onPressed: _isBuying
                  ? null
                  : () async {
                      Navigator.pop(context); // Close the amount dialog
                      // Show buyer info dialog
                      _showBuyerInfoDialog(listing, selectedAmount);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text(
                _isBuying ? 'Processing...' : 'Continue',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show buyer info dialog to collect buyer details before purchase
  void _showBuyerInfoDialog(MarketplaceListing listing, int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BuyerInfoDialog(
        propertyName: listing.propertyName,
        fractions: amount,
        totalAmount: amount * listing.pricePerFraction,
        onConfirm: (buyerName, buyerEmail, buyerPhone) {
          _executeBuyWithCertificate(
            listing: listing,
            amount: amount,
            buyerName: buyerName,
            buyerEmail: buyerEmail,
            buyerPhone: buyerPhone,
          );
        },
      ),
    );
  }

  /// Execute buy with certificate generation
  Future<void> _executeBuyWithCertificate({
    required MarketplaceListing listing,
    required int amount,
    required String buyerName,
    String? buyerEmail,
    String? buyerPhone,
  }) async {
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
    final certificateService = CertificateService();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFD4AF37)),
              const SizedBox(height: 16),
              const Text(
                'Processing Transaction...',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Please approve in your wallet',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Use the real transaction method with buyer metadata
      final txHash = await walletService.buyFractionsReal(
        propertyId: listing.id,
        propertyName: listing.propertyName,
        amount: amount,
        pricePerFraction: listing.pricePerFraction,
        ownerWalletAddress: listing.sellerAddress,
        buyerName: buyerName,
        buyerEmail: buyerEmail,
        buyerPhone: buyerPhone,
        onSuccess: (propertyId, fractionsBought) {
          // Update admin service to record the sale
          adminService.recordSale(propertyId, fractionsBought);
        },
      );

      // Record purchase in portfolio
      await walletService.recordPurchase(
        propertyId: listing.id,
        propertyName: listing.propertyName,
        location: listing.location,
        imageUrl: listing.imageUrl,
        fractions: amount,
        totalFractions: listing.totalFractions,
        amount: amount * listing.pricePerFraction,
        txHash: txHash,
      );

      // Create the contract certificate
      final certificate = certificateService.createCertificate(
        txHash: txHash,
        propertyId: listing.id,
        propertyName: listing.propertyName,
        propertyLocation: listing.location,
        propertyDescription: listing.propertyDescription,
        propertyImageUrl: listing.imageUrl,
        propertyTotalValue: listing.price,
        totalFractions: listing.totalFractions,
        ownerName: listing.ownerName ?? 'Property Owner',
        ownerWalletAddress: listing.sellerAddress,
        ownerEmail: listing.ownerEmail,
        ownerPhone: listing.ownerPhone,
        buyerName: buyerName,
        buyerWalletAddress: walletService.walletAddress ?? '',
        buyerEmail: buyerEmail,
        buyerPhone: buyerPhone,
        fractionsPurchased: amount,
        pricePerFraction: listing.pricePerFraction,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        // Show certificate success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CertificateSuccessDialog(
            certificate: certificate,
            certificateService: certificateService,
            txHash: txHash,
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
        // Get filtered listings
        final filteredListings = _getFilteredListings(walletService.listings);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Marketplace'),
            actions: [
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: _navigateToAdmin,
                tooltip: 'Admin Panel',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadListings,
              ),
            ],
          ),
          body: Column(
            children: [
              // Header with wallet connection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
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
              
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search properties...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters() 
                            ? Colors.amber.withValues(alpha: 0.2) 
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: _hasActiveFilters() 
                            ? Border.all(color: Colors.amber) 
                            : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: _hasActiveFilters() ? Colors.amber : Colors.grey[400],
                        ),
                        onPressed: _showFilterDialog,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Active filters indicator
              if (_hasActiveFilters())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        '${filteredListings.length} results',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            _minPrice = 0;
                            _maxPrice = 100000;
                            _sortBy = 'newest';
                          });
                        },
                        child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                      ),
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
                            // Featured Section (only show if not filtering)
                            if (!_hasActiveFilters() && filteredListings.isNotEmpty) ...[
                              Text(
                                'Featured Properties',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 16),

                              PropertyCard(
                                title: filteredListings.first.propertyName,
                                location: filteredListings.first.location,
                                imageUrl: filteredListings.first.imageUrl,
                                price: filteredListings.first.price,
                                apy: 8.5,
                                fundedPercentage: filteredListings.first.fundedPercentage,
                                fundsRaised: filteredListings.first.fundsRaised,
                                targetAmount: filteredListings.first.targetAmount,
                                onTap: () => _showBuyDialog(filteredListings.first),
                              ),

                              const SizedBox(height: 24),
                            ],

                            // All Listings
                            Text(
                              _hasActiveFilters() ? 'Search Results' : 'All Listings',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            if (filteredListings.isEmpty)
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
                                        _hasActiveFilters() 
                                            ? 'No properties match your search'
                                            : 'No listings available',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 18,
                                        ),
                                        textAlign: TextAlign.center,
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
                                itemCount: filteredListings.length,
                                itemBuilder: (context, index) {
                                  final listing = filteredListings[index];
                                  return PropertyCard(
                                    title: listing.propertyName,
                                    location: listing.location,
                                    imageUrl: listing.imageUrl,
                                    price: listing.price,
                                    apy: 7.2 + index,
                                    fundedPercentage: listing.fundedPercentage,
                                    fundsRaised: listing.fundsRaised,
                                    targetAmount: listing.targetAmount,
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
            color: Colors.green.withValues(alpha: 0.2),
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
