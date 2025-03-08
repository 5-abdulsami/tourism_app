import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tourism_app/utils/colors.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearch;

  const CustomSearchBar({
    super.key,
    required this.onSearch,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(query);
    });

    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _isSearching = false);
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: AppColors.whiteBar,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search places...',
          prefixIcon: const Icon(Icons.search, color: AppColors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey),
                  onPressed: _clearSearch,
                )
              : null,
        ),
        onChanged: _onSearchChanged,
        onSubmitted: (value) {
          widget.onSearch(value);
          FocusScope.of(context).unfocus(); // Close keyboard
        },
      ),
    );
  }
}
