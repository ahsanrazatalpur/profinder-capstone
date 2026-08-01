import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ur'),
  ];

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// App name — usually kept untranslated across locales
  ///
  /// In en, this message translates to:
  /// **'ProFinder'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Find Trusted Professionals Near You'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get hasAccount;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Register as'**
  String get selectRole;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @findProfessional.
  ///
  /// In en, this message translates to:
  /// **'Find a Professional'**
  String get findProfessional;

  /// No description provided for @nearbyProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Nearby Professionals'**
  String get nearbyProfessionals;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @aiSearch.
  ///
  /// In en, this message translates to:
  /// **'AI Search'**
  String get aiSearch;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a service...'**
  String get searchHint;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get experience;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (USD)'**
  String get hourlyRate;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerified;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get serverError;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get invalidPassword;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @invalidLoginCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get invalidLoginCredentials;

  /// No description provided for @forgotPasswordGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account exists with this email, we\'ve sent a password reset link.'**
  String get forgotPasswordGenericMessage;

  /// No description provided for @requestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please check your connection and try again.'**
  String get requestTimedOut;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show here'**
  String get noData;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Title on the first-launch language selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Your Language'**
  String get selectLanguageTitle;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you\'d like to use in ProFinder'**
  String get selectLanguageSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @languageChangeNote.
  ///
  /// In en, this message translates to:
  /// **'You can change your language anytime from Settings.'**
  String get languageChangeNote;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Booking updates, messages & offers'**
  String get pushNotificationsSubtitle;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @emailNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts & account activity'**
  String get emailNotificationsSubtitle;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This needs to go through our support team for verification. Contact Help & Support to proceed.'**
  String get deleteAccountMessage;

  /// Placeholder shown for settings not yet implemented
  ///
  /// In en, this message translates to:
  /// **'{feature} is coming soon'**
  String comingSoon(String feature);

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue.'**
  String get loginWelcomeBack;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @unknownRoleContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Unknown role. Please contact support.'**
  String get unknownRoleContactSupport;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinProFinderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join ProFinder and connect with professionals.'**
  String get joinProFinderSubtitle;

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose Account Type'**
  String get chooseAccountType;

  /// No description provided for @customerRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Hire trusted professionals.'**
  String get customerRoleDescription;

  /// No description provided for @professionalRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Offer your services and grow your business.'**
  String get professionalRoleDescription;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @selectCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get selectCountryHint;

  /// No description provided for @searchCountriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
  String get searchCountriesHint;

  /// No description provided for @noCountriesFound.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get noCountriesFound;

  /// No description provided for @selectCountryValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select your country'**
  String get selectCountryValidation;

  /// No description provided for @selectCityHint.
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get selectCityHint;

  /// No description provided for @selectACountryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a country first'**
  String get selectACountryFirst;

  /// No description provided for @searchCitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Search cities...'**
  String get searchCitiesHint;

  /// No description provided for @noCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get noCitiesFound;

  /// No description provided for @selectCityValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select your city'**
  String get selectCityValidation;

  /// No description provided for @yourProfessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Profession'**
  String get yourProfessionLabel;

  /// No description provided for @selectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select your category'**
  String get selectCategoryHint;

  /// No description provided for @searchProfessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Search professions...'**
  String get searchProfessionsHint;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @selectProfessionValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select your profession'**
  String get selectProfessionValidation;

  /// No description provided for @selectProfessionCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select your profession category.'**
  String get selectProfessionCategoryError;

  /// No description provided for @passwordMinCharsHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get passwordMinCharsHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @capsLockOnHint.
  ///
  /// In en, this message translates to:
  /// **'Caps Lock is on'**
  String get capsLockOnHint;

  /// No description provided for @emailAvailable.
  ///
  /// In en, this message translates to:
  /// **'Email available'**
  String get emailAvailable;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyRegistered;

  /// No description provided for @signInInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign In Instead'**
  String get signInInstead;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @facebookLabel.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebookLabel;

  /// No description provided for @twitterLabel.
  ///
  /// In en, this message translates to:
  /// **'X (Twitter)'**
  String get twitterLabel;

  /// No description provided for @forgotPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email. We will send a password reset link.'**
  String get forgotPasswordInstructions;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// No description provided for @checkSpamFolderHint.
  ///
  /// In en, this message translates to:
  /// **'If it doesn\'t arrive in a few minutes, check your spam folder or try again.'**
  String get checkSpamFolderHint;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @adminAvgRatingTotal.
  ///
  /// In en, this message translates to:
  /// **'Avg rating: {value1} ★ · {value2} total'**
  String adminAvgRatingTotal(String value1, String value2);

  /// No description provided for @adminBy.
  ///
  /// In en, this message translates to:
  /// **'by {value1}'**
  String adminBy(String value1);

  /// No description provided for @adminDeleteReview.
  ///
  /// In en, this message translates to:
  /// **'Delete Review'**
  String get adminDeleteReview;

  /// No description provided for @adminPermanentlyRemovesReviewProvideReasonAudit.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the review. Provide a reason for the audit log.'**
  String get adminPermanentlyRemovesReviewProvideReasonAudit;

  /// No description provided for @adminFailedDeleteReview.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete review.'**
  String get adminFailedDeleteReview;

  /// No description provided for @adminNoReviewsFound.
  ///
  /// In en, this message translates to:
  /// **'No reviews found'**
  String get adminNoReviewsFound;

  /// No description provided for @adminFailedLoadReviews.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reviews'**
  String get adminFailedLoadReviews;

  /// No description provided for @adminSearchByProfessionalReviewer.
  ///
  /// In en, this message translates to:
  /// **'Search by professional or reviewer…'**
  String get adminSearchByProfessionalReviewer;

  /// No description provided for @adminReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get adminReasonRequired;

  /// No description provided for @adminPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get adminPayments;

  /// No description provided for @adminRsShown.
  ///
  /// In en, this message translates to:
  /// **'Rs {value1} shown'**
  String adminRsShown(String value1);

  /// No description provided for @adminRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get adminRefund;

  /// No description provided for @adminTxn.
  ///
  /// In en, this message translates to:
  /// **'Txn: {value1}'**
  String adminTxn(String value1);

  /// No description provided for @adminRefundPayment.
  ///
  /// In en, this message translates to:
  /// **'Refund Payment'**
  String get adminRefundPayment;

  /// No description provided for @adminRefundRs.
  ///
  /// In en, this message translates to:
  /// **'Refund Rs {value1} to {value2}?'**
  String adminRefundRs(String value1, String value2);

  /// No description provided for @adminPaymentRefunded.
  ///
  /// In en, this message translates to:
  /// **'Payment refunded.'**
  String get adminPaymentRefunded;

  /// No description provided for @adminRefundFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund failed.'**
  String get adminRefundFailed;

  /// No description provided for @adminNoPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No payments found'**
  String get adminNoPaymentsFound;

  /// No description provided for @adminFailedLoadPayments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load payments'**
  String get adminFailedLoadPayments;

  /// No description provided for @adminSearchByNameEmailTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or transaction ID…'**
  String get adminSearchByNameEmailTransactionId;

  /// No description provided for @adminBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get adminBlockedUsers;

  /// No description provided for @adminCurrentlyBlocked.
  ///
  /// In en, this message translates to:
  /// **'{value1} currently blocked'**
  String adminCurrentlyBlocked(String value1);

  /// No description provided for @adminUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get adminUnblock;

  /// No description provided for @adminUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock user?'**
  String get adminUnblockUser;

  /// No description provided for @adminRestoreAccessTheyAbleLogAgain.
  ///
  /// In en, this message translates to:
  /// **'This will restore access for {value1}. They will be able to log in again.'**
  String adminRestoreAccessTheyAbleLogAgain(String value1);

  /// No description provided for @adminHasBeenUnblocked.
  ///
  /// In en, this message translates to:
  /// **'{value1} has been unblocked.'**
  String adminHasBeenUnblocked(String value1);

  /// No description provided for @adminFailedUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock user.'**
  String get adminFailedUnblockUser;

  /// No description provided for @adminNoBlockedUsersAllClear.
  ///
  /// In en, this message translates to:
  /// **'No blocked users — all clear! 🎉'**
  String get adminNoBlockedUsersAllClear;

  /// No description provided for @adminFailedLoadBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blocked users'**
  String get adminFailedLoadBlockedUsers;

  /// No description provided for @adminSearchByNameEmailReason.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or reason…'**
  String get adminSearchByNameEmailReason;

  /// No description provided for @adminExportProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Export ({value1} professionals)'**
  String adminExportProfessionals(String value1);

  /// No description provided for @adminClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get adminClose;

  /// No description provided for @adminCopyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get adminCopyClipboard;

  /// No description provided for @adminProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Professionals'**
  String get adminProfessionals;

  /// No description provided for @adminRatingHighLow.
  ///
  /// In en, this message translates to:
  /// **'Rating (High-Low)'**
  String get adminRatingHighLow;

  /// No description provided for @adminMostBookings.
  ///
  /// In en, this message translates to:
  /// **'Most Bookings'**
  String get adminMostBookings;

  /// No description provided for @adminNameZ.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get adminNameZ;

  /// No description provided for @adminNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get adminNewestFirst;

  /// No description provided for @adminSelected.
  ///
  /// In en, this message translates to:
  /// **'{value1} selected'**
  String adminSelected(String value1);

  /// No description provided for @adminVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get adminVerify;

  /// No description provided for @adminRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get adminRemind;

  /// No description provided for @adminExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get adminExport;

  /// No description provided for @adminFailedLoadProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Failed to load professionals'**
  String get adminFailedLoadProfessionals;

  /// No description provided for @adminSearchByNameEmailCategory.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, category…'**
  String get adminSearchByNameEmailCategory;

  /// No description provided for @adminSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get adminSort;

  /// No description provided for @adminRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get adminRefresh;

  /// No description provided for @adminVerifyProfessional.
  ///
  /// In en, this message translates to:
  /// **'Verify Professional?'**
  String get adminVerifyProfessional;

  /// No description provided for @adminVerifyProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Verify {value1} professionals?'**
  String adminVerifyProfessionals(String value1);

  /// No description provided for @adminGetVerifiedBadgeVisibleAllCustomers.
  ///
  /// In en, this message translates to:
  /// **'{value1} will get a verified badge visible to all customers.'**
  String adminGetVerifiedBadgeVisibleAllCustomers(String value1);

  /// No description provided for @adminAllSelectedProfessionalsGetVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'All selected professionals will get a verified badge.'**
  String get adminAllSelectedProfessionalsGetVerifiedBadge;

  /// No description provided for @adminProfinderAdmin.
  ///
  /// In en, this message translates to:
  /// **'ProFinder Admin'**
  String get adminProfinderAdmin;

  /// No description provided for @adminAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminAdminPanel;

  /// No description provided for @adminMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get adminMore;

  /// No description provided for @adminLogout2.
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get adminLogout2;

  /// No description provided for @adminLoggedOutAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'You will be logged out of the admin panel.'**
  String get adminLoggedOutAdminPanel;

  /// No description provided for @adminAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get adminAnalytics;

  /// No description provided for @adminD.
  ///
  /// In en, this message translates to:
  /// **'{value1}D'**
  String adminD(String value1);

  /// No description provided for @adminRs.
  ///
  /// In en, this message translates to:
  /// **'Rs {value1}'**
  String adminRs(String value1);

  /// No description provided for @adminLastDays.
  ///
  /// In en, this message translates to:
  /// **'last {value1} days'**
  String adminLastDays(String value1);

  /// No description provided for @adminLast12Months.
  ///
  /// In en, this message translates to:
  /// **'last 12 months'**
  String get adminLast12Months;

  /// No description provided for @adminDailyBookings.
  ///
  /// In en, this message translates to:
  /// **'Daily Bookings'**
  String get adminDailyBookings;

  /// No description provided for @adminMonthlyBookings12mo.
  ///
  /// In en, this message translates to:
  /// **'Monthly Bookings (12mo)'**
  String get adminMonthlyBookings12mo;

  /// No description provided for @adminTopSearches.
  ///
  /// In en, this message translates to:
  /// **'Top Searches'**
  String get adminTopSearches;

  /// No description provided for @adminNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get adminNoDataYet;

  /// No description provided for @adminFailedLoadAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics'**
  String get adminFailedLoadAnalytics;

  /// No description provided for @adminCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get adminCountries;

  /// No description provided for @adminTopCities.
  ///
  /// In en, this message translates to:
  /// **'Top Cities'**
  String get adminTopCities;

  /// No description provided for @adminTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get adminTopCategories;

  /// No description provided for @adminActivityLogs.
  ///
  /// In en, this message translates to:
  /// **'Activity Logs'**
  String get adminActivityLogs;

  /// No description provided for @adminLogs.
  ///
  /// In en, this message translates to:
  /// **'{value1} logs'**
  String adminLogs(String value1);

  /// No description provided for @adminTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {value1}'**
  String adminTotal(String value1);

  /// No description provided for @adminAdminActionsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Admin actions will appear here'**
  String get adminAdminActionsAppearHere;

  /// No description provided for @adminFailedLoadLogs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load logs'**
  String get adminFailedLoadLogs;

  /// No description provided for @adminSearchByAdminTargetUser.
  ///
  /// In en, this message translates to:
  /// **'Search by admin or target user…'**
  String get adminSearchByAdminTargetUser;

  /// No description provided for @adminClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get adminClearAll;

  /// No description provided for @adminDeleteLog.
  ///
  /// In en, this message translates to:
  /// **'Delete this log?'**
  String get adminDeleteLog;

  /// No description provided for @adminClearAllLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear All Logs?'**
  String get adminClearAllLogs;

  /// No description provided for @adminActionCannotUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get adminActionCannotUndone;

  /// No description provided for @adminAllActivityLogsPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'All {value1} activity logs will be permanently deleted.'**
  String adminAllActivityLogsPermanentlyDeleted(String value1);

  /// No description provided for @adminWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {value1} 👋'**
  String adminWelcome(String value1);

  /// No description provided for @adminCustomersProfessionals.
  ///
  /// In en, this message translates to:
  /// **'{value1} customers · {value2} professionals'**
  String adminCustomersProfessionals(String value1, String value2);

  /// No description provided for @adminSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get adminSearch;

  /// No description provided for @adminGlobalSearchUiReadyConnectUsers.
  ///
  /// In en, this message translates to:
  /// **'Global search UI is ready — will connect to Users/Bookings once that module is rebuilt.'**
  String get adminGlobalSearchUiReadyConnectUsers;

  /// No description provided for @adminReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get adminReview;

  /// No description provided for @adminFailedLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get adminFailedLoadDashboard;

  /// No description provided for @adminSearchUsersProfessionalsBookings.
  ///
  /// In en, this message translates to:
  /// **'Search users, professionals, bookings…'**
  String get adminSearchUsersProfessionalsBookings;

  /// No description provided for @adminTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get adminTotalUsers;

  /// No description provided for @adminCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get adminCustomers;

  /// No description provided for @adminRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get adminRevenue;

  /// No description provided for @adminTodaySBookings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Bookings'**
  String get adminTodaySBookings;

  /// No description provided for @adminPendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get adminPendingVerification;

  /// No description provided for @adminReportedUsers.
  ///
  /// In en, this message translates to:
  /// **'Reported Users'**
  String get adminReportedUsers;

  /// No description provided for @adminExportUsers.
  ///
  /// In en, this message translates to:
  /// **'Export ({value1} users)'**
  String adminExportUsers(String value1);

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminNameZ2.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get adminNameZ2;

  /// No description provided for @adminOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get adminOldestFirst;

  /// No description provided for @adminShown.
  ///
  /// In en, this message translates to:
  /// **'{value1} shown'**
  String adminShown(String value1);

  /// No description provided for @adminBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get adminBlock;

  /// No description provided for @adminJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {value1}'**
  String adminJoined(String value1);

  /// No description provided for @adminFailedLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get adminFailedLoadUsers;

  /// No description provided for @adminSearchByNameEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email…'**
  String get adminSearchByNameEmail;

  /// No description provided for @adminFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update.'**
  String get adminFailedUpdate;

  /// No description provided for @adminFailedDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete.'**
  String get adminFailedDelete;

  /// No description provided for @adminAddCountry.
  ///
  /// In en, this message translates to:
  /// **'Add Country'**
  String get adminAddCountry;

  /// No description provided for @adminFailedAddMayAlreadyExist.
  ///
  /// In en, this message translates to:
  /// **'Failed to add — may already exist.'**
  String get adminFailedAddMayAlreadyExist;

  /// No description provided for @adminAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminAdd;

  /// No description provided for @adminMergeInto.
  ///
  /// In en, this message translates to:
  /// **'Merge into \"{value1}\"'**
  String adminMergeInto(String value1);

  /// No description provided for @adminEnterTypoVariantSpellingsFoundUser.
  ///
  /// In en, this message translates to:
  /// **'Enter typo/variant spellings found in user profiles, comma-separated (e.g. pakistan, Pakistn).'**
  String get adminEnterTypoVariantSpellingsFoundUser;

  /// No description provided for @adminMergeFailed.
  ///
  /// In en, this message translates to:
  /// **'Merge failed.'**
  String get adminMergeFailed;

  /// No description provided for @adminMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get adminMerge;

  /// No description provided for @adminActive.
  ///
  /// In en, this message translates to:
  /// **'{value1} active'**
  String adminActive(String value1);

  /// No description provided for @adminViewCities.
  ///
  /// In en, this message translates to:
  /// **'View Cities'**
  String get adminViewCities;

  /// No description provided for @adminNoCountriesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No countries added yet'**
  String get adminNoCountriesAddedYet;

  /// No description provided for @adminFailedLoadCountries.
  ///
  /// In en, this message translates to:
  /// **'Failed to load countries'**
  String get adminFailedLoadCountries;

  /// No description provided for @adminCountryName.
  ///
  /// In en, this message translates to:
  /// **'Country name'**
  String get adminCountryName;

  /// No description provided for @adminVariant1Variant2.
  ///
  /// In en, this message translates to:
  /// **'variant1, variant2, ...'**
  String get adminVariant1Variant2;

  /// No description provided for @adminRevenueByCategory.
  ///
  /// In en, this message translates to:
  /// **'Revenue by Category'**
  String get adminRevenueByCategory;

  /// No description provided for @adminVsPreviousDays.
  ///
  /// In en, this message translates to:
  /// **'{value1}% vs previous {value2} days'**
  String adminVsPreviousDays(String value1, String value2);

  /// No description provided for @adminNoCategoryDataYet.
  ///
  /// In en, this message translates to:
  /// **'No category data yet'**
  String get adminNoCategoryDataYet;

  /// No description provided for @adminRs2.
  ///
  /// In en, this message translates to:
  /// **'Rs {value1} ({value2})'**
  String adminRs2(String value1, String value2);

  /// No description provided for @adminFailedLoadRevenueData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load revenue data'**
  String get adminFailedLoadRevenueData;

  /// No description provided for @adminDeleteBanner.
  ///
  /// In en, this message translates to:
  /// **'Delete this banner?'**
  String get adminDeleteBanner;

  /// No description provided for @adminPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{value1}\" will be permanently deleted.'**
  String adminPermanentlyDeleted(String value1);

  /// No description provided for @adminPreviewMode.
  ///
  /// In en, this message translates to:
  /// **'👁 PREVIEW MODE'**
  String get adminPreviewMode;

  /// No description provided for @adminActive2.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminActive2;

  /// No description provided for @adminTurningOffHidesBannerFromEveryone.
  ///
  /// In en, this message translates to:
  /// **'Turning this off hides the banner from everyone'**
  String get adminTurningOffHidesBannerFromEveryone;

  /// No description provided for @adminPromoBanners.
  ///
  /// In en, this message translates to:
  /// **'Promo Banners'**
  String get adminPromoBanners;

  /// No description provided for @adminFailedLoadBanners.
  ///
  /// In en, this message translates to:
  /// **'Failed to load banners'**
  String get adminFailedLoadBanners;

  /// No description provided for @adminNoBannersYet.
  ///
  /// In en, this message translates to:
  /// **'No banners yet'**
  String get adminNoBannersYet;

  /// No description provided for @adminTapCreateNewBanner.
  ///
  /// In en, this message translates to:
  /// **'Tap \"+\" to create a new banner'**
  String get adminTapCreateNewBanner;

  /// No description provided for @adminPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get adminPreview;

  /// No description provided for @adminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEdit;

  /// No description provided for @adminFailedGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate report.'**
  String get adminFailedGenerateReport;

  /// No description provided for @adminNoDataRange.
  ///
  /// In en, this message translates to:
  /// **'No data in this range.'**
  String get adminNoDataRange;

  /// No description provided for @adminCopiedClipboardStyleExportCsvReady.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard-style export (CSV) — ready to share.'**
  String get adminCopiedClipboardStyleExportCsvReady;

  /// No description provided for @adminExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get adminExportCsv;

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminQuickGenerate.
  ///
  /// In en, this message translates to:
  /// **'Quick Generate'**
  String get adminQuickGenerate;

  /// No description provided for @adminLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get adminLast30Days;

  /// No description provided for @adminGenerationHistory.
  ///
  /// In en, this message translates to:
  /// **'Generation History'**
  String get adminGenerationHistory;

  /// No description provided for @adminNoReportsGeneratedYetSession.
  ///
  /// In en, this message translates to:
  /// **'No reports generated yet this session.'**
  String get adminNoReportsGeneratedYetSession;

  /// No description provided for @adminRows.
  ///
  /// In en, this message translates to:
  /// **'{value1} rows · {value2}'**
  String adminRows(String value1, String value2);

  /// No description provided for @adminProsBookingsSubcategories.
  ///
  /// In en, this message translates to:
  /// **'{value1} pros · {value2} bookings · {value3} subcategories'**
  String adminProsBookingsSubcategories(
    String value1,
    String value2,
    String value3,
  );

  /// No description provided for @adminFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get adminFeatured;

  /// No description provided for @adminShowGuestHomeSFeaturedCategories.
  ///
  /// In en, this message translates to:
  /// **'Show on Guest Home\'s Featured Categories (max 6)'**
  String get adminShowGuestHomeSFeaturedCategories;

  /// No description provided for @adminAddSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Add Subcategory'**
  String get adminAddSubcategory;

  /// No description provided for @adminFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get adminFailedLoad;

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminName;

  /// No description provided for @adminIconOptional.
  ///
  /// In en, this message translates to:
  /// **'Icon (optional)'**
  String get adminIconOptional;

  /// No description provided for @adminParentCategory.
  ///
  /// In en, this message translates to:
  /// **'Parent Category'**
  String get adminParentCategory;

  /// No description provided for @adminAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get adminAddNew;

  /// No description provided for @adminCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription?'**
  String get adminCancelSubscription;

  /// No description provided for @adminCancelSSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel {value1}\'s {value2} subscription?'**
  String adminCancelSSubscription(String value1, String value2);

  /// No description provided for @adminNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get adminNo;

  /// No description provided for @adminCancelSubscription2.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get adminCancelSubscription2;

  /// No description provided for @adminFailedCancel.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel.'**
  String get adminFailedCancel;

  /// No description provided for @adminExtendedBy30Days.
  ///
  /// In en, this message translates to:
  /// **'Extended by 30 days.'**
  String get adminExtendedBy30Days;

  /// No description provided for @adminFailedExtend.
  ///
  /// In en, this message translates to:
  /// **'Failed to extend.'**
  String get adminFailedExtend;

  /// No description provided for @adminSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get adminSubscriptions;

  /// No description provided for @adminRs3.
  ///
  /// In en, this message translates to:
  /// **'{value1} · Rs {value2}/{value3}'**
  String adminRs3(String value1, String value2, String value3);

  /// No description provided for @adminRenews.
  ///
  /// In en, this message translates to:
  /// **'Renews: {value1}'**
  String adminRenews(String value1);

  /// No description provided for @adminExtend30d.
  ///
  /// In en, this message translates to:
  /// **'Extend 30d'**
  String get adminExtend30d;

  /// No description provided for @adminNoSubscriptionsFound.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions found'**
  String get adminNoSubscriptionsFound;

  /// No description provided for @adminFailedLoadSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscriptions'**
  String get adminFailedLoadSubscriptions;

  /// No description provided for @adminExportCustomers.
  ///
  /// In en, this message translates to:
  /// **'Export ({value1} customers)'**
  String adminExportCustomers(String value1);

  /// No description provided for @adminTotalSpentHighLow.
  ///
  /// In en, this message translates to:
  /// **'Total Spent (High-Low)'**
  String get adminTotalSpentHighLow;

  /// No description provided for @adminFailedLoadCustomers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customers'**
  String get adminFailedLoadCustomers;

  /// No description provided for @adminAddLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add Language'**
  String get adminAddLanguage;

  /// No description provided for @adminRightLeftRtl.
  ///
  /// In en, this message translates to:
  /// **'Right-to-left (RTL)'**
  String get adminRightLeftRtl;

  /// No description provided for @adminFailedAddCodeMayAlreadyExist.
  ///
  /// In en, this message translates to:
  /// **'Failed to add — code may already exist.'**
  String get adminFailedAddCodeMayAlreadyExist;

  /// No description provided for @adminFailedUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status.'**
  String get adminFailedUpdateStatus;

  /// No description provided for @adminChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get adminChangeStatus;

  /// No description provided for @adminDeleteLanguage.
  ///
  /// In en, this message translates to:
  /// **'Delete language?'**
  String get adminDeleteLanguage;

  /// No description provided for @adminPermanentlyRemoveAllItsTranslations.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove \"{value1}\" and all its translations.'**
  String adminPermanentlyRemoveAllItsTranslations(String value1);

  /// No description provided for @adminFailedDeleteLanguage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete language.'**
  String get adminFailedDeleteLanguage;

  /// No description provided for @adminLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get adminLanguages;

  /// No description provided for @adminActiveTotal.
  ///
  /// In en, this message translates to:
  /// **'{value1} active · {value2} total'**
  String adminActiveTotal(String value1, String value2);

  /// No description provided for @adminRtl.
  ///
  /// In en, this message translates to:
  /// **'RTL'**
  String get adminRtl;

  /// No description provided for @adminEditTranslations.
  ///
  /// In en, this message translates to:
  /// **'Edit Translations'**
  String get adminEditTranslations;

  /// No description provided for @adminNoLanguagesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No languages added yet'**
  String get adminNoLanguagesAddedYet;

  /// No description provided for @adminFailedLoadLanguages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load languages'**
  String get adminFailedLoadLanguages;

  /// No description provided for @adminLanguageNameEGUrdu.
  ///
  /// In en, this message translates to:
  /// **'Language name (e.g. Urdu)'**
  String get adminLanguageNameEGUrdu;

  /// No description provided for @adminCodeEGUr.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. ur)'**
  String get adminCodeEGUr;

  /// No description provided for @adminDeleteArticle.
  ///
  /// In en, this message translates to:
  /// **'Delete article?'**
  String get adminDeleteArticle;

  /// No description provided for @adminNewArticle.
  ///
  /// In en, this message translates to:
  /// **'New Article'**
  String get adminNewArticle;

  /// No description provided for @adminTipsMagazine.
  ///
  /// In en, this message translates to:
  /// **'Tips Magazine'**
  String get adminTipsMagazine;

  /// No description provided for @adminNoArticlesHereYet.
  ///
  /// In en, this message translates to:
  /// **'No articles here yet.'**
  String get adminNoArticlesHereYet;

  /// No description provided for @adminMinReadViews.
  ///
  /// In en, this message translates to:
  /// **'{value1} min read · {value2} views'**
  String adminMinReadViews(String value1, String value2);

  /// No description provided for @adminSelect.
  ///
  /// In en, this message translates to:
  /// **'Select…'**
  String get adminSelect;

  /// No description provided for @adminManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get adminManageCategories;

  /// No description provided for @adminNoCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get adminNoCategoriesYet;

  /// No description provided for @adminArticles.
  ///
  /// In en, this message translates to:
  /// **'{value1} articles'**
  String adminArticles(String value1);

  /// No description provided for @adminAddNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get adminAddNewCategory;

  /// No description provided for @adminAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get adminAddCategory;

  /// No description provided for @adminCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get adminCategoryName;

  /// No description provided for @adminNoChangesSave.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get adminNoChangesSave;

  /// No description provided for @adminFailedSaveTranslations.
  ///
  /// In en, this message translates to:
  /// **'Failed to save translations.'**
  String get adminFailedSaveTranslations;

  /// No description provided for @adminAddTranslationKey.
  ///
  /// In en, this message translates to:
  /// **'Add Translation Key'**
  String get adminAddTranslationKey;

  /// No description provided for @adminFailedAddKeyMayAlreadyExist.
  ///
  /// In en, this message translates to:
  /// **'Failed to add — key may already exist.'**
  String get adminFailedAddKeyMayAlreadyExist;

  /// No description provided for @adminDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get adminDiscardChanges;

  /// No description provided for @adminHaveUnsavedTranslationS.
  ///
  /// In en, this message translates to:
  /// **'You have {value1} unsaved translation(s).'**
  String adminHaveUnsavedTranslationS(String value1);

  /// No description provided for @adminKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get adminKeepEditing;

  /// No description provided for @adminDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get adminDiscard;

  /// No description provided for @adminAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add Key'**
  String get adminAddKey;

  /// No description provided for @adminTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate — {value1}'**
  String adminTranslate(String value1);

  /// No description provided for @adminKeysUnsaved.
  ///
  /// In en, this message translates to:
  /// **'{value1} keys · {value2} unsaved'**
  String adminKeysUnsaved(String value1, String value2);

  /// No description provided for @adminMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get adminMissing;

  /// No description provided for @adminNoTranslationKeysYet.
  ///
  /// In en, this message translates to:
  /// **'No translation keys yet'**
  String get adminNoTranslationKeysYet;

  /// No description provided for @adminTapAddKeyCreateFirstOne.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Key\" to create the first one.'**
  String get adminTapAddKeyCreateFirstOne;

  /// No description provided for @adminFailedLoadTranslations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load translations'**
  String get adminFailedLoadTranslations;

  /// No description provided for @adminKeyEGHomeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Key (e.g. home.welcome_title)'**
  String get adminKeyEGHomeWelcomeTitle;

  /// No description provided for @adminDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get adminDescriptionOptional;

  /// No description provided for @adminSearchKeys.
  ///
  /// In en, this message translates to:
  /// **'Search keys…'**
  String get adminSearchKeys;

  /// No description provided for @adminTranslatedText.
  ///
  /// In en, this message translates to:
  /// **'Translated text…'**
  String get adminTranslatedText;

  /// No description provided for @adminAddCity.
  ///
  /// In en, this message translates to:
  /// **'Add City to {value1}'**
  String adminAddCity(String value1);

  /// No description provided for @adminEnterTypoVariantSpellingsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Enter typo/variant spellings, comma-separated.'**
  String get adminEnterTypoVariantSpellingsCommaSeparated;

  /// No description provided for @adminAddCity2.
  ///
  /// In en, this message translates to:
  /// **'Add City'**
  String get adminAddCity2;

  /// No description provided for @adminNoCitiesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No cities added yet'**
  String get adminNoCitiesAddedYet;

  /// No description provided for @adminFailedLoadCities.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cities'**
  String get adminFailedLoadCities;

  /// No description provided for @adminCityName.
  ///
  /// In en, this message translates to:
  /// **'City name'**
  String get adminCityName;

  /// No description provided for @adminPendingReview.
  ///
  /// In en, this message translates to:
  /// **'{value1} pending review'**
  String adminPendingReview(String value1);

  /// No description provided for @adminBlocked.
  ///
  /// In en, this message translates to:
  /// **'BLOCKED'**
  String get adminBlocked;

  /// No description provided for @adminReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by {value1} ({value2})'**
  String adminReportedBy(String value1, String value2);

  /// No description provided for @adminFailedLoadReports.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reports'**
  String get adminFailedLoadReports;

  /// No description provided for @adminReportOn.
  ///
  /// In en, this message translates to:
  /// **'Report on {value1}'**
  String adminReportOn(String value1);

  /// No description provided for @adminAlsoBanUser.
  ///
  /// In en, this message translates to:
  /// **'Also ban this user'**
  String get adminAlsoBanUser;

  /// No description provided for @adminDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminDismiss;

  /// No description provided for @adminMarkReviewed.
  ///
  /// In en, this message translates to:
  /// **'Mark Reviewed'**
  String get adminMarkReviewed;

  /// No description provided for @adminTakeAction.
  ///
  /// In en, this message translates to:
  /// **'Take Action'**
  String get adminTakeAction;

  /// No description provided for @adminFailedUpdateReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to update report.'**
  String get adminFailedUpdateReport;

  /// No description provided for @adminSearchByUserReporterReason.
  ///
  /// In en, this message translates to:
  /// **'Search by user, reporter, or reason…'**
  String get adminSearchByUserReporterReason;

  /// No description provided for @adminAdminNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Admin note (optional)…'**
  String get adminAdminNoteOptional;

  /// No description provided for @adminPortfolioApproval.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Approval'**
  String get adminPortfolioApproval;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminAllPortfoliosReviewed.
  ///
  /// In en, this message translates to:
  /// **'All portfolios reviewed!'**
  String get adminAllPortfoliosReviewed;

  /// No description provided for @adminFailedLoadPortfolios.
  ///
  /// In en, this message translates to:
  /// **'Failed to load portfolios'**
  String get adminFailedLoadPortfolios;

  /// No description provided for @adminSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get adminSkip;

  /// No description provided for @adminWriteReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Write reason (optional)…'**
  String get adminWriteReasonOptional;

  /// No description provided for @adminApprovePortfolio.
  ///
  /// In en, this message translates to:
  /// **'Approve Portfolio?'**
  String get adminApprovePortfolio;

  /// No description provided for @adminVisibleAllCustomers.
  ///
  /// In en, this message translates to:
  /// **'\"{value1}\" will be visible to all customers.'**
  String adminVisibleAllCustomers(String value1);

  /// No description provided for @adminBookings2.
  ///
  /// In en, this message translates to:
  /// **'{value1} bookings'**
  String adminBookings2(String value1);

  /// No description provided for @adminCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {value1}'**
  String adminCreated(String value1);

  /// No description provided for @adminForceCancel.
  ///
  /// In en, this message translates to:
  /// **'Force Cancel'**
  String get adminForceCancel;

  /// No description provided for @adminFailedLoadBookings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bookings'**
  String get adminFailedLoadBookings;

  /// No description provided for @adminYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get adminYesCancel;

  /// No description provided for @adminSearchCustomerProfessional.
  ///
  /// In en, this message translates to:
  /// **'Search customer or professional…'**
  String get adminSearchCustomerProfessional;

  /// No description provided for @adminCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking #{value1}?'**
  String adminCancelBooking(String value1);

  /// No description provided for @adminReflectBothCustomerProfessional.
  ///
  /// In en, this message translates to:
  /// **'{value1} → {value2} This will reflect to both customer and professional.'**
  String adminReflectBothCustomerProfessional(String value1, String value2);

  /// No description provided for @adminVerificationRequests.
  ///
  /// In en, this message translates to:
  /// **'Verification Requests'**
  String get adminVerificationRequests;

  /// No description provided for @adminPendingOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'{value1} pending · oldest first'**
  String adminPendingOldestFirst(String value1);

  /// No description provided for @adminOldest.
  ///
  /// In en, this message translates to:
  /// **'OLDEST'**
  String get adminOldest;

  /// No description provided for @adminApproveVerification.
  ///
  /// In en, this message translates to:
  /// **'Approve verification?'**
  String get adminApproveVerification;

  /// No description provided for @adminMarkedAsVerifiedProfessional.
  ///
  /// In en, this message translates to:
  /// **'{value1} will be marked as a verified professional.'**
  String adminMarkedAsVerifiedProfessional(String value1);

  /// No description provided for @adminRejectSRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject {value1}\'s request?'**
  String adminRejectSRequest(String value1);

  /// No description provided for @adminReasonSentProfessionalSoTheyCan.
  ///
  /// In en, this message translates to:
  /// **'This reason will be sent to the professional so they can resubmit.'**
  String get adminReasonSentProfessionalSoTheyCan;

  /// No description provided for @adminFailedRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to {value1} request.'**
  String adminFailedRequest(String value1);

  /// No description provided for @adminNoPendingVerificationRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending verification requests 🎉'**
  String get adminNoPendingVerificationRequests;

  /// No description provided for @adminFailedLoadVerificationRequests.
  ///
  /// In en, this message translates to:
  /// **'Failed to load verification requests'**
  String get adminFailedLoadVerificationRequests;

  /// No description provided for @adminSearchByNameEmailCategory2.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or category…'**
  String get adminSearchByNameEmailCategory2;

  /// No description provided for @adminEGCnicImageBlurryPlease.
  ///
  /// In en, this message translates to:
  /// **'e.g. CNIC image is blurry, please re-upload…'**
  String get adminEGCnicImageBlurryPlease;

  /// No description provided for @adminFailedCancelItMayHaveAlready.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel — it may have already been sent.'**
  String get adminFailedCancelItMayHaveAlready;

  /// No description provided for @adminCompose.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get adminCompose;

  /// No description provided for @adminScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for: {value1}'**
  String adminScheduledFor(String value1);

  /// No description provided for @adminSentUsersOpenRate.
  ///
  /// In en, this message translates to:
  /// **'Sent to {value1} users · Open rate: {value2}%'**
  String adminSentUsersOpenRate(String value1, String value2);

  /// No description provided for @adminComposeNotification.
  ///
  /// In en, this message translates to:
  /// **'Compose Notification'**
  String get adminComposeNotification;

  /// No description provided for @adminAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get adminAudience;

  /// No description provided for @adminScheduleLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule for later'**
  String get adminScheduleLater;

  /// No description provided for @adminFailedSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification.'**
  String get adminFailedSendNotification;

  /// No description provided for @adminFailedLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get adminFailedLoadNotifications;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminTitle;

  /// No description provided for @adminMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get adminMessage;

  /// No description provided for @adminUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get adminUserId;

  /// No description provided for @adminDeleteAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Delete Announcement?'**
  String get adminDeleteAnnouncement;

  /// No description provided for @adminRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{value1}\"?'**
  String adminRemove(String value1);

  /// No description provided for @adminNewAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New Announcement'**
  String get adminNewAnnouncement;

  /// No description provided for @adminAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get adminAnnouncements;

  /// No description provided for @adminType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminType;

  /// No description provided for @adminFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create.'**
  String get adminFailedCreate;

  /// No description provided for @adminPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get adminPublish;

  /// No description provided for @adminNoAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get adminNoAnnouncementsYet;

  /// No description provided for @adminFailedLoadAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Failed to load announcements'**
  String get adminFailedLoadAnnouncements;

  /// No description provided for @adminMagazineAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Magazine Analytics'**
  String get adminMagazineAnalytics;

  /// No description provided for @adminViews.
  ///
  /// In en, this message translates to:
  /// **'{value1} views'**
  String adminViews(String value1);

  /// No description provided for @adminOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{value1}% of total'**
  String adminOfTotal(String value1);

  /// No description provided for @adminNoViewsYet.
  ///
  /// In en, this message translates to:
  /// **'No views yet.'**
  String get adminNoViewsYet;

  /// No description provided for @adminRecentViewers.
  ///
  /// In en, this message translates to:
  /// **'Recent Viewers'**
  String get adminRecentViewers;

  /// No description provided for @adminComplaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get adminComplaints;

  /// No description provided for @adminVs.
  ///
  /// In en, this message translates to:
  /// **'{value1} vs {value2}'**
  String adminVs(String value1, String value2);

  /// No description provided for @adminAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to: {value1}'**
  String adminAssignedTo(String value1);

  /// No description provided for @adminAssignMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to Me'**
  String get adminAssignMe;

  /// No description provided for @adminResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get adminResolve;

  /// No description provided for @adminFailedAssign.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign.'**
  String get adminFailedAssign;

  /// No description provided for @adminFailedLoadComplaints.
  ///
  /// In en, this message translates to:
  /// **'Failed to load complaints'**
  String get adminFailedLoadComplaints;

  /// No description provided for @adminResolutionNote.
  ///
  /// In en, this message translates to:
  /// **'Resolution note'**
  String get adminResolutionNote;

  /// No description provided for @authWelcomeProfinder.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ProFinder!'**
  String get authWelcomeProfinder;

  /// No description provided for @authPleaseVerifyEmailActivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email to activate your account.'**
  String get authPleaseVerifyEmailActivateAccount;

  /// No description provided for @authContinueLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue to Login'**
  String get authContinueLogin;

  /// No description provided for @profileNoPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get profileNoPaymentsYet;

  /// No description provided for @profileTransactionHistoryAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your transaction history will appear here'**
  String get profileTransactionHistoryAppearHere;

  /// No description provided for @profileWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get profileWallet;

  /// No description provided for @profileTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get profileTotalSpent;

  /// No description provided for @profileAcrossTransaction.
  ///
  /// In en, this message translates to:
  /// **'Across {value1} transaction{value2}'**
  String profileAcrossTransaction(String value1, String value2);

  /// No description provided for @profileCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan: {value1}'**
  String profileCurrentPlan(String value1);

  /// No description provided for @profilePaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get profilePaymentHistory;

  /// No description provided for @profileViewAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'View all your transactions'**
  String get profileViewAllTransactions;

  /// No description provided for @profileSavedProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Saved Professionals'**
  String get profileSavedProfessionals;

  /// No description provided for @profileNoSavedProfessionalsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved professionals yet'**
  String get profileNoSavedProfessionalsYet;

  /// No description provided for @profileTapHeartAnyProfessionalSaveThem.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any professional to save them here'**
  String get profileTapHeartAnyProfessionalSaveThem;

  /// No description provided for @profileHr.
  ///
  /// In en, this message translates to:
  /// **'{value1} • \${value2}/hr'**
  String profileHr(String value1, String value2);

  /// No description provided for @profileBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get profileBook;

  /// No description provided for @profileRemoveFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get profileRemoveFromSaved;

  /// No description provided for @profileChangeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get profileChangeProfilePhoto;

  /// No description provided for @profileChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profileChooseFromGallery;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get profileTakePhoto;

  /// No description provided for @profileMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileMyProfile;

  /// No description provided for @profileNewPhotoSelectedTapSaveUpload.
  ///
  /// In en, this message translates to:
  /// **'New photo selected — tap Save to upload'**
  String get profileNewPhotoSelectedTapSaveUpload;

  /// No description provided for @profilePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profilePersonalInformation;

  /// No description provided for @profileSureWantLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profileSureWantLogout;

  /// No description provided for @profileMyReviews.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get profileMyReviews;

  /// No description provided for @profileNoReviewsWrittenYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews written yet'**
  String get profileNoReviewsWrittenYet;

  /// No description provided for @profileCompleteBookingLeaveFirstReview.
  ///
  /// In en, this message translates to:
  /// **'Complete a booking to leave your first review'**
  String get profileCompleteBookingLeaveFirstReview;

  /// No description provided for @profileSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSecurity;

  /// No description provided for @profileWeLlEmailSecureResetLink.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email a secure reset link to {value1}.'**
  String profileWeLlEmailSecureResetLink(String value1);

  /// No description provided for @profileSignOutDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get profileSignOutDevice;

  /// No description provided for @profileHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupport;

  /// No description provided for @profileNeedHand.
  ///
  /// In en, this message translates to:
  /// **'Need a hand?'**
  String get profileNeedHand;

  /// No description provided for @profileReachOurSupportTeamAnytime.
  ///
  /// In en, this message translates to:
  /// **'Reach our support team anytime'**
  String get profileReachOurSupportTeamAnytime;

  /// No description provided for @profileFrequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get profileFrequentlyAskedQuestions;

  /// No description provided for @profileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{value1} is coming soon'**
  String profileComingSoon(String value1);

  /// No description provided for @profileBrowsingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'You are browsing as Guest'**
  String get profileBrowsingAsGuest;

  /// No description provided for @profileLoginBookSaveManageRequests.
  ///
  /// In en, this message translates to:
  /// **'Login to book, save & manage your requests'**
  String get profileLoginBookSaveManageRequests;

  /// No description provided for @profileProfinderV100.
  ///
  /// In en, this message translates to:
  /// **'ProFinder v1.0.0'**
  String get profileProfinderV100;

  /// No description provided for @profileAboutProfinder.
  ///
  /// In en, this message translates to:
  /// **'About ProFinder'**
  String get profileAboutProfinder;

  /// No description provided for @profileProfinderHelpsFindHireTrustedProfessionals.
  ///
  /// In en, this message translates to:
  /// **'ProFinder helps you find and hire trusted professionals — doctors, lawyers, tutors, engineers, plumbers and more — near you.'**
  String get profileProfinderHelpsFindHireTrustedProfessionals;

  /// No description provided for @profileAccessBookingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Access your bookings & profile'**
  String get profileAccessBookingsProfile;

  /// No description provided for @profileCreateFreeCustomerAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a free customer account'**
  String get profileCreateFreeCustomerAccount;

  /// No description provided for @profileBecomeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Become a Professional'**
  String get profileBecomeProfessional;

  /// No description provided for @profileListServicesGetHired.
  ///
  /// In en, this message translates to:
  /// **'List your services & get hired'**
  String get profileListServicesGetHired;

  /// No description provided for @profileEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileEnglish;

  /// No description provided for @profileComingSoon2.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get profileComingSoon2;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @searchNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get searchNoReviewsYet;

  /// No description provided for @searchFirstReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to review!'**
  String get searchFirstReview;

  /// No description provided for @searchNoPortfolioYet.
  ///
  /// In en, this message translates to:
  /// **'No portfolio yet'**
  String get searchNoPortfolioYet;

  /// No description provided for @searchProfessionalHasNoApprovedWorkYet.
  ///
  /// In en, this message translates to:
  /// **'This professional has no approved work yet'**
  String get searchProfessionalHasNoApprovedWorkYet;

  /// No description provided for @searchHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get searchHourlyRate;

  /// No description provided for @searchHr.
  ///
  /// In en, this message translates to:
  /// **'\${value1}/hr'**
  String searchHr(String value1);

  /// No description provided for @searchLoginBook.
  ///
  /// In en, this message translates to:
  /// **'Login to Book'**
  String get searchLoginBook;

  /// No description provided for @searchLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get searchLoginRequired;

  /// No description provided for @searchPleaseLoginUseAiSearch.
  ///
  /// In en, this message translates to:
  /// **'Please login to use AI Search.'**
  String get searchPleaseLoginUseAiSearch;

  /// No description provided for @searchSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchSearchHistory;

  /// No description provided for @searchNoSearchHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No search history yet'**
  String get searchNoSearchHistoryYet;

  /// No description provided for @searchPriceHr.
  ///
  /// In en, this message translates to:
  /// **'Price: \${value1} — \${value2}/hr'**
  String searchPriceHr(String value1, String value2);

  /// No description provided for @searchMinRating.
  ///
  /// In en, this message translates to:
  /// **'Min Rating: {value1} ★'**
  String searchMinRating(String value1);

  /// No description provided for @searchVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified Only'**
  String get searchVerifiedOnly;

  /// No description provided for @searchPreferredGender.
  ///
  /// In en, this message translates to:
  /// **'Preferred Gender'**
  String get searchPreferredGender;

  /// No description provided for @searchAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get searchAny;

  /// No description provided for @searchFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get searchFemale;

  /// No description provided for @searchMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get searchMale;

  /// No description provided for @searchMinExperienceYrs.
  ///
  /// In en, this message translates to:
  /// **'Min Experience: {value1}+ yrs'**
  String searchMinExperienceYrs(String value1);

  /// No description provided for @searchPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get searchPreferredLanguage;

  /// No description provided for @searchNeedSomeoneNowUrgent.
  ///
  /// In en, this message translates to:
  /// **'Need Someone Now / Urgent'**
  String get searchNeedSomeoneNowUrgent;

  /// No description provided for @searchServiceMode.
  ///
  /// In en, this message translates to:
  /// **'Service Mode'**
  String get searchServiceMode;

  /// No description provided for @searchOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get searchOnline;

  /// No description provided for @searchHomeVisit.
  ///
  /// In en, this message translates to:
  /// **'Home Visit'**
  String get searchHomeVisit;

  /// No description provided for @searchInOffice.
  ///
  /// In en, this message translates to:
  /// **'In Office'**
  String get searchInOffice;

  /// No description provided for @searchReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get searchReset;

  /// No description provided for @searchApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get searchApply;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{value1}\"'**
  String searchNoResults(String value1);

  /// No description provided for @searchHereSomeAlternativesMightLike.
  ///
  /// In en, this message translates to:
  /// **'Here are some alternatives you might like'**
  String get searchHereSomeAlternativesMightLike;

  /// No description provided for @searchClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get searchClearSearch;

  /// No description provided for @searchKm.
  ///
  /// In en, this message translates to:
  /// **'{value1} km'**
  String searchKm(String value1);

  /// No description provided for @searchFor.
  ///
  /// In en, this message translates to:
  /// **'For: \"{value1}\"'**
  String searchFor(String value1);

  /// No description provided for @searchToday.
  ///
  /// In en, this message translates to:
  /// **'{value1}/{value2} today'**
  String searchToday(String value1, String value2);

  /// No description provided for @searchAlsoShowNormalResults.
  ///
  /// In en, this message translates to:
  /// **'Also show normal results'**
  String get searchAlsoShowNormalResults;

  /// No description provided for @searchNoExactMatch.
  ///
  /// In en, this message translates to:
  /// **'No exact match for \"{value1}\"'**
  String searchNoExactMatch(String value1);

  /// No description provided for @searchHereSomeRelevantAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Here are some relevant alternatives'**
  String get searchHereSomeRelevantAlternatives;

  /// No description provided for @searchAiAgentLive.
  ///
  /// In en, this message translates to:
  /// **'AI Agent is live'**
  String get searchAiAgentLive;

  /// No description provided for @searchFindingBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Finding the best match for \"{value1}\"'**
  String searchFindingBestMatch(String value1);

  /// No description provided for @searchRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get searchRecentSearches;

  /// No description provided for @searchSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all ({value1})'**
  String searchSeeAll(String value1);

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @searchPopularSearches.
  ///
  /// In en, this message translates to:
  /// **'Popular Searches'**
  String get searchPopularSearches;

  /// No description provided for @searchBrowseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Browse by Category'**
  String get searchBrowseByCategory;

  /// No description provided for @searchResultFor.
  ///
  /// In en, this message translates to:
  /// **'{value1} result{value2} for \"{value3}\"'**
  String searchResultFor(String value1, String value2, String value3);

  /// No description provided for @searchGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get searchGettingLocation;

  /// No description provided for @searchSortedByDistance.
  ///
  /// In en, this message translates to:
  /// **'Sorted by distance'**
  String get searchSortedByDistance;

  /// No description provided for @searchEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get searchEnableLocation;

  /// No description provided for @searchPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get searchPro;

  /// No description provided for @searchEGKarachiLahore.
  ///
  /// In en, this message translates to:
  /// **'e.g. Karachi, Lahore'**
  String get searchEGKarachiLahore;

  /// No description provided for @searchEGUrduEnglish.
  ///
  /// In en, this message translates to:
  /// **'e.g. Urdu, English'**
  String get searchEGUrduEnglish;

  /// No description provided for @magazineHealthLegalHomeLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Health · Legal · Home & Lifestyle'**
  String get magazineHealthLegalHomeLifestyle;

  /// No description provided for @magazineCouldNotLoadArticles.
  ///
  /// In en, this message translates to:
  /// **'Could not load articles'**
  String get magazineCouldNotLoadArticles;

  /// No description provided for @magazineNoArticlesYet.
  ///
  /// In en, this message translates to:
  /// **'No Articles Yet'**
  String get magazineNoArticlesYet;

  /// No description provided for @magazineCheckBackSoonTipsAdvice.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for tips & advice.'**
  String get magazineCheckBackSoonTipsAdvice;

  /// No description provided for @magazineSearchArticles.
  ///
  /// In en, this message translates to:
  /// **'Search articles…'**
  String get magazineSearchArticles;

  /// No description provided for @magazineMinRead.
  ///
  /// In en, this message translates to:
  /// **'{value1} min read'**
  String magazineMinRead(String value1);

  /// No description provided for @magazineProfinderTipsMagazine.
  ///
  /// In en, this message translates to:
  /// **'ProFinder Tips Magazine'**
  String get magazineProfinderTipsMagazine;

  /// No description provided for @magazineGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get magazineGoBack;

  /// No description provided for @magazineMin.
  ///
  /// In en, this message translates to:
  /// **'{value1} min'**
  String magazineMin(String value1);

  /// No description provided for @chatSharedMedia.
  ///
  /// In en, this message translates to:
  /// **'Shared Media'**
  String get chatSharedMedia;

  /// No description provided for @chatNoSharedMediaYet.
  ///
  /// In en, this message translates to:
  /// **'No shared media yet'**
  String get chatNoSharedMediaYet;

  /// No description provided for @chatPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos ({value1})'**
  String chatPhotos(String value1);

  /// No description provided for @chatVoiceMessages.
  ///
  /// In en, this message translates to:
  /// **'Voice messages ({value1})'**
  String chatVoiceMessages(String value1);

  /// No description provided for @chatS.
  ///
  /// In en, this message translates to:
  /// **'{value1}s'**
  String chatS(String value1);

  /// No description provided for @chatSharedMedia2.
  ///
  /// In en, this message translates to:
  /// **'Shared media'**
  String get chatSharedMedia2;

  /// No description provided for @chatBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get chatBlockUser;

  /// No description provided for @chatReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get chatReportUser;

  /// No description provided for @chatBlock.
  ///
  /// In en, this message translates to:
  /// **'Block {value1}?'**
  String chatBlock(String value1);

  /// No description provided for @chatTheyNoLongerAbleSendMessages.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to send you messages.'**
  String get chatTheyNoLongerAbleSendMessages;

  /// No description provided for @chatUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get chatUnblockUser;

  /// No description provided for @chatYouBlockedUser.
  ///
  /// In en, this message translates to:
  /// **'You blocked {value1}'**
  String chatYouBlockedUser(String value1);

  /// No description provided for @chatBlockedBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'They can\'t call or message you. Unblock to resume the conversation.'**
  String get chatBlockedBannerSubtitle;

  /// No description provided for @chatUnblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get chatUnblockAction;

  /// No description provided for @chatConversationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This conversation is unavailable'**
  String get chatConversationUnavailable;

  /// No description provided for @chatConversationUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send messages here right now.'**
  String get chatConversationUnavailableSubtitle;

  /// No description provided for @chatMessageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Message unavailable'**
  String get chatMessageUnavailable;

  /// No description provided for @chatSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello 👋'**
  String get chatSayHello;

  /// No description provided for @chatSearchChat.
  ///
  /// In en, this message translates to:
  /// **'Search in chat'**
  String get chatSearchChat;

  /// No description provided for @chatCouldNotLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get chatCouldNotLoadMessages;

  /// No description provided for @chatMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatMessages;

  /// No description provided for @chatNoConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoConversationsYet;

  /// No description provided for @chatSearchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get chatSearchMessages;

  /// No description provided for @chatMicrophonePermissionRequiredVoiceMessages.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice messages.'**
  String get chatMicrophonePermissionRequiredVoiceMessages;

  /// No description provided for @chatEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatEmoji;

  /// No description provided for @chatSendPhoto.
  ///
  /// In en, this message translates to:
  /// **'Send a photo'**
  String get chatSendPhoto;

  /// No description provided for @chatReportSubmittedThank.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get chatReportSubmittedThank;

  /// No description provided for @chatCouldNotSubmitReportTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not submit report. Try again.'**
  String get chatCouldNotSubmitReportTryAgain;

  /// No description provided for @chatReport.
  ///
  /// In en, this message translates to:
  /// **'Report {value1}'**
  String chatReport(String value1);

  /// No description provided for @chatSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get chatSubmit;

  /// No description provided for @chatAdditionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get chatAdditionalDetailsOptional;

  /// No description provided for @chatMessageWasDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get chatMessageWasDeleted;

  /// No description provided for @chatEdited.
  ///
  /// In en, this message translates to:
  /// **'edited ·'**
  String get chatEdited;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatDeleteMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatDeleteMe;

  /// No description provided for @chatDeleteEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteEveryone;

  /// No description provided for @chatEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chatEditMessage;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsNoNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No Notifications Yet'**
  String get notificationsNoNotificationsYet;

  /// No description provided for @notificationsBookingUpdatesAurAlertsYahanDikhenge.
  ///
  /// In en, this message translates to:
  /// **'Booking updates aur alerts yahan dikhenge'**
  String get notificationsBookingUpdatesAurAlertsYahanDikhenge;

  /// No description provided for @professionalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get professionalDelete;

  /// No description provided for @professionalDelete2.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{value1}\"?'**
  String professionalDelete2(String value1);

  /// No description provided for @professionalAddPortfolioItem.
  ///
  /// In en, this message translates to:
  /// **'Add Portfolio Item'**
  String get professionalAddPortfolioItem;

  /// No description provided for @professionalTapAddImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add image'**
  String get professionalTapAddImage;

  /// No description provided for @professionalPortfolioReviewedByAdminOnceApproved.
  ///
  /// In en, this message translates to:
  /// **'Your portfolio will be reviewed by admin. Once approved, you\'ll get a verified badge.'**
  String get professionalPortfolioReviewedByAdminOnceApproved;

  /// No description provided for @professionalSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get professionalSubmitReview;

  /// No description provided for @professionalMyPortfolio.
  ///
  /// In en, this message translates to:
  /// **'My Portfolio'**
  String get professionalMyPortfolio;

  /// No description provided for @professionalNoPortfolioItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No portfolio items yet'**
  String get professionalNoPortfolioItemsYet;

  /// No description provided for @professionalAddWorkGetVerified.
  ///
  /// In en, this message translates to:
  /// **'Add your work to get verified'**
  String get professionalAddWorkGetVerified;

  /// No description provided for @professionalAddFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add First Item'**
  String get professionalAddFirstItem;

  /// No description provided for @professionalNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {value1}'**
  String professionalNote(String value1);

  /// No description provided for @professionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get professionalTitle;

  /// No description provided for @professionalEGHouseConstructionProject.
  ///
  /// In en, this message translates to:
  /// **'e.g. House Construction Project'**
  String get professionalEGHouseConstructionProject;

  /// No description provided for @professionalBriefDescriptionWork.
  ///
  /// In en, this message translates to:
  /// **'Brief description of this work...'**
  String get professionalBriefDescriptionWork;

  /// No description provided for @professionalAddPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Add Portfolio'**
  String get professionalAddPortfolio;

  /// No description provided for @professionalTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get professionalTypeMessage;

  /// No description provided for @professionalDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo?'**
  String get professionalDeletePhoto;

  /// No description provided for @professionalPhotoRemovedFromGallery.
  ///
  /// In en, this message translates to:
  /// **'This photo will be removed from your gallery.'**
  String get professionalPhotoRemovedFromGallery;

  /// No description provided for @professionalGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get professionalGallery;

  /// No description provided for @professionalNoPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get professionalNoPhotosYet;

  /// No description provided for @professionalAddPhotosShowcaseWorkEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Add photos to showcase your work environment'**
  String get professionalAddPhotosShowcaseWorkEnvironment;

  /// No description provided for @professionalAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get professionalAddPhoto;

  /// No description provided for @professionalWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get professionalWorkingHours;

  /// No description provided for @professionalProfessionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Professional Details'**
  String get professionalProfessionalDetails;

  /// No description provided for @professionalSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get professionalSkills;

  /// No description provided for @professionalNoSkillsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet'**
  String get professionalNoSkillsAddedYet;

  /// No description provided for @professionalBankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get professionalBankDetails;

  /// No description provided for @professionalCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get professionalCertificates;

  /// No description provided for @professionalWalletEarnings.
  ///
  /// In en, this message translates to:
  /// **'Wallet & Earnings'**
  String get professionalWalletEarnings;

  /// No description provided for @professionalSubscriptionUpgradePremium.
  ///
  /// In en, this message translates to:
  /// **'Subscription / Upgrade to Premium'**
  String get professionalSubscriptionUpgradePremium;

  /// No description provided for @professionalChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get professionalChangePassword;

  /// No description provided for @professionalAddSkill.
  ///
  /// In en, this message translates to:
  /// **'+ Add skill'**
  String get professionalAddSkill;

  /// No description provided for @professionalAddLanguage.
  ///
  /// In en, this message translates to:
  /// **'+ Add language'**
  String get professionalAddLanguage;

  /// No description provided for @professionalNeedMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get professionalNeedMoreHelp;

  /// No description provided for @professionalOurSupportTeamRepliesWithin24.
  ///
  /// In en, this message translates to:
  /// **'Our support team replies within 24 hours'**
  String get professionalOurSupportTeamRepliesWithin24;

  /// No description provided for @professionalContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get professionalContact;

  /// No description provided for @professionalContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get professionalContactSupport;

  /// No description provided for @professionalSupportProfinderCom.
  ///
  /// In en, this message translates to:
  /// **'support@profinder.com'**
  String get professionalSupportProfinderCom;

  /// No description provided for @professionalEmailUsAnytime.
  ///
  /// In en, this message translates to:
  /// **'Email us anytime'**
  String get professionalEmailUsAnytime;

  /// No description provided for @professionalLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get professionalLiveChat;

  /// No description provided for @professionalAvailable9Am6Pm.
  ///
  /// In en, this message translates to:
  /// **'Available 9 AM - 6 PM'**
  String get professionalAvailable9Am6Pm;

  /// No description provided for @professionalRePlan.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the {value1} plan'**
  String professionalRePlan(String value1);

  /// No description provided for @professionalUpgradeMoreBookingsFeaturedProfilePriority.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for more bookings, featured profile & priority ranking'**
  String get professionalUpgradeMoreBookingsFeaturedProfilePriority;

  /// No description provided for @professionalUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get professionalUpgrade;

  /// No description provided for @professionalProfileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get professionalProfileCompletion;

  /// No description provided for @professionalCompleteProfileGetMoreBookings.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get more bookings'**
  String get professionalCompleteProfileGetMoreBookings;

  /// No description provided for @professionalNoClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found for \"{value1}\"'**
  String professionalNoClientsFound(String value1);

  /// No description provided for @professionalQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get professionalQuickActions;

  /// No description provided for @professionalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get professionalEarnings;

  /// No description provided for @professionalViewWallet.
  ///
  /// In en, this message translates to:
  /// **'View Wallet'**
  String get professionalViewWallet;

  /// No description provided for @professionalPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get professionalPerformance;

  /// No description provided for @professionalTodaySSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get professionalTodaySSchedule;

  /// No description provided for @professionalNoBookingsScheduledToday.
  ///
  /// In en, this message translates to:
  /// **'No bookings scheduled for today'**
  String get professionalNoBookingsScheduledToday;

  /// No description provided for @professionalRecentMessages.
  ///
  /// In en, this message translates to:
  /// **'Recent Messages'**
  String get professionalRecentMessages;

  /// No description provided for @professionalSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get professionalSeeAll;

  /// No description provided for @professionalNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get professionalNoMessagesYet;

  /// No description provided for @professionalSkillsPricing.
  ///
  /// In en, this message translates to:
  /// **'Skills & Pricing'**
  String get professionalSkillsPricing;

  /// No description provided for @professionalManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get professionalManage;

  /// No description provided for @professionalAddWorkSamples.
  ///
  /// In en, this message translates to:
  /// **'Add your work samples'**
  String get professionalAddWorkSamples;

  /// No description provided for @professionalGetVerifiedByAddingPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Get verified by adding portfolio'**
  String get professionalGetVerifiedByAddingPortfolio;

  /// No description provided for @professionalRecentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent Reviews'**
  String get professionalRecentReviews;

  /// No description provided for @professionalRecentBookings.
  ///
  /// In en, this message translates to:
  /// **'Recent Bookings'**
  String get professionalRecentBookings;

  /// No description provided for @professionalNoBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get professionalNoBookingsYet;

  /// No description provided for @professionalBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get professionalBookingDetails;

  /// No description provided for @professionalMarkAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get professionalMarkAsCompleted;

  /// No description provided for @professionalCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get professionalCancelBooking;

  /// No description provided for @professionalSearchBookingsByClientName.
  ///
  /// In en, this message translates to:
  /// **'Search bookings by client name...'**
  String get professionalSearchBookingsByClientName;

  /// No description provided for @professionalPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get professionalPortfolio;

  /// No description provided for @professionalAddCertificate.
  ///
  /// In en, this message translates to:
  /// **'Add Certificate'**
  String get professionalAddCertificate;

  /// No description provided for @professionalTapAddCertificateImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add certificate image'**
  String get professionalTapAddCertificateImage;

  /// No description provided for @professionalSaveCertificate.
  ///
  /// In en, this message translates to:
  /// **'Save Certificate'**
  String get professionalSaveCertificate;

  /// No description provided for @professionalNoCertificatesYet.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet'**
  String get professionalNoCertificatesYet;

  /// No description provided for @professionalAddCertificationsBuildTrust.
  ///
  /// In en, this message translates to:
  /// **'Add certifications to build trust'**
  String get professionalAddCertificationsBuildTrust;

  /// No description provided for @professionalAddFirstCertificate.
  ///
  /// In en, this message translates to:
  /// **'Add First Certificate'**
  String get professionalAddFirstCertificate;

  /// No description provided for @professionalCertificateTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate Title *'**
  String get professionalCertificateTitle;

  /// No description provided for @professionalIssuingOrganization.
  ///
  /// In en, this message translates to:
  /// **'Issuing Organization'**
  String get professionalIssuingOrganization;

  /// No description provided for @professionalEGCertifiedElectrician.
  ///
  /// In en, this message translates to:
  /// **'e.g. Certified Electrician'**
  String get professionalEGCertifiedElectrician;

  /// No description provided for @professionalEGTevtaCoursera.
  ///
  /// In en, this message translates to:
  /// **'e.g. TEVTA / Coursera'**
  String get professionalEGTevtaCoursera;

  /// No description provided for @professionalCustomerConversationsShowUpHere.
  ///
  /// In en, this message translates to:
  /// **'Customer conversations will show up here'**
  String get professionalCustomerConversationsShowUpHere;

  /// No description provided for @professionalCancelBooking2.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking?'**
  String get professionalCancelBooking2;

  /// No description provided for @professionalSureWantCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get professionalSureWantCancelBooking;

  /// No description provided for @professionalReasonCancellingOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancelling (optional)'**
  String get professionalReasonCancellingOptional;

  /// No description provided for @professionalYesCancelIt.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel It'**
  String get professionalYesCancelIt;

  /// No description provided for @professionalNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No {value1} bookings'**
  String professionalNoBookings(String value1);

  /// No description provided for @professionalDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get professionalDecline;

  /// No description provided for @professionalEGNotAvailableThatDay.
  ///
  /// In en, this message translates to:
  /// **'e.g. not available that day, emergency came up...'**
  String get professionalEGNotAvailableThatDay;

  /// No description provided for @professionalReview.
  ///
  /// In en, this message translates to:
  /// **'{value1} review{value2}'**
  String professionalReview(String value1, String value2);

  /// No description provided for @professionalWithdrawEarnings.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Earnings'**
  String get professionalWithdrawEarnings;

  /// No description provided for @professionalAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: \${value1}'**
  String professionalAvailable(String value1);

  /// No description provided for @professionalMinimumWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal: \${value1}'**
  String professionalMinimumWithdrawal(String value1);

  /// No description provided for @professionalRequestWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Request Withdrawal'**
  String get professionalRequestWithdrawal;

  /// No description provided for @professionalBankDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Bank Details Required'**
  String get professionalBankDetailsRequired;

  /// No description provided for @professionalPleaseAddBankAccountDetailsProfile.
  ///
  /// In en, this message translates to:
  /// **'Please add your bank account details in Profile before requesting a withdrawal.'**
  String get professionalPleaseAddBankAccountDetailsProfile;

  /// No description provided for @professionalAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get professionalAvailableBalance;

  /// No description provided for @professionalWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get professionalWithdraw;

  /// No description provided for @professionalNoTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get professionalNoTransactionsYet;

  /// No description provided for @professionalEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get professionalEnterAmount;

  /// No description provided for @professionalPerformanceScore.
  ///
  /// In en, this message translates to:
  /// **'Performance Score'**
  String get professionalPerformanceScore;

  /// No description provided for @professionalOut100.
  ///
  /// In en, this message translates to:
  /// **'out of 100'**
  String get professionalOut100;

  /// No description provided for @professionalPerformanceScore40Rating30Acceptance.
  ///
  /// In en, this message translates to:
  /// **'Performance Score = 40% rating + 30% acceptance rate + 30% response rate.'**
  String get professionalPerformanceScore40Rating30Acceptance;

  /// No description provided for @professionalDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get professionalDashboard;

  /// No description provided for @professionalMagazine.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get professionalMagazine;

  /// No description provided for @professionalEnterCurrentPasswordNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and a new password.'**
  String get professionalEnterCurrentPasswordNewPassword;

  /// No description provided for @professionalUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get professionalUpdate;

  /// No description provided for @professionalCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get professionalCurrentPassword;

  /// No description provided for @professionalNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get professionalNewPassword;

  /// No description provided for @professionalConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get professionalConfirmNewPassword;

  /// No description provided for @homeBecomePro.
  ///
  /// In en, this message translates to:
  /// **'Become Pro'**
  String get homeBecomePro;

  /// No description provided for @homeLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get homeLoginRequired;

  /// No description provided for @homeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get homeCreateAccount;

  /// No description provided for @homeWelcomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Guest'**
  String get homeWelcomeGuest;

  /// No description provided for @homeHireRightExpertMinutes.
  ///
  /// In en, this message translates to:
  /// **'Hire the right expert, in minutes.'**
  String get homeHireRightExpertMinutes;

  /// No description provided for @homeSearchDoctorsLawyersPlumbers.
  ///
  /// In en, this message translates to:
  /// **'Search doctors, lawyers, plumbers…'**
  String get homeSearchDoctorsLawyersPlumbers;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @homeAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get homeAllCategories;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get homeFeatured;

  /// No description provided for @homeExploreExperts.
  ///
  /// In en, this message translates to:
  /// **'Explore experts →'**
  String get homeExploreExperts;

  /// No description provided for @homeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Are you a professional?'**
  String get homeProfessional;

  /// No description provided for @homeJoinProfinderGetDiscoveredByThousands.
  ///
  /// In en, this message translates to:
  /// **'Join ProFinder and get discovered by thousands of customers.'**
  String get homeJoinProfinderGetDiscoveredByThousands;

  /// No description provided for @homeUnlockFullExperience.
  ///
  /// In en, this message translates to:
  /// **'Unlock the full experience'**
  String get homeUnlockFullExperience;

  /// No description provided for @homeBookProfessionalsSaveFavouritesTrackRequests.
  ///
  /// In en, this message translates to:
  /// **'Book professionals, save favourites & track your requests.'**
  String get homeBookProfessionalsSaveFavouritesTrackRequests;

  /// No description provided for @homeNoProfessionalsNearbyYet.
  ///
  /// In en, this message translates to:
  /// **'No professionals nearby yet'**
  String get homeNoProfessionalsNearbyYet;

  /// No description provided for @homeTrySearchingCategoryCheckBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Try searching a category or check back soon.'**
  String get homeTrySearchingCategoryCheckBackSoon;

  /// No description provided for @homeSearchNow.
  ///
  /// In en, this message translates to:
  /// **'Search Now'**
  String get homeSearchNow;

  /// No description provided for @homeFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get homeFilter;

  /// No description provided for @homePrice.
  ///
  /// In en, this message translates to:
  /// **'Price: \${value1} — {value2}'**
  String homePrice(String value1, String value2);

  /// No description provided for @homeVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified only'**
  String get homeVerifiedOnly;

  /// No description provided for @homeNoProfessionalsAvailableCity.
  ///
  /// In en, this message translates to:
  /// **'No professionals available in your city.'**
  String get homeNoProfessionalsAvailableCity;

  /// No description provided for @homeTrySearchingNearbyCities.
  ///
  /// In en, this message translates to:
  /// **'Try searching nearby cities.'**
  String get homeTrySearchingNearbyCities;

  /// No description provided for @homeHi.
  ///
  /// In en, this message translates to:
  /// **'Hi, {value1} 👋'**
  String homeHi(String value1);

  /// No description provided for @homeGetPersonalizedPicks.
  ///
  /// In en, this message translates to:
  /// **'Get personalized picks'**
  String get homeGetPersonalizedPicks;

  /// No description provided for @homeBookFirstServiceWeLlStart.
  ///
  /// In en, this message translates to:
  /// **'Book your first service and we\'ll start personalizing this for you.'**
  String get homeBookFirstServiceWeLlStart;

  /// No description provided for @homeBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get homeBrowse;

  /// No description provided for @homeAiPick.
  ///
  /// In en, this message translates to:
  /// **'✨ AI PICK FOR YOU'**
  String get homeAiPick;

  /// No description provided for @homeBookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book Again'**
  String get homeBookAgain;

  /// No description provided for @homeClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get homeClearAll;

  /// No description provided for @homeNoUpcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings'**
  String get homeNoUpcomingBookings;

  /// No description provided for @homeBrowseProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Browse Professionals'**
  String get homeBrowseProfessionals;

  /// No description provided for @homeViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get homeViewDetails;

  /// No description provided for @homeCancelledBy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by {value1}: {value2}'**
  String homeCancelledBy(String value1, String value2);

  /// No description provided for @homeRateExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience ⭐'**
  String get homeRateExperience;

  /// No description provided for @homePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan: {value1}'**
  String homePlan(String value1);

  /// No description provided for @homeRecentChats.
  ///
  /// In en, this message translates to:
  /// **'Recent Chats'**
  String get homeRecentChats;

  /// No description provided for @homeNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get homeNoMessagesYet;

  /// No description provided for @homeStartConversationAfterBookingProfessional.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation after booking a professional.'**
  String get homeStartConversationAfterBookingProfessional;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications{value1}'**
  String homeNotifications(String value1);

  /// No description provided for @homeAiSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Suggestions'**
  String get homeAiSuggestions;

  /// No description provided for @homeUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited ✨'**
  String get homeUnlimited;

  /// No description provided for @homeUsedToday.
  ///
  /// In en, this message translates to:
  /// **'{value1} of {value2} used today'**
  String homeUsedToday(String value1, String value2);

  /// No description provided for @homeJustTellUsWhatNeedWe.
  ///
  /// In en, this message translates to:
  /// **'Just tell us what you need, and we\'ll instantly match you with the right verified professional.'**
  String get homeJustTellUsWhatNeedWe;

  /// No description provided for @homeDailyLimitReachedResetsMidnight.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached — resets at midnight'**
  String get homeDailyLimitReachedResetsMidnight;

  /// No description provided for @homeNeedHelpWeReHere.
  ///
  /// In en, this message translates to:
  /// **'Need help? We\'re here for you'**
  String get homeNeedHelpWeReHere;

  /// No description provided for @homeGetResponseWithin24Hours.
  ///
  /// In en, this message translates to:
  /// **'Get a response within 24 hours'**
  String get homeGetResponseWithin24Hours;

  /// No description provided for @homeHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get homeHelpCenter;

  /// No description provided for @homeEGINeedPlumberLeaking.
  ///
  /// In en, this message translates to:
  /// **'e.g. I need a plumber for a leaking pipe…'**
  String get homeEGINeedPlumberLeaking;

  /// No description provided for @homePopularCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular Categories'**
  String get homePopularCategories;

  /// No description provided for @homeUpcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bookings'**
  String get homeUpcomingBookings;

  /// No description provided for @bookingsBookProfessionalFromHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Book a professional from home screen'**
  String get bookingsBookProfessionalFromHomeScreen;

  /// No description provided for @bookingsEGScheduleChangedNoLonger.
  ///
  /// In en, this message translates to:
  /// **'e.g. schedule changed, no longer needed...'**
  String get bookingsEGScheduleChangedNoLonger;

  /// No description provided for @bookingsBookingSent.
  ///
  /// In en, this message translates to:
  /// **'Booking Sent!'**
  String get bookingsBookingSent;

  /// No description provided for @bookingsRequestSentNotifiedOnceTheyRespond.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {value1}. You will be notified once they respond.'**
  String bookingsRequestSentNotifiedOnceTheyRespond(String value1);

  /// No description provided for @bookingsViewMyBookings.
  ///
  /// In en, this message translates to:
  /// **'View My Bookings'**
  String get bookingsViewMyBookings;

  /// No description provided for @bookingsBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get bookingsBackHome;

  /// No description provided for @bookingsBookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookingsBookAppointment;

  /// No description provided for @bookingsSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get bookingsSummary;

  /// No description provided for @bookingsConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get bookingsConfirmBooking;

  /// No description provided for @bookingsDescribeIssueRequirements.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or requirements...'**
  String get bookingsDescribeIssueRequirements;

  /// No description provided for @bookingsShareExperience.
  ///
  /// In en, this message translates to:
  /// **'Share your experience'**
  String get bookingsShareExperience;

  /// No description provided for @bookingsYourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get bookingsYourRating;

  /// No description provided for @bookingsCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Your Comment (Optional)'**
  String get bookingsCommentOptional;

  /// No description provided for @bookingsReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted! 🎉'**
  String get bookingsReviewSubmitted;

  /// No description provided for @bookingsThankReviewingFeedbackHelpsOthersMake.
  ///
  /// In en, this message translates to:
  /// **'Thank you for reviewing {value1}. Your feedback helps others make better decisions.'**
  String bookingsThankReviewingFeedbackHelpsOthersMake(String value1);

  /// No description provided for @bookingsBackBookings.
  ///
  /// In en, this message translates to:
  /// **'Back to Bookings'**
  String get bookingsBackBookings;

  /// No description provided for @bookingsDescribeExperience.
  ///
  /// In en, this message translates to:
  /// **'Describe your experience with {value1}...'**
  String bookingsDescribeExperience(String value1);

  /// No description provided for @subscriptionConfirmSubscription.
  ///
  /// In en, this message translates to:
  /// **'Confirm Subscription'**
  String get subscriptionConfirmSubscription;

  /// No description provided for @subscriptionSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to {value1} for {value2} {value3}'**
  String subscriptionSubscribe(String value1, String value2, String value3);

  /// No description provided for @subscriptionSubscribe2.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscriptionSubscribe2;

  /// No description provided for @subscriptionChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get subscriptionChoosePlan;

  /// No description provided for @subscriptionAvailablePlans.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get subscriptionAvailablePlans;

  /// No description provided for @subscriptionCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan: {value1}'**
  String subscriptionCurrentPlan(String value1);

  /// No description provided for @subscriptionValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until: {value1}'**
  String subscriptionValidUntil(String value1);

  /// No description provided for @subscriptionUpgradeUnlockPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock premium features'**
  String get subscriptionUpgradeUnlockPremiumFeatures;

  /// No description provided for @subscriptionRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get subscriptionRecommended;

  /// No description provided for @subscriptionCurrentPlan2.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get subscriptionCurrentPlan2;

  /// No description provided for @subscriptionCurrentPlan3.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get subscriptionCurrentPlan3;

  /// No description provided for @subscriptionBasicPlan.
  ///
  /// In en, this message translates to:
  /// **'Basic Plan'**
  String get subscriptionBasicPlan;

  /// No description provided for @subscriptionGet.
  ///
  /// In en, this message translates to:
  /// **'Get {value1}'**
  String subscriptionGet(String value1);

  /// No description provided for @subscriptionCancelAnytimeSecurePayment.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime • Secure payment'**
  String get subscriptionCancelAnytimeSecurePayment;

  /// No description provided for @subscriptionBookingLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Booking Limit Reached!'**
  String get subscriptionBookingLimitReached;

  /// No description provided for @subscriptionVeUsedBookingsMonthFreePlan.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {value1}/{value2} bookings this month on your Free plan.'**
  String subscriptionVeUsedBookingsMonthFreePlan(String value1, String value2);

  /// No description provided for @subscriptionUpgradePremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get subscriptionUpgradePremium;

  /// No description provided for @subscriptionMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get subscriptionMaybeLater;

  /// No description provided for @subscriptionMonthlyBookings.
  ///
  /// In en, this message translates to:
  /// **'Monthly Bookings'**
  String get subscriptionMonthlyBookings;

  /// No description provided for @subscriptionPremiumIncludes.
  ///
  /// In en, this message translates to:
  /// **'Premium includes:'**
  String get subscriptionPremiumIncludes;

  /// No description provided for @subscriptionAiSearchLimitReached.
  ///
  /// In en, this message translates to:
  /// **'AI Search Limit Reached!'**
  String get subscriptionAiSearchLimitReached;

  /// No description provided for @subscriptionVeUsedAiSearchesTodayAi.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {value1}/{value2} AI searches today. AI chat is locked until your limit resets.'**
  String subscriptionVeUsedAiSearchesTodayAi(String value1, String value2);

  /// No description provided for @subscriptionAiSearchesToday.
  ///
  /// In en, this message translates to:
  /// **'AI Searches Today'**
  String get subscriptionAiSearchesToday;

  /// No description provided for @subscriptionGetPremium20AiDay.
  ///
  /// In en, this message translates to:
  /// **'Get Premium — 20 AI/day'**
  String get subscriptionGetPremium20AiDay;

  /// No description provided for @subscriptionContinueNormalSearch.
  ///
  /// In en, this message translates to:
  /// **'Continue with Normal Search'**
  String get subscriptionContinueNormalSearch;

  /// No description provided for @subscriptionPremiumAiFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium AI Features:'**
  String get subscriptionPremiumAiFeatures;

  /// No description provided for @subscriptionProfinderPremium.
  ///
  /// In en, this message translates to:
  /// **'ProFinder Premium'**
  String get subscriptionProfinderPremium;

  /// No description provided for @sharedYExp.
  ///
  /// In en, this message translates to:
  /// **'{value1}y exp'**
  String sharedYExp(String value1);

  /// No description provided for @sharedViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get sharedViewProfile;

  /// No description provided for @homeNotificationsSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications are available after signing in. Log in or create an account to see booking updates and personalised alerts.'**
  String get homeNotificationsSignInMessage;

  /// No description provided for @homeSetUpProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Login or create an account to set up your profile.'**
  String get homeSetUpProfileMessage;

  /// No description provided for @homeLoginToSaveFavourites.
  ///
  /// In en, this message translates to:
  /// **'Login to save professionals to your favourites.'**
  String get homeLoginToSaveFavourites;

  /// No description provided for @homeLoginToBookName.
  ///
  /// In en, this message translates to:
  /// **'Login to book {value1} and manage your appointments.'**
  String homeLoginToBookName(String value1);

  /// No description provided for @homeWhatAreYouLookingForToday.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for today?'**
  String get homeWhatAreYouLookingForToday;

  /// No description provided for @homeTrendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get homeTrendingLabel;

  /// No description provided for @homeFeaturedCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Featured Categories'**
  String get homeFeaturedCategoriesSection;

  /// No description provided for @homeTopRatedProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Top Rated Professionals'**
  String get homeTopRatedProfessionals;

  /// No description provided for @homeTopRatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get homeTopRatedLabel;

  /// No description provided for @homeTrendingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Trending This Week'**
  String get homeTrendingThisWeek;

  /// No description provided for @homePopularProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Popular Professionals'**
  String get homePopularProfessionals;

  /// No description provided for @homePopularLabel.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get homePopularLabel;

  /// No description provided for @homeRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get homeRecentlyAdded;

  /// No description provided for @homeNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get homeNewLabel;

  /// No description provided for @homeFromTheMagazine.
  ///
  /// In en, this message translates to:
  /// **'From the Magazine'**
  String get homeFromTheMagazine;

  /// No description provided for @homeNearLocation.
  ///
  /// In en, this message translates to:
  /// **'Near {value1}'**
  String homeNearLocation(String value1);

  /// No description provided for @homeProfessionalsInLocation.
  ///
  /// In en, this message translates to:
  /// **'Professionals in {value1}'**
  String homeProfessionalsInLocation(String value1);

  /// No description provided for @homeClosestProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Closest Professionals'**
  String get homeClosestProfessionals;

  /// No description provided for @homeTopRatedProfessionalsNationwide.
  ///
  /// In en, this message translates to:
  /// **'Top Rated Professionals Nationwide'**
  String get homeTopRatedProfessionalsNationwide;

  /// No description provided for @homeNearbyLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get homeNearbyLabel;

  /// No description provided for @homeArticleLabel.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get homeArticleLabel;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeSetYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get homeSetYourLocation;

  /// No description provided for @homeCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Karachi, Lahore'**
  String get homeCityHint;

  /// No description provided for @homeNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get homeNoLimit;

  /// No description provided for @homeMinRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Rating: {value1} ★'**
  String homeMinRatingLabel(String value1);

  /// No description provided for @homeResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get homeResetButton;

  /// No description provided for @homeApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get homeApplyButton;

  /// No description provided for @homeFilteredResults.
  ///
  /// In en, this message translates to:
  /// **'Filtered Results'**
  String get homeFilteredResults;

  /// No description provided for @homeRecommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get homeRecommendedForYou;

  /// No description provided for @homeRecommendedLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get homeRecommendedLabel;

  /// No description provided for @homeSavedQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get homeSavedQuickAction;

  /// No description provided for @homeWalletQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get homeWalletQuickAction;

  /// No description provided for @homeHelpQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get homeHelpQuickAction;

  /// No description provided for @homeRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get homeRecentSearches;

  /// No description provided for @homeRecentBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Bookings'**
  String get homeRecentBookingsTitle;

  /// No description provided for @homeConfirmedStatus.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get homeConfirmedStatus;

  /// No description provided for @homeDeclinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get homeDeclinedStatus;

  /// No description provided for @homeCancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get homeCancelledStatus;

  /// No description provided for @homeSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get homeSystemLabel;

  /// No description provided for @homeTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get homeTotalSpent;

  /// No description provided for @homeAcrossTransaction.
  ///
  /// In en, this message translates to:
  /// **'Across {value1} transaction'**
  String homeAcrossTransaction(String value1);

  /// No description provided for @homeAcrossTransactions.
  ///
  /// In en, this message translates to:
  /// **'Across {value1} transactions'**
  String homeAcrossTransactions(String value1);

  /// No description provided for @homeManageButton.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get homeManageButton;

  /// No description provided for @homeUpgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get homeUpgradeButton;

  /// No description provided for @homePaymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get homePaymentHistoryTitle;

  /// No description provided for @homeTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get homeTotalLabel;

  /// No description provided for @homeSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello 👋'**
  String get homeSayHello;

  /// No description provided for @homeMagazineNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get homeMagazineNavLabel;

  /// No description provided for @homeMessagesNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get homeMessagesNavLabel;

  /// No description provided for @homeTipsMagazineTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips Magazine'**
  String get homeTipsMagazineTitle;

  /// No description provided for @homeFeaturedArticlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Articles'**
  String get homeFeaturedArticlesTitle;

  /// No description provided for @homeContactButton.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get homeContactButton;

  /// No description provided for @homeAiPickForYou.
  ///
  /// In en, this message translates to:
  /// **'AI PICK FOR YOU'**
  String get homeAiPickForYou;

  /// No description provided for @homeMessagingComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get homeMessagingComingSoonTitle;

  /// No description provided for @homeMessagingComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to chat directly with professionals here.'**
  String get homeMessagingComingSoonMessage;

  /// No description provided for @commonOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @profileVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get profileVersionLabel;

  /// No description provided for @searchAiSearchFailedTryNormal.
  ///
  /// In en, this message translates to:
  /// **'AI search failed. Try normal search.'**
  String get searchAiSearchFailedTryNormal;

  /// No description provided for @searchFailedCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Please check your connection and try again.'**
  String get searchFailedCheckConnection;

  /// No description provided for @searchClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get searchClearAll;

  /// No description provided for @searchDistanceAny.
  ///
  /// In en, this message translates to:
  /// **'Distance: Any'**
  String get searchDistanceAny;

  /// No description provided for @searchWithinKm.
  ///
  /// In en, this message translates to:
  /// **'Within {value1} km'**
  String searchWithinKm(String value1);

  /// No description provided for @searchSortPriceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low–High'**
  String get searchSortPriceLowHigh;

  /// No description provided for @searchSortPriceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High–Low'**
  String get searchSortPriceHighLow;

  /// No description provided for @searchAiSearchesLeft.
  ///
  /// In en, this message translates to:
  /// **'{value1} left'**
  String searchAiSearchesLeft(String value1);

  /// No description provided for @searchSimilarProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Similar Professionals'**
  String get searchSimilarProfessionals;

  /// No description provided for @searchProfessionalsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Professionals Near You'**
  String get searchProfessionalsNearYou;

  /// No description provided for @searchTrendingCategories.
  ///
  /// In en, this message translates to:
  /// **'Trending Categories'**
  String get searchTrendingCategories;

  /// No description provided for @searchAiPremiumResults.
  ///
  /// In en, this message translates to:
  /// **'AI Premium Results'**
  String get searchAiPremiumResults;

  /// No description provided for @searchAiSearchResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Search Results'**
  String get searchAiSearchResultsTitle;

  /// No description provided for @searchNoMatchingProfessionalsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching professionals found.'**
  String get searchNoMatchingProfessionalsFound;

  /// No description provided for @searchRelatedProfessions.
  ///
  /// In en, this message translates to:
  /// **'Related Professions'**
  String get searchRelatedProfessions;

  /// No description provided for @searchTrendingProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Trending Professionals'**
  String get searchTrendingProfessionals;

  /// No description provided for @searchPopularNearby.
  ///
  /// In en, this message translates to:
  /// **'Popular Nearby'**
  String get searchPopularNearby;

  /// No description provided for @searchShowingResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Showing results for: '**
  String get searchShowingResultsFor;

  /// No description provided for @searchMetersAway.
  ///
  /// In en, this message translates to:
  /// **'{value1}m away'**
  String searchMetersAway(String value1);

  /// No description provided for @searchKmNearYou.
  ///
  /// In en, this message translates to:
  /// **'{value1} km · Near You'**
  String searchKmNearYou(String value1);

  /// No description provided for @searchKmAway.
  ///
  /// In en, this message translates to:
  /// **'{value1} km away'**
  String searchKmAway(String value1);

  /// No description provided for @searchApproxKm.
  ///
  /// In en, this message translates to:
  /// **'~{value1} km'**
  String searchApproxKm(String value1);

  /// No description provided for @searchApproxKmNearbyCity.
  ///
  /// In en, this message translates to:
  /// **'~{value1} km · Nearby City'**
  String searchApproxKmNearbyCity(String value1);

  /// No description provided for @searchDifferentArea.
  ///
  /// In en, this message translates to:
  /// **'Different Area'**
  String get searchDifferentArea;

  /// No description provided for @searchAiHintPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask AI: Find me a plumber...'**
  String get searchAiHintPlaceholder;

  /// No description provided for @searchNameCityProfessionHint.
  ///
  /// In en, this message translates to:
  /// **'Name, city, profession...'**
  String get searchNameCityProfessionHint;

  /// No description provided for @searchAiSearchOnTapDisable.
  ///
  /// In en, this message translates to:
  /// **'AI Search ON — Tap to disable'**
  String get searchAiSearchOnTapDisable;

  /// No description provided for @searchTryAiSearchSmarterResults.
  ///
  /// In en, this message translates to:
  /// **'Try AI Search — smarter results'**
  String get searchTryAiSearchSmarterResults;

  /// No description provided for @subscriptionFailedToLoadPlans.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plans.'**
  String get subscriptionFailedToLoadPlans;

  /// No description provided for @subscriptionSubscribedTo.
  ///
  /// In en, this message translates to:
  /// **'Subscribed to {value1}!'**
  String subscriptionSubscribedTo(String value1);

  /// No description provided for @subscriptionSubscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscription failed.'**
  String get subscriptionSubscriptionFailed;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get subscriptionPerMonth;

  /// No description provided for @subscriptionPerYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get subscriptionPerYear;

  /// No description provided for @subscriptionFreeForever.
  ///
  /// In en, this message translates to:
  /// **'Free forever'**
  String get subscriptionFreeForever;

  /// No description provided for @subscriptionBilledMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get subscriptionBilledMonthly;

  /// No description provided for @subscriptionBilledYearly.
  ///
  /// In en, this message translates to:
  /// **'Billed yearly'**
  String get subscriptionBilledYearly;

  /// No description provided for @subscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get subscriptionFree;

  /// No description provided for @subscriptionUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get subscriptionUnlimited;

  /// No description provided for @subscriptionUpgradeUnlimitedAiSearches.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for unlimited AI searches & more'**
  String get subscriptionUpgradeUnlimitedAiSearches;

  /// No description provided for @subscriptionUpgradeUnlimitedBookings.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for unlimited bookings & priority ranking'**
  String get subscriptionUpgradeUnlimitedBookings;

  /// No description provided for @subscriptionFeatureAiSearchesDay.
  ///
  /// In en, this message translates to:
  /// **'AI Searches/day'**
  String get subscriptionFeatureAiSearchesDay;

  /// No description provided for @subscriptionFeatureMessagesDay.
  ///
  /// In en, this message translates to:
  /// **'Messages/day'**
  String get subscriptionFeatureMessagesDay;

  /// No description provided for @subscriptionFeatureUnlimitedBookings.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Bookings'**
  String get subscriptionFeatureUnlimitedBookings;

  /// No description provided for @subscriptionFeaturePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get subscriptionFeaturePrioritySupport;

  /// No description provided for @subscriptionFeaturePremiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium Badge'**
  String get subscriptionFeaturePremiumBadge;

  /// No description provided for @subscriptionFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get subscriptionFeatureNoAds;

  /// No description provided for @subscriptionFeatureBookingsMonth.
  ///
  /// In en, this message translates to:
  /// **'Bookings/month'**
  String get subscriptionFeatureBookingsMonth;

  /// No description provided for @subscriptionFeaturePortfolioImages.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Images'**
  String get subscriptionFeaturePortfolioImages;

  /// No description provided for @subscriptionFeatureServicesListed.
  ///
  /// In en, this message translates to:
  /// **'Services Listed'**
  String get subscriptionFeatureServicesListed;

  /// No description provided for @subscriptionFeatureFeaturedProfile.
  ///
  /// In en, this message translates to:
  /// **'Featured Profile'**
  String get subscriptionFeatureFeaturedProfile;

  /// No description provided for @subscriptionFeaturePriorityRanking.
  ///
  /// In en, this message translates to:
  /// **'Priority Ranking'**
  String get subscriptionFeaturePriorityRanking;

  /// No description provided for @subscriptionLimitResetsOn.
  ///
  /// In en, this message translates to:
  /// **'Your limit resets on {value1}'**
  String subscriptionLimitResetsOn(String value1);

  /// No description provided for @subscriptionLimitResetsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Your limit resets at the start of next month'**
  String get subscriptionLimitResetsNextMonth;

  /// No description provided for @subscriptionFeatureUnlimitedBookingsMonth.
  ///
  /// In en, this message translates to:
  /// **'Unlimited bookings every month'**
  String get subscriptionFeatureUnlimitedBookingsMonth;

  /// No description provided for @subscriptionFeatureFeaturedProfileSearch.
  ///
  /// In en, this message translates to:
  /// **'Featured profile in search results'**
  String get subscriptionFeatureFeaturedProfileSearch;

  /// No description provided for @subscriptionFeaturePriorityAiRanking.
  ///
  /// In en, this message translates to:
  /// **'Priority AI ranking'**
  String get subscriptionFeaturePriorityAiRanking;

  /// No description provided for @subscriptionFeatureNoAdsProfile.
  ///
  /// In en, this message translates to:
  /// **'No ads on your profile'**
  String get subscriptionFeatureNoAdsProfile;

  /// No description provided for @subscriptionAiResetsTomorrowMidnight.
  ///
  /// In en, this message translates to:
  /// **'Your AI searches reset tomorrow at midnight'**
  String get subscriptionAiResetsTomorrowMidnight;

  /// No description provided for @subscriptionResetsAt.
  ///
  /// In en, this message translates to:
  /// **'Resets {value1} at {value2}'**
  String subscriptionResetsAt(String value1, String value2);

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get commonTomorrow;

  /// No description provided for @subscriptionBenefit20AiSearchesDay.
  ///
  /// In en, this message translates to:
  /// **'20 AI searches per day'**
  String get subscriptionBenefit20AiSearchesDay;

  /// No description provided for @subscriptionBenefitAdvancedAiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Advanced AI recommendations'**
  String get subscriptionBenefitAdvancedAiRecommendations;

  /// No description provided for @subscriptionBenefitSearchByBudgetLocationHistory.
  ///
  /// In en, this message translates to:
  /// **'Search by budget, location & history'**
  String get subscriptionBenefitSearchByBudgetLocationHistory;

  /// No description provided for @subscriptionBenefitPriorityMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'Priority matching results'**
  String get subscriptionBenefitPriorityMatchingResults;

  /// No description provided for @subscriptionNoThanksMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'No thanks, maybe later'**
  String get subscriptionNoThanksMaybeLater;

  /// No description provided for @subscriptionPleaseWaitSeconds.
  ///
  /// In en, this message translates to:
  /// **'Please wait {value1} seconds...'**
  String subscriptionPleaseWaitSeconds(String value1);

  /// No description provided for @chatPhotoReplyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get chatPhotoReplyPlaceholder;

  /// No description provided for @chatMuteConversation.
  ///
  /// In en, this message translates to:
  /// **'Mute conversation'**
  String get chatMuteConversation;

  /// No description provided for @chatUnmuteConversation.
  ///
  /// In en, this message translates to:
  /// **'Unmute conversation'**
  String get chatUnmuteConversation;

  /// No description provided for @chatConversationMuted.
  ///
  /// In en, this message translates to:
  /// **'Conversation muted'**
  String get chatConversationMuted;

  /// No description provided for @chatConversationUnmuted.
  ///
  /// In en, this message translates to:
  /// **'Conversation unmuted'**
  String get chatConversationUnmuted;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get chatTyping;

  /// No description provided for @chatLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {value1}'**
  String chatLastSeen(String value1);

  /// No description provided for @chatReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get chatReasonSpam;

  /// No description provided for @chatReasonHarassmentBullying.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get chatReasonHarassmentBullying;

  /// No description provided for @chatReasonInappropriateContent.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get chatReasonInappropriateContent;

  /// No description provided for @chatReasonScamFraud.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get chatReasonScamFraud;

  /// No description provided for @chatReasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get chatReasonFakeProfile;

  /// No description provided for @chatReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatReasonOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'hi',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
