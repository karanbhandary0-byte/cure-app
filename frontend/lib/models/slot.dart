DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  try {
    final dyn = val as dynamic;
    if (dyn.toDate != null) {
      return dyn.toDate() as DateTime;
    }
  } catch (_) {}
  return DateTime.tryParse(val.toString()) ?? DateTime.now();
}

class CustomSlot {
  final String id;
  final DateTime scheduledAt;

  CustomSlot({
    required this.id,
    required this.scheduledAt,
  });

  factory CustomSlot.fromJson(Map<String, dynamic> json) {
    return CustomSlot(
      id: json['id']?.toString() ?? '',
      scheduledAt: _parseDateTime(json['scheduled_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduled_at': scheduledAt.toIso8601String(),
    };
  }
}

class TimeSlot {
  final String time;
  final String label;
  final bool available;

  TimeSlot({
    required this.time,
    required this.label,
    required this.available,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      available: json['available'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'label': label,
      'available': available,
    };
  }
}
