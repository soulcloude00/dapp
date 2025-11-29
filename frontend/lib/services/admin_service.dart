import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports for web platform JS interop
import 'js_stub.dart' if (dart.library.html) 'js_web.dart' as js;
import 'js_util_stub.dart' if (dart.library.html) 'js_util_web.dart' as js_util;

/// Property listing model for admin-created properties
class Property {
  final String id;
  final String name;
  final String description;
  final String location;
  final String imageUrl;
  final double totalValue; // Total property value in USD
  final int totalFractions;
  final double pricePerFraction; // Price per fraction in ADA
  final String ownerWalletAddress; // Admin/owner wallet to receive payments
  final String? legalDocumentCID; // IPFS CID for legal documents
  final DateTime createdAt;
  final bool isListed; // Whether it's currently listed on marketplace
  final int fractionsSold;
  // On-chain tracking
  final String? txHash; // Transaction hash when listed on-chain
  final int? outputIndex; // UTxO output index
  final String? propertyIdOnChain; // CIP-68 property ID
  
  // Owner details for certificate
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final String? ownerPhotoUrl;

  Property({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.totalValue,
    required this.totalFractions,
    required this.pricePerFraction,
    required this.ownerWalletAddress,
    this.legalDocumentCID,
    required this.createdAt,
    this.isListed = false,
    this.fractionsSold = 0,
    this.txHash,
    this.outputIndex,
    this.propertyIdOnChain,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.ownerPhotoUrl,
  });

  int get fractionsAvailable => totalFractions - fractionsSold;
  double get fundedPercentage => fractionsSold / totalFractions;
  double get totalRaised => fractionsSold * pricePerFraction;
  bool get isOnChain => txHash != null && txHash!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'imageUrl': imageUrl,
        'totalValue': totalValue,
        'totalFractions': totalFractions,
        'pricePerFraction': pricePerFraction,
        'ownerWalletAddress': ownerWalletAddress,
        'legalDocumentCID': legalDocumentCID,
        'createdAt': createdAt.toIso8601String(),
        'isListed': isListed,
        'fractionsSold': fractionsSold,
        'txHash': txHash,
        'outputIndex': outputIndex,
        'propertyIdOnChain': propertyIdOnChain,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'ownerPhotoUrl': ownerPhotoUrl,
      };

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] ?? json['propertyId'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        location: json['location'] ?? '',
        imageUrl: json['imageUrl'] ?? json['image'] ?? '',
        totalValue: _parseDouble(json['totalValue']),
        totalFractions: _parseInt(json['totalFractions']),
        pricePerFraction: _parseDouble(json['pricePerFraction']),
        ownerWalletAddress: json['ownerWalletAddress'] ?? json['ownerWallet'] ?? json['seller'] ?? '',
        legalDocumentCID: json['legalDocumentCID'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isListed: json['isListed'] ?? true, // On-chain = listed
        fractionsSold: json['fractionsSold'] ?? 0,
        txHash: json['txHash'],
        outputIndex: json['outputIndex'],
        propertyIdOnChain: json['propertyId'] ?? json['propertyIdOnChain'],
        ownerName: json['ownerName'],
        ownerEmail: json['ownerEmail'],
        ownerPhone: json['ownerPhone'],
        ownerPhotoUrl: json['ownerPhotoUrl'],
      );

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Property copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? imageUrl,
    double? totalValue,
    int? totalFractions,
    double? pricePerFraction,
    String? ownerWalletAddress,
    String? legalDocumentCID,
    DateTime? createdAt,
    bool? isListed,
    int? fractionsSold,
    String? txHash,
    int? outputIndex,
    String? propertyIdOnChain,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? ownerPhotoUrl,
    bool clearOnChainData = false, // Set to true to explicitly clear on-chain fields
  }) =>
      Property(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        location: location ?? this.location,
        imageUrl: imageUrl ?? this.imageUrl,
        totalValue: totalValue ?? this.totalValue,
        totalFractions: totalFractions ?? this.totalFractions,
        pricePerFraction: pricePerFraction ?? this.pricePerFraction,
        ownerWalletAddress: ownerWalletAddress ?? this.ownerWalletAddress,
        legalDocumentCID: legalDocumentCID ?? this.legalDocumentCID,
        createdAt: createdAt ?? this.createdAt,
        isListed: isListed ?? this.isListed,
        fractionsSold: fractionsSold ?? this.fractionsSold,
        txHash: clearOnChainData ? null : (txHash ?? this.txHash),
        outputIndex: clearOnChainData ? null : (outputIndex ?? this.outputIndex),
        propertyIdOnChain: clearOnChainData ? null : (propertyIdOnChain ?? this.propertyIdOnChain),
        ownerName: ownerName ?? this.ownerName,
        ownerEmail: ownerEmail ?? this.ownerEmail,
        ownerPhone: ownerPhone ?? this.ownerPhone,
        ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      );
}

