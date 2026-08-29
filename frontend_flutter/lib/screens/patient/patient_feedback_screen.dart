import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/user.dart';
import '../../models/appointment.dart';

class PatientFeedbackScreen extends ConsumerStatefulWidget {
  const PatientFeedbackScreen({super.key});

  @override
  ConsumerState<PatientFeedbackScreen> createState() => _PatientFeedbackScreenState();
}

class _PatientFeedbackScreenState extends ConsumerState<PatientFeedbackScreen> {
  List<Appointment> pending = [];
  bool isLoading = true;

  Appointment? selectedAppt;
  Map<String, bool> answers = {};
  double severity = 5.0;
  final _sideEffectsController = TextEditingController();
  final _notesController = TextEditingController();
  bool submitting = false;
  String? recResult;

  final questions = const [
    {"key": "feeling_better", "label": "Are you feeling better?"},
    {"key": "medication_helped", "label": "Did the medication help?"},
    {"key": "symptoms_unchanged", "label": "Are symptoms unchanged?"},
    {"key": "symptoms_worsened", "label": "Have symptoms worsened?"},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sideEffectsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final homeState = ref.read(patientHomeProvider);
    if (homeState.pendingFeedbackAppts.isNotEmpty) {
      if (mounted) {
        setState(() {
          pending = homeState.pendingFeedbackAppts;
          isLoading = false;
        });
        return;
      }
    }

    final unsubmittedAppts = homeState.appointments
        .where((a) => (a.feedbackSubmitted != true) && a.status != 'cancelled')
        .toList();
    if (unsubmittedAppts.isNotEmpty) {
      if (mounted) {
        setState(() {
          pending = unsubmittedAppts;
          isLoading = false;
        });
        return;
      }
    }

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get("/patient/pending-feedback") as List;
      if (mounted) {
        setState(() {
          pending = res.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _submit() async {
    if (selectedAppt == null) return;
    setState(() => submitting = true);

    final appt = selectedAppt!;
    final feelingBetter = answers["feeling_better"] == true;
    final medHelped = answers["medication_helped"] == true;
    final unchanged = answers["symptoms_unchanged"] == true;
    final worsened = answers["symptoms_worsened"] == true;
    final sideEffects = _sideEffectsController.text.trim();
    final notes = _notesController.text.trim();
    final sevInt = severity.round();

    final currentPatient = ref.read(patientHomeProvider).patient ??
        (ref.read(authProvider).currentUser is Patient
            ? ref.read(authProvider).currentUser as Patient
            : null);
    final pid = appt.patientId.isNotEmpty ? appt.patientId : (currentPatient?.id ?? 'patient_demo');
    final apptPatName = appt.patientName;
    final pname = (apptPatName != null && apptPatName.isNotEmpty)
        ? apptPatName
        : (currentPatient?.name ?? 'Patient Demo');

    // Determine recommendation
    String localRec = "continue";
    if (worsened || sevInt >= 8) {
      localRec = "urgent_consultation";
    } else if (sideEffects.isNotEmpty) {
      localRec = "notify_doctor";
    } else if (unchanged || sevInt >= 5) {
      localRec = "book_followup";
    }

    try {
      final fb = ref.read(firebaseServiceProvider);
      final tags = <String>[];
      if (feelingBetter) tags.add("feeling_better");
      if (medHelped) tags.add("medication_helped");
      if (unchanged) tags.add("symptoms_unchanged");
      if (worsened) tags.add("symptoms_worsened");

      await fb.submitFeedback(
        appointmentId: appt.id,
        doctorId: appt.doctorId,
        patientId: pid,
        patientName: pname,
        rating: 10 - sevInt,
        tags: tags,
        comments: "$sideEffects ${notes.isNotEmpty ? '· Note: $notes' : ''}".trim(),
        feelingBetter: feelingBetter,
        medicationHelped: medHelped,
        symptomsUnchanged: unchanged,
        symptomsWorsened: worsened,
        sideEffects: sideEffects,
        notes: notes,
        severity: sevInt,
        recommendation: localRec,
      );

      ref.read(patientHomeProvider.notifier).load();
      if (mounted) {
        setState(() {
          recResult = localRec;
          selectedAppt = null;
          answers.clear();
          severity = 5.0;
          _sideEffectsController.clear();
          _notesController.clear();
          submitting = false;
        });
        _load();
      }
      return;
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.post("/patient/feedback", body: {
        "appointment_id": appt.id,
        "feeling_better": feelingBetter,
        "medication_helped": medHelped,
        "symptoms_unchanged": unchanged,
        "symptoms_worsened": worsened,
        "side_effects": sideEffects,
        "severity": sevInt,
        "notes": notes,
      }) as Map<String, dynamic>;

      ref.read(patientHomeProvider.notifier).load();
      if (mounted) {
        setState(() {
          recResult = res['recommendation']?.toString() ?? localRec;
          selectedAppt = null;
          answers.clear();
          severity = 5.0;
          _sideEffectsController.clear();
          _notesController.clear();
          submitting = false;
        });
        _load();
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    // State 3: Thank you / Result view
    if (recResult != null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            key: const Key("feedback-result"),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.md),
                const Text("Thank you!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                const Text("Your doctor has been updated.", style: TextStyle(color: AppColors.muted, fontSize: 15)),
                const SizedBox(height: AppSpacing.lg),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.brandTertiary, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("OUR RECOMMENDATION", style: TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        recResult == "urgent_consultation"
                            ? "🚨 Please book an urgent consultation."
                            : (recResult == "notify_doctor"
                                ? "⚠️ We've notified your doctor about the side effects."
                                : (recResult == "book_followup"
                                    ? "📅 We recommend booking a follow-up appointment."
                                    : "✅ Continue your medication as prescribed.")),
                        style: const TextStyle(color: AppColors.brandSecondary, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    key: const Key("back-home"),
                    onPressed: () {
                      context.go('/patient/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text("Back to home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // State 1: List pending feedback items
    if (selectedAppt == null) {
      return Scaffold(
        key: const Key("patient-feedback-screen"),
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("How are you feeling?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -0.5)),
                    SizedBox(height: 4),
                    Text("Share next-day feedback to improve your care.", style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  ],
                ),
              ),

              Expanded(
                child: pending.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_outline, size: 48, color: AppColors.muted),
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                              child: Text(
                                "No pending feedback. We'll ask 24 hours after your next visit.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        itemCount: pending.length,
                        itemBuilder: (context, index) {
                          final p = pending[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: InkWell(
                              key: Key("feedback-item-${p.id}"),
                              onTap: () => setState(() => selectedAppt = p),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.doctor?.name ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Text(p.reason ?? "Consultation", style: const TextStyle(color: AppColors.brand, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(DateFormat.yMMMd().format(p.scheduledAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                                  ],
                                ),
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

    // State 2: Selected feedback item form
    final sevColor = severity <= 3.0
        ? AppColors.success
        : (severity <= 6.0 ? AppColors.warning : AppColors.error);

    return Scaffold(
      key: const Key("patient-feedback-form"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => selectedAppt = null),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, color: AppColors.onSurface, size: 20),
                    Text("Back", style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text("Feedback for ${selectedAppt?.doctor?.name ?? 'Doctor'}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text(selectedAppt?.reason ?? "", style: const TextStyle(color: AppColors.muted, fontSize: 14)),

              const SizedBox(height: AppSpacing.lg),

              // Questions Checkboxes
              ...questions.map((q) {
                final key = q['key'] ?? '';
                final label = q['label'] ?? key;
                final active = answers[key] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    key: Key("q-$key"),
                    onTap: () => setState(() => answers[key] = !active),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: active ? AppColors.brandTertiary : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: active ? AppColors.brand : AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            active ? Icons.check_box : Icons.check_box_outline_blank,
                            color: active ? AppColors.brand : AppColors.muted,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: active ? AppColors.brand : AppColors.onSurface,
                                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.lg),

              // Severity Box
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SYMPTOM SEVERITY", style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text("${severity.round()}/10", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: sevColor)),
                    Slider(
                      key: const Key("severity-slider"),
                      value: severity,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: sevColor,
                      inactiveColor: AppColors.border,
                      onChanged: (val) => setState(() => severity = val),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Mild", style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        Text("Severe", style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              const Text("SIDE EFFECTS (IF ANY)", style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const Key("side-effects-input"),
                controller: _sideEffectsController,
                decoration: InputDecoration(
                  hintText: "e.g. Nausea, dizziness",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              const Text("ADDITIONAL NOTES", style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const Key("notes-input"),
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Anything else to share?",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key("submit-feedback"),
                  onPressed: submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
