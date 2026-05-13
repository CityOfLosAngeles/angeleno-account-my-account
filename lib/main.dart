import 'dart:js_interop';

import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:angeleno_project/utils/theme.dart';
import 'package:angeleno_project/views/screens/mfa_screen.dart';
import 'package:angeleno_project/views/screens/home_screen.dart';
import 'package:angeleno_project/views/screens/password_screen.dart';
import 'package:angeleno_project/views/screens/profile_screen.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

@JS('flutterEnvironment')
external set flutterEnvironment(final String value);

Future<void> main() async {

  setPathUrlStrategy();

  // Expose environment to JavaScript
  flutterEnvironment = environment;

  await DatadogSdk.runApp(datadogConfig, TrackingConsent.granted, () async {
    runApp(
      DatadogNavigationObserverProvider(
        navObserver: DatadogNavigationObserver(datadogSdk: DatadogSdk.instance),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (final _) => UserProvider()),
            ChangeNotifierProvider(create: (final _) => OverlayProvider())
          ],
          child: const MyApp()
        ),
      ),
    );
  });
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _sectionNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  observers: [
    DatadogNavigationObserver(datadogSdk: DatadogSdk.instance),
  ],
  redirect: (final BuildContext context, final GoRouterState state) {

    if (state.uri.queryParameters.isNotEmpty &&
      state.uri.queryParameters.containsKey('code')) {
      return state.uri.path; // Strips query params
    }
    return null;
  },
  onException: (final BuildContext context, final GoRouterState state, final GoRouter router) {
    router.go('/profile');
  },
  // initialLocation: '/profile',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (final context, final state, final navigationShell) => MyHomePage(navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _sectionNavigatorKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/profile',
              builder: (final context, final state) => const ProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/password-change',
              builder: (final context, final state) => const PasswordScreen(),
            )
          ]
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/multi-factor-authentication',
              builder: (final context, final state) => const AdvancedSecurityScreen(),
            )
          ]
        )
      ]
    )
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp.router(
    title: 'Angeleno Account',
    debugShowCheckedModeBanner: false,
    theme: MaterialTheme(Theme.of(context).textTheme)
        .theme(MaterialTheme.lightScheme()),
    routerConfig: router
  );
}
