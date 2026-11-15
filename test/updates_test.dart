import 'package:rivium_web/rivium_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server with a version.json and, optionally, an update.json.
class FakeServer {
  String version = '{"app_name":"team","version":"0.5.1","build_number":"11"}';
  String? update;
  Future<String?> fetch(String path) async => path == 'version.json' ? version : (path == 'update.json' ? update : null);
}

Widget app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  late FakeServer server;
  setUp(() {
    RiviumWebUpdates.reset();
    RiviumUpdatePrompt.resetLater();
    server = FakeServer();
    RiviumWebUpdates.fetch = server.fetch;
  });

  test('the first read is the running version; a new deploy is offered', () async {
    await RiviumWebUpdates.checkNow();
    expect(RiviumWebUpdates.runningVersion, '0.5.1+11');
    expect(RiviumWebUpdates.available.value, isNull);

    server.version = '{"version":"0.5.2","build_number":"12"}';
    await RiviumWebUpdates.checkNow();
    final info = RiviumWebUpdates.available.value!;
    expect(info.running, '0.5.1+11');
    expect(info.latest, '0.5.2+12');
    expect(info.required, isFalse);
  });

  test('below update.json minimum the update is required, with its notes', () async {
    server.update = '{"minimum":"0.6.0","notes":{"en":"Faster sign-in","de":"Schneller anmelden"}}';
    await RiviumWebUpdates.checkNow();
    final info = RiviumWebUpdates.available.value!;
    expect(info.required, isTrue);
    expect(info.notesFor('de'), 'Schneller anmelden');
    expect(info.notesFor('it'), 'Faster sign-in');
  });

  test('offline or a broken file changes nothing', () async {
    await RiviumWebUpdates.checkNow();
    server.version = 'not json';
    await RiviumWebUpdates.checkNow();
    expect(RiviumWebUpdates.available.value, isNull);
    expect(RiviumWebUpdates.runningVersion, '0.5.1+11');
  });

  test('versions compare by number, then build', () {
    expect(compareVersions('0.5.1', '0.6.0'), lessThan(0));
    expect(compareVersions('0.10.0', '0.9.9'), greaterThan(0));
    expect(compareVersions('0.5.1+11', '0.5.1+12'), lessThan(0));
    expect(compareVersions('1.0.0', '1.0'), 0);
  });

  testWidgets('the prompt appears for a new version; Later hides it', (tester) async {
    await RiviumWebUpdates.checkNow();
    await tester.pumpWidget(app(const RiviumUpdatePrompt()));
    expect(find.text('New version available'), findsNothing);

    server.version = '{"version":"0.5.2","build_number":"12"}';
    await RiviumWebUpdates.checkNow();
    await tester.pumpAndSettle();
    expect(find.text('New version available'), findsOneWidget);
    expect(find.text('Version 0.5.2'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('New version available'), findsNothing);
  });

  testWidgets('a required update covers the app and cannot be dismissed', (tester) async {
    server.update = '{"minimum":"0.6.0","notes":{"en":"Faster sign-in"}}';
    await RiviumWebUpdates.checkNow();
    await tester.pumpWidget(MaterialApp(home: RiviumUpdateGate(child: const Scaffold(body: Text('work')))));
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Faster sign-in'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(find.text('work'), findsOneWidget); // still behind the blur
  });
}
