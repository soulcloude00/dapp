/// Web implementation using dart:js context
/// This file is used when running on web platforms
library;

// ignore: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

// Export the global context from dart:js
js.JsObject get context => js.context;
