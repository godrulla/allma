import 'package:flutter/material.dart';

class BackgroundStep extends StatefulWidget {
  final String? initialBackground;
  final Function(String background) onChanged;

  const BackgroundStep({
    super.key,
    this.initialBackground,
    required this.onChanged,
  });

  @override
  State<BackgroundStep> createState() => _BackgroundStepState();
}

class _BackgroundStepState extends State<BackgroundStep> {
  late TextEditingController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = TextEditingController(text: widget.initialBackground ?? '');
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onChanged(_backgroundController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Background Story',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Give your companion a background story to make conversations more engaging.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _backgroundController,
            decoration: const InputDecoration(
              labelText: 'Background Story',
              hintText: 'Tell us about your companion\'s background, interests, or role...',
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: A good background helps your companion understand their role and respond more naturally.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}