import 'package:flutter/material.dart';

class FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Function(String?) onOptionSelected;

  const FilterSection({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option),
              selected: selectedOption == option,
              onSelected: (selected) {
                onOptionSelected(selected ? option : null);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
