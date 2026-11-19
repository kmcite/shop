/// Metro outlined search input with a stable internal controller.
library;

import 'package:flutter/material.dart';

import '../design/metro.dart';

/// Controlled search field over package [MetroTextField].
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.query,
    required this.onChanged,
    this.hintText = 'search items\u2026',
  });

  final String query;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MetroTextField(
      controller: _controller,
      placeholder: widget.hintText,
      onChanged: widget.onChanged,
      prefix: const Icon(Icons.search, size: 18),
      textInputAction: TextInputAction.search,
    );
  }
}
