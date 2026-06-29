/// Parses [day_streak] from user profile JSON (shared across home, rating, etc.).
int parseDayStreak(dynamic rawStreak) {
  if (rawStreak is int) return rawStreak;
  if (rawStreak is num) return rawStreak.round();
  final s = rawStreak?.toString().trim() ?? '0';
  return int.tryParse(s) ??
      int.tryParse(double.tryParse(s)?.round().toString() ?? '0') ??
      0;
}
