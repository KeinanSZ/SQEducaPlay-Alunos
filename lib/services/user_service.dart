import '../models/user_model.dart';
import 'password_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final List<User> _users = [];
  String? _currentUsername;

  void addAdminUser(String username, String password, {String? fullName}) {
    final normalized = normalizeUsername(username);
    _users.add(User(
      username: normalized,
      password: PasswordService.hashPassword(password),
      fullName: fullName ?? normalized,
      role: 'admin',
    ));
  }

  User? login(String username, String password) {
    final normalizedUsername = username.trim().toLowerCase();
    for (final user in _users) {
      if (user.username.toLowerCase() == normalizedUsername) {
        return PasswordService.verifyPassword(password, user.password) ? user : null;
      }
    }
    return null;
  }

  void register(User newUser) {
    final normalized = normalizeUsername(newUser.username);

    final validationError = validateUsername(normalized);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    if (newUser.role == 'student' && (newUser.schoolId == null || newUser.schoolId!.isEmpty)) {
      throw ArgumentError('Para criar conta de aluno, selecione a escola.');
    }

    if (newUser.fullName.trim().isEmpty) {
      throw ArgumentError('Informe seu nome completo.');
    }

    final exists = _users.any((u) => u.username.toLowerCase() == normalized.toLowerCase());
    if (exists) {
      throw ArgumentError('Este nome de usuário já está em uso.');
    }

    _users.add(newUser.copy(
      username: normalized,
      fullName: newUser.fullName.trim(),
      password: PasswordService.hashPassword(newUser.password),
    ));

    _currentUsername = normalized;
  }

  User? getUserByUsername(String username) {
    final normalizedUsername = username.trim().toLowerCase();
    for (final user in _users) {
      if (user.username.toLowerCase() == normalizedUsername) {
        return user;
      }
    }
    return null;
  }

  void addUserFromDb(User user) {
    final normalized = normalizeUsername(user.username);
    final idx = _users.indexWhere((u) => u.username.toLowerCase() == normalized.toLowerCase());
    final newUser = user.copy(username: normalized);
    if (idx >= 0) {
      _users[idx] = newUser;
    } else {
      _users.add(newUser);
    }

    _currentUsername = normalized;
  }

  User? get currentUser {
    if (_currentUsername == null) return null;
    return getUserByUsername(_currentUsername!);
  }

  void setCurrentUser(User user) {
    _currentUsername = normalizeUsername(user.username);
  }

  void clearCurrentUser() {
    _currentUsername = null;
  }

  List<User> getAllUsers() => List.unmodifiable(_users);

  bool existsUsername(String username) {
    final normalized = normalizeUsername(username);
    return _users.any((u) => u.username.toLowerCase() == normalized.toLowerCase());
  }

  String normalizeUsername(String value) {
    final trimmed = value.trim();
    return trimmed.replaceAll(RegExp(r"\s+"), '_');
  }

  String? validateUsername(String value) {
    if (value.isEmpty) return 'Por favor, insira um nome.';
    if (value.length < 3 || value.length > 20) {
      return 'O nome deve ter entre 3 e 20 caracteres.';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!regex.hasMatch(value)) {
      return 'Use apenas letras, números e . _ - (sem espaços).';
    }
    return null;
  }
}
