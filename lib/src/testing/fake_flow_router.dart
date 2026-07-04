import 'package:flutter/foundation.dart';

import '../navigation/navigation_engine.dart';
import '../navigation/navigation_intent.dart';
import '../navigation/navigation_result.dart';
import '../typed_routes/flow_route.dart';

/// Test double that records navigation intents without building widgets.
final class FakeFlowRouter extends ChangeNotifier {
  FakeFlowRouter({this._engine});

  NavigationEngine? _engine;
  final List<NavigationIntent> intents = [];

  void attach(NavigationEngine engine) => _engine = engine;

  Future<NavigationResult?> dispatch(NavigationIntent intent) async {
    intents.add(intent);
    notifyListeners();
    return _engine?.dispatch(intent);
  }

  Future<void> go(FlowRoute route, {Object? extra}) async {
    await dispatch(GoIntent(route, extra: extra));
  }

  Future<void> push(FlowRoute route, {Object? extra}) async {
    await dispatch(PushIntent(route, extra: extra));
  }

  bool get hasGoIntents => intents.any((i) => i is GoIntent);
  bool get hasPushIntents => intents.any((i) => i is PushIntent);

  void clear() => intents.clear();
}
