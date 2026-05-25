import '/pages/player/player_constants.dart';

/// Story duration, voice, and display helpers for the player.
abstract final class PlayerStoryUtils {
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static int? parseDurationSeconds(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final clock = RegExp(r'^(\d+):(\d{2})$').firstMatch(text);
    if (clock != null) {
      final minutes = int.tryParse(clock.group(1)!);
      final seconds = int.tryParse(clock.group(2)!);
      if (minutes != null && seconds != null) {
        return minutes * 60 + seconds;
      }
    }
    return num.tryParse(text)?.round();
  }

  static Duration expectedDuration(String? durationLabel) {
    final seconds = parseDurationSeconds(durationLabel);
    if (seconds == null || seconds <= 0) return Duration.zero;
    return Duration(seconds: seconds);
  }

  static Duration effectiveDuration({
    required String? durationLabel,
    required Duration playbackDuration,
  }) {
    final expected = expectedDuration(durationLabel);
    return expected > playbackDuration ? expected : playbackDuration;
  }

  static String? presetVoiceName(String voiceId) {
    final id = voiceId.trim();
    for (final t in PlayerConstants.presetVoices) {
      if (t.$1 == id) return t.$2;
    }
    return null;
  }

  static String voiceLabel(String? voiceId) {
    final id = voiceId?.trim();
    if (id == null || id.isEmpty) return 'In your voice';
    final name = presetVoiceName(id);
    return name != null ? "$name's voice" : 'In your voice';
  }

  static String voiceDropdownValue(String? voiceId) {
    final id = voiceId?.trim();
    if (id == null || id.isEmpty) return PlayerConstants.voiceDropdownMyVoice;
    for (final t in PlayerConstants.presetVoices) {
      if (t.$1 == id) return id;
    }
    return PlayerConstants.voiceDropdownMyVoice;
  }

  static String categoryHeaderLine(String? categoryLabel) {
    final raw = (categoryLabel ?? 'Love').trim();
    final lower = raw.toLowerCase();
    const doneSuffix = '· already done';
    const completeSuffix = '· already complete';
    String withoutSuffix = raw;
    if (lower.endsWith(doneSuffix)) {
      withoutSuffix = raw.substring(0, raw.length - doneSuffix.length).trim();
    } else if (lower.endsWith(completeSuffix)) {
      withoutSuffix =
          raw.substring(0, raw.length - completeSuffix.length).trim();
    }
    withoutSuffix = withoutSuffix.replaceAll(RegExp(r'\s*·\s*$'), '').trim();
    final category = withoutSuffix.isEmpty ? 'Love' : withoutSuffix;
    return '${category.toUpperCase()} · ALREADY DONE';
  }

  static String voiceCacheKey(int storyId, String voiceId) => '${storyId}_$voiceId';

  static String? parseVoiceIdFromMap(Map<String, dynamic> map) {
    final raw = map['voice_id'] ?? map['voice_Id'];
    if (raw == null) return null;
    if (raw is String) return raw.trim().isEmpty ? null : raw.trim();
    if (raw is Map) {
      final id = raw['id'] ?? raw['voice_id'];
      final s = id?.toString().trim();
      return (s != null && s.isNotEmpty) ? s : null;
    }
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String formatSleepSpeed(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    final s = value.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

  static String normalSpeedLabel(double rate) {
    if (rate == 1.0) return 'Normal (1.0x)';
    return '${formatSleepSpeed(rate)}x';
  }

  static String sleepSpeedLabel(double rate) => normalSpeedLabel(rate);

  static bool canUseSleepMode(String? status, String? plan) {
    final s = (status ?? '').toString().toLowerCase().trim();
    final p = (plan ?? '').toString().toLowerCase().trim();
    if (!PlayerConstants.sleepModeAllowedStatuses.contains(s)) return false;
    return PlayerConstants.sleepModeAllowedPlans.contains(p);
  }

  static int visibleWaveBars({
    required Duration position,
    required Duration effectiveDuration,
    required int totalBars,
  }) {
    final dur = effectiveDuration.inMilliseconds;
    if (dur <= 0) return 0;
    final pos = position.inMilliseconds;
    final ratio = (pos / dur).clamp(0.0, 1.0);
    return (ratio * totalBars).round().clamp(0, totalBars);
  }

  static String durationLabelFromStory(Map<String, dynamic> story) {
    final duration = story['play_length'] ?? story['duration'];
    int secs = 0;
    if (duration != null) {
      if (duration is int) {
        secs = duration;
      } else if (duration is num) {
        secs = duration.round();
      } else {
        secs = int.tryParse(duration.toString()) ?? 0;
      }
    }
    return formatDuration(secs);
  }
}
