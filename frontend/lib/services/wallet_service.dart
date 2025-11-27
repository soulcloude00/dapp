import 'dart:async';
import 'package:flutter/foundation.dart';

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

  MarketplaceListing({
    required this.id,
    required this.propertyName,
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
  });

  double get fundedPercentage =>
      (totalFractions - fractionsAvailable) / totalFractions;
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

  // Getters
  WalletConnectionStatus get status => _status;
  bool get isConnected => _status == WalletConnectionStatus.connected;
  String? get walletAddress => _walletAddress;
  String? get walletPkh => _walletPkh;
  CardanoWallet? get connectedWallet => _connectedWallet;
  String? get errorMessage => _errorMessage;
  List<MarketplaceListing> get listings => _listings;

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
      
      // Notify PropFi Bridge of the selected wallet
      _setSelectedWalletInBridge(wallet.id);
      
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

  /// Disconnect wallet
  Future<void> disconnectWallet() async {
    _status = WalletConnectionStatus.disconnected;
    _walletAddress = null;
    _walletPkh = null;
    _connectedWallet = null;
    _walletApi = null;
    _errorMessage = null;
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

  /// Buy fractions with real ADA payment to property owner
  Future<String> buyFractionsReal({
    required String propertyId,
    required int amount,
    required double pricePerFraction,
    required String ownerWalletAddress,
    required Function(String propertyId, int amount) onSuccess,
  }) async {
    if (!isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      final totalAda = amount * pricePerFraction;
      final totalLovelace = (totalAda * 1000000).toInt(); // Convert ADA to Lovelace

      debugPrint('Building real buy transaction');
      debugPrint('Amount: $amount fractions');
      debugPrint('Total Price: $totalAda ADA ($totalLovelace lovelace)');
      debugPrint('Sending to: $ownerWalletAddress');

      if (kIsWeb) {
        // Use PropFi Bridge for web platform
        final window = js.webWindow;
        if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
          throw Exception('PropFi Bridge not loaded');
        }
        final bridge = js_util.getProperty(window, 'PropFiBridge');

        // Build, sign, and submit transaction via bridge (all in one call)
        debugPrint('Calling buildPaymentTransaction...');
        
        dynamic txResult;
        try {
          final buildTxPromise = js_util.callMethod(
            bridge,
            'buildPaymentTransaction',
            [_walletAddress, ownerWalletAddress, totalLovelace.toString()],
          );
          
          debugPrint('Awaiting transaction promise...');
          txResult = await js_util.promiseToFuture(buildTxPromise);
          debugPrint('Transaction result received, type: ${txResult.runtimeType}');
        } catch (jsError) {
          debugPrint('JS Promise error: $jsError');
          throw Exception('Transaction failed: $jsError');
        }
        
        // Extract txHash from result
        String? txHash;
        try {
          if (txResult != null && js_util.hasProperty(txResult, 'txHash')) {
            txHash = js_util.getProperty(txResult, 'txHash')?.toString();
            debugPrint('Extracted txHash: $txHash');
          } else {
            debugPrint('txResult does not have txHash property');
            debugPrint('txResult: $txResult');
          }
        } catch (extractError) {
          debugPrint('Error extracting txHash: $extractError');
        }
        
        if (txHash == null || txHash.isEmpty) {
          throw Exception('Transaction completed but no hash returned');
        }

        debugPrint('Transaction submitted successfully: $txHash');
        
        // Call success callback to update property state
        onSuccess(propertyId, amount);

        return txHash;
      } else {
        // Simulate for non-web platforms
        await Future.delayed(const Duration(seconds: 2));
        final txHash = 'tx_${DateTime.now().millisecondsSinceEpoch}';
        onSuccess(propertyId, amount);
        return txHash;
      }
    } catch (e, stackTrace) {
      debugPrint('=== BUY TRANSACTION ERROR ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Check if this is a JS error with more info
      String errorMessage = e.toString();
      if (errorMessage.contains('ApiError')) {
        debugPrint('This appears to be a Blockfrost API error');
      }
      
      throw Exception('Failed to buy fractions: $errorMessage');
    }
  }

  /// Fetch marketplace listings - now includes admin properties
  Future<List<MarketplaceListing>> fetchListings({List<dynamic>? adminProperties}) async {
    // First, convert admin properties to listings
    if (adminProperties != null && adminProperties.isNotEmpty) {
      _listings = adminProperties.map((property) {
        return MarketplaceListing(
          id: property.id,
          propertyName: property.name,
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
}
