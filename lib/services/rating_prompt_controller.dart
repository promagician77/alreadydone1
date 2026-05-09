import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '/flutter_flow/nav/nav.dart';
import '/pages/player/player_modals/rating_prompt_modal.dart';
import '/services/backend_client.dart';
import '/services/rating_prompt_prefs.dart';
import '/services/supabase_service.dart';
import '/utils/platform_utils.dart';

enum RatingPromptMoment { storyPlaybackComplete, deepenPlaybackComplete }

class RatingPromptController {
  RatingPromptController._();

  static bool _evaluating = false;
  static bool _dialogOpen = false;
  static int? _debugForcedDaysSinceStart;

  static void setDebugForcedDaysSinceStart(int? days) {
    _debugForcedDaysSinceStart = days;
  }

  static Future<void> evaluateAfterPlaybackComplete({
    bool skipForSleepSession = false,
    RatingPromptMoment moment = RatingPromptMoment.storyPlaybackComplete,
  }) async {
    // Keep web disabled in normal flow, but allow explicit debug forcing
    // so QA can test modal behavior on localhost/web builds.
    if (kIsWeb && _debugForcedDaysSinceStart == null) return;
    if (skipForSleepSession) return;
    if (moment != RatingPromptMoment.storyPlaybackComplete &&
        moment != RatingPromptMoment.deepenPlaybackComplete) {
      return;
    }
    if (_evaluating || _dialogOpen) return;

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return;

    if (await RatingPromptPrefs.loadDeclinedPermanent()) return;
    if (await RatingPromptPrefs.allTiersResolved()) return;
    if ((await RatingPromptPrefs.loadShownCountTotal()) >= 3) return;
    if (await RatingPromptPrefs.isGloballyRateLimitedNow()) return;
    final snoozeUntil = await RatingPromptPrefs.loadSnoozeUntil();
    if (snoozeUntil != null && snoozeUntil.isAfter(DateTime.now().toUtc())) {
      return;
    }

    _evaluating = true;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      final daysSinceStart = _daysSinceStartFromProfile(profile);
      if (daysSinceStart < 7) return;
      final flags = await RatingPromptPrefs.loadTierFlags();
      final variant = RatingPromptPrefs.pickVariant(
        daysSinceStart,
        flags.t1,
        flags.t2,
        flags.t3,
      );
      if (variant == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = appNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        unawaited(_tryShowDialog(ctx, variant));
      });
    } catch (e) {
      debugPrint('RatingPromptController: $e');
    } finally {
      _evaluating = false;
    }
  }

  static int _daysSinceStartFromProfile(Map<String, dynamic> profile) {
    final forced = _debugForcedDaysSinceStart;
    if (forced != null && forced >= 0) return forced;

    int readInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    final first = readInt(profile['days_since_first_story']);
    if (first > 0) return first;
    return readInt(profile['days_since_signup']);
  }

  static Future<void> _tryShowDialog(
    BuildContext context,
    RatingPromptVariant variant,
  ) async {
    if (!context.mounted) return;
    if (_dialogOpen) return;

    _dialogOpen = true;
    try {
      await RatingPromptPrefs.incrementShownCountTotal();
      await RatingPromptPrefs.setLastShownNow();
      if (!context.mounted) return;
      await showRatingPromptModal(
        context,
        variant: variant,
        onRate: () {
          unawaited(_handleRate(variant));
        },
        onMaybeLater: () {
          unawaited(RatingPromptPrefs.snoozeFromNow(variant));
        },
        onNoThanks: () {
          unawaited(RatingPromptPrefs.setDeclinedPermanent());
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  static Future<void> _handleRate(RatingPromptVariant variant) async {
    await _openReviewFlow();
    await RatingPromptPrefs.clearSnooze();
    await RatingPromptPrefs.markVariantResolved(variant);
  }

  static Future<void> _openReviewFlow() async {
    if (kIsWeb) return;
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
    } catch (e) {
      debugPrint('RatingPrompt: requestReview failed: $e');
    }
    await _openStoreListingFallback();
  }

  static const _androidPackageId = 'com.mycompany.alreadyapp';

  static Future<void> _openStoreListingFallback() async {
    try {
      final payload = await BackendClient.fetchMobileAppUpdateInfo();
      if (isIOS) {
        final iosUrl = payload?.iosStoreUrl?.trim();
        String? appStoreId;
        if (iosUrl != null && iosUrl.isNotEmpty) {
          final m = RegExp(r'/id(\d+)').firstMatch(iosUrl);
          appStoreId = m?.group(1);
        }
        try {
          await InAppReview.instance.openStoreListing(appStoreId: appStoreId);
          if (appStoreId != null) return;
        } catch (e) {
          debugPrint('RatingPrompt: openStoreListing failed: $e');
        }
        if (iosUrl != null && iosUrl.isNotEmpty) {
          final u = Uri.tryParse(iosUrl);
          if (u != null) {
            await launchUrl(u, mode: LaunchMode.platformDefault);
          }
        }
        return;
      }
      if (isAndroid) {
        final play =
            payload?.androidStoreUrl?.trim().isNotEmpty == true
                ? payload!.androidStoreUrl!.trim()
                : 'https://play.google.com/store/apps/details?id=$_androidPackageId';
        final u = Uri.tryParse(play);
        if (u != null) {
          await launchUrl(u, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('RatingPrompt: store fallback failed: $e');
    }
  }
}
