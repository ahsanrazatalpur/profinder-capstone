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
  String get chatReasonOther => 'Otro';
}
