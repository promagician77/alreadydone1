import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/pages/auth/auth_theme.dart';
import '/pages/onboarding/onboarding_voice_widget.dart';
import '/pages/subscription/subscription_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/app_toast.dart';
import '/widgets/pressable.dart';
import '/services/backend_client.dart';
import '/services/last_played_service.dart';
import '/services/supabase_service.dart';
import '/pages/onboarding/onboarding_state.dart';
import 'profile_model.dart';
import 'profile_modals/profile_modals.dart';
export 'profile_model.dart';

/// Design tokens from HTML (04 — Profile & Settings)
class _ProfileColors {
  static const warmWhite = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkMid = Color(0xFF44403C);
  static const inkSoft = Color(0xFF78716C);
  static const stone = Color(0xFFE8E2DA);
  static const stoneMid = Color(0xFFD6D0C8);
  static const gold = Color(0xFFB8861E);
  static const goldPale = Color(0xFFFBF4E6);
  static const logoutRed = Color(0xFFDC2626);
}

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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
    _model.switchValue1 ??= true;
    _model.switchValue2 ??= true;
    _loadProfile();
  }

  /// Derive subscription and upgrade-card state from user profile rc_subscription_status / rc_subscription_plan.
  void _applySubscriptionFromProfile(Map<String, dynamic> data) {
    final rcStatus = (data['rc_subscription_status'] ?? data['rc_subscription_Status'])
        ?.toString()
        .trim()
        .toLowerCase();
    final rcPlan = (data['rc_subscription_plan'] ?? data['rc_subscription_Plan'])
        ?.toString()
        .trim()
        .toLowerCase();
    final isWeeklyPlan = rcPlan != null && rcPlan.isNotEmpty && (rcPlan.contains('week'));
    final isMonthlyPlan = rcPlan != null && rcPlan.isNotEmpty && rcPlan.contains('month') && !rcPlan.contains('week');
    final isCanceled = rcStatus == 'canceled' || rcStatus == 'cancelled';
    _model.isSubscribedFromRC = rcStatus == 'active' || rcStatus == 'trial';
    _model.showUpgradeCardFromRC = isWeeklyPlan && !isCanceled;
    if (!_model.isSubscribedFromRC || isCanceled) {
      _model.subscriptionRowLabel = 'Free';
    } else if (rcStatus == 'trial') {
      _model.subscriptionRowLabel = 'Trial';
    } else if (isMonthlyPlan) {
      _model.subscriptionRowLabel = 'Monthly';
    } else if (isWeeklyPlan) {
      _model.subscriptionRowLabel = 'Weekly';
    } else {
      _model.subscriptionRowLabel = 'Active';
    }
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
      final data = await BackendClient.getUserProfile(userId);
      if (mounted) {
        setState(() {
          _model.profileData = data;
          _model.profileLoading = false;
          _model.profileError = null;
          _model.switchValue1 = _parseBool(data['is_MorningTime_Reminder'], true);
          _model.switchValue2 = _parseBool(data['is_BedTime_Reminder'], true);
          _applySubscriptionFromProfile(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _model.profileLoading = false;
          _model.profileError = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
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
    await SupabaseService.signOut();
    if (mounted) context.go('/login');
  }

  bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return defaultValue;
  }

  String _formatSpeed(dynamic speed) {
    if (speed == null) return 'Normal (1.0x)';
    final s = speed.toString().toLowerCase();
    if (s == 'slow') return 'Slow (0.85x)';
    if (s == 'normal') return 'Normal (1.0x)';
    if (s == 'fast') return 'Fast (1.15x)';
    if (s == 'very_fast') return 'Very Fast (1.35x)';
    return 'Normal (1.0x)';
  }

  String _getSpeedValue(dynamic speed) {
    if (speed == null) return 'normal';
    final s = speed.toString().toLowerCase();
    if (s == 'slow' || s == 'normal' || s == 'fast' || s == 'very_fast') return s;
    return 'normal';
  }

  Future<void> _updateProfileAndReload(Map<String, dynamic> updates) async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      await BackendClient.updateUserProfile(
        userId,
        speed: updates['speed'] as String?,
        isMorningReminder: updates['is_MorningTime_Reminder'] as bool?,
        isBedtimeReminder: updates['is_BedTime_Reminder'] as bool?,
        name: updates['name'] as String?,
        dreamPlace: updates['dream_place'] as String?,
        energyWord: updates['energy_word'] as String?,
        someoneYouLove: updates['lovedOne'] as String?,
      );
      if (mounted) _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}')),
        );
      }
    }
  }

  Future<void> _onMorningReminderChanged(bool value) async {
    setState(() => _model.switchValue1 = value);
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      await BackendClient.updateUserProfile(userId, isMorningReminder: value);
      if (mounted) AppToast.success(context, 'Morning reminder ${value ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (mounted) {
        setState(() => _model.switchValue1 = !value);
        AppToast.error(context, 'Failed to update: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}');
      }
    }
  }

  Future<void> _onBedtimeReminderChanged(bool value) async {
    setState(() => _model.switchValue2 = value);
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      await BackendClient.updateUserProfile(userId, isBedtimeReminder: value);
      if (mounted) AppToast.success(context, 'Bedtime reminder ${value ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (mounted) {
        setState(() => _model.switchValue2 = !value);
        AppToast.error(context, 'Failed to update: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}');
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
            .toList() ?? [];
        if (list.isEmpty) {
          if (mounted) AppToast.info(context, 'Create a story first before re-recording your voice.');
          return;
        }
        list.sort((a, b) {
          final aAt = a['last_played'] ?? a['last_played_at'] ?? a['created_at'] ?? a['id'] ?? 0;
          final bAt = b['last_played'] ?? b['last_played_at'] ?? b['created_at'] ?? b['id'] ?? 0;
          if (aAt == bAt) return 0;
          return bAt.toString().compareTo(aAt.toString());
        });
        Map<String, dynamic>? story;
        if (storyId != null) {
          for (final s in list) {
            final id = s['id'] is int ? s['id'] as int : int.tryParse(s['id']?.toString() ?? '');
            if (id == storyId) {
              story = s;
              break;
            }
          }
        }
        story ??= list.first;
        storyId = story['id'] is int ? story['id'] as int : int.tryParse(story['id']?.toString() ?? '');
        storyContent = (story['story'] ?? story['content'])?.toString().trim();
      }

      if (storyId == null || storyContent == null || storyContent.isEmpty) {
        if (mounted) AppToast.info(context, 'No story content found. Create a story first.');
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

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    final displayName =
        (_model.profileData?['name']?.toString() ?? '').trim().isNotEmpty
            ? (_model.profileData!['name'] ?? '').toString().trim()
            : (user?.userMetadata?['full_name']?.toString() ??
                user?.email?.split('@').first ??
                'User');
    final dreamLocation =
        _model.profileData?['dream_place']?.toString() ??
        _model.profileData?['Dream_Place']?.toString() ??
        '—';
    final energyWord =
        _model.profileData?['energy_word']?.toString() ??
        _model.profileData?['Energy_Word']?.toString() ??
        'Powerful';
    final someoneYouLove =
        _model.profileData?['lovedOne']?.toString() ??
        _model.profileData?['someoneYouLove']?.toString() ??
        '—';
    final email = _model.profileData?['email']?.toString() ?? user?.email ?? '—';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _ProfileColors.surface,
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
                          style: GoogleFonts.outfit(fontSize: 13, color: _ProfileColors.inkSoft),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(displayName, dreamLocation, energyWord),
                            const SizedBox(height: 24),
                            _buildStats(),
                            const SizedBox(height: 24),
                            _buildSettingsSection('VOICE', items: [
                              ('Re-record My Voice', '→', () => _handleReRecordVoice()),
                              ('Narration Speed', '${_formatSpeed(_model.profileData?['speed'])} →', () async {
                                final userId = await SupabaseService.getCurrentUserTableId();
                                if (userId == null || !mounted) return;
                                showNarrationSpeedModal(
                                  context,
                                  userId: userId,
                                  currentSpeed: _getSpeedValue(_model.profileData?['speed']),
                                ).then((newSpeed) {
                                  if (mounted) {
                                    if (newSpeed != null) AppToast.success(context, 'Narration speed updated');
                                    _loadProfile();
                                  }
                                });
                              }),
                            ]),
                            const SizedBox(height: 24),
                            _buildSettingsSection('PERSONALIZATION', items: [
                              ('Your Name', '$displayName →', () async {
                                final userId = await SupabaseService.getCurrentUserTableId();
                                if (userId == null || !mounted) return;
                                showYourNameModal(
                                  context,
                                  userId: userId,
                                  currentName: displayName,
                                ).then((newName) {
                                  if (mounted) {
                                    if (newName != null) AppToast.success(context, 'Name updated');
                                    _loadProfile();
                                  }
                                });
                              }),
                              ('Dream Location', '$dreamLocation →', () async {
                                final userId = await SupabaseService.getCurrentUserTableId();
                                if (userId == null || !mounted) return;
                                showDreamLocationModal(
                                  context,
                                  userId: userId,
                                  currentLocation: dreamLocation,
                                ).then((newLocation) {
                                  if (mounted) {
                                    if (newLocation != null) AppToast.success(context, 'Dream location updated');
                                    _loadProfile();
                                  }
                                });
                              }),
                              ('Energy Word', '$energyWord →', () async {
                                final userId = await SupabaseService.getCurrentUserTableId();
                                if (userId == null || !mounted) return;
                                showEnergyWordModal(
                                  context,
                                  userId: userId,
                                  currentWord: energyWord,
                                ).then((newWord) {
                                  if (mounted) {
                                    if (newWord != null) AppToast.success(context, 'Energy word updated');
                                    _loadProfile();
                                  }
                                });
                              }),
                              ('Someone You Love', '$someoneYouLove →', () async {
                                final userId = await SupabaseService.getCurrentUserTableId();
                                if (userId == null || !mounted) return;
                                showSomeoneYouLoveModal(
                                  context,
                                  userId: userId,
                                  currentValue: someoneYouLove == '—' ? '' : someoneYouLove,
                                ).then((newValue) {
                                  if (mounted) {
                                    if (newValue != null) AppToast.success(context, 'Updated');
                                    _loadProfile();
                                  }
                                });
                              }),
                            ]),
                            const SizedBox(height: 24),
                            _buildRemindersSection(),
                            const SizedBox(height: 24),
                            _buildSettingsSection('ACCOUNT', items: [
                              ('Email', '$email →', () async {
                                final userId = await SupabaseService.getCurrentUserTableId();
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
                              }),
                              ('Password', 'Change →', () async {
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
                              }),
                              ('Subscription', '${_model.subscriptionRowLabel} →', () => context.go(SubscriptionWidget.routePath)),
                            ]),
                            if (_showUpgradeCard) ...[
                              const SizedBox(height: 24),
                              _buildUpgradeCard(),
                              const SizedBox(height: 24),
                            ],
                            const SizedBox(height: 24),
                            _buildSettingsSection('SUPPORT', items: [
                              ('Help & FAQ', '→', null),
                              ('Contact Us', '→', null),
                              ('Terms of Service', '→', null),
                              ('Privacy Policy', '→', null),
                            ]),
                            _buildLogoutSection(),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String dreamLocation, String energyWord) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: _ProfileColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dreamLocation · $energyWord',
            style: GoogleFonts.outfit(fontSize: 12, color: _ProfileColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final complete = _model.profileData?['complete']?.toString() ?? '0';
    final dayStreak = _model.profileData?['day_streak']?.toString() ?? '0';
    final active = _model.profileData?['active']?.toString() ?? '0';
    return Row(
      children: [
        Expanded(child: _statCard(complete, 'COMPLETE')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(dayStreak, 'DAY STREAK')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(active, 'ACTIVE')),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        border: Border.all(color: _ProfileColors.stone),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _ProfileColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _ProfileColors.inkSoft,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    String title, {
    required List<(String, String, VoidCallback?)> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _ProfileColors.inkMid,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 14),
        ...items.asMap().entries.map((e) {
          final (label, value, onTap) = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Pressable(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _ProfileColors.surface,
                    border: Border.all(color: _ProfileColors.stone),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _ProfileColors.ink,
                        ),
                      ),
                      Text(
                        value,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _ProfileColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSettingWithToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        border: Border.all(color: _ProfileColors.stone),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _ProfileColors.ink,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _ProfileColors.gold,
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _ProfileColors.stoneMid,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    final morningEnabled = _model.switchValue1 ?? true;
    final bedtimeEnabled = _model.switchValue2 ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REMINDERS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _ProfileColors.inkMid,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        _buildSettingWithToggle(
          'Morning Reminder',
          morningEnabled,
          (v) => _onMorningReminderChanged(v),
        ),
        if (morningEnabled) ...[
          const SizedBox(height: 8),
          _buildSettingItem(
            'Morning Time',
          '${formatTimeFromIso(_model.profileData?['morningTime_Reminder'] ?? _model.profileData?['morning_time'] ?? _model.profileData?['morning_Time'])} →',
          subtitle: 'Daily story notification',
          onTap: () async {
            final userId = await SupabaseService.getCurrentUserTableId();
            if (userId == null || !mounted) return;
            showTimePickerModal(
              context,
              title: 'Morning Reminder Time',
              subtitle: 'When should we send your daily story?',
              currentTime: formatTimeFromIso(_model.profileData?['morningTime_Reminder'] ?? _model.profileData?['morning_time'] ?? _model.profileData?['morning_Time']),
              userId: userId,
              fieldType: TimeFieldType.morning,
            ).then((newTime) {
              if (mounted) {
                if (newTime != null) AppToast.success(context, 'Morning reminder time updated');
                _loadProfile();
              }
            });
          },
        ),
        ],
        const SizedBox(height: 8),
        _buildSettingWithToggle(
          'Bedtime Reminder',
          bedtimeEnabled,
          (v) => _onBedtimeReminderChanged(v),
        ),
        if (bedtimeEnabled) ...[
          const SizedBox(height: 8),
          _buildSettingItem(
            'Bedtime Time',
          '${formatTimeFromIso(_model.profileData?['bedTime_Reminder'] ?? _model.profileData?['bedtime_time'] ?? _model.profileData?['bedtime_Time'])} →',
          subtitle: 'Evening reflection prompt',
          onTap: () async {
            final userId = await SupabaseService.getCurrentUserTableId();
            if (userId == null || !mounted) return;
            showTimePickerModal(
              context,
              title: 'Bedtime Reminder Time',
              subtitle: 'When should we send your evening reflection?',
              currentTime: formatTimeFromIso(_model.profileData?['bedTime_Reminder'] ?? _model.profileData?['bedtime_time'] ?? _model.profileData?['bedtime_Time']),
              userId: userId,
              fieldType: TimeFieldType.bedtime,
            ).then((newTime) {
              if (mounted) {
                if (newTime != null) AppToast.success(context, 'Bedtime reminder time updated');
                _loadProfile();
              }
            });
          },
        ),
        ],
      ],
    );
  }

  Widget _buildSettingItem(String label, String value, {String? subtitle, VoidCallback? onTap}) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _ProfileColors.ink,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: _ProfileColors.inkSoft,
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: _ProfileColors.inkSoft,
          ),
        ),
      ],
    );
    final child = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        border: Border.all(color: _ProfileColors.stone),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
    if (onTap != null) {
      return Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      );
    }
    return child;
  }

  Widget _buildUpgradeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4E5F9C), Color(0xFF2A3B5F)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 18,
            child: Text(
              '✓',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPGRADE TO MONTHLY PLAN',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save 30% \nBy Switching to the Monthly Plan',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Billed monthly · Cancel anytime',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Pressable(
                onTap: () => context.go(SubscriptionWidget.routePath),
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _isSubscribed ? 'Upgrade to Monthly' : 'Start Free Trial',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _isSubscribed => _model.isSubscribedFromRC;

  bool get _showUpgradeCard => _model.showUpgradeCardFromRC;

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _ProfileColors.stone)),
            ),
            padding: const EdgeInsets.only(top: 24),
            child: TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: _ProfileColors.logoutRed,
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ProfileColors.logoutRed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: _ProfileColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
