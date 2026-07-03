import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/widgets.dart';

import '../navigation/navigation_engine.dart';
import '../web/imperative_url_policy.dart';
import '../web/platform_location.dart';

/// Syncs navigation state with the platform URL bar (web, deep links).
///
/// Extends [PlatformRouteInformationProvider] so the [Router] can report
/// route changes back to the browser via [SystemNavigator.routeInformationUpdated].
final class FlowRouteInformationProvider extends PlatformRouteInformationProvider {
  FlowRouteInformationProvider({
    required this.engine,
    this.defaultLocation = '/',
    this.imperativeUrlPolicy = ImperativeUrlPolicy.declarativeOnly,
  }) : super(
         initialRouteInformation: RouteInformation(
           uri: Uri.parse(
             resolveInitialLocation(defaultLocation: defaultLocation),
           ),
         ),
       );

  final NavigationEngine engine;
  final String defaultLocation;
  final ImperativeUrlPolicy imperativeUrlPolicy;
}
