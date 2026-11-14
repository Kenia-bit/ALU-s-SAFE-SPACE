import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = [
    'Facilities Issue',
    'Power Outage',
    'Catering services',
    'Safety concern',
    'Sanitation',
    'IT, Internet & Tech infrastructure',
    'Academics',
  ];

  String? _selectedCategory;
  Uint8List? _selectedImageBytes;
  XFile? _selectedImage;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Unable to open the photo gallery.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load the selected photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before submitting a report.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final report = FirebaseFirestore.instance.collection('reports').doc();
      String? imageUrl;
      String? photoUploadError;
      if (_selectedImage != null && _selectedImageBytes != null) {
        final extension = _selectedImage!.name.split('.').last.toLowerCase();
        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'gif' => 'image/gif',
          'heic' => 'image/heic',
          'heif' => 'image/heif',
          _ => 'image/jpeg',
        };
        final storageExtension = switch (extension) {
          'png' => 'png',
          'webp' => 'webp',
          'gif' => 'gif',
          'heic' => 'heic',
          'heif' => 'heif',
          _ => 'jpg',
        };
        if (!SupabaseConfig.isConfigured) {
          photoUploadError = 'Supabase is not configured.';
        } else {
          final storagePath =
              'reports/${user.uid}/${report.id}/photo.$storageExtension';
          try {
            final storage = Supabase.instance.client.storage.from(
              SupabaseConfig.storageBucket,
            );
            await storage.uploadBinary(
              storagePath,
              _selectedImageBytes!,
              fileOptions: FileOptions(contentType: contentType),
            );
            imageUrl = storage.getPublicUrl(storagePath);
          } catch (error) {
            photoUploadError = error.toString();
          }
        }
      }

      await report.set({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'reporterUid': user.uid,
        'reporterEmail': user.email,
        'reporterName': user.displayName,
        'status': 'Waiting',
        'archivedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            photoUploadError == null
                ? 'Your report has been submitted.'
                : 'Your report was submitted, but the photo could not be uploaded: '
                      '$photoUploadError',
          ),
        ),
      );
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit the report: ${error.message ?? error.code}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit the report: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, bool isDarkMode) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDarkMode ? Colors.white30 : Colors.black38),
      filled: true,
      fillColor: isDarkMode ? Colors.grey[950] : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardBgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final inputBorderColor = isDarkMode ? Colors.white30 : Colors.black26;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text('File a Complaint'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Issue Title Summary', textColor),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  'e.g., Water leakage in Room 204',
                  isDarkMode,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 18),
              _buildSectionLabel('Select Category', textColor),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: cardBgColor,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: _buildInputDecoration(
                  'Choose relevant sector',
                  isDarkMode,
                ),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 18),
              _buildSectionLabel('Specific Campus Location', textColor),
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  'e.g., Innovation City, Block B, 2nd Floor',
                  isDarkMode,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Location detail is required'
                    : null,
              ),
              const SizedBox(height: 18),
              _buildSectionLabel('Detailed Explanation', textColor),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  'Describe the issue context clearly...',
                  isDarkMode,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Attach Photographic Evidence', textColor),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isPickingImage ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: inputBorderColor,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filled(
                                tooltip: 'Remove photo',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => setState(() {
                                  _selectedImage = null;
                                  _selectedImageBytes = null;
                                }),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPickingImage
                                  ? Icons.hourglass_top_rounded
                                  : Icons.add_a_photo_outlined,
                              size: 40,
                              color: isDarkMode
                                  ? Colors.white60
                                  : Colors.black45,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isPickingImage
                                  ? 'Opening photo gallery...'
                                  : 'Tap to choose a photo from your gallery',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}