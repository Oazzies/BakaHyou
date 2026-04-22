import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/features/browse/widgets/search_filter_bottom_sheet.dart';

class MBSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;

  const MBSearchBar({
    Key? key,
    required this.onChanged,
    this.onSubmitted,
    this.initialFilters,
    this.onFilterApplied,
  }) : super(key: key);

  @override
  State<MBSearchBar> createState() => _MBSearchBarState();
}

class _MBSearchBarState extends State<MBSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late SearchFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters ?? SearchFilters();
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: "Search for something",
        hintStyle: const TextStyle(color: Colors.white),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_controller.text.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: _clear,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _currentFilters.toMap().isNotEmpty
                      ? AppConstants.accentColor
                      : Colors.white,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: AppConstants.secondaryBackground,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) {
                      return SearchFilterBottomSheet(
                        initialFilters: _currentFilters,
                        onApply: (filters) {
                          setState(() {
                            _currentFilters = filters;
                          });
                          if (widget.onFilterApplied != null) {
                            widget.onFilterApplied!(filters);
                          }
                        },
                      );
                    },
                  );
                },
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: AppConstants.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
}
