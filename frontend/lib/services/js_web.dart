/// Web implementation using dart:js_interop (modern approach)
/// This file is used when running on web platforms
library;

// ignore: deprecated_member_use
export 'dart:js';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: deprecated_member_use
import 'dart:js_util' as js_util;

/// Use globalThis for JavaScript interop with js_util functions
final webWindow = js_util.globalThis;

/// Access to html window for DOM operations
final htmlWindow = html.window;
