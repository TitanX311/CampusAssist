// lib/repositories/post_remote_repository.dart
import 'package:campusassist/core/interceptors/auth_interceptor.dart';
import 'package:campusassist/core/server_constants.dart';
import 'package:campusassist/models/post_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final postDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ServerConstants.baseURL,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  return dio;
});

final postRemoteRepositoryProvider = Provider<PostRemoteRepository>((ref) {
  return PostRemoteRepository(ref.read(postDioProvider));
});

class PostRemoteRepository {
  final Dio _dio;

  PostRemoteRepository(this._dio);

  /// GET /api/posts/community/{community_id}
  Future<List<Post>> getPostsByCommunity(String communityId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/posts/community/$communityId',
      );
      final posts = response.data!['posts'] as List<dynamic>;
      return posts
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET /api/posts/{post_id}
  Future<Post> getPostById(String postId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/posts/$postId',
      );
      return Post.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/posts
  Future<Post> createPost({
    required String communityId,
    required String content,
    List<String> attachments = const [],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/posts',
        data: {
          'community_id': communityId,
          'content': content,
          'attachments': attachments,
        },
      );
      return Post.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// PATCH /api/posts/{post_id}
  Future<Post> updatePost(String postId, {String? content}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/posts/$postId',
        data: {if (content != null) 'content': content},
      );
      return Post.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DELETE /api/posts/{post_id}
  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('/api/posts/$postId');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/posts/{post_id}/like (toggle like/unlike)
  Future<void> likePost(String postId) async {
    try {
      await _dio.post('/api/posts/$postId/like');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/posts/{post_id}/comments
  Future<Comment> addComment(String postId, String body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/posts/$postId/comments',
        data: {'body': body},
      );
      return Comment.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DELETE /api/posts/{post_id}/comments/{comment_id}
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _dio.delete('/api/posts/$postId/comments/$commentId');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final message =
        (e.response?.data is Map
            ? (e.response!.data as Map)['detail']
            : null) ??
        e.message ??
        'Something went wrong';
    if (status == 404) return Exception('Not found');
    if (status == 401 || status == 403) return Exception('Unauthorized');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection');
    }
    return Exception(message);
  }
}
