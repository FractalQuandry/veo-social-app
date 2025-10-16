import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth_service.dart';
import '../../core/usage_limits_service.dart';
import '../../data/dto/feed_item_dto.dart';
import '../feed/feed_controller.dart';

class ComposerPage extends ConsumerStatefulWidget {
  const ComposerPage({super.key});

  @override
  ConsumerState<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends ConsumerState<ComposerPage> {
  final _controller = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _submitting = false;
  String _mediaType = 'image'; // 'image' or 'video'
  String _aspectRatio = '9:16'; // '9:16' (portrait) or '16:9' (landscape)
  int _duration = 6; // Video duration: 4, 6, or 8 seconds
  bool _generateAudio = true; // Generate audio for video
  bool _isPrivate = false; // Privacy setting
  bool _includeMe = false; // Include user's profile image in generation
  List<XFile> _referenceImages = []; // Custom reference images (up to 3)

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickReferenceImage() async {
    if (_referenceImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 reference images allowed'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _referenceImages.add(image);
          // Force 16:9 aspect ratio when reference images are added
          if (_aspectRatio == '9:16') {
            _aspectRatio = '16:9';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeReferenceImage(int index) {
    setState(() {
      _referenceImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadReferenceImages() async {
    if (_referenceImages.isEmpty) return [];

    // Get UID from app's auth service (LocalAuthService or FirebaseAuthService)
    final authService = ref.read(authServiceProvider);
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final storage = FirebaseStorage.instance;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uploadedPaths = <String>[];

    for (var i = 0; i < _referenceImages.length; i++) {
      final file = File(_referenceImages[i].path);
      final fileName = 'reference_${timestamp}_$i.jpg';
      final storagePath = 'media/reference_images/$uid/$fileName';

      final ref = storage.ref().child(storagePath);
      await ref.putFile(file);

      uploadedPaths.add(storagePath);
    }

    return uploadedPaths;
  }

  Future<void> _submit() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Write a prompt first.')));
      return;
    }

    // Check usage limits
    final usageLimits = ref.read(usageLimitsServiceProvider);
    final isVideo = _mediaType == 'video';
    final canGenerate =
        isVideo ? usageLimits.canGenerateVideo : usageLimits.canGenerateImage;

    if (!canGenerate) {
      final remaining = usageLimits.getResetTimeString();
      final limit = isVideo
          ? UsageLimitsService.maxVideosPerDay
          : UsageLimitsService.maxImagesPerDay;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Daily limit reached ($limit ${isVideo ? 'videos' : 'images'} per day). Resets in $remaining.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    final typeLabel = _mediaType == 'video' ? 'Video' : 'Image';

    // Record usage
    final recorded = isVideo
        ? await usageLimits.recordVideoGeneration()
        : await usageLimits.recordImageGeneration();

    if (!recorded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to record usage. Please try again.')),
      );
      return;
    }

    // Upload reference images if any (before navigating away)
    List<String>? referenceImagePaths;
    if (_referenceImages.isNotEmpty) {
      try {
        referenceImagePaths = await _uploadReferenceImages();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload reference images: $e')),
        );
        return;
      }
    }

    // All new content goes to Your Feed (private feed type)
    // It will show both public and private content from this user
    final targetFeed = FeedType.private; // Your Feed

    // Add optimistic pending item to Your Feed BEFORE navigating back
    ref
        .read(feedControllerProvider(targetFeed).notifier)
        .addOptimisticPending(prompt, _mediaType, aspectRatio: _aspectRatio);

    // Navigate back to feed page
    Navigator.of(context).pop();

    // Show confirmation
    final visibilityText = _isPrivate ? '(private)' : '(public)';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Creating your $typeLabel $visibilityText...'),
      duration: const Duration(seconds: 3),
    ));

    // Enqueue in background - when it completes, feed will refresh
    ref
        .read(feedControllerProvider(targetFeed).notifier)
        .enqueuePrompt(prompt,
            mediaType: _mediaType,
            aspectRatio: _aspectRatio,
            duration: _duration,
            audio: _generateAudio,
            isPrivate: _isPrivate,
            includeMe: _includeMe,
            referenceImagePaths: referenceImagePaths)
        .catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create $typeLabel: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Create with AI'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Media Type Selector
              Row(
                children: [
                  Text('Type',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: _CompactButton(
                              icon: Icons.image,
                              label: 'Image',
                              isSelected: _mediaType == 'image',
                              onTap: () => setState(() => _mediaType = 'image'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _CompactButton(
                              icon: Icons.videocam,
                              label: 'Video',
                              isSelected: _mediaType == 'video',
                              onTap: () => setState(() => _mediaType = 'video'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Aspect Ratio Selector
              Row(
                children: [
                  Text('Aspect',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: _CompactButton(
                              icon: Icons.smartphone,
                              label: '9:16',
                              isSelected: _aspectRatio == '9:16',
                              onTap: () =>
                                  setState(() => _aspectRatio = '9:16'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _CompactButton(
                              icon: Icons.tablet,
                              label: '16:9',
                              isSelected: _aspectRatio == '16:9',
                              onTap: () =>
                                  setState(() => _aspectRatio = '16:9'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Video-specific options
              if (_mediaType == 'video') ...[
                const SizedBox(height: 12),

                // Duration Selector
                Row(
                  children: [
                    Text('Length',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            Expanded(
                              child: _CompactButton(
                                icon: Icons.timer,
                                label: '4s',
                                isSelected: _duration == 4,
                                onTap: () => setState(() => _duration = 4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _CompactButton(
                                icon: Icons.timer,
                                label: '6s',
                                isSelected: _duration == 6,
                                onTap: () => setState(() => _duration = 6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _CompactButton(
                                icon: Icons.timer,
                                label: '8s',
                                isSelected: _duration == 8,
                                onTap: () => setState(() => _duration = 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Audio Toggle
                Row(
                  children: [
                    Text('Audio',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            Expanded(
                              child: _CompactButton(
                                icon: Icons.volume_up,
                                label: 'On',
                                isSelected: _generateAudio,
                                onTap: () =>
                                    setState(() => _generateAudio = true),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _CompactButton(
                                icon: Icons.volume_off,
                                label: 'Off',
                                isSelected: !_generateAudio,
                                onTap: () =>
                                    setState(() => _generateAudio = false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Include Me Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _includeMe ? Icons.person : Icons.person_outline,
                      size: 20,
                      color: _includeMe ? Colors.blue : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Include Me',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _includeMe
                                ? 'Your profile image will be used'
                                : 'Generate without your image',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _includeMe,
                      onChanged: (value) {
                        setState(() {
                          _includeMe = value;
                          // Force 16:9 aspect ratio when Include Me is enabled
                          // veo-3.1-generate-preview with referenceImages only supports 16:9
                          if (value && _aspectRatio == '9:16') {
                            _aspectRatio = '16:9';
                          }
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),

              // Include Me limitation warning
              if (_includeMe || _referenceImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.shade700.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.amber.shade300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reference images only support landscape (16:9) videos',
                            style: TextStyle(
                              color: Colors.amber.shade100,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Reference Images Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reference Images',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Add up to 3 images for style/character',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_referenceImages.length < 3)
                          TextButton.icon(
                            onPressed: _pickReferenceImage,
                            icon:
                                const Icon(Icons.add_photo_alternate, size: 18),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                    if (_referenceImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          _referenceImages.length,
                          (index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_referenceImages[index].path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeReferenceImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Privacy Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isPrivate ? Icons.lock : Icons.public,
                      size: 20,
                      color: _isPrivate ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPrivate ? 'Private' : 'Public',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPrivate
                                ? 'Only you can see this'
                                : 'Everyone can see this',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPrivate,
                      onChanged: (value) => setState(() => _isPrivate = value),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Prompt Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: _mediaType == 'video'
                        ? 'Describe your video scene...\ne.g., "A drone shot flying over a misty forest at sunrise"'
                        : 'Describe your image...\ne.g., "A serene mountain lake at sunset with vibrant colors"',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  maxLines: 6,
                  minLines: 6,
                ),
              ),
              const SizedBox(height: 16),

              // Info Text with Usage Limits
              Consumer(
                builder: (context, ref, child) {
                  final usageLimits = ref.watch(usageLimitsServiceProvider);
                  final remaining = _mediaType == 'video'
                      ? usageLimits.videosRemaining
                      : usageLimits.imagesRemaining;
                  final total = _mediaType == 'video'
                      ? UsageLimitsService.maxVideosPerDay
                      : UsageLimitsService.maxImagesPerDay;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _mediaType == 'video'
                                ? Icons.videocam
                                : Icons.image,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _mediaType == 'video'
                                  ? '$_duration-second video • $_aspectRatio • ${_generateAudio ? 'with' : 'no'} audio • ~30-60s generation'
                                  : 'High-quality image • $_aspectRatio • ~15-30s generation',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.battery_charging_full,
                            size: 16,
                            color: remaining > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$remaining of $total ${_mediaType == 'video' ? 'videos' : 'images'} remaining today',
                              style: TextStyle(
                                color: remaining > 0
                                    ? Colors.green.shade400
                                    : Colors.red.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Generate Button
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 24),
                label: Text(
                  _submitting
                      ? 'Queueing...'
                      : 'Generate ${_mediaType == 'video' ? 'Video' : 'Image'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey.shade400,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
