import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/role_selector_screen.dart';
import '../screens/auth/doctor_login_screen.dart';
import '../screens/auth/patient_login_screen.dart';
import '../screens/auth/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/doctor/doctor_shell_screen.dart';
import '../screens/doctor/doctor_dashboard_screen.dart';
import '../screens/doctor/doctor_appointments_screen.dart';
import '../screens/doctor/doctor_patients_screen.dart';
import '../screens/doctor/doctor_analytics_screen.dart';
import '../screens/doctor/doctor_patient_detail_screen.dart';
import '../screens/doctor/doctor_feedback_screen.dart';
import '../screens/patient/patient_shell_screen.dart';
import '../screens/patient/patient_home_screen.dart';
import '../screens/patient/patient_book_screen.dart';
import '../screens/patient/patient_records_screen.dart';
import '../screens/patient/patient_feedback_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _doctorShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'doctorShell');
final GlobalKey<NavigatorState> _patientShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'patientShell');

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final status = authState.status;
    final location = state.matchedLocation;

    if (location == '/admin' || location == '/auth/admin-login') {
      if (status == AuthStatus.authenticatedAdmin) {
        return '/admin/dashboard';
      }
      return null;
    }

    if (location == '/admin/dashboard') {
      if (status != AuthStatus.authenticatedAdmin) {
        return '/admin';
      }
      return null;
    }

    if (status == AuthStatus.authenticatedAdmin) {
      if (location == '/' || location.startsWith('/patient') || location.startsWith('/doctor')) {
        return '/admin/dashboard';
      }
    } else if (status == AuthStatus.authenticatedDoctor) {
      if (location == '/' || location.startsWith('/patient')) return '/doctor/dashboard';
    } else if (status == AuthStatus.authenticatedPatient) {
      if (location == '/' || location.startsWith('/doctor')) return '/patient/home';
    } else if (status == AuthStatus.unauthenticated) {
      if (location.startsWith('/doctor') || location.startsWith('/patient')) {
        return '/';
      }
    }
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleSelectorScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/auth/admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/auth/doctor-login',
        builder: (context, state) => const DoctorLoginScreen(),
      ),
      GoRoute(
        path: '/auth/patient-login',
        builder: (context, state) => const PatientLoginScreen(),
      ),

      // Doctor Navigation Shell
      ShellRoute(
        navigatorKey: _doctorShellNavigatorKey,
        builder: (context, state, child) => DoctorShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/doctor/dashboard',
            builder: (context, state) => const DoctorDashboardScreen(),
          ),
          GoRoute(
            path: '/doctor/appointments',
            builder: (context, state) => const DoctorAppointmentsScreen(),
          ),
          GoRoute(
            path: '/doctor/patients',
            builder: (context, state) => const DoctorPatientsScreen(),
          ),
          GoRoute(
            path: '/doctor/analytics',
            builder: (context, state) => const DoctorAnalyticsScreen(),
          ),
        ],
      ),

      // Doctor Stack Sub-routes
      GoRoute(
        path: '/doctor/patient/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DoctorPatientDetailScreen(patientId: id);
        },
      ),
      GoRoute(
        path: '/doctor/feedback',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DoctorFeedbackScreen(),
      ),

      // Patient Navigation Shell
      ShellRoute(
        navigatorKey: _patientShellNavigatorKey,
        builder: (context, state, child) => PatientShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/patient/home',
            builder: (context, state) => const PatientHomeScreen(),
          ),
          GoRoute(
            path: '/patient/book',
            builder: (context, state) => const PatientBookScreen(),
          ),
          GoRoute(
            path: '/patient/records',
            builder: (context, state) => const PatientRecordsScreen(),
          ),
          GoRoute(
            path: '/patient/feedback',
            builder: (context, state) => const PatientFeedbackScreen(),
          ),
        ],
      ),
    ],
  );
});
