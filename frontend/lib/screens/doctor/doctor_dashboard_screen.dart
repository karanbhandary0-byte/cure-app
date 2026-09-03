import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/status_meta.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/user.dart';
import '../../models/appointment.dart';
import '../../models/feedback.dart';
import '../../providers/schedule_provider.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(doctorDashboardProvider.notifier).load();
    });
  }

  void _showStatusModal(Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StatusModal(doctor: doctor),
    );
  }

  void _showLocationModal(Doctor doctor) {
    final clinicNameController = TextEditingController(text: doctor.clinicName);
    final clinicAddressController = TextEditingController(text: doctor.clinicAddress ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
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
                    "Edit Clinic Location",
                    style: TextStyle(
                      fontSize: 20,
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
              const Text("Clinic Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 4),
              TextField(
                controller: clinicNameController,
                decoration: InputDecoration(
                  hintText: "e.g. Health First Clinic",
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text("Clinic Address / Area / City", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 4),
              TextField(
                controller: clinicAddressController,
                decoration: InputDecoration(
                  hintText: "e.g. Bandra West, Mumbai or Connaught Place, Delhi",
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
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  onPressed: () async {
                    final newName = clinicNameController.text.trim();
                    final newAddr = clinicAddressController.text.trim();
                    Navigator.pop(ctx);
                    await ref.read(doctorDashboardProvider.notifier).updateLocation(newName, newAddr);
                  },
                  child: const Text("Save Location", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSlotsModal(Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SlotsModal(doctor: doctor),
    );
  }

  void _showAddSlotModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _DashboardManageSlotsSheet(),
    );
  }

  Widget _buildDashboardTodayCard(CustomSlotSchedule plan, String todayFormatted) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              Text(todayFormatted, style: const TextStyle(fontSize: 13, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text("From: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              Text(DateFormat('h:mm a').format(DateTime(2026, 1, 1, plan.fromTime.hour, plan.fromTime.minute)), style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text("To: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              Text(DateFormat('h:mm a').format(DateTime(2026, 1, 1, plan.toTime.hour, plan.toTime.minute)), style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text("Consultation Duration: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              Text("${plan.durationMinutes} minutes", style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text("Total Slots: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              Text("${plan.totalSlots}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostponeModal(int upcomingCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostponeModal(upcomingCount: upcomingCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorDashboardProvider);

    if (state.isLoading || state.doctor == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      );
    }

    final doctor = state.doctor!;
    final meta = StatusMeta.get(doctor.status);
    final delayed = state.appointments.where((a) => a.status == "delayed").length;
    final upcoming = state.appointments
        .where((a) => a.status == "scheduled" || a.status == "delayed" || a.status == "booked")
        .length;
    final completed = state.appointments.where((a) => a.status == "completed").length;
    final urgentFb = state.feedbacks
        .where((f) =>
            f.recommendation == "urgent_consultation" ||
            f.recommendation == "notify_doctor")
        .length;

    return Scaffold(
      key: const Key("doctor-dashboard"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(doctorDashboardProvider.notifier).load(),
          color: AppColors.brand,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.x3l),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hello,",
                            style: TextStyle(color: AppColors.muted, fontSize: 14),
                          ),
                          Text(
                            doctor.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${doctor.clinicName} · ${doctor.specialty}",
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            key: const Key("edit-location-chip"),
                            onTap: () => _showLocationModal(doctor),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandTertiary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 13, color: AppColors.brand),
                                  const SizedBox(width: 4),
                                  Text(
                                    (doctor.clinicAddress != null && doctor.clinicAddress!.isNotEmpty)
                                        ? doctor.clinicAddress!
                                        : "Set Clinic Location",
                                    style: const TextStyle(
                                      color: AppColors.brand,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, size: 11, color: AppColors.brand),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        key: const Key("logout-button"),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/');
                        },
                        icon: const Icon(Icons.logout, color: AppColors.onSurface, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (doctor.verificationStatus == "pending")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 24),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Account Under Review",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Your profile is pending Admin verification. Patient booking will be enabled once approved.",
                                  style: TextStyle(color: Color(0xFFB45309), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Status Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: InkWell(
                    key: const Key("status-card-button"),
                    onTap: () => _showStatusSelector(context, doctor),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: meta.bg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "YOUR STATUS",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: meta.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(meta.icon, size: 20, color: meta.color),
                                    const SizedBox(width: 8),
                                    Text(
                                      meta.label,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: meta.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Tap to update — patients notified instantly",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: meta.color.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 22, color: meta.color),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // DASHBOARD SLOTS SECTION (Shows today's schedules only)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SLOTS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Builder(
                        builder: (ctx) {
                          final schedules = ref.watch(scheduleProvider);
                          final todaySchedules = schedules.where((s) => s.isToday).toList();
                          final todayFormatted = DateFormat('MMMM d, yyyy').format(DateTime.now());

                          if (todaySchedules.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Text(
                                "No slots created for today. Use 'Manage Slots' below to create slots.",
                                style: TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                            );
                          }

                          return Column(
                            children: todaySchedules.map((plan) => _buildDashboardTodayCard(plan, todayFormatted)).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      _StatTile(
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.brand,
                        label: "Today",
                        value: state.appointments.length.toString(),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatTile(
                        icon: Icons.hourglass_empty,
                        color: AppColors.warning,
                        label: "Delayed",
                        value: delayed.toString(),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatTile(
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        label: "Done",
                        value: completed.toString(),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          key: const Key("alerts-tile"),
                          onTap: () => context.push('/doctor/feedback'),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: _StatTileContent(
                            icon: Icons.error_outline,
                            color: AppColors.error,
                            label: "Alerts",
                            value: urgentFb.toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Pair
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          key: const Key("add-slot-card"),
                          onTap: _showAddSlotModal,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Manage Slots",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Builder(
                                  builder: (ctx) {
                                    final count = ref.watch(scheduleProvider).length;
                                    return Text(
                                      count > 0 ? "$count schedule${count == 1 ? '' : 's'} configured · tap to manage" : "Select date, times & duration",
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                        height: 1.2,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: InkWell(
                          key: const Key("postpone-card"),
                          onTap: () => _showPostponeModal(upcoming),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.warningBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.access_time_filled,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Postpone schedule",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Push slots if you're unreachable",
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section Header: Appointments
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: AppSpacing.xl,
                    bottom: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's appointments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        "$upcoming upcoming",
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                if (state.appointments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        "No appointments today.",
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ...state.appointments.map((a) => _AppointmentCard(appt: a)),

                // Patient Feedback Section
                if (state.feedbacks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.xl,
                      right: AppSpacing.xl,
                      top: AppSpacing.xl,
                      bottom: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Patient feedback",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        InkWell(
                          key: const Key("view-all-feedback"),
                          onTap: () => context.push('/doctor/feedback'),
                          child: Text(
                            "View all (${state.feedbacks.length})",
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...state.feedbacks.take(5).map((f) => _FeedbackAlertCard(fb: f)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _StatTileContent(
        icon: icon,
        color: color,
        label: label,
        value: value,
      ),
    );
  }
}

class _StatTileContent extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatTileContent({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appt;

  const _AppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.jm().format(appt.scheduledAt);
    final dateStr = DateFormat('MMM d').format(appt.scheduledAt);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: InkWell(
        key: Key("appt-card-${appt.id}"),
        onTap: () {
          final pid = appt.patientId.isNotEmpty ? appt.patientId : (appt.patient?.id ?? '');
          if (pid.isNotEmpty) {
            context.push('/doctor/patient/$pid');
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.only(right: AppSpacing.md),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
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
                      appt.patient?.name ?? (appt.patientName ?? "Patient"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appt.reason ?? "No reason given",
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: appt.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.brandTertiary;
    Color color = AppColors.brand;

    if (status == "completed") {
      bg = AppColors.successBg;
      color = const Color(0xFF065F46);
    } else if (status == "delayed") {
      bg = AppColors.warningBg;
      color = const Color(0xFF92400E);
    } else if (status == "cancelled") {
      bg = AppColors.errorBg;
      color = const Color(0xFF991B1B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _FeedbackAlertCard extends StatelessWidget {
  final PatientFeedbackItem fb;

  const _FeedbackAlertCard({required this.fb});

  @override
  Widget build(BuildContext context) {
    final isUrgent = fb.recommendation == "urgent_consultation" ||
        fb.recommendation == "notify_doctor";
    final sevColor = fb.severity <= 3
        ? AppColors.success
        : (fb.severity <= 6 ? AppColors.warning : AppColors.error);

    String recText = "Treatment going well";
    if (fb.recommendation == "urgent_consultation") recText = "Urgent — symptoms worsened";
    if (fb.recommendation == "notify_doctor") recText = "Side effects flagged";
    if (fb.recommendation == "book_followup") recText = "Recommend follow-up";

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: InkWell(
        key: Key("fb-alert-${fb.id}"),
        onTap: () => context.push('/doctor/feedback'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isUrgent ? AppColors.errorBg : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(
                isUrgent ? Icons.warning : Icons.chat_bubble_outline,
                size: 20,
                color: isUrgent ? AppColors.error : AppColors.brand,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fb.patientName ?? "Patient",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      "$recText · Severity ${fb.severity}/10",
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
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
                  "${fb.severity}",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: sevColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom Sheet Modals
class _StatusModal extends ConsumerStatefulWidget {
  final Doctor doctor;

  const _StatusModal({required this.doctor});

  @override
  ConsumerState<_StatusModal> createState() => _StatusModalState();
}

class _StatusModalState extends ConsumerState<_StatusModal> {
  late String selected;
  late TextEditingController delayController;

  @override
  void initState() {
    super.initState();
    selected = widget.doctor.status ?? "available";
    delayController = TextEditingController(
      text: (widget.doctor.delayMinutes ?? 15).toString(),
    );
  }

  @override
  void dispose() {
    delayController.dispose();
    super.dispose();
  }

  void _apply() async {
    final delay = int.tryParse(delayController.text.trim()) ?? 0;
    await ref.read(doctorDashboardProvider.notifier).updateStatus(selected, delay);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final options = StatusMeta.map.entries.toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              "Update status",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
            const Text(
              "Patients will be notified of changes.",
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),

            ...options.map((e) {
              final key = e.key;
              final m = e.value;
              final isSelected = selected == key;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  key: Key("status-option-$key"),
                  onTap: () => setState(() => selected = key),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandTertiary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? AppColors.brand : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: m.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(m.icon, size: 18, color: m.color),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            m.label,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.brand, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (selected == "running_late" || selected == "in_surgery" || selected == "emergency") ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                "Delay in minutes",
                style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const Key("delay-input"),
                controller: delayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "15",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                key: const Key("apply-status"),
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: const Text("Apply update", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardManageSlotsSheet extends ConsumerStatefulWidget {
  const _DashboardManageSlotsSheet();

  @override
  ConsumerState<_DashboardManageSlotsSheet> createState() => _DashboardManageSlotsSheetState();
}

class _DashboardManageSlotsSheetState extends ConsumerState<_DashboardManageSlotsSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _fromTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _durationController = TextEditingController(text: "4");
  String? _editingId;

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  int get _calculatedTotalSlots {
    int startMinutes = _fromTime.hour * 60 + _fromTime.minute;
    int endMinutes = _toTime.hour * 60 + _toTime.minute;
    int totalWorkingMinutes = endMinutes - startMinutes;
    int duration = int.tryParse(_durationController.text.trim()) ?? 0;

    if (totalWorkingMinutes <= 0 || duration <= 0) return 0;
    return totalWorkingMinutes ~/ duration;
  }

  String _formatTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final current = isFrom ? _fromTime : _toTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: isFrom ? "SELECT FROM TIME (AM/PM)" : "SELECT TO TIME (AM/PM)",
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromTime = picked;
        else _toTime = picked;
      });
    }
  }

  void _saveOrUpdate() {
    final slots = _calculatedTotalSlots;
    if (slots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please make sure To Time is later than From Time and duration is greater than 0."),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 4;

    if (_editingId != null) {
      final updated = CustomSlotSchedule(
        id: _editingId!,
        date: _selectedDate,
        fromTime: _fromTime,
        toTime: _toTime,
        durationMinutes: duration,
        totalSlots: slots,
      );
      ref.read(scheduleProvider.notifier).updateSchedule(updated);
      setState(() => _editingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✓ Schedule updated successfully!"), backgroundColor: Color(0xFF15803D)),
      );
    } else {
      final newSched = CustomSlotSchedule(
        id: "sched_${DateTime.now().millisecondsSinceEpoch}",
        date: _selectedDate,
        fromTime: _fromTime,
        toTime: _toTime,
        durationMinutes: duration,
        totalSlots: slots,
      );
      ref.read(scheduleProvider.notifier).addSchedule(newSched);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newSched.isToday
              ? "✓ Schedule created for TODAY and active in Slots!"
              : "✓ Schedule created for ${newSched.formattedDate}!"),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }

  void _startEdit(CustomSlotSchedule s) {
    setState(() {
      _editingId = s.id;
      _selectedDate = s.date;
      _fromTime = s.fromTime;
      _toTime = s.toTime;
      _durationController.text = s.durationMinutes.toString();
    });
  }

  void _confirmDelete(CustomSlotSchedule schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete this slot schedule?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete the schedule for ${schedule.formattedDate} (${_formatTime(schedule.fromTime)} – ${_formatTime(schedule.toTime)})?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(scheduleProvider.notifier).deleteSchedule(schedule.id);
              if (_editingId == schedule.id) {
                setState(() => _editingId = null);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✓ Schedule deleted."), backgroundColor: Color(0xFFDC2626)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(scheduleProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editingId != null ? "Edit Schedule" : "Manage Slots",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                  ),
                  if (_editingId != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _editingId = null;
                          _selectedDate = DateTime.now();
                          _fromTime = const TimeOfDay(hour: 6, minute: 0);
                          _toTime = const TimeOfDay(hour: 8, minute: 0);
                          _durationController.text = "4";
                        });
                      },
                      child: const Text("Cancel Edit", style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Date Picker Direct
              const Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMMM d, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E))),
                      const Icon(Icons.calendar_month, color: Color(0xFF0F766E), size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // From Time
              const Text("From Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _pickTime(true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(_fromTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Icon(Icons.access_time, size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // To Time
              const Text("To Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _pickTime(false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(_toTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Icon(Icons.access_time, size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Duration
              const Text("Consultation Duration (minutes)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
              const SizedBox(height: 6),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "e.g. 4",
                  suffixText: "minutes",
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Slots", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface)),
                  Text("$_calculatedTotalSlots", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F766E))),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  key: const Key("create-slots-button-dash"),
                  onPressed: _saveOrUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(_editingId != null ? "Update Schedule" : "Create Slots", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Existing Schedules
              const Text("Existing Custom Schedules", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.sm),
              if (schedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("No schedules created yet.", style: TextStyle(color: AppColors.muted)),
                )
              else
                ...schedules.map((schedule) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: schedule.isToday ? const Color(0xFF0F766E) : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(schedule.formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (schedule.isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                                child: const Text("Active Today", style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("${_formatTime(schedule.fromTime)} – ${_formatTime(schedule.toTime)} · ${schedule.durationMinutes} min/slot · ${schedule.totalSlots} Slots", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _startEdit(schedule),
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0F766E)),
                              label: const Text("Edit", style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 6),
                            TextButton.icon(
                              onPressed: () => _confirmDelete(schedule),
                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                              label: const Text("Delete", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostponeModal extends ConsumerStatefulWidget {
  final int upcomingCount;

  const _PostponeModal({required this.upcomingCount});

  @override
  ConsumerState<_PostponeModal> createState() => _PostponeModalState();
}

class _PostponeModalState extends ConsumerState<_PostponeModal> {
  int shift = 60;
  String scope = "today";

  void _apply() async {
    await ref.read(doctorDashboardProvider.notifier).postpone(shift, scope);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final shifts = [15, 30, 60, 90, 120, 180];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: AppSpacing.lg),
            const Text("Postpone schedule", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const Text("Push all of your appointments + custom slots forward. Patients will be notified.", style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFF92400E), size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "${widget.upcomingCount} active appointment${widget.upcomingCount == 1 ? '' : 's'} will be affected.",
                      style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const Text("Shift forward by", style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: shifts.map((s) {
                final active = shift == s;
                final text = s < 60 ? "${s}m" : "${s ~/ 60}h${s % 60 != 0 ? ' ${s % 60}m' : ''}";
                return ChoiceChip(
                  key: Key("postpone-shift-$s"),
                  label: Text(text),
                  selected: active,
                  onSelected: (_) => setState(() => shift = s),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),
            const Text("Apply to", style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                ChoiceChip(
                  key: const Key("postpone-scope-today"),
                  label: const Text("Today only"),
                  selected: scope == "today",
                  onSelected: (_) => setState(() => scope = "today"),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(color: scope == "today" ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  key: const Key("postpone-scope-all"),
                  label: const Text("All upcoming"),
                  selected: scope == "all_upcoming",
                  onSelected: (_) => setState(() => scope = "all_upcoming"),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(color: scope == "all_upcoming" ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                key: const Key("confirm-postpone"),
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text("Postpone by ${shift < 60 ? '$shift min' : '${shift ~/ 60}h${shift % 60 != 0 ? " ${shift % 60}m" : ""}'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
