/// Stub for dart:js context on non-web platforms

class _StubContext {
  bool hasProperty(String name) => false;
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
}

final context = _StubContext();
