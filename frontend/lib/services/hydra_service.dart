import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

// Conditional imports for web platform JS interop
import 'js_stub.dart' if (dart.library.html) 'js_web.dart' as js;
import 'js_util_stub.dart' if (dart.library.html) 'js_util_web.dart' as js_util;

enum HydraStatus { idle, initializing, open, closed, finalized, unknown }

class HydraService extends ChangeNotifier {
  HydraStatus _status = HydraStatus.idle;
  List<Map<String, dynamic>> _messageHistory = [];
  bool _isConnected = false;
  String _nodeUrl = 'ws://localhost:4001';

  HydraStatus get status => _status;
  List<Map<String, dynamic>> get messageHistory => _messageHistory;
  bool get isConnected => _isConnected;
  String get nodeUrl => _nodeUrl;

  HydraService() {
    if (kIsWeb) {
      _initListeners();
    }
  }

  void _initListeners() {
    if (!kIsWeb) return;

    try {
      final window = js.webWindow;
      if (window == null) return;

      // Check if hydraClient exists
      if (js_util.hasProperty(window, 'hydraClient')) {
        // Listen for status changes
        js_util.setProperty(
          window,
          'onHydraStatusChange',
          js.allowInterop((String status) {
            _updateStatus(status);
          }),
        );

        js_util.setProperty(
          window,
          'onHydraMessage',
          js.allowInterop((dynamic msg) {
            _handleMessage(msg);
          }),
        );
      }
    } catch (e) {
      debugPrint('Error initializing Hydra listeners: $e');
    }
  }

  void _updateStatus(String statusStr) {
    HydraStatus newStatus;
    switch (statusStr) {
      case 'Idle':
        newStatus = HydraStatus.idle;
        break;
      case 'Initializing':
        newStatus = HydraStatus.initializing;
        break;
      case 'Open':
        newStatus = HydraStatus.open;
        break;
      case 'Closed':
        newStatus = HydraStatus.closed;
        break;
      case 'Final':
        newStatus = HydraStatus.finalized;
        break;
      default:
        newStatus = HydraStatus.unknown;
    }

    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  void _handleMessage(dynamic msg) {
    try {
      // msg is passed as JSON string from JS to avoid interop issues
      String msgStr = msg.toString();
      final Map<String, dynamic> messageData = jsonDecode(msgStr);
      
      _messageHistory.add({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...messageData,
      });
      
      // Keep history manageable
      if (_messageHistory.length > 100) {
        _messageHistory.removeAt(0);
      }
      
      notifyListeners();
      debugPrint('Hydra Message: ${messageData['tag']}');
    } catch (e) {
      debugPrint('Error handling Hydra message: $e');
    }
  }

  Future<void> connect(String url) async {
    _nodeUrl = url;
    if (!kIsWeb) return;

    try {
      final window = js.webWindow;
      if (window == null) return;

      if (js_util.hasProperty(window, 'hydraClient')) {
        final client = js_util.getProperty(window, 'hydraClient');

        // Update URL if needed (might need to recreate client or add setUrl method)
        // For now assuming default or already set.

        final promise = js_util.callMethod(client, 'connect', []);
        await js_util.promiseToFuture(promise);
        _isConnected = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error connecting to Hydra: $e');
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> initHead() async {
    await _callClientMethod('initHead');
  }

  Future<void> closeHead() async {
    await _callClientMethod('closeHead');
  }

  Future<void> fanout() async {
    await _callClientMethod('fanout');
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
        final promise = js_util.callMethod(client, methodName, args ?? []);
        await js_util.promiseToFuture(promise);
      }
    } catch (e) {
      debugPrint('Error calling $methodName: $e');
      rethrow;
    }
  }

  /// Submit a transaction to the Hydra Head (L2)
  Future<void> submitTransaction(String txCborHex) async {
    await _callClientMethod('newTx', [txCborHex]);
  }

  /// Commit UTxO to the Hydra Head
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

  /// Get the current Head UTxO set
  Future<List<Map<String, dynamic>>> getHeadUtxos() async {
    // Parse from message history - look for SnapshotConfirmed messages
    final snapshots = _messageHistory.where((msg) => msg['tag'] == 'SnapshotConfirmed').toList();
    if (snapshots.isEmpty) return [];
    
    final latestSnapshot = snapshots.last;
    if (latestSnapshot['snapshot'] != null && latestSnapshot['snapshot']['utxo'] != null) {
      // This would need proper parsing based on actual Hydra response format
      return [];
    }
    return [];
  }

  /// Clear message history
  void clearHistory() {
    _messageHistory.clear();
    notifyListeners();
  }

  /// Disconnect from Hydra
  Future<void> disconnect() async {
    if (!kIsWeb) return;
    try {
      final window = js.webWindow;
      if (window == null) return;
      if (js_util.hasProperty(window, 'hydraClient')) {
        final client = js_util.getProperty(window, 'hydraClient');
        js_util.callMethod(client, 'disconnect', []);
      }
      _isConnected = false;
      _status = HydraStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting from Hydra: $e');
    }
  }
}
