import 'package:angeleno_project/models/user.dart';
import '../models/password_reset.dart';
import '../utils/constants.dart';

abstract class Api {

  final String baseUrl = cloudFunctionURL;

  void updateUser(final User user);

  void updatePassword(final PasswordBody body);

  void getAuthenticationMethods(final String userId);

  void enrollMFA(final Map<String, String> body);

  void confirmMFA(final Map<String, String> body);

  void unenrollMFA(final Map<String, String> body);

  void removeConnection(final String connectionId);
}