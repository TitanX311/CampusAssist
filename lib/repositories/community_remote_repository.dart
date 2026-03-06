// lib/repositories/community_remote_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/server_constants.dart';
import '../models/community_model.dart';

final communityDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ServerConstants.baseURL,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
});

final communityRemoteRepositoryProvider =
    Provider<CommunityRemoteRepository>((ref) {
      return CommunityRemoteRepository(ref.watch(communityDioProvider));
    });

class CommunityRemoteRepository {
  final Dio _dio;

  CommunityRemoteRepository(this._dio);

  /// GET /api/community/my-communities
  /// Fetch all communities the user has joined
  Future<List<Community>> getMyCommunities() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/community/my-communities',
      );

      final communities = response.data!['communities'] as List<dynamic>;
      return communities
          .map((e) => Community.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET /api/community/{community_id}
  /// Fetch details of a specific community
  Future<Community> getCommunityById(String communityId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/community/$communityId',
      );

      return Community.fromMap(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/community/{community_id}/join
  /// Join a community
  Future<Community> joinCommunity(String communityId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/community/$communityId/join',
      );

      return Community.fromMap(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DELETE /api/community/{community_id}/leave
  /// Leave a community
  Future<void> leaveCommunity(String communityId) async {
    try {
      await _dio.delete('/api/community/$communityId/leave');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/community
  /// Create a new community
  Future<Community> createCommunity({
    required String name,
    required String type,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/community',
        data: {'name': name, 'type': type},
      );
      return Community.fromMap(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network.';
      case DioExceptionType.connectionError:
        return 'Could not reach server. Is it running?';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode}). Please try again.';
      default:
        return 'Network error. Please try again.';
    }
  }
}
