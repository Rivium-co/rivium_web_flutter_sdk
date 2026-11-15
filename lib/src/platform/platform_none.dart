import '../web_context.dart';

RiviumWebContext readContext() => RiviumWebContext.native;

Future<bool> promptInstall() async => false;

DateTime? dismissedUntil() => null;

void setDismissedUntil(DateTime until) {}
