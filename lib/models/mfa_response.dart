class MfaResponse {
  String barcode; // TOTP
  String token;
  String barcodeString; // TOTP
  String oobCode; // SMS/Voice
  String errorMessage = '';

  MfaResponse({
    this.barcode = '',
    this.token = '',
    this.barcodeString = '',
    this.oobCode = '',
    this.errorMessage = ''
  }) {
    barcode = barcode;
    token = token;
    barcodeString = barcodeString;
    oobCode = oobCode;
    errorMessage = errorMessage;
  }

  @override
  String toString() => '{barcode: $barcode, token: $token, barcodeString: $barcodeString, oobCode: $oobCode}';

  factory MfaResponse.fromJson(final Map<String, dynamic> json) => MfaResponse(
      token: json['token'] as String? ?? '',
      barcode: json['barcode_uri'] as String? ?? '',
      barcodeString: json['secret'] as String? ?? '',
      oobCode: json['oob_code'] as String? ?? '',
      errorMessage: json['error'] as String? ?? ''
    );
}