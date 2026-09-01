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

class DoctorPatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const DoctorPatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends ConsumerState<DoctorPatientDetailScreen> {
  final _diagController = TextEditingController();
  final _presController = TextEditingController();
  final _followUpController = TextEditingController();
  Uint8List? _prescriptionImageBytes;
  String? _prescriptionBase64;
  bool isPickingImage = false;
  bool isSaving = false;

  @override
  void dispose() {
    _diagController.dispose();
    _presController.dispose();
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

  void _submitConsultation(String? appointmentId) async {
    if (_diagController.text.trim().isEmpty && _prescriptionBase64 == null && _presController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a diagnosis, prescription or attach a prescription photo.")),
      );
      return;
    }
    setState(() => isSaving = true);
    final diag = _diagController.text.trim().isNotEmpty ? _diagController.text.trim() : "Prescription Consultation";
    final pres = _presController.text.trim();
    final followUp = _followUpController.text.trim();
    final photo = _prescriptionBase64;
    final apptId = (appointmentId != null && appointmentId.isNotEmpty)
        ? appointmentId
        : 'appt_${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final fb = ref.read(firebaseServiceProvider);
      await fb.createConsultation(
        appointmentId: apptId,
        doctorId: ref.read(authProvider).currentUser?.id ?? '',
        patientId: widget.patientId,
        diagnosis: diag,
        prescription: pres,
        prescriptionImageUrl: photo,
        followUpInstructions: followUp,
      );

      _diagController.clear();
      _presController.clear();
      _followUpController.clear();
      setState(() {
        _prescriptionImageBytes = null;
        _prescriptionBase64 = null;
      });

      ref.invalidate(patientDetailProvider(widget.patientId));
      ref.read(doctorDashboardProvider.notifier).load();
      return;
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      await api.post("/doctor/consultations", body: {
        "appointment_id": apptId,
        "diagnosis": diag,
        "prescription": pres,
        "prescription_image_url": photo,
        "follow_up_instructions": followUp,
      });

      _diagController.clear();
      _presController.clear();
      _followUpController.clear();
      setState(() {
        _prescriptionImageBytes = null;
        _prescriptionBase64 = null;
      });

      ref.invalidate(patientDetailProvider(widget.patientId));
      ref.read(doctorDashboardProvider.notifier).load();
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
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

                          const Text("Diagnosis", style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key("diagnosis-input"),
                            controller: _diagController,
                            decoration: InputDecoration(
                              hintText: "e.g. Viral fever, Hypertension",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),
                          const Text("Prescription (Text / Notes)", style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key("prescription-input"),
                            controller: _presController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "e.g. Paracetamol 500mg x 3 days\nVitamin C x 5 days",
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
                          const Text("Follow-up instructions", style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key("followup-input"),
                            controller: _followUpController,
                            decoration: InputDecoration(
                              hintText: "Rest, drink fluids, review after 5 days…",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              key: const Key("save-consultation"),
                              onPressed: isSaving ? null : () => _submitConsultation(upcoming?.id),
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
                            final photoUrl = c.prescriptionImageUrl;
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
                                      if (photoUrl != null && photoUrl.isNotEmpty)
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
                                              Text("Photo attached", style: TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Diagnosis: ${c.diagnosis}", style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (c.prescription.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(c.prescription, style: const TextStyle(color: AppColors.muted)),
                                  ],
                                  if (photoUrl != null && photoUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _showPrescriptionDialog(context, photoUrl, title: "Prescription for ${c.diagnosis}"),
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
                                  if (followUp != null && followUp.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "Follow-up: $followUp",
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
