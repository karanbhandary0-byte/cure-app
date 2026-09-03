import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/appointment.dart';

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
      if (!displayRows.any((r) => r['name'] == name)) {
        displayRows.add({
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
                        Text(
                          isToday
                              ? "Showing today's booked & walk-in patients"
                              : "Showing patients for selected date",
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
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

            // Appointments Table
            if (displayRows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xxl),
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2), // Slot No.
                      1: FlexColumnWidth(2.4), // Patient Name
                      2: FlexColumnWidth(1.0), // Age
                      3: FlexColumnWidth(2.2), // Booked Slot Time
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // Table Header
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                        ),
                        children: [
                          _buildHeaderCell("Slot No."),
                          _buildHeaderCell("Patient Name"),
                          _buildHeaderCell("Age"),
                          _buildHeaderCell("Booked Slot Time"),
                        ],
                      ),
                      // Table Data Rows
                      ...displayRows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final isEven = index % 2 == 0;

                        return TableRow(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.white : const Color(0xFFFAFAFA),
                            border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          children: [
                            _buildDataCell(
                              row['slotNo'].toString(),
                              isBold: true,
                              color: const Color(0xFF0F766E),
                            ),
                            _buildDataCell(
                              row['name'].toString(),
                              isBold: true,
                            ),
                            _buildDataCell(row['age'].toString()),
                            _buildDataCell(
                              row['time'].toString(),
                              color: const Color(0xFF334155),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? const Color(0xFF334155),
        ),
      ),
    );
  }
}
