import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this.apiService) {
    checkAutoLogin();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null || apiService.isDemoMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> checkAutoLogin() async {
    _isLoading = true;
    _errorMessage = null; // Never show startup errors on the login screen
    notifyListeners();

    // Wait for SharedPreferences to finish loading before reading sessionId
    await apiService.initialized;

    try {
      if (apiService.isDemoMode) {
        _currentUser = await apiService.getProfile();
      } else if (apiService.sessionId.isNotEmpty) {
        // Validate the saved token — throws if invalid/expired
        _currentUser = await apiService.getProfile();
      }
    } catch (_) {
      // Token is stale or server unreachable — silently clear and show login
      await apiService.clearSession();
      _currentUser = null;
      _errorMessage = null; // Don't scare the user with a connection error on startup
    }

    _isLoading = false;
    notifyListeners();
    return isAuthenticated;
  }

  Future<bool> login(String serverUrl, String db, String username, String password, {bool demo = false, String apiKey = ''}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetUrl = serverUrl.isNotEmpty ? serverUrl : apiService.baseUrl;
      final targetDb = db.isNotEmpty ? db : apiService.db;
      if (targetUrl.isNotEmpty || targetDb.isNotEmpty) {
        await apiService.saveConfig(targetUrl, targetDb, demo: demo, key: apiKey);
      }
      _currentUser = await apiService.login(username, password, targetDb);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await apiService.logout();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> resetPassword(String username, {String? newPassword, String? db}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final msg = await apiService.resetPassword(username, newPassword: newPassword, database: db);
      _isLoading = false;
      notifyListeners();
      return msg;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
