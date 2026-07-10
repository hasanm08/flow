import 'package:flow_routing/flow_routing.dart';

/// Tab values for user profile routes.
enum UserTab { overview, activity, settings }

/// App route instances — no classes, just values.
///
/// ```dart
/// context.flow(Routes.home);
/// context.flow(Routes.user(id: 42));
/// context.flowNamed('user', pathParameters: {'id': '42'});
/// ```
abstract final class Routes {
  Routes._();

  static const home = FlowRoute(name: 'home', pathTemplate: '/home');
  static const explore = FlowRoute(name: 'explore', pathTemplate: '/explore');
  static const profile = FlowRoute(name: 'profile', pathTemplate: '/profile');
  static const settings = FlowRoute(name: 'settings', pathTemplate: '/settings');
  static const about = FlowRoute(name: 'about', pathTemplate: '/about');
  static const login = FlowRoute(name: 'login', pathTemplate: '/login');

  static FlowRoute user({required int id, UserTab tab = UserTab.overview}) =>
      FlowRoute(
        name: 'user',
        pathTemplate: '/users/:id',
        pathParameters: {'id': '$id'},
        queryParameters: tab == UserTab.overview
            ? const {}
            : {'tab': tab.name},
      );

  static FlowRoute loginWithReturn(String returnTo) => FlowRoute(
    name: 'login',
    pathTemplate: '/login',
    queryParameters: {'returnTo': returnTo},
  );
}
