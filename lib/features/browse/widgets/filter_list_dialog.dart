import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/widgets/tri_state_chip.dart';

class FilterListDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String idKey;
  final String nameKey;
  final List<String> initialIncludes;
  final List<String> initialExcludes;
  final Function(List<String>, List<String>) onApply;

  const FilterListDialog({
    super.key,
    required this.title,
    required this.items,
    required this.idKey,
    required this.nameKey,
    required this.initialIncludes,
    required this.initialExcludes,
    required this.onApply,
  });

  @override
  State<FilterListDialog> createState() => _FilterListDialogState();
}

class _FilterListDialogState extends State<FilterListDialog> {
  String _searchQuery = '';
  late List<String> _includes;
  late List<String> _excludes;

  @override
  void initState() {
    super.initState();
    _includes = List.from(widget.initialIncludes);
    _excludes = List.from(widget.initialExcludes);
  }

  TriState _getTriState(String value) {
    if (_includes.contains(value)) return TriState.include;
    if (_excludes.contains(value)) return TriState.exclude;
    return TriState.off;
  }

  void _updateTriState(String value, TriState state) {
    setState(() {
      _includes.remove(value);
      _excludes.remove(value);

      if (state == TriState.include) _includes.add(value);
      if (state == TriState.exclude) _excludes.add(value);

      widget.onApply(_includes, _excludes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((t) {
      final name = t[widget.nameKey]?.toString() ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppConstants.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.borderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: TextStyle(color: AppConstants.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.title.toLowerCase()}...',
                    hintStyle: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppConstants.textMutedColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppConstants.secondaryBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppConstants.accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filteredItems.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: AppConstants.borderColor.withValues(alpha: 0.05),
                  height: 1,
                ),
              ),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final id = item[widget.idKey]?.toString() ?? '';
                final name = item[widget.nameKey]?.toString() ?? '';
                final state = _getTriState(id);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _updateTriState(
                        id,
                        state == TriState.include
                            ? TriState.off
                            : TriState.include,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: state != TriState.off
                                    ? AppConstants.textColor
                                    : AppConstants.textMutedColor,
                                fontSize: 16,
                                fontWeight: state != TriState.off
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          _buildActionIcon(
                            icon: Icons.check_circle,
                            isActive: state == TriState.include,
                            activeColor: AppConstants.accentColor,
                            onTap: () {
                              _updateTriState(
                                id,
                                state == TriState.include
                                    ? TriState.off
                                    : TriState.include,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildActionIcon(
                            icon: Icons.cancel,
                            isActive: state == TriState.exclude,
                            activeColor: AppConstants.errorColor,
                            onTap: () {
                              _updateTriState(
                                id,
                                state == TriState.exclude
                                    ? TriState.off
                                    : TriState.exclude,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive
              ? activeColor
              : AppConstants.borderColor.withValues(alpha: 0.3),
          size: 26,
        ),
      ),
    );
  }
}
