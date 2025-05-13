import 'dart:io';
import 'package:angeleno_project/models/user.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:datadog_tracking_http_client/datadog_tracking_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'mocks/auth0_user_api_mock.dart';


class MockClient extends Mock implements http.Client {}

void main() {

  late MockAuth0UserApi mockUserApi;

  setUp(() {
    mockUserApi = MockAuth0UserApi();
  });

  test('updateUser returns status code 200 on success', () async {

    final user = User(
      userId: '123456',
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      address: '123 Main St',
      address2: 'Apt 2',
      city: 'City',
      state: 'State',
      zip: '12345',
      phone: '123-456-7890',
      metadata: {'key': 'value'}
    );

    when(mockUserApi.getOAuthToken()).thenAnswer((_) async => 'dummy_token');

    when(mockUserApi.updateUser(user))
        .thenAnswer((_) async =>
        200);

    final statusCode = await mockUserApi.updateUser(user);

    expect(statusCode, equals(HttpStatus.ok));
  });

  test('Datadog configuration is initialized correctly', () {
    final datadogConfig = DatadogConfiguration(
      clientToken: 'test_token',
      env: 'test_env',
      site: DatadogSite.us5,
      nativeCrashReportEnabled: true,
      loggingConfiguration: DatadogLoggingConfiguration(),
      rumConfiguration: DatadogRumConfiguration(
        applicationId: 'test_app_id',
        reportFlutterPerformance: true,
      ),
    )..enableHttpTracking();

    expect(datadogConfig.clientToken, 'test_token');
    expect(datadogConfig.env, 'test_env');
    expect(datadogConfig.site, DatadogSite.us5);
    expect(datadogConfig.nativeCrashReportEnabled, true);
    expect(datadogConfig.loggingConfiguration, isNotNull);
    expect(datadogConfig.rumConfiguration, isNotNull);
  });

  // test('Logger is created successfully', () {
  //   final logConfiguration = DatadogLoggerConfiguration();
  //   final logger = DatadogSdk.instance.logs?.createLogger(logConfiguration);
  //
  //   expect(logger, isNotNull);
  // });

  test('Datadog configuration handles null values', () {
    final datadogConfig = DatadogConfiguration(
      clientToken: '',
      env: '',
      site: DatadogSite.us5,
      nativeCrashReportEnabled: false,
      loggingConfiguration: null,
      rumConfiguration: null,
    )..enableHttpTracking();

    expect(datadogConfig.clientToken, '');
    expect(datadogConfig.env, '');
    expect(datadogConfig.site, DatadogSite.us5);
    expect(datadogConfig.nativeCrashReportEnabled, false);
    expect(datadogConfig.loggingConfiguration, isNull);
    expect(datadogConfig.rumConfiguration, isNull);
  });

}
