import 'package:flutter/material.dart';

enum AppTab { home, camera, history, none }

class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.activeTab,
    required this.onChanged,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF3F6B2A);
    const idleColor = Color(0xFF6B7565);
    const cameraColor = Color(0xFFE1A53B);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SizedBox(
      height: 74 + bottomInset,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 8 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      label: 'Home',
                      icon: Icons.home_rounded,
                      active: activeTab == AppTab.home,
                      activeColor: selectedColor,
                      idleColor: idleColor,
                      onTap: () => onChanged(AppTab.home),
                    ),
                  ),
                  const SizedBox(width: 72),
                  Expanded(
                    child: _NavItem(
                      label: 'Riwayat',
                      icon: Icons.history_rounded,
                      active: activeTab == AppTab.history,
                      activeColor: selectedColor,
                      idleColor: idleColor,
                      onTap: () => onChanged(AppTab.history),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(AppTab.camera),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: cameraColor,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40E1A53B),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.idleColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color idleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : idleColor;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
