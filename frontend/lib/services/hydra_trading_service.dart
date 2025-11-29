import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'js_stub.dart' if (dart.library.html) 'js_web.dart' as js;
import 'js_util_stub.dart' if (dart.library.html) 'js_util_web.dart' as js_util;

// For web-specific JS context - use dart:js on web, stub on native
// ignore: avoid_web_libraries_in_flutter
import 'js_context_stub.dart'
    if (dart.library.html) 'js_context_web.dart'
    as dart_js;

/// Hydra Trade Order
class HydraTrade {
  final String orderId;
  final String propertyId;
  final String policyId;
  final String assetName;
  final String seller;
  final String buyer;
  final BigInt quantity;
  final BigInt pricePerUnit;
  final BigInt totalPrice;
  final DateTime timestamp;
  final String status;

  HydraTrade({
    required this.orderId,
    required this.propertyId,
    required this.policyId,
    required this.assetName,
    required this.seller,
    required this.buyer,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.timestamp,
    this.status = 'pending',
  });

  HydraTrade copyWith({String? status}) {
    return HydraTrade(
      orderId: orderId,
      propertyId: propertyId,
      policyId: policyId,
      assetName: assetName,
      seller: seller,
      buyer: buyer,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      totalPrice: totalPrice,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'propertyId': propertyId,
    'policyId': policyId,
    'assetName': assetName,
    'seller': seller,
    'buyer': buyer,
    'quantity': quantity.toString(),
    'pricePerUnit': pricePerUnit.toString(),
    'totalPrice': totalPrice.toString(),
    'timestamp': timestamp.toIso8601String(),
    'status': status,
  };
}

/// Property Fraction in Hydra Head
class HydraFraction {
  final String propertyId;
  final String fractionId;
  final String policyId;
  final String assetName;
  final String ownerAddress;
  final BigInt quantity;
  final String txIn;

  HydraFraction({
    required this.propertyId,
    required this.fractionId,
    required this.policyId,
    required this.assetName,
    required this.ownerAddress,
    required this.quantity,
    required this.txIn,
  });

  factory HydraFraction.fromJson(Map<String, dynamic> json) {
    return HydraFraction(
      propertyId: json['propertyId'] ?? '',
      fractionId: json['fractionId'] ?? '',
      policyId: json['policyId'] ?? '',
      assetName: json['assetName'] ?? '',
      ownerAddress: json['ownerAddress'] ?? '',
      quantity: BigInt.parse(json['quantity']?.toString() ?? '0'),
      txIn: json['txIn'] ?? '',
    );
  }
}

/// Trading Statistics
class HydraTradingStats {
  final int totalTrades;
  final BigInt totalVolume;
  final double averageLatencyMs;
  final double peakTps;
  final double currentTps;

  HydraTradingStats({
    this.totalTrades = 0,
    BigInt? totalVolume,
    this.averageLatencyMs = 0,
    this.peakTps = 0,
    this.currentTps = 0,
  }) : totalVolume = totalVolume ?? BigInt.zero;

  factory HydraTradingStats.fromJson(Map<String, dynamic> json) {
    return HydraTradingStats(
      totalTrades: json['totalTrades'] ?? 0,
      totalVolume: BigInt.parse(json['totalVolume']?.toString() ?? '0'),
      averageLatencyMs: (json['averageLatencyMs'] ?? 0).toDouble(),
      peakTps: (json['peakTps'] ?? 0).toDouble(),
      currentTps: (json['currentTps'] ?? 0).toDouble(),
    );
  }
}

/// Hydra Head State
class HydraHeadState {
  final String status;
  final String? headId;
  final int snapshotNumber;
  final int utxoCount;
  final List<String> parties;
  final bool isConnected;
  final HydraTradingStats stats;

  HydraHeadState({
    this.status = 'Disconnected',
    this.headId,
    this.snapshotNumber = 0,
    this.utxoCount = 0,
    this.parties = const [],
    this.isConnected = false,
    HydraTradingStats? stats,
  }) : stats = stats ?? HydraTradingStats();

