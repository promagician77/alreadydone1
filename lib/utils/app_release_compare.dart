/// Compare Flutter [PackageInfo.version] + build against server latest (same scheme).
library;

/// Dot-separated numeric prefixes per segment (e.g. `1.0.8-rc` → 1,0,8).
List<int> numericVersionParts(String version) {
  final t = version.trim();
  if (t.isEmpty) return const <int>[0, 0, 0];
  return t.split('.').map((segment) {
    final m = RegExp(r'^(\d+)').firstMatch(segment.trim());
    return int.tryParse(m?.group(1) ?? '') ?? 0;
  }).toList();
}

/// Lexicographic compare on numeric version components.
int compareNumericVersionStrings(String a, String b) {
  final pa = numericVersionParts(a);
  final pb = numericVersionParts(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

/// True if [latestVersion]/[latestBuild] is strictly newer than [currentVersion]/[currentBuild].
///
/// When [latestVersion] is null or empty, falls back to build-only comparison (legacy servers).
bool isRemoteAppReleaseNewer({
  required String? latestVersion,
  required int latestBuild,
  required String currentVersion,
  required int currentBuild,
}) {
  final lv = latestVersion?.trim();
  if (lv == null || lv.isEmpty) {
    return latestBuild > currentBuild;
  }
  final cv = currentVersion.trim();
  final byVersion = compareNumericVersionStrings(lv, cv);
  if (byVersion != 0) return byVersion > 0;
  return latestBuild > currentBuild;
}

/// Parses `1.0.8+2` from update-dismiss storage.
(String version, int build) parseVersionPlusFingerprint(String raw) {
  final s = raw.trim();
  final idx = s.lastIndexOf('+');
  if (idx > 0 && idx < s.length - 1) {
    final tail = s.substring(idx + 1).trim();
    final b = int.tryParse(tail);
    if (b != null) {
      return (s.substring(0, idx).trim(), b);
    }
  }
  return (s, 0);
}

/// True if server latest is newer than a dismissed `version+build` fingerprint.
bool isRemoteNewerThanFingerprint({
  required String? latestVersion,
  required int latestBuild,
  required String dismissedFingerprint,
}) {
  final (dVer, dBuild) = parseVersionPlusFingerprint(dismissedFingerprint);
  return isRemoteAppReleaseNewer(
    latestVersion: latestVersion,
    latestBuild: latestBuild,
    currentVersion: dVer,
    currentBuild: dBuild,
  );
}
