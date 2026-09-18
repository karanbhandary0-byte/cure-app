import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/schedule_provider.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> {
  // Default View: Automatically opens with current day (Today)
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(doctorDashboardProvider.notifier).load();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F766E),
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openConsultationNotes(String patientId) {
    if (patientId.isNotEmpty) {
      context.push('/doctor/patient/$patientId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorDashboardProvider);
    final bookedSchedulePatients = ref.watch(bookedSchedulePatientsProvider);
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);

    // Get patients from the shared schedule provider for the selected date
    final dateSchedulePatients = bookedSchedulePatients
        .where((p) => _isSameDay(p.date, _selectedDate))
        .toList();

    // Also collect any server appointments for the selected date if present
    final serverAppointments = state.appointments
        .where((a) => _isSameDay(a.scheduledAt, _selectedDate))
        .toList();

    // Merge and format patient items for table display
    final List<Map<String, dynamic>> displayRows = [];

    for (int i = 0; i < dateSchedulePatients.length; i++) {
      final p = dateSchedulePatients[i];
      displayRows.add({
        'id': p.id,
        'slotNo': p.slotNumber > 0 ? p.slotNumber : (i + 1),
        'name': p.name,
        'age': p.age.toString(),
        'time': p.slotTime,
        'isWalkIn': p.isWalkIn,
      });
    }

    // Add any non-duplicate server appointments
    for (final a in serverAppointments) {
      final name = a.patientName ?? (a.patient?.name ?? 'Patient');
      final patientId = a.patientId.isNotEmpty ? a.patientId : (a.patient?.id ?? a.id);
      if (!displayRows.any((r) => r['name'] == name)) {
        displayRows.add({
          'id': patientId,
          'slotNo': a.tokenNumber > 0 ? a.tokenNumber : (displayRows.length + 1),
          'name': name,
          'age': a.patient?.age?.toString() ?? '—',
          'time': DateFormat('h:mm a').format(a.scheduledAt),
          'isWalkIn': false,
        });
      }
    }

    // Ensure slot numbers are strictly ordered 1, 2, 3...
    for (int i = 0; i < displayRows.length; i++) {
      displayRows[i]['slotNo'] = i + 1;
    }

    final formattedDate = DateFormat('MMMM d, yyyy').format(_selectedDate);
    final headerTitle = isToday ? "Today — $formattedDate" : "📅 $formattedDate";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            key: const Key("schedule-calendar-button"),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month, color: Color(0xFF0F766E)),
            tooltip: "View another date",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header and Calendar Picker Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Tap on any patient to view details & consultation notes",
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Color(0xFF0F766E)),
                          SizedBox(width: 6),
                          Text(
                            "Select Date",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Appointments Cards List (2-Line Doctor Friendly Layout)
            if (displayRows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy_outlined, size: 48, color: AppColors.muted),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "No Booked Appointments",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "There are no patients booked for $formattedDate.",
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayRows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = displayRows[index];
                  final patientId = row['id']?.toString() ?? '';
                  final patientName = row['name']?.toString() ?? 'Patient';
                  final slotNo = (row['slotNo'] as num?)?.toInt() ?? (index + 1);
                  final slotTime = row['time']?.toString() ?? '';
                  final age = row['age']?.toString() ?? '—';
                  final isWalkIn = row['isWalkIn'] == true;
                  final isNoShow = row['status'] == 'no_show';

                  return Container(
                    decoration: BoxDecoration(
                      color: isNoShow ? const Color(0xFFFFF5F5) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isNoShow ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LINE 1: Slot No. | Patient Name & Age | Booked Slot Time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Slot Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isNoShow ? const Color(0xFFE2E8F0) : const Color(0xFFE6F4F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Slot $slotNo",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isNoShow ? const Color(0xFF64748B) : const Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Patient Name & Age
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      patientName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isNoShow ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                        decoration: isNoShow ? TextDecoration.lineThrough : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "($age yrs)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isNoShow ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (isWalkIn) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "Walk-in",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Booked Slot Time
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isNoShow ? const Color(0xFFF1F5F9) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_filled,
                                    size: 13,
                                    color: isNoShow ? const Color(0xFF94A3B8) : const Color(0xFF0F766E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    slotTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isNoShow ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 10),

                        // LINE 2: ACTION BUTTONS (Consult & No Show)
                        if (isNoShow)
                          InkWell(
                            onTap: () => _restorePatient(patientId, patientName),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off_rounded, size: 15, color: Color(0xFFDC2626)),
                                  SizedBox(width: 6),
                                  Text(
                                    "Marked as No-Show · Tap to Restore",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              // 1. Consult Button
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openConsultationNotes(patientId),
                                  icon: const Icon(Icons.medical_services_outlined, size: 16),
                                  label: const Text(
                                    "Consult",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 2. No Show Button
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmNoShow(patientId, patientName, slotNo, slotTime),
                                  icon: const Icon(Icons.person_off_outlined, size: 16, color: Color(0xFFE11D48)),
                                  label: const Text(
                                    "No Show",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                                    backgroundColor: const Color(0xFFFFF1F2),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmNoShow(String patientId, String patientName, int slotNo, String slotTime) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_off_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text("Mark as No-Show?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Do you want to mark $patientName (Slot #$slotNo • $slotTime) as No-Show?",
          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.person_off_rounded, size: 16),
            label: const Text("Mark No-Show"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(bookedSchedulePatientsProvider.notifier).updatePatientStatus(patientId, 'no_show');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$patientName marked as No-Show"),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "Undo",
            textColor: Colors.white,
            onPressed: () {
              ref.read(bookedSchedulePatientsProvider.notifier).updatePatientStatus(patientId, 'scheduled');
            },
          ),
        ),
      );
    }
  }

  void _restorePatient(String patientId, String patientName) {
    ref.read(bookedSchedulePatientsProvider.notifier).updatePatientStatus(patientId, 'scheduled');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$patientName restored to Scheduled"),
          backgroundColor: const Color(0xFF0F766E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
