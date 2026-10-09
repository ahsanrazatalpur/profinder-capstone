// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navSearch => 'Buscar';

  @override
  String get appName => 'ProFinder';

  @override
  String get appTagline => 'Encuentra profesionales de confianza cerca de ti';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get sendResetLink => 'Enviar enlace de restablecimiento';

  @override
  String get noAccount => '¿No tienes una cuenta? ';

  @override
  String get hasAccount => '¿Ya tienes una cuenta? ';

  @override
  String get selectRole => 'Registrarse como';

  @override
  String get customer => 'Cliente';

  @override
  String get professional => 'Profesional';

  @override
  String get home => 'Inicio';

  @override
  String get findProfessional => 'Buscar un profesional';

  @override
  String get nearbyProfessionals => 'Profesionales cercanos';

  @override
  String get categories => 'Categorías';

  @override
  String get aiSearch => 'Búsqueda con IA';

  @override
  String get searchHint => 'Buscar un servicio...';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get phone => 'Número de teléfono';

  @override
  String get city => 'Ciudad';

  @override
  String get bio => 'Biografía';

  @override
  String get experience => 'Años de experiencia';

  @override
  String get hourlyRate => 'Tarifa por hora (USD)';

  @override
  String get verified => 'Verificado';

  @override
  String get notVerified => 'No verificado';

  @override
  String get bookings => 'Reservas';

  @override
  String get myBookings => 'Mis reservas';

  @override
  String get bookNow => 'Reservar ahora';

  @override
  String get cancel => 'Cancelar';

  @override
  String get accept => 'Aceptar';

  @override
  String get reject => 'Rechazar';

  @override
  String get complete => 'Completar';

  @override
  String get pending => 'Pendiente';

  @override
  String get accepted => 'Aceptado';

  @override
  String get rejected => 'Rechazado';

  @override
  String get completed => 'Completado';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get markAsRead => 'Marcar como leído';

  @override
  String get noNotifications => 'Aún no hay notificaciones';

  @override
  String get reviews => 'Reseñas';

  @override
  String get writeReview => 'Escribir una reseña';

  @override
  String get rating => 'Calificación';

  @override
  String get comment => 'Comentario';

  @override
  String get submitReview => 'Enviar reseña';

  @override
  String get noInternet => 'Sin conexión a internet';

  @override
  String get serverError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get invalidEmail => 'Introduce un correo electrónico válido';

  @override
  String get invalidPassword =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get fieldRequired => 'Este campo es obligatorio';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden';

  @override
  String get invalidLoginCredentials =>
      'Correo o contraseña incorrectos. Inténtalo de nuevo.';

  @override
  String get forgotPasswordGenericMessage =>
      'Si existe una cuenta con este correo, hemos enviado un enlace de restablecimiento.';

  @override
  String get requestTimedOut =>
      'Se agotó el tiempo de espera. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get save => 'Guardar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get delete => 'Eliminar';

  @override
  String get loading => 'Cargando...';

  @override
  String get retry => 'Reintentar';

  @override
  String get noData => 'Nada para mostrar aquí';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get ok => 'Aceptar';

  @override
  String get selectLanguageTitle => 'Elige tu idioma';

  @override
  String get selectLanguageSubtitle =>
      'Elige el idioma que quieres usar en ProFinder';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get languageChangeNote =>
      'Puedes cambiar el idioma más tarde desde los ajustes.';

  @override
  String get languageUpdated => 'Idioma actualizado';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get notificationsSection => 'Notificaciones';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get pushNotificationsSubtitle =>
      'Actualizaciones de reservas, mensajes y ofertas';

  @override
  String get emailNotifications => 'Notificaciones por correo';

  @override
  String get emailNotificationsSubtitle => 'Recibos y actividad de la cuenta';

  @override
  String get preferencesSection => 'Preferencias';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get darkModeLabel => 'Modo oscuro';

  @override
  String get accountSection => 'Cuenta';

  @override
  String get supportSection => 'Soporte';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle => 'Elimina tu cuenta de forma permanente';

  @override
  String get deleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountMessage =>
      'Esto debe pasar por nuestro equipo de soporte para verificación. Contacta a Ayuda y soporte para continuar.';

  @override
  String comingSoon(String feature) {
    return '$feature próximamente';
  }

  @override
  String get loginWelcomeBack =>
      '¡Bienvenido de nuevo! Inicia sesión para continuar.';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordHint => 'Ingresa tu contraseña';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get unknownRoleContactSupport =>
      'Rol desconocido. Por favor contacta a soporte.';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get joinProFinderSubtitle =>
      'Únete a ProFinder y conéctate con profesionales.';

  @override
  String get chooseAccountType => 'Elige el tipo de cuenta';

  @override
  String get customerRoleDescription => 'Contrata profesionales de confianza.';

  @override
  String get professionalRoleDescription =>
      'Ofrece tus servicios y haz crecer tu negocio.';

  @override
  String get fullNameHint => 'Ingresa tu nombre completo';

  @override
  String get countryLabel => 'País';

  @override
  String get selectCountryHint => 'Selecciona tu país';

  @override
  String get searchCountriesHint => 'Buscar países...';

  @override
  String get noCountriesFound => 'No se encontraron países';

  @override
  String get selectCountryValidation => 'Por favor selecciona tu país';

  @override
  String get selectCityHint => 'Selecciona tu ciudad';

  @override
  String get selectACountryFirst => 'Selecciona primero un país';

  @override
  String get searchCitiesHint => 'Buscar ciudades...';

  @override
  String get noCitiesFound => 'No se encontraron ciudades';

  @override
  String get selectCityValidation => 'Por favor selecciona tu ciudad';

  @override
  String get yourProfessionLabel => 'Tu profesión';

  @override
  String get selectCategoryHint => 'Selecciona tu categoría';

  @override
  String get searchProfessionsHint => 'Buscar profesiones...';

  @override
  String get noCategoriesFound => 'No se encontraron categorías';

  @override
  String get selectProfessionValidation => 'Por favor selecciona tu profesión';

  @override
  String get selectProfessionCategoryError =>
      'Por favor selecciona la categoría de tu profesión.';

  @override
  String get passwordMinCharsHint => 'Mín. 8 caracteres';

  @override
  String get confirmPasswordHint => 'Vuelve a ingresar tu contraseña';

  @override
  String get capsLockOnHint => 'Bloq Mayús está activado';

  @override
  String get emailAvailable => 'Correo disponible';

  @override
  String get emailAlreadyRegistered => 'Este correo ya está registrado.';

  @override
  String get signInInstead => 'Iniciar sesión';

  @override
  String get orContinueWith => 'o continuar con';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get facebookLabel => 'Facebook';

  @override
  String get twitterLabel => 'X (Twitter)';

  @override
  String get forgotPasswordInstructions =>
      'Ingresa tu correo registrado. Te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get checkYourEmail => 'Revisa tu correo';

  @override
  String get checkSpamFolderHint =>
      'Si no llega en unos minutos, revisa tu carpeta de spam o intenta de nuevo.';

  @override
  String get backToLogin => 'Volver a iniciar sesión';

  @override
  String get resendEmail => 'Reenviar correo';

  @override
  String adminAvgRatingTotal(String value1, String value2) {
    return 'Calificación promedio: $value1 ★ · $value2 en total';
  }

  @override
  String adminBy(String value1) {
    return 'por $value1';
  }

  @override
  String get adminDeleteReview => 'Eliminar reseña';

  @override
  String get adminPermanentlyRemovesReviewProvideReasonAudit =>
      'Esto elimina la reseña de forma permanente. Indica un motivo para el registro de auditoría.';

  @override
  String get adminFailedDeleteReview => 'Error al eliminar la reseña.';

  @override
  String get adminNoReviewsFound => 'No se encontraron reseñas';

  @override
  String get adminFailedLoadReviews => 'Error al cargar las reseñas';

  @override
  String get adminSearchByProfessionalReviewer =>
      'Buscar por profesional o autor de la reseña…';

  @override
  String get adminReasonRequired => 'Motivo (obligatorio)';

  @override
  String get adminPayments => 'Pagos';

  @override
  String adminRsShown(String value1) {
    return 'Mostrando Rs $value1';
  }

  @override
  String get adminRefund => 'Reembolso';

  @override
  String adminTxn(String value1) {
    return 'Transacción: $value1';
  }

  @override
  String get adminRefundPayment => 'Reembolsar pago';

  @override
  String adminRefundRs(String value1, String value2) {
    return '¿Reembolsar Rs $value1 a $value2?';
  }

  @override
  String get adminPaymentRefunded => 'Pago reembolsado.';

  @override
  String get adminRefundFailed => 'Error al reembolsar.';

  @override
  String get adminNoPaymentsFound => 'No se encontraron pagos';

  @override
  String get adminFailedLoadPayments => 'Error al cargar los pagos';

  @override
  String get adminSearchByNameEmailTransactionId =>
      'Buscar por nombre, correo o ID de transacción…';

  @override
  String get adminBlockedUsers => 'Usuarios bloqueados';

  @override
  String adminCurrentlyBlocked(String value1) {
    return '$value1 bloqueados actualmente';
  }

  @override
  String get adminUnblock => 'Desbloquear';

  @override
  String get adminUnblockUser => '¿Desbloquear usuario?';

  @override
  String adminRestoreAccessTheyAbleLogAgain(String value1) {
    return 'Esto restaurará el acceso de $value1. Podrá iniciar sesión de nuevo.';
  }

  @override
  String adminHasBeenUnblocked(String value1) {
    return '$value1 ha sido desbloqueado.';
  }

  @override
  String get adminFailedUnblockUser => 'Error al desbloquear al usuario.';

  @override
  String get adminNoBlockedUsersAllClear =>
      'No hay usuarios bloqueados — ¡todo en orden! 🎉';

  @override
  String get adminFailedLoadBlockedUsers =>
      'Error al cargar los usuarios bloqueados';

  @override
  String get adminSearchByNameEmailReason =>
      'Buscar por nombre, correo o motivo…';

  @override
  String adminExportProfessionals(String value1) {
    return 'Exportar ($value1 profesionales)';
  }

  @override
  String get adminClose => 'Cerrar';

  @override
  String get adminCopyClipboard => 'Copiar al portapapeles';

  @override
  String get adminProfessionals => 'Profesionales';

  @override
  String get adminRatingHighLow => 'Calificación (mayor a menor)';

  @override
  String get adminMostBookings => 'Más reservas';

  @override
  String get adminNameZ => 'Nombre (A-Z)';

  @override
  String get adminNewestFirst => 'Más recientes primero';

  @override
  String adminSelected(String value1) {
    return '$value1 seleccionados';
  }

  @override
  String get adminVerify => 'Verificar';

  @override
  String get adminRemind => 'Recordar';

  @override
  String get adminExport => 'Exportar';

  @override
  String get adminFailedLoadProfessionals =>
      'Error al cargar los profesionales';

  @override
  String get adminSearchByNameEmailCategory =>
      'Buscar por nombre, correo, categoría…';

  @override
  String get adminSort => 'Ordenar';

  @override
  String get adminRefresh => 'Actualizar';

  @override
  String get adminVerifyProfessional => '¿Verificar profesional?';

  @override
  String adminVerifyProfessionals(String value1) {
    return '¿Verificar $value1 profesionales?';
  }

  @override
  String adminGetVerifiedBadgeVisibleAllCustomers(String value1) {
    return '$value1 obtendrá una insignia de verificado visible para todos los clientes.';
  }

  @override
  String get adminAllSelectedProfessionalsGetVerifiedBadge =>
      'Todos los profesionales seleccionados obtendrán una insignia de verificado.';

  @override
  String get adminProfinderAdmin => 'ProFinder Admin';

  @override
  String get adminAdminPanel => 'Panel de administración';

  @override
  String get adminMore => 'Más';

  @override
  String get adminLogout2 => '¿Cerrar sesión?';

  @override
  String get adminLoggedOutAdminPanel =>
      'Se cerrará tu sesión en el panel de administración.';

  @override
  String get adminAnalytics => 'Analítica';

  @override
  String adminD(String value1) {
    return '${value1}D';
  }

  @override
  String adminRs(String value1) {
    return 'Rs $value1';
  }

  @override
  String adminLastDays(String value1) {
    return 'últimos $value1 días';
  }

  @override
  String get adminLast12Months => 'últimos 12 meses';

  @override
  String get adminDailyBookings => 'Reservas diarias';

  @override
  String get adminMonthlyBookings12mo => 'Reservas mensuales (12 meses)';

  @override
  String get adminTopSearches => 'Búsquedas principales';

  @override
  String get adminNoDataYet => 'Aún no hay datos';

  @override
  String get adminFailedLoadAnalytics => 'Error al cargar la analítica';

  @override
  String get adminCountries => 'Países';

  @override
  String get adminTopCities => 'Ciudades principales';

  @override
  String get adminTopCategories => 'Categorías principales';

  @override
  String get adminActivityLogs => 'Registros de actividad';

  @override
  String adminLogs(String value1) {
    return '$value1 registros';
  }

  @override
  String adminTotal(String value1) {
    return 'Total: $value1';
  }

  @override
  String get adminAdminActionsAppearHere =>
      'Las acciones del administrador aparecerán aquí';

  @override
  String get adminFailedLoadLogs => 'Error al cargar los registros';

  @override
  String get adminSearchByAdminTargetUser =>
      'Buscar por administrador o usuario objetivo…';

  @override
  String get adminClearAll => 'Borrar todo';

  @override
  String get adminDeleteLog => '¿Eliminar este registro?';

  @override
  String get adminClearAllLogs => '¿Borrar todos los registros?';

  @override
  String get adminActionCannotUndone => 'Esta acción no se puede deshacer.';

  @override
  String adminAllActivityLogsPermanentlyDeleted(String value1) {
    return 'Se eliminarán permanentemente los $value1 registros de actividad.';
  }

  @override
  String adminWelcome(String value1) {
    return 'Bienvenido, $value1 👋';
  }

  @override
  String adminCustomersProfessionals(String value1, String value2) {
    return '$value1 clientes · $value2 profesionales';
  }

  @override
  String get adminSearch => 'Buscar';

  @override
  String get adminGlobalSearchUiReadyConnectUsers =>
      'La interfaz de búsqueda global está lista — se conectará a Usuarios/Reservas una vez que se reconstruya ese módulo.';

  @override
  String get adminReview => 'Reseña';

  @override
  String get adminFailedLoadDashboard => 'Error al cargar el panel';

  @override
  String get adminSearchUsersProfessionalsBookings =>
      'Buscar usuarios, profesionales, reservas…';

  @override
  String get adminTotalUsers => 'Usuarios totales';

  @override
  String get adminCustomers => 'Clientes';

  @override
  String get adminRevenue => 'Ingresos';

  @override
  String get adminTodaySBookings => 'Reservas de hoy';

  @override
  String get adminPendingVerification => 'Verificación pendiente';

  @override
  String get adminReportedUsers => 'Usuarios reportados';

  @override
  String adminExportUsers(String value1) {
    return 'Exportar ($value1 usuarios)';
  }

  @override
  String get adminUsers => 'Usuarios';

  @override
  String get adminNameZ2 => 'Nombre (Z-A)';

  @override
  String get adminOldestFirst => 'Más antiguos primero';

  @override
  String adminShown(String value1) {
    return '$value1 mostrados';
  }

  @override
  String get adminBlock => 'Bloquear';

  @override
  String adminJoined(String value1) {
    return 'Se unió $value1';
  }

  @override
  String get adminFailedLoadUsers => 'Error al cargar los usuarios';

  @override
  String get adminSearchByNameEmail => 'Buscar por nombre o correo…';

  @override
  String get adminFailedUpdate => 'Error al actualizar.';

  @override
  String get adminFailedDelete => 'Error al eliminar.';

  @override
  String get adminAddCountry => 'Agregar país';

  @override
  String get adminFailedAddMayAlreadyExist =>
      'Error al agregar — puede que ya exista.';

  @override
  String get adminAdd => 'Agregar';

  @override
  String adminMergeInto(String value1) {
    return 'Fusionar en \"$value1\"';
  }

  @override
  String get adminEnterTypoVariantSpellingsFoundUser =>
      'Ingresa errores tipográficos o variantes encontradas en los perfiles de usuario, separados por comas (ej. pakistan, Pakistn).';

  @override
  String get adminMergeFailed => 'Error al fusionar.';

  @override
  String get adminMerge => 'Fusionar';

  @override
  String adminActive(String value1) {
    return '$value1 activos';
  }

  @override
  String get adminViewCities => 'Ver ciudades';

  @override
  String get adminNoCountriesAddedYet => 'Aún no se han agregado países';

  @override
  String get adminFailedLoadCountries => 'Error al cargar los países';

  @override
  String get adminCountryName => 'Nombre del país';

  @override
  String get adminVariant1Variant2 => 'variante1, variante2, ...';

  @override
  String get adminRevenueByCategory => 'Ingresos por categoría';

  @override
  String adminVsPreviousDays(String value1, String value2) {
    return '$value1% frente a los $value2 días anteriores';
  }

  @override
  String get adminNoCategoryDataYet => 'Aún no hay datos de categoría';

  @override
  String adminRs2(String value1, String value2) {
    return 'Rs $value1 ($value2)';
  }

  @override
  String get adminFailedLoadRevenueData =>
      'Error al cargar los datos de ingresos';

  @override
  String get adminDeleteBanner => '¿Eliminar este banner?';

  @override
  String adminPermanentlyDeleted(String value1) {
    return '\"$value1\" se eliminará de forma permanente.';
  }

  @override
  String get adminPreviewMode => '👁 MODO DE VISTA PREVIA';

  @override
  String get adminActive2 => 'Activo';

  @override
  String get adminTurningOffHidesBannerFromEveryone =>
      'Desactivar esto oculta el banner para todos';

  @override
  String get adminPromoBanners => 'Banners promocionales';

  @override
  String get adminFailedLoadBanners => 'Error al cargar los banners';

  @override
  String get adminNoBannersYet => 'Aún no hay banners';

  @override
  String get adminTapCreateNewBanner => 'Toca \"+\" para crear un nuevo banner';

  @override
  String get adminPreview => 'Vista previa';

  @override
  String get adminEdit => 'Editar';

  @override
  String get adminFailedGenerateReport => 'Error al generar el informe.';

  @override
  String get adminNoDataRange => 'No hay datos en este rango.';

  @override
  String get adminCopiedClipboardStyleExportCsvReady =>
      'Copiado en formato de exportación (CSV) — listo para compartir.';

  @override
  String get adminExportCsv => 'Exportar CSV';

  @override
  String get adminReports => 'Informes';

  @override
  String get adminQuickGenerate => 'Generación rápida';

  @override
  String get adminLast30Days => 'Últimos 30 días';

  @override
  String get adminGenerationHistory => 'Historial de generación';

  @override
  String get adminNoReportsGeneratedYetSession =>
      'Aún no se han generado informes en esta sesión.';

  @override
  String adminRows(String value1, String value2) {
    return '$value1 filas · $value2';
  }

  @override
  String adminProsBookingsSubcategories(
    String value1,
    String value2,
    String value3,
  ) {
    return '$value1 profesionales · $value2 reservas · $value3 subcategorías';
  }

  @override
  String get adminFeatured => 'Destacado';

  @override
  String get adminShowGuestHomeSFeaturedCategories =>
      'Mostrar en las categorías destacadas de la página de invitados (máx. 6)';

  @override
  String get adminAddSubcategory => 'Agregar subcategoría';

  @override
  String get adminFailedLoad => 'Error al cargar';

  @override
  String get adminName => 'Nombre';

  @override
  String get adminIconOptional => 'Ícono (opcional)';

  @override
  String get adminParentCategory => 'Categoría principal';

  @override
  String get adminAddNew => 'Agregar nuevo';

  @override
  String get adminCancelSubscription => '¿Cancelar suscripción?';

  @override
  String adminCancelSSubscription(String value1, String value2) {
    return '¿Cancelar la suscripción $value2 de $value1?';
  }

  @override
  String get adminNo => 'No';

  @override
  String get adminCancelSubscription2 => 'Cancelar suscripción';

  @override
  String get adminFailedCancel => 'Error al cancelar.';

  @override
  String get adminExtendedBy30Days => 'Extendido por 30 días.';

  @override
  String get adminFailedExtend => 'Error al extender.';

  @override
  String get adminSubscriptions => 'Suscripciones';

  @override
  String adminRs3(String value1, String value2, String value3) {
    return '$value1 · Rs $value2/$value3';
  }

  @override
  String adminRenews(String value1) {
    return 'Renueva: $value1';
  }

  @override
  String get adminExtend30d => 'Extender 30 días';

  @override
  String get adminNoSubscriptionsFound => 'No se encontraron suscripciones';

  @override
  String get adminFailedLoadSubscriptions =>
      'Error al cargar las suscripciones';

  @override
  String adminExportCustomers(String value1) {
    return 'Exportar ($value1 clientes)';
  }

  @override
  String get adminTotalSpentHighLow => 'Gasto total (mayor a menor)';

  @override
  String get adminFailedLoadCustomers => 'Error al cargar los clientes';

  @override
  String get adminAddLanguage => 'Agregar idioma';

  @override
  String get adminRightLeftRtl => 'De derecha a izquierda (RTL)';

  @override
  String get adminFailedAddCodeMayAlreadyExist =>
      'Error al agregar — el código puede que ya exista.';

  @override
  String get adminFailedUpdateStatus => 'Error al actualizar el estado.';

  @override
  String get adminChangeStatus => 'Cambiar estado';

  @override
  String get adminDeleteLanguage => '¿Eliminar idioma?';

  @override
  String adminPermanentlyRemoveAllItsTranslations(String value1) {
    return 'Esto eliminará permanentemente \"$value1\" y todas sus traducciones.';
  }

  @override
  String get adminFailedDeleteLanguage => 'Error al eliminar el idioma.';

  @override
  String get adminLanguages => 'Idiomas';

  @override
  String adminActiveTotal(String value1, String value2) {
    return '$value1 activos · $value2 en total';
  }

  @override
  String get adminRtl => 'RTL';

  @override
  String get adminEditTranslations => 'Editar traducciones';

  @override
  String get adminNoLanguagesAddedYet => 'Aún no se han agregado idiomas';

  @override
  String get adminFailedLoadLanguages => 'Error al cargar los idiomas';

  @override
  String get adminLanguageNameEGUrdu => 'Nombre del idioma (ej. Urdu)';

  @override
  String get adminCodeEGUr => 'Código (ej. ur)';

  @override
  String get adminDeleteArticle => '¿Eliminar artículo?';

  @override
  String get adminNewArticle => 'Nuevo artículo';

  @override
  String get adminTipsMagazine => 'Revista de consejos';

  @override
  String get adminNoArticlesHereYet => 'Aún no hay artículos aquí.';

  @override
  String adminMinReadViews(String value1, String value2) {
    return '$value1 min de lectura · $value2 vistas';
  }

  @override
  String get adminSelect => 'Seleccionar…';

  @override
  String get adminManageCategories => 'Administrar categorías';

  @override
  String get adminNoCategoriesYet => 'Aún no hay categorías.';

  @override
  String adminArticles(String value1) {
    return '$value1 artículos';
  }

  @override
  String get adminAddNewCategory => 'Agregar nueva categoría';

  @override
  String get adminAddCategory => 'Agregar categoría';

  @override
  String get adminCategoryName => 'Nombre de la categoría';

  @override
  String get adminNoChangesSave => 'No hay cambios que guardar.';

  @override
  String get adminFailedSaveTranslations =>
      'Error al guardar las traducciones.';

  @override
  String get adminAddTranslationKey => 'Agregar clave de traducción';

  @override
  String get adminFailedAddKeyMayAlreadyExist =>
      'Error al agregar — la clave puede que ya exista.';

  @override
  String get adminDiscardChanges => '¿Descartar cambios?';

  @override
  String adminHaveUnsavedTranslationS(String value1) {
    return 'Tienes $value1 traducciones sin guardar.';
  }

  @override
  String get adminKeepEditing => 'Seguir editando';

  @override
  String get adminDiscard => 'Descartar';

  @override
  String get adminAddKey => 'Agregar clave';

  @override
  String adminTranslate(String value1) {
    return 'Traducir — $value1';
  }

  @override
  String adminKeysUnsaved(String value1, String value2) {
    return '$value1 claves · $value2 sin guardar';
  }

  @override
  String get adminMissing => 'Faltante';

  @override
  String get adminNoTranslationKeysYet => 'Aún no hay claves de traducción';

  @override
  String get adminTapAddKeyCreateFirstOne =>
      'Toca \"Agregar clave\" para crear la primera.';

  @override
  String get adminFailedLoadTranslations => 'Error al cargar las traducciones';

  @override
  String get adminKeyEGHomeWelcomeTitle => 'Clave (ej. home.welcome_title)';

  @override
  String get adminDescriptionOptional => 'Descripción (opcional)';

  @override
  String get adminSearchKeys => 'Buscar claves…';

  @override
  String get adminTranslatedText => 'Texto traducido…';

  @override
  String adminAddCity(String value1) {
    return 'Agregar ciudad a $value1';
  }

  @override
  String get adminEnterTypoVariantSpellingsCommaSeparated =>
      'Ingresa errores tipográficos o variantes, separados por comas.';

  @override
  String get adminAddCity2 => 'Agregar ciudad';

  @override
  String get adminNoCitiesAddedYet => 'Aún no se han agregado ciudades';

  @override
  String get adminFailedLoadCities => 'Error al cargar las ciudades';

  @override
  String get adminCityName => 'Nombre de la ciudad';

  @override
  String adminPendingReview(String value1) {
    return '$value1 pendientes de revisión';
  }

  @override
  String get adminBlocked => 'BLOQUEADO';

  @override
  String adminReportedBy(String value1, String value2) {
    return 'Reportado por $value1 ($value2)';
  }

  @override
  String get adminFailedLoadReports => 'Error al cargar los reportes';

  @override
  String adminReportOn(String value1) {
    return 'Reporte sobre $value1';
  }

  @override
  String get adminAlsoBanUser => 'También bloquear a este usuario';

  @override
  String get adminDismiss => 'Descartar';

  @override
  String get adminMarkReviewed => 'Marcar como revisado';

  @override
  String get adminTakeAction => 'Tomar acción';

  @override
  String get adminFailedUpdateReport => 'Error al actualizar el reporte.';

  @override
  String get adminSearchByUserReporterReason =>
      'Buscar por usuario, reportante o motivo…';

  @override
  String get adminAdminNoteOptional => 'Nota del administrador (opcional)…';

  @override
  String get adminPortfolioApproval => 'Aprobación de portafolio';

  @override
  String get adminApprove => 'Aprobar';

  @override
  String get adminAllPortfoliosReviewed =>
      '¡Todos los portafolios han sido revisados!';

  @override
  String get adminFailedLoadPortfolios => 'Error al cargar los portafolios';

  @override
  String get adminSkip => 'Omitir';

  @override
  String get adminWriteReasonOptional => 'Escribe el motivo (opcional)…';

  @override
  String get adminApprovePortfolio => '¿Aprobar portafolio?';

  @override
  String adminVisibleAllCustomers(String value1) {
    return '\"$value1\" será visible para todos los clientes.';
  }

  @override
  String adminBookings2(String value1) {
    return '$value1 reservas';
  }

  @override
  String adminCreated(String value1) {
    return 'Creado $value1';
  }

  @override
  String get adminForceCancel => 'Forzar cancelación';

  @override
  String get adminFailedLoadBookings => 'Error al cargar las reservas';

  @override
  String get adminYesCancel => 'Sí, cancelar';

  @override
  String get adminSearchCustomerProfessional => 'Buscar cliente o profesional…';

  @override
  String adminCancelBooking(String value1) {
    return '¿Cancelar la reserva #$value1?';
  }

  @override
  String adminReflectBothCustomerProfessional(String value1, String value2) {
    return '$value1 → $value2 Esto se reflejará tanto para el cliente como para el profesional.';
  }

  @override
  String get adminVerificationRequests => 'Solicitudes de verificación';

  @override
  String adminPendingOldestFirst(String value1) {
    return '$value1 pendientes · más antiguas primero';
  }

  @override
  String get adminOldest => 'MÁS ANTIGUO';

  @override
  String get adminApproveVerification => '¿Aprobar verificación?';

  @override
  String adminMarkedAsVerifiedProfessional(String value1) {
    return '$value1 será marcado como profesional verificado.';
  }

  @override
  String adminRejectSRequest(String value1) {
    return '¿Rechazar la solicitud de $value1?';
  }

  @override
  String get adminReasonSentProfessionalSoTheyCan =>
      'Este motivo se enviará al profesional para que pueda volver a enviar su solicitud.';

  @override
  String adminFailedRequest(String value1) {
    return 'Error al $value1 la solicitud.';
  }

  @override
  String get adminNoPendingVerificationRequests =>
      'No hay solicitudes de verificación pendientes 🎉';

  @override
  String get adminFailedLoadVerificationRequests =>
      'Error al cargar las solicitudes de verificación';

  @override
  String get adminSearchByNameEmailCategory2 =>
      'Buscar por nombre, correo o categoría…';

  @override
  String get adminEGCnicImageBlurryPlease =>
      'ej. la imagen del CNIC está borrosa, por favor vuelve a subirla…';

  @override
  String get adminFailedCancelItMayHaveAlready =>
      'Error al cancelar — puede que ya se haya enviado.';

  @override
  String get adminCompose => 'Redactar';

  @override
  String adminScheduledFor(String value1) {
    return 'Programado para: $value1';
  }

  @override
  String adminSentUsersOpenRate(String value1, String value2) {
    return 'Enviado a $value1 usuarios · Tasa de apertura: $value2%';
  }

  @override
  String get adminComposeNotification => 'Redactar notificación';

  @override
  String get adminAudience => 'Audiencia';

  @override
  String get adminScheduleLater => 'Programar para más tarde';

  @override
  String get adminFailedSendNotification => 'Error al enviar la notificación.';

  @override
  String get adminFailedLoadNotifications =>
      'Error al cargar las notificaciones';

  @override
  String get adminTitle => 'Título';

  @override
  String get adminMessage => 'Mensaje';

  @override
  String get adminUserId => 'ID de usuario';

  @override
  String get adminDeleteAnnouncement => '¿Eliminar anuncio?';

  @override
  String adminRemove(String value1) {
    return '¿Eliminar \"$value1\"?';
  }

  @override
  String get adminNewAnnouncement => 'Nuevo anuncio';

  @override
  String get adminAnnouncements => 'Anuncios';

  @override
  String get adminType => 'Tipo';

  @override
  String get adminFailedCreate => 'Error al crear.';

  @override
  String get adminPublish => 'Publicar';

  @override
  String get adminNoAnnouncementsYet => 'Aún no hay anuncios';

  @override
  String get adminFailedLoadAnnouncements => 'Error al cargar los anuncios';

  @override
  String get adminMagazineAnalytics => 'Analítica de la revista';

  @override
  String adminViews(String value1) {
    return '$value1 vistas';
  }

  @override
  String adminOfTotal(String value1) {
    return '$value1% del total';
  }

  @override
  String get adminNoViewsYet => 'Aún no hay vistas.';

  @override
  String get adminRecentViewers => 'Espectadores recientes';

  @override
  String get adminComplaints => 'Quejas';

  @override
  String adminVs(String value1, String value2) {
    return '$value1 vs $value2';
  }

  @override
  String adminAssignedTo(String value1) {
    return 'Asignado a: $value1';
  }

  @override
  String get adminAssignMe => 'Asignarme';

  @override
  String get adminResolve => 'Resolver';

  @override
  String get adminFailedAssign => 'Error al asignar.';

  @override
  String get adminFailedLoadComplaints => 'Error al cargar las quejas';

  @override
  String get adminResolutionNote => 'Nota de resolución';

  @override
  String get authWelcomeProfinder => '¡Bienvenido a ProFinder!';

  @override
  String get authPleaseVerifyEmailActivateAccount =>
      'Por favor verifica tu correo para activar tu cuenta.';

  @override
  String get authContinueLogin => 'Continuar al inicio de sesión';

  @override
  String get profileNoPaymentsYet => 'Aún no hay pagos';

  @override
  String get profileTransactionHistoryAppearHere =>
      'Tu historial de transacciones aparecerá aquí';

  @override
  String get profileWallet => 'Billetera';

  @override
  String get profileTotalSpent => 'Total gastado';

  @override
  String profileAcrossTransaction(String value1, String value2) {
    return 'En $value1 transacción$value2';
  }

  @override
  String profileCurrentPlan(String value1) {
    return 'Plan actual: $value1';
  }

  @override
  String get profilePaymentHistory => 'Historial de pagos';

  @override
  String get profileViewAllTransactions => 'Ver todas tus transacciones';

  @override
  String get profileSavedProfessionals => 'Profesionales guardados';

  @override
  String get profileNoSavedProfessionalsYet =>
      'Aún no hay profesionales guardados';

  @override
  String get profileTapHeartAnyProfessionalSaveThem =>
      'Toca el corazón de cualquier profesional para guardarlo aquí';

  @override
  String profileHr(String value1, String value2) {
    return '$value1 • \$$value2/hr';
  }

  @override
  String get profileBook => 'Reservar';

  @override
  String get profileRemoveFromSaved => 'Quitar de guardados';

  @override
  String get profileChangeProfilePhoto => 'Cambiar foto de perfil';

  @override
  String get profileChooseFromGallery => 'Elegir de la galería';

  @override
  String get profileTakePhoto => 'Tomar una foto';

  @override
  String get profileMyProfile => 'Mi perfil';

  @override
  String get profileNewPhotoSelectedTapSaveUpload =>
      'Nueva foto seleccionada — toca Guardar para subirla';

  @override
  String get profilePersonalInformation => 'Información personal';

  @override
  String get profileSureWantLogout =>
      '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get profileMyReviews => 'Mis reseñas';

  @override
  String get profileNoReviewsWrittenYet => 'Aún no has escrito reseñas';

  @override
  String get profileCompleteBookingLeaveFirstReview =>
      'Completa una reserva para dejar tu primera reseña';

  @override
  String get profileSecurity => 'Seguridad';

  @override
  String profileWeLlEmailSecureResetLink(String value1) {
    return 'Te enviaremos un enlace seguro de restablecimiento a $value1.';
  }

  @override
  String get profileSignOutDevice => 'Cerrar sesión en este dispositivo';

  @override
  String get profileHelpSupport => 'Ayuda y soporte';

  @override
  String get profileNeedHand => '¿Necesitas ayuda?';

  @override
  String get profileReachOurSupportTeamAnytime =>
      'Contacta a nuestro equipo de soporte en cualquier momento';

  @override
  String get profileFrequentlyAskedQuestions => 'Preguntas frecuentes';

  @override
  String profileComingSoon(String value1) {
    return '$value1 próximamente';
  }

  @override
  String get profileBrowsingAsGuest => 'Estás navegando como invitado';

  @override
  String get profileLoginBookSaveManageRequests =>
      'Inicia sesión para reservar, guardar y administrar tus solicitudes';

  @override
  String get profileProfinderV100 => 'ProFinder v1.0.0';

  @override
  String get profileAboutProfinder => 'Acerca de ProFinder';

  @override
  String get profileProfinderHelpsFindHireTrustedProfessionals =>
      'ProFinder te ayuda a encontrar y contratar profesionales de confianza — médicos, abogados, tutores, ingenieros, plomeros y más — cerca de ti.';

  @override
  String get profileAccessBookingsProfile => 'Accede a tus reservas y perfil';

  @override
  String get profileCreateFreeCustomerAccount =>
      'Crea una cuenta de cliente gratuita';

  @override
  String get profileBecomeProfessional => 'Conviértete en profesional';

  @override
  String get profileListServicesGetHired =>
      'Publica tus servicios y consigue clientes';

  @override
  String get profileEnglish => 'Inglés';

  @override
  String get profileComingSoon2 => 'Próximamente';

  @override
  String get profilePrivacyPolicy => 'Política de privacidad';

  @override
  String get searchNoReviewsYet => 'Aún no hay reseñas';

  @override
  String get searchFirstReview => '¡Sé el primero en dejar una reseña!';

  @override
  String get searchNoPortfolioYet => 'Aún no hay portafolio';

  @override
  String get searchProfessionalHasNoApprovedWorkYet =>
      'Este profesional aún no tiene trabajos aprobados';

  @override
  String get searchHourlyRate => 'Tarifa por hora';

  @override
  String searchHr(String value1) {
    return '\$$value1/hr';
  }

  @override
  String get searchLoginBook => 'Inicia sesión para reservar';

  @override
  String get searchLoginRequired => 'Inicio de sesión requerido';

  @override
  String get searchPleaseLoginUseAiSearch =>
      'Por favor inicia sesión para usar la búsqueda con IA.';

  @override
  String get searchSearchHistory => 'Historial de búsqueda';

  @override
  String get searchNoSearchHistoryYet => 'Aún no hay historial de búsqueda';

  @override
  String searchPriceHr(String value1, String value2) {
    return 'Precio: \$$value1 — \$$value2/hr';
  }

  @override
  String searchMinRating(String value1) {
    return 'Calificación mínima: $value1 ★';
  }

  @override
  String get searchVerifiedOnly => 'Solo verificados';

  @override
  String get searchPreferredGender => 'Género preferido';

  @override
  String get searchAny => 'Cualquiera';

  @override
  String get searchFemale => 'Femenino';

  @override
  String get searchMale => 'Masculino';

  @override
  String searchMinExperienceYrs(String value1) {
    return 'Experiencia mínima: $value1+ años';
  }

  @override
  String get searchPreferredLanguage => 'Idioma preferido';

  @override
  String get searchNeedSomeoneNowUrgent => 'Necesito a alguien ya / Urgente';

  @override
  String get searchServiceMode => 'Modalidad de servicio';

  @override
  String get searchOnline => 'En línea';

  @override
  String get searchHomeVisit => 'Visita a domicilio';

  @override
  String get searchInOffice => 'En oficina';

  @override
  String get searchReset => 'Restablecer';

  @override
  String get searchApply => 'Aplicar';

  @override
  String searchNoResults(String value1) {
    return 'No hay resultados para \"$value1\"';
  }

  @override
  String get searchHereSomeAlternativesMightLike =>
      'Aquí tienes algunas alternativas que podrían gustarte';

  @override
  String get searchClearSearch => 'Borrar búsqueda';

  @override
  String searchKm(String value1) {
    return '$value1 km';
  }

  @override
  String searchFor(String value1) {
    return 'Para: \"$value1\"';
  }

  @override
  String searchToday(String value1, String value2) {
    return '$value1/$value2 hoy';
  }

  @override
  String get searchAlsoShowNormalResults =>
      'Mostrar también resultados normales';

  @override
  String searchNoExactMatch(String value1) {
    return 'No hay coincidencia exacta para \"$value1\"';
  }

  @override
  String get searchHereSomeRelevantAlternatives =>
      'Aquí tienes algunas alternativas relevantes';

  @override
  String get searchAiAgentLive => 'El agente de IA está activo';

  @override
  String searchFindingBestMatch(String value1) {
    return 'Buscando la mejor coincidencia para \"$value1\"';
  }

  @override
  String get searchRecentSearches => 'Búsquedas recientes';

  @override
  String searchSeeAll(String value1) {
    return 'Ver todo ($value1)';
  }

  @override
  String get searchClear => 'Borrar';

  @override
  String get searchPopularSearches => 'Búsquedas populares';

  @override
  String get searchBrowseByCategory => 'Explorar por categoría';

  @override
  String searchResultFor(String value1, String value2, String value3) {
    return '$value1 resultado$value2 para \"$value3\"';
  }

  @override
  String get searchGettingLocation => 'Obteniendo ubicación...';

  @override
  String get searchSortedByDistance => 'Ordenado por distancia';

  @override
  String get searchEnableLocation => 'Activar ubicación';

  @override
  String get searchPro => 'PRO';

  @override
  String get searchEGKarachiLahore => 'ej. Karachi, Lahore';

  @override
  String get searchEGUrduEnglish => 'ej. Urdu, Inglés';

  @override
  String get magazineHealthLegalHomeLifestyle =>
      'Salud · Legal · Hogar y estilo de vida';

  @override
  String get magazineCouldNotLoadArticles =>
      'No se pudieron cargar los artículos';

  @override
  String get magazineNoArticlesYet => 'Aún no hay artículos';

  @override
  String get magazineCheckBackSoonTipsAdvice =>
      'Vuelve pronto para más consejos.';

  @override
  String get magazineSearchArticles => 'Buscar artículos…';

  @override
  String magazineMinRead(String value1) {
    return '$value1 min de lectura';
  }

  @override
  String get magazineProfinderTipsMagazine => 'Revista de consejos ProFinder';

  @override
  String get magazineGoBack => 'Volver';

  @override
  String magazineMin(String value1) {
    return '$value1 min';
  }

  @override
  String get chatSharedMedia => 'Medios compartidos';

  @override
  String get chatNoSharedMediaYet => 'Aún no hay medios compartidos';

  @override
  String chatPhotos(String value1) {
    return 'Fotos ($value1)';
  }

  @override
  String chatVoiceMessages(String value1) {
    return 'Mensajes de voz ($value1)';
  }

  @override
  String chatS(String value1) {
    return '${value1}s';
  }

  @override
  String get chatSharedMedia2 => 'Medios compartidos';

  @override
  String get chatBlockUser => 'Bloquear usuario';

  @override
  String get chatReportUser => 'Reportar usuario';

  @override
  String chatBlock(String value1) {
    return '¿Bloquear a $value1?';
  }

  @override
  String get chatTheyNoLongerAbleSendMessages =>
      'Ya no podrá enviarte mensajes.';

  @override
  String get chatUnblockUser => 'Desbloquear usuario';

  @override
  String chatYouBlockedUser(String value1) {
    return 'Bloqueaste a $value1';
  }

  @override
  String get chatBlockedBannerSubtitle =>
      'No pueden llamarte ni enviarte mensajes. Desbloquea para continuar la conversación.';

  @override
  String get chatUnblockAction => 'Desbloquear';

  @override
  String get chatConversationUnavailable =>
      'Esta conversación no está disponible';

  @override
  String get chatConversationUnavailableSubtitle =>
      'No puedes enviar mensajes aquí en este momento.';

  @override
  String get chatMessageUnavailable => 'Mensaje no disponible';

  @override
  String get chatSayHello => 'Saluda 👋';

  @override
  String get chatSearchChat => 'Buscar en el chat';

  @override
  String get chatCouldNotLoadMessages => 'No se pudieron cargar los mensajes';

  @override
  String get chatMessages => 'Mensajes';

  @override
  String get chatNoConversationsYet => 'Aún no hay conversaciones';

  @override
  String get chatSearchMessages => 'Buscar mensajes...';

  @override
  String get chatMicrophonePermissionRequiredVoiceMessages =>
      'Se requiere permiso del micrófono para los mensajes de voz.';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatSendPhoto => 'Enviar una foto';

  @override
  String get chatReportSubmittedThank => 'Reporte enviado. Gracias.';

  @override
  String get chatCouldNotSubmitReportTryAgain =>
      'No se pudo enviar el reporte. Intenta de nuevo.';

  @override
  String chatReport(String value1) {
    return 'Reportar a $value1';
  }

  @override
  String get chatSubmit => 'Enviar';

  @override
  String get chatAdditionalDetailsOptional => 'Detalles adicionales (opcional)';

  @override
  String get chatMessageWasDeleted => 'Este mensaje fue eliminado';

  @override
  String get chatEdited => 'editado ·';

  @override
  String get chatReply => 'Responder';

  @override
  String get chatDeleteMe => 'Eliminar para mí';

  @override
  String get chatDeleteEveryone => 'Eliminar para todos';

  @override
  String get chatEditMessage => 'Editar mensaje';

  @override
  String get notificationsMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsNoNotificationsYet => 'Aún no hay notificaciones';

  @override
  String get notificationsBookingUpdatesAurAlertsYahanDikhenge =>
      'Las actualizaciones de reservas y alertas aparecerán aquí';

  @override
  String get professionalDelete => '¿Eliminar?';

  @override
  String professionalDelete2(String value1) {
    return '¿Eliminar \"$value1\"?';
  }

  @override
  String get professionalAddPortfolioItem => 'Agregar elemento al portafolio';

  @override
  String get professionalTapAddImage => 'Toca para agregar una imagen';

  @override
  String get professionalPortfolioReviewedByAdminOnceApproved =>
      'Tu portafolio será revisado por un administrador. Una vez aprobado, obtendrás una insignia de verificado.';

  @override
  String get professionalSubmitReview => 'Enviar para revisión';

  @override
  String get professionalMyPortfolio => 'Mi portafolio';

  @override
  String get professionalNoPortfolioItemsYet =>
      'Aún no hay elementos en el portafolio';

  @override
  String get professionalAddWorkGetVerified =>
      'Agrega tu trabajo para verificarte';

  @override
  String get professionalAddFirstItem => 'Agregar primer elemento';

  @override
  String professionalNote(String value1) {
    return 'Nota: $value1';
  }

  @override
  String get professionalTitle => 'Título *';

  @override
  String get professionalEGHouseConstructionProject =>
      'ej. Proyecto de construcción de casa';

  @override
  String get professionalBriefDescriptionWork =>
      'Breve descripción de este trabajo...';

  @override
  String get professionalAddPortfolio => 'Agregar portafolio';

  @override
  String get professionalTypeMessage => 'Escribe un mensaje...';

  @override
  String get professionalDeletePhoto => '¿Eliminar foto?';

  @override
  String get professionalPhotoRemovedFromGallery =>
      'Esta foto se eliminará de tu galería.';

  @override
  String get professionalGallery => 'Galería';

  @override
  String get professionalNoPhotosYet => 'Aún no hay fotos';

  @override
  String get professionalAddPhotosShowcaseWorkEnvironment =>
      'Agrega fotos para mostrar tu entorno de trabajo';

  @override
  String get professionalAddPhoto => 'Agregar foto';

  @override
  String get professionalWorkingHours => 'Horario de trabajo';

  @override
  String get professionalProfessionalDetails => 'Detalles profesionales';

  @override
  String get professionalSkills => 'Habilidades';

  @override
  String get professionalNoSkillsAddedYet =>
      'Aún no se han agregado habilidades';

  @override
  String get professionalBankDetails => 'Datos bancarios';

  @override
  String get professionalCertificates => 'Certificados';

  @override
  String get professionalWalletEarnings => 'Billetera y ganancias';

  @override
  String get professionalSubscriptionUpgradePremium =>
      'Suscripción / Actualizar a Premium';

  @override
  String get professionalChangePassword => 'Cambiar contraseña';

  @override
  String get professionalAddSkill => '+ Agregar habilidad';

  @override
  String get professionalAddLanguage => '+ Agregar idioma';

  @override
  String get professionalNeedMoreHelp => '¿Necesitas más ayuda?';

  @override
  String get professionalOurSupportTeamRepliesWithin24 =>
      'Nuestro equipo de soporte responde en 24 horas';

  @override
  String get professionalContact => 'Contacto';

  @override
  String get professionalContactSupport => 'Contactar soporte';

  @override
  String get professionalSupportProfinderCom => 'support@profinder.com';

  @override
  String get professionalEmailUsAnytime => 'Escríbenos en cualquier momento';

  @override
  String get professionalLiveChat => 'Chat en vivo';

  @override
  String get professionalAvailable9Am6Pm => 'Disponible de 9 AM a 6 PM';

  @override
  String professionalRePlan(String value1) {
    return 'Estás en el plan $value1';
  }

  @override
  String get professionalUpgradeMoreBookingsFeaturedProfilePriority =>
      'Actualiza para más reservas, perfil destacado y prioridad en el ranking';

  @override
  String get professionalUpgrade => 'Actualizar';

  @override
  String get professionalProfileCompletion => 'Completitud del perfil';

  @override
  String get professionalCompleteProfileGetMoreBookings =>
      'Completa tu perfil para conseguir más reservas';

  @override
  String professionalNoClientsFound(String value1) {
    return 'No se encontraron clientes para \"$value1\"';
  }

  @override
  String get professionalQuickActions => 'Acciones rápidas';

  @override
  String get professionalEarnings => 'Ganancias';

  @override
  String get professionalViewWallet => 'Ver billetera';

  @override
  String get professionalPerformance => 'Rendimiento';

  @override
  String get professionalTodaySSchedule => 'Horario de hoy';

  @override
  String get professionalNoBookingsScheduledToday =>
      'No hay reservas programadas para hoy';

  @override
  String get professionalRecentMessages => 'Mensajes recientes';

  @override
  String get professionalSeeAll => 'Ver todo';

  @override
  String get professionalNoMessagesYet => 'Aún no hay mensajes';

  @override
  String get professionalSkillsPricing => 'Habilidades y precios';

  @override
  String get professionalManage => 'Administrar';

  @override
  String get professionalAddWorkSamples => 'Agrega muestras de tu trabajo';

  @override
  String get professionalGetVerifiedByAddingPortfolio =>
      'Verifícate agregando un portafolio';

  @override
  String get professionalRecentReviews => 'Reseñas recientes';

  @override
  String get professionalRecentBookings => 'Reservas recientes';

  @override
  String get professionalNoBookingsYet => 'Aún no hay reservas';

  @override
  String get professionalBookingDetails => 'Detalles de la reserva';

  @override
  String get professionalMarkAsCompleted => 'Marcar como completado';

  @override
  String get professionalCancelBooking => 'Cancelar reserva';

  @override
  String get professionalSearchBookingsByClientName =>
      'Buscar reservas por nombre de cliente...';

  @override
  String get professionalPortfolio => 'Portafolio';

  @override
  String get professionalAddCertificate => 'Agregar certificado';

  @override
  String get professionalTapAddCertificateImage =>
      'Toca para agregar imagen del certificado';

  @override
  String get professionalSaveCertificate => 'Guardar certificado';

  @override
  String get professionalNoCertificatesYet => 'Aún no hay certificados';

  @override
  String get professionalAddCertificationsBuildTrust =>
      'Agrega certificaciones para generar confianza';

  @override
  String get professionalAddFirstCertificate => 'Agregar primer certificado';

  @override
  String get professionalCertificateTitle => 'Título del certificado *';

  @override
  String get professionalIssuingOrganization => 'Organización emisora';

  @override
  String get professionalEGCertifiedElectrician =>
      'ej. Electricista certificado';

  @override
  String get professionalEGTevtaCoursera => 'ej. TEVTA / Coursera';

  @override
  String get professionalCustomerConversationsShowUpHere =>
      'Las conversaciones con clientes aparecerán aquí';

  @override
  String get professionalCancelBooking2 => '¿Cancelar reserva?';

  @override
  String get professionalSureWantCancelBooking =>
      '¿Estás seguro de que deseas cancelar esta reserva?';

  @override
  String get professionalReasonCancellingOptional =>
      'Motivo de la cancelación (opcional)';

  @override
  String get professionalYesCancelIt => 'Sí, cancelar';

  @override
  String professionalNoBookings(String value1) {
    return 'No hay reservas $value1';
  }

  @override
  String get professionalDecline => 'Rechazar';

  @override
  String get professionalEGNotAvailableThatDay =>
      'ej. no disponible ese día, surgió una emergencia...';

  @override
  String professionalReview(String value1, String value2) {
    return '$value1 reseña$value2';
  }

  @override
  String get professionalWithdrawEarnings => 'Retirar ganancias';

  @override
  String professionalAvailable(String value1) {
    return 'Disponible: \$$value1';
  }

  @override
  String professionalMinimumWithdrawal(String value1) {
    return 'Retiro mínimo: \$$value1';
  }

  @override
  String get professionalRequestWithdrawal => 'Solicitar retiro';

  @override
  String get professionalBankDetailsRequired => 'Se requieren datos bancarios';

  @override
  String get professionalPleaseAddBankAccountDetailsProfile =>
      'Por favor agrega los datos de tu cuenta bancaria en tu perfil antes de solicitar un retiro.';

  @override
  String get professionalAvailableBalance => 'Saldo disponible';

  @override
  String get professionalWithdraw => 'Retirar';

  @override
  String get professionalNoTransactionsYet => 'Aún no hay transacciones';

  @override
  String get professionalEnterAmount => 'Ingresa el monto';

  @override
  String get professionalPerformanceScore => 'Puntuación de rendimiento';

  @override
  String get professionalOut100 => 'de 100';

  @override
  String get professionalPerformanceScore40Rating30Acceptance =>
      'Puntuación de rendimiento = 40% calificación + 30% tasa de aceptación + 30% tasa de respuesta.';

  @override
  String get professionalDashboard => 'Panel';

  @override
  String get professionalMagazine => 'Revista';

  @override
  String get professionalEnterCurrentPasswordNewPassword =>
      'Ingresa tu contraseña actual y una nueva contraseña.';

  @override
  String get professionalUpdate => 'Actualizar';

  @override
  String get professionalCurrentPassword => 'Contraseña actual';

  @override
  String get professionalNewPassword => 'Nueva contraseña';

  @override
  String get professionalConfirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get homeBecomePro => 'Hazte Pro';

  @override
  String get homeLoginRequired => 'Inicio de sesión requerido';

  @override
  String get homeCreateAccount => 'Crear una cuenta';

  @override
  String get homeWelcomeGuest => 'Bienvenido, invitado';

  @override
  String get homeHireRightExpertMinutes =>
      'Contrata al experto adecuado, en minutos.';

  @override
  String get homeSearchDoctorsLawyersPlumbers =>
      'Buscar médicos, abogados, plomeros…';

  @override
  String get homeViewAll => 'Ver todo';

  @override
  String get homeAllCategories => 'Todas las categorías';

  @override
  String get homeFeatured => 'DESTACADO';

  @override
  String get homeExploreExperts => 'Explorar expertos →';

  @override
  String get homeProfessional => '¿Eres un profesional?';

  @override
  String get homeJoinProfinderGetDiscoveredByThousands =>
      'Únete a ProFinder y deja que miles de clientes te descubran.';

  @override
  String get homeUnlockFullExperience => 'Desbloquea la experiencia completa';

  @override
  String get homeBookProfessionalsSaveFavouritesTrackRequests =>
      'Reserva profesionales, guarda favoritos y rastrea tus solicitudes.';

  @override
  String get homeNoProfessionalsNearbyYet => 'Aún no hay profesionales cerca';

  @override
  String get homeTrySearchingCategoryCheckBackSoon =>
      'Intenta buscar una categoría o vuelve pronto.';

  @override
  String get homeSearchNow => 'Buscar ahora';

  @override
  String get homeFilter => 'Filtrar';

  @override
  String homePrice(String value1, String value2) {
    return 'Precio: \$$value1 — $value2';
  }

  @override
  String get homeVerifiedOnly => 'Solo verificados';

  @override
  String get homeNoProfessionalsAvailableCity =>
      'No hay profesionales disponibles en tu ciudad.';

  @override
  String get homeTrySearchingNearbyCities =>
      'Intenta buscar en ciudades cercanas.';

  @override
  String homeHi(String value1) {
    return 'Hola, $value1 👋';
  }

  @override
  String get homeGetPersonalizedPicks => 'Obtén recomendaciones personalizadas';

  @override
  String get homeBookFirstServiceWeLlStart =>
      'Reserva tu primer servicio y comenzaremos a personalizar esto para ti.';

  @override
  String get homeBrowse => 'Explorar';

  @override
  String get homeAiPick => '✨ SELECCIÓN DE IA PARA TI';

  @override
  String get homeBookAgain => 'Reservar de nuevo';

  @override
  String get homeClearAll => 'Borrar todo';

  @override
  String get homeNoUpcomingBookings => 'No hay próximas reservas';

  @override
  String get homeBrowseProfessionals => 'Explorar profesionales';

  @override
  String get homeViewDetails => 'Ver detalles';

  @override
  String homeCancelledBy(String value1, String value2) {
    return 'Cancelado por $value1: $value2';
  }

  @override
  String get homeRateExperience => 'Califica tu experiencia ⭐';

  @override
  String homePlan(String value1) {
    return 'Plan: $value1';
  }

  @override
  String get homeRecentChats => 'Chats recientes';

  @override
  String get homeNoMessagesYet => 'Aún no hay mensajes.';

  @override
  String get homeStartConversationAfterBookingProfessional =>
      'Inicia una conversación después de reservar a un profesional.';

  @override
  String homeNotifications(String value1) {
    return 'Notificaciones$value1';
  }

  @override
  String get homeAiSuggestions => 'Sugerencias de IA';

  @override
  String get homeUnlimited => 'Ilimitado ✨';

  @override
  String homeUsedToday(String value1, String value2) {
    return '$value1 de $value2 usados hoy';
  }

  @override
  String get homeJustTellUsWhatNeedWe =>
      'Solo dinos lo que necesitas y te conectaremos al instante con el profesional verificado adecuado.';

  @override
  String get homeDailyLimitReachedResetsMidnight =>
      'Límite diario alcanzado — se restablece a medianoche';

  @override
  String get homeNeedHelpWeReHere => '¿Necesitas ayuda? Estamos aquí para ti';

  @override
  String get homeGetResponseWithin24Hours => 'Obtén una respuesta en 24 horas';

  @override
  String get homeHelpCenter => 'Centro de ayuda';

  @override
  String get homeEGINeedPlumberLeaking =>
      'ej. necesito un plomero para una tubería con fuga…';

  @override
  String get homePopularCategories => 'Categorías populares';

  @override
  String get homeUpcomingBookings => 'Próximas reservas';

  @override
  String get bookingsBookProfessionalFromHomeScreen =>
      'Reserva un profesional desde la pantalla de inicio';

  @override
  String get bookingsEGScheduleChangedNoLonger =>
      'ej. cambió el horario, ya no se necesita...';

  @override
  String get bookingsBookingSent => '¡Reserva enviada!';

  @override
  String bookingsRequestSentNotifiedOnceTheyRespond(String value1) {
    return 'Solicitud enviada a $value1. Se te notificará cuando responda.';
  }

  @override
  String get bookingsViewMyBookings => 'Ver mis reservas';

  @override
  String get bookingsBackHome => 'Volver al inicio';

  @override
  String get bookingsBookAppointment => 'Reservar cita';

  @override
  String get bookingsSummary => 'Resumen';

  @override
  String get bookingsConfirmBooking => 'Confirmar reserva';

  @override
  String get bookingsDescribeIssueRequirements =>
      'Describe tu problema o requisitos...';

  @override
  String get bookingsShareExperience => 'Comparte tu experiencia';

  @override
  String get bookingsYourRating => 'Tu calificación';

  @override
  String get bookingsCommentOptional => 'Tu comentario (opcional)';

  @override
  String get bookingsReviewSubmitted => '¡Reseña enviada! 🎉';

  @override
  String bookingsThankReviewingFeedbackHelpsOthersMake(String value1) {
    return 'Gracias por reseñar a $value1. Tu opinión ayuda a otros a tomar mejores decisiones.';
  }

  @override
  String get bookingsBackBookings => 'Volver a reservas';

  @override
  String bookingsDescribeExperience(String value1) {
    return 'Describe tu experiencia con $value1...';
  }

  @override
  String get subscriptionConfirmSubscription => 'Confirmar suscripción';

  @override
  String subscriptionSubscribe(String value1, String value2, String value3) {
    return 'Suscribirse a $value1 por $value2 $value3';
  }

  @override
  String get subscriptionSubscribe2 => 'Suscribirse';

  @override
  String get subscriptionChoosePlan => 'Elige tu plan';

  @override
  String get subscriptionAvailablePlans => 'Planes disponibles';

  @override
  String subscriptionCurrentPlan(String value1) {
    return 'Plan actual: $value1';
  }

  @override
  String subscriptionValidUntil(String value1) {
    return 'Válido hasta: $value1';
  }

  @override
  String get subscriptionUpgradeUnlockPremiumFeatures =>
      'Actualiza para desbloquear funciones premium';

  @override
  String get subscriptionRecommended => 'RECOMENDADO';

  @override
  String get subscriptionCurrentPlan2 => 'PLAN ACTUAL';

  @override
  String get subscriptionCurrentPlan3 => 'Plan actual';

  @override
  String get subscriptionBasicPlan => 'Plan básico';

  @override
  String subscriptionGet(String value1) {
    return 'Obtener $value1';
  }

  @override
  String get subscriptionCancelAnytimeSecurePayment =>
      'Cancela cuando quieras • Pago seguro';

  @override
  String get subscriptionBookingLimitReached =>
      '¡Límite de reservas alcanzado!';

  @override
  String subscriptionVeUsedBookingsMonthFreePlan(String value1, String value2) {
    return 'Has usado $value1/$value2 reservas este mes en tu plan gratuito.';
  }

  @override
  String get subscriptionUpgradePremium => 'Actualizar a Premium';

  @override
  String get subscriptionMaybeLater => 'Quizás luego';

  @override
  String get subscriptionMonthlyBookings => 'Reservas mensuales';

  @override
  String get subscriptionPremiumIncludes => 'Premium incluye:';

  @override
  String get subscriptionAiSearchLimitReached =>
      '¡Límite de búsquedas con IA alcanzado!';

  @override
  String subscriptionVeUsedAiSearchesTodayAi(String value1, String value2) {
    return 'Has usado $value1/$value2 búsquedas con IA hoy. El chat de IA está bloqueado hasta que se restablezca tu límite.';
  }

  @override
  String get subscriptionAiSearchesToday => 'Búsquedas con IA hoy';

  @override
  String get subscriptionGetPremium20AiDay => 'Obtén Premium — 20 IA/día';

  @override
  String get subscriptionContinueNormalSearch =>
      'Continuar con búsqueda normal';

  @override
  String get subscriptionPremiumAiFeatures => 'Funciones de IA Premium:';

  @override
  String get subscriptionProfinderPremium => 'ProFinder Premium';

  @override
  String sharedYExp(String value1) {
    return '$value1 años de exp.';
  }

  @override
  String get sharedViewProfile => 'Ver perfil';

  @override
  String get homeNotificationsSignInMessage =>
      'Las notificaciones están disponibles después de iniciar sesión. Inicia sesión o crea una cuenta para ver actualizaciones de reservas y alertas personalizadas.';

  @override
  String get homeSetUpProfileMessage =>
      'Inicia sesión o crea una cuenta para configurar tu perfil.';

  @override
  String get homeLoginToSaveFavourites =>
      'Inicia sesión para guardar profesionales en tus favoritos.';

  @override
  String homeLoginToBookName(String value1) {
    return 'Inicia sesión para reservar a $value1 y gestionar tus citas.';
  }

  @override
  String get homeWhatAreYouLookingForToday => '¿Qué estás buscando hoy?';

  @override
  String get homeTrendingLabel => 'Tendencia';

  @override
  String get homeFeaturedCategoriesSection => 'Categorías destacadas';

  @override
  String get homeTopRatedProfessionals => 'Profesionales mejor calificados';

  @override
  String get homeTopRatedLabel => 'Mejor calificados';

  @override
  String get homeTrendingThisWeek => 'Tendencia esta semana';

  @override
  String get homePopularProfessionals => 'Profesionales populares';

  @override
  String get homePopularLabel => 'Popular';

  @override
  String get homeRecentlyAdded => 'Añadidos recientemente';

  @override
  String get homeNewLabel => 'Nuevo';

  @override
  String get homeFromTheMagazine => 'De la revista';

  @override
  String homeNearLocation(String value1) {
    return 'Cerca de $value1';
  }

  @override
  String homeProfessionalsInLocation(String value1) {
    return 'Profesionales en $value1';
  }

  @override
  String get homeClosestProfessionals => 'Profesionales más cercanos';

  @override
  String get homeTopRatedProfessionalsNationwide =>
      'Profesionales mejor calificados a nivel nacional';

  @override
  String get homeNearbyLabel => 'Cercano';

  @override
  String get homeArticleLabel => 'Artículo';

  @override
  String get homeGoodMorning => 'Buenos días';

  @override
  String get homeGoodAfternoon => 'Buenas tardes';

  @override
  String get homeGoodEvening => 'Buenas noches';

  @override
  String get homeWhatServiceAreYouLookingFor => '¿Qué servicio buscas hoy?';

  @override
  String get proReadyToGrowToday => '¿Listo para hacer crecer tu negocio hoy?';

  @override
  String get homeSetYourLocation => 'Configura tu ubicación';

  @override
  String get homeCityHint => 'p. ej. Karachi, Lahore';

  @override
  String get homeNoLimit => 'Sin límite';

  @override
  String homeMinRatingLabel(String value1) {
    return 'Calificación mínima: $value1 ★';
  }

  @override
  String get homeResetButton => 'Restablecer';

  @override
  String get homeApplyButton => 'Aplicar';

  @override
  String get homeFilteredResults => 'Resultados filtrados';

  @override
  String get homeRecommendedForYou => 'Recomendado para ti';

  @override
  String get homeRecommendedLabel => 'Recomendado';

  @override
  String get homeSavedQuickAction => 'Guardados';

  @override
  String get homeWalletQuickAction => 'Billetera';

  @override
  String get homeHelpQuickAction => 'Ayuda';

  @override
  String get homeRecentSearches => 'Búsquedas recientes';

  @override
  String get homeRecentBookingsTitle => 'Reservas recientes';

  @override
  String get homeConfirmedStatus => 'Confirmada';

  @override
  String get homeDeclinedStatus => 'Rechazada';

  @override
  String get homeCancelledStatus => 'Cancelada';

  @override
  String get homeSystemLabel => 'sistema';

  @override
  String get homeTotalSpent => 'Total gastado';

  @override
  String homeAcrossTransaction(String value1) {
    return 'En $value1 transacción';
  }

  @override
  String homeAcrossTransactions(String value1) {
    return 'En $value1 transacciones';
  }

  @override
  String get homeManageButton => 'Administrar';

  @override
  String get homeUpgradeButton => 'Mejorar';

  @override
  String get homePaymentHistoryTitle => 'Historial de pagos';

  @override
  String get homeTotalLabel => 'Total';

  @override
  String get homeSayHello => 'Saluda 👋';

  @override
  String get homeMagazineNavLabel => 'Revista';

  @override
  String get homeMessagesNavLabel => 'Mensajes';

  @override
  String get homeTipsMagazineTitle => 'Revista de consejos';

  @override
  String get homeFeaturedArticlesTitle => 'Artículos destacados';

  @override
  String get homeContactButton => 'Contactar';

  @override
  String get homeAiPickForYou => 'SELECCIÓN DE IA PARA TI';

  @override
  String get homeMessagingComingSoonTitle => 'Mensajería';

  @override
  String get homeMessagingComingSoonMessage =>
      'Aquí podrás chatear directamente con los profesionales.';

  @override
  String get commonOn => 'Activado';

  @override
  String get commonOff => 'Desactivado';

  @override
  String get profileVersionLabel => 'Versión 1.0.0';

  @override
  String get searchAiSearchFailedTryNormal =>
      'La búsqueda con IA falló. Prueba la búsqueda normal.';

  @override
  String get searchFailedCheckConnection =>
      'La búsqueda falló. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get searchClearAll => 'Borrar todo';

  @override
  String get searchDistanceAny => 'Distancia: Cualquiera';

  @override
  String searchWithinKm(String value1) {
    return 'En un radio de $value1 km';
  }

  @override
  String get searchSortPriceLowHigh => 'Precio: de menor a mayor';

  @override
  String get searchSortPriceHighLow => 'Precio: de mayor a menor';

  @override
  String searchAiSearchesLeft(String value1) {
    return '$value1 restantes';
  }

  @override
  String get searchSimilarProfessionals => 'Profesionales similares';

  @override
  String get searchProfessionalsNearYou => 'Profesionales cerca de ti';

  @override
  String get searchTrendingCategories => 'Categorías en tendencia';

  @override
  String get searchAiPremiumResults => 'Resultados IA Premium';

  @override
  String get searchAiSearchResultsTitle => 'Resultados de búsqueda con IA';

  @override
  String get searchNoMatchingProfessionalsFound =>
      'No se encontraron profesionales coincidentes.';

  @override
  String get searchRelatedProfessions => 'Profesiones relacionadas';

  @override
  String get searchTrendingProfessionals => 'Profesionales en tendencia';

  @override
  String get searchPopularNearby => 'Populares cerca';

  @override
  String get searchShowingResultsFor => 'Mostrando resultados para: ';

  @override
  String searchMetersAway(String value1) {
    return 'a $value1 m';
  }

  @override
  String searchKmNearYou(String value1) {
    return '$value1 km · cerca de ti';
  }

  @override
  String searchKmAway(String value1) {
    return 'a $value1 km';
  }

  @override
  String searchApproxKm(String value1) {
    return '~$value1 km';
  }

  @override
  String searchApproxKmNearbyCity(String value1) {
    return '~$value1 km · ciudad cercana';
  }

  @override
  String get searchDifferentArea => 'Zona diferente';

  @override
  String get searchAiHintPlaceholder =>
      'Pregunta a la IA: búscame un plomero...';

  @override
  String get searchNameCityProfessionHint => 'Nombre, ciudad, profesión...';

  @override
  String get searchAiSearchOnTapDisable =>
      'Búsqueda IA activada — Toca para desactivar';

  @override
  String get searchTryAiSearchSmarterResults =>
      'Prueba la búsqueda con IA — resultados más inteligentes';

  @override
  String get subscriptionFailedToLoadPlans => 'Error al cargar los planes.';

  @override
  String subscriptionSubscribedTo(String value1) {
    return '¡Suscrito a $value1!';
  }

  @override
  String get subscriptionSubscriptionFailed => 'La suscripción falló.';

  @override
  String get subscriptionPerMonth => '/mes';

  @override
  String get subscriptionPerYear => '/año';

  @override
  String get subscriptionFreeForever => 'Gratis para siempre';

  @override
  String get subscriptionBilledMonthly => 'Facturación mensual';

  @override
  String get subscriptionBilledYearly => 'Facturación anual';

  @override
  String get subscriptionFree => 'GRATIS';

  @override
  String get subscriptionUnlimited => 'Ilimitado';

  @override
  String get subscriptionUpgradeUnlimitedAiSearches =>
      'Actualiza para búsquedas con IA ilimitadas y más';

  @override
  String get subscriptionUpgradeUnlimitedBookings =>
      'Actualiza para reservas ilimitadas y clasificación prioritaria';

  @override
  String get subscriptionFeatureAiSearchesDay => 'Búsquedas IA/día';

  @override
  String get subscriptionFeatureMessagesDay => 'Mensajes/día';

  @override
  String get subscriptionFeatureUnlimitedBookings => 'Reservas ilimitadas';

  @override
  String get subscriptionFeaturePrioritySupport => 'Soporte prioritario';

  @override
  String get subscriptionFeaturePremiumBadge => 'Insignia Premium';

  @override
  String get subscriptionFeatureNoAds => 'Sin anuncios';

  @override
  String get subscriptionFeatureBookingsMonth => 'Reservas/mes';

  @override
  String get subscriptionFeaturePortfolioImages => 'Imágenes de portafolio';

  @override
  String get subscriptionFeatureServicesListed => 'Servicios ofrecidos';

  @override
  String get subscriptionFeatureFeaturedProfile => 'Perfil destacado';

  @override
  String get subscriptionFeaturePriorityRanking => 'Clasificación prioritaria';

  @override
  String subscriptionLimitResetsOn(String value1) {
    return 'Tu límite se restablecerá el $value1';
  }

  @override
  String get subscriptionLimitResetsNextMonth =>
      'Tu límite se restablecerá a principios del próximo mes';

  @override
  String get subscriptionFeatureUnlimitedBookingsMonth =>
      'Reservas ilimitadas cada mes';

  @override
  String get subscriptionFeatureFeaturedProfileSearch =>
      'Perfil destacado en los resultados de búsqueda';

  @override
  String get subscriptionFeaturePriorityAiRanking =>
      'Clasificación IA prioritaria';

  @override
  String get subscriptionFeatureNoAdsProfile => 'Sin anuncios en tu perfil';

  @override
  String get subscriptionAiResetsTomorrowMidnight =>
      'Tus búsquedas con IA se restablecerán mañana a medianoche';

  @override
  String subscriptionResetsAt(String value1, String value2) {
    return 'Se restablece $value1 a las $value2';
  }

  @override
  String get commonToday => 'hoy';

  @override
  String get commonTomorrow => 'mañana';

  @override
  String get subscriptionBenefit20AiSearchesDay =>
      '20 búsquedas con IA por día';

  @override
  String get subscriptionBenefitAdvancedAiRecommendations =>
      'Recomendaciones de IA avanzadas';

  @override
  String get subscriptionBenefitSearchByBudgetLocationHistory =>
      'Busca por presupuesto, ubicación e historial';

  @override
  String get subscriptionBenefitPriorityMatchingResults =>
      'Resultados de coincidencia prioritarios';

  @override
  String get subscriptionNoThanksMaybeLater => 'No gracias, más tarde';

  @override
  String subscriptionPleaseWaitSeconds(String value1) {
    return 'Espera $value1 segundos...';
  }

  @override
  String get chatPhotoReplyPlaceholder => '📷 Foto';

  @override
  String get chatMuteConversation => 'Silenciar conversación';

  @override
  String get chatUnmuteConversation => 'Activar sonido de conversación';

  @override
  String get chatConversationMuted => 'Conversación silenciada';

  @override
  String get chatConversationUnmuted => 'Sonido de conversación activado';

  @override
  String get chatTyping => 'escribiendo…';

  @override
  String chatLastSeen(String value1) {
    return 'Última vez visto $value1';
  }

  @override
  String get chatReasonSpam => 'Spam';

  @override
  String get chatReasonHarassmentBullying => 'Acoso o intimidación';

  @override
  String get chatReasonInappropriateContent => 'Contenido inapropiado';

  @override
  String get chatReasonScamFraud => 'Estafa o fraude';

  @override
  String get chatReasonFakeProfile => 'Perfil falso';

  @override
  String get chatReasonOther => 'Otro';

  @override
  String get aboutActionLabel => 'Acerca de';

  @override
  String get aboutActionSubtitle => 'Acerca de esta aplicación';

  @override
  String get aboutAppStoreLabel => 'App Store';

  @override
  String get aboutDisabledBadgeLabel => 'No disponible';

  @override
  String get aboutEmptyStateMessage =>
      'No pudimos encontrar información para mostrar en este momento.';

  @override
  String get aboutEmptyStateTitle => 'Nada que mostrar';

  @override
  String get aboutGooglePlayLabel => 'Google Play';

  @override
  String get aboutLabel => 'Acerca de';

  @override
  String aboutLinkCouldNotOpen(Object value1) {
    return 'No se pudo abrir este enlace $value1';
  }

  @override
  String aboutLinkError(Object value1) {
    return 'Algo salió mal al abrir el enlace $value1';
  }

  @override
  String aboutLinkNoAppFound(Object value1) {
    return 'No se encontró ninguna aplicación para abrir este enlace $value1';
  }

  @override
  String get aboutLoadError => 'Error al cargar esta página';

  @override
  String get aboutLoadingText => 'Cargando...';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get acceptCta => 'Aceptar';

  @override
  String get acceptDescription => 'Aceptar esta reserva';

  @override
  String get acceptLabel => 'Aceptar';

  @override
  String get acceptanceRateLabel => 'Tasa de aceptación';

  @override
  String get acceptanceRateSubtext => 'De las reservas que aceptas';

  @override
  String get acceptedLabel => 'Aceptada';

  @override
  String get acceptingBookingsLabel => 'Aceptando reservas';

  @override
  String get accountGroupLabel => 'Cuenta';

  @override
  String get accountHolderLabel => 'Nombre del titular de la cuenta';

  @override
  String get accountNumberLabel => 'Número de cuenta';

  @override
  String get accountSectionLabel => 'Cuenta';

  @override
  String get accountTypeLabel => 'Tipo de cuenta';

  @override
  String get addBankBannerSubtitle =>
      'Agrega tus datos bancarios para recibir retiros';

  @override
  String get addBankBannerTitle => 'Agregar datos bancarios';

  @override
  String get addBankCta => 'Agregar cuenta bancaria';

  @override
  String get addCertificateImageLabel => 'Imagen del certificado';

  @override
  String get addCertificateTitle => 'Agregar certificado';

  @override
  String get addCertificateTooltip => 'Agregar un certificado';

  @override
  String get addCta => 'Agregar';

  @override
  String get addFirstCertificateCta => 'Agrega tu primer certificado';

  @override
  String get addFirstItemCta => 'Agrega tu primer elemento';

  @override
  String get addImageLabel => 'Agregar imagen';

  @override
  String get addLanguageHint => 'Escribe un idioma y pulsa Intro';

  @override
  String get addPhotoCta => 'Agregar foto';

  @override
  String get addPhotoTooltip => 'Agregar una foto';

  @override
  String get addPortfolioHint =>
      'Muestra tus mejores trabajos para atraer más clientes';

  @override
  String get addPortfolioTitle => 'Agregar elemento al portafolio';

  @override
  String get addPortfolioTooltip => 'Agregar elemento al portafolio';

  @override
  String get addSkillHint => 'Escribe una habilidad y pulsa Intro';

  @override
  String get addWorkSamplesLabel => 'Agregar muestras de trabajo';

  @override
  String get adjustSearchTerms => 'Intenta ajustar tus términos de búsqueda';

  @override
  String get adminNoteLabel => 'Nota del administrador';

  @override
  String get allCategoriesTitle => 'Todas las categorías';

  @override
  String get analyticsErrorTitle => 'No se pudieron cargar las estadísticas';

  @override
  String get analyticsLoadError => 'Error al cargar las estadísticas';

  @override
  String get analyticsTitle => 'Estadísticas';

  @override
  String get applyCta => 'Aplicar';

  @override
  String get approvalSubtitle => 'Pendiente de aprobación del administrador';

  @override
  String get approvalTitle => 'Estado de aprobación';

  @override
  String get articleFooterMagazineLabel => 'Más de la revista';

  @override
  String get articleLoadingText => 'Cargando artículo...';

  @override
  String get articleNotFoundError => 'Artículo no encontrado';

  @override
  String get articleNotFoundMessage =>
      'Es posible que este artículo se haya eliminado o no exista';

  @override
  String articleReadTime(Object value1) {
    return '$value1 min de lectura';
  }

  @override
  String articleReadTimeLabel(Object value1) {
    return '$value1 min de lectura';
  }

  @override
  String get automaticDescription =>
      'Aceptar automáticamente las reservas que cumplan tus criterios';

  @override
  String get automaticLabel => 'Automático';

  @override
  String get availabilityClosedLabel => 'Cerrado';

  @override
  String get availabilityLabel => 'Disponibilidad';

  @override
  String get availabilityLoadError => 'Error al cargar la disponibilidad';

  @override
  String get availabilityOffSuccess => 'Ahora estás marcado como no disponible';

  @override
  String get availabilityOnSuccess => 'Ahora estás marcado como disponible';

  @override
  String get availabilityScheduleSaveError => 'Error al guardar el horario';

  @override
  String get availabilityScheduleSaved => 'Horario guardado correctamente';

  @override
  String get availabilityStatusUpdateError =>
      'Error al actualizar el estado de disponibilidad';

  @override
  String availabilityStatusUpdated(Object value1) {
    return 'Disponibilidad establecida en $value1';
  }

  @override
  String get availabilitySummarySubtitle =>
      'Tu horario laboral semanal de un vistazo';

  @override
  String get availabilitySummaryTitle => 'Resumen de disponibilidad';

  @override
  String get availabilityTitle => 'Disponibilidad';

  @override
  String get availabilityUpdateError => 'Error al actualizar la disponibilidad';

  @override
  String get availabilityWeeklySubtitle =>
      'Establece tu horario laboral para cada día';

  @override
  String get availabilityWeeklyTitle => 'Horario semanal';

  @override
  String availableBalanceLabel(Object value1) {
    return 'Saldo disponible: Rs $value1';
  }

  @override
  String get availableBalanceTitle => 'Saldo disponible';

  @override
  String get availableForBookingsLabel => 'Disponible para reservas';

  @override
  String get availableLabel => 'Disponible';

  @override
  String get availableNowLabel => 'Disponible ahora';

  @override
  String get availableSubtitle => 'Listo para aceptar nuevas reservas';

  @override
  String get averageRatingLabel => 'Calificación promedio';

  @override
  String get averageRatingSubtext => 'Basada en las reseñas de los clientes';

  @override
  String get backCta => 'Atrás';

  @override
  String get backToBookingsCta => 'Volver a reservas';

  @override
  String get backToHomeCta => 'Volver al inicio';

  @override
  String get backToLoginCta => 'Volver a iniciar sesión';

  @override
  String get bankDetailsEmpty => 'Aún no se han agregado datos bancarios';

  @override
  String get bankDetailsLabel => 'Datos bancarios';

  @override
  String get bankDetailsRequiredMessage =>
      'Agrega tus datos bancarios antes de solicitar un retiro';

  @override
  String get bankDetailsRequiredTitle => 'Se requieren datos bancarios';

  @override
  String get bankDetailsSubtitle => 'Se usan para los retiros a tu cuenta';

  @override
  String get bankNameLabel => 'Nombre del banco';

  @override
  String get bioLabel => 'Biografía';

  @override
  String get bookAppointmentTitle => 'Reservar cita';

  @override
  String get bookCta => 'Reservar';

  @override
  String get bookNowCta => 'Reservar ahora';

  @override
  String get bookingConfigurationTitle => 'Configuración de reservas';

  @override
  String get bookingDateRequired => 'Selecciona una fecha';

  @override
  String get bookingDetailsTitle => 'Detalles de la reserva';

  @override
  String get bookingFailed => 'La reserva falló. Inténtalo de nuevo.';

  @override
  String get bookingManagementTitle => 'Gestionar reservas';

  @override
  String get bookingSoFarLabel => 'Reservas hasta ahora';

  @override
  String bookingStatusUpdated(Object value1) {
    return 'Reserva marcada como $value1';
  }

  @override
  String bookingSuccessMessage(Object value1) {
    return 'Tu solicitud de reserva con $value1 ha sido enviada';
  }

  @override
  String get bookingSuccessTitle => 'Reserva solicitada';

  @override
  String get bookingTimeRequired => 'Selecciona una hora';

  @override
  String get bookingTipText =>
      'Puedes cancelar gratis hasta 24 horas antes de la cita';

  @override
  String get bookingUpdateError => 'Error al actualizar la reserva';

  @override
  String bookingUpdatedToast(Object value1) {
    return 'Reserva actualizada a $value1';
  }

  @override
  String get bookingsActionLabel => 'Reservas';

  @override
  String get bookingsActionSubtitle => 'Consulta tu historial de reservas';

  @override
  String get bookingsLabel => 'Reservas';

  @override
  String get bookingsStatLabel => 'Reservas';

  @override
  String bufferMinLabel(Object value1) {
    return '$value1 min de margen';
  }

  @override
  String get bufferNoneLabel => 'Sin margen';

  @override
  String get bufferTimeSubtitle => 'Tiempo entre reservas consecutivas';

  @override
  String get bufferTimeTitle => 'Tiempo de margen';

  @override
  String get calendarWeekDays => 'D,L,M,X,J,V,S';

  @override
  String get cameraOptionLabel => 'Cámara';

  @override
  String get cancelBookingCta => 'Cancelar reserva';

  @override
  String get cancelBookingTitle => 'Cancelar reserva';

  @override
  String get cancelConfirmationMessage =>
      '¿Seguro que quieres cancelar esta reserva?';

  @override
  String get cancelCta => 'Cancelar';

  @override
  String get cancelReasonHint => 'Cuéntanos por qué estás cancelando';

  @override
  String get cancelReasonLabel => 'Motivo de la cancelación';

  @override
  String get cancellationPolicyLabel => 'Política de cancelación';

  @override
  String get bookingQuickNoteFirstTime => 'Cliente nuevo';

  @override
  String get bookingQuickNoteUrgent => 'Solicitud urgente';

  @override
  String get bookingQuickNoteFollowUp => 'Visita de seguimiento';

  @override
  String get bookingQuickNoteCallBefore => 'Por favor, llame antes de llegar';

  @override
  String get cancellationPolicyPointFree =>
      'Cancelación gratuita en cualquier momento mientras tu solicitud esté pendiente.';

  @override
  String get cancellationPolicyPointChat =>
      'Una vez aceptada, puedes coordinar cambios directamente con el profesional por chat.';

  @override
  String walletJobCompletedWithName(String name) {
    return 'Trabajo completado — $name';
  }

  @override
  String get walletJobCompleted => 'Trabajo completado';

  @override
  String get walletWithdrawalRequestLabel => 'Solicitud de retiro';

  @override
  String get cancelledByCustomerLabel => 'Cancelada por el cliente';

  @override
  String get cancelledByYouLabel => 'Cancelada por ti';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get certificateAddError => 'Error al agregar el certificado';

  @override
  String get certificateAddSuccess => 'Certificado agregado correctamente';

  @override
  String get certificateTitleHint => 'p. ej. Técnico fontanero certificado';

  @override
  String get certificateTitleLabelRequired => 'Título del certificado';

  @override
  String get certificatesLabel => 'Certificados';

  @override
  String get certificatesTitle => 'Certificados';

  @override
  String get certificationsLabel => 'Certificaciones';

  @override
  String get changePasswordLabel => 'Cambiar contraseña';

  @override
  String get changePasswordSubtitle => 'Actualiza la contraseña de tu cuenta';

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get changeProfilePhotoTitle => 'Cambiar foto de perfil';

  @override
  String get chatMicPermissionRequired =>
      'Se requiere permiso del micrófono para grabar mensajes de voz';

  @override
  String get chatNoMessagesFound => 'No se encontraron mensajes';

  @override
  String get chatSearchMessagesHint => 'Buscar mensajes';

  @override
  String get chatTypeToSearchConversation =>
      'Escribe para buscar en esta conversación';

  @override
  String get checkEmailHint => '¿No lo recibiste? Revisa tu carpeta de spam.';

  @override
  String get checkEmailMessage =>
      'Hemos enviado un enlace para restablecer la contraseña a tu correo electrónico';

  @override
  String get checkEmailTitle => 'Revisa tu correo';

  @override
  String get cityDisabledHint => 'Selecciona primero un país';

  @override
  String get cityEmptyMessage => 'No se encontraron ciudades';

  @override
  String get cityHint => 'Seleccionar ciudad';

  @override
  String get cityLabel => 'Ciudad';

  @override
  String get cityRequiredError => 'Selecciona una ciudad';

  @override
  String get citySearchHint => 'Buscar ciudad';

  @override
  String get clearCta => 'Borrar';

  @override
  String get clientsLabel => 'Clientes';

  @override
  String get closeCta => 'Cerrar';

  @override
  String comingSoonMessage(Object value1) {
    return '$value1 llegará pronto';
  }

  @override
  String commentHint(Object value1) {
    return 'Comparte tu experiencia con $value1';
  }

  @override
  String get commentOptionalLabel => 'Comentario opcional';

  @override
  String get completedLabel => 'Completada';

  @override
  String get confirmBookingCta => 'Confirmar reserva';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get contactChatLabel => 'Chatea con nosotros';

  @override
  String get contactChatSubtitle => 'Obtén una respuesta rápida por chat';

  @override
  String get contactChatTitle => 'Soporte por chat';

  @override
  String get contactCta => 'Contactar';

  @override
  String get contactEmailLabel => 'Escríbenos';

  @override
  String get contactEmailSubtitle => 'Te responderemos en un plazo de 24 horas';

  @override
  String get contactEmailTitle => 'Soporte por correo';

  @override
  String get contactSupportTitle => 'Contactar con soporte';

  @override
  String get continueAsGuestCta => 'Continuar como invitado';

  @override
  String get countryEmptyMessage => 'No se encontraron países';

  @override
  String get countryHint => 'Seleccionar país';

  @override
  String get countryRequiredError => 'Selecciona un país';

  @override
  String get countrySearchHint => 'Buscar país';

  @override
  String get currencyFeatureName => 'Moneda';

  @override
  String get currentPasswordLabel => 'Contraseña actual';

  @override
  String currentPlanLabel(Object value1) {
    return 'Plan actual: $value1';
  }

  @override
  String get currentlyBusyLabel => 'Ocupado actualmente';

  @override
  String get customLocationHint => 'Introduce una ubicación personalizada';

  @override
  String get customLocationOption => 'Ubicación personalizada';

  @override
  String get customLocationSubtitle => 'Introduce una dirección manualmente';

  @override
  String get customSlotDefaultLabel => 'Personalizado';

  @override
  String get customSlotHint => 'Introduce la duración en minutos';

  @override
  String customSlotLabel(Object value1) {
    return 'Personalizado ($value1)';
  }

  @override
  String get customSlotTitle => 'Duración de franja personalizada';

  @override
  String get customSlotValidation => 'Introduce una duración válida';

  @override
  String get customerAccountDescription =>
      'Reserva profesionales de confianza cerca de ti';

  @override
  String get customerDefault => 'Cliente';

  @override
  String get customerLabel => 'Cliente';

  @override
  String get dailyHoursLabel => 'Horas diarias';

  @override
  String get darkModeOffLabel => 'Modo claro';

  @override
  String get darkModeOnLabel => 'Modo oscuro';

  @override
  String get dashboardLoadError => 'Error al cargar el panel';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get dateNotSet => 'Fecha no establecida';

  @override
  String get dateNotSetShort => 'Sin fecha';

  @override
  String get dateRequiredMessage => 'Selecciona una fecha';

  @override
  String get dateTipText => 'Elige la fecha que mejor te convenga';

  @override
  String daysLabel(Object value1) {
    return '$value1 d';
  }

  @override
  String get declineCta => 'Rechazar';

  @override
  String get declineDescription => 'Rechazar esta reserva';

  @override
  String get declineLabel => 'Rechazar';

  @override
  String get deleteAccountDialogContent =>
      'Esto eliminará permanentemente tu cuenta y todos los datos asociados. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountDialogTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountLabel => 'Eliminar cuenta';

  @override
  String get deleteConfirmationTitle => '¿Eliminar este elemento?';

  @override
  String get deleteCta => 'Eliminar';

  @override
  String deleteDialogContent(Object value1) {
    return '¿Seguro que quieres eliminar «$value1»?';
  }

  @override
  String get deleteDialogTitle => 'Eliminar elemento';

  @override
  String get deleteError => 'Error al eliminar';

  @override
  String get deleteGalleryDialogContent =>
      '¿Seguro que quieres eliminar esta foto?';

  @override
  String get deleteGalleryDialogTitle => 'Eliminar foto';

  @override
  String get deleteReviewConfirmationMessage =>
      '¿Seguro que quieres eliminar esta reseña?';

  @override
  String get deleteSuccess => 'Eliminado correctamente';

  @override
  String get descriptionHint => 'Agrega una descripción';

  @override
  String get descriptionLabelOptional => 'Descripción (opcional)';

  @override
  String get detailsLabel => 'Detalles';

  @override
  String get directChatLabel => 'Mensaje';

  @override
  String get discardCta => 'Descartar';

  @override
  String get doneCta => 'Listo';

  @override
  String get earningsLabel => 'Ganancias';

  @override
  String get editCta => 'Editar';

  @override
  String get editLabel => 'Editar';

  @override
  String get editProfileActionLabel => 'Editar perfil';

  @override
  String get editProfileActionSubtitle => 'Actualiza tu información personal';

  @override
  String get editReviewHint => 'Actualiza tu comentario';

  @override
  String get editReviewSubtitle => 'Actualiza tu calificación y comentario';

  @override
  String get editReviewTitle => 'Editar reseña';

  @override
  String get editorHeadingPlaceholder => 'Encabezado';

  @override
  String get editorHintText => 'Empieza a escribir...';

  @override
  String get editorInsertCta => 'Insertar';

  @override
  String get editorInsertLinkTitle => 'Insertar enlace';

  @override
  String get editorLinkHint => 'https://example.com';

  @override
  String get editorLinkPlaceholder => 'Texto del enlace';

  @override
  String get educationLabel => 'Formación';

  @override
  String get emailAvailableLabel => 'El correo electrónico está disponible';

  @override
  String get emailNotificationsLabel => 'Notificaciones por correo';

  @override
  String get emailTakenLabel => 'Este correo electrónico ya está registrado';

  @override
  String get emptyCertificatesSubtitle =>
      'Agrega tus certificaciones para generar confianza con los clientes';

  @override
  String get emptyCertificatesTitle => 'Aún no hay certificados';

  @override
  String get emptyGallerySubtitle => 'Agrega fotos para mostrar tu trabajo';

  @override
  String get emptyGalleryTitle => 'Aún no hay fotos';

  @override
  String get emptyPortfolioSubtitle =>
      'Agrega tus mejores trabajos para atraer más clientes';

  @override
  String get emptyPortfolioTitle => 'Aún no hay elementos en el portafolio';

  @override
  String get endTimeLabel => 'Hora de finalización';

  @override
  String get enterAmountHint => 'Introduce el monto';

  @override
  String get exceedsBalanceError => 'El monto supera tu saldo disponible';

  @override
  String get exceptionsAddRange => 'Agregar rango de fechas';

  @override
  String get exceptionsCalendarSubtitle =>
      'Toca una fecha para establecer una excepción';

  @override
  String get exceptionsCalendarTitle => 'Calendario';

  @override
  String get exceptionsCustomChip => 'Personalizado';

  @override
  String get exceptionsEndDate => 'Fecha de fin';

  @override
  String get exceptionsIntroText =>
      'Marca las fechas en las que tu disponibilidad difiere de tu horario habitual';

  @override
  String get exceptionsLegendClosed => 'Cerrado';

  @override
  String get exceptionsLegendCustom => 'Horario personalizado';

  @override
  String get exceptionsLegendUnavailable => 'No disponible';

  @override
  String get exceptionsLegendVacation => 'Vacaciones';

  @override
  String get exceptionsLegendWorking => 'Trabajando';

  @override
  String get exceptionsLoadError => 'Error al cargar las excepciones';

  @override
  String get exceptionsNoOverrides => 'No hay excepciones establecidas';

  @override
  String get exceptionsOverridesSubtitle =>
      'Fechas con disponibilidad personalizada';

  @override
  String get exceptionsOverridesTitle => 'Excepciones';

  @override
  String get exceptionsReasonLabel => 'Motivo (opcional)';

  @override
  String get exceptionsSelectDate => 'Selecciona una fecha';

  @override
  String get exceptionsSetVacation => 'Establecer vacaciones';

  @override
  String get exceptionsStartDate => 'Fecha de inicio';

  @override
  String get exceptionsTimeError =>
      'La hora de fin debe ser posterior a la hora de inicio';

  @override
  String get exceptionsTitle => 'Excepciones de disponibilidad';

  @override
  String get exceptionsUnavailableChip => 'No disponible';

  @override
  String get exceptionsUnavailableLabel => 'Marcar como no disponible';

  @override
  String get exceptionsUpdateVacation => 'Actualizar vacaciones';

  @override
  String get exceptionsVacationActive =>
      'Las vacaciones están activas actualmente';

  @override
  String exceptionsVacationScheduled(Object value1) {
    return 'Vacaciones programadas desde el $value1';
  }

  @override
  String get exceptionsVacationSubtitle =>
      'Establece un rango de fechas en el que estarás ausente';

  @override
  String get exceptionsVacationTitle => 'Modo vacaciones';

  @override
  String get experienceLabel => 'Experiencia';

  @override
  String experienceYearsLabel(Object value1) {
    return '$value1 años de experiencia';
  }

  @override
  String get exploreExpertsLabel => 'Explorar expertos';

  @override
  String get facebookSignInLabel => 'Continuar con Facebook';

  @override
  String get faqBookingPendingA =>
      'El profesional puede tardar un poco en responder. Se te notificará cuando acepte o rechace.';

  @override
  String get faqBookingPendingQ => '¿Por qué mi reserva sigue pendiente?';

  @override
  String get faqChangeAvailabilityA =>
      'Ve a los ajustes de Disponibilidad desde tu perfil para actualizar tu horario laboral.';

  @override
  String get faqChangeAvailabilityQ => '¿Cómo cambio mi disponibilidad?';

  @override
  String get faqGetVerifiedA =>
      'Completa tu perfil y envía los documentos requeridos desde los ajustes de tu perfil para solicitar la verificación.';

  @override
  String get faqGetVerifiedQ => '¿Cómo me verifico?';

  @override
  String get faqHowToBookA =>
      'Busca un profesional, consulta su perfil y toca Reservar ahora para elegir una fecha y una hora.';

  @override
  String get faqHowToBookQ => '¿Cómo reservo a un profesional?';

  @override
  String get faqHowToCancelA =>
      'Abre la reserva desde Mis reservas y toca Cancelar. Las cancelaciones hechas a tiempo son gratuitas.';

  @override
  String get faqHowToCancelQ => '¿Cómo cancelo una reserva?';

  @override
  String get faqImproveProfileA =>
      'Agrega una foto de perfil, muestras de portafolio y certificados para generar confianza con los clientes.';

  @override
  String get faqImproveProfileQ => '¿Cómo puedo mejorar mi perfil?';

  @override
  String get faqPaymentSecureA =>
      'Sí, todos los pagos se procesan de forma segura y tus datos nunca se comparten.';

  @override
  String get faqPaymentSecureQ => '¿Es segura mi información de pago?';

  @override
  String get faqRefundsA =>
      'Los reembolsos se procesan automáticamente para las cancelaciones elegibles en unos pocos días hábiles.';

  @override
  String get faqRefundsQ => '¿Cómo funcionan los reembolsos?';

  @override
  String get faqSectionLabel => 'Preguntas frecuentes';

  @override
  String get faqSectionTitle => 'Preguntas frecuentes';

  @override
  String get faqWithdrawEarningsA =>
      'Ve a tu Billetera y toca Retirar para transferir tus ganancias a tu cuenta bancaria.';

  @override
  String get faqWithdrawEarningsQ => '¿Cómo retiro mis ganancias?';

  @override
  String get fastResponseLabel => 'Respuesta rápida';

  @override
  String get flexibleTimingLabel => 'Horario flexible';

  @override
  String get freeToCancelLabel => 'Cancelación gratuita';

  @override
  String get fullNameLabel => 'Nombre completo';

  @override
  String get galleryLabel => 'Galería';

  @override
  String get galleryOptionLabel => 'Galería';

  @override
  String get galleryTitle => 'Galería';

  @override
  String get galleryUploadError => 'Error al subir la foto';

  @override
  String get galleryUploadSuccess => 'Foto subida correctamente';

  @override
  String get goBackCta => 'Volver';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodAfternoonComma => 'Buenas tardes,';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get goodEveningComma => 'Buenas noches,';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodMorningComma => 'Buenos días,';

  @override
  String get goodToKnowLabel => 'Conviene saber';

  @override
  String get googleSignInLabel => 'Continuar con Google';

  @override
  String get helpActionLabel => 'Ayuda y soporte';

  @override
  String get helpActionSubtitle => 'Obtén ayuda o contáctanos';

  @override
  String get helpSupportLabel => 'Ayuda y soporte';

  @override
  String get helpSupportTitle => 'Ayuda y soporte';

  @override
  String get helpTitle => 'Ayuda';

  @override
  String get homeDefaultPlanFree => 'Gratis';

  @override
  String get homeDefaultProfessionalName => 'Profesional';

  @override
  String get homeFilterAll => 'Todos';

  @override
  String get homeFilterAvailableNow => 'Disponible ahora';

  @override
  String get homeFilterFastResponse => 'Respuesta rápida';

  @override
  String get homeFilterHighestPrice => 'Precio más alto';

  @override
  String get homeFilterLowestPrice => 'Precio más bajo';

  @override
  String get homeFilterMostBooked => 'Más reservados';

  @override
  String get homeFilterMostExperienced => 'Más experimentados';

  @override
  String get homeFilterMostReviews => 'Más reseñas';

  @override
  String get homeFilterRating1Plus => '1+ estrellas';

  @override
  String get homeFilterRating2Plus => '2+ estrellas';

  @override
  String get homeFilterRating3Plus => '3+ estrellas';

  @override
  String get homeFilterRating4Plus => '4+ estrellas';

  @override
  String get homeFilterRating5Plus => '5 estrellas';

  @override
  String get homeFilterThisMonth => 'Este mes';

  @override
  String get homeFilterThisWeek => 'Esta semana';

  @override
  String get homeFilterToday => 'Hoy';

  @override
  String get homeFilterTopRated => 'Mejor valorados';

  @override
  String get homeFilterVerified => 'Verificados';

  @override
  String get homeFilterWithin10Km => 'A menos de 10 km';

  @override
  String get homeFilterWithin2Km => 'A menos de 2 km';

  @override
  String get homeFilterWithin5Km => 'A menos de 5 km';

  @override
  String get homeGoBack => 'Volver';

  @override
  String get homeNoProfessionalsFound => 'No se encontraron profesionales';

  @override
  String get homeNoProfessionalsFoundHint =>
      'Intenta ajustar tus filtros o buscar en otra zona';

  @override
  String get hour => 'hora';

  @override
  String get hourlyRateLabel => 'Tarifa por hora';

  @override
  String hoursDecimalLabel(Object value1) {
    return '$value1 h';
  }

  @override
  String hoursLabel(Object value1) {
    return '$value1 h';
  }

  @override
  String hoursMinutesShort(Object value1, Object value2) {
    return '$value1 h $value2 min';
  }

  @override
  String hoursShort(Object value1) {
    return '$value1 h';
  }

  @override
  String get idVerifiedLabel => 'Identidad verificada';

  @override
  String get imagePickError => 'Error al seleccionar la imagen';

  @override
  String get instantLabel => 'Instantánea';

  @override
  String get issueDateLabelOptional => 'Fecha de emisión (opcional)';

  @override
  String get issuingOrganizationHint =>
      'p. ej. Consejo Nacional de Competencias';

  @override
  String get issuingOrganizationLabel => 'Organización emisora';

  @override
  String get jobsDoneLabel => 'Trabajos realizados';

  @override
  String get languagesLabel => 'Idiomas';

  @override
  String lastUpdatedLabel(Object value1) {
    return 'Última actualización: $value1';
  }

  @override
  String get laterCta => 'Más tarde';

  @override
  String get loadBookingsError => 'Error al cargar las reservas';

  @override
  String get loadCertificatesError => 'Error al cargar los certificados';

  @override
  String get loadGalleryError => 'Error al cargar la galería';

  @override
  String get loadPortfolioError => 'Error al cargar el portafolio';

  @override
  String get loadSettingsError => 'Error al cargar los ajustes';

  @override
  String get loadWalletError => 'Error al cargar la billetera';

  @override
  String get loadingAnalyticsText => 'Cargando estadísticas...';

  @override
  String get loadingDashboard => 'Cargando panel...';

  @override
  String get locationLabel => 'Ubicación';

  @override
  String get locationNotSpecified => 'Ubicación no especificada';

  @override
  String get locationTipText =>
      'Activa la ubicación para obtener resultados más precisos';

  @override
  String get loginCta => 'Iniciar sesión';

  @override
  String get loginSubtitle =>
      '¡Bienvenido de nuevo! Inicia sesión para continuar';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginToBookCta => 'Inicia sesión para reservar';

  @override
  String get logoutActionLabel => 'Cerrar sesión';

  @override
  String get logoutActionSubtitle => 'Cierra sesión en tu cuenta';

  @override
  String get logoutCta => 'Cerrar sesión';

  @override
  String get logoutDialogContent => '¿Seguro que quieres cerrar sesión?';

  @override
  String get logoutDialogTitle => 'Cerrar sesión';

  @override
  String get magazineAllCategoriesLabel => 'Todos';

  @override
  String magazineArticleCountPlural(Object value1) {
    return '$value1 artículos';
  }

  @override
  String get magazineArticleCountSingle => '1 artículo';

  @override
  String get magazineClearSearchCta => 'Borrar búsqueda';

  @override
  String get magazineEmptyMessage =>
      'No hay artículos disponibles en este momento';

  @override
  String get magazineEmptySearchMessage =>
      'Prueba con otro término de búsqueda';

  @override
  String get magazineEmptySearchTitle => 'No se encontraron resultados';

  @override
  String get magazineEmptyTitle => 'Aún no hay artículos';

  @override
  String get magazineErrorMessage => 'Algo salió mal al cargar la revista';

  @override
  String get magazineErrorTitle => 'Error al cargar';

  @override
  String get magazineLoadError => 'Error al cargar la revista';

  @override
  String get magazineLoadingText => 'Cargando artículos...';

  @override
  String get magazineSearchHint => 'Buscar artículos';

  @override
  String get magazineSearchResultsLabel => 'Resultados de búsqueda';

  @override
  String get magazineSubtitle => 'Consejos e historias para profesionales';

  @override
  String get magazineTitle => 'Revista';

  @override
  String get manageCta => 'Gestionar';

  @override
  String get manageLabel => 'Gestionar';

  @override
  String get manualDescription => 'Revisa y acepta las reservas tú mismo';

  @override
  String get manualInfoFooter =>
      'Puedes cambiarlo en cualquier momento en los ajustes';

  @override
  String get manualInfoTitle => 'Aprobación manual';

  @override
  String get manualLabel => 'Manual';

  @override
  String get markCompletedCta => 'Marcar como completada';

  @override
  String get markCompletedCtaShort => 'Completar';

  @override
  String get maxAdvanceSubtitle =>
      'Con cuánta antelación pueden reservar los clientes';

  @override
  String get maxAdvanceTitle => 'Reserva anticipada máxima';

  @override
  String get memberSinceLabel => 'Miembro desde';

  @override
  String get messagesEmptySubtitle =>
      'Inicia una conversación con un profesional o un cliente';

  @override
  String get messagesEmptyTitle => 'Aún no hay mensajes';

  @override
  String get messagesLoadError => 'Error al cargar los mensajes';

  @override
  String get messagesLoadingText => 'Cargando mensajes...';

  @override
  String get messagesTitle => 'Mensajes';

  @override
  String minAmountError(Object value1) {
    return 'El monto mínimo de retiro es Rs $value1';
  }

  @override
  String get minNoticeSubtitle =>
      'Tiempo mínimo antes de que pueda comenzar una reserva';

  @override
  String get minNoticeTitle => 'Aviso mínimo';

  @override
  String minWithdrawalLabel(Object value1) {
    return 'Retiro mínimo: Rs $value1';
  }

  @override
  String get minute => 'minuto';

  @override
  String minutesLabel(Object value1) {
    return '$value1 min';
  }

  @override
  String minutesShort(Object value1) {
    return '$value1 min';
  }

  @override
  String get minutesZero => '0 minutos';

  @override
  String get myPortfolioLabel => 'Mi portafolio';

  @override
  String get myPortfolioTitle => 'Mi portafolio';

  @override
  String get myReviewsEmptySubtitle =>
      'Las reseñas que escribas aparecerán aquí';

  @override
  String get myReviewsEmptyTitle => 'Aún no hay reseñas';

  @override
  String get myReviewsTitle => 'Mis reseñas';

  @override
  String get navAnalytics => 'Estadísticas';

  @override
  String get navBookings => 'Reservas';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navMagazine => 'Revista';

  @override
  String get navMessages => 'Mensajes';

  @override
  String get navProfile => 'Perfil';

  @override
  String get nearbyLabel => 'Cerca de ti';

  @override
  String get needMoreHelpLabel => '¿Necesitas más ayuda?';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get newPhotoSelectedHint => 'Nueva foto seleccionada';

  @override
  String get nextCta => 'Siguiente';

  @override
  String get noBookingsAccepted => 'No hay reservas aceptadas';

  @override
  String get noBookingsAll => 'Aún no hay reservas';

  @override
  String get noBookingsCancelled => 'No hay reservas canceladas';

  @override
  String get noBookingsCompleted => 'No hay reservas completadas';

  @override
  String get noBookingsDefault => 'No se encontraron reservas';

  @override
  String get noBookingsPending => 'No hay reservas pendientes';

  @override
  String get noBookingsRescheduled => 'No hay reservas reprogramadas';

  @override
  String get noBookingsToday => 'No hay reservas hoy';

  @override
  String get noBookingsYet => 'Aún no hay reservas';

  @override
  String get noClientsFound => 'No se encontraron clientes';

  @override
  String get noLanguagesAdded => 'Aún no se han agregado idiomas';

  @override
  String get noMessagesPlaceholder => 'Aún no hay mensajes';

  @override
  String get noMessagesYet => 'Aún no hay mensajes';

  @override
  String get noPaymentsSubtitle => 'Tu historial de pagos aparecerá aquí';

  @override
  String get noPaymentsTitle => 'Aún no hay pagos';

  @override
  String get noPortfolioSubtitle =>
      'Los elementos del portafolio aparecerán aquí';

  @override
  String get noPortfolioTitle => 'No hay elementos en el portafolio';

  @override
  String get noReviewsSubtitle =>
      'Las reseñas aparecerán aquí cuando los clientes te califiquen';

  @override
  String get noReviewsTitle => 'Aún no hay reseñas';

  @override
  String get noReviewsYet => 'Aún no hay reseñas';

  @override
  String get noServicesSubtitle =>
      'Agrega los servicios que ofreces para atraer clientes';

  @override
  String get noServicesTitle => 'No se han agregado servicios';

  @override
  String get noSkillsAdded => 'Aún no se han agregado habilidades';

  @override
  String get noTransactionsLabel => 'Aún no hay transacciones';

  @override
  String get noWorkingHoursMessage =>
      'No se ha establecido horario laboral para este día';

  @override
  String get notAcceptingBookingsLabel => 'No acepta reservas';

  @override
  String get notAvailableLabel => 'No disponible';

  @override
  String get notAvailableSubtitle => 'No acepta reservas en este momento';

  @override
  String get notSetPlaceholder => 'No establecido';

  @override
  String get notSpecifiedLabel => 'No especificado';

  @override
  String get notVerifiedLabel => 'No verificado';

  @override
  String get notesHintText => 'Agrega tus notas aquí';

  @override
  String get notesInfoText => 'Las notas solo son visibles para ti';

  @override
  String get notesLabel => 'Notas';

  @override
  String get notesTipText => 'Agrega solicitudes especiales o detalles';

  @override
  String get notificationsActionLabel => 'Notificaciones';

  @override
  String get notificationsActionSubtitle =>
      'Gestiona tus preferencias de notificación';

  @override
  String notificationsDaysAgo(Object value1) {
    return 'hace $value1 d';
  }

  @override
  String get notificationsEmptyMessage => '¡Estás al día!';

  @override
  String get notificationsEmptyTitle => 'Sin notificaciones';

  @override
  String get notificationsErrorTitle =>
      'No se pudieron cargar las notificaciones';

  @override
  String notificationsHoursAgo(Object value1) {
    return 'hace $value1 h';
  }

  @override
  String get notificationsJustNow => 'Ahora mismo';

  @override
  String get notificationsLoadError => 'Error al cargar las notificaciones';

  @override
  String get notificationsLoadingText => 'Cargando notificaciones...';

  @override
  String get notificationsMarkAllReadCta => 'Marcar todo como leído';

  @override
  String get notificationsMarkAllReadSuccess =>
      'Todas las notificaciones marcadas como leídas';

  @override
  String notificationsMinutesAgo(Object value1) {
    return 'hace $value1 min';
  }

  @override
  String get notificationsSectionLabel => 'Notificaciones';

  @override
  String get notificationsSectionThisMonth => 'Este mes';

  @override
  String get notificationsSectionThisWeek => 'Esta semana';

  @override
  String get notificationsSectionToday => 'Hoy';

  @override
  String get notificationsSectionYesterday => 'Ayer';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String notifyCustomerMessage(Object value1, Object value2) {
    return '¿Notificar al cliente la nueva hora: $value1 a las $value2?';
  }

  @override
  String get notifyCustomerTitle => 'Notificar al cliente';

  @override
  String get offlineLabel => 'Sin conexión';

  @override
  String get okCta => 'Aceptar';

  @override
  String get onlineLabel => 'En línea';

  @override
  String get openChatCta => 'Abrir chat';

  @override
  String get openChatCtaShort => 'Chat';

  @override
  String get openChatError => 'Error al abrir el chat';

  @override
  String get orContinueWithLabel => 'O continúa con';

  @override
  String get overrideRemoved => 'Excepción eliminada';

  @override
  String overrideSaved(Object value1) {
    return 'Excepción guardada para $value1';
  }

  @override
  String get passwordChangeError => 'Error al cambiar la contraseña';

  @override
  String get passwordChangeSuccess => 'Contraseña cambiada correctamente';

  @override
  String get passwordHelperText => 'Debe tener al menos 8 caracteres';

  @override
  String get passwordMinLengthError =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordMismatchError => 'Las contraseñas no coinciden';

  @override
  String get passwordRequiredError => 'La contraseña es obligatoria';

  @override
  String get paymentHistoryLabel => 'Historial de pagos';

  @override
  String get paymentHistorySubtitle => 'Consulta todos tus pagos anteriores';

  @override
  String get paymentStatusCompleted => 'Completado';

  @override
  String get paymentStatusFailed => 'Fallido';

  @override
  String get paymentStatusPending => 'Pendiente';

  @override
  String get paymentStatusRefunded => 'Reembolsado';

  @override
  String get paymentsActionLabel => 'Pagos';

  @override
  String get paymentsActionSubtitle => 'Consulta tu historial de pagos';

  @override
  String get paymentsTitle => 'Pagos';

  @override
  String get pendingLabel => 'Pendiente';

  @override
  String get perHourLabel => '/h';

  @override
  String get performanceLabel => 'Rendimiento';

  @override
  String get performanceScoreInfo =>
      'Basado en tus calificaciones, tiempo de respuesta y reservas completadas';

  @override
  String get performanceScoreLabel => 'Puntuación de rendimiento';

  @override
  String performanceScoreOutOf(Object value1) {
    return '$value1 de 100';
  }

  @override
  String get personalInfoLabel => 'Información personal';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String photoLimitReached(Object value1) {
    return 'Puedes agregar hasta $value1 fotos';
  }

  @override
  String get photoPickError => 'Error al seleccionar la foto';

  @override
  String get photosOptionalLabel => 'Fotos (opcional)';

  @override
  String get planStatLabel => 'Plan';

  @override
  String get planUpgradeSubtitle =>
      'Desbloquea más funciones y haz crecer tu negocio';

  @override
  String planUpgradeTitle(Object value1) {
    return 'Mejorar desde $value1';
  }

  @override
  String get portfolioInfoNote =>
      'Muestra tus mejores trabajos para atraer más clientes';

  @override
  String get portfolioLabel => 'Portafolio';

  @override
  String get postReplyCta => 'Publicar respuesta';

  @override
  String get preferencesGroupLabel => 'Preferencias';

  @override
  String get preferencesSectionLabel => 'Preferencias';

  @override
  String get premiumActiveSubtitle =>
      'Tienes acceso a todas las funciones premium';

  @override
  String get premiumMemberLabel => 'Miembro Premium';

  @override
  String get premiumUpgradeSubtitle =>
      'Obtén búsquedas con IA ilimitadas y más';

  @override
  String get proBadgeLabel => 'PRO';

  @override
  String get professionEmptyMessage => 'No se encontraron profesiones';

  @override
  String get professionHint => 'Seleccionar profesión';

  @override
  String get professionLabel => 'Profesión';

  @override
  String get professionRequiredError => 'Selecciona una profesión';

  @override
  String get professionSearchHint => 'Buscar profesión';

  @override
  String get professionalAccountDescription =>
      'Ofrece tus servicios a los clientes';

  @override
  String get professionalDefaultName => 'Profesional';

  @override
  String get professionalDetailLoadError =>
      'Error al cargar los datos del profesional';

  @override
  String get professionalDetailsLabel => 'Datos del profesional';

  @override
  String get professionalLabel => 'Profesional';

  @override
  String get professionalLocationLabel => 'Ubicación del profesional';

  @override
  String get professionalLocationOption => 'Ubicación del profesional';

  @override
  String get professionalReviewsLabel => 'Reseñas';

  @override
  String get professionalReviewsSubtitle => 'Lo que dicen los clientes';

  @override
  String get profileCompletionHint =>
      'Completa tu perfil para atraer más clientes';

  @override
  String get profileCompletionLabel => 'Perfil completado';

  @override
  String get profileEditProfile => 'Editar perfil';

  @override
  String get profileLabel => 'Perfil';

  @override
  String get profileLoadError => 'Error al cargar el perfil';

  @override
  String get profileLoadingText => 'Cargando perfil...';

  @override
  String get profileNotAvailable => 'Perfil no disponible';

  @override
  String get profileOff => 'Desactivado';

  @override
  String get profileOn => 'Activado';

  @override
  String get profileReviewsLabel => 'Reseñas';

  @override
  String get profileSavedLabel => 'Guardados';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileUpdateError => 'Error al actualizar el perfil';

  @override
  String get profileUpdateSuccess => 'Perfil actualizado correctamente';

  @override
  String get profileViewsLabel => 'Visitas al perfil';

  @override
  String get profileViewsSubtext => 'Personas que vieron tu perfil';

  @override
  String get profileWalletLabel => 'Billetera';

  @override
  String get pushNotificationsLabel => 'Notificaciones push';

  @override
  String get quickActionsLabel => 'Acciones rápidas';

  @override
  String get quickAddLabel => 'Agregar rápido';

  @override
  String get rateLabel => 'Tarifa';

  @override
  String get ratingLabel => 'Calificación';

  @override
  String get ratingRequiredError => 'Selecciona una calificación';

  @override
  String get recentBookingsLabel => 'Reservas recientes';

  @override
  String get recentMessagesLabel => 'Mensajes recientes';

  @override
  String get recentReviewsLabel => 'Reseñas recientes';

  @override
  String get refreshTooltip => 'Actualizar';

  @override
  String get registerCategoryRequired => 'Selecciona una categoría';

  @override
  String get registerCta => 'Registrarse';

  @override
  String get registerServerError => 'El registro falló. Inténtalo de nuevo.';

  @override
  String get registerSubtitle => 'Regístrate para empezar';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get rejectCta => 'Rechazar';

  @override
  String get relatedProfessionalsLabel => 'También te puede gustar';

  @override
  String get removeCta => 'Quitar';

  @override
  String get replyHint => 'Escribe una respuesta';

  @override
  String get replySubtitle => 'Tu respuesta es pública y visible para todos';

  @override
  String get replyTitle => 'Responder a la reseña';

  @override
  String get reportNoteHint => 'Agrega más detalles';

  @override
  String get reportSubtitle => 'Ayúdanos a entender qué salió mal';

  @override
  String get reportTitle => 'Informar de un problema';

  @override
  String get requestSentLabel => 'Solicitud enviada';

  @override
  String requestSentSubtitle(Object value1) {
    return 'Tu solicitud ha sido enviada a $value1';
  }

  @override
  String get requestWithdrawCta => 'Solicitar retiro';

  @override
  String get rescheduledLabel => 'Reprogramada';

  @override
  String get resendEmailCta => 'Reenviar correo';

  @override
  String get resetLinkError => 'Error al enviar el enlace de restablecimiento';

  @override
  String resetLinkSent(Object value1) {
    return 'Enlace de restablecimiento de contraseña enviado a $value1';
  }

  @override
  String get resetPassSubtitle =>
      'Introduce tu correo electrónico y te enviaremos un enlace de restablecimiento';

  @override
  String get resetPassTitle => 'Restablecer contraseña';

  @override
  String resetPasswordDescription(Object value1) {
    return 'Enviaremos un enlace de restablecimiento de contraseña a $value1';
  }

  @override
  String get resetPasswordLabel => 'Restablecer contraseña';

  @override
  String get responseLabel => 'Respuesta';

  @override
  String get responseRateLabel => 'Tasa de respuesta';

  @override
  String get responseRateSubtext =>
      'Con qué frecuencia respondes a los mensajes';

  @override
  String get responseTimeLabel => 'Tiempo de respuesta';

  @override
  String get retryCta => 'Reintentar';

  @override
  String get reviewBookingLabel => 'Valorar reserva';

  @override
  String get reviewSubmitErrorDefault => 'Error al enviar la reseña';

  @override
  String reviewSubmittedSuccessMessage(Object value1) {
    return 'Tu reseña de $value1 ha sido enviada';
  }

  @override
  String get reviewSubmittedSuccessTitle => 'Reseña enviada';

  @override
  String get reviewUpdateErrorDefault => 'Error al actualizar la reseña';

  @override
  String reviewUpdatedSuccessMessage(Object value1) {
    return 'Tu reseña de $value1 ha sido actualizada';
  }

  @override
  String get reviewUpdatedSuccessTitle => 'Reseña actualizada';

  @override
  String get reviewsActionLabel => 'Reseñas';

  @override
  String get reviewsActionSubtitle => 'Las reseñas que has escrito';

  @override
  String reviewsCountLabel(Object value1) {
    return '$value1 reseñas';
  }

  @override
  String get reviewsLabel => 'Reseñas';

  @override
  String get saveCertificateCta => 'Guardar certificado';

  @override
  String get saveChangesCta => 'Guardar cambios';

  @override
  String get saveCta => 'Guardar';

  @override
  String get saveScheduleCta => 'Guardar horario';

  @override
  String get saveSettingsError => 'Error al guardar los ajustes';

  @override
  String get saveSettingsSuccess => 'Ajustes guardados correctamente';

  @override
  String get savedProfessionalsActionLabel => 'Profesionales guardados';

  @override
  String get savedProfessionalsActionSubtitle =>
      'Los profesionales que has guardado';

  @override
  String get savedProfessionalsEmptySubtitle =>
      'Los profesionales que guardes aparecerán aquí';

  @override
  String get savedProfessionalsEmptyTitle => 'No hay profesionales guardados';

  @override
  String get savedProfessionalsTitle => 'Profesionales guardados';

  @override
  String get savedStatLabel => 'Guardados';

  @override
  String get searchAiPremiumActive => 'Búsqueda con IA Premium activa';

  @override
  String searchAiRemainingToday(Object value1) {
    return '$value1 búsquedas con IA restantes hoy';
  }

  @override
  String get searchBookingsHint => 'Buscar reservas';

  @override
  String get searchCategories => 'Categorías';

  @override
  String get searchPopular => 'Populares';

  @override
  String get searchPopularCleaners => 'Limpieza';

  @override
  String get searchPopularDoctors => 'Médicos';

  @override
  String get searchPopularElectricians => 'Electricistas';

  @override
  String get searchPopularEngineers => 'Ingenieros';

  @override
  String get searchPopularLawyers => 'Abogados';

  @override
  String get searchPopularPlumbers => 'Fontaneros';

  @override
  String get searchProfessionals => 'Profesionales';

  @override
  String get searchProfessions => 'Profesiones';

  @override
  String get searchRecent => 'Recientes';

  @override
  String searchResultsLabel(Object value1, Object value2) {
    return '$value1 resultados para «$value2»';
  }

  @override
  String get searchingLabel => 'Buscando...';

  @override
  String get security => 'Seguridad';

  @override
  String get securityActionLabel => 'Seguridad';

  @override
  String get securityActionSubtitle => 'Contraseña y seguridad de la cuenta';

  @override
  String get securityBannerSubtitle => 'Mantén tu cuenta segura y protegida';

  @override
  String get securityBannerTitle => 'Seguridad de la cuenta';

  @override
  String get securityFooterText =>
      'Si no solicitaste este cambio, contacta con soporte de inmediato';

  @override
  String get securityTitle => 'Seguridad';

  @override
  String get seeAllLabel => 'Ver todo';

  @override
  String get selectedLabel => 'Seleccionado';

  @override
  String get sendResetLinkCta => 'Enviar enlace de restablecimiento';

  @override
  String get serviceLabel => 'Servicio';

  @override
  String get serviceProfessionalLabel => 'Profesional de servicios';

  @override
  String get settingsActionLabel => 'Ajustes';

  @override
  String get settingsActionSubtitle => 'Preferencias de la aplicación';

  @override
  String get shareExperienceLabel => 'Comparte tu experiencia';

  @override
  String get signInInsteadLabel => 'Iniciar sesión en su lugar';

  @override
  String get skillsLabel => 'Habilidades';

  @override
  String get skillsPricingLabel => 'Habilidades y precios';

  @override
  String get slotDurationSubtitle =>
      'Duración predeterminada de cada franja de reserva';

  @override
  String get slotDurationTitle => 'Duración de la franja';

  @override
  String get startConversationError => 'Error al iniciar la conversación';

  @override
  String get startTimeLabel => 'Hora de inicio';

  @override
  String get startingFromLabel => 'Desde';

  @override
  String get statusApproved => 'Aprobado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusRejected => 'Rechazado';

  @override
  String get submitReportCta => 'Enviar informe';

  @override
  String get submitReviewCta => 'Enviar reseña';

  @override
  String get subscriptionActionLabel => 'Suscripción';

  @override
  String subscriptionActiveStatus(Object value1) {
    return 'Plan $value1 activo';
  }

  @override
  String get subscriptionUpgradeLabel => 'Mejorar plan';

  @override
  String get subscriptionUpgradeStatus => 'Pasar a premium';

  @override
  String get suggestTimeCta => 'Sugerir otra hora';

  @override
  String get suggestTimeCtaShort => 'Sugerir hora';

  @override
  String get suggestTimeDescription =>
      'Propón una nueva fecha y hora para esta reserva';

  @override
  String get suggestTimeLabel => 'Sugerir una hora';

  @override
  String get suggestTimeSuccess => 'Nueva hora sugerida al cliente';

  @override
  String get suggestedTimeLabel => 'Hora sugerida';

  @override
  String get supportBannerSubtitle =>
      'Estamos aquí para ayudarte, las 24 horas';

  @override
  String get supportBannerTitle => '¿Necesitas ayuda?';

  @override
  String get supportTeamReplyLabel => 'Equipo de soporte';

  @override
  String get tapStarToRateLabel => 'Toca una estrella para calificar';

  @override
  String get thisMonthLabel => 'Este mes';

  @override
  String get timeLabel => 'Hora';

  @override
  String get timeSlotsLabel => 'Franjas horarias';

  @override
  String get timeTipText => 'Elige la hora que mejor te convenga';

  @override
  String get titleHint => 'Introduce un título';

  @override
  String get titleLabelRequired => 'Título';

  @override
  String get titleValidationError => 'Introduce un título';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get todaysEarningsLabel => 'Ganancias de hoy';

  @override
  String get todaysScheduleLabel => 'Agenda de hoy';

  @override
  String get topRatedLabel => 'Mejor valorados';

  @override
  String get totalBookingsLabel => 'Total de reservas';

  @override
  String get totalEarnedLabel => 'Total ganado';

  @override
  String get totalSpentLabel => 'Total gastado';

  @override
  String transactionCountLabel(Object value1) {
    return '$value1 transacciones';
  }

  @override
  String get transactionHistoryTitle => 'Historial de transacciones';

  @override
  String get tryAgainCta => 'Intentar de nuevo';

  @override
  String get twitterSignInLabel => 'Continuar con Twitter';

  @override
  String get typicallyRepliesLabel => 'Suele responder';

  @override
  String get unavailableLabel => 'No disponible';

  @override
  String get unknownRoleError => 'Tipo de cuenta desconocido';

  @override
  String get updateBookingError => 'Error al actualizar la reserva';

  @override
  String get updateCta => 'Actualizar';

  @override
  String get updateReviewCta => 'Actualizar reseña';

  @override
  String get upgradeCta => 'Mejorar';

  @override
  String get uploadError => 'Error al subir';

  @override
  String get uploadSuccess => 'Subido correctamente';

  @override
  String get userLabel => 'Usuario';

  @override
  String get vacationCleared => 'Vacaciones eliminadas';

  @override
  String get vacationDateRequired =>
      'Selecciona un rango de fechas de vacaciones';

  @override
  String get vacationSet => 'Vacaciones establecidas correctamente';

  @override
  String get validAmountError => 'Introduce un monto válido';

  @override
  String get verificationAddPortfolio =>
      'Agrega elementos al portafolio para ayudar a que te verifiquen';

  @override
  String get verificationLabel => 'Verificación';

  @override
  String get verificationPending => 'Verificación pendiente';

  @override
  String get verifiedLabel => 'Verificado';

  @override
  String get verifiedProfessionalLabel => 'Profesional';

  @override
  String verifiedStatusLabel(Object value1) {
    return 'Verificado $value1';
  }

  @override
  String get viewMyBookingsCta => 'Ver mis reservas';

  @override
  String get viewProfileCta => 'Ver perfil';

  @override
  String get viewWalletLabel => 'Ver billetera';

  @override
  String get visitorsLabel => 'Visitantes';

  @override
  String get visitorsSubtext => 'Personas que vieron tu perfil';

  @override
  String get walletActionLabel => 'Billetera';

  @override
  String get walletActionSubtitle => 'Consulta tu saldo y transacciones';

  @override
  String get walletEarningsLabel => 'Ganancias';

  @override
  String get walletLabel => 'Billetera';

  @override
  String get walletTitle => 'Billetera';

  @override
  String get whatHappensNextLabel => '¿Qué pasa después?';

  @override
  String get whyBookHereLabel => '¿Por qué reservar con nosotros?';

  @override
  String get withdrawCta => 'Retirar';

  @override
  String get withdrawErrorDefault => 'El retiro falló. Inténtalo de nuevo.';

  @override
  String get withdrawSuccess => 'Retiro solicitado correctamente';

  @override
  String get withdrawTitle => 'Retirar fondos';

  @override
  String get withdrawnLabel => 'Retirado';

  @override
  String get workingHoursLabel => 'Horario laboral';

  @override
  String get writeReviewTitle => 'Escribir una reseña';

  @override
  String yearsLabel(Object value1) {
    return '$value1 años';
  }

  @override
  String get yesCancelCta => 'Sí, cancelar';

  @override
  String get youAreNotifiedLabel => 'Se te notificará';

  @override
  String get youAreNotifiedSubtitle =>
      'Te avisaremos en cuanto haya una respuesta';

  @override
  String get yourAccountEmailPlaceholder => 'el correo de tu cuenta';

  @override
  String get tsErrForbidden => 'No tienes permiso para realizar esta acción.';

  @override
  String get tsErrNetwork =>
      'Problema de red. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get tsErrGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get tsRetry => 'Reintentar';

  @override
  String get tsCopy => 'Copiar';

  @override
  String get tsCopied => 'Copiado al portapapeles';

  @override
  String get tsOpenLink => 'Abrir enlace';

  @override
  String get tsLinkOpenFailed => 'No se pudo abrir este enlace.';

  @override
  String get tsCancel => 'Cancelar';

  @override
  String get tsClose => 'Cerrar';

  @override
  String get tsRefresh => 'Actualizar';

  @override
  String get tsAll => 'Todos';

  @override
  String get tsCatSpam => 'Spam';

  @override
  String get tsCatHarassment => 'Acoso';

  @override
  String get tsCatFraud => 'Fraude o estafa';

  @override
  String get tsCatFakeProfile => 'Perfil falso';

  @override
  String get tsCatInappropriate => 'Contenido inapropiado';

  @override
  String get tsCatPaymentFraud => 'Fraude de pago';

  @override
  String get tsCatOffPlatform => 'Pago fuera de la plataforma';

  @override
  String get tsCatThreats => 'Amenazas o problema de seguridad';

  @override
  String get tsCatDiscrimination => 'Discriminación';

  @override
  String get tsCatMisconduct => 'Mala conducta en el servicio';

  @override
  String get tsCatOther => 'Otro';

  @override
  String get tsStatusPending => 'Pendiente';

  @override
  String get tsStatusReviewed => 'Revisado';

  @override
  String get tsStatusActionTaken => 'Acción tomada';

  @override
  String get tsStatusDismissed => 'Descartado';

  @override
  String get tsSevLow => 'Baja';

  @override
  String get tsSevMedium => 'Media';

  @override
  String get tsSevHigh => 'Alta';

  @override
  String get tsSevCritical => 'Crítica';

  @override
  String get tsRoleCustomer => 'Cliente';

  @override
  String get tsRoleProfessional => 'Profesional';

  @override
  String get tsRoleAdmin => 'Administrador';

  @override
  String get tsActWarning => 'Advertencia';

  @override
  String get tsActRestrictMessaging => 'Restricción de mensajería';

  @override
  String get tsActRestrictBooking => 'Restricción de reservas';

  @override
  String get tsActSuspendTemporary => 'Suspensión temporal';

  @override
  String get tsActSuspendPermanent => 'Suspensión permanente';

  @override
  String get tsActWarningDesc =>
      'Registra una advertencia formal. No limita la cuenta.';

  @override
  String get tsActRestrictMessagingDesc =>
      'Marca la cuenta como restringida para enviar mensajes.';

  @override
  String get tsActRestrictBookingDesc =>
      'Marca la cuenta como restringida para crear reservas.';

  @override
  String get tsActSuspendTemporaryDesc =>
      'Marca la cuenta como suspendida hasta la fecha que elijas.';

  @override
  String get tsActSuspendPermanentDesc =>
      'Marca la cuenta como suspendida de forma permanente. Sin vencimiento; solo un administrador puede revertirla.';

  @override
  String get tsStateActive => 'Activa';

  @override
  String get tsStateScheduled => 'Programada';

  @override
  String get tsStateExpired => 'Vencida';

  @override
  String get tsStateReversed => 'Revertida';

  @override
  String get tsAppealPending => 'Pendiente';

  @override
  String get tsAppealApproved => 'Aprobada';

  @override
  String get tsAppealRejected => 'Rechazada';

  @override
  String get tsReportsTitle => 'Usuarios denunciados';

  @override
  String tsPendingReview(String count) {
    return '$count pendientes de revisión';
  }

  @override
  String get tsSearchReportsHint =>
      'Buscar por usuario, denunciante, categoría o ID';

  @override
  String get tsFilterSeverity => 'Gravedad';

  @override
  String get tsFilterCategory => 'Categoría';

  @override
  String get tsFilterDate => 'Fecha';

  @override
  String get tsDateAny => 'Cualquier momento';

  @override
  String get tsDateToday => 'Hoy';

  @override
  String get tsDate7 => 'Últimos 7 días';

  @override
  String get tsDate30 => 'Últimos 30 días';

  @override
  String get tsDateCustom => 'Rango personalizado';

  @override
  String get tsSortNewest => 'Más recientes primero';

  @override
  String get tsSortSeverity => 'Mayor gravedad primero';

  @override
  String get tsClearFilters => 'Borrar filtros';

  @override
  String get tsNoReports => 'Aún no hay denuncias';

  @override
  String get tsNoReportsHint =>
      'Las denuncias enviadas por los usuarios aparecerán aquí.';

  @override
  String get tsNoMatches => 'Ninguna denuncia coincide con tus filtros';

  @override
  String get tsNoMatchesHint => 'Prueba a cambiar o borrar los filtros.';

  @override
  String get tsSelectReport => 'Selecciona una denuncia';

  @override
  String get tsSelectReportHint =>
      'Elige una denuncia de la lista para revisarla y actuar.';

  @override
  String get tsIndBooking => 'Reserva';

  @override
  String get tsIndMessage => 'Mensaje';

  @override
  String get tsIndEvidence => 'Prueba';

  @override
  String tsReportedBy(String name) {
    return 'Denunciado por $name';
  }

  @override
  String get tsAccountBlocked => 'Cuenta bloqueada';

  @override
  String tsReportNumber(String id) {
    return 'Denuncia n.º $id';
  }

  @override
  String tsSubmittedOn(String date) {
    return 'Enviada el $date';
  }

  @override
  String get tsTakeAction => 'Tomar medidas';

  @override
  String get tsMarkReviewed => 'Marcar como revisada';

  @override
  String get tsDismiss => 'Descartar';

  @override
  String get tsSecDescription => 'Descripción de la denuncia';

  @override
  String get tsNoDescription => 'No se proporcionó ninguna descripción.';

  @override
  String get tsSecEvidence => 'Pruebas y contexto';

  @override
  String get tsEvidenceLabel => 'PRUEBA / REFERENCIA';

  @override
  String get tsNoEvidence => 'No se proporcionó enlace de prueba.';

  @override
  String get tsBookingLabel => 'RESERVA RELACIONADA';

  @override
  String tsBookingNumber(String id) {
    return 'Reserva n.º $id';
  }

  @override
  String get tsMessageLabel => 'MENSAJE RELACIONADO';

  @override
  String tsMessageNumber(String id) {
    return 'Mensaje n.º $id';
  }

  @override
  String get tsMessageDeleted =>
      'Este mensaje fue eliminado. Su contenido no está disponible.';

  @override
  String tsMessageAttachments(String count) {
    return 'Archivos adjuntos: $count';
  }

  @override
  String get tsNoRelated => 'Nada vinculado a esta denuncia.';

  @override
  String get tsFieldWhen => 'Cuándo';

  @override
  String get tsFieldParties => 'Partes';

  @override
  String get tsFieldSender => 'Remitente';

  @override
  String tsBookingWith(String customer, String professional) {
    return '$customer con $professional';
  }

  @override
  String get tsSecPeople => 'Personas';

  @override
  String get tsReportedUser => 'USUARIO DENUNCIADO';

  @override
  String get tsReporterLabel => 'DENUNCIANTE';

  @override
  String get tsReporterAdminOnly =>
      'Visible solo para administradores. Nunca se muestra al usuario denunciado.';

  @override
  String get tsAccountBlockedNote =>
      'Esta cuenta está bloqueada actualmente (consulta la pestaña Bloqueados). El bloqueo es independiente de las acciones de moderación.';

  @override
  String get tsSecActive => 'Restricciones y suspensión activas';

  @override
  String get tsNoActive => 'No hay restricciones ni suspensión activas.';

  @override
  String get tsSecTimeline => 'Historial de la denuncia';

  @override
  String get tsSecHistory => 'Historial de moderación';

  @override
  String get tsSecOtherReports => 'Otras denuncias sobre este usuario';

  @override
  String get tsHistoryLoadError =>
      'No se pudo cargar el historial de moderación.';

  @override
  String get tsHistoryEmpty =>
      'No hay acciones de moderación registradas para este usuario.';

  @override
  String get tsTlSubmitted => 'Denuncia enviada';

  @override
  String tsTlReviewed(String status, String admin) {
    return 'Marcada como $status por $admin';
  }

  @override
  String tsTlInternalNote(String note) {
    return 'Nota interna: $note';
  }

  @override
  String tsTlActionApplied(String action, String admin) {
    return '$action aplicada por $admin';
  }

  @override
  String tsTlActionReversed(String action, String admin) {
    return '$action revertida por $admin';
  }

  @override
  String get tsThisReport => 'Esta denuncia';

  @override
  String tsHistPerformedBy(String admin, String date) {
    return 'Por $admin el $date';
  }

  @override
  String tsStartsOn(String date) {
    return 'Comienza el $date';
  }

  @override
  String tsExpiresOn(String date) {
    return 'Vence el $date';
  }

  @override
  String get tsNoExpiryPermanent => 'Permanente, sin vencimiento';

  @override
  String get tsNoExpiryOpen => 'Sin fecha de fin, activa hasta que se levante';

  @override
  String get tsReasonShownToUser => 'MOTIVO (SE MUESTRA AL USUARIO)';

  @override
  String get tsInternalNoteLabel => 'Nota interna (solo administradores)';

  @override
  String tsHistReversedBy(String admin, String date) {
    return 'Revertida por $admin el $date';
  }

  @override
  String get tsReverse => 'Revertir';

  @override
  String get tsAdminUnknown => 'Administrador desconocido';

  @override
  String get tsReviewTitle => 'Marcar la denuncia como revisada';

  @override
  String get tsReviewMessage =>
      'Confirma que has revisado esta denuncia. Puedes agregar una nota interna.';

  @override
  String get tsReviewConfirm => 'Marcar como revisada';

  @override
  String get tsDismissTitle => 'Descartar denuncia';

  @override
  String get tsDismissMessage =>
      'Descarta esta denuncia si no infringe las normas. No se toma ninguna medida contra el usuario denunciado.';

  @override
  String get tsDismissConfirm => 'Descartar denuncia';

  @override
  String get tsResolveReporterNote =>
      'El denunciante recibe una notificación genérica del resultado. El usuario denunciado no es notificado.';

  @override
  String get tsReportUpdated => 'Denuncia actualizada';

  @override
  String get tsTakeActionTitle => 'Tomar medida de moderación';

  @override
  String tsRegardingReport(String id) {
    return 'Sobre la denuncia n.º $id';
  }

  @override
  String get tsChooseAction => 'Elige una acción';

  @override
  String get tsChooseActionError => 'Selecciona una acción para continuar.';

  @override
  String get tsAlreadyActive => 'Ya está activa para este usuario.';

  @override
  String get tsAlreadyPermanentlySuspended =>
      'Este usuario ya está suspendido de forma permanente.';

  @override
  String get tsDurationTitle => 'Duración';

  @override
  String get tsDurationUntilLifted => 'Hasta que se levante';

  @override
  String get tsDurationPermanent => 'Permanente';

  @override
  String tsDurationDays(String n) {
    return '$n días';
  }

  @override
  String get tsDurationCustom => 'Fecha personalizada';

  @override
  String tsEndsAt(String when) {
    return 'Termina $when';
  }

  @override
  String tsUntilDate(String date) {
    return 'Hasta el $date';
  }

  @override
  String get tsExpiryRequired => 'Elige cuándo termina.';

  @override
  String get tsExpiryMustBeFuture =>
      'La hora de finalización debe estar en el futuro.';

  @override
  String get tsReasonLabel => 'Motivo';

  @override
  String get tsReasonHint => 'Explica por qué se toma esta acción';

  @override
  String get tsReasonUserVisibleNote =>
      'Se muestra al usuario en su notificación. No menciones al denunciante ni a otros usuarios.';

  @override
  String tsReasonTooShort(String min) {
    return 'Introduce un motivo de al menos $min caracteres.';
  }

  @override
  String get tsInternalNoteHint =>
      'Contexto opcional para otros administradores';

  @override
  String get tsInternalNoteNote =>
      'Solo uso interno. Nunca se muestra al usuario.';

  @override
  String get tsMarkReportTaken => 'Marcar esta denuncia como «Acción tomada»';

  @override
  String get tsMarkReportTakenHint =>
      'El denunciante recibe únicamente una notificación genérica del resultado.';

  @override
  String get tsApplyAction => 'Aplicar acción';

  @override
  String tsConfirmTitle(String action) {
    return '¿Aplicar $action?';
  }

  @override
  String tsConfirmBody(String user) {
    return 'Esto queda registrado en el historial de moderación de $user y se notifica al usuario.';
  }

  @override
  String get tsConfirmPermanentAck =>
      'Entiendo que esta suspensión no tiene vencimiento y solo puede ser revertida por un administrador.';

  @override
  String get tsFieldUser => 'Usuario';

  @override
  String get tsFieldAction => 'Acción';

  @override
  String get tsFieldDuration => 'Duración';

  @override
  String get tsFieldReason => 'Motivo';

  @override
  String get tsActionApplied => 'Acción de moderación aplicada';

  @override
  String get tsActionAppliedReportFailed =>
      'La acción se aplicó, pero no se pudo actualizar el estado de la denuncia.';

  @override
  String get tsCannotActOnAdmin =>
      'Las acciones de moderación no pueden dirigirse a cuentas de administrador.';

  @override
  String get tsFieldPerformedBy => 'Realizada por';

  @override
  String get tsFieldCreated => 'Creada';

  @override
  String get tsFieldExpires => 'Vence';

  @override
  String get tsFieldReport => 'Denuncia';

  @override
  String get tsFieldDecidedBy => 'Decidida por';

  @override
  String get tsFieldDecidedOn => 'Decidida el';

  @override
  String get tsReverseTitle => 'Revertir acción de moderación';

  @override
  String tsReverseMessage(String action) {
    return '¿Revertir $action? Se levanta y el registro permanece en el historial.';
  }

  @override
  String get tsReversalReasonLabel => 'Motivo de la reversión';

  @override
  String get tsReversalReasonHint => '¿Por qué se levanta esta acción?';

  @override
  String get tsReverseConfirm => 'Revertir acción';

  @override
  String get tsReverseAuditNote =>
      'Tu motivo es interno. Se registra en el historial de moderación y nunca se muestra al usuario.';

  @override
  String get tsReverseNotifyNote =>
      'Se notifica al usuario que esta acción fue levantada.';

  @override
  String get tsReverseLegacyNote =>
      'Esta acción proviene del antiguo flujo de bloqueo. Revertirla también reactiva la cuenta.';

  @override
  String get tsActionReversed => 'Acción de moderación revertida';

  @override
  String get tsAppealsTitle => 'Apelaciones';

  @override
  String tsPendingAppeals(String count) {
    return '$count apelaciones pendientes';
  }

  @override
  String get tsSearchAppealsHint =>
      'Buscar por usuario, correo o texto de la apelación';

  @override
  String get tsNoAppeals => 'No hay apelaciones aquí';

  @override
  String get tsNoAppealsHint =>
      'Las apelaciones contra acciones de moderación aparecerán aquí.';

  @override
  String get tsSelectAppeal => 'Selecciona una apelación';

  @override
  String get tsSelectAppealHint =>
      'Elige una apelación de la lista para revisarla.';

  @override
  String tsAppealNumber(String id) {
    return 'Apelación n.º $id';
  }

  @override
  String get tsSecAppealReason => 'Apelación';

  @override
  String get tsSecAppealedAction => 'Acción apelada';

  @override
  String get tsSecDecision => 'Decisión';

  @override
  String get tsAppealApprove => 'Aprobar';

  @override
  String get tsAppealReject => 'Rechazar';

  @override
  String get tsApproveTitle => 'Aprobar apelación';

  @override
  String get tsApproveMessage =>
      'Aprobar esta apelación levanta la acción de moderación.';

  @override
  String get tsApproveConfirm => 'Aprobar apelación';

  @override
  String get tsRejectTitle => 'Rechazar apelación';

  @override
  String get tsRejectMessage =>
      'Rechazarla mantiene la acción de moderación vigente.';

  @override
  String get tsRejectConfirm => 'Rechazar apelación';

  @override
  String get tsDecisionNoteLabel => 'Nota de la decisión';

  @override
  String get tsDecisionNoteHint => 'Explica tu decisión';

  @override
  String get tsDecisionNoteNote =>
      'Solo uso interno. Nunca se muestra al usuario.';

  @override
  String get tsAppealApproveNote =>
      'La acción se revierte y se notifica al usuario.';

  @override
  String get tsAppealApproveInactive =>
      'Esta acción ya no está en vigor, por lo que aprobar solo cierra la apelación. Se notifica al usuario.';

  @override
  String get tsAppealRejectNote =>
      'La acción se mantiene y se notifica al usuario del resultado.';

  @override
  String get tsAppealApprovedSnack => 'Apelación aprobada';

  @override
  String get tsAppealRejectedSnack => 'Apelación rechazada';

  @override
  String get tsNoDecisionNote => 'No se registró ninguna nota.';

  @override
  String get tsEvidenceLinkOptional => 'Enlace de evidencia (opcional)';

  @override
  String get tsInvalidHttpUrl => 'Introduce una URL http o https válida.';

  @override
  String get myTsMyReportsTitle => 'Mis reportes';

  @override
  String get myTsMyReportsActionSubtitle => 'Reportes que has enviado';

  @override
  String get myTsReportsEmptyTitle => 'Aún no hay reportes';

  @override
  String get myTsReportsEmptyMessage =>
      'Los reportes que envíes sobre otros usuarios aparecerán aquí.';

  @override
  String get myTsReportsLoadError =>
      'No se pudieron cargar tus reportes. Desliza hacia abajo para reintentar.';

  @override
  String get myTsCategoryLabel => 'Categoría';

  @override
  String get myTsSubmittedLabel => 'Enviado';

  @override
  String get myTsStatusLabel => 'Estado';

  @override
  String get myTsOutcomeLabel => 'Resultado';

  @override
  String get myTsYourDescriptionLabel => 'Tu descripción';

  @override
  String get myTsOutcomePending => 'Nuestro equipo aún no ha revisado esto.';

  @override
  String get myTsOutcomeReviewedNoAction =>
      'Revisado: no fue necesaria ninguna otra acción.';

  @override
  String get myTsOutcomeActionTaken =>
      'Revisado: se tomaron medidas según tu reporte.';

  @override
  String get myTsOutcomeDismissed =>
      'Revisado: no se encontró ninguna infracción.';

  @override
  String get myTsAccountStatusTitle => 'Estado de la cuenta';

  @override
  String get myTsAccountStatusActionSubtitle =>
      'Advertencias, restricciones y suspensiones';

  @override
  String get myTsGoodStandingTitle => 'Sin restricciones activas';

  @override
  String get myTsGoodStandingMessage => 'Tu cuenta está en buen estado.';

  @override
  String get myTsStatusLoadError =>
      'No se pudo cargar el estado de tu cuenta. Desliza hacia abajo para reintentar.';

  @override
  String get myTsStartTimeLabel => 'Hora de inicio';

  @override
  String get myTsExpirationTimeLabel => 'Hora de expiración';

  @override
  String get myTsAffectedFeatureLabel => 'Función afectada';

  @override
  String get myTsFeatureMessaging => 'Mensajería';

  @override
  String get myTsFeatureBooking => 'Reservas';

  @override
  String get myTsWarningInfoNote =>
      'Esto es solo una advertencia. No restringe tu cuenta, pero infracciones repetidas pueden dar lugar a más medidas.';

  @override
  String get myTsAppealAvailableNote => 'Puedes apelar esta decisión.';

  @override
  String get myTsAppealButtonLabel => 'Apelar esta decisión';

  @override
  String get myTsAppealPendingNote =>
      'Tu apelación está pendiente de revisión.';

  @override
  String get myTsMyAppealsTitle => 'Mis apelaciones';

  @override
  String get myTsMyAppealsEmpty => 'No has enviado ninguna apelación.';

  @override
  String get myTsAppealsLoadError =>
      'No se pudieron cargar tus apelaciones. Desliza hacia abajo para reintentar.';

  @override
  String get myTsAppealDecidedNote => 'Esta apelación ya ha sido decidida.';

  @override
  String get myTsSubmitAppealTitle => 'Apelar esta decisión';

  @override
  String get myTsAppealReasonLabel => '¿Por qué debería revisarse esto?';

  @override
  String get myTsAppealReasonHint =>
      'Explica por qué crees que esta decisión debería reconsiderarse';

  @override
  String get myTsAppealReasonRequired =>
      'Explica por qué debería revisarse esto.';

  @override
  String get myTsAppealSubmitCta => 'Enviar apelación';

  @override
  String get myTsAppealSubmitSuccess => 'Tu apelación ha sido enviada.';

  @override
  String get myTsAppealSubmitError =>
      'No se pudo enviar tu apelación. Inténtalo de nuevo.';

  @override
  String get myTsAppealAlreadyPending =>
      'Ya tienes una apelación pendiente para esto.';

  @override
  String get myTsAppealNotEligible => 'Ya no se puede apelar esta acción.';

  @override
  String myTsAppealForLabel(String action) {
    return 'Apelación de $action';
  }

  @override
  String get announcementDismiss => 'Cerrar anuncio';

  @override
  String get chatMessageHint => 'Mensaje';

  @override
  String get voiceRecordStartFailed =>
      'No se pudo iniciar la grabación. Comprueba el micrófono e inténtalo de nuevo.';

  @override
  String get voiceRecordSaveFailed =>
      'No se pudo guardar la grabación. Inténtalo de nuevo.';

  @override
  String get voicePlayFailed => 'No se pudo reproducir este mensaje de voz.';

  @override
  String get reviewSortBy => 'Ordenar por';

  @override
  String get reviewSortRelevant => 'Más relevantes';

  @override
  String get reviewSortNewest => 'Más recientes';

  @override
  String get reviewSortHighest => 'Mayor valoración';

  @override
  String get reviewSortLowest => 'Menor valoración';

  @override
  String get reviewSortHelpful => 'Más útiles';

  @override
  String get reviewSortWithPhotos => 'Con fotos';

  @override
  String get reviewFilterAll => 'Todas las reseñas';

  @override
  String get promoSkip => 'Omitir';

  @override
  String reviewCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reseñas',
      one: '1 reseña',
    );
    return '$_temp0';
  }

  @override
  String get valEmailRequired => 'El correo electrónico es obligatorio';

  @override
  String get valEmailInvalid => 'Introduce un correo electrónico válido';

  @override
  String get valEmailTooLong => 'El correo electrónico es demasiado largo';

  @override
  String get valPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get valPasswordMinLength =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get valPasswordUpper => 'Añade al menos una letra mayúscula';

  @override
  String get valPasswordLower => 'Añade al menos una letra minúscula';

  @override
  String get valPasswordNumber => 'Añade al menos un número';

  @override
  String get valPasswordSpecial => 'Añade al menos un carácter especial';

  @override
  String get valConfirmPassword => 'Confirma tu contraseña';

  @override
  String get valPasswordsMismatch => 'Las contraseñas no coinciden';

  @override
  String get valNameRequired => 'El nombre es obligatorio';

  @override
  String get valNameMinLength => 'El nombre debe tener al menos 2 caracteres';

  @override
  String get valNameMaxLength => 'El nombre debe tener menos de 50 caracteres';

  @override
  String get valNameNoNumbers => 'El nombre no puede contener números';

  @override
  String get valNameInvalidChars => 'El nombre contiene caracteres no válidos';

  @override
  String get valPhoneRequired => 'El número de teléfono es obligatorio';

  @override
  String get valPhoneInvalid => 'Introduce un número de teléfono válido';

  @override
  String get valFieldRequired => 'Este campo es obligatorio';

  @override
  String valFieldNamedRequired(String field) {
    return '$field es obligatorio';
  }

  @override
  String get pwReqMinLength => 'Mínimo 8 caracteres';

  @override
  String get pwReqUppercase => 'Letra mayúscula';

  @override
  String get pwReqLowercase => 'Letra minúscula';

  @override
  String get pwReqNumber => 'Número';

  @override
  String get pwReqSpecial => 'Carácter especial';

  @override
  String get pwStrengthVeryWeak => 'Muy débil';

  @override
  String get pwStrengthWeak => 'Débil';

  @override
  String get pwStrengthMedium => 'Media';

  @override
  String get pwStrengthStrong => 'Fuerte';

  @override
  String get pwStrengthExcellent => 'Excelente';

  @override
  String get pickerTapToSelect => 'Toca para seleccionar';

  @override
  String get pickerNoResults => 'No se encontraron resultados';

  @override
  String get pickerSearchHint => 'Buscar...';

  @override
  String get pickerSelectAboveFirst => 'Selecciona primero el campo anterior';

  @override
  String get bkStatusAll => 'Todas';

  @override
  String get bkStatusPending => 'Pendiente';

  @override
  String get bkStatusAccepted => 'Aceptada';

  @override
  String get bkStatusCompleted => 'Completada';

  @override
  String get bkStatusCancelled => 'Cancelada';

  @override
  String get bkStatusRejected => 'Rechazada';

  @override
  String get bkStatusRescheduled => 'Reprogramada';

  @override
  String get bkStatusBooked => 'Reservada';

  @override
  String get bkSwipeHint => 'desliza';

  @override
  String bkCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reservas',
      one: '1 reserva',
    );
    return '$_temp0';
  }

  @override
  String get bkSectionDetails => 'Detalles de la reserva';

  @override
  String get bkSectionService => 'Servicio';

  @override
  String get bkSectionNotes => 'Notas del cliente';

  @override
  String get bkSectionTimeline => 'Cronología de la reserva';

  @override
  String get bkFieldDate => 'Fecha';

  @override
  String get bkFieldTime => 'Hora';

  @override
  String get bkFieldLocation => 'Ubicación';

  @override
  String get bkFieldCategory => 'Categoría';

  @override
  String get bkCancelledByProfessional => 'Cancelada por el profesional';

  @override
  String get bkCancelledByYou => 'Cancelada por ti';

  @override
  String get bkWasRejected => 'La reserva fue rechazada';

  @override
  String get bkWasCancelled => 'La reserva fue cancelada';

  @override
  String get bkCancelledSuccess => 'Reserva cancelada';

  @override
  String get bkCancelFailed => 'No se pudo cancelar, inténtalo de nuevo';

  @override
  String get detailTabOverview => 'Resumen';

  @override
  String detailTabPortfolio(int count) {
    return 'Portafolio ($count)';
  }

  @override
  String detailTabReviews(int count) {
    return 'Reseñas ($count)';
  }

  @override
  String get detailTabServices => 'Servicios';

  @override
  String get detailTabAvailability => 'Disponibilidad';

  @override
  String get detailNotAvailable => 'No disponible';

  @override
  String get detailCertificateDefault => 'Certificado';

  @override
  String get detailPortfolioItemDefault => 'Elemento del portafolio';

  @override
  String get categoryItTech => 'TI y Tecnología';

  @override
  String get categoryEngineers => 'Ingenieros';

  @override
  String get categoryLawyersLegal => 'Abogados y Legal';

  @override
  String get categoryDoctorsHealthcare => 'Médicos y Salud';

  @override
  String get categoryArchitects => 'Arquitectos';

  @override
  String get categoryElectricians => 'Electricistas';

  @override
  String get categoryPlumbers => 'Plomeros';

  @override
  String get categoryTutorsEducation => 'Tutores y Educación';

  @override
  String get ctaGrowYourBusiness => 'Haz crecer tu negocio';

  @override
  String get ctaJoinProfessionalsSubtitle =>
      'Únete a más de 500 profesionales en ProFinder';

  @override
  String get ctaJoinNow => 'Únete ahora';

  @override
  String get promoGetPremium => 'Obtén Premium';

  @override
  String get categoryCarpenters => 'Carpinteros';

  @override
  String get errSomethingWentWrong => 'Algo salió mal.';

  @override
  String get errSomethingWentWrongTryAgain =>
      'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errNetworkCheckConnection => 'Error de red. Revisa tu conexión.';

  @override
  String get errNetworkProblemTryAgain =>
      'Problema de red. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String errRequestFailedHttp(int code) {
    return 'La solicitud falló (HTTP $code).';
  }

  @override
  String get errNotLoggedIn => 'No has iniciado sesión';

  @override
  String get bkStepTitleService => 'Resumen del servicio';

  @override
  String get bkStepTitleDate => 'Selecciona la fecha';

  @override
  String get bkStepTitleTime => 'Selecciona la hora';

  @override
  String get bkStepTitleNotes => 'Notas adicionales';

  @override
  String get bkStepTitleSummary => 'Resumen de la reserva';

  @override
  String get bkStepDesc1 =>
      'Revisa los datos del profesional antes de continuar.';

  @override
  String get bkStepDesc2 => 'Elige la fecha que mejor se adapte a tu cita.';

  @override
  String get bkStepDesc3 => 'Elige un horario disponible para tu visita.';

  @override
  String get bkStepDesc4 =>
      'Indica al profesional dónde debe prestar el servicio.';

  @override
  String get bkStepDesc5 =>
      'Añade cualquier detalle que ayude al profesional a prepararse.';

  @override
  String get bkStepDesc6 =>
      'Revisa todo con atención antes de confirmar tu reserva.';

  @override
  String get bkWeekdayMon => 'Lun';

  @override
  String get bkWeekdayTue => 'Mar';

  @override
  String get bkWeekdayWed => 'Mié';

  @override
  String get bkWeekdayThu => 'Jue';

  @override
  String get bkWeekdayFri => 'Vie';

  @override
  String get bkWeekdaySat => 'Sáb';

  @override
  String get bkWeekdaySun => 'Dom';

  @override
  String get bkGoodToKnow1 =>
      'Enviar una solicitud es gratis y solo toma un minuto.';

  @override
  String get bkGoodToKnow2 =>
      'Recibirás una notificación en cuanto el profesional responda.';

  @override
  String get bkGoodToKnow3 =>
      'Puedes cancelar sin coste mientras tu solicitud siga pendiente.';

  @override
  String get bkTimeSlots1 =>
      'Solo se muestran los horarios dentro de la jornada del profesional.';

  @override
  String get bkTimeSlots2 =>
      'Los horarios de hoy que ya pasaron se desactivan automáticamente.';

  @override
  String get bkTimeSlots3 =>
      'Puedes cambiar la hora elegida en cualquier momento antes de confirmar.';

  @override
  String get chatCouldNotLoadConversations =>
      'No se pudieron cargar las conversaciones';

  @override
  String get chatVoiceMessagePreview => '🎤 Mensaje de voz';

  @override
  String get chatPhotoPreview => '📷 Foto';

  @override
  String get reviewRatingPoor => 'Malo';

  @override
  String get reviewRatingFair => 'Regular';

  @override
  String get reviewRatingGood => 'Bueno';

  @override
  String get reviewRatingVeryGood => 'Muy bueno';

  @override
  String get reviewRatingExcellent => 'Excelente';

  @override
  String get reviewReportReasonSpam => 'Spam';

  @override
  String get reviewReportReasonFake => 'Reseña falsa';

  @override
  String get reviewReportReasonAbusive => 'Lenguaje abusivo';

  @override
  String get reviewReportReasonHarassment => 'Acoso';

  @override
  String get reviewReportReasonOffTopic => 'Fuera de tema';

  @override
  String get reviewReportReasonConflict => 'Conflicto de intereses';

  @override
  String get reviewReportReasonOther => 'Otro';

  @override
  String get availabilityStatusBusy => 'Ocupado';

  @override
  String get availabilityStatusOnLeave => 'De permiso';

  @override
  String get availabilityStatusDescAvailable =>
      'Los clientes pueden reservarte ahora mismo';

  @override
  String get availabilityStatusDescBusy =>
      'Estás trabajando — las nuevas solicitudes están en pausa';

  @override
  String get availabilityStatusDescOffline =>
      'No aparecerás en las nuevas solicitudes de reserva';

  @override
  String get availabilityStatusDescOnLeave =>
      'Marcado como de permiso hasta que regreses';

  @override
  String get professionalInvalidId => 'ID de profesional no válido';

  @override
  String get uploadFailedTryAgain => 'Error al subir. Inténtalo de nuevo.';

  @override
  String get editorListItemPlaceholder => 'Elemento de lista';

  @override
  String get pushChannelGeneralName => 'Notificaciones generales';

  @override
  String get pushChannelGeneralDesc =>
      'Reservas, anuncios, reportes y otras alertas';

  @override
  String get pushChannelChatName => 'Mensajes de chat';

  @override
  String get pushChannelChatDesc => 'Nuevos mensajes de chat';

  @override
  String get errBookingLimitReached => 'Se alcanzó el límite de reservas.';

  @override
  String get categoryCarpenter => 'Carpintero';
}
