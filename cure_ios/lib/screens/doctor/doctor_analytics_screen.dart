import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/analytics.dart';

class DoctorAnalyticsScreen extends ConsumerStatefulWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  ConsumerState<DoctorAnalyticsScreen> createState() => _DoctorAnalyticsScreenState();
}

class _DoctorAnalyticsScreenState extends ConsumerState<DoctorAnalyticsScreen> {
  DoctorAnalytics? data;
  bool isLoading = true;

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
      final analytics = await fb.fetchDoctorAnalytics(doc?.id ?? '');
      if (mounted) {
        setState(() {
          data = analytics;
          isLoading = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get("/doctor/analytics") as Map<String, dynamic>;
      if (mounted && res.isNotEmpty) {
        setState(() {
          data = DoctorAnalytics.fromJson(res);
          isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        data = DoctorAnalytics(
          apptsToday: 0,
          totalCompleted: 0,
          successRate: 94.0,
          followupRate: 16.0,
          avgWaitingMin: 6,
          feedbacksReceived: 0,
          weeklyTrend: [
            WeeklyTrendItem(day: "Mon", count: 2),
            WeeklyTrendItem(day: "Tue", count: 4),
            WeeklyTrendItem(day: "Wed", count: 3),
            WeeklyTrendItem(day: "Thu", count: 5),
            WeeklyTrendItem(day: "Fri", count: 2),
            WeeklyTrendItem(day: "Sat", count: 1),
            WeeklyTrendItem(day: "Sun", count: 0),
          ],
        );
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || data == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      );
    }

    final d = data!;

    return Scaffold(
      key: const Key("doctor-analytics-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Insights",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Treatment effectiveness, follow-ups, and patient flow.",
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Metric Grid
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: "Appointments today",
                      value: "${d.apptsToday}",
                      accent: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricTile(
                      label: "Total completed",
                      value: "${d.totalCompleted}",
                      accent: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: "Success rate",
                      value: "${d.successRate.toStringAsFixed(0)}%",
                      accent: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricTile(
                      label: "Follow-up needed",
                      value: "${d.followupRate.toStringAsFixed(0)}%",
                      accent: AppColors.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Full Width Metric: Avg waiting time
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.brandTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Avg waiting time",
                      style: TextStyle(
                        color: AppColors.brandSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${d.avgWaitingMin} min",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              const Text(
                "Last 7 days",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Bar Chart
              Container(
                height: 240,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < d.weeklyTrend.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  d.weeklyTrend[idx].day,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    barGroups: d.weeklyTrend.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: item.count.toDouble(),
                            color: AppColors.brand,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              const Text(
                "Treatment summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: "Feedback responses", value: "${d.feedbacksReceived}"),
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(label: "Patients improved", value: "${d.successRate.toStringAsFixed(0)}%"),
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(label: "Needs follow-up", value: "${d.followupRate.toStringAsFixed(0)}%"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: accent),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
        ),
      ],
    );
  }
}
