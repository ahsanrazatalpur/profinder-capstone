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
  String get chatReasonOther => 'Autre';
}
