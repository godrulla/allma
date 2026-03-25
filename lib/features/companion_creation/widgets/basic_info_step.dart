import 'package:flutter/material.dart';

class BasicInfoStep extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final Function(String name, String description) onChanged;

  const BasicInfoStep({
    super.key,
    this.initialName,
    this.initialDescription,
    required this.onChanged,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onChanged(
      _nameController.text,
      _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Give your companion a name and tell us about them.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Companion Name',
              hintText: 'Enter a name for your companion',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Describe your companion\'s role or personality',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _notifyChanges(),
          ),
        ],
      ),
    );
  }
}