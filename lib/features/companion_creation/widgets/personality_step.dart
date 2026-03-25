import 'package:flutter/material.dart';

class PersonalityStep extends StatefulWidget {
  final Map<String, double>? initialTraits;
  final Function(Map<String, double> traits) onChanged;

  const PersonalityStep({
    super.key,
    this.initialTraits,
    required this.onChanged,
  });

  @override
  State<PersonalityStep> createState() => _PersonalityStepState();
}

class _PersonalityStepState extends State<PersonalityStep> {
  late Map<String, double> traits;

  final Map<String, String> traitDescriptions = {
    'openness': 'How open to new experiences and ideas',
    'conscientiousness': 'How organized and dependable',
    'extraversion': 'How outgoing and energetic',
    'agreeableness': 'How cooperative and trusting',
    'neuroticism': 'How sensitive and nervous',
  };

  @override
  void initState() {
    super.initState();
    traits = widget.initialTraits ?? {
      'openness': 0.5,
      'conscientiousness': 0.5,
      'extraversion': 0.5,
      'agreeableness': 0.5,
      'neuroticism': 0.3,
    };
  }

  void _updateTrait(String trait, double value) {
    setState(() {
      traits[trait] = value;
    });
    widget.onChanged(traits);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality Traits',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust these traits to shape your companion\'s personality.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ...traits.entries.map((entry) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.toUpperCase(),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            traitDescriptions[entry.key] ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(entry.value * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: entry.value,
                  onChanged: (value) => _updateTrait(entry.key, value),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}