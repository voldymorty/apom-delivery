import 'package:delivery/Screens/analytical_home_screen.dart';
import 'package:delivery/Screens/profile_screen.dart';
import 'package:delivery/Screens/task_screen.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 1; // TaskScreen is primary screen

  final List<Widget> _screens = const [
    AnalyticalHomeScreen(),
    TaskScreen(),
    ProfileScreen(),
  ];

  final List<IconData> _iconList = [
    Icons.auto_graph_rounded,
    Icons.assignment_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = [
    "Dashboard",
    "Tasks",
    "Profile",
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Exit App",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          content: const Text(
            "Are you sure you want to exit the app?",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deliveryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Exit",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Future<void> _handleBackPress() async {
    if (_selectedIndex != 1) {
      setState(() {
        _selectedIndex = 1;
      });
    } else {
      await _showExitDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF5FE),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),

        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          height: 72,
          itemCount: _iconList.length,
          activeIndex: _selectedIndex,
          gapLocation: GapLocation.none,
          notchSmoothness: NotchSmoothness.verySmoothEdge,
          backgroundColor: Colors.white,
          elevation: 10,
          leftCornerRadius: 28,
          rightCornerRadius: 28,
          shadow: BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
          tabBuilder: (index, isActive) {
            final color = isActive
                ? AppColors.deliveryColor
                : Colors.grey.shade500;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.all(isActive ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.deliveryColor.withOpacity(0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconList[index],
                    size: isActive ? 27 : 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            );
          },
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
