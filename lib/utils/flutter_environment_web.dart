import 'dart:js_interop';

@JS('flutterEnvironment')
external set _flutterEnvironment(final String value);

void setFlutterEnvironment(final String value) {
  _flutterEnvironment = value;
}
