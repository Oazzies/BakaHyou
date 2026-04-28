import 'package:flutter/material.dart';

class ExpandableChipWrap extends StatefulWidget {
  final String label;
  final List<String> items;
  final Color? color;

  const ExpandableChipWrap({
    required this.label,
    required this.items,
    this.color,
    super.key,
  });

  @override
  State<ExpandableChipWrap> createState() => _ExpandableChipWrapState();
}

class _ExpandableChipWrapState extends State<ExpandableChipWrap> {
  bool _expanded = false;
  bool _needsExpansion = false;
  double _maxCollapsedHeight = 200.0;
  
  final GlobalKey _fullWrapKey = GlobalKey();
  final GlobalKey _singleChipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateMetrics());
  }

  void _calculateMetrics() {
    if (!mounted) return;
    
    final RenderBox? fullBox = _fullWrapKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? singleBox = _singleChipKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (fullBox != null && singleBox != null) {
      final double singleHeight = singleBox.size.height;
      final double fullHeight = fullBox.size.height;
      
      // We want to show at most 5 rows.
      // Run spacing is 8.
      const double runSpacing = 8.0;
      final double fiveRowsHeight = (singleHeight * 5) + (runSpacing * 4) + 4; // +4 for a small buffer
      
      final bool shouldOverflow = fullHeight > fiveRowsHeight;
      
      if (shouldOverflow != _needsExpansion || fiveRowsHeight != _maxCollapsedHeight) {
        setState(() {
          _needsExpansion = shouldOverflow;
          _maxCollapsedHeight = fiveRowsHeight;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final chips = widget.items
        .map((e) => Chip(
              label: Text(e),
              backgroundColor: widget.color,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Trigger re-calculation whenever layout changes (e.g. orientation)
        WidgetsBinding.instance.addPostFrameCallback((_) => _calculateMetrics());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Stack(
              children: [
                // Measurement items (Invisible)
                Offstage(
                  offstage: true,
                  child: Column(
                    children: [
                      // Single chip to measure row height
                      if (chips.isNotEmpty)
                        Container(key: _singleChipKey, child: chips.first),
                      // Full wrap to measure total height
                      Wrap(
                        key: _fullWrapKey,
                        spacing: 8,
                        runSpacing: 8,
                        children: chips,
                      ),
                    ],
                  ),
                ),
                
                // Visible version
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: _expanded || !_needsExpansion
                        ? const BoxConstraints()
                        : BoxConstraints(maxHeight: _maxCollapsedHeight),
                    child: ClipRect(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chips,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_needsExpansion)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _expanded ? 'Show less' : 'Show all',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
