/// Controller-less search input for the home page.
library;

import 'package:material_ui/material_ui.dart';

/// The field owns its text through [TextFormField.initialValue] and only
/// reports edits via [onChanged]; [ShopState.searchQuery] stays the source
/// of truth. When the query is cleared externally (close/clear buttons),
/// the field is remounted empty via a key change instead of a controller.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  // Mirror of what the field currently shows; diverging from [widget.query]
  // towards empty can only mean an external clear.
  late String _text = widget.query;
  int _generation = 0;

  @override
  void didUpdateWidget(covariant SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_text.isNotEmpty && widget.query.isEmpty) {
      _text = '';
      _generation++; // force TextFormField recreation with empty text
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(_generation),
      initialValue: _text,
      onChanged: (value) {
        _text = value;
        widget.onChanged(value);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search items\u2026',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: () => widget.onChanged(''),
              ),
      ),
    );
  }
}
