import 'package:flutter/material.dart';

/// Shared state for the onboarding flow across separate route pages.
/// Cleared when onboarding completes.
class OnboardingState {
  OnboardingState._();
  static final OnboardingState instance = OnboardingState._();

  final firstNameController = TextEditingController();
  final dreamLocationController = TextEditingController();
  final lovedOneController = TextEditingController();
  final desireDescriptionController = TextEditingController();

  /// Default 0 = 'Powerful' (user can skip selecting if they want Powerful).
  int selectedEnergyWord = 0;
  int selectedCategory = 0;
  final Map<String, bool> accordionOpen = {};

  Map<String, dynamic>? generatedStory;
  bool isGenerating = false;

  /// Duration in seconds of the last voice recording (set by recording page).
  int? recordingDurationSec;

  /// Public URL of the story voice (from api/voice/speak). Set when Continue is
  /// tapped on onboarding_voice_complete; used by onboarding_player to play.
  String? voicePlayUrl;

  /// Display name of the selected voice (e.g. "Marcus", "My Voice", or user's first name).
  /// Set when creating a clone or when choosing a preset in voice selection.
  String? selectedVoiceName;

  static const List<String> energyWords = ['Powerful', 'Peaceful', 'Abundant', 'Grateful', 'Confident'];
  static const List<String> categories = ['Love', 'Money', 'Career', 'Health', 'Home'];

  /// Builds the story request body from all fields (personalization + desire page).
  /// Pass [userTableId] from SupabaseService.getCurrentUserTableId().
  /// Returns a map with keys: user_id, name, location, energyWord, desireCategory,
  /// desireDescription, lovedOne?.
  Map<String, dynamic> toStoryRequestBody(int? userTableId) {
    final firstName = firstNameController.text.trim();
    final dreamPlace = dreamLocationController.text.trim();
    final energyWord = energyWords[selectedEnergyWord];
    final category = categories[selectedCategory];
    final describeWhatAlreadyYours = desireDescriptionController.text.trim();
    final someoneYouLove = lovedOneController.text.trim();

    final body = <String, dynamic>{
      'user_id': userTableId ?? 0,
      'name': firstName,
      'location': dreamPlace,
      'energyWord': energyWord,
      'desireCategory': category,
      'desireDescription': describeWhatAlreadyYours,
      'lovedOne': someoneYouLove.isEmpty ? null : someoneYouLove,
    };

    return body;
  }

  void clear() {
    firstNameController.clear();
    dreamLocationController.clear();
    lovedOneController.clear();
    desireDescriptionController.clear();
    selectedEnergyWord = 0;
    selectedCategory = 0;
    accordionOpen.clear();
    generatedStory = null;
    isGenerating = false;
    recordingDurationSec = null;
    voicePlayUrl = null;
    selectedVoiceName = null;
  }

  void dispose() {
    firstNameController.dispose();
    dreamLocationController.dispose();
    lovedOneController.dispose();
    desireDescriptionController.dispose();
  }
}
