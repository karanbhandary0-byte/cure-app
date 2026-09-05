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
  final _nameController = TextEditingController(text: "Jane Doe");
  final _ageController = TextEditingController(text: "28");
  String _selectedGender = "Female";
  final _phoneController = TextEditingController(text: "+91 98765 43210");
  final _codeController = TextEditingController();
  String _hintCode = "123456";
  String? _validationError;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    setState(() => _validationError = null);
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final phone = _phoneController.text.trim();
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (name.isEmpty) {
      setState(() => _validationError = "Please enter your full name.");
      return;
    }

    final age = int.tryParse(ageStr);
    if (age == null || age < 1 || age > 120) {
      setState(() => _validationError = "Please enter a valid age (1 - 120).");
      return;
    }

    if (cleanDigits.length < 10) {
      setState(() => _validationError = "Please enter a valid 10-digit mobile number.");
      return;
    }

    final formattedPhone = phone.startsWith('+') ? phone : "+91 $cleanDigits";

    final mockCode = await ref.read(authProvider.notifier).sendPatientOtp(
      phone: formattedPhone,
      name: name,
      age: age,
      gender: _selectedGender,
    );

    if (mockCode != null && mounted) {
      setState(() {
        _hintCode = mockCode;
        isOtpStep = true;
      });
    }
  }

  void _verifyOtp() async {
    setState(() => _validationError = null);
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 28;
    final phone = _phoneController.text.trim();
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final formattedPhone = phone.startsWith('+') ? phone : "+91 $cleanDigits";

    if (code.length < 4) {
      setState(() => _validationError = "Please enter the 6-digit authentication code.");
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyPatientOtp(
      phone: formattedPhone,
      code: code,
      name: name,
      age: age,
      gender: _selectedGender,
    );

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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Color(0xFF2563EB),
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                !isOtpStep ? "Patient Sign In" : "Authentication Code",
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
                    ? "Enter your personal details & mobile number to sign in or access records."
                    : "Enter the 6-digit code sent to ${_phoneController.text.trim()}",
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!isOtpStep) ...[
                // 1. Full Name
                const Text(
                  "Full Name *",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key("patient-name-input"),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: "e.g. Jane Doe",
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    hintStyle: const TextStyle(color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Age & Gender Row
                Row(
                  children: [
                    // Age
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Age (years) *",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key("patient-age-input"),
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: "e.g. 28",
                              prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                              hintStyle: const TextStyle(color: AppColors.muted),
                              filled: true,
                              fillColor: AppColors.surfaceSecondary,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Gender
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Gender *",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: const Key("patient-gender-input"),
                            value: _selectedGender,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surfaceSecondary,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: "Female", child: Text("Female")),
                              DropdownMenuItem(value: "Male", child: Text("Male")),
                              DropdownMenuItem(value: "Other", child: Text("Other")),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGender = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Mobile Number
                const Text(
                  "Mobile Number *",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key("patient-phone-input"),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: "+91 98765 43210",
                    prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                    hintStyle: const TextStyle(color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "We'll send a 6-digit authentication code via SMS to this mobile number.",
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ] else ...[
                // Patient Info Summary Chip
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${_nameController.text.trim()} ($_selectedGender, ${_ageController.text.trim()}) · ${_phoneController.text.trim()}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 4. Verification / Authentication Code
                const Text(
                  "Enter 6-Digit Authentication Code *",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key("patient-otp-input"),
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F766E),
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "123456",
                    hintStyle: const TextStyle(color: AppColors.muted, letterSpacing: 8),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.lg,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Mock Code Hint Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "SMS sent! Demo authentication code: $_hintCode",
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Validation / Auth Error
              if (_validationError != null || (authState.error != null && authState.error!.isNotEmpty)) ...[
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
                          _validationError ?? authState.error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
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
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    elevation: 0,
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
                          !isOtpStep ? "Get Authentication Code" : "Verify & Sign In",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              if (isOtpStep) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          isOtpStep = false;
                          _codeController.clear();
                        });
                      },
                      icon: const Icon(Icons.edit, size: 16, color: AppColors.brand),
                      label: const Text(
                        "Edit Details",
                        style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _sendOtp,
                      icon: const Icon(Icons.refresh, size: 16, color: AppColors.brand),
                      label: const Text(
                        "Resend Code",
                        style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Walk-in / Records notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.history_edu_rounded, size: 18, color: Color(0xFF0F766E)),
                        SizedBox(width: 6),
                        Text(
                          "Accessing Clinic Visit Records",
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "If you registered at the clinic as a walk-in, enter the same mobile number to automatically view all your consultation records, prescriptions, and lab tests.",
                      style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.3),
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
