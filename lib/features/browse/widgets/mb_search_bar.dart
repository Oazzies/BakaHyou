import 'package:flutter/material.dart';

class MBSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  const MBSearchBar({
    Key? key,
    required this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<MBSearchBar> createState() => _MBSearchBarState();
}

class _MBSearchBarState extends State<MBSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
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
        suffixIcon: _controller.text.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: _clear,
                  constraints: const BoxConstraints(),
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF18181B),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
}