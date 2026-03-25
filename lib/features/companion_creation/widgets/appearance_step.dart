import 'package:flutter/material.dart';

class AppearanceStep extends StatefulWidget {
  final String? initialAvatar;
  final Function(String avatar) onChanged;

  const AppearanceStep({
    super.key,
    this.initialAvatar,
    required this.onChanged,
  });

  @override
  State<AppearanceStep> createState() => _AppearanceStepState();
}

class _AppearanceStepState extends State<AppearanceStep> {
  String? selectedAvatar;

  final List<String> avatarOptions = [
    '👩', '👨', '🧑', '👩‍💼', '👨‍💼', '👩‍🎓', '👨‍🎓',
    '🧙‍♀️', '🧙‍♂️', '👑', '🤖', '🐱', '🐶', '🦊', '🐼', '🦄',
  ];

  @override
  void initState() {
    super.initState();
    selectedAvatar = widget.initialAvatar ?? avatarOptions.first;
  }

  void _selectAvatar(String avatar) {
    setState(() {
      selectedAvatar = avatar;
    });
    widget.onChanged(avatar);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Appearance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an avatar that represents your companion.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          if (selectedAvatar != null)
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    selectedAvatar!,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Choose Avatar:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = avatarOptions[index];
              final isSelected = avatar == selectedAvatar;
              
              return GestureDetector(
                onTap: () => _selectAvatar(avatar),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Colors.grey[100],
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      avatar,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}