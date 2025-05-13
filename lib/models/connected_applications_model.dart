class Service {
  final String id;
  final String name;
  final List<String> scope;
  final String icon;
  final String grantId;

  Service({
    required this.id,
    required this.name,
    required this.scope,
    required this.icon,
    required this.grantId
  });

  factory Service.fromJson(final Map<String, dynamic> json) => Service(
      id: json['clientId'] as String,
      name: json['name'] as String,
      scope: (json['scope'] as List<dynamic>)
          .where((final element) => element != 'openid')
          .map((final e) => e as String).toList(),
      icon: json['logo_uri'] as String? ?? '',
      grantId: json['grantId'] as String
    );

  Map<String, dynamic> toJson() => {
      'clientId': id,
      'name': name,
      'scope': scope,
      'logo_uri': icon,
      'grantId': grantId
    };
}