// lib/repositories/community_remote_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/interceptors/auth_interceptor.dart';
import '../core/server_constants.dart';
import '../models/community_model.dart';

final communityDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ServerConstants.baseURL,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  return dio;
});

final communityRemoteRepositoryProvider = Provider<CommunityRemoteRepository>((
  ref,
) {
  return CommunityRemoteRepository(ref.watch(communityDioProvider));
});

class CommunityRemoteRepository {
  final Dio _dio;

  CommunityRemoteRepository(this._dio);

  /// GET /api/community/my-communities
  Future<List<Community>> getMyCommunities() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/community/my-communities',
      );
      final data = response.data!;
      final raw =
          (data['communities'] ?? data['items'] ?? data['data'] ?? [])
              as List<dynamic>?;
      return (raw ?? [])
          .map((e) => Community.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET /api/community/{community_id}
  Future<Community> getCommunityById(String communityId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/community/$communityId',
      );
      return Community.fromMap(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/community/{community_id}/join
  Future<Community> joinCommunity(String communityId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/community/$communityId/join',
      );
      return Community.fromMap(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DELETE /api/community/{community_id}/leave
  Future<void> leaveCommunity(String communityId) async {
    try {
      await _dio.delete('/community/$communityId/leave');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/community
  Future<Community> createCommunity({
    required String name,
    required String type,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/community',
        data: {'name': name, 'type': type},
      );
      return Community.fromMap(response.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 409) {
        throw 'A community with this name already exists.';
      }
      throw _mapDioError(e);
    }
  }

  String _mapDioError(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      switch (e.response?.statusCode) {
        case 409:
          return 'A community with this name already exists.';
        case 401:
          return 'Unauthorized. Please log in again.';
        case 403:
          return 'You do not have permission to do this.';
        default:
          return 'Server error (${e.response?.statusCode}). Please try again.';
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network.';
      case DioExceptionType.connectionError:
        return 'Could not reach server. Is it running?';
      default:
        return 'Network error. Please try again.';
    }
  }
}
