/// Textos centralizados em pt-BR. O mercado principal (e, por enquanto,
/// único) do produto é o Brasil, então o scaffolding completo de i18n com
/// `intl`/ARB é deliberadamente evitado em favor de um arquivo de
/// constantes simples — trivial de migrar para arquivos ARB do
/// `flutter_localizations` mais tarde, se/quando outros idiomas forem lançados.
abstract final class AppStrings {
  static const String appName = 'Vai Márcia';
  static const String appTagline = 'Sua energia, um toque de distância.';

  // Home / big button grid
  static const String homeTitle = 'Vai Márcia';
  static const String noClipsInCategory = 'Nenhum áudio nesta categoria ainda.';
  static const String preparingAudios = 'Preparando seus áudios...';

  // Categories
  static const String categoriesTitle = 'Categorias';
  static const String categoryMotivacao = 'Motivação';
  static const String categoryRecuperacao = 'Recuperação';
  static const String categoryEnergia = 'Energia';
  static const String categoryComemoracao = 'Comemoração';
  static const String categoryConcentracao = 'Concentração';
  static const String categoryHumor = 'Humor';
  static const String categoryIncentivo = 'Incentivo';
  static const String categoryTreinador = 'Treinador';
  static const String categoryParceiro = 'Parceiro';
  static const String categoryPersonalizados = 'Personalizados';

  // Favorites
  static const String favoritesTitle = 'Favoritos';
  static const String noFavoritesYet = 'Você ainda não tem favoritos. Toque e segure um áudio para favoritar.';

  // Recording
  static const String recordingTitle = 'Gravar áudio';
  static const String recordingStart = 'Toque para gravar';
  static const String recordingStop = 'Toque para parar';
  static const String recordingSave = 'Salvar';
  static const String recordingDiscard = 'Descartar';
  static const String recordingNamePrompt = 'Dê um nome para o seu áudio';

  // Device pairing / setup wizard
  static const String setupWizardTitle = 'Vamos configurar seu equipamento';
  static const String setupWizardIntro =
      'Vamos detectar automaticamente seu relógio, celular e caixa de som. Você não precisa configurar nada manualmente.';
  static const String setupDetectingWatch = 'Procurando relógio pareado...';
  static const String setupDetectingSpeaker = 'Procurando caixa Bluetooth...';
  static const String setupProbingCapabilities = 'Avaliando capacidades do dispositivo...';
  static const String setupOpenBluetoothSettings = 'Abrir configurações de Bluetooth';
  static const String setupInstallCompanionApp = 'Instalar app do relógio';
  static const String setupFinishButton = 'Concluir';
  static const String setupSummaryDirect = 'Prontinho! Seu %watch% vai tocar direto na sua caixa %speaker%.';
  static const String setupSummaryRelay = 'Prontinho! Seu %watch% vai avisar seu celular, que toca na caixa %speaker%.';
  static const String setupSummaryPhoneOnly = 'Prontinho! Vamos usar seu celular para tocar os áudios.';

  // Bluetooth
  static const String bluetoothPermissionRationale =
      'Precisamos de acesso ao Bluetooth para tocar os áudios na sua caixa de som.';
  static const String bluetoothNotConnected = 'Nenhuma caixa Bluetooth conectada';

  // Auth
  static const String authTitle = 'Entrar';
  static const String authSignInGoogle = 'Entrar com Google';
  static const String authSignInApple = 'Entrar com Apple';
  static const String authSignInEmail = 'Entrar com e-mail';
  static const String authContinueAnonymous = 'Continuar sem conta';
  static const String authSignOut = 'Sair';

  // Store
  static const String storeTitle = 'Loja TogPlay';
  static const String storeBannerText =
      'Precisando de uma nova raquete ou acessórios? Visite a Loja TogPlay — www.lojatogplay.com.br';
  static const String storeUrl = 'https://www.lojatogplay.com.br';
  static const String storeOpenButton = 'Visitar loja';
  static const String storeOpenError = 'Não foi possível abrir a loja. Tente novamente.';

  // Notifications
  static const String notificationsTitle = 'Notificações';
  static const String noNotifications = 'Nenhuma notificação por enquanto.';

  // Generic errors
  static const String genericError = 'Algo deu errado. Tente novamente.';
  static const String networkError = 'Sem conexão com a internet.';
  static const String retry = 'Tentar novamente';
  static const String cancel = 'Cancelar';
  static const String ok = 'OK';
}
