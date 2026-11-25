import 'package:flutter/material.dart';

class CustomerBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool hasWeatherStation;
  const CustomerBottomNav({super.key, required this.index,
    required this.onTap, required this.hasWeatherStation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index,
      onTap: onTap,
      backgroundColor: colorScheme.primary,
      selectedItemColor: colorScheme.onPrimaryContainer,
      unselectedItemColor: colorScheme.onPrimary,
      selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: colorScheme.onPrimary),
      selectedLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(color: colorScheme.onPrimary),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Scheduled Program'),
        const BottomNavigationBarItem(icon: Icon(Icons.report_gmailerrorred), label: 'Log'),
        if(hasWeatherStation)...const [
          BottomNavigationBarItem(icon: Icon(Icons.cloud_outlined), label: 'Weather'),
        ],
        const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    );
  }
}