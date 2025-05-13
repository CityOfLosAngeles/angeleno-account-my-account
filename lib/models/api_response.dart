class ApiResponse implements Exception {
  final int statusCode;
  final String body;

  ApiResponse(this.statusCode, this.body);
}
