import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';

enum ScheduleType { allDays, selectedDays, specificDate }

class DoctorSchedulePlan {
  final String id;
  final ScheduleType type;
  final List<String> selectedDays; // ['Monday', 'Tuesday', ...]
  final String? specificDate; // 'September 5, 2026'
  final TimeOfDay fromTime;
  final TimeOfDay toTime;
  final int durationMinutes;
  final int totalSlots;

  DoctorSchedulePlan({
    required this.id,
    required this.type,
    this.selectedDays = const [],
    this.specificDate,
    required this.fromTime,
    required this.toTime,
    required this.durationMinutes,
    required this.totalSlots,
  });

  String get displayScheduleTarget {
    if (type == ScheduleType.allDays) {
      return "All Days (Monday – Sunday)";
    } else if (type == ScheduleType.selectedDays) {
      return selectedDays.join(', ');
    } else {
      return specificDate ?? "Specific Date";
    }
  }
}

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TAB 1: Created Schedules List
  final List<DoctorSchedulePlan> _schedules = [
    DoctorSchedulePlan(
      id: 'plan_1',
      type: ScheduleType.selectedDays,
      selectedDays: ['Monday', 'Tuesday', 'Friday'],
      fromTime: const TimeOfDay(hour: 6, minute: 0),
      toTime: const TimeOfDay(hour: 8, minute: 0),
      durationMinutes: 4,
      totalSlots: 30,
    ),
    DoctorSchedulePlan(
      id: 'plan_2',
      type: ScheduleType.specificDate,
      specificDate: DateFormat('MMMM d, yyyy').format(DateTime.now()),
      fromTime: const TimeOfDay(hour: 17, minute: 0), // 5:00 PM
      toTime: const TimeOfDay(hour: 20, minute: 0), // 8:00 PM
      durationMinutes: 4,
      totalSlots: 45,
    ),
  ];

  // TAB 2: Manage Slots State
  ScheduleType _scheduleType = ScheduleType.selectedDays;
  final Set<String> _selectedWeekdays = {'Monday', 'Tuesday', 'Friday'};
  DateTime _pickedDate = DateTime.now();

  TimeOfDay _fromTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _durationController = TextEditingController(text: "4");

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _selectTime(bool isFrom) async {
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
      });
    }
  }

  void _createSchedule() {
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

    if (_scheduleType == ScheduleType.selectedDays && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one day of the week."),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final newPlan = DoctorSchedulePlan(
      id: "plan_${DateTime.now().millisecondsSinceEpoch}",
      type: _scheduleType,
      selectedDays: _scheduleType == ScheduleType.selectedDays ? _selectedWeekdays.toList() : [],
      specificDate: _scheduleType == ScheduleType.specificDate ? DateFormat('MMMM d, yyyy').format(_pickedDate) : null,
      fromTime: _fromTime,
      toTime: _toTime,
      durationMinutes: int.tryParse(_durationController.text.trim()) ?? 4,
      totalSlots: slots,
    );

    setState(() {
      _schedules.insert(0, newPlan);
    });

    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✓ Schedule created successfully! Total: $slots slots per scheduled day."),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Doctor Slot Management",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Slots"),
            Tab(text: "Manage Slots"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1 — SLOTS
          _buildSlotsTab(),

          // TAB 2 — MANAGE SLOTS
          _buildManageSlotsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: SLOTS (Simple Card Display Only)
  // ==========================================
  Widget _buildSlotsTab() {
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "No schedule created yet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            const Text(
              "Go to 'Manage Slots' tab to configure your working hours.",
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              child: const Text("Create Schedule"),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _schedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final plan = _schedules[index];
        return _buildScheduleCard(plan);
      },
    );
  }

  Widget _buildScheduleCard(DoctorSchedulePlan plan) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target / Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Date / Days: ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface),
              ),
              Expanded(
                child: Text(
                  plan.displayScheduleTarget,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // From
          Row(
            children: [
              const Text("From: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text(_formatTime(plan.fromTime), style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),

          // To
          Row(
            children: [
              const Text("To: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text(_formatTime(plan.toTime), style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),

          // Consultation Duration
          Row(
            children: [
              const Text("Consultation Duration: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text("${plan.durationMinutes} minutes", style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),

          // Total Slots
          Row(
            children: [
              const Text("Total Slots: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text(
                "${plan.totalSlots}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MANAGE SLOTS (Step-by-Step Simple UX)
  // ==========================================
  Widget _buildManageSlotsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Select Schedule Type
          const Text(
            "Step 1 — Select Schedule Type",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                RadioListTile<ScheduleType>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0F766E),
                  title: const Text("All Days", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Apply the same schedule from Monday to Sunday.", style: TextStyle(fontSize: 12)),
                  value: ScheduleType.allDays,
                  groupValue: _scheduleType,
                  onChanged: (val) {
                    if (val != null) setState(() => _scheduleType = val);
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                RadioListTile<ScheduleType>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0F766E),
                  title: const Text("Selected Days", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Select one or more specific days of the week.", style: TextStyle(fontSize: 12)),
                  value: ScheduleType.selectedDays,
                  groupValue: _scheduleType,
                  onChanged: (val) {
                    if (val != null) setState(() => _scheduleType = val);
                  },
                ),
                if (_scheduleType == ScheduleType.selectedDays) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _weekdays.map((day) {
                        final isChecked = _selectedWeekdays.contains(day);
                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          dense: true,
                          activeColor: const Color(0xFF0F766E),
                          title: Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedWeekdays.add(day);
                              } else {
                                _selectedWeekdays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const Divider(height: 1, color: AppColors.border),
                RadioListTile<ScheduleType>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0F766E),
                  title: const Text("Specific Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Select one particular date using a date picker.", style: TextStyle(fontSize: 12)),
                  value: ScheduleType.specificDate,
                  groupValue: _scheduleType,
                  onChanged: (val) {
                    if (val != null) setState(() => _scheduleType = val);
                  },
                ),
                if (_scheduleType == ScheduleType.specificDate) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM d, yyyy').format(_pickedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
                          ),
                          const Icon(Icons.calendar_month, color: Color(0xFF0F766E), size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Step 2: Enter Schedule
          const Text(
            "Step 2 — Enter Schedule",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From Time
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text("From Time:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(_fromTime),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // To Time
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text("To Time:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(_toTime),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Consultation Duration
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text("Duration:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("minutes", style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.md),

                // Live Total Slots Display (Only show the big number)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Slots",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
                    ),
                    Text(
                      "$_calculatedTotalSlots",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Step 3: Create Schedule Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key("create-schedule-btn"),
              onPressed: _createSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text(
                "Create Schedule",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
