// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  PostCategory _category = PostCategory.general;
  bool _isAnonymous = true;
  bool _addLocation = false;
  bool _submitting = false;
  PickedLocation? _pickedLocation;
  final _ds = DataService();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _ds.createPost(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        category: _category,
        locationLabel: _addLocation
            ? (_pickedLocation?.label ??
                  (_locationCtrl.text.trim().isNotEmpty
                      ? _locationCtrl.text.trim()
                      : null))
            : null,
        isAnonymous: _isAnonymous,
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
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.events),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final college = _ds.selectedCollege;
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
              // College badge
              if (college != null)
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
                        Icons.school_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Posting to: ${college.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Category
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PostCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  final color = AppTheme.categoryColor(cat.label);
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? color : AppTheme.divider,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppTheme.categoryIcon(cat.label),
                            size: 13,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Title *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Summarise your question in one line...',
                ),
                maxLength: 120,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Body
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
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  hintText:
                      'Provide more context about your question or issue...',
                ),
                maxLines: 5,
                maxLength: 1000,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
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
                                                        college?.id ?? '',
                                                    collegeName:
                                                        college?.name ?? '',
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: SwitchListTile(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                  title: const Text(
                    'Post Anonymously',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Your identity will be hidden',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: const Icon(
                    Icons.shield_outlined,
                    color: AppTheme.success,
                  ),
                  activeColor: AppTheme.success,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
