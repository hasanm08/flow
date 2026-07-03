import 'package:flow_routing/flow_routing.dart';

/// Tab values for user profile routes.
enum UserTab { overview, activity, settings }

/// Home dashboard route.
final class HomeRoute extends FlowRoute {
  const HomeRoute();
  @override
  String get name => 'home';
  @override
  String get pathTemplate => '/home';
}

/// Explore / discovery route.
final class ExploreRoute extends FlowRoute {
  const ExploreRoute();
  @override
  String get name => 'explore';
  @override
  String get pathTemplate => '/explore';
}

/// User profile list route.
final class ProfileRoute extends FlowRoute {
  const ProfileRoute();
  @override
  String get name => 'profile';
  @override
  String get pathTemplate => '/profile';
}

/// User detail route with typed parameters.
final class UserRoute extends FlowRoute {
  const UserRoute({required this.id, this.tab = UserTab.overview});

  final int id;
  final UserTab tab;

  @override
  String get name => 'user';

  @override
  String get pathTemplate => '/users/:id';

  @override
  Map<String, String> get pathParameters => {'id': '$id'};

  @override
  Map<String, String> get queryParameters =>
      tab == UserTab.overview ? const {} : {'tab': tab.name};
}

/// App settings route.
final class SettingsRoute extends FlowRoute {
  const SettingsRoute();
  @override
  String get name => 'settings';
  @override
  String get pathTemplate => '/settings';
}

/// Login route for auth guard demo.
final class LoginRoute extends FlowRoute {
  const LoginRoute({this.returnTo});
  final String? returnTo;

  @override
  String get name => 'login';
  @override
  String get pathTemplate => '/login';

  @override
  Map<String, String> get queryParameters =>
      returnTo == null ? const {} : {'returnTo': returnTo!};
}

/// About / info route (pushed as overlay).
final class AboutRoute extends FlowRoute {
  const AboutRoute();
  @override
  String get name => 'about';
  @override
  String get pathTemplate => '/about';
}
