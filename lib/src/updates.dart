import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'platform/platform.dart' as platform;

/// A newer build of the web app than the one running.
@immutable
class RiviumUpdateInfo {
  const RiviumUpdateInfo({required this.running, required this.latest, required this.required, this.notes = const {}});

  /// The version running in this page ("0.5.1").
  final String running;

  /// The version now on the server.
  final String latest;

  /// The running version is below `minimum` of update.json: the app must reload to go on.
  final bool required;

  /// "What's new", by language code (from update.json).
  final Map<String, String> notes;

  /// The notes for [languageCode], else English, else any.
  String? notesFor(String languageCode) =>
      notes[languageCode] ?? notes['en'] ?? (notes.isEmpty ? null : notes.values.first);

  @override
  bool operator ==(Object other) =>
      other is RiviumUpdateInfo &&
      other.running == running &&
      other.latest == latest &&
      other.required == required &&
      mapEquals(other.notes, notes);

  @override
  int get hashCode => Object.hash(running, latest, required, Object.hashAllUnordered(notes.entries.map((e) => '${e.key}=${e.value}')));
}

/// New versions of a Flutter web app. Start it once (`RiviumWebUpdates.start()` in main); [RiviumUpdatePrompt] and
/// [RiviumUpdateGate] show what it finds. Does nothing outside the web.
///
/// The running version is `version.json` (Flutter writes it) read when the app starts; it is read again when the app
/// comes back to the front and every [start]'s `every`. An optional `update.json` next to it:
/// `{"minimum": "0.6.0", "notes": {"en": "…"}}` — below `minimum` the update is required.
abstract final class RiviumWebUpdates {
  static final _available = ValueNotifier<RiviumUpdateInfo?>(null);
  static String? _running;
  static Timer? _timer;
  static bool _started = false;

  /// For tests: reads a file next to the app.
  @visibleForTesting
  static Future<String?> Function(String path) fetch = platform.fetchText;

  /// The newer version, or null while this one is the newest.
  static ValueListenable<RiviumUpdateInfo?> get available => _available;

  /// The version running in this page (from version.json when the app started), null before [start] has read it or
  /// outside the web. Use it as the "installed" version of your own update logic: `package_info_plus` reads
  /// version.json from the server, which is already the new one after a deploy.
  static String? get runningVersion => _running;

  /// Starts watching: once now, when the app comes back to the front, and every [every].
  static Future<void> start({Duration every = const Duration(minutes: 10)}) async {
    if (!kIsWeb || _started) return;
    _started = true;
    await checkNow();
    platform.onVisible(() => unawaited(checkNow()));
    _timer = Timer.periodic(every, (_) => unawaited(checkNow()));
  }

  /// Checks once.
  static Future<void> checkNow() async {
    final version = _version(await fetch('version.json'));
    if (version == null) return; // offline or not served: try next time
    _running ??= version;
    final running = _running!;
    final policy = _policy(await fetch('update.json'));
    final required = policy.minimum != null && compareVersions(running, policy.minimum!) < 0;
    if (version == running && !required) {
      _available.value = null;
      return;
    }
    _available.value = RiviumUpdateInfo(running: running, latest: version, required: required, notes: policy.notes);
  }

  /// Loads the new version.
  static void reload() => platform.reloadPage();

  @visibleForTesting
  static void reset() {
    _timer?.cancel();
    _timer = null;
    _started = false;
    _running = null;
    _available.value = null;
    fetch = platform.fetchText;
  }

  /// "0.5.1+11" from Flutter's version.json.
  static String? _version(String? text) {
    if (text == null) return null;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final version = json['version'] as String?;
      if (version == null) return null;
      final build = json['build_number'];
      return build == null || '$build'.isEmpty ? version : '$version+$build';
    } catch (_) {
      return null;
    }
  }

  static ({String? minimum, Map<String, String> notes}) _policy(String? text) {
    if (text == null) return (minimum: null, notes: const {});
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final notes = (json['notes'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, '$v'));
      return (minimum: json['minimum'] as String?, notes: notes);
    } catch (_) {
      return (minimum: null, notes: const {});
    }
  }
}

/// Compares "1.2.3+4" style versions: negative when [a] is older than [b]. The build number counts only when the
/// versions are equal.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  int build(String v) => v.contains('+') ? int.tryParse(v.split('+').last) ?? 0 : 0;
  return build(a) - build(b);
}
