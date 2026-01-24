import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Auth provider to manage authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthUser? _user;
  bool _isLoading = true;
  bool _isInitialized = false;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  /// Stream of auth state changes
  Stream<AuthUser?> get authStateChanges => _authService.authStateChanges;

  AuthProvider() {
    _initialize();
  }

  /// Initialize auth state
  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _authService.initialize();
      _user = _authService.currentUser;

      // Listen to auth state changes
      _authService.authStateChanges.listen((AuthUser? user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      });

      // Set initial loading state
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        _user = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // User canceled
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _user = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
