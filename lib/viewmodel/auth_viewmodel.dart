import 'dart:async';

import 'package:campusassist/models/user_model.dart';
import 'package:campusassist/repositories/auth_remote_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_local_repository.dart';

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, UserModel?>(
  AuthViewModel.new,
);

class AuthViewModel extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final local = ref.read(authLocalRepositoryProvider);

    print("Checking refresh token...");

    final token = await local.getRefreshToken();
    print("Refresh token: $token");

    if (token == null) {
      print("No token found");
      return null;
    }

    try {
      print("Refreshing session...");
      final user = await ref
          .read(authRemoteRepositoryProvider)
          .refreshSession(token);

      print("Session refreshed");

      await local.saveTokens(user.accessToken, user.refreshToken);

      return user;
    } catch (e) {
      print("Refresh failed: $e");
      await local.clearTokens();
      return null;
    }
  }

  Future<UserModel?> googleSignIn() async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => ref.read(authRemoteRepositoryProvider).googleSignIn(),
    );

    if (result.hasValue && result.value != null) {
      final local = ref.read(authLocalRepositoryProvider);
      await local.saveTokens(
        result.value!.accessToken,
        result.value!.refreshToken,
      );
    }

    state = result;
    return result.value;
  }

  Future<void> signOut() async {
    final local = ref.read(authLocalRepositoryProvider);
    final remote = ref.read(authRemoteRepositoryProvider);

    final refreshToken = await local.getRefreshToken();

    if (refreshToken != null) {
      try {
        await remote.signOut(refreshToken);
      } catch (_) {
        // even if backend logout fails we still clear local tokens
      }
    }

    await local.clearTokens();

    state = const AsyncData(null);
  }
}
