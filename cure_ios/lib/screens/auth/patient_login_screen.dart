import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class PatientLoginScreen extends ConsumerStatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  ConsumerState<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends ConsumerState<PatientLoginScreen> {
  bool isOtpStep = false;
  final _phoneController = TextEditingController(text: "+15551110001");
  final _codeController = TextEditingController();
  String _hintCode = "";

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final mockCode = await ref
        .read(authProvider.notifier)
        .sendPatientOtp(_phoneController.text.trim());

    if (mockCode != null && mounted) {
      setState(() {
        _hintCode = mockCode;
        isOtpStep = true;
      });
    }
  }

  void _verifyOtp() async {
    final success = await ref
        .read(authProvider.notifier)
        .verifyPatientOtp(_phoneController.text.trim(), _codeController.text.trim());

    if (success && mounted) {
      context.go('/patient/home');
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
              // Back Button
              InkWell(
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.smartphone,
                  color: Color(0xFF92400E),
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                !isOtpStep ? "Sign in with mobile" : "Enter the 6-digit code",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                !isOtpStep
                    ? "We'll send you a one-time passcode via SMS."
                    : "Code sent to ${_phoneController.text}. Mock code: $_hintCode",
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!isOtpStep) ...[
                const Text(
                  "Mobile number",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  key: const Key("patient-phone-input"),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: "+1 555 1110001",
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
              ] else ...[
                const Text(
                  "Verification code",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  key: const Key("patient-otp-input"),
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "123456",
                    hintStyle: const TextStyle(color: AppColors.muted, letterSpacing: 6),
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
                  key: const Key("patient-auth-submit"),
                  onPressed: authState.isLoading
                      ? null
                      : (!isOtpStep ? _sendOtp : _verifyOtp),
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
                          !isOtpStep ? "Send code" : "Verify & continue",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              if (isOtpStep) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        isOtpStep = false;
                        _codeController.clear();
                      });
                    },
                    child: const Text(
                      "Change number",
                      style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.x2l),

              // Demo hint box
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
                      "Demo patient phones",
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "+15551110001 · +15551110002 · +15551110003",
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "OTP code: 123456",
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
