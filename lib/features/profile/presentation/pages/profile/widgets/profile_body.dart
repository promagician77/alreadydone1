import 'package:flutter/material.dart';

import '/features/profile/presentation/pages/profile/widgets/profile_logout_section.dart';
import '/features/profile/presentation/pages/profile/widgets/profile_reminders_section.dart';
import '/features/profile/presentation/pages/profile/widgets/profile_settings_section.dart';
import '/features/profile/presentation/pages/profile/widgets/profile_top_section.dart';
import '/features/profile/presentation/pages/profile/widgets/profile_upgrade_card.dart';

/// Scrollable profile settings content.
class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.displayName,
    required this.dreamLocation,
    required this.energyWord,
    required this.complete,
    required this.dayStreak,
    required this.active,
    required this.voiceItems,
    required this.personalizationItems,
    required this.morningEnabled,
    required this.bedtimeEnabled,
    required this.morningTimeLabel,
    required this.bedtimeTimeLabel,
    required this.onMorningChanged,
    required this.onBedtimeChanged,
    required this.onMorningTimeTap,
    required this.onBedtimeTimeTap,
    required this.accountItems,
    required this.showUpgradeCard,
    required this.isSubscribed,
    required this.onUpgradeTap,
    required this.supportItems,
    required this.isClosingAccount,
    required this.onCloseAccount,
    required this.onLogout,
  });

  final String displayName;
  final String dreamLocation;
  final String energyWord;
  final String complete;
  final String dayStreak;
  final String active;
  final List<ProfileSettingItem> voiceItems;
  final List<ProfileSettingItem> personalizationItems;
  final bool morningEnabled;
  final bool bedtimeEnabled;
  final String morningTimeLabel;
  final String bedtimeTimeLabel;
  final ValueChanged<bool> onMorningChanged;
  final ValueChanged<bool> onBedtimeChanged;
  final VoidCallback onMorningTimeTap;
  final VoidCallback onBedtimeTimeTap;
  final List<ProfileSettingItem> accountItems;
  final bool showUpgradeCard;
  final bool isSubscribed;
  final VoidCallback onUpgradeTap;
  final List<ProfileSettingItem> supportItems;
  final bool isClosingAccount;
  final VoidCallback? onCloseAccount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileTopSection(
            displayName: displayName,
            dreamLocation: dreamLocation,
            energyWord: energyWord,
            complete: complete,
            dayStreak: dayStreak,
            active: active,
          ),
          const SizedBox(height: 24),
          ProfileSettingsSection(title: 'VOICE', items: voiceItems),
          const SizedBox(height: 24),
          ProfileSettingsSection(
            title: 'PERSONALIZATION',
            items: personalizationItems,
          ),
          const SizedBox(height: 24),
          ProfileRemindersSection(
            morningEnabled: morningEnabled,
            bedtimeEnabled: bedtimeEnabled,
            morningTimeLabel: morningTimeLabel,
            bedtimeTimeLabel: bedtimeTimeLabel,
            onMorningChanged: onMorningChanged,
            onBedtimeChanged: onBedtimeChanged,
            onMorningTimeTap: onMorningTimeTap,
            onBedtimeTimeTap: onBedtimeTimeTap,
          ),
          const SizedBox(height: 24),
          ProfileSettingsSection(title: 'ACCOUNT', items: accountItems),
          if (showUpgradeCard) ...[
            const SizedBox(height: 24),
            ProfileUpgradeCard(
              isSubscribed: isSubscribed,
              onUpgradeTap: onUpgradeTap,
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 24),
          ProfileSettingsSection(title: 'SUPPORT', items: supportItems),
          ProfileLogoutSection(
            isClosingAccount: isClosingAccount,
            onCloseAccount: onCloseAccount,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }
}
