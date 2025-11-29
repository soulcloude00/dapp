/// Stub implementation for non-web platforms
/// This file is used when running on mobile/desktop

class _JsContext {
  dynamic operator [](String key) => null;
}

final context = _JsContext();

class JsObject {
  JsObject.jsify(dynamic map);

  dynamic operator [](String key) => null;
}

final webWindow = null;
final htmlWindow = null;

dynamic allowInterop<F extends Function>(F f) => f;
