/// A segment of a day. Times are minutes from local midnight (0..1440).
/// [endMin] is null while this is the currently-running focus. [category] is a
/// category key resolved through the user's category registry.
class TimeEntry {
  TimeEntry({
    required this.clientId,
    required this.day,
    required this.category,
    required this.startMin,
    this.endMin,
    this.updatedAt,
  });

  final String clientId;
  final String day; // YYYY-MM-DD (local)
  final String category; // category key
  final int startMin;
  final int? endMin;
  final DateTime? updatedAt;

  bool get isRunning => endMin == null;

  /// Duration in minutes given a live "now" position for running entries.
  int durationMin(int nowMin) {
    final end = endMin ?? nowMin;
    return (end - startMin).clamp(0, 1440);
  }

  TimeEntry copyWith({
    String? day,
    String? category,
    int? startMin,
    Object? endMin = _unset,
    DateTime? updatedAt,
  }) {
    return TimeEntry(
      clientId: clientId,
      day: day ?? this.day,
      category: category ?? this.category,
      startMin: startMin ?? this.startMin,
      endMin: endMin == _unset ? this.endMin : endMin as int?,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'day': day,
        'category': category,
        'start_min': startMin,
        'end_min': endMin,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  factory TimeEntry.fromJson(Map<String, dynamic> j) => TimeEntry(
        clientId: j['client_id'] as String,
        day: j['day'] as String,
        category: j['category'] as String,
        startMin: j['start_min'] as int,
        endMin: j['end_min'] as int?,
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'] as String)
            : null,
      );
}

const _unset = Object();
