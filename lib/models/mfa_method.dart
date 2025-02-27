class MfaMethod {
  late String id;
  late String authenticatorType;
  late bool active;
  late String oobChannel;
  late String name;

  MfaMethod({
    String id = '',
    String authenticatorType = '',
    bool active = false,
    String oobChannel = '',
    String name = '',
  }) {
    id = id;
    authenticatorType = authenticatorType;
    active = active;
    oobChannel = oobChannel;
    name = name;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authenticator_type': authenticatorType,
    'active': active,
    'oob_channel': oobChannel,
    'name': name
  };

  MfaMethod.fromJson(final Map<String, dynamic> json) {
    id = json['id']! as String;
    authenticatorType = json['authenticator_type']! as String;
    active = json['active'] as bool;
    oobChannel = json['oob_channel'] != null ? json['oob_channel'] as String : '';
    name = json['name'] != null ? json['name'] as String : '';
  }
}