import 'package:flutter/material.dart';
import '../core/constants.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home, 'label': 'الرئيسية'},
      {'icon': Icons.book, 'label': 'القرآن'},
      {'icon': Icons.emoji_people, 'label': 'الأذكار'},
      {'icon': Icons.mosque, 'label': 'الصلاة'},
      {'icon': Icons.explore, 'label': 'القبلة'},
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kGreen,
      unselectedItemColor: Colors.grey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      items: items.map((item) {
        final icon = item['icon'] as IconData;
        final label = item['label'] as String;

        return BottomNavigationBarItem(
          icon: Icon(icon),
          label: label,
        );
      }).toList(),
    );
  }
}
