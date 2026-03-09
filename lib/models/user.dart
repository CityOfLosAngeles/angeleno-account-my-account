class User {
  String userId;
  String email;
  String? firstName;
  String? lastName;
  String? zip;
  String? address;
  String? address2;
  String? city;
  String? state;
  String? phone;
  Map<String, dynamic>? metadata;
  Map<String, dynamic> appMetadata = {};
  Map<String, String> consentedApps = {};

  User({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.address2,
    required this.city,
    required this.state,
    required this.zip,
    required this.phone,
    required this.metadata,
    required this.appMetadata,
    required this.consentedApps
  });

  User.copy(final User copy) :
    userId = copy.userId,
    email = copy.email,
    firstName = copy.firstName,
    lastName = copy.lastName,
    address = copy.address,
    address2 = copy.address2,
    city = copy.city,
    state = copy.state,
    zip = copy.zip,
    phone = copy.phone,
    metadata = copy.metadata;

  @override
  bool operator ==(final Object other) => other is User &&
    other.firstName == firstName &&
    other.lastName == lastName &&
    other.zip == zip &&
    other.address == address &&
    other.address2 == address2 &&
    other.city == city &&
    other.phone == phone &&
    other.state == state;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'address': address,
    'address2': address2,
    'city': city,
    'state': state,
    'zip': zip,
    'phone': phone,
    'metadata': metadata
  };

  @override
  String toString() =>
      '{id: $userId, email: $email, firstName: $firstName, lastName: $lastName,'
      ' zip: $zip, address: $address, address2: $address2, city: $city,' 
      ' state: $state, phone: $phone}';

  @override
  int get hashCode => firstName.hashCode ^ lastName.hashCode ^
    zip.hashCode ^ address.hashCode ^ address2.hashCode ^ city.hashCode ^
    state.hashCode ^ phone.hashCode;
}

class Address {
  String address;
  String address2;
  String city;
  String state;
  String zip;

  Address({
    this.address = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.zip = ''
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'address2': address2,
    'city': city,
    'state': state,
    'zip': zip
  };

  factory Address.fromJson(final Map<String, dynamic> json) => Address(
    address: json['address'] as String? ?? '',
    address2: json['address2'] as String? ?? '',
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    zip: json['zip'] as String? ?? ''
  );
}