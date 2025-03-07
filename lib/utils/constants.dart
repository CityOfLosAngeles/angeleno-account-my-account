import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:datadog_tracking_http_client/datadog_tracking_http_client.dart';
import 'package:flutter/material.dart';

/* Environment variables */
const auth0ClientId = String.fromEnvironment('CLIENT_ID');
const auth0Domain = String.fromEnvironment('AUTH0_DOMAIN');
const redirectUri = String.fromEnvironment('REDIRECT_URI');
const cloudFunctionURL =
    String.fromEnvironment('CLOUD_FUNCTIONS_URL');
const serviceAccountSecret = String.fromEnvironment('SA_SECRET_KEY');
const serviceAccountEmail = String.fromEnvironment('SA_EMAIL');
const environment = String.fromEnvironment('ENVIRONMENT');

/* Datadog */
const datadogClientToken = String.fromEnvironment('DATADOG_CLIENT_TOKEN');
const dataDogApplicationId = String.fromEnvironment('DATADOG_APP_ID');
final datadogConfig = DatadogConfiguration(
    clientToken: datadogClientToken,
    env: 'env',
    site: DatadogSite.us5,
    nativeCrashReportEnabled: true,
    loggingConfiguration: DatadogLoggingConfiguration(),
    rumConfiguration: DatadogRumConfiguration(
      applicationId: dataDogApplicationId,
      reportFlutterPerformance: true
    )
)..enableHttpTracking();
final logConfiguration = DatadogLoggerConfiguration();
final logger = DatadogSdk.instance.logs?.createLogger(logConfiguration);

/* Regex */
final RegExp nameRegEx = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-\d]*$");

/* Media Query Breakpoints */
const double smallScreen = 575;

/* Text Styles */
const headerStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold
);