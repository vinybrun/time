import '../../l10n/app_localizations.dart';
import '../data/api_client.dart';

/// Map backend errors to calm, localized messages.
String messageForError(Object error, AppL10n l) {
  if (error is ApiException) {
    final d = error.detail.toLowerCase();
    if (error.statusCode == 401) return l.errorInvalidCredentials;
    if (d.contains('not valid') || d.contains('invalid code') || d.contains('expired')) {
      return l.errorInvalidCode;
    }
    if (d.contains('already exists')) return l.errorEmailTaken;
    if (d.contains('current password')) return l.errorWrongCurrentPassword;
    if (d.contains('password')) return l.errorPasswordShort;
    return l.errorGeneric;
  }
  return l.errorGeneric;
}
