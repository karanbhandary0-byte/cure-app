import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';

class RoleSelectorScreen extends ConsumerStatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  ConsumerState<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends ConsumerState<RoleSelectorScreen> {
  static const String bgImageUrl =
      "https://images.unsplash.com/photo-1593824261342-fd6ee146f73d?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NTY2Njd8MHwxfHNlYXJjaHwyfHxjbGVhbiUyMG1lZGljYWwlMjBob3NwaXRhbCUyMGludGVyaW9yJTIwYWJzdHJhY3QlMjBibHVyJTIwYmx1ZXxlbnwwfHx8fDE3ODE2MTE0Nzl8MA&ixlib=rb-4.1.0&q=85";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              bgImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F1115),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x730059B2),
                    Color(0xD90F1115),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.x2l),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        "Cure",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        "The complete consultation loop — for doctors and patients.",
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),

                  // Cards
                  Column(
                    children: [
                      _RoleCard(
                        key: const Key("select-doctor-button"),
                        icon: Icons.medical_services_outlined,
                        iconBg: AppColors.brandTertiary,
                        iconColor: AppColors.brand,
                        title: "I am a Doctor",
                        subtitle: "Manage appointments, records & status",
                        onTap: () => context.go('/auth/doctor-login'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _RoleCard(
                        key: const Key("select-patient-button"),
                        icon: Icons.person_outline,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFF92400E),
                        title: "I am a Patient",
                        subtitle: "Book visits, get reminders, share feedback",
                        onTap: () => context.go('/auth/patient-login'),
                      ),
                    ],
                  ),

                  // Footer
                  const Center(
                    child: Text(
                      "Secure · HIPAA-style data handling · Built for clinics",
                      style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
