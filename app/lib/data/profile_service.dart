import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/env.dart';

class ProfileImages {
  final CaptureImages? captureImages;
  final String? baseImage;
  final String? baseImagePublicUrl;
  final bool baseImageApproved;
  final DateTime? baseImageCreatedAt;

  ProfileImages({
    this.captureImages,
    this.baseImage,
    this.baseImagePublicUrl,
    this.baseImageApproved = false,
    this.baseImageCreatedAt,
  });

  factory ProfileImages.fromJson(Map<String, dynamic> json) {
    return ProfileImages(
      captureImages: json['captureImages'] != null
          ? CaptureImages.fromJson(json['captureImages'])
          : null,
      baseImage: json['baseImage'],
      baseImagePublicUrl: json['baseImagePublicUrl'],
      baseImageApproved: json['baseImageApproved'] ?? false,
      baseImageCreatedAt: json['baseImageCreatedAt'] != null
          ? DateTime.parse(json['baseImageCreatedAt'])
          : null,
    );
  }
}

class CaptureImages {
  final String front;
  final String left;
  final String right;

  CaptureImages({
    required this.front,
    required this.left,
    required this.right,
  });

  factory CaptureImages.fromJson(Map<String, dynamic> json) {
    return CaptureImages(
      front: json['front'],
      left: json['left'],
      right: json['right'],
    );
  }
}

class ProfileImagesResponse {
  final ProfileImages? profileImages;
  final bool success;
  final String? message;

  ProfileImagesResponse({
    this.profileImages,
    required this.success,
    this.message,
  });

  factory ProfileImagesResponse.fromJson(Map<String, dynamic> json) {
    return ProfileImagesResponse(
      profileImages: json['profileImages'] != null
          ? ProfileImages.fromJson(json['profileImages'])
          : null,
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}

class ProfileService {
  final String baseUrl;
  final Dio _dio;

  ProfileService({required this.baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  /// Upload 3 angle photos for profile image generation
  Future<ProfileImagesResponse> uploadCaptureImages({
    required String uid,
    required File frontImage,
    required File leftImage,
    required File rightImage,
  }) async {
    final uri = Uri.parse('$baseUrl/profile/capture-images');

    var request = http.MultipartRequest('POST', uri);
    request.fields['uid'] = uid;

    request.files
        .add(await http.MultipartFile.fromPath('front', frontImage.path));
    request.files
        .add(await http.MultipartFile.fromPath('left', leftImage.path));
    request.files
        .add(await http.MultipartFile.fromPath('right', rightImage.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ProfileImagesResponse.fromJson(json);
    } else {
      throw Exception('Failed to upload capture images: ${response.body}');
    }
  }

  /// Generate base image from 3 capture photos using Imagen 4
  Future<ProfileImagesResponse> generateBaseImage({
    required String uid,
  }) async {
    try {
      final response = await _dio.post(
        '/profile/generate-base',
        data: {'uid': uid},
      );
      return ProfileImagesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to generate base image: $e');
    }
  }

  /// User approves or rejects generated base image
  Future<ProfileImagesResponse> approveBaseImage({
    required String uid,
    required bool approved,
  }) async {
    try {
      final response = await _dio.post(
        '/profile/approve-base',
        data: {
          'uid': uid,
          'approved': approved,
        },
      );
      return ProfileImagesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to approve base image: $e');
    }
  }

  /// Get user's profile images
  Future<ProfileImagesResponse> getProfileImages({
    required String uid,
  }) async {
    try {
      final response = await _dio.get(
        '/profile/images',
        queryParameters: {'uid': uid},
      );
      return ProfileImagesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get profile images: $e');
    }
  }
}

// Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(baseUrl: Env.apiBaseUrl);
});
