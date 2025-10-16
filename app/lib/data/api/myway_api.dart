import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/env.dart';
import '../../core/logger.dart';
import '../dto/feed_item_dto.dart';

class MyWayApi {
  MyWayApi({Dio? client, List<String>? baseUrls})
      : _baseUrls = baseUrls ?? Env.apiBaseCandidates,
        _dio = client ?? Dio() {
    if (_baseUrls.isEmpty) {
      throw StateError('No API base URLs configured.');
    }
    _applyBaseOptions();
  }

  final Dio _dio;
  final List<String> _baseUrls;
  int _currentBaseIndex = 0;
  String? _lastLoggedBaseUrl;

  Future<FeedResponseDto> fetchFeed({
    required String uid,
    int page = 0,
    FeedType feedType = FeedType.hot,
  }) {
    return _requestWithFallback((dio) async {
      final response = await dio.post('/feed', data: {
        'uid': uid,
        'page': page,
        'feedType': feedType.name,
      });
      return FeedResponseDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Map<String, dynamic>> jobStatus(String jobId) {
    return _requestWithFallback((dio) async {
      final res =
          await dio.get('/gen/status', queryParameters: {'jobId': jobId});
      return res.data as Map<String, dynamic>;
    });
  }

  Future<String> enqueueImage(
      {required String uid,
      required String prompt,
      required String aspectRatio,
      bool isPrivate = false,
      bool includeMe = false,
      List<String>? referenceImagePaths}) {
    return _requestWithFallback((dio) async {
      final data = {
        'uid': uid,
        'prompt': prompt,
        'type': 'image',
        'aspect': aspectRatio,
        'isPrivate': isPrivate,
        'includeMe': includeMe,
      };
      if (referenceImagePaths != null) {
        data['referenceImagePaths'] = referenceImagePaths;
      }
      final res = await dio.post('/gen/image', data: data);
      return (res.data as Map<String, dynamic>)['jobId'] as String;
    });
  }

  Future<String> enqueueVideo(
      {required String uid,
      required String prompt,
      required String aspectRatio,
      required int duration,
      required bool audio,
      bool isPrivate = false,
      bool includeMe = false,
      List<String>? referenceImagePaths}) {
    return _requestWithFallback((dio) async {
      final data = {
        'uid': uid,
        'prompt': prompt,
        'type': 'video',
        'aspect': aspectRatio,
        'duration': duration,
        'audio': audio,
        'isPrivate': isPrivate,
        'includeMe': includeMe,
      };
      if (referenceImagePaths != null) {
        data['referenceImagePaths'] = referenceImagePaths;
      }
      final res = await dio.post('/gen/video', data: data);
      return (res.data as Map<String, dynamic>)['jobId'] as String;
    });
  }

  Future<List<String>> moreLikeThis(
      {required String uid, required String postId, int count = 2}) {
    return _requestWithFallback((dio) async {
      final res = await dio.post('/more-like-this', data: {
        'uid': uid,
        'postId': postId,
        'count': count,
      });
      final data = res.data as Map<String, dynamic>;
      return List<String>.from(data['jobs'] as List);
    });
  }

  Future<T> _requestWithFallback<T>(Future<T> Function(Dio dio) action) async {
    DioException? lastError;
    for (var attempt = 0; attempt < _baseUrls.length; attempt++) {
      _applyBaseOptions();
      try {
        return await action(_dio);
      } on DioException catch (err) {
        if (!_isRetryable(err) || attempt == _baseUrls.length - 1) {
          rethrow;
        }
        lastError = err;
        _advanceBaseUrl(err);
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    throw StateError('Failed to execute request with available API hosts.');
  }

  void _applyBaseOptions() {
    final base = _baseUrls[_currentBaseIndex];
    _dio.options = _dio.options.copyWith(
      baseUrl: base,
      connectTimeout: Env.apiConnectTimeout,
      receiveTimeout: Env.apiReceiveTimeout,
      sendTimeout: Env.apiConnectTimeout,
    );
    if (base != _lastLoggedBaseUrl) {
      AppLogger.info('API host set to $base');
      _lastLoggedBaseUrl = base;
    }
  }

  void _advanceBaseUrl(DioException err) {
    final previous = _baseUrls[_currentBaseIndex];
    _currentBaseIndex = (_currentBaseIndex + 1) % _baseUrls.length;
    final next = _baseUrls[_currentBaseIndex];
    AppLogger.warn('API host $previous failed (${err.message}). Trying $next');
  }

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    final root = err.error;
    return root is SocketException;
  }
}
