import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Admin user model
class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role;

  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'admin',
  });
}

/// Admin authentication service
/// Uses mock credentials for demo purposes
class AdminAuthService {
  static const String _adminSessionKey = 'admin_session_active';
  static const String _adminEmailKey = 'admin_email';

  // Mock admin credentials (for demo)
  static const Map<String, String> _mockAdmins = {
    'admin@hospital.org': 'admin123',
    'supervisor@hospital.org': 'super123',
  };

  AdminUser? _currentAdmin;
  final _authStateController = StreamController<AdminUser?>.broadcast();

  AdminUser? get currentAdmin => _currentAdmin;
  bool get isAuthenticated => _currentAdmin != null;
  Stream<AdminUser?> get authStateChanges => _authStateController.stream;

  /// Sign in with email and password (mock-based)
  Future<AdminUser?> signIn(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check mock credentials
    final storedPassword = _mockAdmins[email.toLowerCase()];
    if (storedPassword == null || storedPassword != password) {
      throw AdminAuthException('Invalid email or password');
    }

    // Create admin user
    final admin = AdminUser(
      id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
      email: email.toLowerCase(),
      name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
    );

    // Save session
    await _saveSession(admin);
    
    _currentAdmin = admin;
    _authStateController.add(admin);

    return admin;
  }

  /// Sign out
  Future<void> signOut() async {
    await _clearSession();
    _currentAdmin = null;
    _authStateController.add(null);
  }

  /// Save admin session
  Future<void> _saveSession(AdminUser admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminSessionKey, true);
    await prefs.setString(_adminEmailKey, admin.email);
  }

  /// Clear admin session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminSessionKey);
    await prefs.remove(_adminEmailKey);
  }

  /// Check for existing session and restore
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSession = prefs.getBool(_adminSessionKey) ?? false;
    
    if (hasSession) {
      final email = prefs.getString(_adminEmailKey);
      if (email != null && _mockAdmins.containsKey(email)) {
        _currentAdmin = AdminUser(
          id: 'admin_restored',
          email: email,
          name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
        );
        _authStateController.add(_currentAdmin);
      }
    }
  }

  void dispose() {
    _authStateController.close();
  }
}

class AdminAuthException implements Exception {
  final String message;
  AdminAuthException(this.message);

  @override
  String toString() => message;
}
