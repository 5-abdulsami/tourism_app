import 'package:flutter/material.dart';
import 'package:tourism_app/utils/colors.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearch;

  const CustomSearchBar({
    Key? key,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search places...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _controller.clear();
              widget.onSearch('');
            },
          ),
        ),
        onSubmitted: (value) {
          widget.onSearch(value);
        },
      ),
    );
  }
}
