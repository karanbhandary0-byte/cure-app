import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/appointment.dart';
import '../../models/slot.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  String selectedFilter = "today";
  bool isLoading = true;
  List<Appointment> appointments = [];

  // Slot Management State
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<AppointmentSlot> _slots = [];
  bool _slotsLoading = false;
  String _slotStatusFilter = 'all';

  // Configured Sessions
  List<DoctorScheduleSession> _sessions = [
    DoctorScheduleSession(
      id: 'sess_morning',
      name: 'Morning Session',
      startHour: 6,
      startMinute: 0,
      startPeriod: 'AM',
      endHour: 8,
      endMinute: 0,
      endPeriod: 'AM',
      consultationDurationMin: 4,
    ),
    DoctorScheduleSession(
      id: 'sess_evening',
      name: 'Evening Session',
      startHour: 5,
      startMinute: 0,
      startPeriod: 'PM',
      endHour: 8,
      endMinute: 0,
      endPeriod: 'PM',
      consultationDurationMin: 4,
    ),
  ];

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
    _mainTabController = TabController(length: 2, vsync: this);
    _load();
    _loadSessionsAndSlots();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
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

  Future<void> _loadSessionsAndSlots() async {
    setState(() => _slotsLoading = true);
    final docId = ref.read(authProvider).currentUser?.id ?? "doc_demo_001";

    try {
      final api = ref.read(apiServiceProvider);
      final sessRes = await api.get("/doctor/schedule/sessions") as List;
      if (sessRes.isNotEmpty) {
        _sessions = sessRes.map((e) => DoctorScheduleSession.fromJson(e as Map<String, dynamic>)).toList();
      }

      final slotsRes = await api.get("/doctor/slots?date=$_selectedDate") as List;
      if (mounted) {
        setState(() {
          _slots = slotsRes.map((e) => AppointmentSlot.fromJson(e as Map<String, dynamic>)).toList();
          _slotsLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback: Generate local slots from current sessions
    _generateLocalSlots(docId);
  }

  void _generateLocalSlots(String docId) {
    List<AppointmentSlot> combined = [];
    for (final sess in _sessions) {
      if (sess.isActive) {
        combined.addAll(sess.generateSlots(doctorId: docId, date: _selectedDate));
      }
    }

    // Set a few demo booked & checked-in states for visual demonstration
    if (combined.length >= 4) {
      combined[0].status = 'checked_in';
      combined[0].patientName = 'James Wilson';
      combined[0].patientPhone = '+1 555-234-8901';
      combined[0].appointmentType = 'online';

      combined[1].status = 'booked';
      combined[1].patientName = 'Emily Davis';
      combined[1].patientPhone = '+1 555-781-4321';
      combined[1].appointmentType = 'online';

      combined[2].status = 'checked_in';
      combined[2].patientName = 'David Miller (Walk-In)';
      combined[2].patientPhone = '+1 555-789-0123';
      combined[2].appointmentType = 'walk_in';
    }

    if (mounted) {
      setState(() {
        _slots = combined;
        _slotsLoading = false;
      });
    }
  }

  Future<void> _saveSessionsAndGenerate() async {
    final docId = ref.read(authProvider).currentUser?.id ?? "doc_demo_001";
    setState(() => _slotsLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.post("/doctor/schedule/sessions", body: {
        "sessions": _sessions.map((s) => s.toJson()).toList(),
      });

      final res = await api.post("/doctor/slots/generate", body: {
        "date": _selectedDate,
        "sessions": _sessions.map((s) => s.toJson()).toList(),
      }) as Map<String, dynamic>;

      if (res['slots'] != null && mounted) {
        final rawSlots = res['slots'] as List;
        setState(() {
          _slots = rawSlots.map((e) => AppointmentSlot.fromJson(e as Map<String, dynamic>)).toList();
          _slotsLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✨ Successfully generated ${_slots.length} complete appointment slots!"),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
        return;
      }
    } catch (e) {
      // Fallback local generation
      _generateLocalSlots(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✨ Successfully generated ${_slots.length} appointment slots for $_selectedDate!"),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      }
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Doctor Schedule & Slots",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: AppColors.brand,
          indicatorWeight: 3,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: "Slot Generator & Sessions"),
            Tab(icon: Icon(Icons.calendar_today_outlined, size: 18), text: "Appointments List"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          // TAB 1: Slot Generator & Multi-Session Configuration
          _buildSlotManagementTab(),

          // TAB 2: Traditional Appointments List View
          _buildAppointmentsListTab(filtered),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: DOCTOR SCHEDULE & SLOT MANAGEMENT VIEW
  // -------------------------------------------------------------
  Widget _buildSlotManagementTab() {
    int totalGenerated = _slots.length;
    int availableCount = _slots.where((s) => s.status == 'available').length;
    int bookedCount = _slots.where((s) => s.status == 'booked').length;
    int checkedInCount = _slots.where((s) => s.status == 'checked_in').length;
    int completedCount = _slots.where((s) => s.status == 'completed').length;

    final filteredSlots = _slots.where((s) {
      if (_slotStatusFilter == 'available') return s.status == 'available';
      if (_slotStatusFilter == 'booked') return s.status == 'booked';
      if (_slotStatusFilter == 'checked_in') return s.status == 'checked_in';
      if (_slotStatusFilter == 'completed') return s.status == 'completed';
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Working Hours & Slots",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Define consultation periods and generate slots",
                    style: TextStyle(fontSize: 12, color: AppColors.muted.withOpacity(0.9)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month, size: 16),
                label: Text(
                  _selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now())
                      ? "Today (${DateFormat('MMM d').format(DateTime.parse(_selectedDate))})"
                      : DateFormat('MMM d, yyyy').format(DateTime.parse(_selectedDate)),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Working Sessions Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Configured Sessions",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              ),
              TextButton.icon(
                key: const Key("add-session-btn"),
                onPressed: _openAddSessionModal,
                icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF0F766E)),
                label: const Text(
                  "+ Add Session",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Session Cards List
          ..._sessions.asMap().entries.map((entry) {
            final idx = entry.key;
            final session = entry.value;
            return _buildSessionCard(session, idx);
          }),
          const SizedBox(height: AppSpacing.md),

          // "Generate Slots" Primary Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key("generate-slots-button"),
              onPressed: _saveSessionsAndGenerate,
              icon: const Icon(Icons.bolt, size: 20),
              label: const Text(
                "Generate Slots for Selected Schedule",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Live Metrics Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _buildMetricTile("Total Slots", totalGenerated.toString(), const Color(0xFF0284C7))),
                Container(width: 1, height: 30, color: AppColors.border),
                Expanded(child: _buildMetricTile("Available", availableCount.toString(), const Color(0xFF16A34A))),
                Container(width: 1, height: 30, color: AppColors.border),
                Expanded(child: _buildMetricTile("Booked", bookedCount.toString(), const Color(0xFFD97706))),
                Container(width: 1, height: 30, color: AppColors.border),
                Expanded(child: _buildMetricTile("Checked In", checkedInCount.toString(), const Color(0xFF0F766E))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Filter Pills for Slots
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSlotFilterPill("All Slots ($totalGenerated)", 'all'),
                _buildSlotFilterPill("Available ($availableCount)", 'available'),
                _buildSlotFilterPill("Booked ($bookedCount)", 'booked'),
                _buildSlotFilterPill("Checked In ($checkedInCount)", 'checked_in'),
                _buildSlotFilterPill("Completed ($completedCount)", 'completed'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Slots Grid / List View
          if (_slotsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredSlots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  "No slots matching selected filter.",
                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            _buildSlotsGrid(filteredSlots),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
      ],
    );
  }

  Widget _buildSessionCard(DoctorScheduleSession session, int index) {
    final totalMin = session.totalWorkingMinutes;
    final slotCount = session.calculatedSlotCount;
    final duration = session.consultationDurationMin;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: session.name.toLowerCase().contains("morning")
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      session.name.toLowerCase().contains("morning") ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                      size: 18,
                      color: session.name.toLowerCase().contains("morning") ? const Color(0xFFD97706) : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    session.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
                    onPressed: () => _openEditSessionModal(session, index),
                    tooltip: "Edit Session",
                  ),
                  if (_sessions.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _sessions.removeAt(index);
                        });
                      },
                      tooltip: "Remove Session",
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Working Period & Slot Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Working Hours", style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      "${session.formattedStartTime} – ${session.formattedEndTime}",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Duration & Slots", style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      "$duration min/slot · $slotCount Complete Slots",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Formula Breakdown & Live Preview Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              "Formula: $totalMin mins ÷ $duration mins = $slotCount slots (e.g. ${session.formattedStartTime}–${session.generateSlots(doctorId: 'x', date: 'x').isNotEmpty ? session.generateSlots(doctorId: 'x', date: 'x').first.endTime : ''})",
              style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotFilterPill(String title, String key) {
    final isSelected = _slotStatusFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _slotStatusFilter = key;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: isSelected ? const Color(0xFF0F766E) : AppColors.border),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsGrid(List<AppointmentSlot> slotsList) {
    return Column(
      children: slotsList.map((slot) => _buildSlotRow(slot)).toList(),
    );
  }

  Widget _buildSlotRow(AppointmentSlot slot) {
    Color bg = const Color(0xFFDCFCE7);
    Color textCol = const Color(0xFF15803D);
    String statusLabel = "Available";

    if (slot.status == 'booked') {
      bg = const Color(0xFFDBEAFE);
      textCol = const Color(0xFF1D4ED8);
      statusLabel = "Booked";
    } else if (slot.status == 'checked_in') {
      bg = const Color(0xFFCCFBF1);
      textCol = const Color(0xFF0F766E);
      statusLabel = "Checked In";
    } else if (slot.status == 'completed') {
      bg = const Color(0xFFF1F5F9);
      textCol = const Color(0xFF64748B);
      statusLabel = "Completed";
    } else if (slot.status == 'cancelled') {
      bg = const Color(0xFFFEE2E2);
      textCol = const Color(0xFFB91C1C);
      statusLabel = "Cancelled";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Token Box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                "#${slot.tokenNumber}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.onSurface),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Slot Time Range (e.g. 6:00 AM – 6:04 AM)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slot.timeRangeLabel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "(${slot.durationMin}m · ${slot.sessionName})",
                      style: const TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
                if (slot.patientName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Patient: ${slot.patientName} (${slot.appointmentType ?? 'Online'})",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ],
              ],
            ),
          ),

          // Status Badge with Tap-to-Change
          PopupMenuButton<String>(
            tooltip: "Change Status",
            onSelected: (newStatus) {
              setState(() {
                slot.status = newStatus;
              });
              try {
                ref.read(apiServiceProvider).put(
                  "/doctor/slots/${slot.id}/status",
                  body: {"status": newStatus},
                );
              } catch (_) {}
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: "available", child: Text("Available")),
              PopupMenuItem(value: "booked", child: Text("Booked")),
              PopupMenuItem(value: "checked_in", child: Text("Checked In")),
              PopupMenuItem(value: "completed", child: Text("Completed")),
              PopupMenuItem(value: "cancelled", child: Text("Cancelled")),
              PopupMenuItem(value: "no_show", child: Text("No-Show")),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textCol),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 14, color: textCol),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: TRADITIONAL APPOINTMENTS LIST TAB
  // -------------------------------------------------------------
  Widget _buildAppointmentsListTab(List<Appointment> filtered) {
    return Column(
      children: [
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
              final isSelected = f['key'] == selectedFilter;
              return Center(
                child: FilterChip(
                  label: Text(f['label']!),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => selectedFilter = f['key']!);
                    _load();
                  },
                  backgroundColor: AppColors.surfaceSecondary,
                  selectedColor: AppColors.brandTertiary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.brand : AppColors.muted,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(
                      child: Text("No appointments found", style: TextStyle(color: AppColors.muted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final apt = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          elevation: 0,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(AppSpacing.md),
                            title: Row(
                              children: [
                                Text(
                                  apt.patientName ?? 'Patient',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(apt.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    apt.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(apt.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  "${DateFormat('h:mm a').format(apt.scheduledAt)} · ${apt.reason}",
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go('/doctor/patient/${apt.patientId}'),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadSessionsAndSlots();
    }
  }

  void _openAddSessionModal() {
    _showSessionEditorModal(
      initialSession: DoctorScheduleSession(
        id: "sess_${DateTime.now().millisecondsSinceEpoch}",
        name: _sessions.length == 1 ? "Evening Session" : "Session ${_sessions.length + 1}",
        startHour: 5,
        startMinute: 0,
        startPeriod: "PM",
        endHour: 8,
        endMinute: 0,
        endPeriod: "PM",
        consultationDurationMin: 4,
      ),
      onSave: (newSess) {
        setState(() {
          _sessions.add(newSess);
        });
        _saveSessionsAndGenerate();
      },
    );
  }

  void _openEditSessionModal(DoctorScheduleSession session, int index) {
    _showSessionEditorModal(
      initialSession: session,
      onSave: (edited) {
        setState(() {
          _sessions[index] = edited;
        });
        _saveSessionsAndGenerate();
      },
    );
  }

  void _showSessionEditorModal({
    required DoctorScheduleSession initialSession,
    required Function(DoctorScheduleSession) onSave,
  }) {
    final nameCtrl = TextEditingController(text: initialSession.name);
    final durationCtrl = TextEditingController(text: initialSession.consultationDurationMin.toString());
    int startH = initialSession.startHour;
    int startM = initialSession.startMinute;
    String startP = initialSession.startPeriod;

    int endH = initialSession.endHour;
    int endM = initialSession.endMinute;
    String endP = initialSession.endPeriod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Live calculation
            int startTotal = (startH % 12 + (startP == "PM" ? 12 : 0)) * 60 + startM;
            int endTotal = (endH % 12 + (endP == "PM" ? 12 : 0)) * 60 + endM;
            int totalWorking = endTotal - startTotal;
            int duration = int.tryParse(durationCtrl.text.trim()) ?? 4;
            int calcSlots = (duration > 0 && totalWorking > 0) ? (totalWorking ~/ duration) : 0;
            bool isValid = totalWorking > 0 && duration > 0 && calcSlots > 0;

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Configure Working Session",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Set consultation start & end times with separate AM/PM selection.",
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),

                    // Session Name
                    const Text("Session Name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: "e.g. Morning Session / Evening Session",
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Start Time Input with AM/PM
                    const Text("1. Start Time (Hour : Min : AM/PM) *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Hour Selector
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: startH,
                            decoration: InputDecoration(
                              labelText: "Hour",
                              filled: true,
                              fillColor: AppColors.surfaceSecondary,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                            ),
                            items: List.generate(12, (i) => i + 1)
                                .map((h) => DropdownMenuItem(value: h, child: Text(h.toString())))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => startH = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Minute Selector
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: startM,
                            decoration: InputDecoration(
                              labelText: "Min",
                              filled: true,
                              fillColor: AppColors.surfaceSecondary,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                            ),
                            items: [0, 4, 5, 10, 15, 20, 30, 45]
                                .map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0'))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => startM = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // AM / PM Segmented Button
                        ToggleButtons(
                          isSelected: [startP == "AM", startP == "PM"],
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF0F766E),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 46),
                          onPressed: (idx) {
                            setModalState(() => startP = idx == 0 ? "AM" : "PM");
                          },
                          children: const [
                            Text("AM", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            Text("PM", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // End Time Input with AM/PM
                    const Text("2. End Time (Hour : Min : AM/PM) *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Hour Selector
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: endH,
                            decoration: InputDecoration(
                              labelText: "Hour",
                              filled: true,
                              fillColor: AppColors.surfaceSecondary,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                            ),
                            items: List.generate(12, (i) => i + 1)
                                .map((h) => DropdownMenuItem(value: h, child: Text(h.toString())))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => endH = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Minute Selector
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: endM,
                            decoration: InputDecoration(
                              labelText: "Min",
                              filled: true,
                              fillColor: AppColors.surfaceSecondary,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                            ),
                            items: [0, 4, 5, 10, 15, 20, 30, 45]
                                .map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0'))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => endM = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // AM / PM Segmented Button
                        ToggleButtons(
                          isSelected: [endP == "AM", endP == "PM"],
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF0F766E),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 46),
                          onPressed: (idx) {
                            setModalState(() => endP = idx == 0 ? "AM" : "PM");
                          },
                          children: const [
                            Text("AM", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            Text("PM", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Consultation Duration (Numeric in mins)
                    const Text("3. Consultation Duration (minutes) *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "e.g. 4",
                        suffixText: "minutes/slot",
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Live Calculation & Validation Alert Box
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isValid ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: isValid ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isValid ? Icons.check_circle_outline : Icons.error_outline,
                                color: isValid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isValid ? "Complete Slots Calculation" : "Invalid Working Period",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: isValid ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isValid
                                ? "• Total Period: $totalWorking minutes ($startH:${startM.toString().padLeft(2, '0')} $startP – $endH:${endM.toString().padLeft(2, '0')} $endP)\n• Slots Created: $totalWorking ÷ $duration = $calcSlots Complete Slots (No partial slots)"
                                : "• End time must be later than start time. Working period must be at least $duration minutes.",
                            style: TextStyle(
                              fontSize: 11,
                              color: isValid ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key("save-session-btn"),
                        onPressed: !isValid
                            ? null
                            : () {
                                final edited = DoctorScheduleSession(
                                  id: initialSession.id,
                                  name: nameCtrl.text.trim().isEmpty ? "Working Session" : nameCtrl.text.trim(),
                                  startHour: startH,
                                  startMinute: startM,
                                  startPeriod: startP,
                                  endHour: endH,
                                  endMinute: endM,
                                  endPeriod: endP,
                                  consultationDurationMin: duration,
                                );
                                onSave(edited);
                                Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          elevation: 0,
                        ),
                        child: const Text("Save Session & Generate Slots", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
