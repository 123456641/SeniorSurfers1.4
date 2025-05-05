import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final Widget? action; // 👈 optional widget like a settings button

  const HeaderWidget({
    super.key,
    this.title = 'Senior Surfer',
    this.showBackButton = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton, // 👈 shows back button if true
      title: Row(
        children: [
          Image.asset(
            'assets/images/seniorsurfersLogoNoName.png',
            height: 50,
            width: 50,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'RobotoSerif',
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: action != null ? [action!] : null, // 👈 show only if provided
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF528FC3), Color(0xFF27445D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
