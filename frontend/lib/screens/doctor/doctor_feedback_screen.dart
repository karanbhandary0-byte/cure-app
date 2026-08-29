import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/feedback.dart';

class DoctorFeedbackScreen extends ConsumerStatefulWidget {
  const DoctorFeedbackScreen({super.key});

  @override
  ConsumerState<DoctorFeedbackScreen> createState() => _DoctorFeedbackScreenState();
}

class _DoctorFeedbackScreenState extends ConsumerState<DoctorFeedbackScreen> {
  String selectedFilter = "all";
  bool isLoading = true;
  List<PatientFeedbackItem> feedbacks = [];

  final filters = const [
    {"key": "all", "label": "All"},
    {"key": "urgent", "label": "Urgent"},
    {"key": "side_effects", "label": "Side effects"},
    {"key": "followup", "label": "Needs follow-up"},
    {"key": "improved", "label": "Improved"},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final doc = ref.read(authProvider).currentUser;
      final fb = ref.read(firebaseServiceProvider);
      final list = await fb.streamDoctorFeedbacks(doc?.id ?? '').first;
      if (mounted && list.isNotEmpty) {
        setState(() {
          feedbacks = list;
          isLoading = false;
        });
        return;
      }

      final api = ref.read(apiServiceProvider);
      final res = await api.get("/doctor/feedbacks") as List;
      if (mounted) {
        setState(() {
          feedbacks = res.map((e) => PatientFeedbackItem.fromJson(e as Map<String, dynamic>)).toList();
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Map<String, int> _getCounts(List<PatientFeedbackItem> list) {
    return {
      "all": list.length,
      "urgent": list.where((f) => f.recommendation == "urgent_consultation" || f.symptomsWorsened || f.severity >= 8).length,
      "side_effects": list.where((f) => f.recommendation == "notify_doctor" || (f.sideEffects ?? "").trim().isNotEmpty).length,
      "followup": list.where((f) => f.recommendation == "book_followup" || f.symptomsUnchanged).length,
      "improved": list.where((f) => f.recommendation == "continue_medication" || f.feelingBetter || f.medicationHelped).length,
    };
  }

  List<PatientFeedbackItem> _getFiltered(List<PatientFeedbackItem> list) {
    if (selectedFilter == "urgent") {
      return list.where((f) => f.recommendation == "urgent_consultation" || f.symptomsWorsened || f.severity >= 8).toList();
    }
    if (selectedFilter == "side_effects") {
      return list.where((f) => f.recommendation == "notify_doctor" || (f.sideEffects ?? "").trim().isNotEmpty).toList();
    }
    if (selectedFilter == "followup") {
      return list.where((f) => f.recommendation == "book_followup" || f.symptomsUnchanged).toList();
    }
    if (selectedFilter == "improved") {
      return list.where((f) => f.recommendation == "continue_medication" || f.feelingBetter || f.medicationHelped).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dashFeedbacks = ref.watch(doctorDashboardProvider).feedbacks;
    final allFeedbacks = dashFeedbacks.isNotEmpty ? dashFeedbacks : feedbacks;
    final filtered = _getFiltered(allFeedbacks);
    final counts = _getCounts(allFeedbacks);

    return Scaffold(
      key: const Key("doctor-feedback-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    key: const Key("back-button"),
                    onTap: () => context.pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, color: AppColors.onSurface, size: 22),
                        SizedBox(width: 4),
                        Text("Back", style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    "Patient feedback",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${feedbacks.length} response${feedbacks.length == 1 ? '' : 's'} received",
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Chips
            Container(
              height: 56,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final f = filters[index];
                  final key = f['key'] ?? '';
                  final label = f['label'] ?? key;
                  final active = key == selectedFilter;
                  final count = counts[key] ?? 0;

                  return Center(
                    child: ChoiceChip(
                      key: Key("fb-filter-$key"),
                      label: Text("$label · $count"),
                      selected: active,
                      onSelected: (_) => setState(() => selectedFilter = key),
                      selectedColor: AppColors.brand,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: active ? AppColors.brand : AppColors.border),
                      labelStyle: TextStyle(
                        color: active ? Colors.white : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Feedback list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
                  : filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sentiment_satisfied, size: 48, color: AppColors.muted),
                              SizedBox(height: 12),
                              Text("No feedback responses.", style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final sevColor = item.severity <= 3
                                ? AppColors.success
                                : (item.severity <= 6 ? AppColors.warning : AppColors.error);

                            String recLabel = "Continue medication";
                            Color recBg = AppColors.successBg;
                            Color recColor = const Color(0xFF065F46);
                            IconData recIcon = Icons.check_circle;

                            if (item.recommendation == "urgent_consultation") {
                              recLabel = "Urgent consultation";
                              recBg = AppColors.errorBg;
                              recColor = const Color(0xFF991B1B);
                              recIcon = Icons.warning;
                            } else if (item.recommendation == "notify_doctor") {
                              recLabel = "Side effects flagged";
                              recBg = AppColors.warningBg;
                              recColor = const Color(0xFF92400E);
                              recIcon = Icons.error_outline;
                            } else if (item.recommendation == "book_followup") {
                              recLabel = "Book follow-up";
                              recBg = AppColors.warningBg;
                              recColor = const Color(0xFF92400E);
                              recIcon = Icons.calendar_today;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: InkWell(
                                key: Key("fb-card-${item.id}"),
                                onTap: () => context.push('/doctor/patient/${item.patientId}'),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top info
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: AppColors.brandTertiary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                (item.patientName ?? "?")[0].toUpperCase(),
                                                style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.patientName ?? "Patient",
                                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15),
                                                ),
                                                Text(
                                                  DateFormat('MMM d, h:mm a').format(item.createdAt),
                                                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: sevColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "${item.severity}/10",
                                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: sevColor),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Tags Row
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          if (item.feelingBetter) const _Tag(label: "Feeling better", color: AppColors.success, bg: AppColors.successBg, icon: Icons.sentiment_very_satisfied),
                                          if (item.medicationHelped) const _Tag(label: "Medication helped", color: AppColors.success, bg: AppColors.successBg, icon: Icons.medical_services),
                                          if (item.symptomsUnchanged) const _Tag(label: "Unchanged", color: AppColors.warning, bg: AppColors.warningBg, icon: Icons.remove_circle_outline),
                                          if (item.symptomsWorsened) const _Tag(label: "Worsened", color: AppColors.error, bg: AppColors.errorBg, icon: Icons.warning_amber_rounded),
                                        ],
                                      ),

                                      if (item.sideEffects != null && (item.sideEffects?.isNotEmpty ?? false)) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("SIDE EFFECTS", style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                              const SizedBox(height: 2),
                                              Text(item.sideEffects ?? '', style: const TextStyle(color: AppColors.onSurface, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ],

                                      if (item.notes != null && (item.notes?.isNotEmpty ?? false)) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(AppSpacing.sm),
                                          decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("NOTES", style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                              const SizedBox(height: 2),
                                              Text(item.notes ?? '', style: const TextStyle(color: AppColors.onSurface, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: recBg, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(recIcon, size: 16, color: recColor),
                                            const SizedBox(width: 6),
                                            Text(recLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: recColor)),
                                          ],
                                        ),
                                      ),
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
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  const _Tag({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
