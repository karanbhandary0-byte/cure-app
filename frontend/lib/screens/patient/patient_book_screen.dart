import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../config/status_meta.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/user.dart';
import '../../models/slot.dart';
import '../../utils/disease_specialty_mapper.dart';

class PatientBookScreen extends ConsumerStatefulWidget {
  const PatientBookScreen({super.key});

  @override
  ConsumerState<PatientBookScreen> createState() => _PatientBookScreenState();
}

class _PatientBookScreenState extends ConsumerState<PatientBookScreen> {
  List<Doctor> doctors = [];
  bool isLoading = true;
  Doctor? selectedDoctor;

  int dayOffset = 0;
  String chosenSlot = "";
  List<TimeSlot> slots = [];
  bool slotsLoading = false;
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();
  bool submitting = false;

  final dayOptions = const [
    {"offset": 0, "label": "Today"},
    {"offset": 1, "label": "Tomorrow"},
    {"offset": 2, "label": "+2 days"},
    {"offset": 3, "label": "+3 days"},
    {"offset": 4, "label": "+4 days"},
    {"offset": 5, "label": "+5 days"},
    {"offset": 6, "label": "+6 days"},
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => isLoading = true);
    try {
      final fb = ref.read(firebaseServiceProvider);
      final fbDocs = await fb.fetchDoctors();
      final verifiedDocs = fbDocs.where((d) => (d.verificationStatus ?? 'pending').toLowerCase() == 'verified').toList();
      if (verifiedDocs.isNotEmpty) {
        if (mounted) {
          setState(() {
            doctors = verifiedDocs;
            isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get("/patient/doctors") as List;
      final parsedDocs = res
          .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
          .where((d) => (d.verificationStatus ?? 'pending').toLowerCase() == 'verified')
          .toList();
      if (mounted && parsedDocs.isNotEmpty) {
        setState(() {
          doctors = parsedDocs;
          isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback demo doctors list if Firestore and API are clean/empty
    if (mounted) {
      setState(() {
        doctors = [
          Doctor(
            id: 'doc_demo_1',
            name: 'Dr. Sarah Smith',
            specialty: 'Cardiology',
            clinicName: 'Cure Medical Center',
            clinicAddress: 'Bandra West, Mumbai',
            status: 'available',
            delayMinutes: 0,
            slotDurationMin: 30,
            slotCount: 8,
            slotStartHour: 9,
          ),
          Doctor(
            id: 'doc_demo_2',
            name: 'Dr. Raj Patel',
            specialty: 'General Physician',
            clinicName: 'Health First Clinic',
            clinicAddress: 'Andheri East, Mumbai',
            status: 'available',
            delayMinutes: 0,
            slotDurationMin: 30,
            slotCount: 8,
            slotStartHour: 9,
          ),
          Doctor(
            id: 'doc_demo_3',
            name: 'Dr. Ananya Roy',
            specialty: 'Dermatology',
            clinicName: 'Skin & Care Clinic',
            clinicAddress: 'Koramangala, Bangalore',
            status: 'available',
            delayMinutes: 0,
            slotDurationMin: 30,
            slotCount: 8,
            slotStartHour: 10,
          ),
          Doctor(
            id: 'doc_demo_4',
            name: 'Dr. Vikram Sharma',
            specialty: 'Orthopedics',
            clinicName: 'Bone & Joint Clinic',
            clinicAddress: 'Connaught Place, Delhi',
            status: 'available',
            delayMinutes: 0,
            slotDurationMin: 30,
            slotCount: 8,
            slotStartHour: 9,
          ),
          Doctor(
            id: 'doc_demo_5',
            name: 'Dr. Priya Mehta',
            specialty: 'Pediatrics',
            clinicName: 'Little Smiles Child Clinic',
            clinicAddress: 'Bandra West, Mumbai',
            status: 'available',
            delayMinutes: 0,
            slotDurationMin: 30,
            slotCount: 8,
            slotStartHour: 9,
          ),
        ];
        isLoading = false;
      });
    }
  }

  String _nextDayISO(int offset) {
    final d = DateTime.now().add(Duration(days: offset));
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadSlots(String doctorId, int offset) async {
    setState(() => slotsLoading = true);
    final targetDate = DateTime.now().add(Duration(days: offset));

    try {
      final fb = ref.read(firebaseServiceProvider);
      final liveSlots = await fb.fetchDoctorAvailableSlots(
        doctorId,
        targetDate,
        startHour: selectedDoctor?.slotStartHour ?? 9,
        count: selectedDoctor?.slotCount ?? 8,
        durationMin: selectedDoctor?.slotDurationMin ?? 30,
      );

      if (liveSlots.isNotEmpty) {
        if (mounted) {
          setState(() {
            slots = liveSlots;
            chosenSlot = "";
            slotsLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get("/patient/doctors/$doctorId/slots?date=${_nextDayISO(offset)}") as Map<String, dynamic>;
      final rawList = res['slots'] as List;
      if (mounted) {
        setState(() {
          slots = rawList.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
          chosenSlot = "";
          slotsLoading = false;
        });
      }
      return;
    } catch (_) {}

    // Fallback generated slots for Firebase demo mode
    final baseDate = targetDate;
    final List<TimeSlot> generatedSlots = [];
    final startHour = selectedDoctor?.slotStartHour ?? 9;
    final count = selectedDoctor?.slotCount ?? 8;
    final duration = selectedDoctor?.slotDurationMin ?? 30;

    for (int i = 0; i < count; i++) {
      final slotTime = DateTime(baseDate.year, baseDate.month, baseDate.day, startHour).add(Duration(minutes: i * duration));
      final hourStr = slotTime.hour > 12 ? (slotTime.hour - 12) : (slotTime.hour == 0 ? 12 : slotTime.hour);
      final amPm = slotTime.hour >= 12 ? 'PM' : 'AM';
      final minStr = slotTime.minute.toString().padLeft(2, '0');
      final label = "$hourStr:$minStr $amPm";
      generatedSlots.add(TimeSlot(
        time: slotTime.toIso8601String(),
        label: label,
        available: true,
      ));
    }

    if (mounted) {
      setState(() {
        slots = generatedSlots;
        chosenSlot = "";
        slotsLoading = false;
      });
    }
  }

  void _book() async {
    if (selectedDoctor == null || chosenSlot.isEmpty) return;
    setState(() => submitting = true);

    final authState = ref.read(authProvider);
    final patient = authState.currentUser is Patient ? authState.currentUser as Patient : null;
    final scheduledDateTime = DateTime.tryParse(chosenSlot) ?? DateTime.now().add(const Duration(days: 1));

    try {
      final fb = ref.read(firebaseServiceProvider);
      await fb.bookAppointment(
        doctorId: selectedDoctor!.id,
        doctorName: selectedDoctor!.name,
        clinicName: selectedDoctor!.clinicName,
        patientId: patient?.id ?? 'patient_demo',
        patientName: patient?.name ?? 'Patient Demo',
        patientPhone: patient?.phone ?? '+15551110001',
        scheduledAt: scheduledDateTime,
      );

      ref.read(patientHomeProvider.notifier).load();
      if (mounted) {
        context.go('/patient/home');
      }
      return;
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      await api.post("/patient/appointments", body: {
        "doctor_id": selectedDoctor!.id,
        "scheduled_at": chosenSlot,
        "reason": _reasonController.text.trim(),
      });

      ref.read(patientHomeProvider.notifier).load();
      if (mounted) {
        context.go('/patient/home');
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

    final location = ref.watch(patientLocationProvider);
    final searchQuery = _searchController.text.trim().toLowerCase();
    final matchedSpecialties = DiseaseSpecialtyMapper.getSpecialtiesForQuery(searchQuery);

    final filteredDoctors = doctors.where((d) {
      if (searchQuery.isEmpty) return true;

      final nameMatch = d.name.toLowerCase().contains(searchQuery);
      final specMatch = d.specialty.toLowerCase().contains(searchQuery);
      final clinicMatch = d.clinicName.toLowerCase().contains(searchQuery) ||
          (d.clinicAddress != null && d.clinicAddress!.toLowerCase().contains(searchQuery));

      final diseaseMatch = matchedSpecialties.any(
        (s) => d.specialty.toLowerCase().contains(s.toLowerCase()) || s.toLowerCase().contains(d.specialty.toLowerCase()),
      );

      return nameMatch || specMatch || clinicMatch || diseaseMatch;
    }).toList();

    // Sort: Nearby doctors in current location appear first
    filteredDoctors.sort((a, b) {
      final aNearby = (a.clinicAddress != null && a.clinicAddress!.toLowerCase().contains(location.toLowerCase())) ||
          a.clinicName.toLowerCase().contains(location.toLowerCase());
      final bNearby = (b.clinicAddress != null && b.clinicAddress!.toLowerCase().contains(location.toLowerCase())) ||
          b.clinicName.toLowerCase().contains(location.toLowerCase());

      if (aNearby && !bNearby) return -1;
      if (!aNearby && bNearby) return 1;
      return 0;
    });

    return Scaffold(
      key: const Key("patient-book-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Location Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    key: const Key("book-screen-location-bar"),
                    onTap: () => _showLocationSelectorModal(context, ref),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.brandTertiary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.brand),
                          const SizedBox(width: 4),
                          Text(
                            "Location: $location",
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 12, color: AppColors.brand),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              const Text(
                "Book an appointment",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Find doctors nearby by entering a disease, symptom, or location.",
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search Input Field
              TextField(
                key: const Key("disease-search-input"),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search disease (e.g. Fever, Heart pain, Skin rash) or doctor...",
                  prefixIcon: const Icon(Icons.search, color: AppColors.brand),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.brand),
                  ),
                ),
              ),

              // Detected Specialty Indicator Banner
              if (searchQuery.isNotEmpty && matchedSpecialties.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.brandTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.brand, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          "Matching Specialty: ${matchedSpecialties.join(', ')}",
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
              ],

              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "DOCTORS",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "${filteredDoctors.length} found",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (filteredDoctors.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, color: AppColors.muted, size: 36),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "No doctors found for \"$searchQuery\"",
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Try searching for General Physician, Fever, Heart pain, or change location.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...filteredDoctors.map((d) {
                  final meta = StatusMeta.get(d.status);
                  final isSelected = selectedDoctor?.id == d.id;

                  final isNearby = (d.clinicAddress != null && d.clinicAddress!.toLowerCase().contains(location.toLowerCase())) ||
                      d.clinicName.toLowerCase().contains(location.toLowerCase());

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InkWell(
                      key: Key("doctor-card-${d.id}"),
                      onTap: () {
                        setState(() {
                          selectedDoctor = d;
                        });
                        _loadSlots(d.id, dayOffset);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected ? AppColors.brand : (isNearby ? AppColors.brand.withOpacity(0.4) : AppColors.border),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.brandTertiary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.medical_services, color: AppColors.brand, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15),
                                        ),
                                      ),
                                      if (isNearby)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successBg,
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                          ),
                                          child: Text(
                                            "📍 Nearby in $location",
                                            style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w700, fontSize: 10),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${d.specialty} · ${d.clinicName}",
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                  if (d.clinicAddress != null && (d.clinicAddress?.isNotEmpty ?? false)) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.muted),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            d.clinicAddress ?? '',
                                            style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(999)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(meta.icon, size: 11, color: meta.color),
                                        const SizedBox(width: 4),
                                        Text(meta.label, style: TextStyle(color: meta.color, fontWeight: FontWeight.w700, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.check_circle, color: AppColors.brand, size: 22),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              if (selectedDoctor != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  "PICK A DAY",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
                ),
                const SizedBox(height: AppSpacing.sm),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dayOptions.map((opt) {
                      final offset = opt['offset'] as int;
                      final active = dayOffset == offset;

                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          key: Key("day-$offset"),
                          label: Text(opt['label'].toString()),
                          selected: active,
                          onSelected: (_) {
                            setState(() => dayOffset = offset);
                            _loadSlots(selectedDoctor!.id, offset);
                          },
                          selectedColor: AppColors.brand,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: active ? AppColors.brand : AppColors.border),
                          labelStyle: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Text(
                  "AVAILABLE TIME SLOTS",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
                ),
                const SizedBox(height: AppSpacing.sm),

                if (slotsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
                  )
                else if (slots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: Text("The doctor hasn't configured any time slots yet.", style: TextStyle(color: AppColors.muted)),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: slots.map((s) {
                      final active = chosenSlot == s.time;
                      final available = s.available;

                      return ChoiceChip(
                        key: Key("slot-${s.label}"),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.label),
                            if (!available)
                              const Text("booked", style: TextStyle(color: AppColors.muted, fontSize: 10)),
                          ],
                        ),
                        selected: active,
                        onSelected: available
                            ? (_) => setState(() => chosenSlot = s.time)
                            : null,
                        selectedColor: AppColors.brand,
                        backgroundColor: available ? AppColors.surface : AppColors.surfaceSecondary,
                        disabledColor: AppColors.surfaceSecondary,
                        side: BorderSide(color: active ? AppColors.brand : AppColors.border),
                        labelStyle: TextStyle(
                          color: active
                              ? Colors.white
                              : (available ? AppColors.onSurface : AppColors.muted.withOpacity(0.5)),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: AppSpacing.lg),
                const Text(
                  "REASON (OPTIONAL)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  key: const Key("reason-input"),
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: "e.g. Persistent cough",
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
                    key: const Key("confirm-booking"),
                    onPressed: (submitting || chosenSlot.isEmpty) ? null : _book,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            chosenSlot.isNotEmpty ? "Confirm booking" : "Select a time slot",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationSelectorModal(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.read(patientLocationProvider);
    final controller = TextEditingController(text: currentLocation);

    final popularCities = [
      "Mumbai",
      "Delhi",
      "Bangalore",
      "Hyderabad",
      "Chennai",
      "Kolkata",
      "Pune",
      "New York",
    ];

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
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.brand, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Select Your Location",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                "Enter your city, area, or locality manually:",
                style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "e.g. Bandra West, Mumbai or Connaught Place",
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                "POPULAR CITIES",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: popularCities.map((city) {
                  final isSelected = currentLocation.toLowerCase() == city.toLowerCase();
                  return ChoiceChip(
                    label: Text(city),
                    selected: isSelected,
                    selectedColor: AppColors.brand,
                    backgroundColor: AppColors.surfaceSecondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      ref.read(patientLocationProvider.notifier).state = city;
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
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
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      ref.read(patientLocationProvider.notifier).state = text;
                      setState(() {});
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text("Set Location", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
