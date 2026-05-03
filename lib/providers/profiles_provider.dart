import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';

class ProfilesNotifier extends StateNotifier<List<KidProfile>> {
  ProfilesNotifier()
      : super([
          KidProfile(
            id: 'profile_1',
            name: 'Emma',
            dateOfBirth: DateTime.now().subtract(const Duration(days: 45)),
            color: Colors.pinkAccent,
            milestones: [
              Milestone(
                title: 'First smile',
                description: 'A bright morning smile that warmed your heart.',
                date: DateTime.now().subtract(const Duration(days: 16)),
                color: Colors.amber,
              ),
              Milestone(
                title: 'First hold',
                description: 'Baby held your finger for the very first time.',
                date: DateTime.now().subtract(const Duration(days: 10)),
                color: Colors.lightBlue,
              ),
              Milestone(
                title: 'Sleepy cuddle',
                description: 'A calm evening full of soft cuddles and tiny yawns.',
                date: DateTime.now().subtract(const Duration(days: 4)),
                color: Colors.pinkAccent,
              ),
            ],
          ),
        ]);

  void updateMilestones(int profileIndex, List<Milestone> milestones) {
    final profile = state[profileIndex];
    final updated = [...state];
    updated[profileIndex] = KidProfile(
      id: profile.id,
      name: profile.name,
      dateOfBirth: profile.dateOfBirth,
      color: profile.color,
      milestones: milestones,
    );
    state = updated;
  }

  void prependMilestone(int profileIndex, Milestone milestone) {
    final profile = state[profileIndex];
    updateMilestones(profileIndex, [milestone, ...profile.milestones]);
  }

  void addProfile(String name, DateTime dob, Color color) {
    state = [
      ...state,
      KidProfile(
        id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        dateOfBirth: dob,
        color: color,
        milestones: [],
      ),
    ];
  }

  void deleteProfile(int index) {
    final list = [...state];
    list.removeAt(index);
    state = list;
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, List<KidProfile>>(
  (ref) => ProfilesNotifier(),
);

final selectedProfileIndexProvider = StateProvider<int>((ref) => 0);

// ── Add-profile form state ─────────────────────────────────────────────────────

class AddProfileFormState {
  final DateTime dob;
  final Color color;

  const AddProfileFormState({required this.dob, required this.color});

  AddProfileFormState copyWith({DateTime? dob, Color? color}) =>
      AddProfileFormState(dob: dob ?? this.dob, color: color ?? this.color);
}

class AddProfileFormNotifier extends StateNotifier<AddProfileFormState> {
  AddProfileFormNotifier()
      : super(AddProfileFormState(dob: DateTime.now(), color: Colors.pinkAccent));

  void setDob(DateTime dob) => state = state.copyWith(dob: dob);
  void setColor(Color color) => state = state.copyWith(color: color);
}

final addProfileFormProvider = StateNotifierProvider.autoDispose<
    AddProfileFormNotifier, AddProfileFormState>(
  (ref) => AddProfileFormNotifier(),
);
