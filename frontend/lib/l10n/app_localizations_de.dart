// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppL10nDe extends AppL10n {
  AppL10nDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Time';

  @override
  String get focusTitle => 'Worauf liegt dein Fokus gerade?';

  @override
  String get historyTitle => 'Du kannst den Verlauf ändern';

  @override
  String get addEntry => 'Eintrag hinzufügen';

  @override
  String get category => 'Kategorie';

  @override
  String get startTime => 'Start';

  @override
  String get endTime => 'Ende';

  @override
  String get add => 'Hinzufügen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get running => 'jetzt';

  @override
  String get today => 'Heute';

  @override
  String totalLogged(int hours, int minutes) {
    return '${hours}h ${minutes}m erfasst';
  }

  @override
  String get noEntries =>
      'Noch keine Einträge. Wähle oben einen Fokus, um zu starten.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get name => 'Name';

  @override
  String get timezone => 'Zeitzone';

  @override
  String get language => 'Sprache';

  @override
  String get languageAuto => 'Automatisch';

  @override
  String get account => 'Konto';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get logout => 'Abmelden';

  @override
  String get madeBy => 'Gemacht von Viny';

  @override
  String get openSettings => 'Einstellungen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Konto erstellen';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get haveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get needAccount => 'Neu hier? Konto erstellen';

  @override
  String get verifyTitle => 'Prüfe deine E-Mails';

  @override
  String verifyHint(String email) {
    return 'Wir haben einen 6-stelligen Code an $email gesendet';
  }

  @override
  String get code => '6-stelliger Code';

  @override
  String get verify => 'Bestätigen';

  @override
  String get resendCode => 'Code erneut senden';

  @override
  String get welcomeTagline => 'Ein ruhiges Bild davon, wohin dein Tag geht.';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get errorInvalidCredentials => 'Ungültige E-Mail oder Passwort.';

  @override
  String get errorInvalidCode => 'Dieser Code ist ungültig oder abgelaufen.';

  @override
  String get errorEmailTaken =>
      'Es existiert bereits ein Konto mit dieser E-Mail.';

  @override
  String get errorPasswordShort =>
      'Das Passwort muss mindestens 8 Zeichen haben.';

  @override
  String get errorWrongCurrentPassword => 'Das aktuelle Passwort ist falsch.';

  @override
  String get passwordChanged => 'Passwort aktualisiert.';

  @override
  String get settingsSaved => 'Gespeichert.';

  @override
  String get savedOffline =>
      'Auf diesem Gerät gespeichert. Synchronisiert bei Verbindung.';

  @override
  String get catWork => 'Arbeit';

  @override
  String get catPersonalChores => 'Persönliche Aufgaben';

  @override
  String get catPersonalProjects => 'Persönliche Projekte';

  @override
  String get catLeisure => 'Freizeit';

  @override
  String get catRelationships => 'Beziehungen';

  @override
  String get catSelfMaintenance => 'Selbstfürsorge';

  @override
  String get catGrowth => 'Wachstum';

  @override
  String get catSleep => 'Schlaf';

  @override
  String get catUncategorized => 'Ohne Kategorie';

  @override
  String get entryOverlapNote =>
      'Einträge können sich überschneiden; der Kreis summiert jede Kategorie.';

  @override
  String get deleteEntryConfirm => 'Diesen Eintrag löschen?';

  @override
  String get downloadApk => 'Android-App herunterladen (.apk)';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetTitle => 'Passwort zurücksetzen';

  @override
  String get resetEmailHint =>
      'Gib deine E-Mail ein, wir senden dir einen Code.';

  @override
  String get sendResetCode => 'Code senden';

  @override
  String resetCodeHint(String email) {
    return 'Gib den an $email gesendeten Code ein und wähle ein neues Passwort.';
  }

  @override
  String get doReset => 'Passwort zurücksetzen';

  @override
  String get backToSignIn => 'Zurück zur Anmeldung';

  @override
  String get categories => 'Kategorien';

  @override
  String get addCategory => 'Kategorie hinzufügen';

  @override
  String get categoryName => 'Kategoriename';

  @override
  String get color => 'Farbe';

  @override
  String get rename => 'Umbenennen';

  @override
  String get yourData => 'Deine Daten';

  @override
  String get exportData => 'Meine Daten exportieren';

  @override
  String get exportedDownload => 'Daten heruntergeladen.';

  @override
  String get exportedClipboard =>
      'Deine Daten wurden in die Zwischenablage kopiert.';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountWarn =>
      'Dies löscht dein Konto und alle deine Zeitdaten dauerhaft. Kann nicht rückgängig gemacht werden.';

  @override
  String get deleteForever => 'Endgültig löschen';

  @override
  String get resetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get manageCategoriesHint =>
      'Benenne um, färbe um, blende aus oder füge eigene Bereiche hinzu.';
}
