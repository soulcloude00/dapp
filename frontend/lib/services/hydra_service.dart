import 'dart:async';

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
      // msg might be a JS object, need to convert to Dart map
      // For simplicity, let's assume it's passed as JSON string or we can parse it
      // If it's a JS object, we might need to use js_util to read properties

      // Actually, let's assume the JS side passes a JSON string to avoid interop issues
      // But if it passes an object, we can try to convert.

      // For now, just logging
      debugPrint('Hydra Message received in Dart');
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
}
