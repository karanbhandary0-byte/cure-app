import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  bool isSaving = false;

  @override
  void dispose() {
    _diagController.dispose();
    _presController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  void _submitConsultation(String appointmentId) async {
    if (_diagController.text.trim().isEmpty) return;
    setState(() => isSaving = true);
    final diag = _diagController.text.trim();
    final pres = _presController.text.trim();
    final followUp = _followUpController.text.trim();

    try {
      final fb = ref.read(firebaseServiceProvider);
      await fb.createConsultation(
        appointmentId: appointmentId,
        doctorId: ref.read(authProvider).currentUser?.id ?? '',
        patientId: widget.patientId,
        diagnosis: diag,
        prescription: pres,
        followUpInstructions: followUp,
      );

      _diagController.clear();
      _presController.clear();
      _followUpController.clear();

      ref.invalidate(patientDetailProvider(widget.patientId));
      ref.read(doctorDashboardProvider.notifier).load();
      return;
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      await api.post("/doctor/consultations", body: {
        "appointment_id": appointmentId,
        "diagnosis": diag,
        "prescription": pres,
        "follow_up_instructions": followUp,
      });

      _diagController.clear();
      _presController.clear();
      _followUpController.clear();

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
                  if (upcoming != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.brand),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Add consultation notes",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Appointment: ${DateFormat('MMM d, h:mm a').format(upcoming.scheduledAt)}",
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          const Text("Diagnosis", style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key("diagnosis-input"),
                            controller: _diagController,
                            decoration: InputDecoration(
                              hintText: "e.g. Viral fever",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),
                          const Text("Prescription", style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
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
                          const Text("Follow-up instructions", style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            key: const Key("followup-input"),
                            controller: _followUpController,
                            decoration: InputDecoration(
                              hintText: "Rest, drink fluids…",
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
                              onPressed: isSaving ? null : () => _submitConsultation(upcoming.id),
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
                  ],

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
                                  Text(DateFormat.yMMMd().format(c.createdAt), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text("Diagnosis: ${c.diagnosis}", style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(c.prescription, style: const TextStyle(color: AppColors.muted)),
                                  if (followUp != null && followUp.isNotEmpty) ...[
                                    const SizedBox(height: 4),
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