  factory HydraHeadState.fromJson(Map<String, dynamic> json) {
    return HydraHeadState(
      status: json['status'] ?? 'Disconnected',
      headId: json['headId'],
      snapshotNumber: json['snapshotNumber'] ?? 0,
      utxoCount: json['utxoCount'] ?? 0,
      parties:
          (json['parties'] as List<dynamic>?)?.map((e) {
            if (e is String) return e;
            if (e is Map) return e['vkey']?.toString() ?? e.toString();
            return e.toString();
          }).toList() ??
          [],
      isConnected: json['isConnected'] ?? false,
      stats: json['stats'] != null
          ? HydraTradingStats.fromJson(json['stats'])
          : null,
    );
  }

  bool get isOpen => status == 'Open';
  bool get canTrade => isOpen && isConnected;
}

/// Production Hydra Trading Service for Flutter
/// This is a GLOBAL singleton service that maintains Hydra connection
class HydraTradingService extends ChangeNotifier {
  HydraHeadState _state = HydraHeadState();
  final List<HydraTrade> _recentTrades = [];
  final List<HydraFraction> _availableFractions = [];
  final List<Map<String, dynamic>> _messageHistory = [];
  StreamController<HydraTrade>? _tradeStreamController;
  String _lastUrl = 'ws://localhost:4001';
  bool _autoReconnect = true;

  // Getters
  HydraHeadState get state => _state;
  List<HydraTrade> get recentTrades => List.unmodifiable(_recentTrades);
  List<HydraFraction> get availableFractions =>
      List.unmodifiable(_availableFractions);
  List<Map<String, dynamic>> get messageHistory =>
      List.unmodifiable(_messageHistory);
  Stream<HydraTrade> get tradeStream =>
      _tradeStreamController?.stream ?? const Stream.empty();
  String get lastUrl => _lastUrl;

  bool get isConnected => _state.isConnected;
  bool get isOpen => _state.isOpen;
  bool get canTrade => _state.canTrade;

  HydraTradingService() {
    _tradeStreamController = StreamController<HydraTrade>.broadcast();
    if (kIsWeb) {
      _initListeners();
      // Check initial connection state from JS client
      _syncStateFromClient();
    }
  }

  /// Sync state from the global JS client (which persists across navigation)
  void _syncStateFromClient() {
    if (!kIsWeb) return;
    try {
      final window = js.webWindow;
      if (window == null) return;
      if (js_util.hasProperty(window, 'hydraClient')) {
        final client = js_util.getProperty(window, 'hydraClient');
        // Check if already connected
        final isConnectedJs = js_util.callMethod(client, 'isConnected', []);
        if (isConnectedJs == true) {
          debugPrint('Hydra: Found existing connection, syncing state...');
          _updateStateFromClient();
        }
      }
    } catch (e) {
      debugPrint('Error syncing Hydra state: $e');
    }
  }

  void _initListeners() {
    if (!kIsWeb) return;

    try {
      final window = js.webWindow;
      if (window == null) return;

      // Connection changes - fired when websocket opens/closes
      js_util.setProperty(
        window,
        'onHydraConnectionChange',
        js.allowInterop((bool isConnected) {
          debugPrint('Hydra connection changed: $isConnected');
          if (isConnected) {
            _updateStateFromClient();
          } else {
            _state = HydraHeadState(status: 'Disconnected', isConnected: false);
          }
          notifyListeners();
        }),
      );

      // Status changes
      js_util.setProperty(
        window,
        'onHydraStatusChange',
        js.allowInterop((String status) {
          debugPrint('Hydra status changed: $status');
          // Sync full state on status change
          _updateStateFromClient();
        }),
      );

      // Messages
      js_util.setProperty(
        window,
        'onHydraMessage',
        js.allowInterop((dynamic msg) {
          _handleMessage(msg);
        }),
      );

      // UTxO updates
      js_util.setProperty(
        window,
        'onHydraUtxosUpdated',
        js.allowInterop((dynamic utxos) {
          _handleUtxosUpdated(utxos);
        }),
      );
    } catch (e) {
      debugPrint('Error initializing Hydra listeners: $e');
    }
  }

