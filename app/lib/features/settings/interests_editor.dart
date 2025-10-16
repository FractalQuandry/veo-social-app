import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InterestsEditor extends StatefulWidget {
  const InterestsEditor({super.key});

  @override
  State<InterestsEditor> createState() => _InterestsEditorState();
}

class _InterestsEditorState extends State<InterestsEditor> {
  final Set<String> _selectedInterests = {};
  bool _isLoading = true;

  final List<String> _interests = [
    '🎨 Art & Design',
    '🎵 Music',
    '🎮 Gaming',
    '🍳 Food & Cooking',
    '✈️ Travel',
    '💪 Fitness',
    '📚 Books',
    '🎬 Movies & TV',
    '🐾 Pets & Animals',
    '💻 Technology',
    '🌲 Nature & Outdoors',
    '🧘 Wellness & Mindfulness',
    '⚽ Sports',
    '😂 Comedy',
    '📷 Photography',
    '🏡 Home & DIY',
  ];

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('selected_interests') ?? [];
    debugPrint('Loading interests: ${saved.length} found - $saved');
    setState(() {
      _selectedInterests.addAll(saved);
      _isLoading = false;
    });
  }

  Future<void> _saveInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final interestsList = _selectedInterests.toList();
    await prefs.setStringList('selected_interests', interestsList);
    debugPrint('Saved interests: ${interestsList.length} - $interestsList');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${interestsList.length} interests saved!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Interests'),
        actions: [
          TextButton(
            onPressed: _selectedInterests.isEmpty ? null : _saveInterests,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Select topics you\'re interested in',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll personalize your feed based on your selections',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                      selectedColor: theme.colorScheme.primaryContainer,
                      checkmarkColor: theme.colorScheme.onPrimaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                if (_selectedInterests.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedInterests.length} interests selected',
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your feed will be customized based on these topics',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
