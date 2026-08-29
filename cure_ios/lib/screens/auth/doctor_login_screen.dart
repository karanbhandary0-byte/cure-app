import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class DoctorLoginScreen extends ConsumerStatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  ConsumerState<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends ConsumerState<DoctorLoginScreen> {
  bool isRegister = false;
  final _emailController = TextEditingController(text: "dr.smith@cure.app");
  final _passwordController = TextEditingController(text: "doctor123");
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _clinicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _specialtyController.dispose();
    _clinicController.dispose();
    super.dispose();
  }

  void _submit() async {
    final success = await ref.read(authProvider.notifier).doctorAuth(
          isRegister: isRegister,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          specialty: _specialtyController.text.trim(),
          clinicName: _clinicController.text.trim(),
        );

    if (success && mounted) {
      context.go('/doctor/dashboard');
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
                key: const Key("back-button"),
                onTap: () => context.go('/'),
                child: const Row(
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
              const SizedBox(height: AppSpacing.lg),

              // Header Icon & Title
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.brand,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isRegister ? "Create doctor account" : "Doctor Sign in",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isRegister ? "Set up your clinic in seconds." : "Welcome back to Cure.",
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (isRegister) ...[
                _Field(
                  key: const Key("reg-name"),
                  label: "Full name",
                  hint: "Dr. Jane Doe",
                  controller: _nameController,
                ),
                _Field(
                  key: const Key("reg-specialty"),
                  label: "Specialty",
                  hint: "Cardiology",
                  controller: _specialtyController,
                ),
                _Field(
                  key: const Key("reg-clinic"),
                  label: "Clinic name",
                  hint: "Wellness Family Clinic",
                  controller: _clinicController,
                ),
              ],

              _Field(
                key: const Key("login-email"),
                label: "Email",
                hint: "doctor@clinic.com",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              _Field(
                key: const Key("login-password"),
                label: "Password",
                hint: "••••••••",
                controller: _passwordController,
                obscureText: true,
              ),

              if (authState.error != null && authState.error!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key("doctor-login-submit"),
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isRegister ? "Create account" : "Sign in",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Toggle Mode
              Center(
                child: TextButton(
                  key: const Key("toggle-auth-mode"),
                  onPressed: () {
                    ref.read(authProvider.notifier).clearError();
                    setState(() {
                      isRegister = !isRegister;
                    });
                  },
                  child: Text(
                    isRegister ? "Have an account? Sign in" : "New here? Create an account",
                    style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.x2l),

              // Demo credentials box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Demo doctor login",
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "dr.smith@cure.app · doctor123",
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
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

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _Field({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
