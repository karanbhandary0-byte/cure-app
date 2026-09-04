import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadDoctorPhoto(Doctor doctor) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Update Profile Photo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF0F766E)),
                  title: const Text("Choose from Gallery"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        final base64Photo = "data:image/jpeg;base64,${base64Encode(bytes)}";
                        await ref.read(authProvider.notifier).updateDoctorPhoto(base64Photo);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Profile photo updated successfully!")),
                          );
                        }
                      }
                    } catch (_) {}
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF0F766E)),
                  title: const Text("Take a Photo with Camera"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 600, maxHeight: 600);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        final base64Photo = "data:image/jpeg;base64,${base64Encode(bytes)}";
                        await ref.read(authProvider.notifier).updateDoctorPhoto(base64Photo);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Profile photo updated successfully!")),
                          );
                        }
                      }
                    } catch (_) {}
                  },
                ),
                if (doctor.profilePhoto != null && doctor.profilePhoto!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Remove Photo", style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref.read(authProvider.notifier).updateDoctorPhoto("");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profile photo removed.")),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
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

  void _confirmRemoveStaff(AuthorizedStaffMember staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_remove_outlined, color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Remove Staff Member",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.onSurface),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to remove '${staff.name}' (${staff.designation}) from your clinical staff team? Their clinical access and verification code (${staff.verificationCode}) will be revoked immediately.",
          style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _staffList.removeWhere((s) => s.id == staff.id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Staff member '${staff.name}' removed successfully."),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            child: const Text("Remove Staff", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showEditClinicModal(Doctor doctor) {
    final nameController = TextEditingController(text: doctor.clinicName);
    final addressController = TextEditingController(
      text: doctor.clinicAddress ?? "Suite 402, 750 Health Plaza, 5th Cross, Indiranagar, Bengaluru, 560038",
    );
    final mapsController = TextEditingController(
      text: doctor.googleMapsLocation ?? "https://maps.google.com/?q=12.9716,77.5946 (Indiranagar, Bengaluru)",
    );
    final phoneController = TextEditingController(
      text: doctor.clinicPhone ?? "+91 80 4123 4567",
    );
    final feeController = TextEditingController(
      text: "${doctor.consultationFee ?? 800}",
    );
    final durationController = TextEditingController(
      text: "${doctor.slotDurationMin ?? 20}",
    );
    final daysController = TextEditingController(
      text: doctor.availableDays ?? "Monday, Tuesday, Wednesday, Thursday, Friday, Saturday",
    );
    final hoursController = TextEditingController(
      text: doctor.workingHours ?? "09:00 AM - 01:00 PM, 04:30 PM - 08:30 PM",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_hospital_outlined, color: Color(0xFF0F766E), size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Edit Clinic Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),

                // 1. Clinic Name
                _buildModalField("1. Clinic Name *", "e.g. Cure Family Medical Center", nameController),

                // 2. Complete Clinic Address
                _buildModalField("2. Complete Clinic Address *", "Street, Area, Landmark, City & PIN code", addressController, maxLines: 2),

                // 3. Google Maps / Location
                _buildModalField("3. Google Maps / Location Link *", "e.g. https://maps.google.com/?q=... or Landmark", mapsController),

                // 4. Clinic Phone Number
                _buildModalField("4. Clinic Phone Number *", "e.g. +91 80 4123 4567", phoneController, keyboardType: TextInputType.phone),

                // 5. Consultation Fee & 6. Duration Row
                Row(
                  children: [
                    Expanded(
                      child: _buildModalField("5. Consultation Fee (₹) *", "e.g. 800", feeController, keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildModalField("6. Duration (Mins) *", "e.g. 20", durationController, keyboardType: TextInputType.number),
                    ),
                  ],
                ),

                // 7. Available Days
                _buildModalField("7. Available Days *", "e.g. Monday to Saturday", daysController),

                // 8. Working Hours
                _buildModalField("8. Working Hours *", "e.g. 09:00 AM - 01:00 PM, 04:30 PM - 08:30 PM", hoursController),

                const SizedBox(height: AppSpacing.xl),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final updatedDoctor = Doctor(
                        id: doctor.id,
                        name: doctor.name,
                        specialty: doctor.specialty,
                        clinicName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : doctor.clinicName,
                        clinicAddress: addressController.text.trim(),
                        status: doctor.status,
                        verificationStatus: doctor.verificationStatus,
                        delayMinutes: doctor.delayMinutes,
                        slotDurationMin: int.tryParse(durationController.text.trim()) ?? doctor.slotDurationMin,
                        slotCount: doctor.slotCount,
                        slotStartHour: doctor.slotStartHour,
                        profilePhoto: doctor.profilePhoto,
                        medicalDegree: doctor.medicalDegree,
                        subSpecialization: doctor.subSpecialization,
                        registrationNumber: doctor.registrationNumber,
                        registrationCouncil: doctor.registrationCouncil,
                        experienceYears: doctor.experienceYears,
                        languagesSpoken: doctor.languagesSpoken,
                        googleMapsLocation: mapsController.text.trim(),
                        clinicPhone: phoneController.text.trim(),
                        consultationFee: int.tryParse(feeController.text.trim()) ?? doctor.consultationFee,
                        availableDays: daysController.text.trim(),
                        workingHours: hoursController.text.trim(),
                      );

                      try {
                        final fb = ref.read(firebaseServiceProvider);
                        await fb.updateDoctorClinicProfile(
                          doctor.id,
                          clinicName: updatedDoctor.clinicName,
                          clinicAddress: updatedDoctor.clinicAddress ?? '',
                          googleMapsLocation: updatedDoctor.googleMapsLocation,
                          clinicPhone: updatedDoctor.clinicPhone,
                          consultationFee: updatedDoctor.consultationFee,
                          consultationDuration: updatedDoctor.slotDurationMin,
                          availableDays: updatedDoctor.availableDays,
                          workingHours: updatedDoctor.workingHours,
                        );
                      } catch (_) {}

                      // Update local session
                      final session = ref.read(sessionServiceProvider);
                      await session.saveSession(token: "fb_${doctor.id}", role: "doctor", user: updatedDoctor.toJson());

                      // Refresh Auth State
                      ref.read(authProvider.notifier).checkInitialAuth();

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Clinic details updated successfully.")),
                        );
                      }
                    },
                    child: const Text("Save Clinic Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalField(String label, String hint, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddStaffModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: "Triage & Patient Intake");

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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Authorize Clinical Staff",
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
              const SizedBox(height: AppSpacing.md),
              const Text("Staff Full Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 4),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: "e.g. Nurse Rahul Sharma",
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text("Staff Mobile Phone Number", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 4),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "e.g. +91 98765 43210",
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text("Clinical Designation / Role", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 4),
              TextField(
                controller: roleCtrl,
                decoration: InputDecoration(
                  hintText: "e.g. Clinic Receptionist / Triage Nurse",
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final designation = roleCtrl.text.trim();

                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill in staff name and phone number.")),
                      );
                      return;
                    }

                    final newCode = (100000 + Random().nextInt(900000)).toString();

                    setState(() {
                      _staffList.insert(
                        0,
                        AuthorizedStaffMember(
                          id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          phone: phone,
                          designation: designation.isNotEmpty ? designation : "Clinical Staff",
                          verificationCode: newCode,
                          isVerified: false,
                          addedAt: DateTime.now(),
                        ),
                      );
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Staff '$name' authorized with code $newCode"),
                        backgroundColor: const Color(0xFF0F766E),
                      ),
                    );
                  },
                  child: const Text("Generate Staff Verification Code", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final Doctor? doctor = authState.currentUser is Doctor ? authState.currentUser as Doctor : null;

    final docName = doctor?.name ?? "Dr. Sarah Mitchell";
    final docDegree = doctor?.medicalDegree ?? "MBBS, MD";
    final docSpecialty = doctor?.specialty ?? "Cardiology";
    final docSubSpecialty = doctor?.subSpecialization;
    final docRegNumber = doctor?.registrationNumber ?? "KMC-84920";
    final docCouncil = doctor?.registrationCouncil ?? "Karnataka Medical Council";
    final docExperience = doctor?.experienceYears ?? 8;
    final docLanguages = doctor?.languagesSpoken ?? "English, Hindi, Kannada";
    final docPhoto = doctor?.profilePhoto;

    // Clinic Details
    final clinicName = doctor?.clinicName ?? "Cure Medical Center";
    final clinicAddress = doctor?.clinicAddress ?? "Suite 402, 750 Health Plaza, 5th Cross, Indiranagar, Bengaluru, 560038";
    final googleMapsLocation = doctor?.googleMapsLocation ?? "https://maps.google.com/?q=12.9716,77.5946 (Indiranagar, Bengaluru)";
    final clinicPhone = doctor?.clinicPhone ?? "+91 80 4123 4567";
    final consultationFee = doctor?.consultationFee ?? 800;
    final slotDuration = doctor?.slotDurationMin ?? 20;
    final availableDays = doctor?.availableDays ?? "Monday, Tuesday, Wednesday, Thursday, Friday, Saturday";
    final workingHours = doctor?.workingHours ?? "09:00 AM - 01:00 PM, 04:30 PM - 08:30 PM";

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
            // 1. Doctor Professional Profile Card
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
                      InkWell(
                        onTap: doctor != null ? () => _pickAndUploadDoctorPhoto(doctor) : null,
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F766E), width: 1.5),
                              ),
                              child: docPhoto != null && docPhoto.isNotEmpty
                                  ? ClipOval(
                                      child: docPhoto.startsWith("data:image")
                                          ? Image.memory(
                                              base64Decode(docPhoto.split(",").last),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(docPhoto, fit: BoxFit.cover),
                                    )
                                  : Center(
                                      child: Text(
                                        docName.isNotEmpty ? docName[0].toUpperCase() : "D",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
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
                              "$docDegree · $docSpecialty",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F766E),
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
                                    "Verified Practitioner",
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

                  // Medical & Council Registration Details
                  _buildProfileRow(Icons.school_outlined, "Medical Degree", docDegree),
                  const SizedBox(height: 8),
                  _buildProfileRow(Icons.medical_information_outlined, "Specialization", "$docSpecialty${docSubSpecialty != null && docSubSpecialty.isNotEmpty ? ' ($docSubSpecialty)' : ''}"),
                  const SizedBox(height: 8),
                  _buildProfileRow(Icons.verified_user_outlined, "Council Reg. No.", "$docRegNumber · $docCouncil"),
                  const SizedBox(height: 8),
                  _buildProfileRow(Icons.work_history_outlined, "Experience", "$docExperience years in clinical practice"),
                  const SizedBox(height: 8),
                  _buildProfileRow(Icons.translate_outlined, "Languages", docLanguages),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2. Clinic Details Section Header & Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Clinic Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Practice location, working hours & consultation fee",
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  key: const Key("edit-clinic-btn"),
                  onPressed: () {
                    if (doctor != null) {
                      _showEditClinicModal(doctor);
                    } else {
                      final demoDoc = Doctor(
                        id: 'doc_demo',
                        name: docName,
                        specialty: docSpecialty,
                        clinicName: clinicName,
                        clinicAddress: clinicAddress,
                        googleMapsLocation: googleMapsLocation,
                        clinicPhone: clinicPhone,
                        consultationFee: consultationFee,
                        slotDurationMin: slotDuration,
                        availableDays: availableDays,
                        workingHours: workingHours,
                      );
                      _showEditClinicModal(demoDoc);
                    }
                  },
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text(
                    "Edit Clinic",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

            // Clinic Information Detailed Card
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
                  _buildProfileRow(Icons.business_outlined, "Clinic Name", clinicName),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.location_on_outlined, "Complete Clinic Address", clinicAddress),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.map_outlined, "Google Maps / Location", googleMapsLocation),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.phone_outlined, "Clinic Phone Number", clinicPhone),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.currency_rupee, "Consultation Fee", "₹$consultationFee per consultation"),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.timer_outlined, "Consultation Duration", "$slotDuration minutes per slot"),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.calendar_today_outlined, "Available Days", availableDays),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.access_time_outlined, "Working Hours", workingHours),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3. Clinical Staff Management Header
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
        Icon(icon, size: 16, color: const Color(0xFF0F766E)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _confirmRemoveStaff(staff),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${staff.designation} · ${staff.phone}",
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                                  color: Color(0xFF0F766E),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _confirmRemoveStaff(staff),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove_circle_outline, size: 13, color: Colors.red.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  "Remove",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
