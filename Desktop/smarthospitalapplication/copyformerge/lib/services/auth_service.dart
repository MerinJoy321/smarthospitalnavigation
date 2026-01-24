import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple user model for authentication
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );
}

/// Authentication service (works without Firebase)
class AuthService {
  static const String _userIdKey = 'auth_user_id';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userNameKey = 'auth_user_name';
  static const String _isAuthenticatedKey = 'auth_is_authenticated';

  AuthUser? _currentUser;
  final _authStateController = StreamController<AuthUser?>.broadcast();

  /// Get current user
  AuthUser? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Stream of auth state changes
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  /// Sign in with Google (simulated for now - just creates a session)
  Future<AuthUser?> signInWithGoogle() async {
    try {
      // Simulate a brief sign-in delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Create a simulated user (in production, this would come from Google)
      final user = AuthUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@hospital.org',
        displayName: 'Hospital User',
        photoUrl: null,
      );

      // Save to preferences
      await _saveUser(user);
      
      _currentUser = user;
      _authStateController.add(user);

      return user;
    } catch (e) {
      throw AuthException('Failed to sign in: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _clearUser();
      _currentUser = null;
      _authStateController.add(null);
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  /// Save user to shared preferences
  Future<void> _saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, true);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userEmailKey, user.email);
    if (user.displayName != null) {
      await prefs.setString(_userNameKey, user.displayName!);
    }
  }

  /// Clear user from shared preferences
  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }

  /// Check if session exists and restore user
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  /// Initialize auth state (restore existing session)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(_isAuthenticatedKey) ?? false;
    
    if (isAuthenticated) {
      final userId = prefs.getString(_userIdKey);
      final userEmail = prefs.getString(_userEmailKey);
      
      if (userId != null && userEmail != null) {
        _currentUser = AuthUser(
          id: userId,
          email: userEmail,
          displayName: prefs.getString(_userNameKey),
        );
        _authStateController.add(_currentUser);
      }
    }
  }

  /// Dispose the controller
  void dispose() {
    _authStateController.close();
  }
}

/// Custom auth exception
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