/// Admin service for managing properties (with on-chain support)
class AdminService extends ChangeNotifier {
  static const String _storageKey = 'propfi_properties';
  static const String _adminWalletKey = 'propfi_admin_wallet';
  static const String _saleRecordsKey = 'propfi_sale_records';

  List<Property> _properties = [];
  List<Property> _onChainProperties = [];
  Map<String, int> _saleRecords = {}; // propertyId -> fractionsSold
  String? _adminWalletAddress;
  bool _isLoading = false;
  String? _lastError;

  List<Property> get properties => [..._properties, ..._onChainProperties];
  List<Property> get localProperties => _properties;
  List<Property> get onChainProperties => _onChainProperties;
  List<Property> get listedProperties =>
      properties.where((p) => p.isListed || p.isOnChain).toList();
  String? get adminWalletAddress => _adminWalletAddress;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  AdminService() {
    _loadProperties();
  }

  /// Load properties from local storage and on-chain
  Future<void> _loadProperties() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load admin wallet
      _adminWalletAddress = prefs.getString(_adminWalletKey);

      // Load local properties (cache/draft)
      final propertiesJson = prefs.getString(_storageKey);
      if (propertiesJson != null) {
        final List<dynamic> decoded = jsonDecode(propertiesJson);
        _properties = decoded.map((e) => Property.fromJson(e)).toList();
      }

      // Load sale records (persisted separately for on-chain properties)
      final saleRecordsJson = prefs.getString(_saleRecordsKey);
      if (saleRecordsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(saleRecordsJson);
        _saleRecords = decoded.map((k, v) => MapEntry(k, v as int));
      }

      debugPrint('Loaded ${_properties.length} local properties');
      debugPrint('Loaded ${_saleRecords.length} sale records');

