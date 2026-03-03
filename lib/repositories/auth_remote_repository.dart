// /repositories/auth_remote_repository.dart
import 'package:campusassist/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authDioProvider = Provider<Dio>((ref) => Dio());

final authRepositoryProvider = Provider<AuthRemoteRepository>((ref) {
  return AuthRemoteRepository(ref.read(authDioProvider));
});

class AuthRemoteRepository {
  final Dio _dio;

  AuthRemoteRepository(this._dio);

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '',
        data: {'email': email, 'password': password},
      );
      final user = UserModel.fromMap(response.data);
      return user;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<UserModel> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '',
        data: {'name': name, 'email': email, 'password': password},
      );
      final user = UserModel.fromMap(response.data);
      return user;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  // Future<UserModel> googleSignIn() async {
  //   try {
  //
  //   }
  // }
}
