// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Time';

  @override
  String get focusTitle => '¿En qué te enfocas ahora?';

  @override
  String get historyTitle => 'Puedes cambiar el historial';

  @override
  String get addEntry => 'Añadir un registro';

  @override
  String get category => 'Categoría';

  @override
  String get startTime => 'Inicio';

  @override
  String get endTime => 'Fin';

  @override
  String get add => 'Añadir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get running => 'ahora';

  @override
  String get today => 'Hoy';

  @override
  String totalLogged(int hours, int minutes) {
    return '${hours}h ${minutes}m registrados';
  }

  @override
  String get noEntries =>
      'Aún no hay registros. Elige un enfoque arriba para empezar.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get name => 'Nombre';

  @override
  String get timezone => 'Zona horaria';

  @override
  String get language => 'Idioma';

  @override
  String get languageAuto => 'Automático';

  @override
  String get account => 'Cuenta';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get madeBy => 'Hecho por Viny';

  @override
  String get openSettings => 'Ajustes';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signUp => 'Crear cuenta';

  @override
  String get email => 'Correo';

  @override
  String get password => 'Contraseña';

  @override
  String get haveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get needAccount => '¿Nuevo aquí? Crea una cuenta';

  @override
  String get verifyTitle => 'Revisa tu correo';

  @override
  String verifyHint(String email) {
    return 'Enviamos un código de 6 dígitos a $email';
  }

  @override
  String get code => 'Código de 6 dígitos';

  @override
  String get verify => 'Verificar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get welcomeTagline => 'Una imagen serena de a dónde va tu día.';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorInvalidCredentials => 'Correo o contraseña inválidos.';

  @override
  String get errorInvalidCode => 'Ese código no es válido o ha expirado.';

  @override
  String get errorEmailTaken => 'Ya existe una cuenta con este correo.';

  @override
  String get errorPasswordShort =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get errorWrongCurrentPassword => 'La contraseña actual es incorrecta.';

  @override
  String get passwordChanged => 'Contraseña actualizada.';

  @override
  String get settingsSaved => 'Guardado.';

  @override
  String get savedOffline =>
      'Guardado en este dispositivo. Se sincronizará al reconectar.';

  @override
  String get catWork => 'Trabajo';

  @override
  String get catPersonalChores => 'Tareas personales';

  @override
  String get catPersonalProjects => 'Proyectos personales';

  @override
  String get catLeisure => 'Ocio';

  @override
  String get catRelationships => 'Relaciones';

  @override
  String get catSelfMaintenance => 'Autocuidado';

  @override
  String get catGrowth => 'Crecimiento';

  @override
  String get catSleep => 'Sueño';

  @override
  String get catUncategorized => 'Sin categoría';

  @override
  String get entryOverlapNote =>
      'Los registros pueden superponerse; el círculo suma cada categoría.';

  @override
  String get deleteEntryConfirm => '¿Eliminar este registro?';

  @override
  String get downloadApk => 'Descargar app de Android (.apk)';
}
