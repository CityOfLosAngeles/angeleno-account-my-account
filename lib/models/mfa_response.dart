class MfaResponse {
  final String barcode; // TOTP
  final String token;
  final String barcodeString; // TOTP
  final String oobCode; // SMS/Voice

  MfaResponse({
    required this.barcode,
    required this.token,
    required this.barcodeString,
    required this.oobCode
  });

  @override
  String toString() => 'MfaResponse{barcode: $barcode, token: $token, barcodeString: $barcodeString, oobCode: $oobCode}';

  factory MfaResponse.fromJson(final Map<String, dynamic> json) => MfaResponse(
      token: json['token'] as String? ?? '',
      barcode: json['barcode_uri'] as String? ?? '',
      barcodeString: json['secret'] as String? ?? '',
      oobCode: json['oob_code'] as String? ?? ''
    );
}