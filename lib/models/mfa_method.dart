class MfaMethod {
  String id;
  String authenticatorType;
  bool active;
  String oobChannel;
  String name;

  MfaMethod({
    this.id = '',
    this.authenticatorType = '',
    this.active = false,
    this.oobChannel = '',
    this.name = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'authenticator_type': authenticatorType,
    'active': active,
    'oob_channel': oobChannel,
    'name': name
  };

  factory MfaMethod.fromJson(final Map<String, dynamic> json) => MfaMethod(
    id: json['id'] as String? ?? '',
    authenticatorType: json['authenticator_type'] as String? ?? '',
    active: json['active'] as bool? ?? false,
    oobChannel: json['oob_channel'] as String? ?? '',
    name: json['name'] as String? ?? ''
  );
}