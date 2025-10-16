import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth_service.dart';
import '../../data/profile_service.dart';

/// Profile image capture page with 3-angle photo workflow
class ProfileImageCapturePage extends ConsumerStatefulWidget {
  const ProfileImageCapturePage({super.key});

  @override
  ConsumerState<ProfileImageCapturePage> createState() =>
      _ProfileImageCapturePageState();
}

class _ProfileImageCapturePageState
    extends ConsumerState<ProfileImageCapturePage> {
  File? _frontImage;
  File? _leftImage;
  File? _rightImage;

  bool _isUploading = false;
  bool _isGenerating = false;
  String? _generatedBaseImageUrl;
  bool _showApproval = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _captureImage(String angle) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          switch (angle) {
            case 'front':
              _frontImage = File(photo.path);
              break;
            case 'left':
              _leftImage = File(photo.path);
              break;
            case 'right':
              _rightImage = File(photo.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndGenerate() async {
    if (_frontImage == null || _leftImage == null || _rightImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all 3 photos first')),
      );
      return;
    }

    final auth = ref.read(authServiceProvider);
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final profileService = ref.read(profileServiceProvider);

      // Step 1: Upload capture images
      await profileService.uploadCaptureImages(
        uid: uid,
        frontImage: _frontImage!,
        leftImage: _leftImage!,
        rightImage: _rightImage!,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _isGenerating = true;
      });

      // Step 2: Generate base image
      final generateResponse = await profileService.generateBaseImage(uid: uid);

      if (!mounted) return;

      if (generateResponse.success &&
          generateResponse.profileImages?.baseImagePublicUrl != null) {
        setState(() {
          _isGenerating = false;
          _generatedBaseImageUrl =
              generateResponse.profileImages!.baseImagePublicUrl;
          _showApproval = true;
        });
      } else {
        throw Exception('Failed to generate base image');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _approveBaseImage(bool approved) async {
    final auth = ref.read(authServiceProvider);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final profileService = ref.read(profileServiceProvider);
      final response = await profileService.approveBaseImage(
        uid: uid,
        approved: approved,
      );

      if (!mounted) return;

      if (approved && response.success) {
        // Success! Go back to profile page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile image saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else if (!approved) {
        // User rejected, allow retry
        setState(() {
          _showApproval = false;
          _generatedBaseImageUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can try capturing new photos'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile Image'),
        backgroundColor: colorScheme.surface,
      ),
      body:
          _showApproval ? _buildApprovalView(theme) : _buildCaptureView(theme),
    );
  }

  Widget _buildCaptureView(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final allCaptured =
        _frontImage != null && _leftImage != null && _rightImage != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Photo Guidelines',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideline('✓ Good, even lighting'),
                  _buildGuideline('✓ Neutral background'),
                  _buildGuideline('✓ Calm, neutral expression'),
                  _buildGuideline('✓ Face clearly visible'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Capture buttons
          _buildCaptureButton(
            label: '1. Front-Facing',
            icon: Icons.face,
            image: _frontImage,
            onTap: () => _captureImage('front'),
          ),
          const SizedBox(height: 16),
          _buildCaptureButton(
            label: '2. Left Profile',
            icon: Icons.arrow_back,
            image: _leftImage,
            onTap: () => _captureImage('left'),
          ),
          const SizedBox(height: 16),
          _buildCaptureButton(
            label: '3. Right Profile',
            icon: Icons.arrow_forward,
            image: _rightImage,
            onTap: () => _captureImage('right'),
          ),
          const SizedBox(height: 32),

          // Generate button
          if (allCaptured && !_isUploading && !_isGenerating)
            FilledButton.icon(
              onPressed: _uploadAndGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate My Digital Twin'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

          if (_isUploading || _isGenerating)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isUploading
                        ? 'Uploading photos...'
                        : 'Generating your digital twin...\nThis may take a minute.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalView(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review Your Digital Twin',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This image will be used as your profile picture and can be inserted into generated content.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Generated image
          if (_generatedBaseImageUrl != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _generatedBaseImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: colorScheme.errorContainer,
                      child: Center(
                        child: Text(
                          'Failed to load image',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Approve button
          FilledButton.icon(
            onPressed: () => _approveBaseImage(true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Approve & Save'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 12),

          // Reject button
          OutlinedButton.icon(
            onPressed: () => _approveBaseImage(false),
            icon: const Icon(Icons.cancel),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton({
    required String label,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final captured = image != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: captured
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: captured ? colorScheme.primary : colorScheme.outline,
            width: captured ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Image preview or icon
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: captured
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      captured ? 'Captured ✓' : 'Tap to capture',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: captured
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (captured)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.check_circle, color: colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideline(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
