import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/appointment.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> {
  String selectedFilter = "today";
  bool isLoading = true;
  List<Appointment> appointments = [];

  final filters = const [
    {"key": "today", "label": "Today"},
    {"key": "upcoming", "label": "Upcoming"},
    {"key": "delayed", "label": "Delayed"},
    {"key": "completed", "label": "Completed"},
    {"key": "all", "label": "All"},
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
      final list = await fb.streamDoctorAppointments(doc?.id ?? '').first;
      if (mounted && list.isNotEmpty) {
        setState(() {
          appointments = list;
          isLoading = false;
        });
        return;
      }

      final api = ref.read(apiServiceProvider);
      final res = await api.get("/doctor/appointments?filter=$selectedFilter") as List;
      if (mounted) {
        setState(() {
          appointments = res.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _statusColor(String? s) {
    if (s == "completed") return const Color(0xFF065F46);
    if (s == "delayed") return const Color(0xFF92400E);
    if (s == "cancelled") return const Color(0xFF991B1B);
    return AppColors.brand;
  }

  List<Appointment> _getFiltered(List<Appointment> list) {
    final now = DateTime.now();
    if (selectedFilter == "today") {
      return list.where((a) =>
          a.scheduledAt.year == now.year &&
          a.scheduledAt.month == now.month &&
          a.scheduledAt.day == now.day).toList();
    }
    if (selectedFilter == "upcoming") {
      return list.where((a) =>
          a.status == "scheduled" || a.status == "booked" || a.status == "delayed").toList();
    }
    if (selectedFilter == "delayed") {
      return list.where((a) => a.status == "delayed").toList();
    }
    if (selectedFilter == "completed") {
      return list.where((a) => a.status == "completed").toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dashAppts = ref.watch(doctorDashboardProvider).appointments;
    final allAppts = dashAppts.isNotEmpty ? dashAppts : appointments;
    final filtered = _getFiltered(allAppts);

    return Scaffold(
      key: const Key("doctor-appointments-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                "Schedule",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Horizontal Filter Chips
            Container(
              height: 56,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final f = filters[index];
                  final key = f['key'] ?? '';
                  final label = f['label'] ?? key;
                  final active = key == selectedFilter;

                  return Center(
                    child: ChoiceChip(
                      key: Key("filter-$key"),
                      label: Text(label),
                      selected: active,
                      onSelected: (_) {
                        setState(() => selectedFilter = key);
                        _load();
                      },
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

            // Appointment List
            Expanded(
              child: (isLoading && allAppts.isEmpty)
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No appointments in this view.",
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final dtStr = DateFormat('MMM d, h:mm a').format(item.scheduledAt);
                            final patName = item.patient?.name ?? (item.patientName ?? "Patient");

                            return InkWell(
                              key: Key("appt-row-${item.id}"),
                              onTap: () {
                                final pid = item.patientId.isNotEmpty ? item.patientId : (item.patient?.id ?? '');
                                if (pid.isNotEmpty) {
                                  context.push('/doctor/patient/$pid');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.brand,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurface,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "$dtStr · ${item.reason ?? '—'}",
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(item.status),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
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
