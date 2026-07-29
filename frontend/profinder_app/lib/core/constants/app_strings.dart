// lib/core/constants/app_strings.dart
//
// ✅ i18n fix — this class used to hold hardcoded English text. That's why
// switching to Urdu flipped the layout to RTL (Flutter derives text
// direction from the active locale automatically) but left every string
// on screens that used AppStrings.xxx untranslated — they were never
// reading from AppLocalizations/the .arb files in the first place.
//
// Fix: keep the exact same `AppStrings.xxx` API (so login_screen.dart,
// register_screen.dart, forgot_password_screen.dart,
// professional_detail_screen.dart and app_logo.dart don't need to change
// even one line — no UI/logic touched) but back every field with a
// getter that reads the CURRENT AppLocalizations for the CURRENT locale.
// English is only used as a safety-net fallback (e.g. the very first
// frame, before the root context is available).
//
// The other ~99% of the app already calls AppLocalizations.of(context)
// directly per-screen (that's the correct/normal Flutter pattern) and
// was already translating fine — this file only patches the few legacy
// screens still using the old AppStrings shortcut.

import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';

class AppStrings {
  AppStrings._();

  /// Set once from MaterialApp's `builder` in main.dart. That context sits
  /// *below* the Localizations widget, so AppLocalizations.of(_context!)
  /// resolves to whatever language is currently selected, and updates
  /// automatically every time the locale changes (LocaleProvider rebuilds
  /// MaterialApp, which calls builder again).
  static BuildContext? _context;
  static void setContext(BuildContext context) => _context = context;

  static AppLocalizations? get _t =>
      _context == null ? null : AppLocalizations.of(_context!);

  // ─── App ────────────────────────────────────────────────
  static String get appName        => _t?.appName ?? 'ProFinder';
  static String get appTagline     => _t?.appTagline ?? 'Find Trusted Professionals Near You';

  // ─── Auth ───────────────────────────────────────────────
  static String get login          => _t?.login ?? 'Login';
  static String get register       => _t?.register ?? 'Register';
  static String get logout         => _t?.logout ?? 'Logout';
  static String get email          => _t?.email ?? 'Email';
  static String get password       => _t?.password ?? 'Password';
  static String get confirmPass    => _t?.confirmPassword ?? 'Confirm Password';
  static String get fullName       => _t?.fullName ?? 'Full Name';
  static String get forgotPass     => _t?.forgotPassword ?? 'Forgot Password?';
  static String get resetPass      => _t?.resetPassword ?? 'Reset Password';
  static String get sendResetLink  => _t?.sendResetLink ?? 'Send Reset Link';
  static String get noAccount      => _t?.noAccount ?? "Don't have an account? ";
  static String get hasAccount     => _t?.hasAccount ?? 'Already have an account? ';
  static String get selectRole     => _t?.selectRole ?? 'Register as';
  static String get customer       => _t?.customer ?? 'Customer';
  static String get professional   => _t?.professional ?? 'Professional';
  static String get continueAsGuest => _t?.continueAsGuest ?? 'Continue as Guest';

  // ─── Home ───────────────────────────────────────────────
  static String get home           => _t?.home ?? 'Home';
  static String get findPro        => _t?.findProfessional ?? 'Find a Professional';
  static String get nearby         => _t?.nearbyProfessionals ?? 'Nearby Professionals';
  static String get categories     => _t?.categories ?? 'Categories';
  static String get aiSearch       => _t?.aiSearch ?? 'AI Search';
  static String get searchHint     => _t?.searchHint ?? 'Search for a service...';

  // ─── Profile ────────────────────────────────────────────
  static String get profile        => _t?.profile ?? 'Profile';
  static String get editProfile    => _t?.editProfile ?? 'Edit Profile';
  static String get phone          => _t?.phone ?? 'Phone Number';
  static String get city           => _t?.city ?? 'City';
  static String get bio            => _t?.bio ?? 'Bio';
  static String get experience     => _t?.experience ?? 'Years of Experience';
  static String get hourlyRate     => _t?.hourlyRate ?? 'Hourly Rate (USD)';
  static String get verified       => _t?.verified ?? 'Verified';
  static String get notVerified    => _t?.notVerified ?? 'Not Verified';

  // ─── Bookings ───────────────────────────────────────────
  static String get bookings       => _t?.bookings ?? 'Bookings';
  static String get myBookings     => _t?.myBookings ?? 'My Bookings';
  static String get bookNow        => _t?.bookNow ?? 'Book Now';
  static String get cancel         => _t?.cancel ?? 'Cancel';
  static String get accept         => _t?.accept ?? 'Accept';
  static String get reject         => _t?.reject ?? 'Reject';
  static String get complete       => _t?.complete ?? 'Complete';
  static String get pending        => _t?.pending ?? 'Pending';
  static String get accepted       => _t?.accepted ?? 'Accepted';
  static String get rejected       => _t?.rejected ?? 'Rejected';
  static String get completed      => _t?.completed ?? 'Completed';

  // ─── Notifications ──────────────────────────────────────
  static String get notifications  => _t?.notifications ?? 'Notifications';
  static String get markAsRead     => _t?.markAsRead ?? 'Mark as Read';
  static String get noNotifications => _t?.noNotifications ?? 'No notifications yet';

  // ─── Reviews ────────────────────────────────────────────
  static String get reviews        => _t?.reviews ?? 'Reviews';
  static String get writeReview    => _t?.writeReview ?? 'Write a Review';
  static String get rating         => _t?.rating ?? 'Rating';
  static String get comment        => _t?.comment ?? 'Comment';
  static String get submitReview   => _t?.submitReview ?? 'Submit Review';

  // ─── Errors ─────────────────────────────────────────────
  static String get noInternet     => _t?.noInternet ?? 'No internet connection';
  static String get serverError    => _t?.serverError ?? 'Something went wrong. Try again.';
  static String get invalidEmail   => _t?.invalidEmail ?? 'Please enter a valid email';
  static String get invalidPass    => _t?.invalidPassword ?? 'Password must be at least 8 characters';
  static String get fieldRequired  => _t?.fieldRequired ?? 'This field is required';
  static String get passMismatch   => _t?.passwordMismatch ?? 'Passwords do not match';
  // Generic login failure — intentionally the same for "no such account"
  // and "wrong password" so the UI never reveals which one it was.
  static String get invalidLoginCredentials =>
      _t?.invalidLoginCredentials ?? 'Incorrect email or password. Please try again.';
  // Generic forgot-password confirmation — shown locally regardless of the
  // backend's exact wording, so the UI never reveals whether the email is
  // actually registered even if the backend message ever changes.
  static String get forgotPasswordGenericMessage =>
      _t?.forgotPasswordGenericMessage ??
      "If an account exists with this email, we've sent a password reset link.";
  static String get requestTimedOut =>
      _t?.requestTimedOut ?? 'Request timed out. Please check your connection and try again.';
  static String get backToLogin    => _t?.backToLogin ?? 'Back to Login';
  static String get resendEmail    => _t?.resendEmail ?? 'Resend Email';

  // ─── General ────────────────────────────────────────────
  static String get save           => _t?.save ?? 'Save';
  static String get confirm        => _t?.confirm ?? 'Confirm';
  static String get delete         => _t?.delete ?? 'Delete';
  static String get loading        => _t?.loading ?? 'Loading...';
  static String get retry          => _t?.retry ?? 'Retry';
  static String get noData         => _t?.noData ?? 'Nothing to show here';
  static String get seeAll         => _t?.seeAll ?? 'See All';
}