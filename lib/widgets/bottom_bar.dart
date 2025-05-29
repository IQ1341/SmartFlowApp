import 'package:flutter/material.dart';
import 'package:smartflow/screens/settings/settings_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/history/history_screen.dart';

class CustomBottomNav extends StatefulWidget {
  const CustomBottomNav({super.key});

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  int _currentIndex = 1; // Dashboard di tengah, index = 1

  final List<Widget> _screens = const [
  HistoryScreen(),     // index 0 (kiri)
  DashboardScreen(),   // index 1 (TENGAH - FAB)
    SettingsScreen()
];


  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onMiddleTap() {
  _onTap(1); // harus index 1 → Dashboard
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBody: true,
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _onMiddleTap,
        backgroundColor: _currentIndex == 1 ? const Color.fromARGB(255, 107, 139, 255) : const Color.fromARGB(255, 107, 139, 255),
        elevation: 8,
        shape: const CircleBorder(),
        child: Icon(
          _currentIndex == 1 ? Icons.dashboard : Icons.dashboard_outlined,
          size: 30,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 10,
        color: Colors.white,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  Icons.history_outlined, Icons.history, "History", 0),
              const SizedBox(width: 48), // Spacer untuk FAB
              _buildNavItem(
                  Icons.settings_outlined, Icons.settings, "Setting", 2),
            ],

          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color.fromARGB(255, 107, 139, 255) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color.fromARGB(255, 107, 139, 255) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
