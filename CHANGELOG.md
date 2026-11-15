# Changelog

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
