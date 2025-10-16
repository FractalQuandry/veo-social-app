import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

typedef ReasonList = List<String>;

class FeedResponseDto {
  const FeedResponseDto({
    required this.items,
    required this.hasMore,
    required this.nextPage,
  });

  factory FeedResponseDto.fromJson(Map<String, dynamic> json) {
    return FeedResponseDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => FeedItemDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
      nextPage: json['nextPage'] as int? ?? 0,
    );
  }

  final List<FeedItemDto> items;
  final bool hasMore;
  final int nextPage;
}

enum FeedSlot { ready, pending, fallback }

enum PostType { image, video }

enum FeedType {
  hot,
  interests,
  private,
  random;

  String get displayName {
    switch (this) {
      case FeedType.hot:
        return 'Hot';
      case FeedType.interests:
        return 'Interests';
      case FeedType.private:
        return 'Your Feed';
      case FeedType.random:
        return 'Random';
    }
  }

  IconData get icon {
    switch (this) {
      case FeedType.hot:
        return Icons.local_fire_department;
      case FeedType.interests:
        return Icons.explore;
      case FeedType.private:
        return Icons.person;
      case FeedType.random:
        return Icons.shuffle;
    }
  }
}

class SafetyInfoDto {
  const SafetyInfoDto({
    required this.blocked,
    this.scores = const {},
  });

  factory SafetyInfoDto.fromJson(Map<String, dynamic> json) {
    return SafetyInfoDto(
      blocked: json['blocked'] as bool? ?? false,
      scores: (json['scores'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
    );
  }

  final bool blocked;
  final Map<String, double> scores;

  Map<String, dynamic> toJson() => {
        'blocked': blocked,
        'scores': scores,
      };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SafetyInfoDto &&
            other.blocked == blocked &&
            const MapEquality<String, double>().equals(other.scores, scores);
  }

  @override
  int get hashCode =>
      blocked.hashCode ^ const MapEquality<String, double>().hash(scores);
}

class PostDto {
  const PostDto({
    required this.id,
    required this.type,
    required this.status,
    required this.storagePath,
    this.publicUrl,
    this.duration,
    this.aspect = '9:16',
    required this.model,
    required this.prompt,
    this.title,
    this.seed,
    required this.safety,
    this.synthId = true,
    required this.authorUid,
    this.isPrivate = false,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    return PostDto(
      id: json['id'] as String,
      type: (json['type'] as String).toLowerCase() == 'video'
          ? PostType.video
          : PostType.image,
      status: json['status'] as String? ?? 'ready',
      storagePath: json['storagePath'] as String? ?? '',
      publicUrl: json['publicUrl'] as String?,
      duration: (json['duration'] as num?)?.toDouble(),
      aspect: json['aspect'] as String? ?? '9:16',
      model: json['model'] as String? ?? 'model',
      prompt: json['prompt'] as String? ?? '',
      title: json['title'] as String?,
      seed: json['seed'] as int?,
      safety:
          SafetyInfoDto.fromJson(json['safety'] as Map<String, dynamic>? ?? {}),
      synthId: json['synthId'] as bool? ?? true,
      authorUid: json['authorUid'] as String? ?? 'system',
      isPrivate: json['isPrivate'] as bool? ?? false,
    );
  }

  final String id;
  final PostType type;
  final String status;
  final String storagePath;
  final String? publicUrl;
  final double? duration;
  final String aspect;
  final String model;
  final String prompt;
  final String? title;
  final int? seed;
  final SafetyInfoDto safety;
  final bool synthId;
  final String authorUid;
  final bool isPrivate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'status': status,
        'storagePath': storagePath,
        'publicUrl': publicUrl,
        'duration': duration,
        'aspect': aspect,
        'model': model,
        'prompt': prompt,
        'title': title,
        'seed': seed,
        'safety': safety.toJson(),
        'synthId': synthId,
        'authorUid': authorUid,
        'isPrivate': isPrivate,
      };
}

class FeedItemDto {
  const FeedItemDto({
    required this.slot,
    this.post,
    this.jobId,
    this.reason = const <String>[],
  });

  factory FeedItemDto.fromJson(Map<String, dynamic> json) {
    final slotRaw = (json['slot'] as String?)?.toLowerCase() ?? 'fallback';
    return FeedItemDto(
      slot: FeedSlot.values.firstWhere(
        (value) => value.name.toLowerCase() == slotRaw,
        orElse: () => FeedSlot.fallback,
      ),
      post: json['post'] == null
          ? null
          : PostDto.fromJson(json['post'] as Map<String, dynamic>),
      jobId: json['jobId'] as String?,
      reason: (json['reason'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
    );
  }

  final FeedSlot slot;
  final PostDto? post;
  final String? jobId;
  final List<String> reason;

  Map<String, dynamic> toJson() => {
        'slot': slot.name.toUpperCase(),
        'post': post?.toJson(),
        'jobId': jobId,
        'reason': reason,
      };

  FeedItemDto copyWith({
    FeedSlot? slot,
    PostDto? post,
    String? jobId,
    List<String>? reason,
  }) {
    return FeedItemDto(
      slot: slot ?? this.slot,
      post: post ?? this.post,
      jobId: jobId ?? this.jobId,
      reason: reason ?? this.reason,
    );
  }
}
