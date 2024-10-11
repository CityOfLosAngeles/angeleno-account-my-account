class AutofillSuggestion {
  final String? placeId;
  final String? description;
  final String? streetAddress; //This is StreetNumber and Street combined
  /*
  final String? streetNumber;
  final String? street;
  final String? city;
  final String? zipCode;
  final String? state;
**/
  AutofillSuggestion(this.placeId, this.description, this.streetAddress);
  //AutofillSuggestion(this.placeId, this.description, this.streetAddress, this.streetNumber, this.street, this.city, this.zipCode, this.state);

  @override
  // ignore: lines_longer_than_80_chars
  String toString() =>
      'AutofillSuggestion(description: $description, placeId: $placeId, streetAddress: $streetAddress)';
}
