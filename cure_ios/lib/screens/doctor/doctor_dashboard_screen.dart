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
      builder: (context) => const _AddSlotModal(),
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
                    key: const Key("status-card"),
                    onTap: () => _showStatusModal(doctor),
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

                // Slot Generator Quick Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: InkWell(
                    key: const Key("quick-slot-config-card"),
                    onTap: () => context.go('/doctor/appointments'),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: const [
                          BoxShadow(color: Color(0x140F766E), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Working Hours & 4-Min Slot Generator",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Configure Morning (6–8 AM) & Evening (5–8 PM) sessions",
                                  style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
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

                // Slot Settings Card
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: AppSpacing.lg,
                  ),
                  child: InkWell(
                    key: const Key("slot-settings-card"),
                    onTap: () => _showSlotsModal(doctor),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.brandTertiary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: AppColors.brand,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Slot settings",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${doctor.slotCount ?? 8} slots · every ${doctor.slotDurationMin ?? 30} min · from ${doctor.slotStartHour ?? 9}:00",
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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
                                  "Manage slots",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.customSlots.isNotEmpty
                                      ? "${state.customSlots.length} custom slot${state.customSlots.length == 1 ? '' : 's'} · tap to edit"
                                      : "Insert any time today or future",
                                  style: const TextStyle(
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

class _SlotsModal extends ConsumerStatefulWidget {
  final Doctor doctor;

  const _SlotsModal({required this.doctor});

  @override
  ConsumerState<_SlotsModal> createState() => _SlotsModalState();
}

class _SlotsModalState extends ConsumerState<_SlotsModal> {
  late String duration;
  late String count;
  late String start;

  @override
  void initState() {
    super.initState();
    duration = (widget.doctor.slotDurationMin ?? 30).toString();
    count = (widget.doctor.slotCount ?? 8).toString();
    start = (widget.doctor.slotStartHour ?? 9).toString();
  }

  void _save() async {
    await ref.read(doctorDashboardProvider.notifier).updateSettings(
          int.tryParse(duration) ?? 30,
          int.tryParse(count) ?? 8,
          int.tryParse(start) ?? 9,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final durations = ["5", "10", "15", "20", "30", "45", "60"];
    final counts = ["4", "6", "8", "10", "12", "16", "20"];
    final hours = ["7", "8", "9", "10", "11", "13", "14", "15", "16"];

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
                decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text("Slot settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
            const Text("Configure how patients book your time.", style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: AppSpacing.lg),

            const Text("Slot interval (minutes)", style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: durations.map((d) {
                final active = duration == d;
                return ChoiceChip(
                  key: Key("slot-duration-$d"),
                  label: Text("${d}m"),
                  selected: active,
                  onSelected: (_) => setState(() => duration = d),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),
            const Text("Number of slots", style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: counts.map((c) {
                final active = count == c;
                return ChoiceChip(
                  key: Key("slot-count-$c"),
                  label: Text(c),
                  selected: active,
                  onSelected: (_) => setState(() => count = c),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),
            const Text("Start hour", style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: hours.map((h) {
                final active = start == h;
                return ChoiceChip(
                  key: Key("slot-start-$h"),
                  label: Text("$h:00"),
                  selected: active,
                  onSelected: (_) => setState(() => start = h),
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.brandTertiary, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PREVIEW", style: TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text("$count slots · every $duration min · from $start:00", style: const TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                key: const Key("apply-slot-settings"),
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: const Text("Save settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSlotModal extends ConsumerStatefulWidget {
  const _AddSlotModal();

  @override
  ConsumerState<_AddSlotModal> createState() => _AddSlotModalState();
}

class _AddSlotModalState extends ConsumerState<_AddSlotModal> {
  int dayOffset = 0;
  String hour = "14";
  String minute = "45";

  void _add() async {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: dayOffset));
    final scheduledAt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      int.tryParse(hour) ?? 14,
      int.tryParse(minute) ?? 0,
    );

    await ref.read(doctorDashboardProvider.notifier).addSlot(scheduledAt);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorDashboardProvider);
    final hours = List.generate(14, (i) => "${7 + i}");
    final minutes = ["00", "15", "30", "45"];
    final days = [
      {"o": 0, "label": "Today"},
      {"o": 1, "label": "Tomorrow"},
      {"o": 2, "label": "+2 days"},
      {"o": 3, "label": "+3 days"},
      {"o": 7, "label": "+1 week"},
    ];

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
              const Text("Manage custom slots", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const Text("One-off slots added on top of your auto schedule.", style: TextStyle(color: AppColors.muted, fontSize: 13)),

              if (state.customSlots.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text("Upcoming custom slots (${state.customSlots.length})", style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ...state.customSlots.map((s) => Padding(
                      key: Key("custom-slot-${s.id}"),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.access_time, size: 16, color: AppColors.success),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('EEE, MMM d').format(s.scheduledAt), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(DateFormat.jm().format(s.scheduledAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            key: Key("delete-slot-${s.id}"),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                            onPressed: () => ref.read(doctorDashboardProvider.notifier).deleteSlot(s.id),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: AppSpacing.lg),
              const Text("Add a new slot", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: days.map((d) {
                  final active = dayOffset == d['o'];
                  return ChoiceChip(
                    key: Key("add-slot-day-${d['o']}"),
                    label: Text(d['label'].toString()),
                    selected: active,
                    onSelected: (_) => setState(() => dayOffset = d['o'] as int),
                    selectedColor: AppColors.brand,
                    labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.md),
              const Text("Hour", style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: hours.map((h) {
                    final active = hour == h;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        key: Key("add-slot-hour-$h"),
                        label: Text("$h:00"),
                        selected: active,
                        onSelected: (_) => setState(() => hour = h),
                        selectedColor: AppColors.brand,
                        labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              const Text("Minutes", style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
              Wrap(
                spacing: AppSpacing.sm,
                children: minutes.map((m) {
                  final active = minute == m;
                  return ChoiceChip(
                    key: Key("add-slot-min-$m"),
                    label: Text(":$m"),
                    selected: active,
                    onSelected: (_) => setState(() => minute = m),
                    selectedColor: AppColors.brand,
                    labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  key: const Key("confirm-add-slot"),
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text("Add slot", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
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
