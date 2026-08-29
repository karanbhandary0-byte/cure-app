import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class DoctorShellScreen extends StatelessWidget {
  final Widget child;

  const DoctorShellScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/doctor/appointments')) return 1;
    if (location.startsWith('/doctor/patients')) return 2;
    if (location.startsWith('/doctor/analytics')) return 3;
    return 0; // /doctor/dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/doctor/dashboard');
        break;
      case 1:
        context.go('/doctor/appointments');
        break;
      case 2:
        context.go('/doctor/patients');
        break;
      case 3:
        context.go('/doctor/analytics');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (idx) => _onItemTapped(idx, context),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.brand,
          unselectedItemColor: AppColors.muted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }
}
