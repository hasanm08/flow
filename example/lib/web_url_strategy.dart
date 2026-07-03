import 'web_url_strategy_stub.dart'
    if (dart.library.js_interop) 'web_url_strategy_web.dart';

/// Configures clean path-based URLs on web (no hash `#`).
void configureWebUrlStrategy() => configureWebUrlStrategyImpl();
