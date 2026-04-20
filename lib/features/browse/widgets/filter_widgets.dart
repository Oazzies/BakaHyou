import 'package:flutter/material.dart';

class FilterOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const FilterOptionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? Theme.of(context).primaryColor,
      backgroundColor: unselectedColor ?? const Color(0xFF18181B),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
      ),
    );
  }
}

class MultiSelectFilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final ValueChanged<List<String>> onSelectionChanged;
  final String? description;

  const MultiSelectFilterSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterOptionChip(
              label: option,
              isSelected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedOptions);
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onSelectionChanged(newSelection);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _RangeFilterContent extends StatefulWidget {
  final double min;
  final double max;
  final double currentMin;
  final double currentMax;
  final ValueChanged<RangeValues> onRangeChanged;

  const _RangeFilterContent({
    required this.min,
    required this.max,
    required this.currentMin,
    required this.currentMax,
    required this.onRangeChanged,
  });

  @override
  State<_RangeFilterContent> createState() => _RangeFilterContentState();
}

class _RangeFilterContentState extends State<_RangeFilterContent> {
  late RangeValues _rangeValues;

  @override
  void initState() {
    super.initState();
    _rangeValues = RangeValues(widget.currentMin, widget.currentMax);
  }

  @override
  void didUpdateWidget(_RangeFilterContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMin != widget.currentMin || oldWidget.currentMax != widget.currentMax) {
      _rangeValues = RangeValues(widget.currentMin, widget.currentMax);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_rangeValues.start.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${_rangeValues.end.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        RangeSlider(
          values: _rangeValues,
          min: widget.min,
          max: widget.max,
          onChanged: (RangeValues values) {
            setState(() {
              _rangeValues = values;
            });
            widget.onRangeChanged(values);
          },
        ),
      ],
    );
  }
}

class RangeFilterSection extends StatelessWidget {
  final String title;
  final double min;
  final double max;
  final double currentMin;
  final double currentMax;
  final ValueChanged<RangeValues> onRangeChanged;
  final String? unit;

  const RangeFilterSection({
    super.key,
    required this.title,
    required this.min,
    required this.max,
    required this.currentMin,
    required this.currentMax,
    required this.onRangeChanged,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _RangeFilterContent(
          min: min,
          max: max,
          currentMin: currentMin,
          currentMax: currentMax,
          onRangeChanged: onRangeChanged,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class SingleSelectFilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String?> onSelectionChanged;
  final bool allowClear;

  const SingleSelectFilterSection({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onSelectionChanged,
    this.allowClear = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            if (allowClear && selectedOption != null)
              FilterOptionChip(
                label: 'Clear',
                isSelected: false,
                onSelected: (_) => onSelectionChanged(null),
              ),
            ...options.map((option) {
              final isSelected = selectedOption == option;
              return FilterOptionChip(
                label: option,
                isSelected: isSelected,
                onSelected: (selected) {
                  onSelectionChanged(selected ? option : null);
                },
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _DateInputField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const _DateInputField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<_DateInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        hintText: 'YYYY-MM-DD',
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class DateRangeFilterSection extends StatelessWidget {
  final String title;
  final String? startDate;
  final String? endDate;
  final ValueChanged<({String? start, String? end})> onDateRangeChanged;

  const DateRangeFilterSection({
    super.key,
    required this.title,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateInputField(
                initialValue: startDate,
                onChanged: (value) {
                  onDateRangeChanged((
                    start: value.isEmpty ? null : value,
                    end: endDate,
                  ));
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('to'),
            const SizedBox(width: 8),
            Expanded(
              child: _DateInputField(
                initialValue: endDate,
                onChanged: (value) {
                  onDateRangeChanged((
                    start: startDate,
                    end: value.isEmpty ? null : value,
                  ));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
