import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attachment.dart';
import '../models/external_link.dart';

class AddMilestoneFormState {
  final DateTime date;
  final List<Attachment> attachments;
  final List<ExternalLink> links;

  const AddMilestoneFormState({
    required this.date,
    required this.attachments,
    required this.links,
  });

  AddMilestoneFormState copyWith({
    DateTime? date,
    List<Attachment>? attachments,
    List<ExternalLink>? links,
  }) =>
      AddMilestoneFormState(
        date: date ?? this.date,
        attachments: attachments ?? this.attachments,
        links: links ?? this.links,
      );
}

class AddMilestoneFormNotifier
    extends StateNotifier<AddMilestoneFormState> {
  AddMilestoneFormNotifier()
      : super(AddMilestoneFormState(
          date: DateTime.now(),
          attachments: [],
          links: [],
        ));

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void addAttachment(Attachment attachment) =>
      state = state.copyWith(attachments: [...state.attachments, attachment]);

  void removeAttachment(int index) {
    final list = [...state.attachments]..removeAt(index);
    state = state.copyWith(attachments: list);
  }

  void addLink(ExternalLink link) =>
      state = state.copyWith(links: [...state.links, link]);

  void removeLink(int index) {
    final list = [...state.links]..removeAt(index);
    state = state.copyWith(links: list);
  }
}

final addMilestoneFormProvider = StateNotifierProvider.autoDispose<
    AddMilestoneFormNotifier, AddMilestoneFormState>(
  (ref) => AddMilestoneFormNotifier(),
);
