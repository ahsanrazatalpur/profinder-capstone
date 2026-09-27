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
  String get aboutActionLabel => 'About';

  @override
  String get aboutActionSubtitle => 'About this app';

  @override
  String get aboutAppStoreLabel => 'App Store';

  @override
  String get aboutDisabledBadgeLabel => 'Unavailable';

  @override
  String get aboutEmptyStateMessage =>
      'We couldn\'t find any information to show right now.';

  @override
  String get aboutEmptyStateTitle => 'Nothing to Show';

  @override
  String get aboutGooglePlayLabel => 'Google Play';

  @override
  String get aboutLabel => 'About';

  @override
  String aboutLinkCouldNotOpen(Object value1) {
    return 'Could not open this link $value1';
  }

  @override
  String aboutLinkError(Object value1) {
    return 'Something went wrong while opening the link $value1';
  }

  @override
  String aboutLinkNoAppFound(Object value1) {
    return 'No app found to open this link $value1';
  }

  @override
  String get aboutLoadError => 'Failed to load this page';

  @override
  String get aboutLoadingText => 'Loading...';

  @override
  String get aboutTitle => 'About';

  @override
  String get acceptCta => 'Accept';

  @override
  String get acceptDescription => 'Accept this booking';

  @override
  String get acceptLabel => 'Accept';

  @override
  String get acceptanceRateLabel => 'Acceptance Rate';

  @override
  String get acceptanceRateSubtext => 'Of bookings you accept';

  @override
  String get acceptedLabel => 'Accepted';

  @override
  String get acceptingBookingsLabel => 'Accepting Bookings';

  @override
  String get accountGroupLabel => 'Account';

  @override
  String get accountHolderLabel => 'Account Holder Name';

  @override
  String get accountNumberLabel => 'Account Number';

  @override
  String get accountSectionLabel => 'Account';

  @override
  String get accountTypeLabel => 'Account Type';

  @override
  String get addBankBannerSubtitle =>
      'Add your bank details to receive withdrawals';

  @override
  String get addBankBannerTitle => 'Add Bank Details';

  @override
  String get addBankCta => 'Add Bank Account';

  @override
  String get addCertificateImageLabel => 'Certificate Image';

  @override
  String get addCertificateTitle => 'Add Certificate';

  @override
  String get addCertificateTooltip => 'Add a certificate';

  @override
  String get addCta => 'Add';

  @override
  String get addFirstCertificateCta => 'Add Your First Certificate';

  @override
  String get addFirstItemCta => 'Add Your First Item';

  @override
  String get addImageLabel => 'Add Image';

  @override
  String get addLanguageHint => 'Type a language and press enter';

  @override
  String get addPhotoCta => 'Add Photo';

  @override
  String get addPhotoTooltip => 'Add a photo';

  @override
  String get addPortfolioHint =>
      'Showcase your best work to attract more customers';

  @override
  String get addPortfolioTitle => 'Add Portfolio Item';

  @override
  String get addPortfolioTooltip => 'Add portfolio item';

  @override
  String get addSkillHint => 'Type a skill and press enter';

  @override
  String get addWorkSamplesLabel => 'Add work samples';

  @override
  String get adjustSearchTerms => 'Try adjusting your search terms';

  @override
  String get adminNoteLabel => 'Admin Note';

  @override
  String get allCategoriesTitle => 'All Categories';

  @override
  String get analyticsErrorTitle => 'Couldn\'t load analytics';

  @override
  String get analyticsLoadError => 'Failed to load analytics';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get applyCta => 'Apply';

  @override
  String get approvalSubtitle => 'Pending admin approval';

  @override
  String get approvalTitle => 'Approval Status';

  @override
  String get articleFooterMagazineLabel => 'More from Magazine';

  @override
  String get articleLoadingText => 'Loading article...';

  @override
  String get articleNotFoundError => 'Article not found';

  @override
  String get articleNotFoundMessage =>
      'This article may have been removed or doesn\'t exist';

  @override
  String articleReadTime(Object value1) {
    return '$value1 min read';
  }

  @override
  String articleReadTimeLabel(Object value1) {
    return '$value1 min read';
  }

  @override
  String get automaticDescription =>
      'Automatically accept bookings that meet your criteria';

  @override
  String get automaticLabel => 'Automatic';

  @override
  String get availabilityClosedLabel => 'Closed';

  @override
  String get availabilityLabel => 'Availability';

  @override
  String get availabilityLoadError => 'Failed to load availability';

  @override
  String get availabilityOffSuccess => 'You\'re now marked as unavailable';

  @override
  String get availabilityOnSuccess => 'You\'re now marked as available';

  @override
  String get availabilityScheduleSaveError => 'Failed to save schedule';

  @override
  String get availabilityScheduleSaved => 'Schedule saved successfully';

  @override
  String get availabilityStatusUpdateError =>
      'Failed to update availability status';

  @override
  String availabilityStatusUpdated(Object value1) {
    return 'Availability set to $value1';
  }

  @override
  String get availabilitySummarySubtitle =>
      'Your weekly working hours at a glance';

  @override
  String get availabilitySummaryTitle => 'Availability Summary';

  @override
  String get availabilityTitle => 'Availability';

  @override
  String get availabilityUpdateError => 'Failed to update availability';

  @override
  String get availabilityWeeklySubtitle =>
      'Set your working hours for each day';

  @override
  String get availabilityWeeklyTitle => 'Weekly Schedule';

  @override
  String availableBalanceLabel(Object value1) {
    return 'Available balance: Rs $value1';
  }

  @override
  String get availableBalanceTitle => 'Available Balance';

  @override
  String get availableForBookingsLabel => 'Available for Bookings';

  @override
  String get availableLabel => 'Available';

  @override
  String get availableNowLabel => 'Available Now';

  @override
  String get availableSubtitle => 'Ready to accept new bookings';

  @override
  String get averageRatingLabel => 'Average Rating';

  @override
  String get averageRatingSubtext => 'Based on customer reviews';

  @override
  String get backCta => 'Back';

  @override
  String get backToBookingsCta => 'Back to Bookings';

  @override
  String get backToHomeCta => 'Back to Home';

  @override
  String get backToLoginCta => 'Back to Login';

  @override
  String get bankDetailsEmpty => 'No bank details added yet';

  @override
  String get bankDetailsLabel => 'Bank Details';

  @override
  String get bankDetailsRequiredMessage =>
      'Please add your bank details before requesting a withdrawal';

  @override
  String get bankDetailsRequiredTitle => 'Bank Details Required';

  @override
  String get bankDetailsSubtitle => 'Used for withdrawals to your account';

  @override
  String get bankNameLabel => 'Bank Name';

  @override
  String get bioLabel => 'Bio';

  @override
  String get bookAppointmentTitle => 'Book Appointment';

  @override
  String get bookCta => 'Book';

  @override
  String get bookNowCta => 'Book Now';

  @override
  String get bookingConfigurationTitle => 'Booking Configuration';

  @override
  String get bookingDateRequired => 'Please select a date';

  @override
  String get bookingDetailsTitle => 'Booking Details';

  @override
  String get bookingFailed => 'Booking failed. Please try again.';

  @override
  String get bookingManagementTitle => 'Manage Bookings';

  @override
  String get bookingSoFarLabel => 'Bookings so far';

  @override
  String bookingStatusUpdated(Object value1) {
    return 'Booking marked as $value1';
  }

  @override
  String bookingSuccessMessage(Object value1) {
    return 'Your booking request with $value1 has been sent';
  }

  @override
  String get bookingSuccessTitle => 'Booking Requested';

  @override
  String get bookingTimeRequired => 'Please select a time';

  @override
  String get bookingTipText =>
      'You can cancel for free up to 24 hours before the appointment';

  @override
  String get bookingUpdateError => 'Failed to update booking';

  @override
  String bookingUpdatedToast(Object value1) {
    return 'Booking updated to $value1';
  }

  @override
  String get bookingsActionLabel => 'Bookings';

  @override
  String get bookingsActionSubtitle => 'View your booking history';

  @override
  String get bookingsLabel => 'Bookings';

  @override
  String get bookingsStatLabel => 'Bookings';

  @override
  String bufferMinLabel(Object value1) {
    return '$value1 min buffer';
  }

  @override
  String get bufferNoneLabel => 'No buffer';

  @override
  String get bufferTimeSubtitle => 'Time between consecutive bookings';

  @override
  String get bufferTimeTitle => 'Buffer Time';

  @override
  String get calendarWeekDays => 'S,M,T,W,T,F,S';

  @override
  String get cameraOptionLabel => 'Camera';

  @override
  String get cancelBookingCta => 'Cancel Booking';

  @override
  String get cancelBookingTitle => 'Cancel Booking';

  @override
  String get cancelConfirmationMessage =>
      'Are you sure you want to cancel this booking?';

  @override
  String get cancelCta => 'Cancel';

  @override
  String get cancelReasonHint => 'Let us know why you are cancelling';

  @override
  String get cancelReasonLabel => 'Reason for cancellation';

  @override
  String get cancellationPolicyLabel => 'Cancellation Policy';

  @override
  String get cancelledByCustomerLabel => 'Cancelled by customer';

  @override
  String get cancelledByYouLabel => 'Cancelled by you';

  @override
  String get categoryLabel => 'Category';

  @override
  String get certificateAddError => 'Failed to add certificate';

  @override
  String get certificateAddSuccess => 'Certificate added successfully';

  @override
  String get certificateTitleHint => 'e.g. Certified Plumbing Technician';

  @override
  String get certificateTitleLabelRequired => 'Certificate Title';

  @override
  String get certificatesLabel => 'Certificates';

  @override
  String get certificatesTitle => 'Certificates';

  @override
  String get certificationsLabel => 'Certifications';

  @override
  String get changePasswordLabel => 'Change Password';

  @override
  String get changePasswordSubtitle => 'Update your account password';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changeProfilePhotoTitle => 'Change Profile Photo';

  @override
  String get chatMicPermissionRequired =>
      'Microphone permission is required to record voice messages';

  @override
  String get chatNoMessagesFound => 'No messages found';

  @override
  String get chatSearchMessagesHint => 'Search messages';

  @override
  String get chatTypeToSearchConversation => 'Type to search this conversation';

  @override
  String get checkEmailHint => 'Didn\'t receive it? Check your spam folder.';

  @override
  String get checkEmailMessage =>
      'We\'ve sent a password reset link to your email';

  @override
  String get checkEmailTitle => 'Check Your Email';

  @override
  String get cityDisabledHint => 'Select a country first';

  @override
  String get cityEmptyMessage => 'No cities found';

  @override
  String get cityHint => 'Select city';

  @override
  String get cityLabel => 'City';

  @override
  String get cityRequiredError => 'Please select a city';

  @override
  String get citySearchHint => 'Search city';

  @override
  String get clearCta => 'Clear';

  @override
  String get clientsLabel => 'Clients';

  @override
  String get closeCta => 'Close';

  @override
  String comingSoonMessage(Object value1) {
    return '$value1 is coming soon';
  }

  @override
  String commentHint(Object value1) {
    return 'Share your experience with $value1';
  }

  @override
  String get commentOptionalLabel => 'Comment Optional';

  @override
  String get completedLabel => 'Completed';

  @override
  String get confirmBookingCta => 'Confirm Booking';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get contactChatLabel => 'Chat with us';

  @override
  String get contactChatSubtitle => 'Get a quick response in chat';

  @override
  String get contactChatTitle => 'Chat Support';

  @override
  String get contactCta => 'Contact';

  @override
  String get contactEmailLabel => 'Email us';

  @override
  String get contactEmailSubtitle => 'We\'ll get back to you within 24 hours';

  @override
  String get contactEmailTitle => 'Email Support';

  @override
  String get contactSupportTitle => 'Contact Support';

  @override
  String get continueAsGuestCta => 'Continue as Guest';

  @override
  String get countryEmptyMessage => 'No countries found';

  @override
  String get countryHint => 'Select country';

  @override
  String get countryRequiredError => 'Please select a country';

  @override
  String get countrySearchHint => 'Search country';

  @override
  String get currencyFeatureName => 'Currency';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String currentPlanLabel(Object value1) {
    return 'Current plan: $value1';
  }

  @override
  String get currentlyBusyLabel => 'Currently Busy';

  @override
  String get customLocationHint => 'Enter a custom location';

  @override
  String get customLocationOption => 'Custom Location';

  @override
  String get customLocationSubtitle => 'Enter an address manually';

  @override
  String get customSlotDefaultLabel => 'Custom';

  @override
  String get customSlotHint => 'Enter duration in minutes';

  @override
  String customSlotLabel(Object value1) {
    return 'Custom ($value1)';
  }

  @override
  String get customSlotTitle => 'Custom Slot Duration';

  @override
  String get customSlotValidation => 'Please enter a valid duration';

  @override
  String get customerAccountDescription =>
      'Book trusted professionals near you';

  @override
  String get customerDefault => 'Customer';

  @override
  String get customerLabel => 'Customer';

  @override
  String get dailyHoursLabel => 'Daily Hours';

  @override
  String get darkModeOffLabel => 'Light Mode';

  @override
  String get darkModeOnLabel => 'Dark Mode';

  @override
  String get dashboardLoadError => 'Failed to load dashboard';

  @override
  String get dateLabel => 'Date';

  @override
  String get dateNotSet => 'Date not set';

  @override
  String get dateNotSetShort => 'No date';

  @override
  String get dateRequiredMessage => 'Please select a date';

  @override
  String get dateTipText => 'Choose a date that works best for you';

  @override
  String daysLabel(Object value1) {
    return '${value1}d';
  }

  @override
  String get declineCta => 'Decline';

  @override
  String get declineDescription => 'Decline this booking';

  @override
  String get declineLabel => 'Decline';

  @override
  String get deleteAccountDialogContent =>
      'This will permanently delete your account and all associated data. This action cannot be undone.';

  @override
  String get deleteAccountDialogTitle => 'Delete Account';

  @override
  String get deleteAccountLabel => 'Delete Account';

  @override
  String get deleteConfirmationTitle => 'Delete this item?';

  @override
  String get deleteCta => 'Delete';

  @override
  String deleteDialogContent(Object value1) {
    return 'Are you sure you want to delete \"$value1\"?';
  }

  @override
  String get deleteDialogTitle => 'Delete Item';

  @override
  String get deleteError => 'Failed to delete';

  @override
  String get deleteGalleryDialogContent =>
      'Are you sure you want to delete this photo?';

  @override
  String get deleteGalleryDialogTitle => 'Delete Photo';

  @override
  String get deleteReviewConfirmationMessage =>
      'Are you sure you want to delete this review?';

  @override
  String get deleteSuccess => 'Deleted successfully';

  @override
  String get descriptionHint => 'Add a description';

  @override
  String get descriptionLabelOptional => 'Description (optional)';

  @override
  String get detailsLabel => 'Details';

  @override
  String get directChatLabel => 'Message';

  @override
  String get discardCta => 'Discard';

  @override
  String get doneCta => 'Done';

  @override
  String get earningsLabel => 'Earnings';

  @override
  String get editCta => 'Edit';

  @override
  String get editLabel => 'Edit';

  @override
  String get editProfileActionLabel => 'Edit Profile';

  @override
  String get editProfileActionSubtitle => 'Update your personal information';

  @override
  String get editReviewHint => 'Update your comment';

  @override
  String get editReviewSubtitle => 'Update your rating and comment';

  @override
  String get editReviewTitle => 'Edit Review';

  @override
  String get editorHeadingPlaceholder => 'Heading';

  @override
  String get editorHintText => 'Start writing...';

  @override
  String get editorInsertCta => 'Insert';

  @override
  String get editorInsertLinkTitle => 'Insert Link';

  @override
  String get editorLinkHint => 'https://example.com';

  @override
  String get editorLinkPlaceholder => 'Link text';

  @override
  String get educationLabel => 'Education';

  @override
  String get emailAvailableLabel => 'Email is available';

  @override
  String get emailNotificationsLabel => 'Email Notifications';

  @override
  String get emailTakenLabel => 'This email is already registered';

  @override
  String get emptyCertificatesSubtitle =>
      'Add your certifications to build trust with customers';

  @override
  String get emptyCertificatesTitle => 'No Certificates Yet';

  @override
  String get emptyGallerySubtitle => 'Add photos to showcase your work';

  @override
  String get emptyGalleryTitle => 'No Photos Yet';

  @override
  String get emptyPortfolioSubtitle =>
      'Add your best work to attract more customers';

  @override
  String get emptyPortfolioTitle => 'No Portfolio Items Yet';

  @override
  String get endTimeLabel => 'End Time';

  @override
  String get enterAmountHint => 'Enter amount';

  @override
  String get exceedsBalanceError => 'Amount exceeds your available balance';

  @override
  String get exceptionsAddRange => 'Add Date Range';

  @override
  String get exceptionsCalendarSubtitle => 'Tap a date to set an exception';

  @override
  String get exceptionsCalendarTitle => 'Calendar';

  @override
  String get exceptionsCustomChip => 'Custom';

  @override
  String get exceptionsEndDate => 'End Date';

  @override
  String get exceptionsIntroText =>
      'Mark dates when your availability differs from your usual schedule';

  @override
  String get exceptionsLegendClosed => 'Closed';

  @override
  String get exceptionsLegendCustom => 'Custom Hours';

  @override
  String get exceptionsLegendUnavailable => 'Unavailable';

  @override
  String get exceptionsLegendVacation => 'Vacation';

  @override
  String get exceptionsLegendWorking => 'Working';

  @override
  String get exceptionsLoadError => 'Failed to load exceptions';

  @override
  String get exceptionsNoOverrides => 'No exceptions set';

  @override
  String get exceptionsOverridesSubtitle => 'Dates with custom availability';

  @override
  String get exceptionsOverridesTitle => 'Overrides';

  @override
  String get exceptionsReasonLabel => 'Reason (optional)';

  @override
  String get exceptionsSelectDate => 'Select a date';

  @override
  String get exceptionsSetVacation => 'Set Vacation';

  @override
  String get exceptionsStartDate => 'Start Date';

  @override
  String get exceptionsTimeError => 'End time must be after start time';

  @override
  String get exceptionsTitle => 'Availability Exceptions';

  @override
  String get exceptionsUnavailableChip => 'Unavailable';

  @override
  String get exceptionsUnavailableLabel => 'Mark as unavailable';

  @override
  String get exceptionsUpdateVacation => 'Update Vacation';

  @override
  String get exceptionsVacationActive => 'Vacation is currently active';

  @override
  String exceptionsVacationScheduled(Object value1) {
    return 'Vacation scheduled from $value1';
  }

  @override
  String get exceptionsVacationSubtitle => 'Set a date range when you are away';

  @override
  String get exceptionsVacationTitle => 'Vacation Mode';

  @override
  String get experienceLabel => 'Experience';

  @override
  String experienceYearsLabel(Object value1) {
    return '$value1 years experience';
  }

  @override
  String get exploreExpertsLabel => 'Explore Experts';

  @override
  String get facebookSignInLabel => 'Continue with Facebook';

  @override
  String get faqBookingPendingA =>
      'It may take a little time for the professional to respond. You will be notified once they accept or decline.';

  @override
  String get faqBookingPendingQ => 'Why is my booking still pending?';

  @override
  String get faqChangeAvailabilityA =>
      'Go to your Availability settings from your profile to update your working hours.';

  @override
  String get faqChangeAvailabilityQ => 'How do I change my availability?';

  @override
  String get faqGetVerifiedA =>
      'Complete your profile and submit the required documents from your profile settings to request verification.';

  @override
  String get faqGetVerifiedQ => 'How do I get verified?';

  @override
  String get faqHowToBookA =>
      'Search for a professional, view their profile, and tap Book Now to select a date and time.';

  @override
  String get faqHowToBookQ => 'How do I book a professional?';

  @override
  String get faqHowToCancelA =>
      'Open the booking from My Bookings and tap Cancel. Cancellations made in time are free.';

  @override
  String get faqHowToCancelQ => 'How do I cancel a booking?';

  @override
  String get faqImproveProfileA =>
      'Add a profile photo, portfolio samples, and certificates to build trust with customers.';

  @override
  String get faqImproveProfileQ => 'How can I improve my profile?';

  @override
  String get faqPaymentSecureA =>
      'Yes, all payments are processed securely and your details are never shared.';

  @override
  String get faqPaymentSecureQ => 'Is my payment information secure?';

  @override
  String get faqRefundsA =>
      'Refunds are processed automatically for eligible cancellations within a few business days.';

  @override
  String get faqRefundsQ => 'How do refunds work?';

  @override
  String get faqSectionLabel => 'FAQ';

  @override
  String get faqSectionTitle => 'Frequently Asked Questions';

  @override
  String get faqWithdrawEarningsA =>
      'Go to your Wallet and tap Withdraw to transfer your earnings to your bank account.';

  @override
  String get faqWithdrawEarningsQ => 'How do I withdraw my earnings?';

  @override
  String get fastResponseLabel => 'Fast Response';

  @override
  String get flexibleTimingLabel => 'Flexible Timing';

  @override
  String get freeToCancelLabel => 'Free to Cancel';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get galleryLabel => 'Gallery';

  @override
  String get galleryOptionLabel => 'Gallery';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get galleryUploadError => 'Failed to upload photo';

  @override
  String get galleryUploadSuccess => 'Photo uploaded successfully';

  @override
  String get goBackCta => 'Go Back';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodAfternoonComma => 'Good afternoon,';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get goodEveningComma => 'Good evening,';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodMorningComma => 'Good morning,';

  @override
  String get goodToKnowLabel => 'Good to Know';

  @override
  String get googleSignInLabel => 'Continue with Google';

  @override
  String get helpActionLabel => 'Help & Support';

  @override
  String get helpActionSubtitle => 'Get help or contact us';

  @override
  String get helpSupportLabel => 'Help & Support';

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get helpTitle => 'Help';

  @override
  String get homeDefaultPlanFree => 'Free';

  @override
  String get homeDefaultProfessionalName => 'Professional';

  @override
  String get homeFilterAll => 'All';

  @override
  String get homeFilterAvailableNow => 'Available Now';

  @override
  String get homeFilterFastResponse => 'Fast Response';

  @override
  String get homeFilterHighestPrice => 'Highest Price';

  @override
  String get homeFilterLowestPrice => 'Lowest Price';

  @override
  String get homeFilterMostBooked => 'Most Booked';

  @override
  String get homeFilterMostExperienced => 'Most Experienced';

  @override
  String get homeFilterMostReviews => 'Most Reviews';

  @override
  String get homeFilterRating1Plus => '1+ Stars';

  @override
  String get homeFilterRating2Plus => '2+ Stars';

  @override
  String get homeFilterRating3Plus => '3+ Stars';

  @override
  String get homeFilterRating4Plus => '4+ Stars';

  @override
  String get homeFilterRating5Plus => '5 Stars';

  @override
  String get homeFilterThisMonth => 'This Month';

  @override
  String get homeFilterThisWeek => 'This Week';

  @override
  String get homeFilterToday => 'Today';

  @override
  String get homeFilterTopRated => 'Top Rated';

  @override
  String get homeFilterVerified => 'Verified';

  @override
  String get homeFilterWithin10Km => 'Within 10 km';

  @override
  String get homeFilterWithin2Km => 'Within 2 km';

  @override
  String get homeFilterWithin5Km => 'Within 5 km';

  @override
  String get homeGoBack => 'Go Back';

  @override
  String get homeNoProfessionalsFound => 'No professionals found';

  @override
  String get homeNoProfessionalsFoundHint =>
      'Try adjusting your filters or search a different area';

  @override
  String get hour => 'hour';

  @override
  String get hourlyRateLabel => 'Hourly Rate';

  @override
  String hoursDecimalLabel(Object value1) {
    return '${value1}h';
  }

  @override
  String hoursLabel(Object value1) {
    return '${value1}h';
  }

  @override
  String hoursMinutesShort(Object value1, Object value2) {
    return '${value1}h ${value2}m';
  }

  @override
  String hoursShort(Object value1) {
    return '${value1}h';
  }

  @override
  String get idVerifiedLabel => 'ID Verified';

  @override
  String get imagePickError => 'Failed to select image';

  @override
  String get instantLabel => 'Instant';

  @override
  String get issueDateLabelOptional => 'Issue Date (optional)';

  @override
  String get issuingOrganizationHint => 'e.g. National Skills Board';

  @override
  String get issuingOrganizationLabel => 'Issuing Organization';

  @override
  String get jobsDoneLabel => 'Jobs Done';

  @override
  String get languagesLabel => 'Languages';

  @override
  String lastUpdatedLabel(Object value1) {
    return 'Last updated: $value1';
  }

  @override
  String get laterCta => 'Later';

  @override
  String get loadBookingsError => 'Failed to load bookings';

  @override
  String get loadCertificatesError => 'Failed to load certificates';

  @override
  String get loadGalleryError => 'Failed to load gallery';

  @override
  String get loadPortfolioError => 'Failed to load portfolio';

  @override
  String get loadSettingsError => 'Failed to load settings';

  @override
  String get loadWalletError => 'Failed to load wallet';

  @override
  String get loadingAnalyticsText => 'Loading analytics...';

  @override
  String get loadingDashboard => 'Loading dashboard...';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationNotSpecified => 'Location not specified';

  @override
  String get locationTipText => 'Enable location for more accurate results';

  @override
  String get loginCta => 'Login';

  @override
  String get loginSubtitle => 'Welcome back! Please sign in to continue';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginToBookCta => 'Login to Book';

  @override
  String get logoutActionLabel => 'Logout';

  @override
  String get logoutActionSubtitle => 'Sign out of your account';

  @override
  String get logoutCta => 'Logout';

  @override
  String get logoutDialogContent => 'Are you sure you want to log out?';

  @override
  String get logoutDialogTitle => 'Logout';

  @override
  String get magazineAllCategoriesLabel => 'All';

  @override
  String magazineArticleCountPlural(Object value1) {
    return '$value1 articles';
  }

  @override
  String get magazineArticleCountSingle => '1 article';

  @override
  String get magazineClearSearchCta => 'Clear Search';

  @override
  String get magazineEmptyMessage => 'No articles available right now';

  @override
  String get magazineEmptySearchMessage => 'Try a different search term';

  @override
  String get magazineEmptySearchTitle => 'No Results Found';

  @override
  String get magazineEmptyTitle => 'No Articles Yet';

  @override
  String get magazineErrorMessage =>
      'Something went wrong while loading the magazine';

  @override
  String get magazineErrorTitle => 'Failed to Load';

  @override
  String get magazineLoadError => 'Failed to load magazine';

  @override
  String get magazineLoadingText => 'Loading articles...';

  @override
  String get magazineSearchHint => 'Search articles';

  @override
  String get magazineSearchResultsLabel => 'Search Results';

  @override
  String get magazineSubtitle => 'Tips and stories for professionals';

  @override
  String get magazineTitle => 'Magazine';

  @override
  String get manageCta => 'Manage';

  @override
  String get manageLabel => 'Manage';

  @override
  String get manualDescription => 'Review and accept bookings yourself';

  @override
  String get manualInfoFooter => 'You can change this anytime in settings';

  @override
  String get manualInfoTitle => 'Manual Approval';

  @override
  String get manualLabel => 'Manual';

  @override
  String get markCompletedCta => 'Mark as Completed';

  @override
  String get markCompletedCtaShort => 'Complete';

  @override
  String get maxAdvanceSubtitle => 'How far in advance customers can book';

  @override
  String get maxAdvanceTitle => 'Max Advance Booking';

  @override
  String get memberSinceLabel => 'Member Since';

  @override
  String get messagesEmptySubtitle =>
      'Start a conversation with a professional or customer';

  @override
  String get messagesEmptyTitle => 'No Messages Yet';

  @override
  String get messagesLoadError => 'Failed to load messages';

  @override
  String get messagesLoadingText => 'Loading messages...';

  @override
  String get messagesTitle => 'Messages';

  @override
  String minAmountError(Object value1) {
    return 'Minimum withdrawal amount is Rs $value1';
  }

  @override
  String get minNoticeSubtitle => 'Minimum time before a booking can start';

  @override
  String get minNoticeTitle => 'Minimum Notice';

  @override
  String minWithdrawalLabel(Object value1) {
    return 'Minimum withdrawal: Rs $value1';
  }

  @override
  String get minute => 'minute';

  @override
  String minutesLabel(Object value1) {
    return '${value1}m';
  }

  @override
  String minutesShort(Object value1) {
    return '${value1}m';
  }

  @override
  String get minutesZero => '0 minutes';

  @override
  String get myPortfolioLabel => 'My Portfolio';

  @override
  String get myPortfolioTitle => 'My Portfolio';

  @override
  String get myReviewsEmptySubtitle => 'Reviews you write will appear here';

  @override
  String get myReviewsEmptyTitle => 'No Reviews Yet';

  @override
  String get myReviewsTitle => 'My Reviews';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navMagazine => 'Magazine';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get nearbyLabel => 'Nearby';

  @override
  String get needMoreHelpLabel => 'Need more help?';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get newPhotoSelectedHint => 'New photo selected';

  @override
  String get nextCta => 'Next';

  @override
  String get noBookingsAccepted => 'No accepted bookings';

  @override
  String get noBookingsAll => 'No bookings yet';

  @override
  String get noBookingsCancelled => 'No cancelled bookings';

  @override
  String get noBookingsCompleted => 'No completed bookings';

  @override
  String get noBookingsDefault => 'No bookings found';

  @override
  String get noBookingsPending => 'No pending bookings';

  @override
  String get noBookingsRescheduled => 'No rescheduled bookings';

  @override
  String get noBookingsToday => 'No bookings today';

  @override
  String get noBookingsYet => 'No bookings yet';

  @override
  String get noClientsFound => 'No clients found';

  @override
  String get noLanguagesAdded => 'No languages added yet';

  @override
  String get noMessagesPlaceholder => 'No messages yet';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noPaymentsSubtitle => 'Your payment history will appear here';

  @override
  String get noPaymentsTitle => 'No Payments Yet';

  @override
  String get noPortfolioSubtitle => 'Portfolio items will appear here';

  @override
  String get noPortfolioTitle => 'No Portfolio Items';

  @override
  String get noReviewsSubtitle =>
      'Reviews will appear here once customers rate you';

  @override
  String get noReviewsTitle => 'No Reviews Yet';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get noServicesSubtitle =>
      'Add services you offer to attract customers';

  @override
  String get noServicesTitle => 'No Services Added';

  @override
  String get noSkillsAdded => 'No skills added yet';

  @override
  String get noTransactionsLabel => 'No transactions yet';

  @override
  String get noWorkingHoursMessage => 'No working hours set for this day';

  @override
  String get notAcceptingBookingsLabel => 'Not Accepting Bookings';

  @override
  String get notAvailableLabel => 'Not Available';

  @override
  String get notAvailableSubtitle => 'Not accepting bookings right now';

  @override
  String get notSetPlaceholder => 'Not set';

  @override
  String get notSpecifiedLabel => 'Not specified';

  @override
  String get notVerifiedLabel => 'Not Verified';

  @override
  String get notesHintText => 'Add any notes here';

  @override
  String get notesInfoText => 'Notes are only visible to you';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesTipText => 'Add any special requests or details';

  @override
  String get notificationsActionLabel => 'Notifications';

  @override
  String get notificationsActionSubtitle => 'Manage notification preferences';

  @override
  String notificationsDaysAgo(Object value1) {
    return '${value1}d ago';
  }

  @override
  String get notificationsEmptyMessage => 'You\'re all caught up!';

  @override
  String get notificationsEmptyTitle => 'No Notifications';

  @override
  String get notificationsErrorTitle => 'Couldn\'t load notifications';

  @override
  String notificationsHoursAgo(Object value1) {
    return '${value1}h ago';
  }

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String get notificationsLoadError => 'Failed to load notifications';

  @override
  String get notificationsLoadingText => 'Loading notifications...';

  @override
  String get notificationsMarkAllReadCta => 'Mark all as read';

  @override
  String get notificationsMarkAllReadSuccess =>
      'All notifications marked as read';

  @override
  String notificationsMinutesAgo(Object value1) {
    return '${value1}m ago';
  }

  @override
  String get notificationsSectionLabel => 'Notifications';

  @override
  String get notificationsSectionThisMonth => 'This Month';

  @override
  String get notificationsSectionThisWeek => 'This Week';

  @override
  String get notificationsSectionToday => 'Today';

  @override
  String get notificationsSectionYesterday => 'Yesterday';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notifyCustomerMessage(Object value1, Object value2) {
    return 'Notify the customer about the new time: $value1 at $value2?';
  }

  @override
  String get notifyCustomerTitle => 'Notify Customer';

  @override
  String get offlineLabel => 'Offline';

  @override
  String get okCta => 'OK';

  @override
  String get onlineLabel => 'Online';

  @override
  String get openChatCta => 'Open Chat';

  @override
  String get openChatCtaShort => 'Chat';

  @override
  String get openChatError => 'Failed to open chat';

  @override
  String get orContinueWithLabel => 'Or continue with';

  @override
  String get overrideRemoved => 'Exception removed';

  @override
  String overrideSaved(Object value1) {
    return 'Exception saved for $value1';
  }

  @override
  String get passwordChangeError => 'Failed to change password';

  @override
  String get passwordChangeSuccess => 'Password changed successfully';

  @override
  String get passwordHelperText => 'Must be at least 8 characters';

  @override
  String get passwordMinLengthError => 'Password must be at least 8 characters';

  @override
  String get passwordMismatchError => 'Passwords do not match';

  @override
  String get passwordRequiredError => 'Password is required';

  @override
  String get paymentHistoryLabel => 'Payment History';

  @override
  String get paymentHistorySubtitle => 'View all your past payments';

  @override
  String get paymentStatusCompleted => 'Completed';

  @override
  String get paymentStatusFailed => 'Failed';

  @override
  String get paymentStatusPending => 'Pending';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get paymentsActionLabel => 'Payments';

  @override
  String get paymentsActionSubtitle => 'View your payment history';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get perHourLabel => '/hr';

  @override
  String get performanceLabel => 'Performance';

  @override
  String get performanceScoreInfo =>
      'Based on your ratings, response time, and completed bookings';

  @override
  String get performanceScoreLabel => 'Performance Score';

  @override
  String performanceScoreOutOf(Object value1) {
    return '$value1 out of 100';
  }

  @override
  String get personalInfoLabel => 'Personal Information';

  @override
  String get phoneLabel => 'Phone';

  @override
  String photoLimitReached(Object value1) {
    return 'You can add up to $value1 photos';
  }

  @override
  String get photoPickError => 'Failed to select photo';

  @override
  String get photosOptionalLabel => 'Photos (optional)';

  @override
  String get planStatLabel => 'Plan';

  @override
  String get planUpgradeSubtitle =>
      'Unlock more features and grow your business';

  @override
  String planUpgradeTitle(Object value1) {
    return 'Upgrade from $value1';
  }

  @override
  String get portfolioInfoNote =>
      'Showcase your best work to attract more customers';

  @override
  String get portfolioLabel => 'Portfolio';

  @override
  String get postReplyCta => 'Post Reply';

  @override
  String get preferencesGroupLabel => 'Preferences';

  @override
  String get preferencesSectionLabel => 'Preferences';

  @override
  String get premiumActiveSubtitle => 'You have access to all premium features';

  @override
  String get premiumMemberLabel => 'Premium Member';

  @override
  String get premiumUpgradeSubtitle => 'Get unlimited AI searches and more';

  @override
  String get proBadgeLabel => 'PRO';

  @override
  String get professionEmptyMessage => 'No professions found';

  @override
  String get professionHint => 'Select profession';

  @override
  String get professionLabel => 'Profession';

  @override
  String get professionRequiredError => 'Please select a profession';

  @override
  String get professionSearchHint => 'Search profession';

  @override
  String get professionalAccountDescription =>
      'Offer your services to customers';

  @override
  String get professionalDefaultName => 'Professional';

  @override
  String get professionalDetailLoadError =>
      'Failed to load professional details';

  @override
  String get professionalDetailsLabel => 'Professional Details';

  @override
  String get professionalLabel => 'Professional';

  @override
  String get professionalLocationLabel => 'Professional\'s Location';

  @override
  String get professionalLocationOption => 'Professional\'s Location';

  @override
  String get professionalReviewsLabel => 'Reviews';

  @override
  String get professionalReviewsSubtitle => 'What customers are saying';

  @override
  String get profileCompletionHint =>
      'Complete your profile to attract more customers';

  @override
  String get profileCompletionLabel => 'Profile Completion';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileLabel => 'Profile';

  @override
  String get profileLoadError => 'Failed to load profile';

  @override
  String get profileLoadingText => 'Loading profile...';

  @override
  String get profileNotAvailable => 'Profile not available';

  @override
  String get profileOff => 'Off';

  @override
  String get profileOn => 'On';

  @override
  String get profileReviewsLabel => 'Reviews';

  @override
  String get profileSavedLabel => 'Saved';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUpdateError => 'Failed to update profile';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String get profileViewsLabel => 'Profile Views';

  @override
  String get profileViewsSubtext => 'People who viewed your profile';

  @override
  String get profileWalletLabel => 'Wallet';

  @override
  String get pushNotificationsLabel => 'Push Notifications';

  @override
  String get quickActionsLabel => 'Quick Actions';

  @override
  String get quickAddLabel => 'Quick Add';

  @override
  String get rateLabel => 'Rate';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get ratingRequiredError => 'Please select a rating';

  @override
  String get recentBookingsLabel => 'Recent Bookings';

  @override
  String get recentMessagesLabel => 'Recent Messages';

  @override
  String get recentReviewsLabel => 'Recent Reviews';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get registerCategoryRequired => 'Please select a category';

  @override
  String get registerCta => 'Register';

  @override
  String get registerServerError => 'Registration failed. Please try again.';

  @override
  String get registerSubtitle => 'Sign up to get started';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get rejectCta => 'Reject';

  @override
  String get relatedProfessionalsLabel => 'You May Also Like';

  @override
  String get removeCta => 'Remove';

  @override
  String get replyHint => 'Write a reply';

  @override
  String get replySubtitle => 'Your reply is public and visible to everyone';

  @override
  String get replyTitle => 'Reply to Review';

  @override
  String get reportNoteHint => 'Add any additional details';

  @override
  String get reportSubtitle => 'Help us understand what went wrong';

  @override
  String get reportTitle => 'Report an Issue';

  @override
  String get requestSentLabel => 'Request Sent';

  @override
  String requestSentSubtitle(Object value1) {
    return 'Your request has been sent to $value1';
  }

  @override
  String get requestWithdrawCta => 'Request Withdrawal';

  @override
  String get rescheduledLabel => 'Rescheduled';

  @override
  String get resendEmailCta => 'Resend Email';

  @override
  String get resetLinkError => 'Failed to send reset link';

  @override
  String resetLinkSent(Object value1) {
    return 'Password reset link sent to $value1';
  }

  @override
  String get resetPassSubtitle =>
      'Enter your email and we\'ll send you a reset link';

  @override
  String get resetPassTitle => 'Reset Password';

  @override
  String resetPasswordDescription(Object value1) {
    return 'We\'ll send a password reset link to $value1';
  }

  @override
  String get resetPasswordLabel => 'Reset Password';

  @override
  String get responseLabel => 'Response';

  @override
  String get responseRateLabel => 'Response Rate';

  @override
  String get responseRateSubtext => 'How often you respond to messages';

  @override
  String get responseTimeLabel => 'Response Time';

  @override
  String get retryCta => 'Retry';

  @override
  String get reviewBookingLabel => 'Review Booking';

  @override
  String get reviewSubmitErrorDefault => 'Failed to submit review';

  @override
  String reviewSubmittedSuccessMessage(Object value1) {
    return 'Your review for $value1 has been submitted';
  }

  @override
  String get reviewSubmittedSuccessTitle => 'Review Submitted';

  @override
  String get reviewUpdateErrorDefault => 'Failed to update review';

  @override
  String reviewUpdatedSuccessMessage(Object value1) {
    return 'Your review for $value1 has been updated';
  }

  @override
  String get reviewUpdatedSuccessTitle => 'Review Updated';

  @override
  String get reviewsActionLabel => 'Reviews';

  @override
  String get reviewsActionSubtitle => 'Reviews you have written';

  @override
  String reviewsCountLabel(Object value1) {
    return '$value1 reviews';
  }

  @override
  String get reviewsLabel => 'Reviews';

  @override
  String get saveCertificateCta => 'Save Certificate';

  @override
  String get saveChangesCta => 'Save Changes';

  @override
  String get saveCta => 'Save';

  @override
  String get saveScheduleCta => 'Save Schedule';

  @override
  String get saveSettingsError => 'Failed to save settings';

  @override
  String get saveSettingsSuccess => 'Settings saved successfully';

  @override
  String get savedProfessionalsActionLabel => 'Saved Professionals';

  @override
  String get savedProfessionalsActionSubtitle => 'Professionals you have saved';

  @override
  String get savedProfessionalsEmptySubtitle =>
      'Professionals you save will appear here';

  @override
  String get savedProfessionalsEmptyTitle => 'No Saved Professionals';

  @override
  String get savedProfessionalsTitle => 'Saved Professionals';

  @override
  String get savedStatLabel => 'Saved';

  @override
  String get searchAiPremiumActive => 'AI Search Premium Active';

  @override
  String searchAiRemainingToday(Object value1) {
    return '$value1 AI searches remaining today';
  }

  @override
  String get searchBookingsHint => 'Search bookings';

  @override
  String get searchCategories => 'Categories';

  @override
  String get searchPopular => 'Popular';

  @override
  String get searchPopularCleaners => 'Cleaners';

  @override
  String get searchPopularDoctors => 'Doctors';

  @override
  String get searchPopularElectricians => 'Electricians';

  @override
  String get searchPopularEngineers => 'Engineers';

  @override
  String get searchPopularLawyers => 'Lawyers';

  @override
  String get searchPopularPlumbers => 'Plumbers';

  @override
  String get searchProfessionals => 'Professionals';

  @override
  String get searchProfessions => 'Professions';

  @override
  String get searchRecent => 'Recent';

  @override
  String searchResultsLabel(Object value1, Object value2) {
    return '$value1 results for \"$value2\"';
  }

  @override
  String get searchingLabel => 'Searching...';

  @override
  String get security => 'Security';

  @override
  String get securityActionLabel => 'Security';

  @override
  String get securityActionSubtitle => 'Password and account security';

  @override
  String get securityBannerSubtitle => 'Keep your account safe and secure';

  @override
  String get securityBannerTitle => 'Account Security';

  @override
  String get securityFooterText =>
      'If you didn\'t request this change, please contact support immediately';

  @override
  String get securityTitle => 'Security';

  @override
  String get seeAllLabel => 'See All';

  @override
  String get selectedLabel => 'Selected';

  @override
  String get sendResetLinkCta => 'Send Reset Link';

  @override
  String get serviceLabel => 'Service';

  @override
  String get serviceProfessionalLabel => 'Service Professional';

  @override
  String get settingsActionLabel => 'Settings';

  @override
  String get settingsActionSubtitle => 'App preferences';

  @override
  String get shareExperienceLabel => 'Share your experience';

  @override
  String get signInInsteadLabel => 'Sign in instead';

  @override
  String get skillsLabel => 'Skills';

  @override
  String get skillsPricingLabel => 'Skills & Pricing';

  @override
  String get slotDurationSubtitle => 'Default length of each booking slot';

  @override
  String get slotDurationTitle => 'Slot Duration';

  @override
  String get startConversationError => 'Failed to start conversation';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get startingFromLabel => 'Starting from';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get submitReportCta => 'Submit Report';

  @override
  String get submitReviewCta => 'Submit Review';

  @override
  String get subscriptionActionLabel => 'Subscription';

  @override
  String subscriptionActiveStatus(Object value1) {
    return '$value1 plan active';
  }

  @override
  String get subscriptionUpgradeLabel => 'Upgrade Plan';

  @override
  String get subscriptionUpgradeStatus => 'Upgrade to premium';

  @override
  String get suggestTimeCta => 'Suggest a Different Time';

  @override
  String get suggestTimeCtaShort => 'Suggest Time';

  @override
  String get suggestTimeDescription =>
      'Propose a new date and time for this booking';

  @override
  String get suggestTimeLabel => 'Suggest a Time';

  @override
  String get suggestTimeSuccess => 'New time suggested to customer';

  @override
  String get suggestedTimeLabel => 'Suggested Time';

  @override
  String get supportBannerSubtitle => 'We\'re here to help, 24/7';

  @override
  String get supportBannerTitle => 'Need Help?';

  @override
  String get supportTeamReplyLabel => 'Support Team';

  @override
  String get tapStarToRateLabel => 'Tap a star to rate';

  @override
  String get thisMonthLabel => 'This Month';

  @override
  String get timeLabel => 'Time';

  @override
  String get timeSlotsLabel => 'Time Slots';

  @override
  String get timeTipText => 'Choose a time that works best for you';

  @override
  String get titleHint => 'Enter a title';

  @override
  String get titleLabelRequired => 'Title';

  @override
  String get titleValidationError => 'Please enter a title';

  @override
  String get todayLabel => 'Today';

  @override
  String get todaysEarningsLabel => 'Today\'s Earnings';

  @override
  String get todaysScheduleLabel => 'Today\'s Schedule';

  @override
  String get topRatedLabel => 'Top Rated';

  @override
  String get totalBookingsLabel => 'Total Bookings';

  @override
  String get totalEarnedLabel => 'Total Earned';

  @override
  String get totalSpentLabel => 'Total Spent';

  @override
  String transactionCountLabel(Object value1) {
    return '$value1 transactions';
  }

  @override
  String get transactionHistoryTitle => 'Transaction History';

  @override
  String get tryAgainCta => 'Try Again';

  @override
  String get twitterSignInLabel => 'Continue with Twitter';

  @override
  String get typicallyRepliesLabel => 'Typically replies';

  @override
  String get unavailableLabel => 'Unavailable';

  @override
  String get unknownRoleError => 'Unknown account type';

  @override
  String get updateBookingError => 'Failed to update booking';

  @override
  String get updateCta => 'Update';

  @override
  String get updateReviewCta => 'Update Review';

  @override
  String get upgradeCta => 'Upgrade';

  @override
  String get uploadError => 'Upload failed';

  @override
  String get uploadSuccess => 'Uploaded successfully';

  @override
  String get userLabel => 'User';

  @override
  String get vacationCleared => 'Vacation cleared';

  @override
  String get vacationDateRequired => 'Please select a vacation date range';

  @override
  String get vacationSet => 'Vacation set successfully';

  @override
  String get validAmountError => 'Please enter a valid amount';

  @override
  String get verificationAddPortfolio =>
      'Add portfolio items to help get verified';

  @override
  String get verificationLabel => 'Verification';

  @override
  String get verificationPending => 'Verification pending';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get verifiedProfessionalLabel => 'Professional';

  @override
  String verifiedStatusLabel(Object value1) {
    return 'Verified $value1';
  }

  @override
  String get viewMyBookingsCta => 'View My Bookings';

  @override
  String get viewProfileCta => 'View Profile';

  @override
  String get viewWalletLabel => 'View Wallet';

  @override
  String get visitorsLabel => 'Visitors';

  @override
  String get visitorsSubtext => 'People who viewed your profile';

  @override
  String get walletActionLabel => 'Wallet';

  @override
  String get walletActionSubtitle => 'View balance and transactions';

  @override
  String get walletEarningsLabel => 'Earnings';

  @override
  String get walletLabel => 'Wallet';

  @override
  String get walletTitle => 'Wallet';

  @override
  String get whatHappensNextLabel => 'What happens next?';

  @override
  String get whyBookHereLabel => 'Why book with us?';

  @override
  String get withdrawCta => 'Withdraw';

  @override
  String get withdrawErrorDefault => 'Withdrawal failed. Please try again.';

  @override
  String get withdrawSuccess => 'Withdrawal requested successfully';

  @override
  String get withdrawTitle => 'Withdraw Funds';

  @override
  String get withdrawnLabel => 'Withdrawn';

  @override
  String get workingHoursLabel => 'Working Hours';

  @override
  String get writeReviewTitle => 'Write a Review';

  @override
  String yearsLabel(Object value1) {
    return '$value1 years';
  }

  @override
  String get yesCancelCta => 'Yes, Cancel';

  @override
  String get youAreNotifiedLabel => 'You\'ll be notified';

  @override
  String get youAreNotifiedSubtitle =>
      'We\'ll notify you as soon as there\'s a response';

  @override
  String get yourAccountEmailPlaceholder => 'your account email';

  @override
  String get tsErrForbidden =>
      'You do not have permission to perform this action.';

  @override
  String get tsErrNetwork =>
      'Network problem. Check your connection and try again.';

  @override
  String get tsErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get tsRetry => 'Retry';

  @override
  String get tsCopy => 'Copy';

  @override
  String get tsCopied => 'Copied to clipboard';

  @override
  String get tsOpenLink => 'Open link';

  @override
  String get tsLinkOpenFailed => 'This link could not be opened.';

  @override
  String get tsCancel => 'Cancel';

  @override
  String get tsClose => 'Close';

  @override
  String get tsRefresh => 'Refresh';

  @override
  String get tsAll => 'All';

  @override
  String get tsCatSpam => 'Spam';

  @override
  String get tsCatHarassment => 'Harassment';

  @override
  String get tsCatFraud => 'Fraud or scam';

  @override
  String get tsCatFakeProfile => 'Fake profile';

  @override
  String get tsCatInappropriate => 'Inappropriate content';

  @override
  String get tsCatPaymentFraud => 'Payment fraud';

  @override
  String get tsCatOffPlatform => 'Off-platform payment';

  @override
  String get tsCatThreats => 'Threats or safety concern';

  @override
  String get tsCatDiscrimination => 'Discrimination';

  @override
  String get tsCatMisconduct => 'Service misconduct';

  @override
  String get tsCatOther => 'Other';

  @override
  String get tsStatusPending => 'Pending';

  @override
  String get tsStatusReviewed => 'Reviewed';

  @override
  String get tsStatusActionTaken => 'Action taken';

  @override
  String get tsStatusDismissed => 'Dismissed';

  @override
  String get tsSevLow => 'Low';

  @override
  String get tsSevMedium => 'Medium';

  @override
  String get tsSevHigh => 'High';

  @override
  String get tsSevCritical => 'Critical';

  @override
  String get tsRoleCustomer => 'Customer';

  @override
  String get tsRoleProfessional => 'Professional';

  @override
  String get tsRoleAdmin => 'Admin';

  @override
  String get tsActWarning => 'Warning';

  @override
  String get tsActRestrictMessaging => 'Messaging restriction';

  @override
  String get tsActRestrictBooking => 'Booking restriction';

  @override
  String get tsActSuspendTemporary => 'Temporary suspension';

  @override
  String get tsActSuspendPermanent => 'Permanent suspension';

  @override
  String get tsActWarningDesc =>
      'Records a formal warning. Does not limit the account.';

  @override
  String get tsActRestrictMessagingDesc =>
      'Marks the account as restricted from messaging.';

  @override
  String get tsActRestrictBookingDesc =>
      'Marks the account as restricted from creating bookings.';

  @override
  String get tsActSuspendTemporaryDesc =>
      'Marks the account as suspended until the date you choose.';

  @override
  String get tsActSuspendPermanentDesc =>
      'Marks the account as permanently suspended. No expiry; only an admin can reverse it.';

  @override
  String get tsStateActive => 'Active';

  @override
  String get tsStateScheduled => 'Scheduled';

  @override
  String get tsStateExpired => 'Expired';

  @override
  String get tsStateReversed => 'Reversed';

  @override
  String get tsAppealPending => 'Pending';

  @override
  String get tsAppealApproved => 'Approved';

  @override
  String get tsAppealRejected => 'Rejected';

  @override
  String get tsReportsTitle => 'Reported Users';

  @override
  String tsPendingReview(String count) {
    return '$count pending review';
  }

  @override
  String get tsSearchReportsHint => 'Search by user, reporter, category or ID';

  @override
  String get tsFilterSeverity => 'Severity';

  @override
  String get tsFilterCategory => 'Category';

  @override
  String get tsFilterDate => 'Date';

  @override
  String get tsDateAny => 'Any time';

  @override
  String get tsDateToday => 'Today';

  @override
  String get tsDate7 => 'Last 7 days';

  @override
  String get tsDate30 => 'Last 30 days';

  @override
  String get tsDateCustom => 'Custom range';

  @override
  String get tsSortNewest => 'Newest first';

  @override
  String get tsSortSeverity => 'Highest severity first';

  @override
  String get tsClearFilters => 'Clear filters';

  @override
  String get tsNoReports => 'No reports yet';

  @override
  String get tsNoReportsHint => 'Reports submitted by users will appear here.';

  @override
  String get tsNoMatches => 'No reports match your filters';

  @override
  String get tsNoMatchesHint => 'Try changing or clearing the filters.';

  @override
  String get tsSelectReport => 'Select a report';

  @override
  String get tsSelectReportHint =>
      'Choose a report from the list to review it and take action.';

  @override
  String get tsIndBooking => 'Booking';

  @override
  String get tsIndMessage => 'Message';

  @override
  String get tsIndEvidence => 'Evidence';

  @override
  String tsReportedBy(String name) {
    return 'Reported by $name';
  }

  @override
  String get tsAccountBlocked => 'Account blocked';

  @override
  String tsReportNumber(String id) {
    return 'Report #$id';
  }

  @override
  String tsSubmittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String get tsTakeAction => 'Take action';

  @override
  String get tsMarkReviewed => 'Mark reviewed';

  @override
  String get tsDismiss => 'Dismiss';

  @override
  String get tsSecDescription => 'Report description';

  @override
  String get tsNoDescription => 'No description was provided.';

  @override
  String get tsSecEvidence => 'Evidence and context';

  @override
  String get tsEvidenceLabel => 'EVIDENCE / REFERENCE';

  @override
  String get tsNoEvidence => 'No evidence link provided.';

  @override
  String get tsBookingLabel => 'RELATED BOOKING';

  @override
  String tsBookingNumber(String id) {
    return 'Booking #$id';
  }

  @override
  String get tsMessageLabel => 'RELATED MESSAGE';

  @override
  String tsMessageNumber(String id) {
    return 'Message #$id';
  }

  @override
  String get tsMessageDeleted =>
      'This message was deleted. Its content is not available.';

  @override
  String tsMessageAttachments(String count) {
    return 'Attachments: $count';
  }

  @override
  String get tsNoRelated => 'None linked to this report.';

  @override
  String get tsFieldWhen => 'When';

  @override
  String get tsFieldParties => 'Parties';

  @override
  String get tsFieldSender => 'Sender';

  @override
  String tsBookingWith(String customer, String professional) {
    return '$customer with $professional';
  }

  @override
  String get tsSecPeople => 'People';

  @override
  String get tsReportedUser => 'REPORTED USER';

  @override
  String get tsReporterLabel => 'REPORTER';

  @override
  String get tsReporterAdminOnly =>
      'Visible to admins only. Never shown to the reported user.';

  @override
  String get tsAccountBlockedNote =>
      'This account is currently blocked (see the Blocked tab). Blocking is separate from moderation actions.';

  @override
  String get tsSecActive => 'Active restrictions and suspension';

  @override
  String get tsNoActive => 'No active restrictions or suspension.';

  @override
  String get tsSecTimeline => 'Report history';

  @override
  String get tsSecHistory => 'Moderation history';

  @override
  String get tsSecOtherReports => 'Other reports about this user';

  @override
  String get tsHistoryLoadError => 'Could not load moderation history.';

  @override
  String get tsHistoryEmpty => 'No moderation actions on record for this user.';

  @override
  String get tsTlSubmitted => 'Report submitted';

  @override
  String tsTlReviewed(String status, String admin) {
    return 'Marked $status by $admin';
  }

  @override
  String tsTlInternalNote(String note) {
    return 'Internal note: $note';
  }

  @override
  String tsTlActionApplied(String action, String admin) {
    return '$action applied by $admin';
  }

  @override
  String tsTlActionReversed(String action, String admin) {
    return '$action reversed by $admin';
  }

  @override
  String get tsThisReport => 'This report';

  @override
  String tsHistPerformedBy(String admin, String date) {
    return 'By $admin on $date';
  }

  @override
  String tsStartsOn(String date) {
    return 'Starts $date';
  }

  @override
  String tsExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get tsNoExpiryPermanent => 'Permanent, no expiry';

  @override
  String get tsNoExpiryOpen => 'No end date, active until lifted';

  @override
  String get tsReasonShownToUser => 'REASON (SHOWN TO THE USER)';

  @override
  String get tsInternalNoteLabel => 'Internal note (admin only)';

  @override
  String tsHistReversedBy(String admin, String date) {
    return 'Reversed by $admin on $date';
  }

  @override
  String get tsReverse => 'Reverse';

  @override
  String get tsAdminUnknown => 'Unknown admin';

  @override
  String get tsReviewTitle => 'Mark report as reviewed';

  @override
  String get tsReviewMessage =>
      'Confirm that you have reviewed this report. You can add an internal note.';

  @override
  String get tsReviewConfirm => 'Mark reviewed';

  @override
  String get tsDismissTitle => 'Dismiss report';

  @override
  String get tsDismissMessage =>
      'Dismiss this report if it does not break the rules. No action is taken against the reported user.';

  @override
  String get tsDismissConfirm => 'Dismiss report';

  @override
  String get tsResolveReporterNote =>
      'The reporter receives a generic outcome notification. The reported user is not notified.';

  @override
  String get tsReportUpdated => 'Report updated';

  @override
  String get tsTakeActionTitle => 'Take moderation action';

  @override
  String tsRegardingReport(String id) {
    return 'Regarding report #$id';
  }

  @override
  String get tsChooseAction => 'Choose an action';

  @override
  String get tsChooseActionError => 'Select an action to continue.';

  @override
  String get tsAlreadyActive => 'Already active for this user.';

  @override
  String get tsAlreadyPermanentlySuspended =>
      'This user is already permanently suspended.';

  @override
  String get tsDurationTitle => 'Duration';

  @override
  String get tsDurationUntilLifted => 'Until lifted';

  @override
  String get tsDurationPermanent => 'Permanent';

  @override
  String tsDurationDays(String n) {
    return '$n days';
  }

  @override
  String get tsDurationCustom => 'Custom date';

  @override
  String tsEndsAt(String when) {
    return 'Ends $when';
  }

  @override
  String tsUntilDate(String date) {
    return 'Until $date';
  }

  @override
  String get tsExpiryRequired => 'Choose when this ends.';

  @override
  String get tsExpiryMustBeFuture => 'The end time must be in the future.';

  @override
  String get tsReasonLabel => 'Reason';

  @override
  String get tsReasonHint => 'Explain why this action is being taken';

  @override
  String get tsReasonUserVisibleNote =>
      'Shown to the user in their notification. Do not mention the reporter or other users.';

  @override
  String tsReasonTooShort(String min) {
    return 'Please enter a reason of at least $min characters.';
  }

  @override
  String get tsInternalNoteHint => 'Optional context for other admins';

  @override
  String get tsInternalNoteNote => 'Internal only. Never shown to the user.';

  @override
  String get tsMarkReportTaken => 'Mark this report as Action taken';

  @override
  String get tsMarkReportTakenHint =>
      'The reporter receives a generic outcome notification only.';

  @override
  String get tsApplyAction => 'Apply action';

  @override
  String tsConfirmTitle(String action) {
    return 'Apply $action?';
  }

  @override
  String tsConfirmBody(String user) {
    return 'This is recorded in the moderation history of $user and the user is notified.';
  }

  @override
  String get tsConfirmPermanentAck =>
      'I understand this suspension has no expiry and can only be reversed by an admin.';

  @override
  String get tsFieldUser => 'User';

  @override
  String get tsFieldAction => 'Action';

  @override
  String get tsFieldDuration => 'Duration';

  @override
  String get tsFieldReason => 'Reason';

  @override
  String get tsActionApplied => 'Moderation action applied';

  @override
  String get tsActionAppliedReportFailed =>
      'The action was applied, but the report status could not be updated.';

  @override
  String get tsCannotActOnAdmin =>
      'Moderation actions cannot target admin accounts.';

  @override
  String get tsFieldPerformedBy => 'Performed by';

  @override
  String get tsFieldCreated => 'Created';

  @override
  String get tsFieldExpires => 'Expires';

  @override
  String get tsFieldReport => 'Report';

  @override
  String get tsFieldDecidedBy => 'Decided by';

  @override
  String get tsFieldDecidedOn => 'Decided on';

  @override
  String get tsReverseTitle => 'Reverse moderation action';

  @override
  String tsReverseMessage(String action) {
    return 'Reverse the $action? It is lifted and the record stays in the history.';
  }

  @override
  String get tsReversalReasonLabel => 'Reason for reversal';

  @override
  String get tsReversalReasonHint => 'Why is this action being lifted?';

  @override
  String get tsReverseConfirm => 'Reverse action';

  @override
  String get tsReverseAuditNote =>
      'Your reason is internal. It is recorded in the moderation history and never shown to the user.';

  @override
  String get tsReverseNotifyNote =>
      'The user is notified that this action was lifted.';

  @override
  String get tsReverseLegacyNote =>
      'This action came from the legacy ban flow. Reversing it also re-enables the account.';

  @override
  String get tsActionReversed => 'Moderation action reversed';

  @override
  String get tsAppealsTitle => 'Appeals';

  @override
  String tsPendingAppeals(String count) {
    return '$count pending appeals';
  }

  @override
  String get tsSearchAppealsHint => 'Search by user, email or appeal text';

  @override
  String get tsNoAppeals => 'No appeals here';

  @override
  String get tsNoAppealsHint =>
      'Appeals against moderation actions will appear here.';

  @override
  String get tsSelectAppeal => 'Select an appeal';

  @override
  String get tsSelectAppealHint =>
      'Choose an appeal from the list to review it.';

  @override
  String tsAppealNumber(String id) {
    return 'Appeal #$id';
  }

  @override
  String get tsSecAppealReason => 'Appeal';

  @override
  String get tsSecAppealedAction => 'Appealed action';

  @override
  String get tsSecDecision => 'Decision';

  @override
  String get tsAppealApprove => 'Approve';

  @override
  String get tsAppealReject => 'Reject';

  @override
  String get tsApproveTitle => 'Approve appeal';

  @override
  String get tsApproveMessage =>
      'Approving this appeal lifts the moderation action.';

  @override
  String get tsApproveConfirm => 'Approve appeal';

  @override
  String get tsRejectTitle => 'Reject appeal';

  @override
  String get tsRejectMessage =>
      'Rejecting keeps the moderation action in place.';

  @override
  String get tsRejectConfirm => 'Reject appeal';

  @override
  String get tsDecisionNoteLabel => 'Decision note';

  @override
  String get tsDecisionNoteHint => 'Explain your decision';

  @override
  String get tsDecisionNoteNote => 'Internal only. Never shown to the user.';

  @override
  String get tsAppealApproveNote =>
      'The action is reversed and the user is notified.';

  @override
  String get tsAppealApproveInactive =>
      'This action is no longer in effect, so approving only closes the appeal. The user is notified.';

  @override
  String get tsAppealRejectNote =>
      'The action stays in place and the user is notified of the outcome.';

  @override
  String get tsAppealApprovedSnack => 'Appeal approved';

  @override
  String get tsAppealRejectedSnack => 'Appeal rejected';

  @override
  String get tsNoDecisionNote => 'No note was recorded.';

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
}
