import 'package:flutter/material.dart';
import 'package:tourism_app/utils/colors.dart';
import 'package:tourism_app/view/profile_screen/widgets/action_button.dart';
import 'package:tourism_app/view/profile_screen/widgets/profile_gallery.dart';
import 'package:tourism_app/view/profile_screen/widgets/profile_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkBlueColor, // Dark purple/blue at top
              Color(0xFF0088CC), // Light blue at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileHeader(),
                const Center(
                  child: Text(
                    '"I can draw my life by myself"',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const ProfileGallery(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: () {},
        backgroundColor: darkBlueColor,
        shape: const CircleBorder(),
        child: Icon(
          Icons.add,
          color: lightSkyBlueColor,
          size: 35,
        ),
      ),
    );
  }
}
