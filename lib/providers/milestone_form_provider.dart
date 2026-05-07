import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attachment.dart';

class AddMilestoneFormState {
  final DateTime date;
  final List<Attachment> attachments;

  const AddMilestoneFormState({
    required this.date,
    required this.attachments,
  });

  AddMilestoneFormState copyWith({
    DateTime? date,
    List<Attachment>? attachments,
  }) =>
      AddMilestoneFormState(
        date: date ?? this.date,
        attachments: attachments ?? this.attachments,
      );
}

class AddMilestoneFormNotifier extends StateNotifier<AddMilestoneFormState> {
  AddMilestoneFormNotifier()
      : super(AddMilestoneFormState(
          date: DateTime.now(),
          attachments: [],
        ));

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void addAttachment(Attachment attachment) =>
      state = state.copyWith(attachments: [...state.attachments, attachment]);

  void removeAttachment(int index) {
    final list = [...state.attachments]..removeAt(index);
    state = state.copyWith(attachments: list);
  }
}

final addMilestoneFormProvider = StateNotifierProvider.autoDispose<
    AddMilestoneFormNotifier, AddMilestoneFormState>(
  (ref) => AddMilestoneFormNotifier(),
);
