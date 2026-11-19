class Service {
  final String id;
  final String name;
  final String scope;
  final String icon;
  final String loginUri;

  Service({
    required this.id,
    required this.name,
    required this.scope,
    required this.icon,
    required this.loginUri
  });

  factory Service.fromJson(final Map<String, dynamic> json) => Service(
      id: json['clientId'] as String,
      name: json['name'] as String,
      scope: json['scopes'] as String,
      icon: json['logo_uri'] as String? ?? '',
      loginUri: json['loginUri'] as String? ?? ''
    );

  Map<String, dynamic> toJson() => {
      'clientId': id,
      'name': name,
      'scope': scope,
      'logo_uri': icon,
      'loginUri': loginUri
    };
}