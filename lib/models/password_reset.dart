class PasswordBody {
  late String email;
  late String oldPassword;
  late String newPassword;
  late String userId;

  PasswordBody({
    required this.email,
    required this.oldPassword,
    required this.newPassword,
    required this.userId
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'oldPassword': oldPassword,
    'newPassword': newPassword,
    'userId': userId
  };
}