  void _handleMessage(dynamic msg) {
    try {
      String msgStr = msg.toString();
      final Map<String, dynamic> messageData = jsonDecode(msgStr);

      // Store message with our own milliseconds timestamp
      // Put timestamp AFTER spread so it doesn't get overwritten by Hydra's string timestamp
      final Map<String, dynamic> storedMessage = {
        ...messageData,
        'localTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _messageHistory.add(storedMessage);

      if (_messageHistory.length > 100) {
        _messageHistory.removeAt(0);
      }

      // Handle specific message types
      final tag = messageData['tag'];
      if (tag == 'TxValid') {
        _handleTxConfirmed(messageData);
      } else if (tag == 'SnapshotConfirmed') {
        _refreshFractions();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling Hydra message: $e');
    }
  }

  void _handleUtxosUpdated(dynamic utxos) {
    try {
      String utxosStr = utxos.toString();
      final List<dynamic> utxoList = jsonDecode(utxosStr);
      _refreshFractionsFromUtxos(utxoList);
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling UTxOs update: $e');
    }
  }

  void _handleTxConfirmed(Map<String, dynamic> message) {
    // Update trade status
    for (int i = 0; i < _recentTrades.length; i++) {
      if (_recentTrades[i].status == 'submitted') {
        _recentTrades[i] = _recentTrades[i].copyWith(status: 'confirmed');
        _tradeStreamController?.add(_recentTrades[i]);
      }
    }
  }

  void _refreshFractionsFromUtxos(List<dynamic> utxoList) {
    _availableFractions.clear();
    for (final utxo in utxoList) {
      final assets = utxo['value']?['assets'] as Map<String, dynamic>? ?? {};
      for (final entry in assets.entries) {
        final assetId = entry.key;
        final quantity = entry.value;
        final assetName = assetId.length > 56 ? assetId.substring(56) : '';

        // Check for CIP-68 user token prefix
        if (assetName.startsWith('000de140')) {
          _availableFractions.add(
            HydraFraction(
              propertyId: assetName.substring(8),
              fractionId: assetId,
              policyId: assetId.substring(0, 56),
              assetName: assetName,
              ownerAddress: utxo['address'] ?? '',
              quantity: BigInt.parse(quantity.toString()),
              txIn: utxo['txIn'] ?? '',
            ),
          );
        }
      }
    }
  }

  // ============ CONNECTION METHODS ============

  /// Connect to Hydra node - connection persists globally in JS client
  Future<void> connect([String url = 'ws://localhost:4001']) async {
    if (!kIsWeb) return;

    _lastUrl = url;

    try {
      final window = js.webWindow;
      if (window == null) return;

      if (js_util.hasProperty(window, 'hydraClient')) {
        final client = js_util.getProperty(window, 'hydraClient');

        // Set URL
        js_util.callMethod(client, 'setUrl', [url]);

        // Connect (this persists in the global JS client)
        final promise = js_util.callMethod(client, 'connect', []);
        await js_util.promiseToFuture(promise);

        _updateStateFromClient();
        notifyListeners();

        debugPrint('Hydra: Connected to $url (global connection)');
      }
    } catch (e) {
      debugPrint('Error connecting to Hydra: $e');
      rethrow;
    }
  }

  /// Disconnect from Hydra - clears global connection
  Future<void> disconnect() async {
    if (!kIsWeb) return;
    _autoReconnect = false;
    try {
      await _callClientMethod('disconnect');
      _state = HydraHeadState();
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Reconnect to last known URL
  Future<void> reconnect() async {
    if (!isConnected && _lastUrl.isNotEmpty) {
      _autoReconnect = true;
      await connect(_lastUrl);
    }
  }

  // ============ HEAD LIFECYCLE ============

  Future<void> initHead() async {
    await _callClientMethod('initHead');
  }

  Future<void> abort() async {
    await _callClientMethod('abort');
  }

  Future<void> closeHead() async {
    await _callClientMethod('closeHead');
  }

  Future<void> fanout() async {
    await _callClientMethod('fanout');
  }

  Future<void> commitUtxo(Map<String, dynamic> utxo) async {
    if (!kIsWeb) return;
    try {
      final window = js.webWindow;
      if (window == null) return;
      if (js_util.hasProperty(window, 'hydraClient')) {
        final client = js_util.getProperty(window, 'hydraClient');
        final utxoJs = js_util.jsify(utxo);
        final promise = js_util.callMethod(client, 'commit', [utxoJs]);
        await js_util.promiseToFuture(promise);
      }
    } catch (e) {
      debugPrint('Error committing UTxO: $e');
      rethrow;
    }
  }

  // ============ TRADING METHODS ============

  /// Build a real Hydra transaction using PropFiBridge and Lucid
  Future<String> buildTradeTx({
    required String toAddress,
    required BigInt lovelaceAmount,
    String? assetId,
    BigInt? assetAmount,
  }) async {
    if (!kIsWeb) throw Exception('Web only');

    try {
      final window = js.webWindow;
      if (window == null) throw Exception('Window not found');

      // 1. Get Hydra UTxOs as JSON string
      if (!js_util.hasProperty(window, 'hydraGetUtxosString')) {
        throw Exception('hydraGetUtxosString not found');
      }
      final utxosJson = js_util.callMethod(window, 'hydraGetUtxosString', []);

      // 2. Call PropFiBridge.buildHydraTx
      if (!js_util.hasProperty(window, 'PropFiBridge')) {
        throw Exception('PropFiBridge not found');
      }
      final bridge = js_util.getProperty(window, 'PropFiBridge');

      final promise = js_util.callMethod(bridge, 'buildHydraTx', [
        utxosJson,
        toAddress,
        lovelaceAmount.toString(),
        assetId,
        assetAmount?.toString(),
      ]);

      final result = await js_util.promiseToFuture(promise);
      return result.toString();
    } catch (e) {
      debugPrint('Error building Hydra tx: $e');
      rethrow;
    }
  }

  /// Get wallet UTxOs formatted for Hydra Commit
  Future<Map<String, dynamic>> getWalletUtxos() async {
    if (!kIsWeb) return {};
    try {
      final window = js.webWindow;
      if (window == null) return {};

      if (!js_util.hasProperty(window, 'PropFiBridge')) {
        throw Exception('PropFiBridge not found');
      }
      final bridge = js_util.getProperty(window, 'PropFiBridge');

      final promise = js_util.callMethod(bridge, 'getWalletUtxosForHydra', []);
      final result = await js_util.promiseToFuture(promise);

      if (result is String) {
        return jsonDecode(result) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Error getting wallet UTxOs: $e');
      return {};
    }
  }

  /// Submit a trade transaction to the Hydra Head
  Future<HydraTrade> submitTrade({
    required String propertyId,
    required String policyId,
    required String assetName,
    required String seller,
    required String buyer,
    required BigInt quantity,
    required BigInt pricePerUnit,
    required String txCborHex,
  }) async {
    if (!canTrade) {
      throw Exception('Cannot trade: Hydra Head not open');
    }

    final trade = HydraTrade(
      orderId: 'trade_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      policyId: policyId,
      assetName: assetName,
      seller: seller,
      buyer: buyer,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      totalPrice: quantity * pricePerUnit,
      timestamp: DateTime.now(),
      status: 'submitted',
    );

    _recentTrades.insert(0, trade);
    if (_recentTrades.length > 50) {
      _recentTrades.removeLast();
    }
    notifyListeners();

    try {
      // Submit to Hydra
      await _callClientMethod('submitTxAsync', [txCborHex]);
      _tradeStreamController?.add(trade);
      return trade;
    } catch (e) {
      // Update trade status to failed
      final index = _recentTrades.indexWhere((t) => t.orderId == trade.orderId);
      if (index != -1) {
        _recentTrades[index] = trade.copyWith(status: 'failed');
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Submit a raw transaction to the Hydra Head
  Future<void> submitTransaction(String txCborHex) async {
    await _callClientMethod('submitTxAsync', [txCborHex]);
  }

  /// Get property fractions owned by an address
  List<HydraFraction> getFractionsForAddress(String address) {
    return _availableFractions.where((f) => f.ownerAddress == address).toList();
  }

  /// Get a specific fraction for a property ID (if available in Head)
  HydraFraction? getFractionForProperty(String propertyId) {
    try {
      return _availableFractions.firstWhere((f) => f.propertyId == propertyId);
    } catch (_) {
      return null;
    }
  }

  /// Refresh state from JS client
  void _updateStateFromClient() {
    if (!kIsWeb) return;
    try {
      // Use dart:js context directly for reliable string conversion
      final context = dart_js.context;
      if (context.hasProperty('hydraGetStateString')) {
        final result = context.callMethod('hydraGetStateString', []);

        if (result == null) return;

        debugPrint('Hydra raw state result type: ${result.runtimeType}');

        Map<String, dynamic>? stateJson;

        if (result is String) {
          final String stateJsonStr = result;
          if (stateJsonStr.isNotEmpty &&
              stateJsonStr != 'null' &&
              stateJsonStr != 'undefined' &&
              stateJsonStr.startsWith('{')) {
            try {
              stateJson = jsonDecode(stateJsonStr) as Map<String, dynamic>;
            } catch (e) {
              debugPrint('Error decoding Hydra state JSON: $e');
            }
          }
        } else if (result is Map) {
          // Handle case where JS returns an object directly (converted to Map by dart:js/interop)
          debugPrint('Hydra returned Map result directly');
          try {
            stateJson = Map<String, dynamic>.from(result);
          } catch (e) {
            debugPrint('Error converting Map to State: $e');
          }
        } else {
          debugPrint('Hydra returned unexpected type: $result');
        }

        if (stateJson != null) {
          debugPrint('Hydra parsed state: $stateJson');
          _state = HydraHeadState.fromJson(stateJson);
          _refreshFractions();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating state: $e');
    }
  }

  void _refreshFractions() {
    if (!kIsWeb) return;
    try {
      _availableFractions.clear();

      // Use dart:js context directly for reliable string conversion
      final context = dart_js.context;
      if (context.hasProperty('hydraGetFractionsString')) {
        final result = context.callMethod('hydraGetFractionsString', []);

        if (result == null) return;

        debugPrint('Hydra raw fractions result type: ${result.runtimeType}');

        List<dynamic>? fractionsList;

        if (result is String) {
          final String fractionsJsonStr = result;
          if (fractionsJsonStr.isNotEmpty &&
              fractionsJsonStr != 'null' &&
              fractionsJsonStr != '[]' &&
              fractionsJsonStr.startsWith('[')) {
            try {
              fractionsList = jsonDecode(fractionsJsonStr) as List<dynamic>;
            } catch (e) {
              debugPrint('Error decoding Hydra fractions JSON: $e');
            }
          }
        } else if (result is List) {
          debugPrint('Hydra returned List result directly');
          fractionsList = result;
        }

        if (fractionsList != null) {
          for (final f in fractionsList) {
            _availableFractions.add(
              HydraFraction.fromJson(f as Map<String, dynamic>),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error refreshing fractions: $e');
    }
  }

  Future<void> _callClientMethod(
    String methodName, [
    List<dynamic>? args,
  ]) async {
    if (!kIsWeb) return;
    try {
      final window = js.webWindow;
      if (window == null) return;
      if (js_util.hasProperty(window, 'hydraClient')) {
        final client = js_util.getProperty(window, 'hydraClient');
        final result = js_util.callMethod(client, methodName, args ?? []);
        if (result is Future || js_util.hasProperty(result, 'then')) {
          await js_util.promiseToFuture(result);
        }
      }
    } catch (e) {
      debugPrint('Error calling $methodName: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _tradeStreamController?.close();
    super.dispose();
  }
}
