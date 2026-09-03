import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/consultation.dart';
import '../../models/user.dart';

class PatientRecordsScreen extends ConsumerStatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  ConsumerState<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends ConsumerState<PatientRecordsScreen> {
  List<Consultation> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showPrescriptionDialog(BuildContext context, String imageUrlOrBase64, {String? title}) {
    showDialog(
      context: context,
      builder: (ctx) {
        Widget imageWidget;
        if (imageUrlOrBase64.startsWith("data:image")) {
          final base64Data = imageUrlOrBase64.split(",").last;
          final bytes = base64Decode(base64Data);
          imageWidget = Image.memory(bytes, fit: BoxFit.contain);
        } else {
          imageWidget = Image.network(
            imageUrlOrBase64,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(child: Text("Could not load image")),
          );
        }

        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.92),
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title ?? "Doctor's Prescription Photo",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageWidget,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Pinch or drag to zoom in and examine prescription details",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final authState = ref.read(authProvider);
    final patient = authState.currentUser is Patient ? authState.currentUser as Patient : null;
    final pid = patient?.id ?? 'patient_demo';

    try {
      final fb = ref.read(firebaseServiceProvider);
      final fbStream = fb.streamPatientConsultations(pid);
      final list = await fbStream.first.timeout(const Duration(seconds: 2));
      if (mounted && list.isNotEmpty) {
        setState(() {
          records = list;
          isLoading = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get("/patient/records") as List;
      if (mounted) {
        setState(() {
          records = res.map((e) => Consultation.fromJson(e as Map<String, dynamic>)).toList();
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMemberSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final membersState = ref.watch(patientMembersProvider);
            final members = membersState.members;
            final selected = membersState.selectedMember;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "View Records For",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final isSelected = member.id == selected.id;

                          return InkWell(
                            onTap: () {
                              ref.read(patientMembersProvider.notifier).selectMember(member);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Showing medical records for ${member.name}"),
                                  backgroundColor: const Color(0xFF0F766E),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isSelected ? const Color(0xFF0F766E).withOpacity(0.15) : const Color(0xFFF1F5F9),
                                    child: Icon(
                                      Icons.person,
                                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          "${member.relation} · ${member.ageOrDob} · ${member.gender}",
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "SELECTED",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(patientMembersProvider);
    final activeMember = membersState.selectedMember;

    // Retrieve local session recorded consultations to ensure fresh consultations appear
    final recordedConsultations = ref.watch(recordedConsultationsProvider);

    // Merge backend consultations + local consultations
    final List<Consultation> mergedRecords = [...records];
    for (final rc in recordedConsultations) {
      if (!mergedRecords.any((c) => c.id == rc.id || c.appointmentId == rc.appointmentId)) {
        mergedRecords.insert(
          0,
          Consultation(
            id: rc.id,
            appointmentId: rc.appointmentId,
            patientId: rc.patientId,
            patientName: rc.patientName,
            diagnosis: rc.diagnosis,
            prescription: rc.prescription,
            prescriptionImageUrl: rc.prescriptionImageUrl,
            followUpInstructions: rc.followUpInstructions,
            createdAt: rc.createdAt,
            doctor: Doctor(
              id: rc.doctorId,
              email: '',
              name: rc.doctorName,
              specialty: 'Consultation',
              clinicName: 'Cure Clinic',
            ),
          ),
        );
      }
    }

    // Filter consultations STRICTLY for the active patient profile so details are never mixed
    final memberRecords = mergedRecords.where((c) {
      if (c.patientName != null && c.patientName!.trim().isNotEmpty) {
        return c.patientName!.trim().toLowerCase() == activeMember.name.trim().toLowerCase();
      }
      if (c.patientId != null && c.patientId!.trim().isNotEmpty) {
        return c.patientId!.contains(activeMember.id);
      }
      return activeMember.isPrimary;
    }).toList();

    return Scaffold(
      key: const Key("patient-records-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Member Selector Bar
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Medical Records & Prescriptions",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Active Member Switcher Card
                  InkWell(
                    key: const Key("records-member-switcher"),
                    onTap: () => _showMemberSelectorModal(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF0F766E), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      activeMember.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        activeMember.relation.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "Showing records exclusively for ${activeMember.name} (${activeMember.ageOrDob})",
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0F766E), size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Records List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
                  : memberRecords.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.description_outlined, size: 32, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No records for ${activeMember.name} yet",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Prescriptions and doctor slips for ${activeMember.name} will be saved and displayed here separately.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/patient/book'),
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text("Book Visit for ${activeMember.name}"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: memberRecords.length,
                          itemBuilder: (context, index) {
                            final item = memberRecords[index];
                            final photoUrl = item.prescriptionImageUrl;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Card Head
                                    Row(
                                      children: [
                                        const Icon(Icons.medical_services, color: AppColors.brand, size: 20),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.doctor?.name ?? "Doctor",
                                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15),
                                              ),
                                              Text(
                                                item.doctor?.specialty ?? "Consultation",
                                                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          DateFormat.yMMMd().format(item.createdAt),
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),

                                    const Divider(color: AppColors.border, height: 24),

                                    const Text("DIAGNOSIS", style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(item.diagnosis, style: const TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.4)),

                                    if (item.prescription.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      const Text("PRESCRIPTION", style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(item.prescription, style: const TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.4)),
                                    ],

                                    // Prescription Photo Card
                                    if (photoUrl != null && photoUrl.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      const Text(
                                        "ORIGINAL PRESCRIPTION SLIP",
                                        style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => _showPrescriptionDialog(context, photoUrl, title: "Prescription from ${item.doctor?.name ?? 'Doctor'}"),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        child: Container(
                                          padding: const EdgeInsets.all(AppSpacing.md),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                            border: Border.all(color: AppColors.brand.withOpacity(0.35)),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: AppColors.brand.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.image, color: AppColors.brand, size: 20),
                                              ),
                                              const SizedBox(width: AppSpacing.md),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "View Uploaded Prescription Slip",
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface),
                                                    ),
                                                    Text(
                                                      "Tap to zoom and view handwritten slip",
                                                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.brand),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
