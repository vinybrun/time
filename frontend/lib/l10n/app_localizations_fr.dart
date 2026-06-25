// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Time';

  @override
  String get focusTitle => 'Sur quoi te concentres-tu ?';

  @override
  String get historyTitle => 'Tu peux modifier l\'historique';

  @override
  String get addEntry => 'Ajouter une entrée';

  @override
  String get category => 'Catégorie';

  @override
  String get startTime => 'Début';

  @override
  String get endTime => 'Fin';

  @override
  String get add => 'Ajouter';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get running => 'maintenant';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String totalLogged(int hours, int minutes) {
    return '${hours}h ${minutes}m enregistrés';
  }

  @override
  String get noEntries =>
      'Aucune entrée. Choisis un focus ci-dessus pour commencer.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get name => 'Nom';

  @override
  String get timezone => 'Fuseau horaire';

  @override
  String get language => 'Langue';

  @override
  String get languageAuto => 'Automatique';

  @override
  String get account => 'Compte';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get madeBy => 'Fait par Viny';

  @override
  String get openSettings => 'Paramètres';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get haveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get needAccount => 'Nouveau ici ? Créer un compte';

  @override
  String get verifyTitle => 'Vérifie tes e-mails';

  @override
  String verifyHint(String email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email';
  }

  @override
  String get code => 'Code à 6 chiffres';

  @override
  String get verify => 'Vérifier';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get welcomeTagline => 'Une image apaisée de l\'emploi de ta journée.';

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessaie.';

  @override
  String get errorInvalidCredentials => 'E-mail ou mot de passe invalide.';

  @override
  String get errorInvalidCode => 'Ce code est invalide ou expiré.';

  @override
  String get errorEmailTaken => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get errorPasswordShort =>
      'Le mot de passe doit faire au moins 8 caractères.';

  @override
  String get errorWrongCurrentPassword =>
      'Le mot de passe actuel est incorrect.';

  @override
  String get passwordChanged => 'Mot de passe mis à jour.';

  @override
  String get settingsSaved => 'Enregistré.';

  @override
  String get savedOffline =>
      'Enregistré sur cet appareil. Synchronisation à la reconnexion.';

  @override
  String get catWork => 'Travail';

  @override
  String get catPersonalChores => 'Tâches personnelles';

  @override
  String get catPersonalProjects => 'Projets personnels';

  @override
  String get catLeisure => 'Loisirs';

  @override
  String get catRelationships => 'Relations';

  @override
  String get catSelfMaintenance => 'Soin de soi';

  @override
  String get catGrowth => 'Développement';

  @override
  String get catSleep => 'Sommeil';

  @override
  String get catUncategorized => 'Sans catégorie';

  @override
  String get entryOverlapNote =>
      'Les entrées peuvent se chevaucher ; le cercle additionne chaque catégorie.';

  @override
  String get deleteEntryConfirm => 'Supprimer cette entrée ?';

  @override
  String get downloadApk => 'Télécharger l\'app Android (.apk)';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetEmailHint =>
      'Saisis ton e-mail et nous t\'enverrons un code.';

  @override
  String get sendResetCode => 'Envoyer le code';

  @override
  String resetCodeHint(String email) {
    return 'Saisis le code envoyé à $email et choisis un nouveau mot de passe.';
  }

  @override
  String get doReset => 'Réinitialiser';

  @override
  String get backToSignIn => 'Retour à la connexion';

  @override
  String get categories => 'Catégories';

  @override
  String get addCategory => 'Ajouter une catégorie';

  @override
  String get categoryName => 'Nom de la catégorie';

  @override
  String get color => 'Couleur';

  @override
  String get rename => 'Renommer';

  @override
  String get yourData => 'Tes données';

  @override
  String get exportData => 'Exporter mes données';

  @override
  String get exportedDownload => 'Données téléchargées.';

  @override
  String get exportedClipboard =>
      'Tes données ont été copiées dans le presse-papiers.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountWarn =>
      'Ceci supprime définitivement ton compte et toutes tes données de temps. Action irréversible.';

  @override
  String get deleteForever => 'Supprimer définitivement';

  @override
  String get resetToDefaults => 'Réinitialiser';

  @override
  String get manageCategoriesHint =>
      'Renomme, recolorie, masque ou ajoute tes propres domaines.';
}
