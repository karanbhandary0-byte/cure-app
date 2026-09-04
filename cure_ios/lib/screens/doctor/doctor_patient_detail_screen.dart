import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';

class DoctorPatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const DoctorPatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends ConsumerState<DoctorPatientDetailScreen> {
  final _followUpController = TextEditingController();
  DateTime? _nextFollowUpDate;
  Uint8List? _prescriptionImageBytes;
  String? _prescriptionBase64;
  Uint8List? _reportImageBytes;
  String? _reportBase64;
  bool isPickingImage = false;
  bool isPickingReportImage = false;
  bool isSaving = false;

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _pickPrescription(ImageSource source) async {
    try {
      setState(() => isPickingImage = true);
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
        setState(() {
          _prescriptionImageBytes = bytes;
          _prescriptionBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error selecting image: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isPickingImage = false);
    }
  }

  Future<void> _pickReport(ImageSource source) async {
    try {
      setState(() => isPickingReportImage = true);
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
        setState(() {
          _reportImageBytes = bytes;
          _reportBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error selecting report image: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isPickingReportImage = false);
    }
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
                      title ?? "Doctor's Document Photo",
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
                  "Pinch or drag to zoom in and examine details",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitConsultation(String? appointmentId, [String? patientName]) async {
    final followUp = _followUpController.text.trim();
    final followUpDateStr = _nextFollowUpDate != null ? DateFormat('yyyy-MM-dd').format(_nextFollowUpDate!) : null;
    final photo = _prescriptionBase64;
    final photoReport = _reportBase64;

    if (followUp.isEmpty && photo == null && photoReport == null && followUpDateStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter follow-up notes, attach prescription or report photos, or select next follow-up date.")),
      );
      return;
    }
    setState(() => isSaving = true);
    final diag = followUp.isNotEmpty ? followUp : "Doctor Consultation & Prescription";
    final pres = "";
    final apptId = (appointmentId != null && appointmentId.isNotEmpty)
        ? appointmentId
        : 'appt_${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}';

    final currentDoctor = ref.read(authProvider).currentUser;
    final doctorId = currentDoctor?.id ?? 'doc_current';
    final doctorName = currentDoctor?.name ?? 'Dr. Sarah';
    final doctorSpecialty = currentDoctor is Doctor ? (currentDoctor as Doctor).specialty : 'General Physician';

    // Always record locally in recordedConsultationsProvider so it's instantly available
    ref.read(recordedConsultationsProvider.notifier).addConsultation(
      RecordedConsultation(
        id: 'consult_${DateTime.now().millisecondsSinceEpoch}',
        doctorId: doctorId,
        patientId: widget.patientId,
        patientName: patientName,
        appointmentId: apptId,
        diagnosis: diag,
        prescription: pres,
        prescriptionImageUrl: photo,
        reportImageUrl: photoReport,
        followUpInstructions: followUp,
        followUpDate: followUpDateStr,
        createdAt: DateTime.now(),
        doctorName: doctorName,
      ),
    );

    try {
      final fb = ref.read(firebaseServiceProvider);
      await fb.createConsultation(
        appointmentId: apptId,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        patientId: widget.patientId,
        patientName: patientName,
        diagnosis: diag,
        prescription: pres,
        prescriptionImageUrl: photo,
        reportImageUrl: photoReport,
        followUpInstructions: followUp,
        followUpDate: followUpDateStr,
      );

      _followUpController.clear();
      setState(() {
        _nextFollowUpDate = null;
        _prescriptionImageBytes = null;
        _prescriptionBase64 = null;
        _reportImageBytes = null;
        _reportBase64 = null;
      });

      ref.invalidate(patientDetailProvider(widget.patientId));
      ref.read(doctorDashboardProvider.notifier).load();
      return;
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      await api.post("/doctor/consultations", body: {
        "appointment_id": apptId,
        "patient_id": widget.patientId,
        "patient_name": patientName,
        "doctor_name": doctorName,
        "doctor_specialty": doctorSpecialty,
        "diagnosis": diag,
        "prescription": pres,
        "prescription_image_url": photo,
        "report_image_url": photoReport,
        "follow_up_instructions": followUp,
        "follow_up_date": followUpDateStr,
      });

      _followUpController.clear();
      setState(() {
        _nextFollowUpDate = null;
        _prescriptionImageBytes = null;
        _prescriptionBase64 = null;
        _reportImageBytes = null;
        _reportBase64 = null;
      });

      ref.invalidate(patientDetailProvider(widget.patientId));
      ref.read(doctorDashboardProvider.notifier).load();
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget _buildQuickDateChip(String label, int days) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected = _nextFollowUpDate != null &&
        _nextFollowUpDate!.year == targetDate.year &&
        _nextFollowUpDate!.month == targetDate.month &&
        _nextFollowUpDate!.day == targetDate.day;

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.brand,
        ),
      ),
      backgroundColor: isSelected ? AppColors.brand : AppColors.brand.withOpacity(0.08),
      side: BorderSide(color: isSelected ? AppColors.brand : AppColors.brand.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () {
        setState(() => _nextFollowUpDate = targetDate);
      },
    );
  }

  Color _statusColor(String? s) {
    if (s == "completed") return const Color(0xFF065F46);
    if (s == "delayed") return const Color(0xFF92400E);
    if (s == "cancelled") return const Color(0xFF991B1B);
    return AppColors.brand;
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(patientDetailProvider(widget.patientId));

    return Scaffold(
      key: const Key("patient-detail-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: asyncDetail.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
          error: (err, stack) => Center(child: Text("Error loading patient: $err")),
          data: (state) {
            final p = state.patient;
            if (p == null) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          key: const Key("back-button"),
                          onTap: () => context.pop(),
                          child: const Icon(Icons.chevron_left, color: AppColors.onSurface, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2l),
                    const Icon(Icons.person_off_outlined, size: 48, color: AppColors.muted),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.error ?? "Patient profile not found.",
                      style: const TextStyle(color: AppColors.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            final upcoming = state.appointments.cast<Appointment?>().firstWhere(
                  (a) => a?.status == "scheduled" || a?.status == "delayed" || a?.status == "booked",
                  orElse: () => null,
                );

            final patientName = p.name.isNotEmpty ? p.name : "Patient";
            final initialLetter = patientName.isNotEmpty ? patientName[0].toUpperCase() : "?";

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.x3l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          key: const Key("back-button"),
                          onTap: () => context.pop(),
                          child: const Icon(Icons.chevron_left, color: AppColors.onSurface, size: 22),
                        ),
                        Text(
                          patientName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),
                  ),

                  // Patient Card
                  Container(
                    margin: const EdgeInsets.all(AppSpacing.xl),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: AppColors.brandTertiary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  initialLetter,
                                  style: const TextStyle(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${p.phone} · ${p.age ?? '—'} · ${p.gender ?? '—'}",
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (p.allergies != null && (p.allergies?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            "⚠️ Allergies: ${p.allergies ?? ''}",
                            style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Consultation Form
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.brand.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Add consultation notes",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                upcoming != null ? "Active Visit" : "Prescription & Notes",
                                style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upcoming != null
                              ? "Appointment: ${DateFormat('MMM d, h:mm a').format(upcoming.scheduledAt)}"
                              : "Create prescription & medical record note",
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            "Follow-up Instructions & Clinical Notes",
                            style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key("followup-input"),
                            controller: _followUpController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Enter follow-up instructions, advice, dietary rules, or clinical notes…",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),
                          // Prescription Photo Section
                          const Text(
                            "Prescription Photo (Physical Slip / Handwritten)",
                            style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),

                          if (isPickingImage) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                                  ),
                                  SizedBox(width: 10),
                                  Text("Opening camera / image selector...", style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                          ] else if (_prescriptionImageBytes != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showPrescriptionDialog(context, _prescriptionBase64!, title: "Captured Prescription Photo"),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: Image.memory(
                                        _prescriptionImageBytes!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              "Prescription Photo Attached",
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF10B981)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => _showPrescriptionDialog(context, _prescriptionBase64!, title: "Captured Prescription Photo"),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.brand.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.zoom_in, color: AppColors.brand, size: 14),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Tap to preview full size",
                                                  style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: "Remove photo",
                                    onPressed: () {
                                      setState(() {
                                        _prescriptionImageBytes = null;
                                        _prescriptionBase64 = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isPickingImage ? null : () => _pickPrescription(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                    label: const Text(
                                      "Click Picture",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brand,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isPickingImage ? null : () => _pickPrescription(ImageSource.gallery),
                                    icon: const Icon(Icons.upload_file, size: 18, color: AppColors.onSurface),
                                    label: const Text(
                                      "Upload Photo",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: const BorderSide(color: AppColors.border, width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                      backgroundColor: AppColors.surface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: AppSpacing.md),
                          // Report Photo (Lab / Clinical Photo) Section
                          const Text(
                            "Report Photo (Lab / Clinical Photo)",
                            style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),

                          if (isPickingReportImage) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                                  ),
                                  SizedBox(width: 10),
                                  Text("Opening camera / image selector...", style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                          ] else if (_reportImageBytes != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.6), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showPrescriptionDialog(context, _reportBase64!, title: "Captured Lab / Clinical Report"),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: Image.memory(
                                        _reportImageBytes!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Color(0xFF0284C7), size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              "Report Photo Attached",
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0284C7)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => _showPrescriptionDialog(context, _reportBase64!, title: "Captured Lab / Clinical Report"),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.zoom_in, color: Color(0xFF0284C7), size: 14),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Tap to preview full size",
                                                  style: TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: "Remove report photo",
                                    onPressed: () {
                                      setState(() {
                                        _reportImageBytes = null;
                                        _reportBase64 = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isPickingReportImage ? null : () => _pickReport(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                    label: const Text(
                                      "Click Picture",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isPickingReportImage ? null : () => _pickReport(ImageSource.gallery),
                                    icon: const Icon(Icons.upload_file, size: 18, color: AppColors.onSurface),
                                    label: const Text(
                                      "Upload Photo",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: const BorderSide(color: AppColors.border, width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                      backgroundColor: AppColors.surface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Next Follow-up Date",
                                style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                              ),
                              if (_nextFollowUpDate != null)
                                InkWell(
                                  onTap: () => setState(() => _nextFollowUpDate = null),
                                  child: const Text(
                                    "Clear Date",
                                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _nextFollowUpDate ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _nextFollowUpDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                              decoration: BoxDecoration(
                                color: _nextFollowUpDate != null ? AppColors.brand.withOpacity(0.06) : AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _nextFollowUpDate != null ? AppColors.brand : AppColors.border,
                                  width: _nextFollowUpDate != null ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: _nextFollowUpDate != null ? AppColors.brand : AppColors.muted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _nextFollowUpDate != null
                                          ? DateFormat('EEEE, d MMMM yyyy').format(_nextFollowUpDate!)
                                          : "Select follow-up date (tap to choose)",
                                      style: TextStyle(
                                        color: _nextFollowUpDate != null ? AppColors.onSurface : AppColors.muted,
                                        fontWeight: _nextFollowUpDate != null ? FontWeight.w700 : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: _nextFollowUpDate != null ? AppColors.brand : AppColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickDateChip("+3 Days", 3),
                                const SizedBox(width: 6),
                                _buildQuickDateChip("+1 Week", 7),
                                const SizedBox(width: 6),
                                _buildQuickDateChip("+2 Weeks", 14),
                                const SizedBox(width: 6),
                                _buildQuickDateChip("+1 Month", 30),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              key: const Key("save-consultation"),
                              onPressed: isSaving ? null : () => _submitConsultation(upcoming?.id, patientName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brand,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              ),
                              child: isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("Save & mark completed", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Visit History
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Visit history (${state.appointments.length})",
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (state.appointments.isEmpty)
                          const Text("No visits yet.", style: TextStyle(color: AppColors.muted))
                        else
                          ...state.appointments.map((a) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat.yMMMd().format(a.scheduledAt), style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text(DateFormat.jm().format(a.scheduledAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(child: Text(a.reason ?? "—")),
                                    Text(
                                      a.status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: _statusColor(a.status),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),

                  // Prescriptions
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prescriptions (${state.consultations.length})",
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (state.consultations.isEmpty)
                          const Text("No prescriptions yet.", style: TextStyle(color: AppColors.muted))
                        else
                          ...state.consultations.map((c) {
                            final followUp = c.followUpInstructions;
                            final followUpDate = c.followUpDate;
                            final photoUrl = c.prescriptionImageUrl;
                            final reportUrl = c.reportImageUrl;
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat.yMMMd().format(c.createdAt), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                      Row(
                                        children: [
                                          if (photoUrl != null && photoUrl.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.brand.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.image, color: AppColors.brand, size: 12),
                                                  SizedBox(width: 3),
                                                  Text("Prescription", style: TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          if (reportUrl != null && reportUrl.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0284C7).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.description, color: Color(0xFF0284C7), size: 12),
                                                  SizedBox(width: 3),
                                                  Text("Lab Report", style: TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (photoUrl != null && photoUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _showPrescriptionDialog(context, photoUrl, title: "Prescription Slip"),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                          border: Border.all(color: AppColors.brand.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.document_scanner, color: AppColors.brand, size: 20),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                "View Original Prescription Slip Photo",
                                                style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                            ),
                                            const Icon(Icons.zoom_in, color: AppColors.brand, size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (reportUrl != null && reportUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _showPrescriptionDialog(context, reportUrl, title: "Lab / Clinical Report"),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                          border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.biotech, color: Color(0xFF0284C7), size: 20),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                "View Lab / Clinical Report Photo",
                                                style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                            ),
                                            const Icon(Icons.zoom_in, color: Color(0xFF0284C7), size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (followUpDate != null && followUpDate.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.25)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.event, color: Color(0xFF0F766E), size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Next Follow-up Date: $followUpDate",
                                            style: const TextStyle(
                                              color: Color(0xFF0F766E),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (followUp != null && followUp.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "Follow-up Instructions: $followUp",
                                      style: const TextStyle(color: AppColors.brand, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // Feedback
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Feedback (${state.feedbacks.length})",
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (state.feedbacks.isEmpty)
                          const Text("No feedback received.", style: TextStyle(color: AppColors.muted))
                        else
                          ...state.feedbacks.map((f) {
                            final sideEffects = f.sideEffects;
                            final notes = f.notes;
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat.yMMMd().format(f.createdAt), style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text("Severity ${f.severity}/10", style: const TextStyle(color: AppColors.muted)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${f.feelingBetter ? '✅ Feeling better' : ''}${f.medicationHelped ? ' · 💊 Medication helped' : ''}${f.symptomsUnchanged ? ' · ⚠️ Unchanged' : ''}${f.symptomsWorsened ? ' · 🆘 Worsened' : ''}",
                                  ),
                                  if (sideEffects != null && sideEffects.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text("Side effects: $sideEffects", style: const TextStyle(color: Color(0xFF92400E))),
                                  ],
                                  if (notes != null && notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(notes, style: const TextStyle(color: AppColors.muted)),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
