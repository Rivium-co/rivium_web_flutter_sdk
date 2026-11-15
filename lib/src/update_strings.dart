/// The texts of [RiviumUpdatePrompt] and [RiviumUpdateGate]. English is built in.
class RiviumUpdateStrings {
  const RiviumUpdateStrings({
    required this.title,
    required this.version,
    required this.body,
    required this.requiredTitle,
    required this.requiredBody,
    required this.whatsNew,
    required this.reload,
    required this.later,
    this.versionBuild,
  });

  final String title;

  /// "Version {v}".
  final String Function(String version) version;

  /// "Version {v} (build {b})": shown when the new deploy has the same version as the running one.
  final String Function(String version, String build)? versionBuild;
  final String body;
  final String requiredTitle;
  final String requiredBody;
  final String whatsNew;
  final String reload;
  final String later;

  static final en = RiviumUpdateStrings(
    title: 'New version available',
    version: (v) => 'Version $v',
    body: 'Reload to get the latest improvements. It takes a second.',
    requiredTitle: 'Update required',
    requiredBody: 'This version no longer works. Reload to continue; nothing you saved is lost.',
    whatsNew: 'What’s new',
    reload: 'Reload',
    later: 'Later',
    versionBuild: (v, b) => 'Version $v (build $b)',
  );

  static RiviumUpdateStrings forLanguage(String languageCode) => en;
}
