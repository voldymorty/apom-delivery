import 'package:delivery/Screens/analytical_home_screen.dart';
import 'package:delivery/Screens/profile_screen.dart';
import 'package:delivery/Screens/task_screen.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 1;

  final List<Widget> _screens = const [
    AnalyticalHomeScreen(),
    TaskScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10 ,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.translationValues(
                  0, isSelected ? -6 : 0, 0), // 👈 hover effect
              child: Icon(
                size: 30,
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? AppColors.deliveryColor
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppColors.deliveryColor
                    : Colors.grey,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // ✅ Custom Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.auto_graph_outlined,
              Icons.auto_graph_rounded,
              "Dashboard",
              0,
            ),
            _buildNavItem(
              Icons.assignment_outlined,
              Icons.assignment,
              "Tasks",
              1,
            ),
            _buildNavItem(
              Icons.person_outline,
              Icons.person,
              "Profile",
              2,
            ),
          ],
        ),
      ),
    );
  }
}