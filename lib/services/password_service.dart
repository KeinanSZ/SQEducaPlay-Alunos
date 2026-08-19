import 'package:bcrypt/bcrypt.dart';

class PasswordService {
  static bool isHashed(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2y$');
  }

  static String hashPassword(String plainText) {
    return BCrypt.hashpw(plainText, BCrypt.gensalt());
  }

  static bool verifyPassword(String plainText, String stored) {
    if (!isHashed(stored)) return false;
    return BCrypt.checkpw(plainText, stored);
  }

  static String hashIfNeeded(String password) {
    return isHashed(password) ? password : hashPassword(password);
  }
}
