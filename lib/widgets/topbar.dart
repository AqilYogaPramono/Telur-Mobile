import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({
    super.key,
    required this.title,
    this.productName = 'Telur',
    this.onProfileTap,
  });

  final String title;
  final String productName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2F4A2B),
      centerTitle: true,
      title: Text(
        productName,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE9F1E3),
                border: Border.all(color: const Color(0xFFB8C9A8)),
              ),
              child: const Icon(Icons.person_rounded, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
