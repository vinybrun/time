// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppL10nPt extends AppL10n {
  AppL10nPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Time';

  @override
  String get focusTitle => 'Onde está seu foco agora?';

  @override
  String get historyTitle => 'Você pode mudar o histórico';

  @override
  String get addEntry => 'Adicionar um registro';

  @override
  String get category => 'Categoria';

  @override
  String get startTime => 'Início';

  @override
  String get endTime => 'Fim';

  @override
  String get add => 'Adicionar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get edit => 'Editar';

  @override
  String get running => 'agora';

  @override
  String get today => 'Hoje';

  @override
  String totalLogged(int hours, int minutes) {
    return '${hours}h ${minutes}m registrados';
  }

  @override
  String get noEntries =>
      'Sem registros ainda. Escolha um foco acima para começar.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get name => 'Nome';

  @override
  String get timezone => 'Fuso horário';

  @override
  String get language => 'Idioma';

  @override
  String get languageAuto => 'Automático';

  @override
  String get account => 'Conta';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String get currentPassword => 'Senha atual';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get logout => 'Sair';

  @override
  String get madeBy => 'Feito por Viny';

  @override
  String get openSettings => 'Configurações';

  @override
  String get signIn => 'Entrar';

  @override
  String get signUp => 'Criar conta';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get haveAccount => 'Já tem conta? Entrar';

  @override
  String get needAccount => 'Novo por aqui? Criar conta';

  @override
  String get verifyTitle => 'Confira seu e-mail';

  @override
  String verifyHint(String email) {
    return 'Enviamos um código de 6 dígitos para $email';
  }

  @override
  String get code => 'Código de 6 dígitos';

  @override
  String get verify => 'Verificar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get welcomeTagline => 'Um retrato calmo de onde vai o seu dia.';

  @override
  String get errorGeneric => 'Algo deu errado. Tente novamente.';

  @override
  String get errorInvalidCredentials => 'E-mail ou senha inválidos.';

  @override
  String get errorInvalidCode => 'Esse código é inválido ou expirou.';

  @override
  String get errorEmailTaken => 'Já existe uma conta com este e-mail.';

  @override
  String get errorPasswordShort => 'A senha deve ter ao menos 8 caracteres.';

  @override
  String get errorWrongCurrentPassword => 'A senha atual está incorreta.';

  @override
  String get passwordChanged => 'Senha atualizada.';

  @override
  String get settingsSaved => 'Salvo.';

  @override
  String get savedOffline =>
      'Salvo neste dispositivo. Vai sincronizar quando houver conexão.';

  @override
  String get catWork => 'Trabalho';

  @override
  String get catPersonalChores => 'Tarefas pessoais';

  @override
  String get catPersonalProjects => 'Projetos pessoais';

  @override
  String get catLeisure => 'Lazer';

  @override
  String get catRelationships => 'Relacionamentos';

  @override
  String get catSelfMaintenance => 'Autocuidado';

  @override
  String get catGrowth => 'Crescimento';

  @override
  String get catSleep => 'Sono';

  @override
  String get catUncategorized => 'Sem categoria';

  @override
  String get entryOverlapNote =>
      'Registros podem se sobrepor; o círculo soma cada categoria.';

  @override
  String get deleteEntryConfirm => 'Excluir este registro?';

  @override
  String get downloadApk => 'Baixar app Android (.apk)';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get resetTitle => 'Redefinir sua senha';

  @override
  String get resetEmailHint =>
      'Digite seu e-mail e enviaremos um código de redefinição.';

  @override
  String get sendResetCode => 'Enviar código';

  @override
  String resetCodeHint(String email) {
    return 'Digite o código enviado para $email e escolha uma nova senha.';
  }

  @override
  String get doReset => 'Redefinir senha';

  @override
  String get backToSignIn => 'Voltar para entrar';

  @override
  String get categories => 'Categorias';

  @override
  String get addCategory => 'Adicionar categoria';

  @override
  String get categoryName => 'Nome da categoria';

  @override
  String get color => 'Cor';

  @override
  String get rename => 'Renomear';

  @override
  String get yourData => 'Seus dados';

  @override
  String get exportData => 'Exportar meus dados';

  @override
  String get exportedDownload => 'Seus dados foram baixados.';

  @override
  String get exportedClipboard =>
      'Seus dados foram copiados para a área de transferência.';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountWarn =>
      'Isto exclui permanentemente sua conta e todos os seus dados de tempo. Não pode ser desfeito.';

  @override
  String get deleteForever => 'Excluir para sempre';

  @override
  String get resetToDefaults => 'Restaurar padrões';

  @override
  String get manageCategoriesHint =>
      'Renomeie, recolora, oculte ou adicione suas próprias áreas.';

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get themeOffWhite => 'Bege claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeCircadian => 'Circadiano';

  @override
  String get themeCircadianHint => 'Acompanha o céu ao longo do seu dia';
}
