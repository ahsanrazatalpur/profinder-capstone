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

  /// No description provided for @aboutActionLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutActionLabel;

  /// No description provided for @aboutActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutActionSubtitle;

  /// No description provided for @aboutAppStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get aboutAppStoreLabel;

  /// No description provided for @aboutDisabledBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get aboutDisabledBadgeLabel;

  /// No description provided for @aboutEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any information to show right now.'**
  String get aboutEmptyStateMessage;

  /// No description provided for @aboutEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to Show'**
  String get aboutEmptyStateTitle;

  /// No description provided for @aboutGooglePlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Google Play'**
  String get aboutGooglePlayLabel;

  /// No description provided for @aboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// No description provided for @aboutLinkCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link {value1}'**
  String aboutLinkCouldNotOpen(Object value1);

  /// No description provided for @aboutLinkError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while opening the link {value1}'**
  String aboutLinkError(Object value1);

  /// No description provided for @aboutLinkNoAppFound.
  ///
  /// In en, this message translates to:
  /// **'No app found to open this link {value1}'**
  String aboutLinkNoAppFound(Object value1);

  /// No description provided for @aboutLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load this page'**
  String get aboutLoadError;

  /// No description provided for @aboutLoadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get aboutLoadingText;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @acceptCta.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptCta;

  /// No description provided for @acceptDescription.
  ///
  /// In en, this message translates to:
  /// **'Accept this booking'**
  String get acceptDescription;

  /// No description provided for @acceptLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptLabel;

  /// No description provided for @acceptanceRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Rate'**
  String get acceptanceRateLabel;

  /// No description provided for @acceptanceRateSubtext.
  ///
  /// In en, this message translates to:
  /// **'Of bookings you accept'**
  String get acceptanceRateSubtext;

  /// No description provided for @acceptedLabel.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedLabel;

  /// No description provided for @acceptingBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Accepting Bookings'**
  String get acceptingBookingsLabel;

  /// No description provided for @accountGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountGroupLabel;

  /// No description provided for @accountHolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderLabel;

  /// No description provided for @accountNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumberLabel;

  /// No description provided for @accountSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionLabel;

  /// No description provided for @accountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountTypeLabel;

  /// No description provided for @addBankBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your bank details to receive withdrawals'**
  String get addBankBannerSubtitle;

  /// No description provided for @addBankBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Bank Details'**
  String get addBankBannerTitle;

  /// No description provided for @addBankCta.
  ///
  /// In en, this message translates to:
  /// **'Add Bank Account'**
  String get addBankCta;

  /// No description provided for @addCertificateImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate Image'**
  String get addCertificateImageLabel;

  /// No description provided for @addCertificateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Certificate'**
  String get addCertificateTitle;

  /// No description provided for @addCertificateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a certificate'**
  String get addCertificateTooltip;

  /// No description provided for @addCta.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addCta;

  /// No description provided for @addFirstCertificateCta.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Certificate'**
  String get addFirstCertificateCta;

  /// No description provided for @addFirstItemCta.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Item'**
  String get addFirstItemCta;

  /// No description provided for @addImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImageLabel;

  /// No description provided for @addLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a language and press enter'**
  String get addLanguageHint;

  /// No description provided for @addPhotoCta.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhotoCta;

  /// No description provided for @addPhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhotoTooltip;

  /// No description provided for @addPortfolioHint.
  ///
  /// In en, this message translates to:
  /// **'Showcase your best work to attract more customers'**
  String get addPortfolioHint;

  /// No description provided for @addPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Portfolio Item'**
  String get addPortfolioTitle;

  /// No description provided for @addPortfolioTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add portfolio item'**
  String get addPortfolioTooltip;

  /// No description provided for @addSkillHint.
  ///
  /// In en, this message translates to:
  /// **'Type a skill and press enter'**
  String get addSkillHint;

  /// No description provided for @addWorkSamplesLabel.
  ///
  /// In en, this message translates to:
  /// **'Add work samples'**
  String get addWorkSamplesLabel;

  /// No description provided for @adjustSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get adjustSearchTerms;

  /// No description provided for @adminNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin Note'**
  String get adminNoteLabel;

  /// No description provided for @allCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategoriesTitle;

  /// No description provided for @analyticsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load analytics'**
  String get analyticsErrorTitle;

  /// No description provided for @analyticsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics'**
  String get analyticsLoadError;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @applyCta.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyCta;

  /// No description provided for @approvalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending admin approval'**
  String get approvalSubtitle;

  /// No description provided for @approvalTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval Status'**
  String get approvalTitle;

  /// No description provided for @articleFooterMagazineLabel.
  ///
  /// In en, this message translates to:
  /// **'More from Magazine'**
  String get articleFooterMagazineLabel;

  /// No description provided for @articleLoadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading article...'**
  String get articleLoadingText;

  /// No description provided for @articleNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'Article not found'**
  String get articleNotFoundError;

  /// No description provided for @articleNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This article may have been removed or doesn\'t exist'**
  String get articleNotFoundMessage;

  /// No description provided for @articleReadTime.
  ///
  /// In en, this message translates to:
  /// **'{value1} min read'**
  String articleReadTime(Object value1);

  /// No description provided for @articleReadTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1} min read'**
  String articleReadTimeLabel(Object value1);

  /// No description provided for @automaticDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically accept bookings that meet your criteria'**
  String get automaticDescription;

  /// No description provided for @automaticLabel.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automaticLabel;

  /// No description provided for @availabilityClosedLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get availabilityClosedLabel;

  /// No description provided for @availabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityLabel;

  /// No description provided for @availabilityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load availability'**
  String get availabilityLoadError;

  /// No description provided for @availabilityOffSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re now marked as unavailable'**
  String get availabilityOffSuccess;

  /// No description provided for @availabilityOnSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re now marked as available'**
  String get availabilityOnSuccess;

  /// No description provided for @availabilityScheduleSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save schedule'**
  String get availabilityScheduleSaveError;

  /// No description provided for @availabilityScheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved successfully'**
  String get availabilityScheduleSaved;

  /// No description provided for @availabilityStatusUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update availability status'**
  String get availabilityStatusUpdateError;

  /// No description provided for @availabilityStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Availability set to {value1}'**
  String availabilityStatusUpdated(Object value1);

  /// No description provided for @availabilitySummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your weekly working hours at a glance'**
  String get availabilitySummarySubtitle;

  /// No description provided for @availabilitySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability Summary'**
  String get availabilitySummaryTitle;

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityTitle;

  /// No description provided for @availabilityUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update availability'**
  String get availabilityUpdateError;

  /// No description provided for @availabilityWeeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your working hours for each day'**
  String get availabilityWeeklySubtitle;

  /// No description provided for @availabilityWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get availabilityWeeklyTitle;

  /// No description provided for @availableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available balance: Rs {value1}'**
  String availableBalanceLabel(Object value1);

  /// No description provided for @availableBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalanceTitle;

  /// No description provided for @availableForBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Available for Bookings'**
  String get availableForBookingsLabel;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @availableNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get availableNowLabel;

  /// No description provided for @availableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to accept new bookings'**
  String get availableSubtitle;

  /// No description provided for @averageRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRatingLabel;

  /// No description provided for @averageRatingSubtext.
  ///
  /// In en, this message translates to:
  /// **'Based on customer reviews'**
  String get averageRatingSubtext;

  /// No description provided for @backCta.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backCta;

  /// No description provided for @backToBookingsCta.
  ///
  /// In en, this message translates to:
  /// **'Back to Bookings'**
  String get backToBookingsCta;

  /// No description provided for @backToHomeCta.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHomeCta;

  /// No description provided for @backToLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLoginCta;

  /// No description provided for @bankDetailsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bank details added yet'**
  String get bankDetailsEmpty;

  /// No description provided for @bankDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetailsLabel;

  /// No description provided for @bankDetailsRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please add your bank details before requesting a withdrawal'**
  String get bankDetailsRequiredMessage;

  /// No description provided for @bankDetailsRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Details Required'**
  String get bankDetailsRequiredTitle;

  /// No description provided for @bankDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for withdrawals to your account'**
  String get bankDetailsSubtitle;

  /// No description provided for @bankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankNameLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @bookAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointmentTitle;

  /// No description provided for @bookCta.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookCta;

  /// No description provided for @bookNowCta.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNowCta;

  /// No description provided for @bookingConfigurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Configuration'**
  String get bookingConfigurationTitle;

  /// No description provided for @bookingDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get bookingDateRequired;

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetailsTitle;

  /// No description provided for @bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking failed. Please try again.'**
  String get bookingFailed;

  /// No description provided for @bookingManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Bookings'**
  String get bookingManagementTitle;

  /// No description provided for @bookingSoFarLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings so far'**
  String get bookingSoFarLabel;

  /// No description provided for @bookingStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Booking marked as {value1}'**
  String bookingStatusUpdated(Object value1);

  /// No description provided for @bookingSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your booking request with {value1} has been sent'**
  String bookingSuccessMessage(Object value1);

  /// No description provided for @bookingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Requested'**
  String get bookingSuccessTitle;

  /// No description provided for @bookingTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get bookingTimeRequired;

  /// No description provided for @bookingTipText.
  ///
  /// In en, this message translates to:
  /// **'You can cancel for free up to 24 hours before the appointment'**
  String get bookingTipText;

  /// No description provided for @bookingUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update booking'**
  String get bookingUpdateError;

  /// No description provided for @bookingUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Booking updated to {value1}'**
  String bookingUpdatedToast(Object value1);

  /// No description provided for @bookingsActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsActionLabel;

  /// No description provided for @bookingsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your booking history'**
  String get bookingsActionSubtitle;

  /// No description provided for @bookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsLabel;

  /// No description provided for @bookingsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsStatLabel;

  /// No description provided for @bufferMinLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1} min buffer'**
  String bufferMinLabel(Object value1);

  /// No description provided for @bufferNoneLabel.
  ///
  /// In en, this message translates to:
  /// **'No buffer'**
  String get bufferNoneLabel;

  /// No description provided for @bufferTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time between consecutive bookings'**
  String get bufferTimeSubtitle;

  /// No description provided for @bufferTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Buffer Time'**
  String get bufferTimeTitle;

  /// No description provided for @calendarWeekDays.
  ///
  /// In en, this message translates to:
  /// **'S,M,T,W,T,F,S'**
  String get calendarWeekDays;

  /// No description provided for @cameraOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraOptionLabel;

  /// No description provided for @cancelBookingCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBookingCta;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBookingTitle;

  /// No description provided for @cancelConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get cancelConfirmationMessage;

  /// No description provided for @cancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelCta;

  /// No description provided for @cancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Let us know why you are cancelling'**
  String get cancelReasonHint;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation'**
  String get cancelReasonLabel;

  /// No description provided for @cancellationPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy'**
  String get cancellationPolicyLabel;

  /// No description provided for @cancelledByCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by customer'**
  String get cancelledByCustomerLabel;

  /// No description provided for @cancelledByYouLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by you'**
  String get cancelledByYouLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @certificateAddError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add certificate'**
  String get certificateAddError;

  /// No description provided for @certificateAddSuccess.
  ///
  /// In en, this message translates to:
  /// **'Certificate added successfully'**
  String get certificateAddSuccess;

  /// No description provided for @certificateTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Certified Plumbing Technician'**
  String get certificateTitleHint;

  /// No description provided for @certificateTitleLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Certificate Title'**
  String get certificateTitleLabelRequired;

  /// No description provided for @certificatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificatesLabel;

  /// No description provided for @certificatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificatesTitle;

  /// No description provided for @certificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certificationsLabel;

  /// No description provided for @changePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordLabel;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changeProfilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhotoTitle;

  /// No description provided for @chatMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record voice messages'**
  String get chatMicPermissionRequired;

  /// No description provided for @chatNoMessagesFound.
  ///
  /// In en, this message translates to:
  /// **'No messages found'**
  String get chatNoMessagesFound;

  /// No description provided for @chatSearchMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get chatSearchMessagesHint;

  /// No description provided for @chatTypeToSearchConversation.
  ///
  /// In en, this message translates to:
  /// **'Type to search this conversation'**
  String get chatTypeToSearchConversation;

  /// No description provided for @checkEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it? Check your spam folder.'**
  String get checkEmailHint;

  /// No description provided for @checkEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to your email'**
  String get checkEmailMessage;

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkEmailTitle;

  /// No description provided for @cityDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Select a country first'**
  String get cityDisabledHint;

  /// No description provided for @cityEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get cityEmptyMessage;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get cityHint;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @cityRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get cityRequiredError;

  /// No description provided for @citySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get citySearchHint;

  /// No description provided for @clearCta.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCta;

  /// No description provided for @clientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsLabel;

  /// No description provided for @closeCta.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeCta;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'{value1} is coming soon'**
  String comingSoonMessage(Object value1);

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with {value1}'**
  String commentHint(Object value1);

  /// No description provided for @commentOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment Optional'**
  String get commentOptionalLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @confirmBookingCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBookingCta;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @contactChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat with us'**
  String get contactChatLabel;

  /// No description provided for @contactChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a quick response in chat'**
  String get contactChatSubtitle;

  /// No description provided for @contactChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Support'**
  String get contactChatTitle;

  /// No description provided for @contactCta.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactCta;

  /// No description provided for @contactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get contactEmailLabel;

  /// No description provided for @contactEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll get back to you within 24 hours'**
  String get contactEmailSubtitle;

  /// No description provided for @contactEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get contactEmailTitle;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTitle;

  /// No description provided for @continueAsGuestCta.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuestCta;

  /// No description provided for @countryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get countryEmptyMessage;

  /// No description provided for @countryHint.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get countryHint;

  /// No description provided for @countryRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get countryRequiredError;

  /// No description provided for @countrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get countrySearchHint;

  /// No description provided for @currencyFeatureName.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyFeatureName;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current plan: {value1}'**
  String currentPlanLabel(Object value1);

  /// No description provided for @currentlyBusyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currently Busy'**
  String get currentlyBusyLabel;

  /// No description provided for @customLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a custom location'**
  String get customLocationHint;

  /// No description provided for @customLocationOption.
  ///
  /// In en, this message translates to:
  /// **'Custom Location'**
  String get customLocationOption;

  /// No description provided for @customLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter an address manually'**
  String get customLocationSubtitle;

  /// No description provided for @customSlotDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customSlotDefaultLabel;

  /// No description provided for @customSlotHint.
  ///
  /// In en, this message translates to:
  /// **'Enter duration in minutes'**
  String get customSlotHint;

  /// No description provided for @customSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom ({value1})'**
  String customSlotLabel(Object value1);

  /// No description provided for @customSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Slot Duration'**
  String get customSlotTitle;

  /// No description provided for @customSlotValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid duration'**
  String get customSlotValidation;

  /// No description provided for @customerAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Book trusted professionals near you'**
  String get customerAccountDescription;

  /// No description provided for @customerDefault.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerDefault;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @dailyHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Hours'**
  String get dailyHoursLabel;

  /// No description provided for @darkModeOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get darkModeOffLabel;

  /// No description provided for @darkModeOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeOnLabel;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get dashboardLoadError;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @dateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Date not set'**
  String get dateNotSet;

  /// No description provided for @dateNotSetShort.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get dateNotSetShort;

  /// No description provided for @dateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get dateRequiredMessage;

  /// No description provided for @dateTipText.
  ///
  /// In en, this message translates to:
  /// **'Choose a date that works best for you'**
  String get dateTipText;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1}d'**
  String daysLabel(Object value1);

  /// No description provided for @declineCta.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineCta;

  /// No description provided for @declineDescription.
  ///
  /// In en, this message translates to:
  /// **'Decline this booking'**
  String get declineDescription;

  /// No description provided for @declineLabel.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineLabel;

  /// No description provided for @deleteAccountDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all associated data. This action cannot be undone.'**
  String get deleteAccountDialogContent;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountLabel;

  /// No description provided for @deleteConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get deleteConfirmationTitle;

  /// No description provided for @deleteCta.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteCta;

  /// No description provided for @deleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{value1}\"?'**
  String deleteDialogContent(Object value1);

  /// No description provided for @deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteDialogTitle;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get deleteError;

  /// No description provided for @deleteGalleryDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get deleteGalleryDialogContent;

  /// No description provided for @deleteGalleryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deleteGalleryDialogTitle;

  /// No description provided for @deleteReviewConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this review?'**
  String get deleteReviewConfirmationMessage;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get descriptionHint;

  /// No description provided for @descriptionLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionLabelOptional;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @directChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get directChatLabel;

  /// No description provided for @discardCta.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardCta;

  /// No description provided for @doneCta.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneCta;

  /// No description provided for @earningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsLabel;

  /// No description provided for @editCta.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editCta;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @editProfileActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileActionLabel;

  /// No description provided for @editProfileActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get editProfileActionSubtitle;

  /// No description provided for @editReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Update your comment'**
  String get editReviewHint;

  /// No description provided for @editReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your rating and comment'**
  String get editReviewSubtitle;

  /// No description provided for @editReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Review'**
  String get editReviewTitle;

  /// No description provided for @editorHeadingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get editorHeadingPlaceholder;

  /// No description provided for @editorHintText.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get editorHintText;

  /// No description provided for @editorInsertCta.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get editorInsertCta;

  /// No description provided for @editorInsertLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert Link'**
  String get editorInsertLinkTitle;

  /// No description provided for @editorLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get editorLinkHint;

  /// No description provided for @editorLinkPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Link text'**
  String get editorLinkPlaceholder;

  /// No description provided for @educationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationLabel;

  /// No description provided for @emailAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Email is available'**
  String get emailAvailableLabel;

  /// No description provided for @emailNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotificationsLabel;

  /// No description provided for @emailTakenLabel.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailTakenLabel;

  /// No description provided for @emptyCertificatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your certifications to build trust with customers'**
  String get emptyCertificatesSubtitle;

  /// No description provided for @emptyCertificatesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Certificates Yet'**
  String get emptyCertificatesTitle;

  /// No description provided for @emptyGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add photos to showcase your work'**
  String get emptyGallerySubtitle;

  /// No description provided for @emptyGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'No Photos Yet'**
  String get emptyGalleryTitle;

  /// No description provided for @emptyPortfolioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your best work to attract more customers'**
  String get emptyPortfolioSubtitle;

  /// No description provided for @emptyPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'No Portfolio Items Yet'**
  String get emptyPortfolioTitle;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeLabel;

  /// No description provided for @enterAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmountHint;

  /// No description provided for @exceedsBalanceError.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds your available balance'**
  String get exceedsBalanceError;

  /// No description provided for @exceptionsAddRange.
  ///
  /// In en, this message translates to:
  /// **'Add Date Range'**
  String get exceptionsAddRange;

  /// No description provided for @exceptionsCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a date to set an exception'**
  String get exceptionsCalendarSubtitle;

  /// No description provided for @exceptionsCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get exceptionsCalendarTitle;

  /// No description provided for @exceptionsCustomChip.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get exceptionsCustomChip;

  /// No description provided for @exceptionsEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get exceptionsEndDate;

  /// No description provided for @exceptionsIntroText.
  ///
  /// In en, this message translates to:
  /// **'Mark dates when your availability differs from your usual schedule'**
  String get exceptionsIntroText;

  /// No description provided for @exceptionsLegendClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get exceptionsLegendClosed;

  /// No description provided for @exceptionsLegendCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Hours'**
  String get exceptionsLegendCustom;

  /// No description provided for @exceptionsLegendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get exceptionsLegendUnavailable;

  /// No description provided for @exceptionsLegendVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get exceptionsLegendVacation;

  /// No description provided for @exceptionsLegendWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get exceptionsLegendWorking;

  /// No description provided for @exceptionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load exceptions'**
  String get exceptionsLoadError;

  /// No description provided for @exceptionsNoOverrides.
  ///
  /// In en, this message translates to:
  /// **'No exceptions set'**
  String get exceptionsNoOverrides;

  /// No description provided for @exceptionsOverridesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dates with custom availability'**
  String get exceptionsOverridesSubtitle;

  /// No description provided for @exceptionsOverridesTitle.
  ///
  /// In en, this message translates to:
  /// **'Overrides'**
  String get exceptionsOverridesTitle;

  /// No description provided for @exceptionsReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get exceptionsReasonLabel;

  /// No description provided for @exceptionsSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get exceptionsSelectDate;

  /// No description provided for @exceptionsSetVacation.
  ///
  /// In en, this message translates to:
  /// **'Set Vacation'**
  String get exceptionsSetVacation;

  /// No description provided for @exceptionsStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get exceptionsStartDate;

  /// No description provided for @exceptionsTimeError.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get exceptionsTimeError;

  /// No description provided for @exceptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability Exceptions'**
  String get exceptionsTitle;

  /// No description provided for @exceptionsUnavailableChip.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get exceptionsUnavailableChip;

  /// No description provided for @exceptionsUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark as unavailable'**
  String get exceptionsUnavailableLabel;

  /// No description provided for @exceptionsUpdateVacation.
  ///
  /// In en, this message translates to:
  /// **'Update Vacation'**
  String get exceptionsUpdateVacation;

  /// No description provided for @exceptionsVacationActive.
  ///
  /// In en, this message translates to:
  /// **'Vacation is currently active'**
  String get exceptionsVacationActive;

  /// No description provided for @exceptionsVacationScheduled.
  ///
  /// In en, this message translates to:
  /// **'Vacation scheduled from {value1}'**
  String exceptionsVacationScheduled(Object value1);

  /// No description provided for @exceptionsVacationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a date range when you are away'**
  String get exceptionsVacationSubtitle;

  /// No description provided for @exceptionsVacationTitle.
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode'**
  String get exceptionsVacationTitle;

  /// No description provided for @experienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceLabel;

  /// No description provided for @experienceYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1} years experience'**
  String experienceYearsLabel(Object value1);

  /// No description provided for @exploreExpertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Explore Experts'**
  String get exploreExpertsLabel;

  /// No description provided for @facebookSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get facebookSignInLabel;

  /// No description provided for @faqBookingPendingA.
  ///
  /// In en, this message translates to:
  /// **'It may take a little time for the professional to respond. You will be notified once they accept or decline.'**
  String get faqBookingPendingA;

  /// No description provided for @faqBookingPendingQ.
  ///
  /// In en, this message translates to:
  /// **'Why is my booking still pending?'**
  String get faqBookingPendingQ;

  /// No description provided for @faqChangeAvailabilityA.
  ///
  /// In en, this message translates to:
  /// **'Go to your Availability settings from your profile to update your working hours.'**
  String get faqChangeAvailabilityA;

  /// No description provided for @faqChangeAvailabilityQ.
  ///
  /// In en, this message translates to:
  /// **'How do I change my availability?'**
  String get faqChangeAvailabilityQ;

  /// No description provided for @faqGetVerifiedA.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile and submit the required documents from your profile settings to request verification.'**
  String get faqGetVerifiedA;

  /// No description provided for @faqGetVerifiedQ.
  ///
  /// In en, this message translates to:
  /// **'How do I get verified?'**
  String get faqGetVerifiedQ;

  /// No description provided for @faqHowToBookA.
  ///
  /// In en, this message translates to:
  /// **'Search for a professional, view their profile, and tap Book Now to select a date and time.'**
  String get faqHowToBookA;

  /// No description provided for @faqHowToBookQ.
  ///
  /// In en, this message translates to:
  /// **'How do I book a professional?'**
  String get faqHowToBookQ;

  /// No description provided for @faqHowToCancelA.
  ///
  /// In en, this message translates to:
  /// **'Open the booking from My Bookings and tap Cancel. Cancellations made in time are free.'**
  String get faqHowToCancelA;

  /// No description provided for @faqHowToCancelQ.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel a booking?'**
  String get faqHowToCancelQ;

  /// No description provided for @faqImproveProfileA.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo, portfolio samples, and certificates to build trust with customers.'**
  String get faqImproveProfileA;

  /// No description provided for @faqImproveProfileQ.
  ///
  /// In en, this message translates to:
  /// **'How can I improve my profile?'**
  String get faqImproveProfileQ;

  /// No description provided for @faqPaymentSecureA.
  ///
  /// In en, this message translates to:
  /// **'Yes, all payments are processed securely and your details are never shared.'**
  String get faqPaymentSecureA;

  /// No description provided for @faqPaymentSecureQ.
  ///
  /// In en, this message translates to:
  /// **'Is my payment information secure?'**
  String get faqPaymentSecureQ;

  /// No description provided for @faqRefundsA.
  ///
  /// In en, this message translates to:
  /// **'Refunds are processed automatically for eligible cancellations within a few business days.'**
  String get faqRefundsA;

  /// No description provided for @faqRefundsQ.
  ///
  /// In en, this message translates to:
  /// **'How do refunds work?'**
  String get faqRefundsQ;

  /// No description provided for @faqSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqSectionLabel;

  /// No description provided for @faqSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqSectionTitle;

  /// No description provided for @faqWithdrawEarningsA.
  ///
  /// In en, this message translates to:
  /// **'Go to your Wallet and tap Withdraw to transfer your earnings to your bank account.'**
  String get faqWithdrawEarningsA;

  /// No description provided for @faqWithdrawEarningsQ.
  ///
  /// In en, this message translates to:
  /// **'How do I withdraw my earnings?'**
  String get faqWithdrawEarningsQ;

  /// No description provided for @fastResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'Fast Response'**
  String get fastResponseLabel;

  /// No description provided for @flexibleTimingLabel.
  ///
  /// In en, this message translates to:
  /// **'Flexible Timing'**
  String get flexibleTimingLabel;

  /// No description provided for @freeToCancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Free to Cancel'**
  String get freeToCancelLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @galleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryLabel;

  /// No description provided for @galleryOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryOptionLabel;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @galleryUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get galleryUploadError;

  /// No description provided for @galleryUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully'**
  String get galleryUploadSuccess;

  /// No description provided for @goBackCta.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBackCta;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodAfternoonComma.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoonComma;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodEveningComma.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEveningComma;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodMorningComma.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorningComma;

  /// No description provided for @goodToKnowLabel.
  ///
  /// In en, this message translates to:
  /// **'Good to Know'**
  String get goodToKnowLabel;

  /// No description provided for @googleSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignInLabel;

  /// No description provided for @helpActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpActionLabel;

  /// No description provided for @helpActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help or contact us'**
  String get helpActionSubtitle;

  /// No description provided for @helpSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportLabel;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @homeDefaultPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get homeDefaultPlanFree;

  /// No description provided for @homeDefaultProfessionalName.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get homeDefaultProfessionalName;

  /// No description provided for @homeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeFilterAll;

  /// No description provided for @homeFilterAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get homeFilterAvailableNow;

  /// No description provided for @homeFilterFastResponse.
  ///
  /// In en, this message translates to:
  /// **'Fast Response'**
  String get homeFilterFastResponse;

  /// No description provided for @homeFilterHighestPrice.
  ///
  /// In en, this message translates to:
  /// **'Highest Price'**
  String get homeFilterHighestPrice;

  /// No description provided for @homeFilterLowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest Price'**
  String get homeFilterLowestPrice;

  /// No description provided for @homeFilterMostBooked.
  ///
  /// In en, this message translates to:
  /// **'Most Booked'**
  String get homeFilterMostBooked;

  /// No description provided for @homeFilterMostExperienced.
  ///
  /// In en, this message translates to:
  /// **'Most Experienced'**
  String get homeFilterMostExperienced;

  /// No description provided for @homeFilterMostReviews.
  ///
  /// In en, this message translates to:
  /// **'Most Reviews'**
  String get homeFilterMostReviews;

  /// No description provided for @homeFilterRating1Plus.
  ///
  /// In en, this message translates to:
  /// **'1+ Stars'**
  String get homeFilterRating1Plus;

  /// No description provided for @homeFilterRating2Plus.
  ///
  /// In en, this message translates to:
  /// **'2+ Stars'**
  String get homeFilterRating2Plus;

  /// No description provided for @homeFilterRating3Plus.
  ///
  /// In en, this message translates to:
  /// **'3+ Stars'**
  String get homeFilterRating3Plus;

  /// No description provided for @homeFilterRating4Plus.
  ///
  /// In en, this message translates to:
  /// **'4+ Stars'**
  String get homeFilterRating4Plus;

  /// No description provided for @homeFilterRating5Plus.
  ///
  /// In en, this message translates to:
  /// **'5 Stars'**
  String get homeFilterRating5Plus;

  /// No description provided for @homeFilterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get homeFilterThisMonth;

  /// No description provided for @homeFilterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get homeFilterThisWeek;

  /// No description provided for @homeFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeFilterToday;

  /// No description provided for @homeFilterTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get homeFilterTopRated;

  /// No description provided for @homeFilterVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get homeFilterVerified;

  /// No description provided for @homeFilterWithin10Km.
  ///
  /// In en, this message translates to:
  /// **'Within 10 km'**
  String get homeFilterWithin10Km;

  /// No description provided for @homeFilterWithin2Km.
  ///
  /// In en, this message translates to:
  /// **'Within 2 km'**
  String get homeFilterWithin2Km;

  /// No description provided for @homeFilterWithin5Km.
  ///
  /// In en, this message translates to:
  /// **'Within 5 km'**
  String get homeFilterWithin5Km;

  /// No description provided for @homeGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get homeGoBack;

  /// No description provided for @homeNoProfessionalsFound.
  ///
  /// In en, this message translates to:
  /// **'No professionals found'**
  String get homeNoProfessionalsFound;

  /// No description provided for @homeNoProfessionalsFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search a different area'**
  String get homeNoProfessionalsFoundHint;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRateLabel;

  /// No description provided for @hoursDecimalLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1}h'**
  String hoursDecimalLabel(Object value1);

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1}h'**
  String hoursLabel(Object value1);

  /// No description provided for @hoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{value1}h {value2}m'**
  String hoursMinutesShort(Object value1, Object value2);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{value1}h'**
  String hoursShort(Object value1);

  /// No description provided for @idVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'ID Verified'**
  String get idVerifiedLabel;

  /// No description provided for @imagePickError.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image'**
  String get imagePickError;

  /// No description provided for @instantLabel.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get instantLabel;

  /// No description provided for @issueDateLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Issue Date (optional)'**
  String get issueDateLabelOptional;

  /// No description provided for @issuingOrganizationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. National Skills Board'**
  String get issuingOrganizationHint;

  /// No description provided for @issuingOrganizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuing Organization'**
  String get issuingOrganizationLabel;

  /// No description provided for @jobsDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Jobs Done'**
  String get jobsDoneLabel;

  /// No description provided for @languagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesLabel;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {value1}'**
  String lastUpdatedLabel(Object value1);

  /// No description provided for @laterCta.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterCta;

  /// No description provided for @loadBookingsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bookings'**
  String get loadBookingsError;

  /// No description provided for @loadCertificatesError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load certificates'**
  String get loadCertificatesError;

  /// No description provided for @loadGalleryError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load gallery'**
  String get loadGalleryError;

  /// No description provided for @loadPortfolioError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load portfolio'**
  String get loadPortfolioError;

  /// No description provided for @loadSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings'**
  String get loadSettingsError;

  /// No description provided for @loadWalletError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wallet'**
  String get loadWalletError;

  /// No description provided for @loadingAnalyticsText.
  ///
  /// In en, this message translates to:
  /// **'Loading analytics...'**
  String get loadingAnalyticsText;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get loadingDashboard;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Location not specified'**
  String get locationNotSpecified;

  /// No description provided for @locationTipText.
  ///
  /// In en, this message translates to:
  /// **'Enable location for more accurate results'**
  String get locationTipText;

  /// No description provided for @loginCta.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginCta;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginToBookCta.
  ///
  /// In en, this message translates to:
  /// **'Login to Book'**
  String get loginToBookCta;

  /// No description provided for @logoutActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutActionLabel;

  /// No description provided for @logoutActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get logoutActionSubtitle;

  /// No description provided for @logoutCta.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutCta;

  /// No description provided for @logoutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutDialogContent;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutDialogTitle;

  /// No description provided for @magazineAllCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get magazineAllCategoriesLabel;

  /// No description provided for @magazineArticleCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{value1} articles'**
  String magazineArticleCountPlural(Object value1);

  /// No description provided for @magazineArticleCountSingle.
  ///
  /// In en, this message translates to:
  /// **'1 article'**
  String get magazineArticleCountSingle;

  /// No description provided for @magazineClearSearchCta.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get magazineClearSearchCta;

  /// No description provided for @magazineEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No articles available right now'**
  String get magazineEmptyMessage;

  /// No description provided for @magazineEmptySearchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get magazineEmptySearchMessage;

  /// No description provided for @magazineEmptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get magazineEmptySearchTitle;

  /// No description provided for @magazineEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Articles Yet'**
  String get magazineEmptyTitle;

  /// No description provided for @magazineErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading the magazine'**
  String get magazineErrorMessage;

  /// No description provided for @magazineErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load'**
  String get magazineErrorTitle;

  /// No description provided for @magazineLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load magazine'**
  String get magazineLoadError;

  /// No description provided for @magazineLoadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading articles...'**
  String get magazineLoadingText;

  /// No description provided for @magazineSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles'**
  String get magazineSearchHint;

  /// No description provided for @magazineSearchResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get magazineSearchResultsLabel;

  /// No description provided for @magazineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tips and stories for professionals'**
  String get magazineSubtitle;

  /// No description provided for @magazineTitle.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get magazineTitle;

  /// No description provided for @manageCta.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageCta;

  /// No description provided for @manageLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageLabel;

  /// No description provided for @manualDescription.
  ///
  /// In en, this message translates to:
  /// **'Review and accept bookings yourself'**
  String get manualDescription;

  /// No description provided for @manualInfoFooter.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings'**
  String get manualInfoFooter;

  /// No description provided for @manualInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Approval'**
  String get manualInfoTitle;

  /// No description provided for @manualLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualLabel;

  /// No description provided for @markCompletedCta.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markCompletedCta;

  /// No description provided for @markCompletedCtaShort.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get markCompletedCtaShort;

  /// No description provided for @maxAdvanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How far in advance customers can book'**
  String get maxAdvanceSubtitle;

  /// No description provided for @maxAdvanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Max Advance Booking'**
  String get maxAdvanceTitle;

  /// No description provided for @memberSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSinceLabel;

  /// No description provided for @messagesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with a professional or customer'**
  String get messagesEmptySubtitle;

  /// No description provided for @messagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Messages Yet'**
  String get messagesEmptyTitle;

  /// No description provided for @messagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get messagesLoadError;

  /// No description provided for @messagesLoadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading messages...'**
  String get messagesLoadingText;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @minAmountError.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal amount is Rs {value1}'**
  String minAmountError(Object value1);

  /// No description provided for @minNoticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum time before a booking can start'**
  String get minNoticeSubtitle;

  /// No description provided for @minNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum Notice'**
  String get minNoticeTitle;

  /// No description provided for @minWithdrawalLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal: Rs {value1}'**
  String minWithdrawalLabel(Object value1);

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1}m'**
  String minutesLabel(Object value1);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{value1}m'**
  String minutesShort(Object value1);

  /// No description provided for @minutesZero.
  ///
  /// In en, this message translates to:
  /// **'0 minutes'**
  String get minutesZero;

  /// No description provided for @myPortfolioLabel.
  ///
  /// In en, this message translates to:
  /// **'My Portfolio'**
  String get myPortfolioLabel;

  /// No description provided for @myPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'My Portfolio'**
  String get myPortfolioTitle;

  /// No description provided for @myReviewsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews you write will appear here'**
  String get myReviewsEmptySubtitle;

  /// No description provided for @myReviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Reviews Yet'**
  String get myReviewsEmptyTitle;

  /// No description provided for @myReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get myReviewsTitle;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navMagazine.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get navMagazine;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @nearbyLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyLabel;

  /// No description provided for @needMoreHelpLabel.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get needMoreHelpLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @newPhotoSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'New photo selected'**
  String get newPhotoSelectedHint;

  /// No description provided for @nextCta.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextCta;

  /// No description provided for @noBookingsAccepted.
  ///
  /// In en, this message translates to:
  /// **'No accepted bookings'**
  String get noBookingsAccepted;

  /// No description provided for @noBookingsAll.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsAll;

  /// No description provided for @noBookingsCancelled.
  ///
  /// In en, this message translates to:
  /// **'No cancelled bookings'**
  String get noBookingsCancelled;

  /// No description provided for @noBookingsCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed bookings'**
  String get noBookingsCompleted;

  /// No description provided for @noBookingsDefault.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsDefault;

  /// No description provided for @noBookingsPending.
  ///
  /// In en, this message translates to:
  /// **'No pending bookings'**
  String get noBookingsPending;

  /// No description provided for @noBookingsRescheduled.
  ///
  /// In en, this message translates to:
  /// **'No rescheduled bookings'**
  String get noBookingsRescheduled;

  /// No description provided for @noBookingsToday.
  ///
  /// In en, this message translates to:
  /// **'No bookings today'**
  String get noBookingsToday;

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsYet;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found'**
  String get noClientsFound;

  /// No description provided for @noLanguagesAdded.
  ///
  /// In en, this message translates to:
  /// **'No languages added yet'**
  String get noLanguagesAdded;

  /// No description provided for @noMessagesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesPlaceholder;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noPaymentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment history will appear here'**
  String get noPaymentsSubtitle;

  /// No description provided for @noPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Payments Yet'**
  String get noPaymentsTitle;

  /// No description provided for @noPortfolioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio items will appear here'**
  String get noPortfolioSubtitle;

  /// No description provided for @noPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'No Portfolio Items'**
  String get noPortfolioTitle;

  /// No description provided for @noReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews will appear here once customers rate you'**
  String get noReviewsSubtitle;

  /// No description provided for @noReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Reviews Yet'**
  String get noReviewsTitle;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @noServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add services you offer to attract customers'**
  String get noServicesSubtitle;

  /// No description provided for @noServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Services Added'**
  String get noServicesTitle;

  /// No description provided for @noSkillsAdded.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet'**
  String get noSkillsAdded;

  /// No description provided for @noTransactionsLabel.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsLabel;

  /// No description provided for @noWorkingHoursMessage.
  ///
  /// In en, this message translates to:
  /// **'No working hours set for this day'**
  String get noWorkingHoursMessage;

  /// No description provided for @notAcceptingBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Not Accepting Bookings'**
  String get notAcceptingBookingsLabel;

  /// No description provided for @notAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailableLabel;

  /// No description provided for @notAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not accepting bookings right now'**
  String get notAvailableSubtitle;

  /// No description provided for @notSetPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSetPlaceholder;

  /// No description provided for @notSpecifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecifiedLabel;

  /// No description provided for @notVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerifiedLabel;

  /// No description provided for @notesHintText.
  ///
  /// In en, this message translates to:
  /// **'Add any notes here'**
  String get notesHintText;

  /// No description provided for @notesInfoText.
  ///
  /// In en, this message translates to:
  /// **'Notes are only visible to you'**
  String get notesInfoText;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesTipText.
  ///
  /// In en, this message translates to:
  /// **'Add any special requests or details'**
  String get notesTipText;

  /// No description provided for @notificationsActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsActionLabel;

  /// No description provided for @notificationsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationsActionSubtitle;

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{value1}d ago'**
  String notificationsDaysAgo(Object value1);

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notifications'**
  String get notificationsErrorTitle;

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{value1}h ago'**
  String notificationsHoursAgo(Object value1);

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get notificationsLoadError;

  /// No description provided for @notificationsLoadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications...'**
  String get notificationsLoadingText;

  /// No description provided for @notificationsMarkAllReadCta.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllReadCta;

  /// No description provided for @notificationsMarkAllReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsMarkAllReadSuccess;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{value1}m ago'**
  String notificationsMinutesAgo(Object value1);

  /// No description provided for @notificationsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSectionLabel;

  /// No description provided for @notificationsSectionThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get notificationsSectionThisMonth;

  /// No description provided for @notificationsSectionThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get notificationsSectionThisWeek;

  /// No description provided for @notificationsSectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsSectionToday;

  /// No description provided for @notificationsSectionYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationsSectionYesterday;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notifyCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Notify the customer about the new time: {value1} at {value2}?'**
  String notifyCustomerMessage(Object value1, Object value2);

  /// No description provided for @notifyCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Notify Customer'**
  String get notifyCustomerTitle;

  /// No description provided for @offlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineLabel;

  /// No description provided for @okCta.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okCta;

  /// No description provided for @onlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineLabel;

  /// No description provided for @openChatCta.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChatCta;

  /// No description provided for @openChatCtaShort.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get openChatCtaShort;

  /// No description provided for @openChatError.
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat'**
  String get openChatError;

  /// No description provided for @orContinueWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWithLabel;

  /// No description provided for @overrideRemoved.
  ///
  /// In en, this message translates to:
  /// **'Exception removed'**
  String get overrideRemoved;

  /// No description provided for @overrideSaved.
  ///
  /// In en, this message translates to:
  /// **'Exception saved for {value1}'**
  String overrideSaved(Object value1);

  /// No description provided for @passwordChangeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get passwordChangeError;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangeSuccess;

  /// No description provided for @passwordHelperText.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters'**
  String get passwordHelperText;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLengthError;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatchError;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequiredError;

  /// No description provided for @paymentHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistoryLabel;

  /// No description provided for @paymentHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View all your past payments'**
  String get paymentHistorySubtitle;

  /// No description provided for @paymentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get paymentStatusCompleted;

  /// No description provided for @paymentStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentStatusFailed;

  /// No description provided for @paymentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// No description provided for @paymentsActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsActionLabel;

  /// No description provided for @paymentsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your payment history'**
  String get paymentsActionSubtitle;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @perHourLabel.
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get perHourLabel;

  /// No description provided for @performanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performanceLabel;

  /// No description provided for @performanceScoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Based on your ratings, response time, and completed bookings'**
  String get performanceScoreInfo;

  /// No description provided for @performanceScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Performance Score'**
  String get performanceScoreLabel;

  /// No description provided for @performanceScoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{value1} out of 100'**
  String performanceScoreOutOf(Object value1);

  /// No description provided for @personalInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfoLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @photoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {value1} photos'**
  String photoLimitReached(Object value1);

  /// No description provided for @photoPickError.
  ///
  /// In en, this message translates to:
  /// **'Failed to select photo'**
  String get photoPickError;

  /// No description provided for @photosOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional)'**
  String get photosOptionalLabel;

  /// No description provided for @planStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planStatLabel;

  /// No description provided for @planUpgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock more features and grow your business'**
  String get planUpgradeSubtitle;

  /// No description provided for @planUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade from {value1}'**
  String planUpgradeTitle(Object value1);

  /// No description provided for @portfolioInfoNote.
  ///
  /// In en, this message translates to:
  /// **'Showcase your best work to attract more customers'**
  String get portfolioInfoNote;

  /// No description provided for @portfolioLabel.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioLabel;

  /// No description provided for @postReplyCta.
  ///
  /// In en, this message translates to:
  /// **'Post Reply'**
  String get postReplyCta;

  /// No description provided for @preferencesGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesGroupLabel;

  /// No description provided for @preferencesSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSectionLabel;

  /// No description provided for @premiumActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have access to all premium features'**
  String get premiumActiveSubtitle;

  /// No description provided for @premiumMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium Member'**
  String get premiumMemberLabel;

  /// No description provided for @premiumUpgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited AI searches and more'**
  String get premiumUpgradeSubtitle;

  /// No description provided for @proBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proBadgeLabel;

  /// No description provided for @professionEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No professions found'**
  String get professionEmptyMessage;

  /// No description provided for @professionHint.
  ///
  /// In en, this message translates to:
  /// **'Select profession'**
  String get professionHint;

  /// No description provided for @professionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get professionLabel;

  /// No description provided for @professionRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a profession'**
  String get professionRequiredError;

  /// No description provided for @professionSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search profession'**
  String get professionSearchHint;

  /// No description provided for @professionalAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Offer your services to customers'**
  String get professionalAccountDescription;

  /// No description provided for @professionalDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professionalDefaultName;

  /// No description provided for @professionalDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load professional details'**
  String get professionalDetailLoadError;

  /// No description provided for @professionalDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional Details'**
  String get professionalDetailsLabel;

  /// No description provided for @professionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professionalLabel;

  /// No description provided for @professionalLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional\'s Location'**
  String get professionalLocationLabel;

  /// No description provided for @professionalLocationOption.
  ///
  /// In en, this message translates to:
  /// **'Professional\'s Location'**
  String get professionalLocationOption;

  /// No description provided for @professionalReviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get professionalReviewsLabel;

  /// No description provided for @professionalReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What customers are saying'**
  String get professionalReviewsSubtitle;

  /// No description provided for @profileCompletionHint.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to attract more customers'**
  String get profileCompletionHint;

  /// No description provided for @profileCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletionLabel;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadError;

  /// No description provided for @profileLoadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get profileLoadingText;

  /// No description provided for @profileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Profile not available'**
  String get profileNotAvailable;

  /// No description provided for @profileOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profileOff;

  /// No description provided for @profileOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profileOn;

  /// No description provided for @profileReviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get profileReviewsLabel;

  /// No description provided for @profileSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSavedLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateError;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccess;

  /// No description provided for @profileViewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Views'**
  String get profileViewsLabel;

  /// No description provided for @profileViewsSubtext.
  ///
  /// In en, this message translates to:
  /// **'People who viewed your profile'**
  String get profileViewsSubtext;

  /// No description provided for @profileWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get profileWalletLabel;

  /// No description provided for @pushNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsLabel;

  /// No description provided for @quickActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsLabel;

  /// No description provided for @quickAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAddLabel;

  /// No description provided for @rateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateLabel;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingLabel;

  /// No description provided for @ratingRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get ratingRequiredError;

  /// No description provided for @recentBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Bookings'**
  String get recentBookingsLabel;

  /// No description provided for @recentMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Messages'**
  String get recentMessagesLabel;

  /// No description provided for @recentReviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Reviews'**
  String get recentReviewsLabel;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @registerCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get registerCategoryRequired;

  /// No description provided for @registerCta.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerCta;

  /// No description provided for @registerServerError.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerServerError;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get registerSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @rejectCta.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectCta;

  /// No description provided for @relatedProfessionalsLabel.
  ///
  /// In en, this message translates to:
  /// **'You May Also Like'**
  String get relatedProfessionalsLabel;

  /// No description provided for @removeCta.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeCta;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply'**
  String get replyHint;

  /// No description provided for @replySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your reply is public and visible to everyone'**
  String get replySubtitle;

  /// No description provided for @replyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply to Review'**
  String get replyTitle;

  /// No description provided for @reportNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional details'**
  String get reportNoteHint;

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us understand what went wrong'**
  String get reportSubtitle;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportTitle;

  /// No description provided for @requestSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get requestSentLabel;

  /// No description provided for @requestSentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent to {value1}'**
  String requestSentSubtitle(Object value1);

  /// No description provided for @requestWithdrawCta.
  ///
  /// In en, this message translates to:
  /// **'Request Withdrawal'**
  String get requestWithdrawCta;

  /// No description provided for @rescheduledLabel.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get rescheduledLabel;

  /// No description provided for @resendEmailCta.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmailCta;

  /// No description provided for @resetLinkError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link'**
  String get resetLinkError;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {value1}'**
  String resetLinkSent(Object value1);

  /// No description provided for @resetPassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link'**
  String get resetPassSubtitle;

  /// No description provided for @resetPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassTitle;

  /// No description provided for @resetPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a password reset link to {value1}'**
  String resetPasswordDescription(Object value1);

  /// No description provided for @resetPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordLabel;

  /// No description provided for @responseLabel.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get responseLabel;

  /// No description provided for @responseRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Response Rate'**
  String get responseRateLabel;

  /// No description provided for @responseRateSubtext.
  ///
  /// In en, this message translates to:
  /// **'How often you respond to messages'**
  String get responseRateSubtext;

  /// No description provided for @responseTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get responseTimeLabel;

  /// No description provided for @retryCta.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryCta;

  /// No description provided for @reviewBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Review Booking'**
  String get reviewBookingLabel;

  /// No description provided for @reviewSubmitErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get reviewSubmitErrorDefault;

  /// No description provided for @reviewSubmittedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your review for {value1} has been submitted'**
  String reviewSubmittedSuccessMessage(Object value1);

  /// No description provided for @reviewSubmittedSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted'**
  String get reviewSubmittedSuccessTitle;

  /// No description provided for @reviewUpdateErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Failed to update review'**
  String get reviewUpdateErrorDefault;

  /// No description provided for @reviewUpdatedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your review for {value1} has been updated'**
  String reviewUpdatedSuccessMessage(Object value1);

  /// No description provided for @reviewUpdatedSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Updated'**
  String get reviewUpdatedSuccessTitle;

  /// No description provided for @reviewsActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsActionLabel;

  /// No description provided for @reviewsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews you have written'**
  String get reviewsActionSubtitle;

  /// No description provided for @reviewsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1} reviews'**
  String reviewsCountLabel(Object value1);

  /// No description provided for @reviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsLabel;

  /// No description provided for @saveCertificateCta.
  ///
  /// In en, this message translates to:
  /// **'Save Certificate'**
  String get saveCertificateCta;

  /// No description provided for @saveChangesCta.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesCta;

  /// No description provided for @saveCta.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveCta;

  /// No description provided for @saveScheduleCta.
  ///
  /// In en, this message translates to:
  /// **'Save Schedule'**
  String get saveScheduleCta;

  /// No description provided for @saveSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get saveSettingsError;

  /// No description provided for @saveSettingsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get saveSettingsSuccess;

  /// No description provided for @savedProfessionalsActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved Professionals'**
  String get savedProfessionalsActionLabel;

  /// No description provided for @savedProfessionalsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professionals you have saved'**
  String get savedProfessionalsActionSubtitle;

  /// No description provided for @savedProfessionalsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professionals you save will appear here'**
  String get savedProfessionalsEmptySubtitle;

  /// No description provided for @savedProfessionalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Saved Professionals'**
  String get savedProfessionalsEmptyTitle;

  /// No description provided for @savedProfessionalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Professionals'**
  String get savedProfessionalsTitle;

  /// No description provided for @savedStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedStatLabel;

  /// No description provided for @searchAiPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'AI Search Premium Active'**
  String get searchAiPremiumActive;

  /// No description provided for @searchAiRemainingToday.
  ///
  /// In en, this message translates to:
  /// **'{value1} AI searches remaining today'**
  String searchAiRemainingToday(Object value1);

  /// No description provided for @searchBookingsHint.
  ///
  /// In en, this message translates to:
  /// **'Search bookings'**
  String get searchBookingsHint;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get searchCategories;

  /// No description provided for @searchPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get searchPopular;

  /// No description provided for @searchPopularCleaners.
  ///
  /// In en, this message translates to:
  /// **'Cleaners'**
  String get searchPopularCleaners;

  /// No description provided for @searchPopularDoctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get searchPopularDoctors;

  /// No description provided for @searchPopularElectricians.
  ///
  /// In en, this message translates to:
  /// **'Electricians'**
  String get searchPopularElectricians;

  /// No description provided for @searchPopularEngineers.
  ///
  /// In en, this message translates to:
  /// **'Engineers'**
  String get searchPopularEngineers;

  /// No description provided for @searchPopularLawyers.
  ///
  /// In en, this message translates to:
  /// **'Lawyers'**
  String get searchPopularLawyers;

  /// No description provided for @searchPopularPlumbers.
  ///
  /// In en, this message translates to:
  /// **'Plumbers'**
  String get searchPopularPlumbers;

  /// No description provided for @searchProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Professionals'**
  String get searchProfessionals;

  /// No description provided for @searchProfessions.
  ///
  /// In en, this message translates to:
  /// **'Professions'**
  String get searchProfessions;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get searchRecent;

  /// No description provided for @searchResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1} results for \"{value2}\"'**
  String searchResultsLabel(Object value1, Object value2);

  /// No description provided for @searchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingLabel;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securityActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityActionLabel;

  /// No description provided for @securityActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Password and account security'**
  String get securityActionSubtitle;

  /// No description provided for @securityBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your account safe and secure'**
  String get securityBannerSubtitle;

  /// No description provided for @securityBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get securityBannerTitle;

  /// No description provided for @securityFooterText.
  ///
  /// In en, this message translates to:
  /// **'If you didn\'t request this change, please contact support immediately'**
  String get securityFooterText;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @seeAllLabel.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAllLabel;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @sendResetLinkCta.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkCta;

  /// No description provided for @serviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get serviceLabel;

  /// No description provided for @serviceProfessionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Professional'**
  String get serviceProfessionalLabel;

  /// No description provided for @settingsActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsActionLabel;

  /// No description provided for @settingsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get settingsActionSubtitle;

  /// No description provided for @shareExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Share your experience'**
  String get shareExperienceLabel;

  /// No description provided for @signInInsteadLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in instead'**
  String get signInInsteadLabel;

  /// No description provided for @skillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillsLabel;

  /// No description provided for @skillsPricingLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills & Pricing'**
  String get skillsPricingLabel;

  /// No description provided for @slotDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default length of each booking slot'**
  String get slotDurationSubtitle;

  /// No description provided for @slotDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Slot Duration'**
  String get slotDurationTitle;

  /// No description provided for @startConversationError.
  ///
  /// In en, this message translates to:
  /// **'Failed to start conversation'**
  String get startConversationError;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @startingFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting from'**
  String get startingFromLabel;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @submitReportCta.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReportCta;

  /// No description provided for @submitReviewCta.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReviewCta;

  /// No description provided for @subscriptionActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionActionLabel;

  /// No description provided for @subscriptionActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'{value1} plan active'**
  String subscriptionActiveStatus(Object value1);

  /// No description provided for @subscriptionUpgradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get subscriptionUpgradeLabel;

  /// No description provided for @subscriptionUpgradeStatus.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to premium'**
  String get subscriptionUpgradeStatus;

  /// No description provided for @suggestTimeCta.
  ///
  /// In en, this message translates to:
  /// **'Suggest a Different Time'**
  String get suggestTimeCta;

  /// No description provided for @suggestTimeCtaShort.
  ///
  /// In en, this message translates to:
  /// **'Suggest Time'**
  String get suggestTimeCtaShort;

  /// No description provided for @suggestTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'Propose a new date and time for this booking'**
  String get suggestTimeDescription;

  /// No description provided for @suggestTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggest a Time'**
  String get suggestTimeLabel;

  /// No description provided for @suggestTimeSuccess.
  ///
  /// In en, this message translates to:
  /// **'New time suggested to customer'**
  String get suggestTimeSuccess;

  /// No description provided for @suggestedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested Time'**
  String get suggestedTimeLabel;

  /// No description provided for @supportBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help, 24/7'**
  String get supportBannerSubtitle;

  /// No description provided for @supportBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get supportBannerTitle;

  /// No description provided for @supportTeamReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Support Team'**
  String get supportTeamReplyLabel;

  /// No description provided for @tapStarToRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get tapStarToRateLabel;

  /// No description provided for @thisMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @timeSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Slots'**
  String get timeSlotsLabel;

  /// No description provided for @timeTipText.
  ///
  /// In en, this message translates to:
  /// **'Choose a time that works best for you'**
  String get timeTipText;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get titleHint;

  /// No description provided for @titleLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabelRequired;

  /// No description provided for @titleValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get titleValidationError;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @todaysEarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get todaysEarningsLabel;

  /// No description provided for @todaysScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaysScheduleLabel;

  /// No description provided for @topRatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRatedLabel;

  /// No description provided for @totalBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Bookings'**
  String get totalBookingsLabel;

  /// No description provided for @totalEarnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarnedLabel;

  /// No description provided for @totalSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpentLabel;

  /// No description provided for @transactionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1} transactions'**
  String transactionCountLabel(Object value1);

  /// No description provided for @transactionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistoryTitle;

  /// No description provided for @tryAgainCta.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainCta;

  /// No description provided for @twitterSignInLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue with Twitter'**
  String get twitterSignInLabel;

  /// No description provided for @typicallyRepliesLabel.
  ///
  /// In en, this message translates to:
  /// **'Typically replies'**
  String get typicallyRepliesLabel;

  /// No description provided for @unavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailableLabel;

  /// No description provided for @unknownRoleError.
  ///
  /// In en, this message translates to:
  /// **'Unknown account type'**
  String get unknownRoleError;

  /// No description provided for @updateBookingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update booking'**
  String get updateBookingError;

  /// No description provided for @updateCta.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateCta;

  /// No description provided for @updateReviewCta.
  ///
  /// In en, this message translates to:
  /// **'Update Review'**
  String get updateReviewCta;

  /// No description provided for @upgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeCta;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadError;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Uploaded successfully'**
  String get uploadSuccess;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @vacationCleared.
  ///
  /// In en, this message translates to:
  /// **'Vacation cleared'**
  String get vacationCleared;

  /// No description provided for @vacationDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a vacation date range'**
  String get vacationDateRequired;

  /// No description provided for @vacationSet.
  ///
  /// In en, this message translates to:
  /// **'Vacation set successfully'**
  String get vacationSet;

  /// No description provided for @validAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get validAmountError;

  /// No description provided for @verificationAddPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Add portfolio items to help get verified'**
  String get verificationAddPortfolio;

  /// No description provided for @verificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationLabel;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get verificationPending;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @verifiedProfessionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get verifiedProfessionalLabel;

  /// No description provided for @verifiedStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified {value1}'**
  String verifiedStatusLabel(Object value1);

  /// No description provided for @viewMyBookingsCta.
  ///
  /// In en, this message translates to:
  /// **'View My Bookings'**
  String get viewMyBookingsCta;

  /// No description provided for @viewProfileCta.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfileCta;

  /// No description provided for @viewWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'View Wallet'**
  String get viewWalletLabel;

  /// No description provided for @visitorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get visitorsLabel;

  /// No description provided for @visitorsSubtext.
  ///
  /// In en, this message translates to:
  /// **'People who viewed your profile'**
  String get visitorsSubtext;

  /// No description provided for @walletActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletActionLabel;

  /// No description provided for @walletActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View balance and transactions'**
  String get walletActionSubtitle;

  /// No description provided for @walletEarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get walletEarningsLabel;

  /// No description provided for @walletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletLabel;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @whatHappensNextLabel.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get whatHappensNextLabel;

  /// No description provided for @whyBookHereLabel.
  ///
  /// In en, this message translates to:
  /// **'Why book with us?'**
  String get whyBookHereLabel;

  /// No description provided for @withdrawCta.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawCta;

  /// No description provided for @withdrawErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal failed. Please try again.'**
  String get withdrawErrorDefault;

  /// No description provided for @withdrawSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal requested successfully'**
  String get withdrawSuccess;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawTitle;

  /// No description provided for @withdrawnLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get withdrawnLabel;

  /// No description provided for @workingHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHoursLabel;

  /// No description provided for @writeReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReviewTitle;

  /// No description provided for @yearsLabel.
  ///
  /// In en, this message translates to:
  /// **'{value1} years'**
  String yearsLabel(Object value1);

  /// No description provided for @yesCancelCta.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancelCta;

  /// No description provided for @youAreNotifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified'**
  String get youAreNotifiedLabel;

  /// No description provided for @youAreNotifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you as soon as there\'s a response'**
  String get youAreNotifiedSubtitle;

  /// No description provided for @yourAccountEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'your account email'**
  String get yourAccountEmailPlaceholder;

  /// No description provided for @tsErrForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get tsErrForbidden;

  /// No description provided for @tsErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network problem. Check your connection and try again.'**
  String get tsErrNetwork;

  /// No description provided for @tsErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get tsErrGeneric;

  /// No description provided for @tsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get tsRetry;

  /// No description provided for @tsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get tsCopy;

  /// No description provided for @tsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get tsCopied;

  /// No description provided for @tsOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get tsOpenLink;

  /// No description provided for @tsLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'This link could not be opened.'**
  String get tsLinkOpenFailed;

  /// No description provided for @tsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tsCancel;

  /// No description provided for @tsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tsClose;

  /// No description provided for @tsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get tsRefresh;

  /// No description provided for @tsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tsAll;

  /// No description provided for @tsCatSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get tsCatSpam;

  /// No description provided for @tsCatHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get tsCatHarassment;

  /// No description provided for @tsCatFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get tsCatFraud;

  /// No description provided for @tsCatFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get tsCatFakeProfile;

  /// No description provided for @tsCatInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get tsCatInappropriate;

  /// No description provided for @tsCatPaymentFraud.
  ///
  /// In en, this message translates to:
  /// **'Payment fraud'**
  String get tsCatPaymentFraud;

  /// No description provided for @tsCatOffPlatform.
  ///
  /// In en, this message translates to:
  /// **'Off-platform payment'**
  String get tsCatOffPlatform;

  /// No description provided for @tsCatThreats.
  ///
  /// In en, this message translates to:
  /// **'Threats or safety concern'**
  String get tsCatThreats;

  /// No description provided for @tsCatDiscrimination.
  ///
  /// In en, this message translates to:
  /// **'Discrimination'**
  String get tsCatDiscrimination;

  /// No description provided for @tsCatMisconduct.
  ///
  /// In en, this message translates to:
  /// **'Service misconduct'**
  String get tsCatMisconduct;

  /// No description provided for @tsCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tsCatOther;

  /// No description provided for @tsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tsStatusPending;

  /// No description provided for @tsStatusReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get tsStatusReviewed;

  /// No description provided for @tsStatusActionTaken.
  ///
  /// In en, this message translates to:
  /// **'Action taken'**
  String get tsStatusActionTaken;

  /// No description provided for @tsStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get tsStatusDismissed;

  /// No description provided for @tsSevLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get tsSevLow;

  /// No description provided for @tsSevMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get tsSevMedium;

  /// No description provided for @tsSevHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get tsSevHigh;

  /// No description provided for @tsSevCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get tsSevCritical;

  /// No description provided for @tsRoleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get tsRoleCustomer;

  /// No description provided for @tsRoleProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get tsRoleProfessional;

  /// No description provided for @tsRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get tsRoleAdmin;

  /// No description provided for @tsActWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get tsActWarning;

  /// No description provided for @tsActRestrictMessaging.
  ///
  /// In en, this message translates to:
  /// **'Messaging restriction'**
  String get tsActRestrictMessaging;

  /// No description provided for @tsActRestrictBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking restriction'**
  String get tsActRestrictBooking;

  /// No description provided for @tsActSuspendTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary suspension'**
  String get tsActSuspendTemporary;

  /// No description provided for @tsActSuspendPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent suspension'**
  String get tsActSuspendPermanent;

  /// No description provided for @tsActWarningDesc.
  ///
  /// In en, this message translates to:
  /// **'Records a formal warning. Does not limit the account.'**
  String get tsActWarningDesc;

  /// No description provided for @tsActRestrictMessagingDesc.
  ///
  /// In en, this message translates to:
  /// **'Marks the account as restricted from messaging.'**
  String get tsActRestrictMessagingDesc;

  /// No description provided for @tsActRestrictBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Marks the account as restricted from creating bookings.'**
  String get tsActRestrictBookingDesc;

  /// No description provided for @tsActSuspendTemporaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Marks the account as suspended until the date you choose.'**
  String get tsActSuspendTemporaryDesc;

  /// No description provided for @tsActSuspendPermanentDesc.
  ///
  /// In en, this message translates to:
  /// **'Marks the account as permanently suspended. No expiry; only an admin can reverse it.'**
  String get tsActSuspendPermanentDesc;

  /// No description provided for @tsStateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tsStateActive;

  /// No description provided for @tsStateScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tsStateScheduled;

  /// No description provided for @tsStateExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get tsStateExpired;

  /// No description provided for @tsStateReversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get tsStateReversed;

  /// No description provided for @tsAppealPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tsAppealPending;

  /// No description provided for @tsAppealApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get tsAppealApproved;

  /// No description provided for @tsAppealRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get tsAppealRejected;

  /// No description provided for @tsReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported Users'**
  String get tsReportsTitle;

  /// No description provided for @tsPendingReview.
  ///
  /// In en, this message translates to:
  /// **'{count} pending review'**
  String tsPendingReview(String count);

  /// No description provided for @tsSearchReportsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by user, reporter, category or ID'**
  String get tsSearchReportsHint;

  /// No description provided for @tsFilterSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get tsFilterSeverity;

  /// No description provided for @tsFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tsFilterCategory;

  /// No description provided for @tsFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tsFilterDate;

  /// No description provided for @tsDateAny.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get tsDateAny;

  /// No description provided for @tsDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tsDateToday;

  /// No description provided for @tsDate7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get tsDate7;

  /// No description provided for @tsDate30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get tsDate30;

  /// No description provided for @tsDateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get tsDateCustom;

  /// No description provided for @tsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get tsSortNewest;

  /// No description provided for @tsSortSeverity.
  ///
  /// In en, this message translates to:
  /// **'Highest severity first'**
  String get tsSortSeverity;

  /// No description provided for @tsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get tsClearFilters;

  /// No description provided for @tsNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get tsNoReports;

  /// No description provided for @tsNoReportsHint.
  ///
  /// In en, this message translates to:
  /// **'Reports submitted by users will appear here.'**
  String get tsNoReportsHint;

  /// No description provided for @tsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No reports match your filters'**
  String get tsNoMatches;

  /// No description provided for @tsNoMatchesHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing or clearing the filters.'**
  String get tsNoMatchesHint;

  /// No description provided for @tsSelectReport.
  ///
  /// In en, this message translates to:
  /// **'Select a report'**
  String get tsSelectReport;

  /// No description provided for @tsSelectReportHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a report from the list to review it and take action.'**
  String get tsSelectReportHint;

  /// No description provided for @tsIndBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get tsIndBooking;

  /// No description provided for @tsIndMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get tsIndMessage;

  /// No description provided for @tsIndEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get tsIndEvidence;

  /// No description provided for @tsReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by {name}'**
  String tsReportedBy(String name);

  /// No description provided for @tsAccountBlocked.
  ///
  /// In en, this message translates to:
  /// **'Account blocked'**
  String get tsAccountBlocked;

  /// No description provided for @tsReportNumber.
  ///
  /// In en, this message translates to:
  /// **'Report #{id}'**
  String tsReportNumber(String id);

  /// No description provided for @tsSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String tsSubmittedOn(String date);

  /// No description provided for @tsTakeAction.
  ///
  /// In en, this message translates to:
  /// **'Take action'**
  String get tsTakeAction;

  /// No description provided for @tsMarkReviewed.
  ///
  /// In en, this message translates to:
  /// **'Mark reviewed'**
  String get tsMarkReviewed;

  /// No description provided for @tsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get tsDismiss;

  /// No description provided for @tsSecDescription.
  ///
  /// In en, this message translates to:
  /// **'Report description'**
  String get tsSecDescription;

  /// No description provided for @tsNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description was provided.'**
  String get tsNoDescription;

  /// No description provided for @tsSecEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence and context'**
  String get tsSecEvidence;

  /// No description provided for @tsEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'EVIDENCE / REFERENCE'**
  String get tsEvidenceLabel;

  /// No description provided for @tsNoEvidence.
  ///
  /// In en, this message translates to:
  /// **'No evidence link provided.'**
  String get tsNoEvidence;

  /// No description provided for @tsBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'RELATED BOOKING'**
  String get tsBookingLabel;

  /// No description provided for @tsBookingNumber.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id}'**
  String tsBookingNumber(String id);

  /// No description provided for @tsMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'RELATED MESSAGE'**
  String get tsMessageLabel;

  /// No description provided for @tsMessageNumber.
  ///
  /// In en, this message translates to:
  /// **'Message #{id}'**
  String tsMessageNumber(String id);

  /// No description provided for @tsMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted. Its content is not available.'**
  String get tsMessageDeleted;

  /// No description provided for @tsMessageAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments: {count}'**
  String tsMessageAttachments(String count);

  /// No description provided for @tsNoRelated.
  ///
  /// In en, this message translates to:
  /// **'None linked to this report.'**
  String get tsNoRelated;

  /// No description provided for @tsFieldWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get tsFieldWhen;

  /// No description provided for @tsFieldParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get tsFieldParties;

  /// No description provided for @tsFieldSender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get tsFieldSender;

  /// No description provided for @tsBookingWith.
  ///
  /// In en, this message translates to:
  /// **'{customer} with {professional}'**
  String tsBookingWith(String customer, String professional);

  /// No description provided for @tsSecPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get tsSecPeople;

  /// No description provided for @tsReportedUser.
  ///
  /// In en, this message translates to:
  /// **'REPORTED USER'**
  String get tsReportedUser;

  /// No description provided for @tsReporterLabel.
  ///
  /// In en, this message translates to:
  /// **'REPORTER'**
  String get tsReporterLabel;

  /// No description provided for @tsReporterAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Visible to admins only. Never shown to the reported user.'**
  String get tsReporterAdminOnly;

  /// No description provided for @tsAccountBlockedNote.
  ///
  /// In en, this message translates to:
  /// **'This account is currently blocked (see the Blocked tab). Blocking is separate from moderation actions.'**
  String get tsAccountBlockedNote;

  /// No description provided for @tsSecActive.
  ///
  /// In en, this message translates to:
  /// **'Active restrictions and suspension'**
  String get tsSecActive;

  /// No description provided for @tsNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active restrictions or suspension.'**
  String get tsNoActive;

  /// No description provided for @tsSecTimeline.
  ///
  /// In en, this message translates to:
  /// **'Report history'**
  String get tsSecTimeline;

  /// No description provided for @tsSecHistory.
  ///
  /// In en, this message translates to:
  /// **'Moderation history'**
  String get tsSecHistory;

  /// No description provided for @tsSecOtherReports.
  ///
  /// In en, this message translates to:
  /// **'Other reports about this user'**
  String get tsSecOtherReports;

  /// No description provided for @tsHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load moderation history.'**
  String get tsHistoryLoadError;

  /// No description provided for @tsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No moderation actions on record for this user.'**
  String get tsHistoryEmpty;

  /// No description provided for @tsTlSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get tsTlSubmitted;

  /// No description provided for @tsTlReviewed.
  ///
  /// In en, this message translates to:
  /// **'Marked {status} by {admin}'**
  String tsTlReviewed(String status, String admin);

  /// No description provided for @tsTlInternalNote.
  ///
  /// In en, this message translates to:
  /// **'Internal note: {note}'**
  String tsTlInternalNote(String note);

  /// No description provided for @tsTlActionApplied.
  ///
  /// In en, this message translates to:
  /// **'{action} applied by {admin}'**
  String tsTlActionApplied(String action, String admin);

  /// No description provided for @tsTlActionReversed.
  ///
  /// In en, this message translates to:
  /// **'{action} reversed by {admin}'**
  String tsTlActionReversed(String action, String admin);

  /// No description provided for @tsThisReport.
  ///
  /// In en, this message translates to:
  /// **'This report'**
  String get tsThisReport;

  /// No description provided for @tsHistPerformedBy.
  ///
  /// In en, this message translates to:
  /// **'By {admin} on {date}'**
  String tsHistPerformedBy(String admin, String date);

  /// No description provided for @tsStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String tsStartsOn(String date);

  /// No description provided for @tsExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String tsExpiresOn(String date);

  /// No description provided for @tsNoExpiryPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent, no expiry'**
  String get tsNoExpiryPermanent;

  /// No description provided for @tsNoExpiryOpen.
  ///
  /// In en, this message translates to:
  /// **'No end date, active until lifted'**
  String get tsNoExpiryOpen;

  /// No description provided for @tsReasonShownToUser.
  ///
  /// In en, this message translates to:
  /// **'REASON (SHOWN TO THE USER)'**
  String get tsReasonShownToUser;

  /// No description provided for @tsInternalNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Internal note (admin only)'**
  String get tsInternalNoteLabel;

  /// No description provided for @tsHistReversedBy.
  ///
  /// In en, this message translates to:
  /// **'Reversed by {admin} on {date}'**
  String tsHistReversedBy(String admin, String date);

  /// No description provided for @tsReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get tsReverse;

  /// No description provided for @tsAdminUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown admin'**
  String get tsAdminUnknown;

  /// No description provided for @tsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark report as reviewed'**
  String get tsReviewTitle;

  /// No description provided for @tsReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you have reviewed this report. You can add an internal note.'**
  String get tsReviewMessage;

  /// No description provided for @tsReviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark reviewed'**
  String get tsReviewConfirm;

  /// No description provided for @tsDismissTitle.
  ///
  /// In en, this message translates to:
  /// **'Dismiss report'**
  String get tsDismissTitle;

  /// No description provided for @tsDismissMessage.
  ///
  /// In en, this message translates to:
  /// **'Dismiss this report if it does not break the rules. No action is taken against the reported user.'**
  String get tsDismissMessage;

  /// No description provided for @tsDismissConfirm.
  ///
  /// In en, this message translates to:
  /// **'Dismiss report'**
  String get tsDismissConfirm;

  /// No description provided for @tsResolveReporterNote.
  ///
  /// In en, this message translates to:
  /// **'The reporter receives a generic outcome notification. The reported user is not notified.'**
  String get tsResolveReporterNote;

  /// No description provided for @tsReportUpdated.
  ///
  /// In en, this message translates to:
  /// **'Report updated'**
  String get tsReportUpdated;

  /// No description provided for @tsTakeActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Take moderation action'**
  String get tsTakeActionTitle;

  /// No description provided for @tsRegardingReport.
  ///
  /// In en, this message translates to:
  /// **'Regarding report #{id}'**
  String tsRegardingReport(String id);

  /// No description provided for @tsChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose an action'**
  String get tsChooseAction;

  /// No description provided for @tsChooseActionError.
  ///
  /// In en, this message translates to:
  /// **'Select an action to continue.'**
  String get tsChooseActionError;

  /// No description provided for @tsAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'Already active for this user.'**
  String get tsAlreadyActive;

  /// No description provided for @tsAlreadyPermanentlySuspended.
  ///
  /// In en, this message translates to:
  /// **'This user is already permanently suspended.'**
  String get tsAlreadyPermanentlySuspended;

  /// No description provided for @tsDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tsDurationTitle;

  /// No description provided for @tsDurationUntilLifted.
  ///
  /// In en, this message translates to:
  /// **'Until lifted'**
  String get tsDurationUntilLifted;

  /// No description provided for @tsDurationPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get tsDurationPermanent;

  /// No description provided for @tsDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String tsDurationDays(String n);

  /// No description provided for @tsDurationCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom date'**
  String get tsDurationCustom;

  /// No description provided for @tsEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends {when}'**
  String tsEndsAt(String when);

  /// No description provided for @tsUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String tsUntilDate(String date);

  /// No description provided for @tsExpiryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose when this ends.'**
  String get tsExpiryRequired;

  /// No description provided for @tsExpiryMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'The end time must be in the future.'**
  String get tsExpiryMustBeFuture;

  /// No description provided for @tsReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get tsReasonLabel;

  /// No description provided for @tsReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Explain why this action is being taken'**
  String get tsReasonHint;

  /// No description provided for @tsReasonUserVisibleNote.
  ///
  /// In en, this message translates to:
  /// **'Shown to the user in their notification. Do not mention the reporter or other users.'**
  String get tsReasonUserVisibleNote;

  /// No description provided for @tsReasonTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason of at least {min} characters.'**
  String tsReasonTooShort(String min);

  /// No description provided for @tsInternalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional context for other admins'**
  String get tsInternalNoteHint;

  /// No description provided for @tsInternalNoteNote.
  ///
  /// In en, this message translates to:
  /// **'Internal only. Never shown to the user.'**
  String get tsInternalNoteNote;

  /// No description provided for @tsMarkReportTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark this report as Action taken'**
  String get tsMarkReportTaken;

  /// No description provided for @tsMarkReportTakenHint.
  ///
  /// In en, this message translates to:
  /// **'The reporter receives a generic outcome notification only.'**
  String get tsMarkReportTakenHint;

  /// No description provided for @tsApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply action'**
  String get tsApplyAction;

  /// No description provided for @tsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply {action}?'**
  String tsConfirmTitle(String action);

  /// No description provided for @tsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This is recorded in the moderation history of {user} and the user is notified.'**
  String tsConfirmBody(String user);

  /// No description provided for @tsConfirmPermanentAck.
  ///
  /// In en, this message translates to:
  /// **'I understand this suspension has no expiry and can only be reversed by an admin.'**
  String get tsConfirmPermanentAck;

  /// No description provided for @tsFieldUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get tsFieldUser;

  /// No description provided for @tsFieldAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get tsFieldAction;

  /// No description provided for @tsFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tsFieldDuration;

  /// No description provided for @tsFieldReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get tsFieldReason;

  /// No description provided for @tsActionApplied.
  ///
  /// In en, this message translates to:
  /// **'Moderation action applied'**
  String get tsActionApplied;

  /// No description provided for @tsActionAppliedReportFailed.
  ///
  /// In en, this message translates to:
  /// **'The action was applied, but the report status could not be updated.'**
  String get tsActionAppliedReportFailed;

  /// No description provided for @tsCannotActOnAdmin.
  ///
  /// In en, this message translates to:
  /// **'Moderation actions cannot target admin accounts.'**
  String get tsCannotActOnAdmin;

  /// No description provided for @tsFieldPerformedBy.
  ///
  /// In en, this message translates to:
  /// **'Performed by'**
  String get tsFieldPerformedBy;

  /// No description provided for @tsFieldCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get tsFieldCreated;

  /// No description provided for @tsFieldExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get tsFieldExpires;

  /// No description provided for @tsFieldReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get tsFieldReport;

  /// No description provided for @tsFieldDecidedBy.
  ///
  /// In en, this message translates to:
  /// **'Decided by'**
  String get tsFieldDecidedBy;

  /// No description provided for @tsFieldDecidedOn.
  ///
  /// In en, this message translates to:
  /// **'Decided on'**
  String get tsFieldDecidedOn;

  /// No description provided for @tsReverseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse moderation action'**
  String get tsReverseTitle;

  /// No description provided for @tsReverseMessage.
  ///
  /// In en, this message translates to:
  /// **'Reverse the {action}? It is lifted and the record stays in the history.'**
  String tsReverseMessage(String action);

  /// No description provided for @tsReversalReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for reversal'**
  String get tsReversalReasonLabel;

  /// No description provided for @tsReversalReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why is this action being lifted?'**
  String get tsReversalReasonHint;

  /// No description provided for @tsReverseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reverse action'**
  String get tsReverseConfirm;

  /// No description provided for @tsReverseAuditNote.
  ///
  /// In en, this message translates to:
  /// **'Your reason is internal. It is recorded in the moderation history and never shown to the user.'**
  String get tsReverseAuditNote;

  /// No description provided for @tsReverseNotifyNote.
  ///
  /// In en, this message translates to:
  /// **'The user is notified that this action was lifted.'**
  String get tsReverseNotifyNote;

  /// No description provided for @tsReverseLegacyNote.
  ///
  /// In en, this message translates to:
  /// **'This action came from the legacy ban flow. Reversing it also re-enables the account.'**
  String get tsReverseLegacyNote;

  /// No description provided for @tsActionReversed.
  ///
  /// In en, this message translates to:
  /// **'Moderation action reversed'**
  String get tsActionReversed;

  /// No description provided for @tsAppealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appeals'**
  String get tsAppealsTitle;

  /// No description provided for @tsPendingAppeals.
  ///
  /// In en, this message translates to:
  /// **'{count} pending appeals'**
  String tsPendingAppeals(String count);

  /// No description provided for @tsSearchAppealsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by user, email or appeal text'**
  String get tsSearchAppealsHint;

  /// No description provided for @tsNoAppeals.
  ///
  /// In en, this message translates to:
  /// **'No appeals here'**
  String get tsNoAppeals;

  /// No description provided for @tsNoAppealsHint.
  ///
  /// In en, this message translates to:
  /// **'Appeals against moderation actions will appear here.'**
  String get tsNoAppealsHint;

  /// No description provided for @tsSelectAppeal.
  ///
  /// In en, this message translates to:
  /// **'Select an appeal'**
  String get tsSelectAppeal;

  /// No description provided for @tsSelectAppealHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an appeal from the list to review it.'**
  String get tsSelectAppealHint;

  /// No description provided for @tsAppealNumber.
  ///
  /// In en, this message translates to:
  /// **'Appeal #{id}'**
  String tsAppealNumber(String id);

  /// No description provided for @tsSecAppealReason.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get tsSecAppealReason;

  /// No description provided for @tsSecAppealedAction.
  ///
  /// In en, this message translates to:
  /// **'Appealed action'**
  String get tsSecAppealedAction;

  /// No description provided for @tsSecDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get tsSecDecision;

  /// No description provided for @tsAppealApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get tsAppealApprove;

  /// No description provided for @tsAppealReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get tsAppealReject;

  /// No description provided for @tsApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve appeal'**
  String get tsApproveTitle;

  /// No description provided for @tsApproveMessage.
  ///
  /// In en, this message translates to:
  /// **'Approving this appeal lifts the moderation action.'**
  String get tsApproveMessage;

  /// No description provided for @tsApproveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve appeal'**
  String get tsApproveConfirm;

  /// No description provided for @tsRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject appeal'**
  String get tsRejectTitle;

  /// No description provided for @tsRejectMessage.
  ///
  /// In en, this message translates to:
  /// **'Rejecting keeps the moderation action in place.'**
  String get tsRejectMessage;

  /// No description provided for @tsRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject appeal'**
  String get tsRejectConfirm;

  /// No description provided for @tsDecisionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision note'**
  String get tsDecisionNoteLabel;

  /// No description provided for @tsDecisionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Explain your decision'**
  String get tsDecisionNoteHint;

  /// No description provided for @tsDecisionNoteNote.
  ///
  /// In en, this message translates to:
  /// **'Internal only. Never shown to the user.'**
  String get tsDecisionNoteNote;

  /// No description provided for @tsAppealApproveNote.
  ///
  /// In en, this message translates to:
  /// **'The action is reversed and the user is notified.'**
  String get tsAppealApproveNote;

  /// No description provided for @tsAppealApproveInactive.
  ///
  /// In en, this message translates to:
  /// **'This action is no longer in effect, so approving only closes the appeal. The user is notified.'**
  String get tsAppealApproveInactive;

  /// No description provided for @tsAppealRejectNote.
  ///
  /// In en, this message translates to:
  /// **'The action stays in place and the user is notified of the outcome.'**
  String get tsAppealRejectNote;

  /// No description provided for @tsAppealApprovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Appeal approved'**
  String get tsAppealApprovedSnack;

  /// No description provided for @tsAppealRejectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Appeal rejected'**
  String get tsAppealRejectedSnack;

  /// No description provided for @tsNoDecisionNote.
  ///
  /// In en, this message translates to:
  /// **'No note was recorded.'**
  String get tsNoDecisionNote;

  /// No description provided for @tsEvidenceLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Evidence link (optional)'**
  String get tsEvidenceLinkOptional;

  /// No description provided for @tsInvalidHttpUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http or https URL.'**
  String get tsInvalidHttpUrl;

  /// No description provided for @myTsMyReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myTsMyReportsTitle;

  /// No description provided for @myTsMyReportsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reports you\'ve submitted'**
  String get myTsMyReportsActionSubtitle;

  /// No description provided for @myTsReportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get myTsReportsEmptyTitle;

  /// No description provided for @myTsReportsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Reports you submit about other users will appear here.'**
  String get myTsReportsEmptyMessage;

  /// No description provided for @myTsReportsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your reports. Pull down to try again.'**
  String get myTsReportsLoadError;

  /// No description provided for @myTsCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get myTsCategoryLabel;

  /// No description provided for @myTsSubmittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get myTsSubmittedLabel;

  /// No description provided for @myTsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get myTsStatusLabel;

  /// No description provided for @myTsOutcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get myTsOutcomeLabel;

  /// No description provided for @myTsYourDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your description'**
  String get myTsYourDescriptionLabel;

  /// No description provided for @myTsOutcomePending.
  ///
  /// In en, this message translates to:
  /// **'Our team hasn\'t reviewed this yet.'**
  String get myTsOutcomePending;

  /// No description provided for @myTsOutcomeReviewedNoAction.
  ///
  /// In en, this message translates to:
  /// **'Reviewed — no further action was needed.'**
  String get myTsOutcomeReviewedNoAction;

  /// No description provided for @myTsOutcomeActionTaken.
  ///
  /// In en, this message translates to:
  /// **'Reviewed — action was taken based on your report.'**
  String get myTsOutcomeActionTaken;

  /// No description provided for @myTsOutcomeDismissed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed — no violation was found.'**
  String get myTsOutcomeDismissed;

  /// No description provided for @myTsAccountStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get myTsAccountStatusTitle;

  /// No description provided for @myTsAccountStatusActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warnings, restrictions & suspensions'**
  String get myTsAccountStatusActionSubtitle;

  /// No description provided for @myTsGoodStandingTitle.
  ///
  /// In en, this message translates to:
  /// **'No active restrictions'**
  String get myTsGoodStandingTitle;

  /// No description provided for @myTsGoodStandingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is in good standing.'**
  String get myTsGoodStandingMessage;

  /// No description provided for @myTsStatusLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your account status. Pull down to try again.'**
  String get myTsStatusLoadError;

  /// No description provided for @myTsStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get myTsStartTimeLabel;

  /// No description provided for @myTsExpirationTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiration time'**
  String get myTsExpirationTimeLabel;

  /// No description provided for @myTsAffectedFeatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Affected feature'**
  String get myTsAffectedFeatureLabel;

  /// No description provided for @myTsFeatureMessaging.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get myTsFeatureMessaging;

  /// No description provided for @myTsFeatureBooking.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get myTsFeatureBooking;

  /// No description provided for @myTsWarningInfoNote.
  ///
  /// In en, this message translates to:
  /// **'This is a warning only. It doesn\'t restrict your account, but repeated violations may lead to further action.'**
  String get myTsWarningInfoNote;

  /// No description provided for @myTsAppealAvailableNote.
  ///
  /// In en, this message translates to:
  /// **'You can appeal this decision.'**
  String get myTsAppealAvailableNote;

  /// No description provided for @myTsAppealButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Appeal this decision'**
  String get myTsAppealButtonLabel;

  /// No description provided for @myTsAppealPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Your appeal is pending review.'**
  String get myTsAppealPendingNote;

  /// No description provided for @myTsMyAppealsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Appeals'**
  String get myTsMyAppealsTitle;

  /// No description provided for @myTsMyAppealsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t submitted any appeals.'**
  String get myTsMyAppealsEmpty;

  /// No description provided for @myTsAppealsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your appeals. Pull down to try again.'**
  String get myTsAppealsLoadError;

  /// No description provided for @myTsAppealDecidedNote.
  ///
  /// In en, this message translates to:
  /// **'This appeal has been decided.'**
  String get myTsAppealDecidedNote;

  /// No description provided for @myTsSubmitAppealTitle.
  ///
  /// In en, this message translates to:
  /// **'Appeal this decision'**
  String get myTsSubmitAppealTitle;

  /// No description provided for @myTsAppealReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Why should this be reviewed?'**
  String get myTsAppealReasonLabel;

  /// No description provided for @myTsAppealReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Explain why you believe this decision should be reconsidered'**
  String get myTsAppealReasonHint;

  /// No description provided for @myTsAppealReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please explain why this should be reviewed.'**
  String get myTsAppealReasonRequired;

  /// No description provided for @myTsAppealSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Submit appeal'**
  String get myTsAppealSubmitCta;

  /// No description provided for @myTsAppealSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your appeal has been submitted.'**
  String get myTsAppealSubmitSuccess;

  /// No description provided for @myTsAppealSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit your appeal. Try again.'**
  String get myTsAppealSubmitError;

  /// No description provided for @myTsAppealAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending appeal for this.'**
  String get myTsAppealAlreadyPending;

  /// No description provided for @myTsAppealNotEligible.
  ///
  /// In en, this message translates to:
  /// **'This action can no longer be appealed.'**
  String get myTsAppealNotEligible;

  /// No description provided for @myTsAppealForLabel.
  ///
  /// In en, this message translates to:
  /// **'Appeal for {action}'**
  String myTsAppealForLabel(String action);
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
