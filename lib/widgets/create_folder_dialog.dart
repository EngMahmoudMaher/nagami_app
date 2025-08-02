import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class CreateFolderDialog extends StatefulWidget {
  final bool isDarkMode;

  const CreateFolderDialog({super.key, required this.isDarkMode});

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Create New Folder',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Folder Name',
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDarkMode
                        ? Colors.white24
                        : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                filled: true,
                fillColor: widget.isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a folder name';
                }
                if (value.trim().length < 2) {
                  return 'Folder name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDarkMode
                        ? Colors.white24
                        : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                filled: true,
                fillColor: widget.isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[50],
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            debugPrint("Create button pressed");
            debugPrint("Form valid: ${_formKey.currentState!.validate()}");
            debugPrint("Name: ${_nameController.text.trim()}");
            debugPrint("Description: ${_descriptionController.text.trim()}");

            if (_formKey.currentState!.validate()) {
              final result = {
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
              };
              debugPrint("Returning result: $result");
              Navigator.of(context).pop(result);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
