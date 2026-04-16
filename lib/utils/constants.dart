import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:datadog_tracking_http_client/datadog_tracking_http_client.dart';
import 'package:flutter/material.dart';

/* Environment variables */
const auth0ClientId = String.fromEnvironment('CLIENT_ID');
const auth0Domain = String.fromEnvironment('AUTH0_DOMAIN');
const auth0NonCustomDomain = String.fromEnvironment('AUTH0_NON_CUSTOM_DOMAIN');
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
    env: environment,
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
const double smallScreenWidthBreakpoint = 575;

/* Text Styles */
const headerStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold
);

/* Navigation ENUM */
enum NavigationItem {
    profile('Profile'),
    password('Password Change'),
    mfa('Multi-factor authentication'),
    connectedApps('Your connected partner\nservices');

    const NavigationItem(this.value);
    final String value;
}

/* Utility Class */
class Constants {
  static String formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp == 0) return 'Unknown';
    final ms = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
    if (ms == 0) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
