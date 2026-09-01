import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class AuthorizedStaffMember {
  final String id;
  final String name;
  final String phone;
  final String designation;
  String verificationCode;
  bool isVerified;
  final DateTime addedAt;

  AuthorizedStaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.designation,
    required this.verificationCode,
    this.isVerified = false,
    required this.addedAt,
  });
}

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final List<AuthorizedStaffMember> _staffList = [
    AuthorizedStaffMember(
      id: 'staff_sarah_01',
      name: 'Nurse Sarah Mitchell',
      phone: '+1 (555) 345-6789',
      designation: 'Triage & Clinical Nurse',
      verificationCode: '849201',
      isVerified: true,
      addedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    AuthorizedStaffMember(
      id: 'staff_elena_02',
      name: 'Elena Rostova',
      phone: '+1 (555) 672-8819',
      designation: 'Front Desk & Intake Coordinator',
      verificationCode: '429105',
      isVerified: false,
      addedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final Doctor? doctor = authState.currentUser is Doctor ? authState.currentUser as Doctor : null;

    final docName = doctor?.name ?? "Dr. Robert Smith, MD";
    final docSpecialty = doctor?.specialty ?? "Cardiology & Internal Medicine";
    final clinicName = doctor?.clinicName ?? "Cure Medical Center";
    final clinicAddress = doctor?.clinicAddress ?? "Suite 402, 750 Health Plaza, Medical District";
    final slotDuration = doctor?.slotDurationMin ?? 30;
    final slotCount = doctor?.slotCount ?? 8;
    final slotStartHour = doctor?.slotStartHour ?? 9;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Doctor Profile & Staff",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.muted),
            tooltip: "Log Out",
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Profile Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.brandTertiary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: AppColors.brand,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              docSpecialty,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Color(0xFF16A34A)),
                                  SizedBox(width: 4),
                                  Text(
                                    "Verified Practice",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSpacing.md),

                  // Clinic Info Details
                  _buildProfileRow(Icons.business_outlined, "Clinic Practice", clinicName),
                  const SizedBox(height: 8),
                  _buildProfileRow(Icons.location_on_outlined, "Location", clinicAddress),
                  const SizedBox(height: 8),
                  _buildProfileRow(
                    Icons.access_time_outlined,
                    "Consultation Slots",
                    "$slotDuration mins/slot · $slotCount slots/day (Starts at ${slotStartHour.toString().padLeft(2, '0')}:00)",
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Clinical Staff Management Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Clinical Staff Team",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Authorize staff via phone number & verification code",
                      style: TextStyle(fontSize: 12, color: AppColors.muted.withOpacity(0.9)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  key: const Key("add-staff-member-btn"),
                  onPressed: _openAddStaffModal,
                  icon: const Icon(Icons.person_add_alt, size: 16),
                  label: const Text(
                    "+ Add Staff",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Staff Notice Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1).withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF0F766E), size: 22),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "When you add a clinical staff number, an instant verification code is generated. Once verified, the staff member gains access to patient check-in, triage vitals, and queue management.",
                      style: TextStyle(fontSize: 11, color: Color(0xFF115E59), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Authorized Staff Cards
            if (_staffList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    "No clinical staff members added yet.",
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              ..._staffList.map((staff) => _buildStaffCard(staff)),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffCard(AuthorizedStaffMember staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: staff.isVerified ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: staff.isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.assignment_ind_outlined,
                  color: staff.isVerified ? const Color(0xFF15803D) : const Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            staff.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: staff.isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                staff.isVerified ? Icons.check_circle : Icons.hourglass_top,
                                size: 12,
                                color: staff.isVerified ? const Color(0xFF15803D) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                staff.isVerified ? "Verified & Active" : "Pending Verification",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: staff.isVerified ? const Color(0xFF15803D) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${staff.designation} · ${staff.phone}",
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Verification Code: ",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                          Text(
                            staff.verificationCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.xs),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!staff.isVerified) ...[
                TextButton.icon(
                  onPressed: () => _openVerifyStaffDialog(staff),
                  icon: const Icon(Icons.check, size: 16, color: Color(0xFF15803D)),
                  label: const Text(
                    "Enter Code to Verify",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () => _resendCode(staff),
                  icon: const Icon(Icons.send_outlined, size: 14, color: AppColors.brand),
                  label: const Text(
                    "Resend SMS",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand),
                  ),
                ),
              ],
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _staffList.removeWhere((s) => s.id == staff.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Staff member ${staff.name} access revoked.")),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.error),
                label: const Text(
                  "Remove",
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resendCode(AuthorizedStaffMember staff) {
    final newCode = (100000 + Random().nextInt(900000)).toString();
    setState(() {
      staff.verificationCode = newCode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📲 Verification code $newCode sent via SMS to ${staff.phone}"),
        backgroundColor: const Color(0xFF0F766E),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openVerifyStaffDialog(AuthorizedStaffMember staff) {
    final codeController = TextEditingController(text: staff.verificationCode);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          title: Text("Verify ${staff.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter the 6-digit code sent to ${staff.phone}:",
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: "6-digit code",
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.trim() == staff.verificationCode) {
                  setState(() {
                    staff.isVerified = true;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("🎉 ${staff.name} is now VERIFIED & authorized for clinical portal!"),
                      backgroundColor: const Color(0xFF15803D),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Invalid verification code. Please check and try again."),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm Verification"),
            ),
          ],
        );
      },
    );
  }

  void _openAddStaffModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: "+1 (555) ");
    final designationCtrl = TextEditingController(text: "Triage & Clinical Nurse");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Clinical Staff Member",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Enter her name and phone number to dispatch an activation verification code.",
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),

              _buildInputField("Staff Full Name *", nameCtrl, "e.g. Nurse Sarah Mitchell"),
              const SizedBox(height: AppSpacing.sm),
              _buildInputField("Mobile Number (SMS verification) *", phoneCtrl, "+1 (555) 000-0000"),
              const SizedBox(height: AppSpacing.sm),
              _buildInputField("Designation / Role", designationCtrl, "e.g. Triage Nurse / Intake Specialist"),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key("submit-add-staff-btn"),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;

                    final generatedCode = (100000 + Random().nextInt(900000)).toString();
                    final newStaff = AuthorizedStaffMember(
                      id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      designation: designationCtrl.text.trim().isEmpty
                          ? "Triage & Clinical Nurse"
                          : designationCtrl.text.trim(),
                      verificationCode: generatedCode,
                      isVerified: false,
                      addedAt: DateTime.now(),
                    );

                    setState(() {
                      _staffList.add(newStaff);
                    });

                    Navigator.pop(ctx);

                    // Show visual SMS sent banner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("📲 Verification code $generatedCode sent to ${newStaff.phone}!"),
                        backgroundColor: const Color(0xFF0F766E),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: "VERIFY NOW",
                          textColor: Colors.white,
                          onPressed: () => _openVerifyStaffDialog(newStaff),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text(
                    "Send Verification Code & Add Staff",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }
}
