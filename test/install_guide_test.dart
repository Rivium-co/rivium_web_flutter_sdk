import 'package:rivium_web/rivium_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_context_test.dart' show iPhoneSafari, iPhoneInstagram, androidChrome;

Widget app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

RiviumWebContext ctx(String ua, {bool installed = false, bool prompt = false}) =>
    RiviumWebContext.fromUserAgent(ua, installed: installed, canPromptInstall: prompt);

void main() {
  setUp(RiviumInstallGuide.resetDismissed);

  testWidgets('iPhone Safari: header, features, three steps with the iPhone controls', (tester) async {
    await tester.pumpWidget(app(RiviumInstallGuide(appName: 'Lino', context: ctx(iPhoneSafari))));
    await tester.pumpAndSettle();
    expect(find.text('Lino'), findsOneWidget);
    expect(find.text('Install the app'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Tap the Share button'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
    expect(find.text('Add to Home Screen'), findsOneWidget);
    expect(find.text('Open Lino from its new icon'), findsOneWidget);
    expect(find.text('Install'), findsNothing);
  });

  testWidgets('installed: nothing at all', (tester) async {
    await tester.pumpWidget(app(RiviumInstallGuide(appName: 'Lino', context: ctx(iPhoneSafari, installed: true))));
    expect(find.text('Lino'), findsNothing);
  });

  testWidgets('Android with the install prompt: an Install button instead of steps', (tester) async {
    await tester.pumpWidget(app(RiviumInstallGuide(appName: 'Lino', context: ctx(androidChrome, prompt: true))));
    await tester.pumpAndSettle();
    expect(find.text('Install'), findsOneWidget);
    expect(find.text('Tap the browser menu ⋮'), findsNothing);
  });

  testWidgets('in-app browser: names the app, offers Copy link', (tester) async {
    await tester.pumpWidget(app(RiviumInstallGuide(appName: 'Lino', context: ctx(iPhoneInstagram))));
    await tester.pumpAndSettle();
    expect(find.text('This page is open inside Instagram'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
  });

  testWidgets('Not now hides it', (tester) async {
    await tester.pumpWidget(app(RiviumInstallGuide(appName: 'Lino', context: ctx(iPhoneSafari))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pump();
    expect(find.text('Lino'), findsNothing);
  });
}
