// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Time';

  @override
  String get focusTitle => 'Where is your focus now?';

  @override
  String get historyTitle => 'You can change history';

  @override
  String get addEntry => 'Add a time entry';

  @override
  String get category => 'Category';

  @override
  String get startTime => 'Start';

  @override
  String get endTime => 'End';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get running => 'now';

  @override
  String get today => 'Today';

  @override
  String totalLogged(int hours, int minutes) {
    return '${hours}h ${minutes}m logged';
  }

  @override
  String get noEntries => 'No entries yet. Pick a focus above to begin.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get name => 'Name';

  @override
  String get timezone => 'Time zone';

  @override
  String get language => 'Language';

  @override
  String get languageAuto => 'Automatic';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get logout => 'Log out';

  @override
  String get madeBy => 'Made by Viny';

  @override
  String get openSettings => 'Settings';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get needAccount => 'New here? Create an account';

  @override
  String get verifyTitle => 'Check your email';

  @override
  String verifyHint(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get code => '6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get welcomeTagline => 'A calm picture of where your day goes.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorInvalidCredentials => 'Invalid email or password.';

  @override
  String get errorInvalidCode => 'That code is not valid or has expired.';

  @override
  String get errorEmailTaken => 'An account with this email already exists.';

  @override
  String get errorPasswordShort => 'Password must be at least 8 characters.';

  @override
  String get errorWrongCurrentPassword => 'Current password is incorrect.';

  @override
  String get passwordChanged => 'Password updated.';

  @override
  String get settingsSaved => 'Saved.';

  @override
  String get savedOffline => 'Saved on this device. Will sync when online.';

  @override
  String get catWork => 'Work';

  @override
  String get catPersonalChores => 'Personal chores';

  @override
  String get catPersonalProjects => 'Personal projects';

  @override
  String get catLeisure => 'Leisure';

  @override
  String get catRelationships => 'Relationships';

  @override
  String get catSelfMaintenance => 'Self maintenance';

  @override
  String get catGrowth => 'Growth';

  @override
  String get catSleep => 'Sleep';

  @override
  String get catUncategorized => 'Uncategorized';

  @override
  String get entryOverlapNote =>
      'Entries can overlap; the circle sums each category.';

  @override
  String get deleteEntryConfirm => 'Delete this entry?';

  @override
  String get downloadApk => 'Download Android app (.apk)';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetTitle => 'Reset your password';

  @override
  String get resetEmailHint => 'Enter your email and we\'ll send a reset code.';

  @override
  String get sendResetCode => 'Send reset code';

  @override
  String resetCodeHint(String email) {
    return 'Enter the code we sent to $email and choose a new password.';
  }

  @override
  String get doReset => 'Reset password';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get categoryName => 'Category name';

  @override
  String get color => 'Color';

  @override
  String get rename => 'Rename';

  @override
  String get yourData => 'Your data';

  @override
  String get exportData => 'Export my data';

  @override
  String get exportedDownload => 'Downloaded your data.';

  @override
  String get exportedClipboard => 'Your data was copied to the clipboard.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountWarn =>
      'This permanently deletes your account and all your time data. This cannot be undone.';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get resetToDefaults => 'Reset to defaults';

  @override
  String get manageCategoriesHint =>
      'Rename, recolor, hide, or add your own areas.';
}
