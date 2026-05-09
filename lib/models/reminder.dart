enum ReminderType { vaccination, appointment, birthday, swimClass, other }

enum ReminderRepeat { none, daily, weekly, monthly, yearly }

extension ReminderTypeLabel on ReminderType {
  String get label => switch (this) {
        ReminderType.vaccination => 'Vaccination',
        ReminderType.appointment => 'Appointment',
        ReminderType.birthday => 'Birthday',
        ReminderType.swimClass => 'Swim Class',
        ReminderType.other => 'Other',
      };

  String get emoji => switch (this) {
        ReminderType.vaccination => '💉',
        ReminderType.appointment => '🏥',
        ReminderType.birthday => '🎂',
        ReminderType.swimClass => '🏊',
        ReminderType.other => '📌',
      };
}

extension ReminderRepeatLabel on ReminderRepeat {
  String get label => switch (this) {
        ReminderRepeat.none => 'Once',
        ReminderRepeat.daily => 'Day',
        ReminderRepeat.weekly => 'Week',
        ReminderRepeat.monthly => 'Month',
        ReminderRepeat.yearly => 'Year',
      };

  String get fullLabel => switch (this) {
        ReminderRepeat.none => 'Once',
        ReminderRepeat.daily => 'Daily',
        ReminderRepeat.weekly => 'Weekly',
        ReminderRepeat.monthly => 'Monthly',
        ReminderRepeat.yearly => 'Yearly',
      };
}

class Reminder {
  final String id;
  final String title;
  final String? notes;
  final DateTime dateTime;
  final ReminderType type;
  final bool isDone;
  final ReminderRepeat repeat;

  const Reminder({
    required this.id,
    required this.title,
    this.notes,
    required this.dateTime,
    this.type = ReminderType.other,
    this.isDone = false,
    this.repeat = ReminderRepeat.none,
  });

  bool get isUpcoming => !isDone && dateTime.isAfter(DateTime.now());
  bool get isOverdue => !isDone && dateTime.isBefore(DateTime.now());

  Reminder copyWith({
    String? title,
    String? notes,
    DateTime? dateTime,
    ReminderType? type,
    bool? isDone,
    ReminderRepeat? repeat,
    bool clearNotes = false,
  }) =>
      Reminder(
        id: id,
        title: title ?? this.title,
        notes: clearNotes ? null : notes ?? this.notes,
        dateTime: dateTime ?? this.dateTime,
        type: type ?? this.type,
        isDone: isDone ?? this.isDone,
        repeat: repeat ?? this.repeat,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'dateTime': dateTime.toIso8601String(),
        'type': type.name,
        'isDone': isDone,
        'repeat': repeat.name,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        title: j['title'] as String,
        notes: j['notes'] as String?,
        dateTime: DateTime.parse(j['dateTime'] as String),
        type: ReminderType.values.firstWhere(
          (e) => e.name == (j['type'] as String? ?? 'other'),
          orElse: () => ReminderType.other,
        ),
        isDone: j['isDone'] as bool? ?? false,
        repeat: ReminderRepeat.values.firstWhere(
          (e) => e.name == (j['repeat'] as String? ?? 'none'),
          orElse: () => ReminderRepeat.none,
        ),
      );
}
