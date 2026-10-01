// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navSearch => 'Rechercher';

  @override
  String get appName => 'ProFinder';

  @override
  String get appTagline =>
      'Trouvez des professionnels de confiance près de chez vous';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get sendResetLink => 'Envoyer le lien de réinitialisation';

  @override
  String get noAccount => 'Vous n\'avez pas de compte ? ';

  @override
  String get hasAccount => 'Vous avez déjà un compte ? ';

  @override
  String get selectRole => 'S\'inscrire en tant que';

  @override
  String get customer => 'Client';

  @override
  String get professional => 'Professionnel';

  @override
  String get home => 'Accueil';

  @override
  String get findProfessional => 'Trouver un professionnel';

  @override
  String get nearbyProfessionals => 'Professionnels à proximité';

  @override
  String get categories => 'Catégories';

  @override
  String get aiSearch => 'Recherche IA';

  @override
  String get searchHint => 'Rechercher un service...';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get phone => 'Numéro de téléphone';

  @override
  String get city => 'Ville';

  @override
  String get bio => 'Bio';

  @override
  String get experience => 'Années d\'expérience';

  @override
  String get hourlyRate => 'Tarif horaire (USD)';

  @override
  String get verified => 'Vérifié';

  @override
  String get notVerified => 'Non vérifié';

  @override
  String get bookings => 'Réservations';

  @override
  String get myBookings => 'Mes réservations';

  @override
  String get bookNow => 'Réserver';

  @override
  String get cancel => 'Annuler';

  @override
  String get accept => 'Accepter';

  @override
  String get reject => 'Refuser';

  @override
  String get complete => 'Terminer';

  @override
  String get pending => 'En attente';

  @override
  String get accepted => 'Accepté';

  @override
  String get rejected => 'Refusé';

  @override
  String get completed => 'Terminé';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get noNotifications => 'Aucune notification pour le moment';

  @override
  String get reviews => 'Avis';

  @override
  String get writeReview => 'Écrire un avis';

  @override
  String get rating => 'Note';

  @override
  String get comment => 'Commentaire';

  @override
  String get submitReview => 'Envoyer l\'avis';

  @override
  String get noInternet => 'Pas de connexion internet';

  @override
  String get serverError => 'Une erreur s\'est produite. Réessayez.';

  @override
  String get invalidEmail => 'Veuillez saisir un e-mail valide';

  @override
  String get invalidPassword =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get fieldRequired => 'Ce champ est requis';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get invalidLoginCredentials =>
      'E-mail ou mot de passe incorrect. Veuillez réessayer.';

  @override
  String get forgotPasswordGenericMessage =>
      'Si un compte existe avec cet e-mail, nous avons envoyé un lien de réinitialisation.';

  @override
  String get requestTimedOut =>
      'Délai d\'attente dépassé. Vérifiez votre connexion et réessayez.';

  @override
  String get save => 'Enregistrer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Supprimer';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';

  @override
  String get noData => 'Rien à afficher ici';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get ok => 'OK';

  @override
  String get selectLanguageTitle => 'Choisissez votre langue';

  @override
  String get selectLanguageSubtitle =>
      'Choisissez la langue à utiliser dans ProFinder';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get languageChangeNote =>
      'Vous pourrez changer de langue plus tard dans les paramètres.';

  @override
  String get languageUpdated => 'Langue mise à jour';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get pushNotificationsSubtitle =>
      'Mises à jour de réservation, messages et offres';

  @override
  String get emailNotifications => 'Notifications par e-mail';

  @override
  String get emailNotificationsSubtitle => 'Reçus et activité du compte';

  @override
  String get preferencesSection => 'Préférences';

  @override
  String get languageLabel => 'Langue';

  @override
  String get currencyLabel => 'Devise';

  @override
  String get darkModeLabel => 'Mode sombre';

  @override
  String get accountSection => 'Compte';

  @override
  String get supportSection => 'Assistance';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle => 'Supprimer définitivement votre compte';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountMessage =>
      'Cela doit passer par notre équipe d\'assistance pour vérification. Contactez l\'aide pour continuer.';

  @override
  String comingSoon(String feature) {
    return '$feature arrive bientôt';
  }

  @override
  String get loginWelcomeBack =>
      'Bon retour ! Veuillez vous connecter pour continuer.';

  @override
  String get emailHint => 'exemple@email.com';

  @override
  String get passwordHint => 'Entrez votre mot de passe';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get unknownRoleContactSupport =>
      'Rôle inconnu. Veuillez contacter le support.';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get joinProFinderSubtitle =>
      'Rejoignez ProFinder et connectez-vous avec des professionnels.';

  @override
  String get chooseAccountType => 'Choisissez le type de compte';

  @override
  String get customerRoleDescription =>
      'Engagez des professionnels de confiance.';

  @override
  String get professionalRoleDescription =>
      'Proposez vos services et développez votre activité.';

  @override
  String get fullNameHint => 'Entrez votre nom complet';

  @override
  String get countryLabel => 'Pays';

  @override
  String get selectCountryHint => 'Sélectionnez votre pays';

  @override
  String get searchCountriesHint => 'Rechercher des pays...';

  @override
  String get noCountriesFound => 'Aucun pays trouvé';

  @override
  String get selectCountryValidation => 'Veuillez sélectionner votre pays';

  @override
  String get selectCityHint => 'Sélectionnez votre ville';

  @override
  String get selectACountryFirst => 'Sélectionnez d\'abord un pays';

  @override
  String get searchCitiesHint => 'Rechercher des villes...';

  @override
  String get noCitiesFound => 'Aucune ville trouvée';

  @override
  String get selectCityValidation => 'Veuillez sélectionner votre ville';

  @override
  String get yourProfessionLabel => 'Votre profession';

  @override
  String get selectCategoryHint => 'Sélectionnez votre catégorie';

  @override
  String get searchProfessionsHint => 'Rechercher des professions...';

  @override
  String get noCategoriesFound => 'Aucune catégorie trouvée';

  @override
  String get selectProfessionValidation =>
      'Veuillez sélectionner votre profession';

  @override
  String get selectProfessionCategoryError =>
      'Veuillez sélectionner votre catégorie de profession.';

  @override
  String get passwordMinCharsHint => 'Min. 8 caractères';

  @override
  String get confirmPasswordHint => 'Ressaisissez votre mot de passe';

  @override
  String get capsLockOnHint => 'Verr. Maj est activé';

  @override
  String get emailAvailable => 'E-mail disponible';

  @override
  String get emailAlreadyRegistered => 'Cet e-mail est déjà enregistré.';

  @override
  String get signInInstead => 'Se connecter à la place';

  @override
  String get orContinueWith => 'ou continuer avec';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get facebookLabel => 'Facebook';

  @override
  String get twitterLabel => 'X (Twitter)';

  @override
  String get forgotPasswordInstructions =>
      'Entrez votre e-mail enregistré. Nous vous enverrons un lien de réinitialisation.';

  @override
  String get checkYourEmail => 'Vérifiez votre e-mail';

  @override
  String get checkSpamFolderHint =>
      'S\'il n\'arrive pas dans quelques minutes, vérifiez votre dossier spam ou réessayez.';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get resendEmail => 'Renvoyer l\'e-mail';

  @override
  String adminAvgRatingTotal(String value1, String value2) {
    return 'Note moy. : $value1 ★ · $value2 au total';
  }

  @override
  String adminBy(String value1) {
    return 'par $value1';
  }

  @override
  String get adminDeleteReview => 'Supprimer l\'avis';

  @override
  String get adminPermanentlyRemovesReviewProvideReasonAudit =>
      'Cela supprime définitivement l\'avis. Indiquez un motif pour le journal d\'audit.';

  @override
  String get adminFailedDeleteReview => 'Échec de la suppression de l\'avis.';

  @override
  String get adminNoReviewsFound => 'Aucun avis trouvé';

  @override
  String get adminFailedLoadReviews => 'Échec du chargement des avis';

  @override
  String get adminSearchByProfessionalReviewer =>
      'Rechercher par professionnel ou évaluateur…';

  @override
  String get adminReasonRequired => 'Motif (obligatoire)';

  @override
  String get adminPayments => 'Paiements';

  @override
  String adminRsShown(String value1) {
    return '$value1 Rs affichées';
  }

  @override
  String get adminRefund => 'Rembourser';

  @override
  String adminTxn(String value1) {
    return 'Trans. : $value1';
  }

  @override
  String get adminRefundPayment => 'Rembourser le paiement';

  @override
  String adminRefundRs(String value1, String value2) {
    return 'Rembourser $value1 Rs à $value2 ?';
  }

  @override
  String get adminPaymentRefunded => 'Paiement remboursé.';

  @override
  String get adminRefundFailed => 'Échec du remboursement.';

  @override
  String get adminNoPaymentsFound => 'Aucun paiement trouvé';

  @override
  String get adminFailedLoadPayments => 'Échec du chargement des paiements';

  @override
  String get adminSearchByNameEmailTransactionId =>
      'Rechercher par nom, e-mail ou ID de transaction…';

  @override
  String get adminBlockedUsers => 'Utilisateurs bloqués';

  @override
  String adminCurrentlyBlocked(String value1) {
    return '$value1 actuellement bloqué(s)';
  }

  @override
  String get adminUnblock => 'Débloquer';

  @override
  String get adminUnblockUser => 'Débloquer l\'utilisateur ?';

  @override
  String adminRestoreAccessTheyAbleLogAgain(String value1) {
    return 'Cela restaurera l\'accès de $value1. Il pourra se reconnecter.';
  }

  @override
  String adminHasBeenUnblocked(String value1) {
    return '$value1 a été débloqué.';
  }

  @override
  String get adminFailedUnblockUser => 'Échec du déblocage de l\'utilisateur.';

  @override
  String get adminNoBlockedUsersAllClear =>
      'Aucun utilisateur bloqué — tout est en ordre ! 🎉';

  @override
  String get adminFailedLoadBlockedUsers =>
      'Échec du chargement des utilisateurs bloqués';

  @override
  String get adminSearchByNameEmailReason =>
      'Rechercher par nom, e-mail ou motif…';

  @override
  String adminExportProfessionals(String value1) {
    return 'Exporter ($value1 professionnels)';
  }

  @override
  String get adminClose => 'Fermer';

  @override
  String get adminCopyClipboard => 'Copier dans le presse-papiers';

  @override
  String get adminProfessionals => 'Professionnels';

  @override
  String get adminRatingHighLow => 'Note (décroissant)';

  @override
  String get adminMostBookings => 'Le plus de réservations';

  @override
  String get adminNameZ => 'Nom (A-Z)';

  @override
  String get adminNewestFirst => 'Plus récent d\'abord';

  @override
  String adminSelected(String value1) {
    return '$value1 sélectionné(s)';
  }

  @override
  String get adminVerify => 'Vérifier';

  @override
  String get adminRemind => 'Rappeler';

  @override
  String get adminExport => 'Exporter';

  @override
  String get adminFailedLoadProfessionals =>
      'Échec du chargement des professionnels';

  @override
  String get adminSearchByNameEmailCategory =>
      'Rechercher par nom, e-mail, catégorie…';

  @override
  String get adminSort => 'Trier';

  @override
  String get adminRefresh => 'Actualiser';

  @override
  String get adminVerifyProfessional => 'Vérifier le professionnel ?';

  @override
  String adminVerifyProfessionals(String value1) {
    return 'Vérifier $value1 professionnels ?';
  }

  @override
  String adminGetVerifiedBadgeVisibleAllCustomers(String value1) {
    return '$value1 recevra un badge vérifié visible par tous les clients.';
  }

  @override
  String get adminAllSelectedProfessionalsGetVerifiedBadge =>
      'Tous les professionnels sélectionnés recevront un badge vérifié.';

  @override
  String get adminProfinderAdmin => 'ProFinder Admin';

  @override
  String get adminAdminPanel => 'Panneau d\'administration';

  @override
  String get adminMore => 'Plus';

  @override
  String get adminLogout2 => 'Se déconnecter ?';

  @override
  String get adminLoggedOutAdminPanel =>
      'Vous serez déconnecté du panneau d\'administration.';

  @override
  String get adminAnalytics => 'Analytique';

  @override
  String adminD(String value1) {
    return '${value1}J';
  }

  @override
  String adminRs(String value1) {
    return 'Rs $value1';
  }

  @override
  String adminLastDays(String value1) {
    return '$value1 derniers jours';
  }

  @override
  String get adminLast12Months => '12 derniers mois';

  @override
  String get adminDailyBookings => 'Réservations quotidiennes';

  @override
  String get adminMonthlyBookings12mo => 'Réservations mensuelles (12 mois)';

  @override
  String get adminTopSearches => 'Recherches les plus fréquentes';

  @override
  String get adminNoDataYet => 'Aucune donnée pour l\'instant';

  @override
  String get adminFailedLoadAnalytics => 'Échec du chargement des analyses';

  @override
  String get adminCountries => 'Pays';

  @override
  String get adminTopCities => 'Villes principales';

  @override
  String get adminTopCategories => 'Catégories principales';

  @override
  String get adminActivityLogs => 'Journaux d\'activité';

  @override
  String adminLogs(String value1) {
    return '$value1 journaux';
  }

  @override
  String adminTotal(String value1) {
    return 'Total : $value1';
  }

  @override
  String get adminAdminActionsAppearHere =>
      'Les actions d\'administration apparaîtront ici';

  @override
  String get adminFailedLoadLogs => 'Échec du chargement des journaux';

  @override
  String get adminSearchByAdminTargetUser =>
      'Rechercher par administrateur ou utilisateur cible…';

  @override
  String get adminClearAll => 'Tout effacer';

  @override
  String get adminDeleteLog => 'Supprimer ce journal ?';

  @override
  String get adminClearAllLogs => 'Effacer tous les journaux ?';

  @override
  String get adminActionCannotUndone => 'Cette action est irréversible.';

  @override
  String adminAllActivityLogsPermanentlyDeleted(String value1) {
    return 'Les $value1 journaux d\'activité seront définitivement supprimés.';
  }

  @override
  String adminWelcome(String value1) {
    return 'Bienvenue, $value1 👋';
  }

  @override
  String adminCustomersProfessionals(String value1, String value2) {
    return '$value1 clients · $value2 professionnels';
  }

  @override
  String get adminSearch => 'Rechercher';

  @override
  String get adminGlobalSearchUiReadyConnectUsers =>
      'L\'interface de recherche globale est prête — elle sera connectée à Utilisateurs/Réservations une fois ce module reconstruit.';

  @override
  String get adminReview => 'Avis';

  @override
  String get adminFailedLoadDashboard =>
      'Échec du chargement du tableau de bord';

  @override
  String get adminSearchUsersProfessionalsBookings =>
      'Rechercher utilisateurs, professionnels, réservations…';

  @override
  String get adminTotalUsers => 'Utilisateurs au total';

  @override
  String get adminCustomers => 'Clients';

  @override
  String get adminRevenue => 'Revenu';

  @override
  String get adminTodaySBookings => 'Réservations du jour';

  @override
  String get adminPendingVerification => 'Vérification en attente';

  @override
  String get adminReportedUsers => 'Utilisateurs signalés';

  @override
  String adminExportUsers(String value1) {
    return 'Exporter ($value1 utilisateurs)';
  }

  @override
  String get adminUsers => 'Utilisateurs';

  @override
  String get adminNameZ2 => 'Nom (Z-A)';

  @override
  String get adminOldestFirst => 'Plus ancien d\'abord';

  @override
  String adminShown(String value1) {
    return '$value1 affiché(s)';
  }

  @override
  String get adminBlock => 'Bloquer';

  @override
  String adminJoined(String value1) {
    return 'Inscrit le $value1';
  }

  @override
  String get adminFailedLoadUsers => 'Échec du chargement des utilisateurs';

  @override
  String get adminSearchByNameEmail => 'Rechercher par nom ou e-mail…';

  @override
  String get adminFailedUpdate => 'Échec de la mise à jour.';

  @override
  String get adminFailedDelete => 'Échec de la suppression.';

  @override
  String get adminAddCountry => 'Ajouter un pays';

  @override
  String get adminFailedAddMayAlreadyExist =>
      'Échec de l\'ajout — existe peut-être déjà.';

  @override
  String get adminAdd => 'Ajouter';

  @override
  String adminMergeInto(String value1) {
    return 'Fusionner dans « $value1 »';
  }

  @override
  String get adminEnterTypoVariantSpellingsFoundUser =>
      'Entrez les fautes/variantes d\'orthographe trouvées dans les profils utilisateurs, séparées par des virgules (ex. pakistan, Pakistn).';

  @override
  String get adminMergeFailed => 'Échec de la fusion.';

  @override
  String get adminMerge => 'Fusionner';

  @override
  String adminActive(String value1) {
    return '$value1 actif(s)';
  }

  @override
  String get adminViewCities => 'Voir les villes';

  @override
  String get adminNoCountriesAddedYet => 'Aucun pays ajouté pour l\'instant';

  @override
  String get adminFailedLoadCountries => 'Échec du chargement des pays';

  @override
  String get adminCountryName => 'Nom du pays';

  @override
  String get adminVariant1Variant2 => 'variante1, variante2, ...';

  @override
  String get adminRevenueByCategory => 'Revenu par catégorie';

  @override
  String adminVsPreviousDays(String value1, String value2) {
    return '$value1 % vs les $value2 jours précédents';
  }

  @override
  String get adminNoCategoryDataYet =>
      'Aucune donnée de catégorie pour l\'instant';

  @override
  String adminRs2(String value1, String value2) {
    return 'Rs $value1 ($value2)';
  }

  @override
  String get adminFailedLoadRevenueData =>
      'Échec du chargement des données de revenu';

  @override
  String get adminDeleteBanner => 'Supprimer cette bannière ?';

  @override
  String adminPermanentlyDeleted(String value1) {
    return '« $value1 » sera définitivement supprimé.';
  }

  @override
  String get adminPreviewMode => '👁 MODE APERÇU';

  @override
  String get adminActive2 => 'Actif';

  @override
  String get adminTurningOffHidesBannerFromEveryone =>
      'Désactiver ceci masque la bannière pour tout le monde';

  @override
  String get adminPromoBanners => 'Bannières promotionnelles';

  @override
  String get adminFailedLoadBanners => 'Échec du chargement des bannières';

  @override
  String get adminNoBannersYet => 'Aucune bannière pour l\'instant';

  @override
  String get adminTapCreateNewBanner =>
      'Appuyez sur « + » pour créer une nouvelle bannière';

  @override
  String get adminPreview => 'Aperçu';

  @override
  String get adminEdit => 'Modifier';

  @override
  String get adminFailedGenerateReport => 'Échec de la génération du rapport.';

  @override
  String get adminNoDataRange => 'Aucune donnée dans cette période.';

  @override
  String get adminCopiedClipboardStyleExportCsvReady =>
      'Copié au format export (CSV) — prêt à partager.';

  @override
  String get adminExportCsv => 'Exporter en CSV';

  @override
  String get adminReports => 'Rapports';

  @override
  String get adminQuickGenerate => 'Génération rapide';

  @override
  String get adminLast30Days => '30 derniers jours';

  @override
  String get adminGenerationHistory => 'Historique de génération';

  @override
  String get adminNoReportsGeneratedYetSession =>
      'Aucun rapport généré pour l\'instant dans cette session.';

  @override
  String adminRows(String value1, String value2) {
    return '$value1 lignes · $value2';
  }

  @override
  String adminProsBookingsSubcategories(
    String value1,
    String value2,
    String value3,
  ) {
    return '$value1 pros · $value2 réservations · $value3 sous-catégories';
  }

  @override
  String get adminFeatured => 'En vedette';

  @override
  String get adminShowGuestHomeSFeaturedCategories =>
      'Afficher dans les catégories en vedette de l\'accueil invité (max 6)';

  @override
  String get adminAddSubcategory => 'Ajouter une sous-catégorie';

  @override
  String get adminFailedLoad => 'Échec du chargement';

  @override
  String get adminName => 'Nom';

  @override
  String get adminIconOptional => 'Icône (facultatif)';

  @override
  String get adminParentCategory => 'Catégorie parente';

  @override
  String get adminAddNew => 'Ajouter';

  @override
  String get adminCancelSubscription => 'Annuler l\'abonnement ?';

  @override
  String adminCancelSSubscription(String value1, String value2) {
    return 'Annuler l\'abonnement $value2 de $value1 ?';
  }

  @override
  String get adminNo => 'Non';

  @override
  String get adminCancelSubscription2 => 'Annuler l\'abonnement';

  @override
  String get adminFailedCancel => 'Échec de l\'annulation.';

  @override
  String get adminExtendedBy30Days => 'Prolongé de 30 jours.';

  @override
  String get adminFailedExtend => 'Échec de la prolongation.';

  @override
  String get adminSubscriptions => 'Abonnements';

  @override
  String adminRs3(String value1, String value2, String value3) {
    return '$value1 · Rs $value2/$value3';
  }

  @override
  String adminRenews(String value1) {
    return 'Renouvellement : $value1';
  }

  @override
  String get adminExtend30d => 'Prolonger de 30j';

  @override
  String get adminNoSubscriptionsFound => 'Aucun abonnement trouvé';

  @override
  String get adminFailedLoadSubscriptions =>
      'Échec du chargement des abonnements';

  @override
  String adminExportCustomers(String value1) {
    return 'Exporter ($value1 clients)';
  }

  @override
  String get adminTotalSpentHighLow => 'Total dépensé (décroissant)';

  @override
  String get adminFailedLoadCustomers => 'Échec du chargement des clients';

  @override
  String get adminAddLanguage => 'Ajouter une langue';

  @override
  String get adminRightLeftRtl => 'De droite à gauche (RTL)';

  @override
  String get adminFailedAddCodeMayAlreadyExist =>
      'Échec de l\'ajout — le code existe peut-être déjà.';

  @override
  String get adminFailedUpdateStatus => 'Échec de la mise à jour du statut.';

  @override
  String get adminChangeStatus => 'Changer le statut';

  @override
  String get adminDeleteLanguage => 'Supprimer la langue ?';

  @override
  String adminPermanentlyRemoveAllItsTranslations(String value1) {
    return 'Cela supprimera définitivement « $value1 » et toutes ses traductions.';
  }

  @override
  String get adminFailedDeleteLanguage =>
      'Échec de la suppression de la langue.';

  @override
  String get adminLanguages => 'Langues';

  @override
  String adminActiveTotal(String value1, String value2) {
    return '$value1 actives · $value2 au total';
  }

  @override
  String get adminRtl => 'RTL';

  @override
  String get adminEditTranslations => 'Modifier les traductions';

  @override
  String get adminNoLanguagesAddedYet =>
      'Aucune langue ajoutée pour l\'instant';

  @override
  String get adminFailedLoadLanguages => 'Échec du chargement des langues';

  @override
  String get adminLanguageNameEGUrdu => 'Nom de la langue (ex. Ourdou)';

  @override
  String get adminCodeEGUr => 'Code (ex. ur)';

  @override
  String get adminDeleteArticle => 'Supprimer l\'article ?';

  @override
  String get adminNewArticle => 'Nouvel article';

  @override
  String get adminTipsMagazine => 'Magazine de conseils';

  @override
  String get adminNoArticlesHereYet => 'Aucun article ici pour l\'instant.';

  @override
  String adminMinReadViews(String value1, String value2) {
    return '$value1 min de lecture · $value2 vues';
  }

  @override
  String get adminSelect => 'Sélectionner…';

  @override
  String get adminManageCategories => 'Gérer les catégories';

  @override
  String get adminNoCategoriesYet => 'Aucune catégorie pour l\'instant.';

  @override
  String adminArticles(String value1) {
    return '$value1 articles';
  }

  @override
  String get adminAddNewCategory => 'Ajouter une nouvelle catégorie';

  @override
  String get adminAddCategory => 'Ajouter une catégorie';

  @override
  String get adminCategoryName => 'Nom de la catégorie';

  @override
  String get adminNoChangesSave => 'Aucun changement à enregistrer.';

  @override
  String get adminFailedSaveTranslations =>
      'Échec de l\'enregistrement des traductions.';

  @override
  String get adminAddTranslationKey => 'Ajouter une clé de traduction';

  @override
  String get adminFailedAddKeyMayAlreadyExist =>
      'Échec de l\'ajout — la clé existe peut-être déjà.';

  @override
  String get adminDiscardChanges => 'Annuler les modifications ?';

  @override
  String adminHaveUnsavedTranslationS(String value1) {
    return 'Vous avez $value1 traduction(s) non enregistrée(s).';
  }

  @override
  String get adminKeepEditing => 'Continuer à modifier';

  @override
  String get adminDiscard => 'Annuler';

  @override
  String get adminAddKey => 'Ajouter la clé';

  @override
  String adminTranslate(String value1) {
    return 'Traduire — $value1';
  }

  @override
  String adminKeysUnsaved(String value1, String value2) {
    return '$value1 clés · $value2 non enregistrées';
  }

  @override
  String get adminMissing => 'Manquant';

  @override
  String get adminNoTranslationKeysYet =>
      'Aucune clé de traduction pour l\'instant';

  @override
  String get adminTapAddKeyCreateFirstOne =>
      'Appuyez sur « Ajouter la clé » pour créer la première.';

  @override
  String get adminFailedLoadTranslations =>
      'Échec du chargement des traductions';

  @override
  String get adminKeyEGHomeWelcomeTitle => 'Clé (ex. home.welcome_title)';

  @override
  String get adminDescriptionOptional => 'Description (facultatif)';

  @override
  String get adminSearchKeys => 'Rechercher des clés…';

  @override
  String get adminTranslatedText => 'Texte traduit…';

  @override
  String adminAddCity(String value1) {
    return 'Ajouter une ville à $value1';
  }

  @override
  String get adminEnterTypoVariantSpellingsCommaSeparated =>
      'Entrez les fautes/variantes d\'orthographe, séparées par des virgules.';

  @override
  String get adminAddCity2 => 'Ajouter une ville';

  @override
  String get adminNoCitiesAddedYet => 'Aucune ville ajoutée pour l\'instant';

  @override
  String get adminFailedLoadCities => 'Échec du chargement des villes';

  @override
  String get adminCityName => 'Nom de la ville';

  @override
  String adminPendingReview(String value1) {
    return '$value1 en attente d\'examen';
  }

  @override
  String get adminBlocked => 'BLOQUÉ';

  @override
  String adminReportedBy(String value1, String value2) {
    return 'Signalé par $value1 ($value2)';
  }

  @override
  String get adminFailedLoadReports => 'Échec du chargement des signalements';

  @override
  String adminReportOn(String value1) {
    return 'Signalement sur $value1';
  }

  @override
  String get adminAlsoBanUser => 'Bannir également cet utilisateur';

  @override
  String get adminDismiss => 'Rejeter';

  @override
  String get adminMarkReviewed => 'Marquer comme examiné';

  @override
  String get adminTakeAction => 'Agir';

  @override
  String get adminFailedUpdateReport =>
      'Échec de la mise à jour du signalement.';

  @override
  String get adminSearchByUserReporterReason =>
      'Rechercher par utilisateur, rapporteur ou motif…';

  @override
  String get adminAdminNoteOptional =>
      'Note de l\'administrateur (facultatif)…';

  @override
  String get adminPortfolioApproval => 'Approbation du portfolio';

  @override
  String get adminApprove => 'Approuver';

  @override
  String get adminAllPortfoliosReviewed =>
      'Tous les portfolios ont été examinés !';

  @override
  String get adminFailedLoadPortfolios => 'Échec du chargement des portfolios';

  @override
  String get adminSkip => 'Passer';

  @override
  String get adminWriteReasonOptional => 'Écrire un motif (facultatif)…';

  @override
  String get adminApprovePortfolio => 'Approuver le portfolio ?';

  @override
  String adminVisibleAllCustomers(String value1) {
    return '« $value1 » sera visible par tous les clients.';
  }

  @override
  String adminBookings2(String value1) {
    return '$value1 réservations';
  }

  @override
  String adminCreated(String value1) {
    return 'Créé le $value1';
  }

  @override
  String get adminForceCancel => 'Forcer l\'annulation';

  @override
  String get adminFailedLoadBookings => 'Échec du chargement des réservations';

  @override
  String get adminYesCancel => 'Oui, annuler';

  @override
  String get adminSearchCustomerProfessional =>
      'Rechercher un client ou un professionnel…';

  @override
  String adminCancelBooking(String value1) {
    return 'Annuler la réservation n° $value1 ?';
  }

  @override
  String adminReflectBothCustomerProfessional(String value1, String value2) {
    return '$value1 → $value2 Cela affectera à la fois le client et le professionnel.';
  }

  @override
  String get adminVerificationRequests => 'Demandes de vérification';

  @override
  String adminPendingOldestFirst(String value1) {
    return '$value1 en attente · plus ancien d\'abord';
  }

  @override
  String get adminOldest => 'PLUS ANCIEN';

  @override
  String get adminApproveVerification => 'Approuver la vérification ?';

  @override
  String adminMarkedAsVerifiedProfessional(String value1) {
    return '$value1 sera marqué comme professionnel vérifié.';
  }

  @override
  String adminRejectSRequest(String value1) {
    return 'Rejeter la demande de $value1 ?';
  }

  @override
  String get adminReasonSentProfessionalSoTheyCan =>
      'Ce motif sera envoyé au professionnel afin qu\'il puisse soumettre à nouveau.';

  @override
  String adminFailedRequest(String value1) {
    return 'Échec de la demande $value1.';
  }

  @override
  String get adminNoPendingVerificationRequests =>
      'Aucune demande de vérification en attente 🎉';

  @override
  String get adminFailedLoadVerificationRequests =>
      'Échec du chargement des demandes de vérification';

  @override
  String get adminSearchByNameEmailCategory2 =>
      'Rechercher par nom, e-mail ou catégorie…';

  @override
  String get adminEGCnicImageBlurryPlease =>
      'ex. l\'image CNIC est floue, veuillez la retélécharger…';

  @override
  String get adminFailedCancelItMayHaveAlready =>
      'Échec de l\'annulation — elle a peut-être déjà été envoyée.';

  @override
  String get adminCompose => 'Composer';

  @override
  String adminScheduledFor(String value1) {
    return 'Programmé pour : $value1';
  }

  @override
  String adminSentUsersOpenRate(String value1, String value2) {
    return 'Envoyé à $value1 utilisateurs · Taux d\'ouverture : $value2 %';
  }

  @override
  String get adminComposeNotification => 'Composer une notification';

  @override
  String get adminAudience => 'Audience';

  @override
  String get adminScheduleLater => 'Programmer plus tard';

  @override
  String get adminFailedSendNotification =>
      'Échec de l\'envoi de la notification.';

  @override
  String get adminFailedLoadNotifications =>
      'Échec du chargement des notifications';

  @override
  String get adminTitle => 'Titre';

  @override
  String get adminMessage => 'Message';

  @override
  String get adminUserId => 'ID utilisateur';

  @override
  String get adminDeleteAnnouncement => 'Supprimer l\'annonce ?';

  @override
  String adminRemove(String value1) {
    return 'Supprimer « $value1 » ?';
  }

  @override
  String get adminNewAnnouncement => 'Nouvelle annonce';

  @override
  String get adminAnnouncements => 'Annonces';

  @override
  String get adminType => 'Type';

  @override
  String get adminFailedCreate => 'Échec de la création.';

  @override
  String get adminPublish => 'Publier';

  @override
  String get adminNoAnnouncementsYet => 'Aucune annonce pour l\'instant';

  @override
  String get adminFailedLoadAnnouncements => 'Échec du chargement des annonces';

  @override
  String get adminMagazineAnalytics => 'Analytique du magazine';

  @override
  String adminViews(String value1) {
    return '$value1 vues';
  }

  @override
  String adminOfTotal(String value1) {
    return '$value1 % du total';
  }

  @override
  String get adminNoViewsYet => 'Aucune vue pour l\'instant.';

  @override
  String get adminRecentViewers => 'Lecteurs récents';

  @override
  String get adminComplaints => 'Réclamations';

  @override
  String adminVs(String value1, String value2) {
    return '$value1 vs $value2';
  }

  @override
  String adminAssignedTo(String value1) {
    return 'Assigné à : $value1';
  }

  @override
  String get adminAssignMe => 'M\'assigner';

  @override
  String get adminResolve => 'Résoudre';

  @override
  String get adminFailedAssign => 'Échec de l\'attribution.';

  @override
  String get adminFailedLoadComplaints =>
      'Échec du chargement des réclamations';

  @override
  String get adminResolutionNote => 'Note de résolution';

  @override
  String get authWelcomeProfinder => 'Bienvenue sur ProFinder !';

  @override
  String get authPleaseVerifyEmailActivateAccount =>
      'Veuillez vérifier votre e-mail pour activer votre compte.';

  @override
  String get authContinueLogin => 'Continuer vers la connexion';

  @override
  String get profileNoPaymentsYet => 'Aucun paiement pour l\'instant';

  @override
  String get profileTransactionHistoryAppearHere =>
      'Votre historique de transactions apparaîtra ici';

  @override
  String get profileWallet => 'Portefeuille';

  @override
  String get profileTotalSpent => 'Total dépensé';

  @override
  String profileAcrossTransaction(String value1, String value2) {
    return 'Sur $value1 transaction$value2';
  }

  @override
  String profileCurrentPlan(String value1) {
    return 'Plan actuel : $value1';
  }

  @override
  String get profilePaymentHistory => 'Historique des paiements';

  @override
  String get profileViewAllTransactions => 'Voir toutes vos transactions';

  @override
  String get profileSavedProfessionals => 'Professionnels enregistrés';

  @override
  String get profileNoSavedProfessionalsYet =>
      'Aucun professionnel enregistré pour l\'instant';

  @override
  String get profileTapHeartAnyProfessionalSaveThem =>
      'Appuyez sur le cœur de n\'importe quel professionnel pour l\'enregistrer ici';

  @override
  String profileHr(String value1, String value2) {
    return '$value1 • $value2 \$/h';
  }

  @override
  String get profileBook => 'Réserver';

  @override
  String get profileRemoveFromSaved => 'Retirer des enregistrés';

  @override
  String get profileChangeProfilePhoto => 'Changer la photo de profil';

  @override
  String get profileChooseFromGallery => 'Choisir dans la galerie';

  @override
  String get profileTakePhoto => 'Prendre une photo';

  @override
  String get profileMyProfile => 'Mon profil';

  @override
  String get profileNewPhotoSelectedTapSaveUpload =>
      'Nouvelle photo sélectionnée — appuyez sur Enregistrer pour la téléverser';

  @override
  String get profilePersonalInformation => 'Informations personnelles';

  @override
  String get profileSureWantLogout =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get profileMyReviews => 'Mes avis';

  @override
  String get profileNoReviewsWrittenYet => 'Aucun avis rédigé pour l\'instant';

  @override
  String get profileCompleteBookingLeaveFirstReview =>
      'Terminez une réservation pour laisser votre premier avis';

  @override
  String get profileSecurity => 'Sécurité';

  @override
  String profileWeLlEmailSecureResetLink(String value1) {
    return 'Nous enverrons un lien de réinitialisation sécurisé à $value1.';
  }

  @override
  String get profileSignOutDevice => 'Se déconnecter de cet appareil';

  @override
  String get profileHelpSupport => 'Aide et support';

  @override
  String get profileNeedHand => 'Besoin d\'aide ?';

  @override
  String get profileReachOurSupportTeamAnytime =>
      'Contactez notre équipe de support à tout moment';

  @override
  String get profileFrequentlyAskedQuestions => 'Questions fréquentes';

  @override
  String profileComingSoon(String value1) {
    return '$value1 arrive bientôt';
  }

  @override
  String get profileBrowsingAsGuest => 'Vous naviguez en tant qu\'invité';

  @override
  String get profileLoginBookSaveManageRequests =>
      'Connectez-vous pour réserver, enregistrer et gérer vos demandes';

  @override
  String get profileProfinderV100 => 'ProFinder v1.0.0';

  @override
  String get profileAboutProfinder => 'À propos de ProFinder';

  @override
  String get profileProfinderHelpsFindHireTrustedProfessionals =>
      'ProFinder vous aide à trouver et engager des professionnels de confiance — médecins, avocats, tuteurs, ingénieurs, plombiers et plus encore — près de chez vous.';

  @override
  String get profileAccessBookingsProfile =>
      'Accédez à vos réservations et votre profil';

  @override
  String get profileCreateFreeCustomerAccount =>
      'Créez un compte client gratuit';

  @override
  String get profileBecomeProfessional => 'Devenir professionnel';

  @override
  String get profileListServicesGetHired =>
      'Répertoriez vos services et faites-vous engager';

  @override
  String get profileEnglish => 'Anglais';

  @override
  String get profileComingSoon2 => 'Bientôt disponible';

  @override
  String get profilePrivacyPolicy => 'Politique de confidentialité';

  @override
  String get searchNoReviewsYet => 'Aucun avis pour l\'instant';

  @override
  String get searchFirstReview => 'Soyez le premier à donner votre avis !';

  @override
  String get searchNoPortfolioYet => 'Aucun portfolio pour l\'instant';

  @override
  String get searchProfessionalHasNoApprovedWorkYet =>
      'Ce professionnel n\'a pas encore de travail approuvé';

  @override
  String get searchHourlyRate => 'Tarif horaire';

  @override
  String searchHr(String value1) {
    return '$value1 \$/h';
  }

  @override
  String get searchLoginBook => 'Se connecter pour réserver';

  @override
  String get searchLoginRequired => 'Connexion requise';

  @override
  String get searchPleaseLoginUseAiSearch =>
      'Veuillez vous connecter pour utiliser la recherche IA.';

  @override
  String get searchSearchHistory => 'Historique de recherche';

  @override
  String get searchNoSearchHistoryYet =>
      'Aucun historique de recherche pour l\'instant';

  @override
  String searchPriceHr(String value1, String value2) {
    return 'Prix : $value1 \$ — $value2 \$/h';
  }

  @override
  String searchMinRating(String value1) {
    return 'Note min. : $value1 ★';
  }

  @override
  String get searchVerifiedOnly => 'Vérifiés uniquement';

  @override
  String get searchPreferredGender => 'Genre préféré';

  @override
  String get searchAny => 'Peu importe';

  @override
  String get searchFemale => 'Femme';

  @override
  String get searchMale => 'Homme';

  @override
  String searchMinExperienceYrs(String value1) {
    return 'Expérience min. : $value1+ ans';
  }

  @override
  String get searchPreferredLanguage => 'Langue préférée';

  @override
  String get searchNeedSomeoneNowUrgent =>
      'Besoin de quelqu\'un maintenant / Urgent';

  @override
  String get searchServiceMode => 'Mode de service';

  @override
  String get searchOnline => 'En ligne';

  @override
  String get searchHomeVisit => 'Visite à domicile';

  @override
  String get searchInOffice => 'Au bureau';

  @override
  String get searchReset => 'Réinitialiser';

  @override
  String get searchApply => 'Appliquer';

  @override
  String searchNoResults(String value1) {
    return 'Aucun résultat pour « $value1 »';
  }

  @override
  String get searchHereSomeAlternativesMightLike =>
      'Voici quelques alternatives qui pourraient vous plaire';

  @override
  String get searchClearSearch => 'Effacer la recherche';

  @override
  String searchKm(String value1) {
    return '$value1 km';
  }

  @override
  String searchFor(String value1) {
    return 'Pour : « $value1 »';
  }

  @override
  String searchToday(String value1, String value2) {
    return '$value1/$value2 aujourd\'hui';
  }

  @override
  String get searchAlsoShowNormalResults =>
      'Afficher aussi les résultats normaux';

  @override
  String searchNoExactMatch(String value1) {
    return 'Aucune correspondance exacte pour « $value1 »';
  }

  @override
  String get searchHereSomeRelevantAlternatives =>
      'Voici quelques alternatives pertinentes';

  @override
  String get searchAiAgentLive => 'L\'agent IA est en ligne';

  @override
  String searchFindingBestMatch(String value1) {
    return 'Recherche de la meilleure correspondance pour « $value1 »';
  }

  @override
  String get searchRecentSearches => 'Recherches récentes';

  @override
  String searchSeeAll(String value1) {
    return 'Voir tout ($value1)';
  }

  @override
  String get searchClear => 'Effacer';

  @override
  String get searchPopularSearches => 'Recherches populaires';

  @override
  String get searchBrowseByCategory => 'Parcourir par catégorie';

  @override
  String searchResultFor(String value1, String value2, String value3) {
    return '$value1 résultat$value2 pour « $value3 »';
  }

  @override
  String get searchGettingLocation => 'Obtention de la position...';

  @override
  String get searchSortedByDistance => 'Trié par distance';

  @override
  String get searchEnableLocation => 'Activer la localisation';

  @override
  String get searchPro => 'PRO';

  @override
  String get searchEGKarachiLahore => 'ex. Karachi, Lahore';

  @override
  String get searchEGUrduEnglish => 'ex. Ourdou, Anglais';

  @override
  String get magazineHealthLegalHomeLifestyle =>
      'Santé · Juridique · Maison & Style de vie';

  @override
  String get magazineCouldNotLoadArticles =>
      'Impossible de charger les articles';

  @override
  String get magazineNoArticlesYet => 'Aucun article pour l\'instant';

  @override
  String get magazineCheckBackSoonTipsAdvice =>
      'Revenez bientôt pour des conseils et astuces.';

  @override
  String get magazineSearchArticles => 'Rechercher des articles…';

  @override
  String magazineMinRead(String value1) {
    return '$value1 min de lecture';
  }

  @override
  String get magazineProfinderTipsMagazine => 'Magazine de conseils ProFinder';

  @override
  String get magazineGoBack => 'Retour';

  @override
  String magazineMin(String value1) {
    return '$value1 min';
  }

  @override
  String get chatSharedMedia => 'Médias partagés';

  @override
  String get chatNoSharedMediaYet => 'Aucun média partagé pour l\'instant';

  @override
  String chatPhotos(String value1) {
    return 'Photos ($value1)';
  }

  @override
  String chatVoiceMessages(String value1) {
    return 'Messages vocaux ($value1)';
  }

  @override
  String chatS(String value1) {
    return '${value1}s';
  }

  @override
  String get chatSharedMedia2 => 'Médias partagés';

  @override
  String get chatBlockUser => 'Bloquer l\'utilisateur';

  @override
  String get chatReportUser => 'Signaler l\'utilisateur';

  @override
  String chatBlock(String value1) {
    return 'Bloquer $value1 ?';
  }

  @override
  String get chatTheyNoLongerAbleSendMessages =>
      'Il ne pourra plus vous envoyer de messages.';

  @override
  String get chatUnblockUser => 'Débloquer l\'utilisateur';

  @override
  String chatYouBlockedUser(String value1) {
    return 'Vous avez bloqué $value1';
  }

  @override
  String get chatBlockedBannerSubtitle =>
      'Il ne peut plus vous appeler ni vous envoyer de messages. Débloquez-le pour reprendre la conversation.';

  @override
  String get chatUnblockAction => 'Débloquer';

  @override
  String get chatConversationUnavailable =>
      'Cette conversation n\'est pas disponible';

  @override
  String get chatConversationUnavailableSubtitle =>
      'Vous ne pouvez pas envoyer de messages ici pour le moment.';

  @override
  String get chatMessageUnavailable => 'Message indisponible';

  @override
  String get chatSayHello => 'Dites bonjour 👋';

  @override
  String get chatSearchChat => 'Rechercher dans la conversation';

  @override
  String get chatCouldNotLoadMessages => 'Impossible de charger les messages';

  @override
  String get chatMessages => 'Messages';

  @override
  String get chatNoConversationsYet => 'Aucune conversation pour l\'instant';

  @override
  String get chatSearchMessages => 'Rechercher des messages...';

  @override
  String get chatMicrophonePermissionRequiredVoiceMessages =>
      'L\'autorisation du microphone est requise pour les messages vocaux.';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatSendPhoto => 'Envoyer une photo';

  @override
  String get chatReportSubmittedThank => 'Signalement envoyé. Merci.';

  @override
  String get chatCouldNotSubmitReportTryAgain =>
      'Impossible d\'envoyer le signalement. Réessayez.';

  @override
  String chatReport(String value1) {
    return 'Signaler $value1';
  }

  @override
  String get chatSubmit => 'Envoyer';

  @override
  String get chatAdditionalDetailsOptional =>
      'Détails supplémentaires (facultatif)';

  @override
  String get chatMessageWasDeleted => 'Ce message a été supprimé';

  @override
  String get chatEdited => 'modifié ·';

  @override
  String get chatReply => 'Répondre';

  @override
  String get chatDeleteMe => 'Supprimer pour moi';

  @override
  String get chatDeleteEveryone => 'Supprimer pour tout le monde';

  @override
  String get chatEditMessage => 'Modifier le message';

  @override
  String get notificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notificationsNoNotificationsYet =>
      'Aucune notification pour l\'instant';

  @override
  String get notificationsBookingUpdatesAurAlertsYahanDikhenge =>
      'Les mises à jour de réservation et les alertes s\'afficheront ici';

  @override
  String get professionalDelete => 'Supprimer ?';

  @override
  String professionalDelete2(String value1) {
    return 'Supprimer « $value1 » ?';
  }

  @override
  String get professionalAddPortfolioItem => 'Ajouter un élément au portfolio';

  @override
  String get professionalTapAddImage => 'Appuyez pour ajouter une image';

  @override
  String get professionalPortfolioReviewedByAdminOnceApproved =>
      'Votre portfolio sera examiné par un administrateur. Une fois approuvé, vous recevrez un badge vérifié.';

  @override
  String get professionalSubmitReview => 'Soumettre pour examen';

  @override
  String get professionalMyPortfolio => 'Mon portfolio';

  @override
  String get professionalNoPortfolioItemsYet =>
      'Aucun élément de portfolio pour l\'instant';

  @override
  String get professionalAddWorkGetVerified =>
      'Ajoutez votre travail pour être vérifié';

  @override
  String get professionalAddFirstItem => 'Ajouter le premier élément';

  @override
  String professionalNote(String value1) {
    return 'Remarque : $value1';
  }

  @override
  String get professionalTitle => 'Titre *';

  @override
  String get professionalEGHouseConstructionProject =>
      'ex. Projet de construction de maison';

  @override
  String get professionalBriefDescriptionWork =>
      'Brève description de ce travail...';

  @override
  String get professionalAddPortfolio => 'Ajouter au portfolio';

  @override
  String get professionalTypeMessage => 'Écrivez un message...';

  @override
  String get professionalDeletePhoto => 'Supprimer la photo ?';

  @override
  String get professionalPhotoRemovedFromGallery =>
      'Cette photo sera retirée de votre galerie.';

  @override
  String get professionalGallery => 'Galerie';

  @override
  String get professionalNoPhotosYet => 'Aucune photo pour l\'instant';

  @override
  String get professionalAddPhotosShowcaseWorkEnvironment =>
      'Ajoutez des photos pour présenter votre environnement de travail';

  @override
  String get professionalAddPhoto => 'Ajouter une photo';

  @override
  String get professionalWorkingHours => 'Heures de travail';

  @override
  String get professionalProfessionalDetails => 'Détails professionnels';

  @override
  String get professionalSkills => 'Compétences';

  @override
  String get professionalNoSkillsAddedYet =>
      'Aucune compétence ajoutée pour l\'instant';

  @override
  String get professionalBankDetails => 'Coordonnées bancaires';

  @override
  String get professionalCertificates => 'Certificats';

  @override
  String get professionalWalletEarnings => 'Portefeuille et revenus';

  @override
  String get professionalSubscriptionUpgradePremium =>
      'Abonnement / Passer à Premium';

  @override
  String get professionalChangePassword => 'Changer le mot de passe';

  @override
  String get professionalAddSkill => '+ Ajouter une compétence';

  @override
  String get professionalAddLanguage => '+ Ajouter une langue';

  @override
  String get professionalNeedMoreHelp => 'Besoin d\'aide supplémentaire ?';

  @override
  String get professionalOurSupportTeamRepliesWithin24 =>
      'Notre équipe de support répond sous 24 heures';

  @override
  String get professionalContact => 'Contact';

  @override
  String get professionalContactSupport => 'Contacter le support';

  @override
  String get professionalSupportProfinderCom => 'support@profinder.com';

  @override
  String get professionalEmailUsAnytime => 'Écrivez-nous à tout moment';

  @override
  String get professionalLiveChat => 'Chat en direct';

  @override
  String get professionalAvailable9Am6Pm => 'Disponible de 9h à 18h';

  @override
  String professionalRePlan(String value1) {
    return 'Vous êtes sur le plan $value1';
  }

  @override
  String get professionalUpgradeMoreBookingsFeaturedProfilePriority =>
      'Passez à un plan supérieur pour plus de réservations, un profil en vedette et un classement prioritaire';

  @override
  String get professionalUpgrade => 'Mettre à niveau';

  @override
  String get professionalProfileCompletion => 'Complétion du profil';

  @override
  String get professionalCompleteProfileGetMoreBookings =>
      'Complétez votre profil pour obtenir plus de réservations';

  @override
  String professionalNoClientsFound(String value1) {
    return 'Aucun client trouvé pour « $value1 »';
  }

  @override
  String get professionalQuickActions => 'Actions rapides';

  @override
  String get professionalEarnings => 'Revenus';

  @override
  String get professionalViewWallet => 'Voir le portefeuille';

  @override
  String get professionalPerformance => 'Performance';

  @override
  String get professionalTodaySSchedule => 'Programme du jour';

  @override
  String get professionalNoBookingsScheduledToday =>
      'Aucune réservation prévue aujourd\'hui';

  @override
  String get professionalRecentMessages => 'Messages récents';

  @override
  String get professionalSeeAll => 'Voir tout';

  @override
  String get professionalNoMessagesYet => 'Aucun message pour l\'instant';

  @override
  String get professionalSkillsPricing => 'Compétences et tarifs';

  @override
  String get professionalManage => 'Gérer';

  @override
  String get professionalAddWorkSamples =>
      'Ajoutez des échantillons de votre travail';

  @override
  String get professionalGetVerifiedByAddingPortfolio =>
      'Faites-vous vérifier en ajoutant un portfolio';

  @override
  String get professionalRecentReviews => 'Avis récents';

  @override
  String get professionalRecentBookings => 'Réservations récentes';

  @override
  String get professionalNoBookingsYet => 'Aucune réservation pour l\'instant';

  @override
  String get professionalBookingDetails => 'Détails de la réservation';

  @override
  String get professionalMarkAsCompleted => 'Marquer comme terminé';

  @override
  String get professionalCancelBooking => 'Annuler la réservation';

  @override
  String get professionalSearchBookingsByClientName =>
      'Rechercher des réservations par nom de client...';

  @override
  String get professionalPortfolio => 'Portfolio';

  @override
  String get professionalAddCertificate => 'Ajouter un certificat';

  @override
  String get professionalTapAddCertificateImage =>
      'Appuyez pour ajouter une image de certificat';

  @override
  String get professionalSaveCertificate => 'Enregistrer le certificat';

  @override
  String get professionalNoCertificatesYet =>
      'Aucun certificat pour l\'instant';

  @override
  String get professionalAddCertificationsBuildTrust =>
      'Ajoutez des certifications pour renforcer la confiance';

  @override
  String get professionalAddFirstCertificate => 'Ajouter le premier certificat';

  @override
  String get professionalCertificateTitle => 'Titre du certificat *';

  @override
  String get professionalIssuingOrganization => 'Organisme émetteur';

  @override
  String get professionalEGCertifiedElectrician => 'ex. Électricien certifié';

  @override
  String get professionalEGTevtaCoursera => 'ex. TEVTA / Coursera';

  @override
  String get professionalCustomerConversationsShowUpHere =>
      'Les conversations avec les clients apparaîtront ici';

  @override
  String get professionalCancelBooking2 => 'Annuler la réservation ?';

  @override
  String get professionalSureWantCancelBooking =>
      'Êtes-vous sûr de vouloir annuler cette réservation ?';

  @override
  String get professionalReasonCancellingOptional =>
      'Motif de l\'annulation (facultatif)';

  @override
  String get professionalYesCancelIt => 'Oui, l\'annuler';

  @override
  String professionalNoBookings(String value1) {
    return 'Aucune réservation $value1';
  }

  @override
  String get professionalDecline => 'Refuser';

  @override
  String get professionalEGNotAvailableThatDay =>
      'ex. non disponible ce jour-là, urgence survenue...';

  @override
  String professionalReview(String value1, String value2) {
    return '$value1 avis$value2';
  }

  @override
  String get professionalWithdrawEarnings => 'Retirer les revenus';

  @override
  String professionalAvailable(String value1) {
    return 'Disponible : $value1 \$';
  }

  @override
  String professionalMinimumWithdrawal(String value1) {
    return 'Retrait minimum : $value1 \$';
  }

  @override
  String get professionalRequestWithdrawal => 'Demander un retrait';

  @override
  String get professionalBankDetailsRequired =>
      'Coordonnées bancaires requises';

  @override
  String get professionalPleaseAddBankAccountDetailsProfile =>
      'Veuillez ajouter vos coordonnées bancaires dans le profil avant de demander un retrait.';

  @override
  String get professionalAvailableBalance => 'Solde disponible';

  @override
  String get professionalWithdraw => 'Retirer';

  @override
  String get professionalNoTransactionsYet =>
      'Aucune transaction pour l\'instant';

  @override
  String get professionalEnterAmount => 'Entrez le montant';

  @override
  String get professionalPerformanceScore => 'Score de performance';

  @override
  String get professionalOut100 => 'sur 100';

  @override
  String get professionalPerformanceScore40Rating30Acceptance =>
      'Score de performance = 40 % note + 30 % taux d\'acceptation + 30 % taux de réponse.';

  @override
  String get professionalDashboard => 'Tableau de bord';

  @override
  String get professionalMagazine => 'Magazine';

  @override
  String get professionalEnterCurrentPasswordNewPassword =>
      'Entrez votre mot de passe actuel et un nouveau mot de passe.';

  @override
  String get professionalUpdate => 'Mettre à jour';

  @override
  String get professionalCurrentPassword => 'Mot de passe actuel';

  @override
  String get professionalNewPassword => 'Nouveau mot de passe';

  @override
  String get professionalConfirmNewPassword =>
      'Confirmer le nouveau mot de passe';

  @override
  String get homeBecomePro => 'Devenir Pro';

  @override
  String get homeLoginRequired => 'Connexion requise';

  @override
  String get homeCreateAccount => 'Créer un compte';

  @override
  String get homeWelcomeGuest => 'Bienvenue, Invité';

  @override
  String get homeHireRightExpertMinutes =>
      'Engagez le bon expert, en quelques minutes.';

  @override
  String get homeSearchDoctorsLawyersPlumbers =>
      'Rechercher médecins, avocats, plombiers…';

  @override
  String get homeViewAll => 'Voir tout';

  @override
  String get homeAllCategories => 'Toutes les catégories';

  @override
  String get homeFeatured => 'EN VEDETTE';

  @override
  String get homeExploreExperts => 'Explorer les experts →';

  @override
  String get homeProfessional => 'Êtes-vous un professionnel ?';

  @override
  String get homeJoinProfinderGetDiscoveredByThousands =>
      'Rejoignez ProFinder et faites-vous découvrir par des milliers de clients.';

  @override
  String get homeUnlockFullExperience => 'Débloquez l\'expérience complète';

  @override
  String get homeBookProfessionalsSaveFavouritesTrackRequests =>
      'Réservez des professionnels, enregistrez vos favoris et suivez vos demandes.';

  @override
  String get homeNoProfessionalsNearbyYet =>
      'Aucun professionnel à proximité pour l\'instant';

  @override
  String get homeTrySearchingCategoryCheckBackSoon =>
      'Essayez de rechercher une catégorie ou revenez bientôt.';

  @override
  String get homeSearchNow => 'Rechercher maintenant';

  @override
  String get homeFilter => 'Filtrer';

  @override
  String homePrice(String value1, String value2) {
    return 'Prix : $value1 \$ — $value2';
  }

  @override
  String get homeVerifiedOnly => 'Vérifiés uniquement';

  @override
  String get homeNoProfessionalsAvailableCity =>
      'Aucun professionnel disponible dans votre ville.';

  @override
  String get homeTrySearchingNearbyCities =>
      'Essayez de rechercher dans les villes voisines.';

  @override
  String homeHi(String value1) {
    return 'Bonjour, $value1 👋';
  }

  @override
  String get homeGetPersonalizedPicks =>
      'Obtenez des recommandations personnalisées';

  @override
  String get homeBookFirstServiceWeLlStart =>
      'Réservez votre premier service et nous commencerons à personnaliser cela pour vous.';

  @override
  String get homeBrowse => 'Parcourir';

  @override
  String get homeAiPick => '✨ SÉLECTION IA POUR VOUS';

  @override
  String get homeBookAgain => 'Réserver à nouveau';

  @override
  String get homeClearAll => 'Tout effacer';

  @override
  String get homeNoUpcomingBookings => 'Aucune réservation à venir';

  @override
  String get homeBrowseProfessionals => 'Parcourir les professionnels';

  @override
  String get homeViewDetails => 'Voir les détails';

  @override
  String homeCancelledBy(String value1, String value2) {
    return 'Annulé par $value1 : $value2';
  }

  @override
  String get homeRateExperience => 'Évaluez votre expérience ⭐';

  @override
  String homePlan(String value1) {
    return 'Plan : $value1';
  }

  @override
  String get homeRecentChats => 'Discussions récentes';

  @override
  String get homeNoMessagesYet => 'Aucun message pour l\'instant.';

  @override
  String get homeStartConversationAfterBookingProfessional =>
      'Démarrez une conversation après avoir réservé un professionnel.';

  @override
  String homeNotifications(String value1) {
    return 'Notifications$value1';
  }

  @override
  String get homeAiSuggestions => 'Suggestions IA';

  @override
  String get homeUnlimited => 'Illimité ✨';

  @override
  String homeUsedToday(String value1, String value2) {
    return '$value1 sur $value2 utilisé aujourd\'hui';
  }

  @override
  String get homeJustTellUsWhatNeedWe =>
      'Dites-nous simplement de quoi vous avez besoin, et nous vous mettrons instantanément en relation avec le bon professionnel vérifié.';

  @override
  String get homeDailyLimitReachedResetsMidnight =>
      'Limite quotidienne atteinte — réinitialisation à minuit';

  @override
  String get homeNeedHelpWeReHere =>
      'Besoin d\'aide ? Nous sommes là pour vous';

  @override
  String get homeGetResponseWithin24Hours =>
      'Recevez une réponse sous 24 heures';

  @override
  String get homeHelpCenter => 'Centre d\'aide';

  @override
  String get homeEGINeedPlumberLeaking =>
      'ex. J\'ai besoin d\'un plombier pour une fuite…';

  @override
  String get homePopularCategories => 'Catégories populaires';

  @override
  String get homeUpcomingBookings => 'Réservations à venir';

  @override
  String get bookingsBookProfessionalFromHomeScreen =>
      'Réservez un professionnel depuis l\'écran d\'accueil';

  @override
  String get bookingsEGScheduleChangedNoLonger =>
      'ex. changement d\'horaire, plus nécessaire...';

  @override
  String get bookingsBookingSent => 'Réservation envoyée !';

  @override
  String bookingsRequestSentNotifiedOnceTheyRespond(String value1) {
    return 'Demande envoyée à $value1. Vous serez averti dès qu\'il répondra.';
  }

  @override
  String get bookingsViewMyBookings => 'Voir mes réservations';

  @override
  String get bookingsBackHome => 'Retour à l\'accueil';

  @override
  String get bookingsBookAppointment => 'Prendre rendez-vous';

  @override
  String get bookingsSummary => 'Résumé';

  @override
  String get bookingsConfirmBooking => 'Confirmer la réservation';

  @override
  String get bookingsDescribeIssueRequirements =>
      'Décrivez votre problème ou vos exigences...';

  @override
  String get bookingsShareExperience => 'Partagez votre expérience';

  @override
  String get bookingsYourRating => 'Votre note';

  @override
  String get bookingsCommentOptional => 'Votre commentaire (facultatif)';

  @override
  String get bookingsReviewSubmitted => 'Avis envoyé ! 🎉';

  @override
  String bookingsThankReviewingFeedbackHelpsOthersMake(String value1) {
    return 'Merci d\'avoir évalué $value1. Votre avis aide les autres à faire de meilleurs choix.';
  }

  @override
  String get bookingsBackBookings => 'Retour aux réservations';

  @override
  String bookingsDescribeExperience(String value1) {
    return 'Décrivez votre expérience avec $value1...';
  }

  @override
  String get subscriptionConfirmSubscription => 'Confirmer l\'abonnement';

  @override
  String subscriptionSubscribe(String value1, String value2, String value3) {
    return 'S\'abonner à $value1 pour $value2 $value3';
  }

  @override
  String get subscriptionSubscribe2 => 'S\'abonner';

  @override
  String get subscriptionChoosePlan => 'Choisissez votre plan';

  @override
  String get subscriptionAvailablePlans => 'Plans disponibles';

  @override
  String subscriptionCurrentPlan(String value1) {
    return 'Plan actuel : $value1';
  }

  @override
  String subscriptionValidUntil(String value1) {
    return 'Valide jusqu\'au : $value1';
  }

  @override
  String get subscriptionUpgradeUnlockPremiumFeatures =>
      'Passez à un plan supérieur pour débloquer les fonctionnalités premium';

  @override
  String get subscriptionRecommended => 'RECOMMANDÉ';

  @override
  String get subscriptionCurrentPlan2 => 'PLAN ACTUEL';

  @override
  String get subscriptionCurrentPlan3 => 'Plan actuel';

  @override
  String get subscriptionBasicPlan => 'Plan de base';

  @override
  String subscriptionGet(String value1) {
    return 'Obtenir $value1';
  }

  @override
  String get subscriptionCancelAnytimeSecurePayment =>
      'Annulez à tout moment • Paiement sécurisé';

  @override
  String get subscriptionBookingLimitReached =>
      'Limite de réservations atteinte !';

  @override
  String subscriptionVeUsedBookingsMonthFreePlan(String value1, String value2) {
    return 'Vous avez utilisé $value1/$value2 réservations ce mois-ci sur votre plan Gratuit.';
  }

  @override
  String get subscriptionUpgradePremium => 'Passer à Premium';

  @override
  String get subscriptionMaybeLater => 'Peut-être plus tard';

  @override
  String get subscriptionMonthlyBookings => 'Réservations mensuelles';

  @override
  String get subscriptionPremiumIncludes => 'Premium inclut :';

  @override
  String get subscriptionAiSearchLimitReached =>
      'Limite de recherches IA atteinte !';

  @override
  String subscriptionVeUsedAiSearchesTodayAi(String value1, String value2) {
    return 'Vous avez utilisé $value1/$value2 recherches IA aujourd\'hui. Le chat IA est verrouillé jusqu\'à la réinitialisation de votre limite.';
  }

  @override
  String get subscriptionAiSearchesToday => 'Recherches IA aujourd\'hui';

  @override
  String get subscriptionGetPremium20AiDay => 'Obtenir Premium — 20 IA/jour';

  @override
  String get subscriptionContinueNormalSearch =>
      'Continuer avec la recherche normale';

  @override
  String get subscriptionPremiumAiFeatures => 'Fonctionnalités IA Premium :';

  @override
  String get subscriptionProfinderPremium => 'ProFinder Premium';

  @override
  String sharedYExp(String value1) {
    return '$value1 an(s) d\'exp.';
  }

  @override
  String get sharedViewProfile => 'Voir le profil';

  @override
  String get homeNotificationsSignInMessage =>
      'Les notifications sont disponibles après connexion. Connectez-vous ou créez un compte pour voir les mises à jour de réservation et les alertes personnalisées.';

  @override
  String get homeSetUpProfileMessage =>
      'Connectez-vous ou créez un compte pour configurer votre profil.';

  @override
  String get homeLoginToSaveFavourites =>
      'Connectez-vous pour ajouter des professionnels à vos favoris.';

  @override
  String homeLoginToBookName(String value1) {
    return 'Connectez-vous pour réserver $value1 et gérer vos rendez-vous.';
  }

  @override
  String get homeWhatAreYouLookingForToday =>
      'Que recherchez-vous aujourd\'hui ?';

  @override
  String get homeTrendingLabel => 'Tendance';

  @override
  String get homeFeaturedCategoriesSection => 'Catégories en vedette';

  @override
  String get homeTopRatedProfessionals => 'Professionnels les mieux notés';

  @override
  String get homeTopRatedLabel => 'Les mieux notés';

  @override
  String get homeTrendingThisWeek => 'Tendance cette semaine';

  @override
  String get homePopularProfessionals => 'Professionnels populaires';

  @override
  String get homePopularLabel => 'Populaire';

  @override
  String get homeRecentlyAdded => 'Récemment ajoutés';

  @override
  String get homeNewLabel => 'Nouveau';

  @override
  String get homeFromTheMagazine => 'Extrait du magazine';

  @override
  String homeNearLocation(String value1) {
    return 'Près de $value1';
  }

  @override
  String homeProfessionalsInLocation(String value1) {
    return 'Professionnels à $value1';
  }

  @override
  String get homeClosestProfessionals => 'Professionnels les plus proches';

  @override
  String get homeTopRatedProfessionalsNationwide =>
      'Professionnels les mieux notés dans tout le pays';

  @override
  String get homeNearbyLabel => 'À proximité';

  @override
  String get homeArticleLabel => 'Article';

  @override
  String get homeGoodMorning => 'Bonjour';

  @override
  String get homeGoodAfternoon => 'Bon après-midi';

  @override
  String get homeGoodEvening => 'Bonsoir';

  @override
  String get homeWhatServiceAreYouLookingFor =>
      'Quel service recherchez-vous aujourd\'hui ?';

  @override
  String get proReadyToGrowToday =>
      'Prêt à développer votre activité aujourd\'hui ?';

  @override
  String get homeSetYourLocation => 'Définissez votre position';

  @override
  String get homeCityHint => 'ex. Karachi, Lahore';

  @override
  String get homeNoLimit => 'Sans limite';

  @override
  String homeMinRatingLabel(String value1) {
    return 'Note minimale : $value1 ★';
  }

  @override
  String get homeResetButton => 'Réinitialiser';

  @override
  String get homeApplyButton => 'Appliquer';

  @override
  String get homeFilteredResults => 'Résultats filtrés';

  @override
  String get homeRecommendedForYou => 'Recommandé pour vous';

  @override
  String get homeRecommendedLabel => 'Recommandé';

  @override
  String get homeSavedQuickAction => 'Favoris';

  @override
  String get homeWalletQuickAction => 'Portefeuille';

  @override
  String get homeHelpQuickAction => 'Aide';

  @override
  String get homeRecentSearches => 'Recherches récentes';

  @override
  String get homeRecentBookingsTitle => 'Réservations récentes';

  @override
  String get homeConfirmedStatus => 'Confirmée';

  @override
  String get homeDeclinedStatus => 'Refusée';

  @override
  String get homeCancelledStatus => 'Annulée';

  @override
  String get homeSystemLabel => 'système';

  @override
  String get homeTotalSpent => 'Total dépensé';

  @override
  String homeAcrossTransaction(String value1) {
    return 'Sur $value1 transaction';
  }

  @override
  String homeAcrossTransactions(String value1) {
    return 'Sur $value1 transactions';
  }

  @override
  String get homeManageButton => 'Gérer';

  @override
  String get homeUpgradeButton => 'Mettre à niveau';

  @override
  String get homePaymentHistoryTitle => 'Historique des paiements';

  @override
  String get homeTotalLabel => 'Total';

  @override
  String get homeSayHello => 'Dites bonjour 👋';

  @override
  String get homeMagazineNavLabel => 'Magazine';

  @override
  String get homeMessagesNavLabel => 'Messages';

  @override
  String get homeTipsMagazineTitle => 'Magazine de conseils';

  @override
  String get homeFeaturedArticlesTitle => 'Articles en vedette';

  @override
  String get homeContactButton => 'Contacter';

  @override
  String get homeAiPickForYou => 'SÉLECTION IA POUR VOUS';

  @override
  String get homeMessagingComingSoonTitle => 'Messagerie';

  @override
  String get homeMessagingComingSoonMessage =>
      'Vous pourrez discuter directement avec des professionnels ici.';

  @override
  String get commonOn => 'Activé';

  @override
  String get commonOff => 'Désactivé';

  @override
  String get profileVersionLabel => 'Version 1.0.0';

  @override
  String get searchAiSearchFailedTryNormal =>
      'La recherche IA a échoué. Essayez la recherche normale.';

  @override
  String get searchFailedCheckConnection =>
      'Échec de la recherche. Vérifiez votre connexion et réessayez.';

  @override
  String get searchClearAll => 'Tout effacer';

  @override
  String get searchDistanceAny => 'Distance : Toutes';

  @override
  String searchWithinKm(String value1) {
    return 'Dans un rayon de $value1 km';
  }

  @override
  String get searchSortPriceLowHigh => 'Prix : croissant';

  @override
  String get searchSortPriceHighLow => 'Prix : décroissant';

  @override
  String searchAiSearchesLeft(String value1) {
    return '$value1 restantes';
  }

  @override
  String get searchSimilarProfessionals => 'Professionnels similaires';

  @override
  String get searchProfessionalsNearYou => 'Professionnels près de vous';

  @override
  String get searchTrendingCategories => 'Catégories tendance';

  @override
  String get searchAiPremiumResults => 'Résultats IA Premium';

  @override
  String get searchAiSearchResultsTitle => 'Résultats de recherche IA';

  @override
  String get searchNoMatchingProfessionalsFound =>
      'Aucun professionnel correspondant trouvé.';

  @override
  String get searchRelatedProfessions => 'Métiers connexes';

  @override
  String get searchTrendingProfessionals => 'Professionnels tendance';

  @override
  String get searchPopularNearby => 'Populaires à proximité';

  @override
  String get searchShowingResultsFor => 'Affichage des résultats pour : ';

  @override
  String searchMetersAway(String value1) {
    return 'à $value1 m';
  }

  @override
  String searchKmNearYou(String value1) {
    return '$value1 km · près de vous';
  }

  @override
  String searchKmAway(String value1) {
    return 'à $value1 km';
  }

  @override
  String searchApproxKm(String value1) {
    return '~$value1 km';
  }

  @override
  String searchApproxKmNearbyCity(String value1) {
    return '~$value1 km · ville voisine';
  }

  @override
  String get searchDifferentArea => 'Zone différente';

  @override
  String get searchAiHintPlaceholder =>
      'Demandez à l\'IA : trouve-moi un plombier...';

  @override
  String get searchNameCityProfessionHint => 'Nom, ville, profession...';

  @override
  String get searchAiSearchOnTapDisable =>
      'Recherche IA activée — Touchez pour désactiver';

  @override
  String get searchTryAiSearchSmarterResults =>
      'Essayez la recherche IA — résultats plus intelligents';

  @override
  String get subscriptionFailedToLoadPlans =>
      'Échec du chargement des forfaits.';

  @override
  String subscriptionSubscribedTo(String value1) {
    return 'Abonné à $value1 !';
  }

  @override
  String get subscriptionSubscriptionFailed => 'Échec de l\'abonnement.';

  @override
  String get subscriptionPerMonth => '/mois';

  @override
  String get subscriptionPerYear => '/an';

  @override
  String get subscriptionFreeForever => 'Gratuit pour toujours';

  @override
  String get subscriptionBilledMonthly => 'Facturation mensuelle';

  @override
  String get subscriptionBilledYearly => 'Facturation annuelle';

  @override
  String get subscriptionFree => 'GRATUIT';

  @override
  String get subscriptionUnlimited => 'Illimité';

  @override
  String get subscriptionUpgradeUnlimitedAiSearches =>
      'Passez à un forfait supérieur pour des recherches IA illimitées et plus';

  @override
  String get subscriptionUpgradeUnlimitedBookings =>
      'Passez à un forfait supérieur pour des réservations illimitées et un classement prioritaire';

  @override
  String get subscriptionFeatureAiSearchesDay => 'Recherches IA/jour';

  @override
  String get subscriptionFeatureMessagesDay => 'Messages/jour';

  @override
  String get subscriptionFeatureUnlimitedBookings => 'Réservations illimitées';

  @override
  String get subscriptionFeaturePrioritySupport => 'Support prioritaire';

  @override
  String get subscriptionFeaturePremiumBadge => 'Badge Premium';

  @override
  String get subscriptionFeatureNoAds => 'Sans publicité';

  @override
  String get subscriptionFeatureBookingsMonth => 'Réservations/mois';

  @override
  String get subscriptionFeaturePortfolioImages => 'Images du portfolio';

  @override
  String get subscriptionFeatureServicesListed => 'Services proposés';

  @override
  String get subscriptionFeatureFeaturedProfile => 'Profil en vedette';

  @override
  String get subscriptionFeaturePriorityRanking => 'Classement prioritaire';

  @override
  String subscriptionLimitResetsOn(String value1) {
    return 'Votre limite sera réinitialisée le $value1';
  }

  @override
  String get subscriptionLimitResetsNextMonth =>
      'Votre limite sera réinitialisée au début du mois prochain';

  @override
  String get subscriptionFeatureUnlimitedBookingsMonth =>
      'Réservations illimitées chaque mois';

  @override
  String get subscriptionFeatureFeaturedProfileSearch =>
      'Profil en vedette dans les résultats de recherche';

  @override
  String get subscriptionFeaturePriorityAiRanking =>
      'Classement IA prioritaire';

  @override
  String get subscriptionFeatureNoAdsProfile =>
      'Pas de publicité sur votre profil';

  @override
  String get subscriptionAiResetsTomorrowMidnight =>
      'Vos recherches IA seront réinitialisées demain à minuit';

  @override
  String subscriptionResetsAt(String value1, String value2) {
    return 'Réinitialisation $value1 à $value2';
  }

  @override
  String get commonToday => 'aujourd\'hui';

  @override
  String get commonTomorrow => 'demain';

  @override
  String get subscriptionBenefit20AiSearchesDay => '20 recherches IA par jour';

  @override
  String get subscriptionBenefitAdvancedAiRecommendations =>
      'Recommandations IA avancées';

  @override
  String get subscriptionBenefitSearchByBudgetLocationHistory =>
      'Recherche par budget, lieu et historique';

  @override
  String get subscriptionBenefitPriorityMatchingResults =>
      'Résultats de correspondance prioritaires';

  @override
  String get subscriptionNoThanksMaybeLater => 'Non merci, plus tard';

  @override
  String subscriptionPleaseWaitSeconds(String value1) {
    return 'Veuillez patienter $value1 secondes...';
  }

  @override
  String get chatPhotoReplyPlaceholder => '📷 Photo';

  @override
  String get chatMuteConversation => 'Mettre la conversation en sourdine';

  @override
  String get chatUnmuteConversation => 'Réactiver le son de la conversation';

  @override
  String get chatConversationMuted => 'Conversation mise en sourdine';

  @override
  String get chatConversationUnmuted => 'Son de la conversation réactivé';

  @override
  String get chatTyping => 'est en train d\'écrire…';

  @override
  String chatLastSeen(String value1) {
    return 'Vu pour la dernière fois $value1';
  }

  @override
  String get chatReasonSpam => 'Spam';

  @override
  String get chatReasonHarassmentBullying => 'Harcèlement ou intimidation';

  @override
  String get chatReasonInappropriateContent => 'Contenu inapproprié';

  @override
  String get chatReasonScamFraud => 'Arnaque ou fraude';

  @override
  String get chatReasonFakeProfile => 'Faux profil';

  @override
  String get chatReasonOther => 'Autre';

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
  String get tsEvidenceLinkOptional => 'Lien de preuve (facultatif)';

  @override
  String get tsInvalidHttpUrl => 'Saisissez une URL http ou https valide.';

  @override
  String get myTsMyReportsTitle => 'Mes signalements';

  @override
  String get myTsMyReportsActionSubtitle => 'Signalements que vous avez soumis';

  @override
  String get myTsReportsEmptyTitle => 'Aucun signalement pour le moment';

  @override
  String get myTsReportsEmptyMessage =>
      'Les signalements que vous soumettez à propos d\'autres utilisateurs apparaîtront ici.';

  @override
  String get myTsReportsLoadError =>
      'Impossible de charger vos signalements. Tirez vers le bas pour réessayer.';

  @override
  String get myTsCategoryLabel => 'Catégorie';

  @override
  String get myTsSubmittedLabel => 'Soumis';

  @override
  String get myTsStatusLabel => 'Statut';

  @override
  String get myTsOutcomeLabel => 'Résultat';

  @override
  String get myTsYourDescriptionLabel => 'Votre description';

  @override
  String get myTsOutcomePending => 'Notre équipe n\'a pas encore examiné ceci.';

  @override
  String get myTsOutcomeReviewedNoAction =>
      'Examiné — aucune autre action n\'était nécessaire.';

  @override
  String get myTsOutcomeActionTaken =>
      'Examiné — une action a été prise suite à votre signalement.';

  @override
  String get myTsOutcomeDismissed =>
      'Examiné — aucune infraction n\'a été constatée.';

  @override
  String get myTsAccountStatusTitle => 'Statut du compte';

  @override
  String get myTsAccountStatusActionSubtitle =>
      'Avertissements, restrictions et suspensions';

  @override
  String get myTsGoodStandingTitle => 'Aucune restriction active';

  @override
  String get myTsGoodStandingMessage => 'Votre compte est en règle.';

  @override
  String get myTsStatusLoadError =>
      'Impossible de charger le statut de votre compte. Tirez vers le bas pour réessayer.';

  @override
  String get myTsStartTimeLabel => 'Heure de début';

  @override
  String get myTsExpirationTimeLabel => 'Heure d\'expiration';

  @override
  String get myTsAffectedFeatureLabel => 'Fonctionnalité concernée';

  @override
  String get myTsFeatureMessaging => 'Messagerie';

  @override
  String get myTsFeatureBooking => 'Réservations';

  @override
  String get myTsWarningInfoNote =>
      'Ceci est seulement un avertissement. Il ne restreint pas votre compte, mais des infractions répétées peuvent entraîner d\'autres mesures.';

  @override
  String get myTsAppealAvailableNote =>
      'Vous pouvez faire appel de cette décision.';

  @override
  String get myTsAppealButtonLabel => 'Faire appel de cette décision';

  @override
  String get myTsAppealPendingNote => 'Votre appel est en attente d\'examen.';

  @override
  String get myTsMyAppealsTitle => 'Mes appels';

  @override
  String get myTsMyAppealsEmpty => 'Vous n\'avez soumis aucun appel.';

  @override
  String get myTsAppealsLoadError =>
      'Impossible de charger vos appels. Tirez vers le bas pour réessayer.';

  @override
  String get myTsAppealDecidedNote => 'Cet appel a été tranché.';

  @override
  String get myTsSubmitAppealTitle => 'Faire appel de cette décision';

  @override
  String get myTsAppealReasonLabel =>
      'Pourquoi cela devrait-il être réexaminé ?';

  @override
  String get myTsAppealReasonHint =>
      'Expliquez pourquoi vous pensez que cette décision devrait être reconsidérée';

  @override
  String get myTsAppealReasonRequired =>
      'Veuillez expliquer pourquoi cela devrait être réexaminé.';

  @override
  String get myTsAppealSubmitCta => 'Soumettre l\'appel';

  @override
  String get myTsAppealSubmitSuccess => 'Votre appel a été soumis.';

  @override
  String get myTsAppealSubmitError =>
      'Impossible de soumettre votre appel. Réessayez.';

  @override
  String get myTsAppealAlreadyPending =>
      'Vous avez déjà un appel en attente pour ceci.';

  @override
  String get myTsAppealNotEligible =>
      'Cette action ne peut plus faire l\'objet d\'un appel.';

  @override
  String myTsAppealForLabel(String action) {
    return 'Appel concernant $action';
  }
}
