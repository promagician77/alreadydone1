import '/core/constants/legal_urls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/shared/state/onboarding_state.dart';
import '/features/onboarding/presentation/pages/onboarding/onboarding_voice_widget.dart';
import '/features/subscription/presentation/pages/subscription/subscription_widget.dart';
import '/features/profile/presentation/pages/profile/profile_colors.dart';
import '/features/profile/presentation/pages/profile/profile_utils.dart';
import '/features/profile/presentation/pages/profile/widgets/profile_body.dart';
import '/features/profile/presentation/pages/profile/widgets/profile_close_account_overlay.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/shared/services/app_toast.dart';
import '/core/network/backend_client.dart';
import '/core/di/profile_locator.dart';
import '/core/di/auth_locator.dart';
import '/features/player/data/datasources/last_played_service.dart';
import '/shared/services/supabase_service.dart';
import 'profile_model.dart';
import 'profile_modals/profile_modals.dart';
export 'profile_model.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'Profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late ProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isClosingAccount = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
    _model.switchValue1 ??= true;
    _model.switchValue2 ??= true;
    _loadProfile();
  }

  void _applySubscriptionFromProfile(Map<String, dynamic> data) {
    final info = ProfileSubscriptionUtils.fromProfile(data);
    _model.isSubscribedFromRC = info.isSubscribedFromRC;
    _model.showUpgradeCardFromRC = info.showUpgradeCardFromRC;
    _model.subscriptionRowLabel = info.subscriptionRowLabel;
  }

  Future<void> _loadProfile() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) {
      if (mounted) {
        setState(() {
          _model.profileLoading = false;
          _model.profileError = 'Not signed in';
        });
      }
      return;
    }
    try {
      final data = await profileRepository.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _model.profileData = data;
          _model.profileLoading = false;
          _model.profileError = null;
          _model.switchValue1 =
              ProfileUtils.parseBool(data['is_MorningTime_Reminder'], true);
          _model.switchValue2 =
              ProfileUtils.parseBool(data['is_BedTime_Reminder'], true);
          _applySubscriptionFromProfile(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _model.profileLoading = false;
          _model.profileError =
              e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        });
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await authRepository.signOut();
    if (mounted) context.go('/login?welcomeBack=true');
  }

  Future<void> _closeAccount() async {
    if (_isClosingAccount) return;
    final authUser = SupabaseService.currentUser;
    final accessToken = await SupabaseService.getValidAccessToken() ?? '';
    if (authUser == null || accessToken.isEmpty) {
      if (mounted) AppToast.error(context, 'You must be signed in');
      return;
    }
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;

    setState(() => _isClosingAccount = true);
    try {
      await profileRepository.closeAccount(
        userId: userId,
        authUserId: authUser.id,
        supabaseAccessToken: accessToken,
      );
      if (!mounted) return;
      await authRepository.signOut();
      if (!mounted) return;
      AppToast.success(context, 'Account closed');
      context.go('/login?welcomeBack=true');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        'Failed to close account: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
      );
    } finally {
      if (mounted) setState(() => _isClosingAccount = false);
    }
  }

  Future<void> _confirmCloseAccount() async {
    if (!mounted) return;
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close account?'),
        content: const Text(
          'This will permanently delete your account, stories, and voice data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Close account'),
          ),
        ],
      ),
    );
    if (shouldClose == true) {
      await _closeAccount();
    }
  }

  Future<void> _onMorningReminderChanged(bool value) async {
    setState(() => _model.switchValue1 = value);
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      await profileRepository.updateUserProfile(userId, isMorningReminder: value);
      if (mounted) {
        AppToast.success(
          context,
          'Morning reminder ${value ? 'enabled' : 'disabled'}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _model.switchValue1 = !value);
        AppToast.error(
          context,
          'Failed to update: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
        );
      }
    }
  }

  Future<void> _onBedtimeReminderChanged(bool value) async {
    setState(() => _model.switchValue2 = value);
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      await profileRepository.updateUserProfile(userId, isBedtimeReminder: value);
      if (mounted) {
        AppToast.success(
          context,
          'Bedtime reminder ${value ? 'enabled' : 'disabled'}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _model.switchValue2 = !value);
        AppToast.error(
          context,
          'Failed to update: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
        );
      }
    }
  }

  Future<void> _handleReRecordVoice() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      final lastPlayed = await LastPlayedService.loadLastPlayed();
      int? storyId;
      String? storyContent;

      if (lastPlayed != null) {
        final idRaw = lastPlayed['storyId'];
        storyId = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
        storyContent = lastPlayed['storyContent']?.toString().trim();
      }

      if (storyId == null || storyContent == null || storyContent.isEmpty) {
        final res = await BackendClient.getStories(userId);
        final list = (res['stories'] as List<dynamic>?)
                ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
                .toList() ??
            [];
        if (list.isEmpty) {
          if (mounted) {
            AppToast.info(
              context,
              'Create a story first before re-recording your voice.',
            );
          }
          return;
        }
        list.sort((a, b) {
          final aAt =
              a['last_played'] ?? a['last_played_at'] ?? a['created_at'] ?? a['id'] ?? 0;
          final bAt =
              b['last_played'] ?? b['last_played_at'] ?? b['created_at'] ?? b['id'] ?? 0;
          if (aAt == bAt) return 0;
          return bAt.toString().compareTo(aAt.toString());
        });
        Map<String, dynamic>? story;
        if (storyId != null) {
          for (final s in list) {
            final id = s['id'] is int
                ? s['id'] as int
                : int.tryParse(s['id']?.toString() ?? '');
            if (id == storyId) {
              story = s;
              break;
            }
          }
        }
        story ??= list.first;
        storyId = story['id'] is int
            ? story['id'] as int
            : int.tryParse(story['id']?.toString() ?? '');
        storyContent = (story['story'] ?? story['content'])?.toString().trim();
      }

      if (storyId == null || storyContent == null || storyContent.isEmpty) {
        if (mounted) {
          AppToast.info(context, 'No story content found. Create a story first.');
        }
        return;
      }

      OnboardingState.instance.generatedStory = {'id': storyId, 'story': storyContent};
      if (mounted) context.go(OnboardingVoiceWidget.routePath);
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          'Failed to load story: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
        );
      }
    }
  }

  dynamic _morningTimeIso() =>
      _model.profileData?['morningTime_Reminder'] ??
      _model.profileData?['morning_time'] ??
      _model.profileData?['morning_Time'];

  dynamic _bedtimeTimeIso() =>
      _model.profileData?['bedTime_Reminder'] ??
      _model.profileData?['bedtime_time'] ??
      _model.profileData?['bedtime_Time'];

  Future<void> _openMorningTimePicker() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    final newTime = await showTimePickerModal(
      context,
      title: 'Morning Reminder Time',
      subtitle: 'When should we send your daily story?',
      currentTime: formatTimeFromIso(_morningTimeIso()),
      userId: userId,
      fieldType: TimeFieldType.morning,
    );
    if (mounted) {
      if (newTime != null) AppToast.success(context, 'Morning reminder time updated');
      _loadProfile();
    }
  }

  Future<void> _openBedtimeTimePicker() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    final newTime = await showTimePickerModal(
      context,
      title: 'Bedtime Reminder Time',
      subtitle: 'When should we send your evening reflection?',
      currentTime: formatTimeFromIso(_bedtimeTimeIso()),
      userId: userId,
      fieldType: TimeFieldType.bedtime,
    );
    if (mounted) {
      if (newTime != null) AppToast.success(context, 'Bedtime reminder time updated');
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final displayName =
        (_model.profileData?['name']?.toString() ?? '').trim().isNotEmpty
            ? (_model.profileData!['name'] ?? '').toString().trim()
            : (user?.userMetadata?['full_name']?.toString() ??
                user?.email?.split('@').first ??
                'User');
    final dreamLocation = _model.profileData?['dream_place']?.toString() ??
        _model.profileData?['dreamPlace']?.toString() ??
        _model.profileData?['dream_location']?.toString() ??
        _model.profileData?['location']?.toString() ??
        '—';
    final energyWord = _model.profileData?['energyWord']?.toString() ?? 'Powerful';
    final someoneYouLove = _model.profileData?['lovedOne']?.toString() ?? '—';
    final email = _model.profileData?['email']?.toString() ?? user?.email ?? '—';
    final profileData = _model.profileData;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: ProfileColors.surface,
            body: SafeArea(
              top: true,
              child: _model.profileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _model.profileError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _model.profileError!,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: ProfileColors.inkSoft,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ProfileBody(
                            displayName: displayName,
                            dreamLocation: dreamLocation,
                            energyWord: energyWord,
                            complete: profileData?['complete']?.toString() ?? '0',
                            dayStreak: profileData?['day_streak']?.toString() ?? '0',
                            active: profileData?['active']?.toString() ?? '0',
                            voiceItems: [
                              ('Re-record My Voice', '→', _handleReRecordVoice),
                              (
                                'Narration Speed',
                                '${ProfileUtils.formatSpeed(profileData?['speed'])} →',
                                () async {
                                  final userId =
                                      await SupabaseService.getCurrentUserTableId();
                                  if (userId == null || !mounted) return;
                                  final newSpeed = await showNarrationSpeedModal(
                                    context,
                                    userId: userId,
                                    currentSpeed: ProfileUtils.getSpeedValue(
                                      profileData?['speed'],
                                    ),
                                  );
                                  if (mounted) {
                                    if (newSpeed != null) {
                                      AppToast.success(
                                        context,
                                        'Narration speed updated',
                                      );
                                    }
                                    _loadProfile();
                                  }
                                },
                              ),
                            ],
                            personalizationItems: [
                              (
                                'Your Name',
                                '$displayName →',
                                () async {
                                  final userId =
                                      await SupabaseService.getCurrentUserTableId();
                                  if (userId == null || !mounted) return;
                                  final newName = await showYourNameModal(
                                    context,
                                    userId: userId,
                                    currentName: displayName,
                                  );
                                  if (mounted) {
                                    if (newName != null) {
                                      AppToast.success(context, 'Name updated');
                                    }
                                    _loadProfile();
                                  }
                                },
                              ),
                              (
                                'Dream Location',
                                '$dreamLocation →',
                                () async {
                                  final userId =
                                      await SupabaseService.getCurrentUserTableId();
                                  if (userId == null || !mounted) return;
                                  final newLocation = await showDreamLocationModal(
                                    context,
                                    userId: userId,
                                    currentLocation: dreamLocation,
                                  );
                                  if (mounted) {
                                    if (newLocation != null) {
                                      AppToast.success(
                                        context,
                                        'Dream location updated',
                                      );
                                    }
                                    _loadProfile();
                                  }
                                },
                              ),
                              (
                                'Energy Word',
                                '$energyWord →',
                                () async {
                                  final userId =
                                      await SupabaseService.getCurrentUserTableId();
                                  if (userId == null || !mounted) return;
                                  final newWord = await showEnergyWordModal(
                                    context,
                                    userId: userId,
                                    currentWord: energyWord,
                                  );
                                  if (mounted) {
                                    if (newWord != null) {
                                      AppToast.success(context, 'Energy word updated');
                                    }
                                    _loadProfile();
                                  }
                                },
                              ),
                              (
                                'Someone You Love (Romantic)',
                                '$someoneYouLove →',
                                () async {
                                  final userId =
                                      await SupabaseService.getCurrentUserTableId();
                                  if (userId == null || !mounted) return;
                                  final newValue = await showSomeoneYouLoveModal(
                                    context,
                                    userId: userId,
                                    currentValue:
                                        someoneYouLove == '—' ? '' : someoneYouLove,
                                  );
                                  if (mounted) {
                                    if (newValue != null) {
                                      AppToast.success(context, 'Updated');
                                    }
                                    _loadProfile();
                                  }
                                },
                              ),
                            ],
                            morningEnabled: _model.switchValue1 ?? true,
                            bedtimeEnabled: _model.switchValue2 ?? true,
                            morningTimeLabel:
                                '${formatTimeFromIso(_morningTimeIso())} →',
                            bedtimeTimeLabel:
                                '${formatTimeFromIso(_bedtimeTimeIso())} →',
                            onMorningChanged: _onMorningReminderChanged,
                            onBedtimeChanged: _onBedtimeReminderChanged,
                            onMorningTimeTap: _openMorningTimePicker,
                            onBedtimeTimeTap: _openBedtimeTimePicker,
                            accountItems: [
                              (
                                'Email',
                                '$email →',
                                () async {
                                  final userId =
                                      await SupabaseService.getCurrentUserTableId();
                                  if (userId == null || !mounted) return;
                                  await showVerifyPasswordModal(
                                    context,
                                    purpose: 'change your email',
                                    onVerified: (_) async {
                                      if (!mounted) return;
                                      showChangeEmailModal(
                                        context,
                                        userId: userId,
                                        currentEmail: email == '—' ? '' : email,
                                        onSave: (_) => _loadProfile(),
                                      );
                                    },
                                  );
                                },
                              ),
                              (
                                'Password',
                                'Change →',
                                () async {
                                  await showVerifyPasswordModal(
                                    context,
                                    purpose: 'change your password',
                                    onVerified: (verifiedPassword) async {
                                      if (!mounted) return;
                                      showChangePasswordModal(
                                        context,
                                        verifiedPassword: verifiedPassword,
                                        onUpdate: (_) {},
                                      );
                                    },
                                  );
                                },
                              ),
                              (
                                'Subscription',
                                '${_model.subscriptionRowLabel} →',
                                () => context.go(SubscriptionWidget.routePath),
                              ),
                            ],
                            showUpgradeCard: _model.showUpgradeCardFromRC,
                            isSubscribed: _model.isSubscribedFromRC,
                            onUpgradeTap: () =>
                                context.go(SubscriptionWidget.routePath),
                            supportItems: [
                              (
                                'Contact Us',
                                '→',
                                () => launchURL(kContactInformationUri.toString()),
                              ),
                              (
                                'Terms of Service',
                                '→',
                                () => launchURL(kTermsOfServiceUri.toString()),
                              ),
                              (
                                'Privacy Policy',
                                '→',
                                () => launchURL(kPrivacyPolicyUri.toString()),
                              ),
                            ],
                            isClosingAccount: _isClosingAccount,
                            onCloseAccount: _confirmCloseAccount,
                            onLogout: _logout,
                          ),
                        ),
            ),
          ),
        ),
        if (_isClosingAccount) const ProfileCloseAccountOverlay(),
      ],
    );
  }
}
