import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class PatientShellScreen extends StatelessWidget {
  final Widget child;

  const PatientShellScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/patient/book')) return 1;
    if (location.startsWith('/patient/records')) return 2;
    if (location.startsWith('/patient/feedback')) return 3;
    return 0; // /patient/home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/patient/home');
        break;
      case 1:
        context.go('/patient/book');
        break;
      case 2:
        context.go('/patient/records');
        break;
      case 3:
        context.go('/patient/feedback');
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
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Book',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              label: 'Records',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              label: 'Feedback',
            ),
          ],
        ),
      ),
    );
  }
}
