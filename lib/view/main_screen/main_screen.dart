import 'package:flutter/material.dart';
import 'package:tourism_app/view/home_screen/home_screen.dart';
import 'package:tourism_app/view/new_blog_screen/new_blog_screen.dart';
import 'package:tourism_app/view/profile_screen/profile_screen.dart';
import 'package:tourism_app/view/saved_screen/saved_screen.dart';
import 'package:tourism_app/widgets/custom_bottom_navbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Placeholder(), // For You screen (to be implemented)
    const NewBlogScreen(),
    const ProfileScreen(),
    const SavedScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // void _showNewPostDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('New Post'),
  //         content: const Text('Create a new blog post here.'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Close'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
