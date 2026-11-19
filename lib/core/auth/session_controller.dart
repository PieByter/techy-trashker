import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/app_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController({AppRepository? repository})
    : repository = repository ?? AppRepository(ApiClient()) {
    this.repository.api.onSessionExpired = _handleSessionExpired;
  }

  final AppRepository repository;

  bool isInitialized = false;
  bool isBusy = false;
  bool isAuthenticated = false;
  UserProfile? profile;
  String? errorMessage;

  void _handleSessionExpired() {
    profile = null;
    isAuthenticated = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (isInitialized) return;
    try {
      final token = await repository.api.tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          profile = await repository.getProfile();
          isAuthenticated = true;
        } catch (_) {
          await repository.api.tokenStore.clear();
        }
      }
    } catch (_) {
      // Secure storage may be unavailable in a browser's private context.
      try {
        await repository.api.tokenStore.clear();
      } catch (_) {
        // Continue to the unauthenticated state.
      }
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await repository.login(email: email, password: password);
      await repository.api.tokenStore.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      profile = UserProfile.fromJson(session.profile);
      isAuthenticated = true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      isBusy = false;
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await repository.register(
        name: name,
        email: email,
        password: password,
      );
      await repository.api.tokenStore.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      profile = UserProfile.fromJson(session.profile);
      isAuthenticated = true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      isBusy = false;
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    profile = await repository.getProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.logout();
    } finally {
      profile = null;
      isAuthenticated = false;
      isBusy = false;
      notifyListeners();
    }
  }
}
