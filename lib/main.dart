import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:angeleno_project/utils/theme.dart';
import 'package:angeleno_project/views/screens/home_screen.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';


Future<void> main() async {
  setPathUrlStrategy();

  await DatadogSdk.runApp(datadogConfig, TrackingConsent.granted, () async {
    runApp(
        MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (final _) => UserProvider()),
              ChangeNotifierProvider(create: (final _) => OverlayProvider())
            ],
            child: const MyApp()
        )
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp(
    title: 'Angeleno - My Account '
        '${environment == 'prod' ? '' : ' - $environment'}',
    debugShowCheckedModeBanner: false,
    theme: MaterialTheme(Theme.of(context).textTheme)
        .theme(MaterialTheme.lightScheme()),
    darkTheme: MaterialTheme(Theme.of(context).textTheme)
        .theme(MaterialTheme.darkScheme()),
    navigatorObservers: [
      DatadogNavigationObserver(datadogSdk: DatadogSdk.instance),
    ],
    onGenerateRoute: (final settings) => MaterialPageRoute(
      builder: (final context) => const MyHomePage(),
      settings: const RouteSettings(name: '/')
    ),
    home: const MyHomePage()
  );
}