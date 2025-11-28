/// Stub implementation for js_util on non-web platforms

dynamic getProperty(dynamic o, String name) => null;
bool hasProperty(dynamic o, String name) => false;
dynamic callMethod(dynamic o, String method, List<dynamic> args) => null;
Future<T> promiseToFuture<T>(dynamic promise) async => throw UnimplementedError('Not available on this platform');
dynamic jsify(dynamic object) => null;
