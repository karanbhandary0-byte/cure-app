class WeeklyTrendItem {
  final String day;
  final int count;

  WeeklyTrendItem({required this.day, required this.count});

  factory WeeklyTrendItem.fromJson(Map<String, dynamic> json) {
    return WeeklyTrendItem(
      day: json['day']?.toString() ?? '',
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }
}

class DoctorAnalytics {
  final int apptsToday;
  final int totalCompleted;
  final double successRate;
  final double followupRate;
  final int avgWaitingMin;
  final int feedbacksReceived;
  final List<WeeklyTrendItem> weeklyTrend;

  DoctorAnalytics({
    required this.apptsToday,
    required this.totalCompleted,
    required this.successRate,
    required this.followupRate,
    required this.avgWaitingMin,
    required this.feedbacksReceived,
    required this.weeklyTrend,
  });

  factory DoctorAnalytics.fromJson(Map<String, dynamic> json) {
    var rawTrend = json['weekly_trend'];
    List<WeeklyTrendItem> trendList = [];
    if (rawTrend is List) {
      trendList = rawTrend.map((e) => WeeklyTrendItem.fromJson(e)).toList();
    }

    return DoctorAnalytics(
      apptsToday: json['appts_today'] is int
          ? json['appts_today']
          : int.tryParse(json['appts_today']?.toString() ?? '0') ?? 0,
      totalCompleted: json['total_completed'] is int
          ? json['total_completed']
          : int.tryParse(json['total_completed']?.toString() ?? '0') ?? 0,
      successRate: json['success_rate'] is num
          ? (json['success_rate'] as num).toDouble()
          : double.tryParse(json['success_rate']?.toString() ?? '0') ?? 0.0,
      followupRate: json['followup_rate'] is num
          ? (json['followup_rate'] as num).toDouble()
          : double.tryParse(json['followup_rate']?.toString() ?? '0') ?? 0.0,
      avgWaitingMin: json['avg_waiting_min'] is int
          ? json['avg_waiting_min']
          : int.tryParse(json['avg_waiting_min']?.toString() ?? '0') ?? 0,
      feedbacksReceived: json['feedbacks_received'] is int
          ? json['feedbacks_received']
          : int.tryParse(json['feedbacks_received']?.toString() ?? '0') ?? 0,
      weeklyTrend: trendList,
    );
  }
}
