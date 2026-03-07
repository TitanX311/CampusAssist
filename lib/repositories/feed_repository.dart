// lib/repositories/feed_repository.dart
import 'package:campusassist/core/interceptors/auth_interceptor.dart';
import 'package:campusassist/core/server_constants.dart';
import 'package:campusassist/models/feed_item_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  // Trailing slash is required so Dio appends paths correctly:
  // baseUrl = "http://host/api/"  +  "feed/my"  → "http://host/api/feed/my"
  final dio = Dio(
    BaseOptions(
      baseUrl: '${ServerConstants.baseURL}/',
      connectTimeout: const Duration(seconds: 15),
      // Feed endpoint builds a Redis cache on first call — can take 30-60 s
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  return FeedRepository(dio);
});

class FeedRepository {
  final Dio _dio;

  FeedRepository(this._dio);

  /// GET /api/feed/my — personalised feed (cursor-based)
  Future<FeedPage> getMyFeed({int cursor = 0, int pageSize = 20}) async {
    try {
      debugPrint('[FeedRepo] baseUrl=${_dio.options.baseUrl}');
      debugPrint('[FeedRepo] GET /feed/my cursor=$cursor pageSize=$pageSize');
      final res = await _dio.get<Map<String, dynamic>>(
        'feed/my',
        queryParameters: {'cursor': cursor, 'page_size': pageSize},
      );
      return FeedPage.fromJson(res.data!, isIndia: false);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /api/feed/india — across-India trending feed (cursor-based)
  Future<FeedPage> getIndiaFeed({int cursor = 0, int pageSize = 20}) async {
    try {
      debugPrint('[FeedRepo] baseUrl=${_dio.options.baseUrl}');
      debugPrint(
        '[FeedRepo] GET /feed/india cursor=$cursor pageSize=$pageSize',
      );
      final res = await _dio.get<Map<String, dynamic>>(
        'feed/india',
        queryParameters: {'cursor': cursor, 'page_size': pageSize},
      );
      return FeedPage.fromJson(res.data!, isIndia: true);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /api/feed/seen/{post_id}
  Future<void> markSeen(String postId) async {
    try {
      debugPrint('[FeedRepo] POST /feed/seen/$postId');
      await _dio.post<void>('feed/seen/$postId');
    } on DioException catch (e) {
      debugPrint('[FeedRepo] markSeen error: $e');
    }
  }

  /// DELETE /api/feed/cache — invalidate my-feed cache
  Future<void> invalidateMyCache() async {
    try {
      debugPrint('[FeedRepo] DELETE /feed/cache');
      await _dio.delete<void>('feed/cache');
    } on DioException catch (e) {
      debugPrint('[FeedRepo] invalidateMyCache error: $e');
    }
  }

  /// DELETE /api/feed/india/cache
  Future<void> invalidateIndiaCache() async {
    try {
      debugPrint('[FeedRepo] DELETE /feed/india/cache');
      await _dio.delete<void>('feed/india/cache');
    } on DioException catch (e) {
      debugPrint('[FeedRepo] invalidateIndiaCache error: $e');
    }
  }

  Exception _mapError(DioException e) {
    debugPrint(
      '[FeedRepo] DioException type=${e.type} status=${e.response?.statusCode} msg=${e.message} error=${e.error}',
    );
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return Exception(
        'Cannot reach server (${e.requestOptions.uri.host}:${e.requestOptions.uri.port}). '
        'Check that the backend is running and the device is on the same network.',
      );
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return Exception(
        'Server is taking too long to respond — it may be building the feed cache. '
        'Pull down to retry in a moment.',
      );
    }
    final msg =
        (e.response?.data is Map
            ? (e.response!.data as Map)['detail']
            : null) ??
        e.message ??
        'Network error';
    return Exception(msg);
  }
}
