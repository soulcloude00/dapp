import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports for web platform JS interop
import 'js_stub.dart' if (dart.library.html) 'js_web.dart' as js;
import 'js_util_stub.dart' if (dart.library.html) 'js_util_web.dart' as js_util;

/// Contract configuration from deployed contracts
class ContractConfig {
  static const String network = 'preprod';
  static const String fractionalizeScriptHash =
      '4e03e3aacbb838b267ee6dcccdaffebff835a3a8cf51d9870e5a6b2e';
  static const String cip68MintingPolicyId =
      '7af62086280f10305eec66f17afff08526513d5b41549cb63bd1e4ca';
  static const String marketplaceScriptHash =
      'a763ffb61095577404d7594b17475e8db0d3b3a2595fa82e93642225';

  // Stablecoin configs (Preprod placeholders)
  static const String usdmPolicyId =
      'c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad';
  static const String usdmAssetName = '5553444d'; // "USDM" in hex
}

/// Supported Cardano wallets
enum CardanoWallet {
  nami('nami', 'Nami'),
  eternl('eternl', 'Eternl'),
  flint('flint', 'Flint'),
  yoroi('yoroi', 'Yoroi'),
  lace('lace', 'Lace'),
  typhon('typhon', 'Typhon');

  final String id;
  final String displayName;
  const CardanoWallet(this.id, this.displayName);
}

/// Wallet connection status
enum WalletConnectionStatus { disconnected, connecting, connected, error }

/// Represents a marketplace listing
class MarketplaceListing {
  final String id;
  final String propertyName;
  final String propertyDescription;
  final String location;
  final String imageUrl;
  final double price;
  final int fractionsAvailable;
  final int totalFractions;
  final double pricePerFraction;
  final String sellerAddress;
  final String fractionPolicyId;
  final String fractionTokenName;
  final String txHash;
  final int outputIndex;
  
  // Owner details for certificate
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;

  MarketplaceListing({
    required this.id,
    required this.propertyName,
    this.propertyDescription = '',
    required this.location,
    required this.imageUrl,
    required this.price,
    required this.fractionsAvailable,
    required this.totalFractions,
    required this.pricePerFraction,
    required this.sellerAddress,
    required this.fractionPolicyId,
    required this.fractionTokenName,
    required this.txHash,
    required this.outputIndex,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
  });

  double get fundedPercentage =>
      (totalFractions - fractionsAvailable) / totalFractions;
  
  int get fractionsSold => totalFractions - fractionsAvailable;
  double get fundsRaised => fractionsSold * pricePerFraction;
  double get targetAmount => totalFractions * pricePerFraction;
}

/// Transaction types for history
enum TransactionType { buy, sell, receive, send }

/// Represents a property holding in user's portfolio
class PropertyHolding {
  final String propertyId;
  final String propertyName;
  final String location;
  final String imageUrl;
  final int fractionsOwned;
  final int totalFractions;
  final double purchasePrice;
  final double currentValue;
  final DateTime purchaseDate;

  PropertyHolding({
    required this.propertyId,
    required this.propertyName,
    required this.location,
    required this.imageUrl,
    required this.fractionsOwned,
    required this.totalFractions,
    required this.purchasePrice,
    required this.currentValue,
    required this.purchaseDate,
  });

  double get ownershipPercentage => (fractionsOwned / totalFractions) * 100;
  double get profitLoss => ((currentValue - purchasePrice) / purchasePrice) * 100;

  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    'propertyName': propertyName,
    'location': location,
    'imageUrl': imageUrl,
    'fractionsOwned': fractionsOwned,
    'totalFractions': totalFractions,
    'purchasePrice': purchasePrice,
    'currentValue': currentValue,
    'purchaseDate': purchaseDate.toIso8601String(),
  };

  factory PropertyHolding.fromJson(Map<String, dynamic> json) => PropertyHolding(
    propertyId: json['propertyId'],
    propertyName: json['propertyName'],
    location: json['location'],
    imageUrl: json['imageUrl'] ?? '',
    fractionsOwned: json['fractionsOwned'],
    totalFractions: json['totalFractions'],
    purchasePrice: (json['purchasePrice'] as num).toDouble(),
    currentValue: (json['currentValue'] as num).toDouble(),
    purchaseDate: DateTime.parse(json['purchaseDate']),
  );
}

/// Represents a transaction in history
class TransactionRecord {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final String? propertyName;
  final int? fractions;
  final String? txHash;

  TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.propertyName,
    this.fractions,
    this.txHash,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'propertyName': propertyName,
    'fractions': fractions,
    'txHash': txHash,
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) => TransactionRecord(
    id: json['id'],
    type: TransactionType.values.firstWhere((e) => e.name == json['type']),
    amount: (json['amount'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
    propertyName: json['propertyName'],
    fractions: json['fractions'],
    txHash: json['txHash'],
  );
}

/// Service to handle wallet connection and transaction signing
/// Uses JS interop for web platform to connect to browser-based wallets
class WalletService extends ChangeNotifier {
  WalletConnectionStatus _status = WalletConnectionStatus.disconnected;
  String? _walletAddress;
  String? _walletPkh; // Payment key hash
  CardanoWallet? _connectedWallet;
  String? _errorMessage;
  dynamic _walletApi;

  // Marketplace listings cache
  List<MarketplaceListing> _listings = [];

  // Portfolio data
  List<PropertyHolding> _holdings = [];
  List<TransactionRecord> _transactions = [];

  // RPG Stats
  int _userLevel = 1;
  int _userXp = 0;
  double _balance = 0.0;

  // Profile Data
  bool _isLoggedIn = false;
  String _userName = 'CryptoTycoon';
  String _userBio = 'Real Estate Mogul';

  // Getters
  WalletConnectionStatus get status => _status;
  bool get isConnected => _status == WalletConnectionStatus.connected;
  String? get walletAddress => _walletAddress;
  String? get walletPkh => _walletPkh;
  CardanoWallet? get connectedWallet => _connectedWallet;
  String? get errorMessage => _errorMessage;
  List<MarketplaceListing> get listings => _listings;

  // Portfolio getters
  List<PropertyHolding> get holdings => _holdings;
  List<TransactionRecord> get transactionHistory => _transactions;
  double get portfolioValue => _holdings.fold(0.0, (sum, h) => sum + h.currentValue);

  int get userLevel => _userLevel;
  int get userXp => _userXp;
  double get balance => _balance;
  int get nextLevelXp => _userLevel * 1000;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userBio => _userBio;

  WalletService() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userLevel = prefs.getInt('userLevel') ?? 1;
    _userXp = prefs.getInt('userXp') ?? 0;
    _userName = prefs.getString('userName') ?? 'CryptoTycoon';
    _userBio = prefs.getString('userBio') ?? 'Real Estate Mogul';
    await _loadPortfolio();
    notifyListeners();
  }

  Future<void> _loadPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Debug: Check what's in storage
    final allKeys = prefs.getKeys();
    debugPrint('SharedPreferences keys: $allKeys');
    
    // Load holdings using JSON
    final holdingsJsonStr = prefs.getString('holdings_json');
    debugPrint('Raw holdings_json from storage: $holdingsJsonStr');
    
    if (holdingsJsonStr != null && holdingsJsonStr.isNotEmpty && holdingsJsonStr != '[]') {
      try {
        final holdingsList = jsonDecode(holdingsJsonStr) as List;
        _holdings = holdingsList.map((json) {
          try {
            return PropertyHolding.fromJson(Map<String, dynamic>.from(json));
          } catch (e) {
            debugPrint('Error parsing holding: $e');
            return null;
          }
        }).whereType<PropertyHolding>().toList();
        debugPrint('Loaded ${_holdings.length} holdings from storage');
      } catch (e) {
        debugPrint('Error loading holdings: $e');
        _holdings = [];
      }
    } else {
      debugPrint('No holdings found in storage');
      _holdings = [];
    }

    // Load transactions using JSON
    final txJsonStr = prefs.getString('transactions_json');
    if (txJsonStr != null && txJsonStr.isNotEmpty && txJsonStr != '[]') {
      try {
        final txList = jsonDecode(txJsonStr) as List;
        _transactions = txList.map((json) {
          try {
            return TransactionRecord.fromJson(Map<String, dynamic>.from(json));
          } catch (e) {
            debugPrint('Error parsing transaction: $e');
            return null;
          }
        }).whereType<TransactionRecord>().toList();
        debugPrint('Loaded ${_transactions.length} transactions from storage');
      } catch (e) {
        debugPrint('Error loading transactions: $e');
        _transactions = [];
      }
    } else {
      _transactions = [];
    }

    // Sort transactions by date (newest first)
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Load sale records
    final saleRecordsStr = prefs.getString('sale_records_json') ?? '[]';
    try {
      final saleList = jsonDecode(saleRecordsStr) as List;
      debugPrint('Loaded ${saleList.length} sale records');
    } catch (e) {
      debugPrint('Error loading sale records: $e');
    }
  }

  Future<void> _savePortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save holdings as JSON
    final holdingsJson = _holdings.map((h) => h.toJson()).toList();
    await prefs.setString('holdings_json', jsonEncode(holdingsJson));
    debugPrint('Saved ${_holdings.length} holdings to storage');

    // Save transactions as JSON
    final txJson = _transactions.map((t) => t.toJson()).toList();
    await prefs.setString('transactions_json', jsonEncode(txJson));
    debugPrint('Saved ${_transactions.length} transactions to storage');
  }

  /// Sync holdings from on-chain data by checking wallet assets
  /// Note: In direct payment mode, holdings are tracked locally, not as tokens
  Future<void> syncHoldingsFromChain() async {
    if (!kIsWeb || !isConnected) return;

    try {
      debugPrint('Syncing holdings from blockchain...');
      
      // Get wallet assets
      final assets = await getWalletAssets();
      final tokens = assets['tokens'] as Map<String, dynamic>? ?? {};
      
      debugPrint('Found ${tokens.length} token types in wallet');
      debugPrint('Current local holdings: ${_holdings.length}');
      
      // In direct payment mode, fraction tokens may not be in the wallet
      // Holdings are tracked locally via recordPurchase
      // This sync is for when actual fraction tokens are received
      
      if (tokens.isEmpty) {
        debugPrint('No tokens found - using locally saved holdings');
        return;
      }
      
      // Get on-chain properties to match tokens with property names
      final window = js.webWindow;
      if (window == null) return;
      
      if (!js_util.hasProperty(window, 'PropFiBridge')) return;
      final bridge = js_util.getProperty(window, 'PropFiBridge');
      
      // Fetch property metadata from chain
      Map<String, dynamic> propertyMetadata = {};
      if (js_util.hasProperty(bridge, 'fetchOnChainPropertiesJson')) {
        try {
          final promise = js_util.callMethod(bridge, 'fetchOnChainPropertiesJson', []);
          final jsonStr = await js_util.promiseToFuture(promise);
          if (jsonStr != null && jsonStr is String) {
            final properties = jsonDecode(jsonStr) as List;
            for (final prop in properties) {
              final propId = prop['propertyId'] as String?;
              if (propId != null) {
                propertyMetadata[propId] = prop;
              }
            }
            debugPrint('Fetched ${propertyMetadata.length} property metadata records');
          }
        } catch (e) {
          debugPrint('Error fetching property metadata: $e');
        }
      }
      
      // Match tokens with fraction policy
      final fractionPolicyId = ContractConfig.cip68MintingPolicyId;
      int tokensMatched = 0;
      
      for (final entry in tokens.entries) {
        final assetId = entry.key;
        final amount = int.tryParse(entry.value.toString()) ?? 0;
        
        debugPrint('Checking token: $assetId with amount: $amount');
        
        // Check if this is a fraction token (starts with our policy ID)
        if (assetId.startsWith(fractionPolicyId) && amount > 0) {
          tokensMatched++;
          // Extract property ID from asset name
          final assetName = assetId.substring(fractionPolicyId.length);
          // CIP-68 reference token starts with 000de140
          String propertyId = assetName;
          if (assetName.startsWith('000de140')) {
            propertyId = assetName.substring(8); // Remove prefix
          } else if (assetName.startsWith('000643b0')) {
            propertyId = assetName.substring(8); // User token prefix
          }
          
          debugPrint('Found fraction token: $propertyId with $amount fractions');
          
          // Look up property info
          final propInfo = propertyMetadata[propertyId];
          final propName = propInfo?['name'] ?? 'Property $propertyId';
          final propLocation = propInfo?['location'] ?? 'Unknown';
          final propImage = propInfo?['image'] ?? '';
          final totalFractions = int.tryParse(propInfo?['totalFractions']?.toString() ?? '1000') ?? 1000;
          final pricePerFraction = double.tryParse(propInfo?['pricePerFraction']?.toString() ?? '10') ?? 10.0;
          
          // Update or add holding
          final existingIndex = _holdings.indexWhere((h) => h.propertyId == propertyId);
          
          if (existingIndex >= 0) {
            // Update existing holding with on-chain amount
            final existing = _holdings[existingIndex];
            _holdings[existingIndex] = PropertyHolding(
              propertyId: propertyId,
              propertyName: propName,
              location: propLocation,
              imageUrl: propImage,
              fractionsOwned: amount,
              totalFractions: totalFractions,
              purchasePrice: existing.purchasePrice,
              currentValue: amount * pricePerFraction,
              purchaseDate: existing.purchaseDate,
            );
          } else {
            // Add new holding from chain
            _holdings.add(PropertyHolding(
              propertyId: propertyId,
              propertyName: propName,
              location: propLocation,
              imageUrl: propImage,
              fractionsOwned: amount,
              totalFractions: totalFractions,
              purchasePrice: amount * pricePerFraction,
              currentValue: amount * pricePerFraction,
              purchaseDate: DateTime.now(),
            ));
          }
        }
      }
      
      debugPrint('Matched $tokensMatched fraction tokens from wallet');
      
      if (tokensMatched > 0) {
        await _savePortfolio();
      }
      
      debugPrint('Holdings synced: ${_holdings.length} properties owned');
      notifyListeners();
      debugPrint('Holdings synced: ${_holdings.length} properties owned');
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing holdings from chain: $e');
    }
  }

  /// Fetch purchases from on-chain metadata (decentralized storage)
  /// This queries the blockchain for transactions with Crestadel purchase metadata
  Future<void> fetchOnChainPurchases() async {
    if (_status != WalletConnectionStatus.connected || !kIsWeb) return;
    
    try {
      debugPrint('Fetching on-chain purchases from blockchain metadata...');
      
      final bridge = js.context['PropFiBridge'];
      if (bridge == null) {
        debugPrint('PropFiBridge not available');
        return;
      }
      
      // Check if function exists
      if (!js_util.hasProperty(bridge, 'fetchUserPurchasesJson')) {
        debugPrint('fetchUserPurchasesJson not available in bridge');
        return;
      }
      
      // Call the bridge to fetch on-chain purchases
      final fetchPromise = js_util.callMethod(bridge, 'fetchUserPurchasesJson', []);
      final purchasesJsonStr = await js_util.promiseToFuture<String?>(fetchPromise);
      
      if (purchasesJsonStr == null || purchasesJsonStr.isEmpty) {
        debugPrint('No on-chain purchases found');
        return;
      }
      
      debugPrint('On-chain purchases JSON: $purchasesJsonStr');
      
      final List<dynamic> purchases = jsonDecode(purchasesJsonStr);
      debugPrint('Found ${purchases.length} on-chain purchases');
      
      // Property metadata for lookup
      final propertyMetadata = {
        'prop_tower_1': {
          'name': 'Skyline Tower',
          'location': 'Downtown, New York',
          'image': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400',
          'totalFractions': '1000',
          'pricePerFraction': '50',
        },
        'prop_marina_2': {
          'name': 'Marina Bay Residences',
          'location': 'Marina Bay, Singapore',
          'image': 'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=400',
          'totalFractions': '500',
          'pricePerFraction': '100',
        },
        'prop_lux_3': {
          'name': 'Luxury Apartments',
          'location': 'Beverly Hills, CA',
          'image': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400',
          'totalFractions': '2000',
          'pricePerFraction': '25',
        },
      };
      
      for (final purchase in purchases) {
        final propertyId = purchase['propertyId']?.toString() ?? '';
        final propertyName = purchase['propertyName']?.toString() ?? 'Unknown Property';
        final fractions = int.tryParse(purchase['fractions']?.toString() ?? '0') ?? 0;
        final priceAda = double.tryParse(purchase['priceAda']?.toString() ?? '0') ?? 0.0;
        final timestamp = purchase['timestamp']?.toString() ?? '';
        // txHash available in purchase['txHash'] if needed
        
        if (propertyId.isEmpty || fractions <= 0) continue;
        
        debugPrint('Processing on-chain purchase: $propertyName, $fractions fractions at $priceAda ADA');
        
        // Look up property info or use stored values
        final propInfo = propertyMetadata[propertyId];
        final location = propInfo?['location'] ?? 'Unknown Location';
        final imageUrl = propInfo?['image'] ?? '';
        final totalFractions = int.tryParse(propInfo?['totalFractions']?.toString() ?? '1000') ?? 1000;
        
        // Parse timestamp
        DateTime purchaseDate = DateTime.now();
        if (timestamp.isNotEmpty) {
          try {
            purchaseDate = DateTime.parse(timestamp);
          } catch (e) {
            debugPrint('Could not parse timestamp: $timestamp');
          }
        }
        
        // Find existing holding or create new
        final existingIndex = _holdings.indexWhere((h) => h.propertyId == propertyId);
        
        if (existingIndex >= 0) {
          // Update existing - add fractions if this is a new transaction
          final existing = _holdings[existingIndex];
          // Check if we already processed this transaction (by comparing total fractions)
          if (existing.fractionsOwned < fractions) {
            _holdings[existingIndex] = PropertyHolding(
              propertyId: propertyId,
              propertyName: propertyName,
              location: location,
              imageUrl: imageUrl,
              fractionsOwned: fractions, // Use the on-chain value
              totalFractions: totalFractions,
              purchasePrice: priceAda,
              currentValue: priceAda,
              purchaseDate: purchaseDate,
            );
            debugPrint('Updated holding from on-chain: $fractions fractions');
          }
        } else {
          // Add new holding from on-chain data
          _holdings.add(PropertyHolding(
            propertyId: propertyId,
            propertyName: propertyName,
            location: location,
            imageUrl: imageUrl,
            fractionsOwned: fractions,
            totalFractions: totalFractions,
            purchasePrice: priceAda,
            currentValue: priceAda,
            purchaseDate: purchaseDate,
          ));
          debugPrint('Added new holding from on-chain: $propertyName with $fractions fractions');
        }
      }
      
      if (purchases.isNotEmpty) {
        await _savePortfolio();
        notifyListeners();
      }
      
      debugPrint('On-chain purchases sync complete. Total holdings: ${_holdings.length}');
    } catch (e) {
      debugPrint('Error fetching on-chain purchases: $e');
    }
  }

  /// Record a property purchase
  Future<void> recordPurchase({
    required String propertyId,
    required String propertyName,
    required String location,
    required String imageUrl,
    required int fractions,
    required int totalFractions,
    required double amount,
    String? txHash,
  }) async {
    debugPrint('Recording purchase: $propertyName, $fractions fractions, $amount ADA');
    
    // Find existing holding or create new
    final existingIndex = _holdings.indexWhere((h) => h.propertyId == propertyId);
    
    if (existingIndex >= 0) {
      final existing = _holdings[existingIndex];
      _holdings[existingIndex] = PropertyHolding(
        propertyId: propertyId,
        propertyName: propertyName,
        location: location,
        imageUrl: imageUrl,
        fractionsOwned: existing.fractionsOwned + fractions,
        totalFractions: totalFractions,
        purchasePrice: existing.purchasePrice + amount,
        currentValue: existing.currentValue + amount,
        purchaseDate: existing.purchaseDate,
      );
      debugPrint('Updated existing holding: now owns ${existing.fractionsOwned + fractions} fractions');
    } else {
      _holdings.add(PropertyHolding(
        propertyId: propertyId,
        propertyName: propertyName,
        location: location,
        imageUrl: imageUrl,
        fractionsOwned: fractions,
        totalFractions: totalFractions,
        purchasePrice: amount,
        currentValue: amount,
        purchaseDate: DateTime.now(),
      ));
      debugPrint('Added new holding: $propertyName with $fractions fractions');
    }

    // Add transaction record
    _transactions.insert(0, TransactionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.buy,
      amount: amount,
      timestamp: DateTime.now(),
      propertyName: propertyName,
      fractions: fractions,
      txHash: txHash,
    ));

    await _savePortfolio();
    debugPrint('Portfolio saved. Total holdings: ${_holdings.length}');
    notifyListeners();
  }

  Future<void> completeLogin() async {
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    notifyListeners();
  }

  Future<void> saveProfile(String name, String bio) async {
    _userName = name;
    _userBio = bio;
    _isLoggedIn = true; // Saving profile implies logging in
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userBio', bio);
    await prefs.setBool('isLoggedIn', true);
    notifyListeners();
  }

  Future<void> _saveRpgStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userLevel', _userLevel);
    await prefs.setInt('userXp', _userXp);
  }

  /// Check which wallets are available in the browser
  List<CardanoWallet> getAvailableWallets() {
    if (!kIsWeb) return [];

    final available = <CardanoWallet>[];

    try {
      final window = js.webWindow;
      if (window == null) return [];

      // Try via PropFiBridge first (most robust)
      if (js_util.hasProperty(window, 'PropFiBridge')) {
        final bridge = js_util.getProperty(window, 'PropFiBridge');
        if (js_util.hasProperty(bridge, 'getAvailableWallets')) {
          final walletsJs = js_util.callMethod(
            bridge,
            'getAvailableWallets',
            [],
          );
          if (walletsJs is List) {
            for (final wId in walletsJs) {
              try {
                final wallet = CardanoWallet.values.firstWhere(
                  (w) => w.id == wId,
                );
                if (!available.contains(wallet)) available.add(wallet);
              } catch (_) {}
            }
            if (available.isNotEmpty) {
              debugPrint(
                'PropFiBridge detected wallets: ${available.map((w) => w.displayName).join(", ")}',
              );
              return available;
            }
          }
        }
      }

      // Fallback to manual detection
      if (!js_util.hasProperty(window, 'cardano')) {
        debugPrint('window.cardano is null - no Cardano wallets detected');
        return [];
      }

      final cardano = js_util.getProperty(window, 'cardano');
      debugPrint('window.cardano found, checking for wallets...');

      for (final wallet in CardanoWallet.values) {
        try {
          if (js_util.hasProperty(cardano, wallet.id)) {
            debugPrint('Found wallet: ${wallet.displayName}');
            available.add(wallet);
          }
        } catch (e) {
          debugPrint('Error checking wallet ${wallet.id}: $e');
        }
      }

      debugPrint(
        'Available wallets: ${available.map((w) => w.displayName).join(", ")}',
      );
    } catch (e) {
      debugPrint('Error detecting wallets: $e');
    }

    return available;
  }

  /// robustly detect wallets with retries
  Future<List<CardanoWallet>> detectWallets({
    int retries = 10,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    if (!kIsWeb) return [];

    for (int i = 0; i < retries; i++) {
      final wallets = getAvailableWallets();
      if (wallets.isNotEmpty) {
        return wallets;
      }
      debugPrint(
        'No wallets found, retrying in ${delay.inMilliseconds}ms... (${i + 1}/$retries)',
      );
      await Future.delayed(delay);
    }

    return [];
  }

  /// Connect to a specific wallet
  Future<bool> connectWallet(CardanoWallet wallet) async {
    if (!kIsWeb) {
      // For non-web platforms, simulate connection
      return _simulateConnection(wallet);
    }

    _status = WalletConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      // Set the selected wallet in PropFi Bridge FIRST
      _setSelectedWalletInBridge(wallet.id);

      final window = js.webWindow;
      if (window == null) throw Exception('Window not found');

      if (!js_util.hasProperty(window, 'cardano')) {
        throw Exception('Cardano wallet API not found');
      }
      final cardano = js_util.getProperty(window, 'cardano');

      if (!js_util.hasProperty(cardano, wallet.id)) {
        throw Exception('${wallet.displayName} wallet not found');
      }
      final walletObj = js_util.getProperty(cardano, wallet.id);

      // Request wallet access
      final enablePromise = js_util.callMethod(walletObj, 'enable', []);
      _walletApi = await js_util.promiseToFuture(enablePromise);

      // Get wallet address
      final addressesPromise = js_util.callMethod(
        _walletApi,
        'getUsedAddresses',
        [],
      );
      final addresses = await js_util.promiseToFuture(addressesPromise);

      if (addresses != null && (addresses as List).isNotEmpty) {
        _walletAddress = addresses[0] as String;
        _walletPkh = _extractPkh(_walletAddress!);
      } else {
        // Try unused addresses
        final unusedPromise = js_util.callMethod(
          _walletApi,
          'getUnusedAddresses',
          [],
        );
        final unusedAddresses = await js_util.promiseToFuture(unusedPromise);
        if (unusedAddresses != null && (unusedAddresses as List).isNotEmpty) {
          _walletAddress = unusedAddresses[0] as String;
          _walletPkh = _extractPkh(_walletAddress!);
        }
      }

      _connectedWallet = wallet;
      _status = WalletConnectionStatus.connected;

      // Fetch balance
      _balance = await getBalance();

      // ALWAYS set profile to match the connected wallet
      final shortAddr =
          '${_walletAddress!.substring(0, 8)}...${_walletAddress!.substring(_walletAddress!.length - 4)}';
      _userName = '${wallet.displayName} User';
      _userBio = 'Connected via ${wallet.displayName}\nAddress: $shortAddr';

      // Persist
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _userName);
      await prefs.setString('userBio', _userBio);
      await prefs.setString('connectedWalletId', wallet.id);

      // Load saved holdings for this wallet
      await _loadPortfolio();
      
      // Then sync from chain to get any updates
      await syncHoldingsFromChain();
      
      // Also fetch purchases from on-chain metadata (decentralized storage)
      await fetchOnChainPurchases();

      notifyListeners();

      return true;
    } catch (e) {
      _status = WalletConnectionStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Set the selected wallet in PropFi Bridge (JS)
  void _setSelectedWalletInBridge(String walletId) {
    if (!kIsWeb) return; // Only for web platform

    try {
      final window = js.webWindow;
      if (window != null && js_util.hasProperty(window, 'PropFiBridge')) {
        final bridge = js_util.getProperty(window, 'PropFiBridge');
        js_util.callMethod(bridge, 'setSelectedWallet', [walletId]);
        debugPrint('Set selected wallet in bridge: $walletId');
      }
    } catch (e) {
      debugPrint('Failed to set wallet in bridge: $e');
    }
  }

  /// Disconnect wallet and clear all state
  Future<void> disconnectWallet() async {
    // Clear bridge wallet state on web
    if (kIsWeb) {
      try {
        final window = js.webWindow;
        if (window != null && js_util.hasProperty(window, 'PropFiBridge')) {
          final bridge = js_util.getProperty(window, 'PropFiBridge');
          if (js_util.hasProperty(bridge, 'disconnectWallet')) {
            js_util.callMethod(bridge, 'disconnectWallet', []);
            debugPrint('Cleared wallet state in PropFiBridge');
          }
        }
      } catch (e) {
        debugPrint('Failed to disconnect wallet in bridge: $e');
      }
    }

    // Clear all wallet state
    _status = WalletConnectionStatus.disconnected;
    _walletAddress = null;
    _walletPkh = null;
    _connectedWallet = null;
    _walletApi = null;
    _errorMessage = null;
    _balance = 0.0;
    
    // Reset profile to default
    _userName = 'CryptoTycoon';
    _userBio = 'Real Estate Mogul';
    _isLoggedIn = false;
    
    // Clear persisted wallet data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connectedWalletId');
    await prefs.setString('userName', 'CryptoTycoon');
    await prefs.setString('userBio', 'Real Estate Mogul');
    await prefs.setBool('isLoggedIn', false);
    
    notifyListeners();
  }

  /// Sign a transaction
  Future<String> signTransaction(String txCbor) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    if (!kIsWeb) {
      // Simulate signing for non-web platforms
      await Future.delayed(const Duration(seconds: 1));
      return 'signed_$txCbor';
    }

    try {
      final signPromise = js_util.callMethod(
        _walletApi,
        'signTx',
        [txCbor, true], // true for partial sign
      );
      final signedTx = await js_util.promiseToFuture(signPromise);
      return signedTx as String;
    } catch (e) {
      throw Exception('Failed to sign transaction: $e');
    }
  }

  /// Submit a signed transaction - DEPRECATED, use buildPaymentTransaction instead
  Future<String> submitTransaction(String signedTxCbor) async {
    debugPrint('WARNING: submitTransaction called - this should not happen!');
    debugPrint('Stack trace: ${StackTrace.current}');

    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    if (!kIsWeb) {
      // Simulate submission for non-web platforms
      await Future.delayed(const Duration(seconds: 1));
      return 'mock_tx_hash_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final submitPromise = js_util.callMethod(_walletApi, 'submitTx', [
        signedTxCbor,
      ]);
      final txHash = await js_util.promiseToFuture(submitPromise);
      return txHash as String;
    } catch (e) {
      throw Exception('Failed to submit transaction: $e');
    }
  }

  /// Buy fractions from a listing
  Future<String> buyFractions(MarketplaceListing listing, int amount) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      debugPrint('Building buy transaction for ${listing.propertyName}');
      debugPrint('Amount: $amount fractions');
      debugPrint('Total Price: ${listing.pricePerFraction * amount} USDM');

      if (kIsWeb) {
        // Use PropFi Bridge for web platform
        final window = js.webWindow;
        if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
          throw Exception('PropFi Bridge not loaded');
        }
        final bridge = js_util.getProperty(window, 'PropFiBridge');

        // Build transaction via bridge
        final listingJs = js.JsObject.jsify({
          'txHash': listing.txHash,
          'outputIndex': listing.outputIndex,
          'policyId': listing.fractionPolicyId,
          'assetName': listing.fractionTokenName,
          'quantity': amount.toString(),
          'datum': {
            'seller': listing.sellerAddress,
            'price': (listing.pricePerFraction * amount).toInt(),
          },
        });

        final buildTxPromise = js_util.callMethod(
          bridge,
          'buildBuyTransaction',
          [listingJs, _walletAddress, 'USDM'],
        );
        final txResult = await js_util.promiseToFuture(buildTxPromise);
        final txCbor = js_util.getProperty(txResult, 'txCbor') as String;

        // Sign and submit via wallet
        final signedTx = await signTransaction(txCbor);
        final txHash = await submitTransaction(signedTx);

        debugPrint('Transaction submitted: $txHash');

        // Gain XP for buying
        gainXp(500);

        return txHash;
      } else {
        // Simulate for non-web platforms
        await Future.delayed(const Duration(seconds: 2));
        return 'mock_tx_hash_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('Buy transaction error: $e');
      throw Exception('Failed to buy fractions: $e');
    }
  }

  /// Fractionalize a property
  Future<String> fractionalizeProperty({
    required String name,
    required String description,
    required String location,
    required String imageUrl,
    required double totalValue,
    required int totalFractions,
    required double pricePerFraction,
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      debugPrint('Fractionalizing property: $name');

      if (kIsWeb) {
        final window = js.webWindow;
        if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
          throw Exception('PropFi Bridge not loaded');
        }
        final bridge = js_util.getProperty(window, 'PropFiBridge');

        final metadata = js.JsObject.jsify({
          'name': name,
          'description': description,
          'location': location,
          'image': imageUrl,
          'totalValue': totalValue,
          'totalFractions': totalFractions,
          'pricePerFraction': pricePerFraction,
        });

        final promise = js_util.callMethod(bridge, 'fractionalizeProperty', [
          metadata,
          totalFractions,
        ]);

        final txHash = await js_util.promiseToFuture(promise);
        debugPrint('Fractionalization submitted: $txHash');
        return txHash as String;
      } else {
        await Future.delayed(const Duration(seconds: 2));
        return 'mock_tx_hash_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('Fractionalization error: $e');
      throw Exception('Failed to fractionalize property: $e');
    }
  }

  /// List a property for sale
  Future<String> listProperty({
    required String fractionPolicyId,
    required String fractionAssetName,
    required int amount,
    required double pricePerFraction,
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      debugPrint('Listing property for sale...');

      if (kIsWeb) {
        final window = js.webWindow;
        if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
          throw Exception('PropFi Bridge not loaded');
        }
        final bridge = js_util.getProperty(window, 'PropFiBridge');

        final promise = js_util.callMethod(bridge, 'listForSale', [
          fractionPolicyId,
          fractionAssetName,
          amount,
          pricePerFraction,
        ]);

        final txHash = await js_util.promiseToFuture(promise);
        debugPrint('Listing submitted: $txHash');
        return txHash as String;
      } else {
        await Future.delayed(const Duration(seconds: 2));
        return 'mock_tx_hash_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('Listing error: $e');
      throw Exception('Failed to list property: $e');
    }
  }

  /// Buy fractions with real ADA payment
  Future<String> buyFractionsReal({
    required String propertyId,
    required int amount,
    required double pricePerFraction,
    required String ownerWalletAddress,
    required Function(String propertyId, int amount) onSuccess,
    String? propertyName,
    String? buyerName,
    String? buyerEmail,
    String? buyerPhone,
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      final totalAda = amount * pricePerFraction;
      final totalLovelace = (totalAda * 1000000).toInt();

      debugPrint('Building real buy transaction with on-chain metadata');
      debugPrint('Amount: $amount fractions');
      debugPrint('Total Price: $totalAda ADA');

      if (kIsWeb) {
        final window = js.webWindow;
        if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
          throw Exception('PropFi Bridge not loaded');
        }
        final bridge = js_util.getProperty(window, 'PropFiBridge');

        // Use the new metadata-enabled transaction for decentralized storage
        // Include buyer details for certificate generation
        final purchaseData = js.JsObject.jsify({
          'propertyId': propertyId,
          'propertyName': propertyName ?? 'Property $propertyId',
          'fractions': amount,
          'priceAda': totalAda,
          'buyerName': buyerName ?? 'Anonymous',
          'buyerEmail': buyerEmail ?? '',
          'buyerPhone': buyerPhone ?? '',
          'buyerWallet': _walletAddress ?? '',
        });

        final buildTxPromise = js_util.callMethod(
          bridge,
          'buildPaymentWithMetadata',
          [ownerWalletAddress, totalLovelace.toString(), purchaseData],
        );

        final txResult = await js_util.promiseToFuture(buildTxPromise);

        String? txHash;
        if (txResult != null && js_util.hasProperty(txResult, 'txHash')) {
          txHash = js_util.getProperty(txResult, 'txHash')?.toString();
        }

        if (txHash == null || txHash.isEmpty) {
          throw Exception('Transaction completed but no hash returned');
        }

        debugPrint('Transaction submitted successfully: $txHash');
        onSuccess(propertyId, amount);

        // Gain XP for buying
        gainXp(500);

        return txHash;
      } else {
        await Future.delayed(const Duration(seconds: 2));
        final txHash = 'tx_${DateTime.now().millisecondsSinceEpoch}';
        onSuccess(propertyId, amount);
        return txHash;
      }
    } catch (e) {
      debugPrint('Buy transaction error: $e');
      throw Exception('Failed to buy fractions: $e');
    }
  }

  /// Fetch marketplace listings - now includes admin properties
  Future<List<MarketplaceListing>> fetchListings({
    List<dynamic>? adminProperties,
  }) async {
    // First, convert admin properties to listings
    if (adminProperties != null && adminProperties.isNotEmpty) {
      _listings = adminProperties.map((property) {
        return MarketplaceListing(
          id: property.id,
          propertyName: property.name,
          propertyDescription: property.description,
          location: property.location,
          imageUrl: property.imageUrl,
          price: property.totalValue,
          fractionsAvailable: property.fractionsAvailable,
          totalFractions: property.totalFractions,
          pricePerFraction: property.pricePerFraction,
          sellerAddress: property.ownerWalletAddress,
          fractionPolicyId: ContractConfig.cip68MintingPolicyId,
          fractionTokenName: '000de140${property.id}',
          txHash: 'admin_${property.id}',
          outputIndex: 0,
          ownerName: property.ownerName,
          ownerEmail: property.ownerEmail,
          ownerPhone: property.ownerPhone,
        );
      }).toList();

      notifyListeners();
      return _listings;
    }

    if (kIsWeb) {
      // Try to fetch from blockchain via PropFi Bridge
      try {
        final window = js.webWindow;
        if (window != null && js_util.hasProperty(window, 'PropFiBridge')) {
          final bridge = js_util.getProperty(window, 'PropFiBridge');
          if (js_util.hasProperty(bridge, 'fetchMarketplaceListings')) {
            debugPrint('PropFi Bridge found, fetching listings...');

            // Call the async function and await the promise
            final promise = js_util.callMethod(
              bridge,
              'fetchMarketplaceListings',
              [],
            );
            final rawListings = await js_util.promiseToFuture(promise);

            debugPrint('Raw listings received: $rawListings');

            if (rawListings != null &&
                rawListings is List &&
                rawListings.isNotEmpty) {
              _listings = (rawListings).asMap().entries.map((entry) {
                final idx = entry.key;
                final listing = entry.value;

                // Helper to safely get property
                dynamic getProp(dynamic obj, String key) {
                  if (obj == null) return null;
                  if (js_util.hasProperty(obj, key)) {
                    return js_util.getProperty(obj, key);
                  }
                  return null;
                }

                final metadata = getProp(listing, 'metadata');
                final datum = getProp(listing, 'datum');

                return MarketplaceListing(
                  id: idx.toString(),
                  propertyName: metadata != null
                      ? (getProp(metadata, 'name') ?? 'Property $idx')
                      : 'Property $idx',
                  location: metadata != null
                      ? (getProp(metadata, 'location') ?? 'Unknown')
                      : 'Unknown',
                  imageUrl: metadata != null
                      ? (getProp(metadata, 'image') ?? '')
                      : '',
                  price: datum != null
                      ? (getProp(datum, 'price') ?? 0).toDouble()
                      : 0,
                  fractionsAvailable:
                      int.tryParse(
                        getProp(listing, 'quantity')?.toString() ?? '0',
                      ) ??
                      0,
                  totalFractions: 1000,
                  pricePerFraction: datum != null
                      ? ((getProp(datum, 'price') ?? 0) / 1000).toDouble()
                      : 0,
                  sellerAddress: datum != null
                      ? (getProp(datum, 'seller') ?? '')
                      : '',
                  fractionPolicyId: getProp(listing, 'policyId') ?? '',
                  fractionTokenName: getProp(listing, 'assetName') ?? '',
                  txHash: getProp(listing, 'txHash') ?? '',
                  outputIndex: getProp(listing, 'outputIndex') ?? 0,
                );
              }).toList();

              notifyListeners();
              return _listings;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching listings from blockchain: $e');
      }
    }

    // Return empty list if no admin properties
    _listings = [];
    notifyListeners();
    return _listings;
  }

  /// Extract payment key hash from address (simplified)
  String _extractPkh(String address) {
    // In production, properly decode bech32 address
    // For now, return a mock PKH
    return address.length > 20 ? address.substring(10, 66) : 'mock_pkh';
  }

  /// Simulate wallet connection for non-web platforms
  Future<bool> _simulateConnection(CardanoWallet wallet) async {
    _status = WalletConnectionStatus.connecting;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _connectedWallet = wallet;
    _walletAddress =
        'addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3n0d3vllmyqwsx5wktcd8cc3sq835lu7drv2xwl2wywfgs68faae';
    _walletPkh = '82a814cc3db6f04d44e47e21af627f06c7c66d14f5c6c5e4a0c0c38c';
    _status = WalletConnectionStatus.connected;
    notifyListeners();

    return true;
  }

  void gainXp(int amount) {
    _userXp += amount;
    // Check for level up
    if (_userXp >= nextLevelXp) {
      _userLevel++;
      _userXp -= nextLevelXp;
    }
    _saveRpgStats();
    notifyListeners();
  }

  /// Refresh the wallet balance and holdings from the blockchain
  Future<void> refreshBalance() async {
    if (!isConnected) return;
    
    try {
      final newBalance = await getBalance();
      if (newBalance != _balance) {
        _balance = newBalance;
        debugPrint('Balance updated: $_balance ADA');
      }
      
      // Also sync holdings from chain
      await syncHoldingsFromChain();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing balance: $e');
    }
  }

  /// Get balance from the connected wallet
  Future<double> getBalance() async {
    if (!kIsWeb) return 0.0;
    
    try {
      final window = js.webWindow;
      if (window == null) {
        debugPrint('getBalance: window is null');
        return 0.0;
      }
      
      if (!js_util.hasProperty(window, 'PropFiBridge')) {
        debugPrint('getBalance: PropFiBridge not found');
        return 0.0;
      }
      
      final bridge = js_util.getProperty(window, 'PropFiBridge');
      debugPrint('getBalance: Calling PropFiBridge.getBalance()...');
      
      final promise = js_util.callMethod(bridge, 'getBalance', []);
      final balance = await js_util.promiseToFuture(promise);
      
      debugPrint('getBalance: Raw balance result: $balance (type: ${balance.runtimeType})');
      
      final balanceDouble = (balance as num).toDouble();
      debugPrint('getBalance: Parsed balance: $balanceDouble ADA');
      
      return balanceDouble;
    } catch (e) {
      debugPrint('Error fetching balance: $e');
      return 0.0;
    }
  }

  /// Get detailed wallet assets (native tokens, NFTs, etc.)
  Future<Map<String, dynamic>> getWalletAssets() async {
    if (!kIsWeb || !isConnected) return {};
    
    try {
      final window = js.webWindow;
      if (window != null && js_util.hasProperty(window, 'PropFiBridge')) {
        final bridge = js_util.getProperty(window, 'PropFiBridge');
        if (js_util.hasProperty(bridge, 'getWalletAssets')) {
          final promise = js_util.callMethod(bridge, 'getWalletAssets', []);
          final assets = await js_util.promiseToFuture(promise);
          debugPrint('Wallet assets: $assets');
          return Map<String, dynamic>.from(assets as Map);
        }
      }
    } catch (e) {
      debugPrint('Error fetching wallet assets: $e');
    }
    return {};
  }
}
