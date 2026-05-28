class GrowthEntry {
  final String id;
  final DateTime date;
  final double? weightKg;
  final double? heightCm;
  final double? headCm;
  final String? note;

  const GrowthEntry({
    required this.id,
    required this.date,
    this.weightKg,
    this.heightCm,
    this.headCm,
    this.note,
  });

  bool get hasData => weightKg != null || heightCm != null || headCm != null;

  GrowthEntry copyWith({
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? headCm,
    String? note,
    bool clearNote = false,
    bool clearWeight = false,
    bool clearHeight = false,
    bool clearHead = false,
  }) =>
      GrowthEntry(
        id: id,
        date: date ?? this.date,
        weightKg: clearWeight ? null : weightKg ?? this.weightKg,
        heightCm: clearHeight ? null : heightCm ?? this.heightCm,
        headCm: clearHead ? null : headCm ?? this.headCm,
        note: clearNote ? null : note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        if (weightKg != null) 'weightKg': weightKg,
        if (heightCm != null) 'heightCm': heightCm,
        if (headCm != null) 'headCm': headCm,
        if (note != null) 'note': note,
      };

  factory GrowthEntry.fromJson(Map<String, dynamic> j) => GrowthEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        headCm: (j['headCm'] as num?)?.toDouble(),
        note: j['note'] as String?,
      );
}
