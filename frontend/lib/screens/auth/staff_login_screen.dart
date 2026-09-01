import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController(text: "+1 (555) 345-6789");
  final _codeController = TextEditingController(text: "849201");
  final _emailController = TextEditingController(text: "staff@cure.app");
  final _passwordController = TextEditingController(text: "staff123");
  final _nameController = TextEditingController(text: "Nurse Sarah Mitchell");
  final _designationController = TextEditingController(text: "Triage & Clinical Nurse");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _submitPhoneAndCode() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both phone number and 6-digit verification code.")),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).staffAuth(
          email: "staff_${phone.replaceAll(RegExp(r'[^0-9]'), '')}@cure.app",
          password: "verified_otp_$code",
          name: phone.contains("345") ? "Nurse Sarah Mitchell" : "Elena Rostova",
          designation: phone.contains("345") ? "Triage & Clinical Specialist" : "Front Desk Coordinator",
        );

    if (success && mounted) {
      context.go('/staff/dashboard');
    }
  }

  void _submitEmailPassword() async {
    final success = await ref.read(authProvider.notifier).staffAuth(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          designation: _designationController.text.trim(),
        );

    if (success && mounted) {
      context.go('/staff/dashboard');
    }
  }

  void _quickDemoLogin() async {
    final success = await ref.read(authProvider.notifier).staffAuth(
          email: "staff@cure.app",
          password: "staff123",
          name: "Nurse Sarah Mitchell",
          designation: "Triage & Clinical Specialist",
        );

    if (success && mounted) {
      context.go('/staff/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              InkWell(
                key: const Key("staff-back-button"),
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, color: AppColors.onSurface, size: 22),
                      SizedBox(width: 4),
                      Text(
                        "Back",
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header Badge & Title
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.assignment_ind_outlined,
                  color: Color(0xFF0F766E),
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                "Clinical Staff Portal",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                "Log in to manage today's appointments, walk-in patients, lobby arrival & triage vitals.",
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // DEMO CREDENTIALS BOX
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.badge_outlined, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Demo Staff Credentials",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text(
                            "Auto-Fill Active",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text("• Email: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                        Text("staff@cure.app", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                        SizedBox(width: 12),
                        Text("• Password: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                        Text("staff123", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text("• Phone OTP: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                        Text("+1 555-345-6789", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                        SizedBox(width: 12),
                        Text("• Code: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                        Text("849201", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key("quick-staff-login-button"),
                        onPressed: authState.isLoading ? null : _quickDemoLogin,
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text(
                          "Instant 1-Tap Demo Sign In (Nurse Sarah)",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Mode Tabs: 1. Email & Password | 2. Phone + Doctor Verification Code
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.muted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  tabs: const [
                    Tab(text: "Demo ID / Email"),
                    Tab(text: "Phone + Doctor Code"),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tab Views
              SizedBox(
                height: 330,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Email & Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Staff Email ID",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          key: const Key("staff-email-input"),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "staff@cure.app",
                            prefixIcon: const Icon(Icons.email_outlined, size: 18),
                            filled: true,
                            fillColor: AppColors.surfaceSecondary,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const Text(
                          "Password",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          key: const Key("staff-password-input"),
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "staff123",
                            prefixIcon: const Icon(Icons.lock_outline, size: 18),
                            filled: true,
                            fillColor: AppColors.surfaceSecondary,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const Key("staff-login-button"),
                            onPressed: authState.isLoading ? null : _submitEmailPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Sign In with Demo ID",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Tab 2: Phone + Doctor Verification Code
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Authorized Staff Mobile Number",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          key: const Key("staff-phone-input"),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: "+1 (555) 345-6789",
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                            filled: true,
                            fillColor: AppColors.surfaceSecondary,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const Text(
                          "6-Digit Verification Code (Sent by Doctor)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          key: const Key("staff-otp-input"),
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: "849201",
                            prefixIcon: const Icon(Icons.pin_outlined, size: 18),
                            filled: true,
                            fillColor: AppColors.surfaceSecondary,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            key: const Key("verify-code-staff-login-btn"),
                            onPressed: authState.isLoading ? null : _submitPhoneAndCode,
                            icon: const Icon(Icons.verified_user_outlined, size: 18),
                            label: const Text(
                              "Verify Code & Enter Portal",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Info note
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.muted),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        "Clinical staff access is granted and managed directly by the supervising doctor under the Doctor Profile & Staff management section.",
                        style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
