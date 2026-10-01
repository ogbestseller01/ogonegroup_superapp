import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'custom_button.dart';

class PostForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  final bool isLoading;
  const PostForm({super.key, required this.onSubmit, this.initialData, this.isLoading = false});

  @override
  State<PostForm> createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _contentController.text = widget.initialData!['content'] ?? '';
      _imagePath = widget.initialData!['image'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imagePath = file.path);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'image': _imagePath,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: const OutlineInputBorder(),
              labelStyle: theme.textTheme.bodyMedium,
            ),
            validator: (v) => v != null && v.isNotEmpty ? null : 'Title required',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Content',
              border: const OutlineInputBorder(),
              labelStyle: theme.textTheme.bodyMedium,
            ),
            validator: (v) => v != null && v.isNotEmpty ? null : 'Content required',
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: theme.hintColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _imagePath == null ? Icons.add_photo_alternate : Icons.check_circle,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _imagePath == null ? 'Add Image (optional)' : 'Image selected',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: widget.initialData == null ? 'Create Post' : 'Update Post',
            onPressed: _submit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}