import 'package:shared_preferences/shared_preferences.dart';

import '/services/onboarding_service.dart';
import '/services/supabase_service.dart';

enum MainCoachmarkStep {
  playerSettings,
  library,
  addManifestation,
}

class MainExperienceCoachmarkService {
  MainExperienceCoachmarkService._();

  static const String _progressPrefix = 'main_experience_coachmark_progress_v1_';

  static String _progressKey() {
    final user = SupabaseService.currentUser;
    final userKey = user?.id.toLowerCase() ?? 'guest';
    return '$_progressPrefix$userKey';
  }

  static Future<bool> _isEligible() async {
    final completed = await OnboardingService.hasCompletedOnboarding();
    if (!completed) return false;
    return OnboardingService.hasGeneratedFirstStory();
  }

  static Future<int> _progress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_progressKey()) ?? 0;
  }

  static Future<void> _setProgress(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressKey(), value);
  }

  static Future<bool> canShow(MainCoachmarkStep step) async {
    if (!await _isEligible()) return false;
    final progress = await _progress();
    switch (step) {
      case MainCoachmarkStep.playerSettings:
        return progress == 0;
      case MainCoachmarkStep.library:
        return progress == 1;
      case MainCoachmarkStep.addManifestation:
        return progress == 2;
    }
  }

  static Future<void> markSeen(MainCoachmarkStep step) async {
    final progress = await _progress();
    final nextValue = switch (step) {
      MainCoachmarkStep.playerSettings => 1,
      MainCoachmarkStep.library => 2,
      MainCoachmarkStep.addManifestation => 3,
    };
    if (nextValue > progress) {
      await _setProgress(nextValue);
    }
  }
}
