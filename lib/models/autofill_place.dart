class AutofillPlace {
  String? streetNumber;
  String? street;
  String? city;
  String? zipCode;
  String? state;

  AutofillPlace(
      {this.streetNumber, this.street, this.city, this.zipCode, this.state});

  @override
  String toString() =>
      'AutofillPlace(streetNumber: $streetNumber, street: $street, city: $city, zipCode: $zipCode, state: $state)';
}
