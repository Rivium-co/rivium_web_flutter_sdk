# Changelog

## [0.3.0] - 2026-11-15

### Added
- `dart run rivium_web:setup`: a branded offline page (`web/offline.html`, Try again, reloads when the connection is
  back) from `web/manifest.json`, served by the root service worker `web/rivium-push-sw.js` when the app is opened
  with no network.

## [0.2.1] - 2026-11-15

### Changed
- `RiviumUpdatePrompt` and `RiviumUpdateGate` show the build ("Version 0.5.1 (build 13)") when the new deploy has the
  same version as the running one.
- `RiviumUpdateStrings.versionBuild` (optional): the text for that case.

## [0.2.0] - 2026-11-15

### Added
- New versions: `RiviumWebUpdates.start()` reads `version.json` when the app starts (the version running) and again
  when it comes back to the front and every 10 minutes. `RiviumUpdatePrompt` shows "New version available" with
  Reload and Later; `RiviumUpdateGate` covers the app with a required update when an optional `update.json` says
  `minimum` is newer than the running version, with "What's new" notes.
- `RiviumWebUpdates.runningVersion`: the version running in this page (`package_info_plus` on the web reads the
  server's version.json, already the new one after a deploy).

## [0.1.1] - 2026-11-15

### Changed
- iPhone and iPad steps follow Safari's layout: Safari 26 on iPhone (Share under ⋯ at the bottom), Safari up to 18 on
  iPhone (Share at the bottom), iPad (Share at the top). "In Safari's Share menu:" above the picture of the "Add to Home
  Screen" row, which is a picture, not a button; "scroll down if you don't see it, then tap Add".
- `RiviumWebContext.isIpad` and `safariVersion` (Safari 26 still reports iOS 18.6 in its user agent).

## [0.1.0] - 2026-11-15

### Added
- `RiviumInstallGuide`: shows how to install the web app where that is needed — iPhone and iPad Safari (Share › Add
  to Home Screen), Android (the browser's Install prompt, or its menu), an app's in-app browser (open in the browser,
  Copy link) — and nothing when installed, on a computer or in a native build. "Not now" for 7 days, the app's icon and brand colour.
- `RiviumWeb.context`: where the app runs (installed, iOS, Android, in-app browser) and what installing needs.
- `RiviumWeb.promptInstall()`: the browser's install prompt on Android.
