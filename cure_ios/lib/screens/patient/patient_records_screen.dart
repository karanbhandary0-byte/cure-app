import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/consultation.dart';
import '../../models/user.dart';

class PatientRecordsScreen extends ConsumerStatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  ConsumerState<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends ConsumerState<PatientRecordsScreen> {
  List<Consultation> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final authState = ref.read(authProvider);
    final patient = authState.currentUser is Patient ? authState.currentUser as Patient : null;
    final pid = patient?.id ?? 'patient_demo';

    try {
      final fb = ref.read(firebaseServiceProvider);
      final fbStream = fb.streamPatientConsultations(pid);
      final list = await fbStream.first.timeout(const Duration(seconds: 2));
      if (mounted && list.isNotEmpty) {
        setState(() {
          records = list;
          isLoading = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get("/patient/records") as List;
      if (mounted) {
        setState(() {
          records = res.map((e) => Consultation.fromJson(e as Map<String, dynamic>)).toList();
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("patient-records-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Medical records",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Past diagnoses and prescriptions",
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Records List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
                  : records.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_outlined, size: 48, color: AppColors.muted),
                              SizedBox(height: 12),
                              Text("No medical records yet.", style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final item = records[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Card Head
                                    Row(
                                      children: [
                                        const Icon(Icons.description, color: AppColors.brand, size: 20),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.doctor?.name ?? "Doctor",
                                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15),
                                              ),
                                              Text(
                                                item.doctor?.specialty ?? "",
                                                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          DateFormat.yMMMd().format(item.createdAt),
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),

                                    const Divider(color: AppColors.border, height: 24),

                                    const Text("DIAGNOSIS", style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(item.diagnosis, style: const TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.4)),

                                    const SizedBox(height: AppSpacing.sm),
                                    const Text("PRESCRIPTION", style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(item.prescription, style: const TextStyle(color: AppColors.onSurface, fontSize: 14, height: 1.4)),

                                    if (item.followUpInstructions != null && (item.followUpInstructions?.isNotEmpty ?? false)) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      const Text("FOLLOW-UP", style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.followUpInstructions ?? '',
                                        style: const TextStyle(color: AppColors.brand, fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
                                      ),
                                    ],
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
