// lib/screens/create_post_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marquee/marquee.dart';
import '../viewmodel/post_viewmodel.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String? communityId;
  final String? communityName;

  const CreatePostScreen({super.key, this.communityId, this.communityName});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  // bool _isAnonymous = true;
  bool _addLocation = false;
  bool _submitting = false;
  PickedLocation? _pickedLocation;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _attachments = [];

  // Upload progress: fileIndex → 0.0..1.0  (only populated while submitting)
  final Map<int, double> _uploadProgress = {};

  /// The index of the file currently being uploaded (-1 if none).
  int get _uploadingFileIndex =>
      _uploadProgress.isEmpty ? -1 : _uploadProgress.keys.last;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _imagePicker.pickMultiImage(imageQuality: 80);
      if (!mounted || images.isEmpty) return;

      setState(() {
        _attachments.addAll(images);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick images: $e'),
          backgroundColor: AppTheme.events,
        ),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (!mounted || image == null) return;

      setState(() {
        _attachments.add(image);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open camera: $e'),
          backgroundColor: AppTheme.events,
        ),
      );
    }
  }

  void _removeAttachmentAt(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _showAttachPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.communityId == null || widget.communityId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No community selected for this post.')),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _uploadProgress.clear();
    });
    try {
      await ref
          .read(postListProvider(widget.communityId!).notifier)
          .createPost(
            content: _contentCtrl.text.trim(),
            attachments: _attachments,
            onFileProgress: (fileIndex, sent, total) {
              if (!mounted) return;
              setState(() {
                _uploadProgress[fileIndex] = total > 0 ? sent / total : 0.0;
              });
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Post created successfully!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _uploadProgress.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.events,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityName = widget.communityName;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Ask a Question'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community badge
              if (communityName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: SizedBox(
                          height: 20,
                          child: Marquee(
                            text: 'Posting to: $communityName',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            scrollAxis: Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            blankSpace:
                                20.0, // Space between the end of text and start of next cycle
                            velocity: 30.0, // Pixels per second
                            pauseAfterRound: const Duration(seconds: 1),
                            accelerationDuration: const Duration(seconds: 1),
                            accelerationCurve: Curves.linear,
                            decelerationDuration: const Duration(
                              milliseconds: 500,
                            ),
                            decelerationCurve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Content
              const Text(
                'Description *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  hintText: 'What do you want to share or ask?',
                ),
                maxLines: 6,
                maxLength: 2000,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Attach photos
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showAttachPhotoOptions,
                icon: const Icon(
                  Icons.add_a_photo_outlined,
                  size: 18,
                  color: AppTheme.primary,
                ),
                label: const Text(
                  'Attach Photos',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${_attachments.length} photo(s) attached',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_submitting && _uploadingFileIndex >= 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Uploading ${_uploadingFileIndex + 1}/${_attachments.length}…',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final img = _attachments[i];
                      final progress = _uploadProgress[i];
                      final isUploading =
                          _submitting && _uploadingFileIndex == i;
                      final isDone =
                          _submitting && (_uploadProgress[i] ?? 0) >= 1.0;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FutureBuilder<Uint8List>(
                              future: img.readAsBytes(),
                              builder: (_, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return Container(
                                  width: 92,
                                  height: 92,
                                  color: AppTheme.surface,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Upload progress overlay
                          if (isUploading || (isDone))
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  color: Colors.black.withOpacity(0.45),
                                  alignment: Alignment.center,
                                  child: isDone
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        )
                                      : SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 3,
                                            color: Colors.white,
                                            backgroundColor: Colors.white
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          // Remove button — hidden while submitting
                          if (!_submitting)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeAttachmentAt(i),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Location section
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pickedLocation != null
                        ? AppTheme.primary.withOpacity(0.4)
                        : AppTheme.divider,
                    width: _pickedLocation != null ? 1.5 : 1,
                  ),
                  boxShadow: _pickedLocation != null
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.07),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    // Toggle
                    SwitchListTile(
                      value: _addLocation,
                      onChanged: (v) => setState(() {
                        _addLocation = v;
                        if (!v) {
                          _pickedLocation = null;
                          _locationCtrl.clear();
                        }
                      }),
                      title: const Text(
                        'Add Campus Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Tag a specific spot on campus',
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primary,
                      ),
                      activeColor: AppTheme.primary,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                    if (_addLocation) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text field — always visible
                            TextFormField(
                              controller: _locationCtrl,
                              onChanged: (_) {
                                // Rebuild so button text/style updates live
                                setState(() {
                                  if (_pickedLocation != null) {
                                    _pickedLocation = null;
                                  }
                                });
                              },
                              decoration: const InputDecoration(
                                hintText:
                                    'e.g. Block C Hostel, Main Canteen...',
                                prefixIcon: Icon(
                                  Icons.place_rounded,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Map button — text changes based on field content
                            GestureDetector(
                              onTap: _locationCtrl.text.trim().isEmpty
                                  ? null
                                  : () async {
                                      final result =
                                          await Navigator.push<PickedLocation>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  LocationPickerScreen(
                                                    collegeId:
                                                        widget.communityId ??
                                                        '',
                                                    collegeName:
                                                        widget.communityName ??
                                                        '',
                                                    initialLabel: _locationCtrl
                                                        .text
                                                        .trim(),
                                                    initial: _pickedLocation,
                                                  ),
                                            ),
                                          );
                                      if (result != null && mounted) {
                                        setState(() {
                                          _pickedLocation = result;
                                          _locationCtrl.text = result.label;
                                        });
                                      } else if (result == null && mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_off_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Could not find "${_locationCtrl.text.trim()}" on the map',
                                                ),
                                              ],
                                            ),
                                            backgroundColor: AppTheme.events,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _locationCtrl.text.trim().isEmpty
                                      ? AppTheme.surface
                                      : AppTheme.primary.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _locationCtrl.text.trim().isEmpty
                                        ? AppTheme.divider
                                        : AppTheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _locationCtrl.text.trim().isEmpty
                                          ? Icons.search_rounded
                                          : Icons.map_rounded,
                                      size: 15,
                                      color: _locationCtrl.text.trim().isEmpty
                                          ? AppTheme.textLight
                                          : AppTheme.primary,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      _locationCtrl.text.trim().isEmpty
                                          ? 'Enter a location to find on map'
                                          : 'Pick on Map',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _locationCtrl.text.trim().isEmpty
                                            ? AppTheme.textLight
                                            : AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Pin confirmed preview — shown only after picking
                            if (_pickedLocation != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.success.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: AppTheme.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Location pinned on map',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.success,
                                            ),
                                          ),
                                          Text(
                                            '${_pickedLocation!.latLng.latitude.toStringAsFixed(5)}, '
                                            '${_pickedLocation!.latLng.longitude.toStringAsFixed(5)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _pickedLocation = null,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Anonymous toggle
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(color: AppTheme.divider),
              //   ),
              //   child: SwitchListTile(
              //     value: _isAnonymous,
              //     onChanged: (v) => setState(() => _isAnonymous = v),
              //     title: const Text(
              //       'Post Anonymously',
              //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              //     ),
              //     subtitle: const Text(
              //       'Your identity will be hidden',
              //       style: TextStyle(fontSize: 12),
              //     ),
              //     secondary: const Icon(
              //       Icons.shield_outlined,
              //       color: AppTheme.success,
              //     ),
              //     activeColor: AppTheme.success,
              //     contentPadding: const EdgeInsets.symmetric(
              //       horizontal: 16,
              //       vertical: 4,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