      // Also fetch on-chain properties
      await refreshOnChainProperties();
    } catch (e) {
      debugPrint('Error loading properties: $e');
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save sale records to persistent storage
  Future<void> _saveSaleRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saleRecordsKey, jsonEncode(_saleRecords));
  }

  /// Get fractions sold for a property (from sale records)
  int getFractionsSold(String propertyId) {
    return _saleRecords[propertyId] ?? 0;
  }

  /// Refresh on-chain properties from blockchain
  Future<void> refreshOnChainProperties() async {
    if (!kIsWeb) {
      debugPrint('On-chain property fetching only available on web');
      return;
    }
    
    try {
      debugPrint('Fetching on-chain properties...');
      
      // Call JavaScript bridge to fetch on-chain properties
      final window = js.webWindow;
      if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
        debugPrint('PropFiBridge not available');
        return;
      }
      final bridge = js_util.getProperty(window, 'PropFiBridge');

      // Check if the JSON version exists
      final hasJsonMethod = js_util.hasProperty(bridge, 'fetchOnChainPropertiesJson');
      debugPrint('Has fetchOnChainPropertiesJson: $hasJsonMethod');

      if (hasJsonMethod) {
        // Use JSON version for easier Dart interop
        final promise = js_util.callMethod(bridge, 'fetchOnChainPropertiesJson', []);
        final jsonString = await js_util.promiseToFuture(promise);
        debugPrint('JSON response: $jsonString');
        
        if (jsonString != null && jsonString.toString().isNotEmpty && jsonString.toString() != '[]') {
          final List<dynamic> propertiesList = json.decode(jsonString.toString());
          _onChainProperties = propertiesList.map((p) {
            final property = Property.fromJson(Map<String, dynamic>.from(p));
            
            // Apply persisted sale records
            final savedSales = _saleRecords[property.id] ?? 
                               _saleRecords[property.propertyIdOnChain] ?? 
                               _saleRecords[property.txHash] ?? 0;
            
            if (savedSales > 0) {
              debugPrint('Applying ${savedSales} saved sales to property ${property.name}');
              return property.copyWith(fractionsSold: savedSales);
            }
            return property;
          }).toList();
          
          debugPrint('Fetched ${_onChainProperties.length} on-chain properties');
        } else {
          _onChainProperties = [];
          debugPrint('No on-chain properties found');
        }
      } else {
        debugPrint('fetchOnChainPropertiesJson not available, using old method');
        _onChainProperties = [];
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error fetching on-chain properties: $e');
      debugPrint('Stack trace: $stackTrace');
      _lastError = e.toString();
    }
  }

  /// Save properties to local storage
  Future<void> _saveProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_properties.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving properties: $e');
    }
  }

  /// Set admin wallet address
  Future<void> setAdminWallet(String address) async {
    _adminWalletAddress = address;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminWalletKey, address);
    notifyListeners();
  }

  /// Add a new property (saves locally as draft)
  Future<Property> addProperty({
    required String name,
    required String description,
    required String location,
    required String imageUrl,
    required double totalValue,
    required int totalFractions,
    required double pricePerFraction,
    required String ownerWalletAddress,
    String? legalDocumentCID,
  }) async {
    final property = Property(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      location: location,
      imageUrl: imageUrl,
      totalValue: totalValue,
      totalFractions: totalFractions,
      pricePerFraction: pricePerFraction,
      ownerWalletAddress: ownerWalletAddress,
      legalDocumentCID: legalDocumentCID,
      createdAt: DateTime.now(),
      isListed: false,
      fractionsSold: 0,
    );

    _properties.add(property);
    await _saveProperties();
    notifyListeners();

    debugPrint('Added property: ${property.name} (local draft)');
    return property;
  }

  /// List a property ON-CHAIN (decentralized)
  Future<String?> listPropertyOnChain(String id) async {
    if (!kIsWeb) {
      _lastError = 'On-chain listing only available on web';
      notifyListeners();
      return null;
    }
    
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final property = _properties.firstWhere((p) => p.id == id);
      
      debugPrint('Listing property on-chain: ${property.name}');

      // Call JavaScript bridge
      final window = js.webWindow;
      if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
        throw Exception('PropFiBridge not available. Please refresh the page.');
      }
      final bridge = js_util.getProperty(window, 'PropFiBridge');

      // Create property object for JS using js_util.jsify (compatible with globalThis)
      final propertyData = js_util.jsify({
        'name': property.name,
        'description': property.description,
        'location': property.location,
        'imageUrl': property.imageUrl,
        'totalValue': property.totalValue,
        'totalFractions': property.totalFractions,
        'pricePerFraction': property.pricePerFraction,
        'ownerWalletAddress': property.ownerWalletAddress,
        'legalDocumentCID': property.legalDocumentCID ?? '',
      });

      final promise = js_util.callMethod(bridge, 'listPropertyOnChain', [propertyData]);
      final result = await js_util.promiseToFuture(promise);

      if (result != null) {
        final txHash = js_util.getProperty(result, 'txHash')?.toString();
        final propertyIdOnChain = js_util.getProperty(result, 'propertyId')?.toString();
        
        debugPrint('Property listed on-chain! TX: $txHash, PropertyID: $propertyIdOnChain');

        // Update local property with on-chain info
        final index = _properties.indexWhere((p) => p.id == id);
        if (index != -1) {
          _properties[index] = property.copyWith(
            isListed: true,
            txHash: txHash,
            propertyIdOnChain: propertyIdOnChain,
          );
          await _saveProperties();
        }

        // Refresh on-chain properties
        await refreshOnChainProperties();
        
        return txHash;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error listing property on-chain: $e');
      _lastError = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel/Delist a property from marketplace (on-chain)
  Future<String?> cancelPropertyListing(String txHash, int outputIndex) async {
    if (!kIsWeb) {
      _lastError = 'On-chain operations only available on web';
      notifyListeners();
      return null;
    }
    
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint('Canceling property listing: $txHash#$outputIndex');

      final window = js.webWindow;
      if (window == null || !js_util.hasProperty(window, 'PropFiBridge')) {
        throw Exception('PropFiBridge not available');
      }
      final bridge = js_util.getProperty(window, 'PropFiBridge');

      final promise = js_util.callMethod(bridge, 'cancelPropertyListing', [txHash, outputIndex]);
      final result = await js_util.promiseToFuture(promise);

      debugPrint('Property delisted! TX: $result');

      // Refresh on-chain properties
      await refreshOnChainProperties();

      return result?.toString();
    } catch (e) {
      debugPrint('Error canceling listing: $e');
      _lastError = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a property
  Future<void> updateProperty(Property updatedProperty) async {
    final index = _properties.indexWhere((p) => p.id == updatedProperty.id);
    if (index != -1) {
      _properties[index] = updatedProperty;
      await _saveProperties();
      notifyListeners();
    }
  }

  /// Delete a property (local only)
  Future<void> deleteProperty(String id) async {
    _properties.removeWhere((p) => p.id == id);
    await _saveProperties();
    notifyListeners();
  }

  /// Reset a property's on-chain status (for failed transactions)
  Future<void> resetOnChainStatus(String id) async {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        clearOnChainData: true,
      );
      await _saveProperties();
      notifyListeners();
    }
  }

  /// List a property on marketplace (local flag - use listPropertyOnChain for decentralized)
  Future<void> listProperty(String id) async {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(isListed: true);
      await _saveProperties();
      notifyListeners();
    }
  }

  /// Unlist a property from marketplace (local flag)
  Future<void> unlistProperty(String id) async {
    final index = _properties.indexWhere((p) => p.id == id);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(isListed: false);
      await _saveProperties();
      notifyListeners();
    }
  }

  /// Record a sale of fractions (persists to storage)
  Future<void> recordSale(String propertyId, int fractionsBought) async {
    debugPrint('Recording sale: $fractionsBought fractions for property $propertyId');
    
    // Update sale records (persisted)
    _saleRecords[propertyId] = (_saleRecords[propertyId] ?? 0) + fractionsBought;
    await _saveSaleRecords();
    
    // Check local properties
    var index = _properties.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      final property = _properties[index];
      _properties[index] = property.copyWith(
        fractionsSold: property.fractionsSold + fractionsBought,
      );
      await _saveProperties();
      notifyListeners();
      return;
    }

    // Check on-chain properties (update local cache with persisted sale record)
    index = _onChainProperties.indexWhere((p) => 
      p.id == propertyId || 
      p.propertyIdOnChain == propertyId ||
      p.txHash == propertyId
    );
    if (index != -1) {
      final property = _onChainProperties[index];
      final totalSold = _saleRecords[propertyId] ?? fractionsBought;
      _onChainProperties[index] = property.copyWith(
        fractionsSold: totalSold,
      );
      debugPrint('Updated on-chain property ${property.name} with $totalSold fractions sold');
      notifyListeners();
    }
  }

  /// Get property by ID (checks both local and on-chain)
  Property? getProperty(String id) {
    try {
      // Check local first
      return _properties.firstWhere((p) => p.id == id);
    } catch (_) {
      // Check on-chain
      try {
        return _onChainProperties.firstWhere(
          (p) => p.id == id || p.propertyIdOnChain == id || p.txHash == id
        );
      } catch (_) {
        return null;
      }
    }
  }

  /// Get property by transaction hash
  Property? getPropertyByTxHash(String txHash) {
    try {
      return properties.firstWhere((p) => p.txHash == txHash);
    } catch (_) {
      return null;
    }
  }

  /// Clear all local properties (for testing)
  Future<void> clearAll() async {
    _properties.clear();
    await _saveProperties();
    notifyListeners();
  }

  /// Force refresh from blockchain
  Future<void> refresh() async {
    await refreshOnChainProperties();
  }
}
