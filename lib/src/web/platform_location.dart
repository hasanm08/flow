import 'package:flutter/widgets.dart';

/// Reads the platform/browser URL path on startup.
String resolvePlatformLocation({String fallback = '/'}) {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  var location = platform.isNotEmpty ? platform : fallback;
  if (!location.startsWith('/')) {
    location = '/$location';
  }
  return location;
}

/// Startup location: honor deep links/direct URLs, otherwise [defaultLocation].
String resolveInitialLocation({String? defaultLocation}) {
  final platform = resolvePlatformLocation();
  if (platform != '/' || defaultLocation == null) {
    return platform;
  }
  return defaultLocation.startsWith('/')
      ? defaultLocation
      : '/$defaultLocation';
}
