import 'package:flutter/material.dart';

class SidebarButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const SidebarButton(this.label, {this.isActive = false, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      tileColor: isActive ? Colors.blue.shade100 : null,
      onTap: () {
        // handle tap
      },
    );
  }
}
