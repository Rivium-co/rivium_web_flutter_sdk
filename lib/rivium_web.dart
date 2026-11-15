/// Rivium Web: helpers for Flutter web apps that people install on their phone (PWA) — where the app runs, a
/// ready-made "Add to Home Screen" guide, and new versions (update prompt, required updates).
library;

export 'src/install_guide.dart' show RiviumInstallGuide;
export 'src/install_strings.dart' show RiviumInstallStrings;
export 'src/update_prompt.dart' show RiviumUpdateGate, RiviumUpdatePrompt;
export 'src/update_strings.dart' show RiviumUpdateStrings;
export 'src/updates.dart' show RiviumUpdateInfo, RiviumWebUpdates, compareVersions;
export 'src/web_context.dart' show RiviumInstallNeed, RiviumWeb, RiviumWebContext;
