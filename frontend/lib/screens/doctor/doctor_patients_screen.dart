import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/user.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  List<Patient> patients = [];
  bool isLoading = true;
  String searchQuery = "";
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final doc = ref.read(authProvider).currentUser;
      final fb = ref.read(firebaseServiceProvider);
      final list = await fb.fetchDoctorPatients(doc?.id ?? '');
      if (mounted && list.isNotEmpty) {
        setState(() {
          patients = list;
          isLoading = false;
        });
        return;
      }

      final api = ref.read(apiServiceProvider);
      final res = await api.get("/doctor/patients") as List;
      if (mounted && res.isNotEmpty) {
        setState(() {
          patients = res.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
          isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback from live appointments if any
    final dashAppts = ref.read(doctorDashboardProvider).appointments;
    final Map<String, Patient> map = {};
    for (final a in dashAppts) {
      final pid = a.patientId.isNotEmpty ? a.patientId : (a.patient?.id ?? '');
      final pname = a.patient?.name ?? (a.patientName ?? 'Patient');
      final pphone = a.patient?.phone ?? (a.patientPhone ?? '+15551110001');
      if (pid.isNotEmpty && !map.containsKey(pid)) {
        map[pid] = Patient(
          id: pid,
          name: pname,
          phone: pphone,
          age: a.patient?.age ?? 30,
          gender: a.patient?.gender ?? 'Other',
          allergies: a.patient?.allergies ?? 'None',
        );
      }
    }

    if (mounted) {
      setState(() {
        patients = map.values.toList();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = patients.where((p) {
      final query = searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) || p.phone.contains(query);
    }).toList();

    return Scaffold(
      key: const Key("doctor-patients-screen"),
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
                  const Text(
                    "Patients",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${patients.length} total",
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.muted, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        key: const Key("patient-search-input"),
                        controller: _searchController,
                        onChanged: (val) => setState(() => searchQuery = val),
                        style: const TextStyle(fontSize: 15, color: AppColors.onSurface),
                        decoration: const InputDecoration(
                          hintText: "Search by name or phone",
                          hintStyle: TextStyle(color: AppColors.muted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Patient List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No patients yet.",
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];

                            return InkWell(
                              key: Key("patient-row-${item.id}"),
                              onTap: () => context.push('/doctor/patient/${item.id}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: AppColors.brandTertiary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          item.name.isNotEmpty ? item.name[0].toUpperCase() : "?",
                                          style: const TextStyle(
                                            color: AppColors.brand,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurface,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${item.phone} · ${item.age ?? '—'} ${item.gender != null ? '· ${item.gender}' : ''}",
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (item.allergies != null && item.allergies!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              "⚠️ ${item.allergies}",
                                              style: const TextStyle(
                                                color: Color(0xFF92400E),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
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
