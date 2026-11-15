import 'package:rivium_web/rivium_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The install guide in each situation, side by side. In your app, use
/// `const RiviumInstallGuide(appName: 'Your app')`: it picks the situation itself.
void main() {
  // New versions: checks version.json now, when the app comes back, and every 5 s here (10 min by default).
  RiviumWebUpdates.start(every: const Duration(seconds: 5));
  runApp(const Example());
}

const _iphone =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1';
const _iphone26 =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1';
const _instagram =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 350.0.0.0';
const _android = 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

const _brand = Color(0xFF1C72C8);
final _icon = Image.network('icons/Icon-192.png', fit: BoxFit.cover);

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    const name = 'Lino';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1C72C8)),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF1C72C8), brightness: Brightness.dark),
      themeMode: Uri.base.queryParameters['dark'] == '1' ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => RiviumUpdateGate(icon: _icon, accentColor: _brand, child: child!),
      home: Scaffold(
        appBar: AppBar(title: const Text('rivium_web')),
        body: ListView(
          children: [
            RiviumUpdatePrompt(icon: _icon, accentColor: _brand),
            const _Label('iPhone, Safari tab'),
            RiviumInstallGuide(appName: name, icon: _icon, accentColor: _brand, context: RiviumWebContext.fromUserAgent(_iphone, installed: false)),
            const _Label('iPhone, Safari 26 (Share under ⋯)'),
            RiviumInstallGuide(
              appName: name,
              icon: _icon,
              accentColor: _brand,
              context: RiviumWebContext.fromUserAgent(_iphone26, installed: false),
            ),
            const _Label('Android, the browser offers Install'),
            RiviumInstallGuide(
              appName: name,
              icon: _icon,
              accentColor: _brand,
              context: RiviumWebContext.fromUserAgent(_android, installed: false, canPromptInstall: true),
            ),
            const _Label('Inside Instagram'),
            RiviumInstallGuide(appName: name, icon: _icon, accentColor: _brand, context: RiviumWebContext.fromUserAgent(_instagram, installed: false)),
            const _Label('This browser (nothing when installed or on a computer)'),
            RiviumInstallGuide(appName: name),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}
