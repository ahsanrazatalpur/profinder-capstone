// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/auth_provider.dart';
import 'services/home_provider.dart';
import 'services/push_notification_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/home/screens/customer_home_screen.dart';
import 'features/home/screens/guest_main_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/bookings/screens/my_bookings_screen.dart';
import 'features/profile/screens/customer_profile_screen.dart';
import 'features/professional/screens/professional_main_screen.dart';
import 'features/professional/screens/professional_portfolio_screen.dart';
import 'features/admin/screens/admin_main_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/magazine/screens/magazine_screen.dart'; // ✅ NEW
import 'features/chat/presentation/providers/conversation_list_provider.dart'; // ✅ NEW — chat feature
import 'features/onboarding/screens/language_selection_screen.dart'; // ✅ i18n
import 'core/localization/locale_provider.dart'; // ✅ i18n
import 'core/localization/supported_languages.dart'; // ✅ i18n
import 'l10n/generated/app_localizations.dart'; // ✅ i18n — generated from lib/l10n/*.arb, see l10n.yaml
import 'core/constants/app_strings.dart'; // ✅ i18n fix — keeps AppStrings in sync with the active locale
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService().init();

  // ✅ i18n — must be ready (persisted locale loaded / device locale
  // detected) before the first frame, so MaterialApp never flashes the
  // wrong language.
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  runApp(ProFinderApp(localeProvider: localeProvider));
}

class ProFinderApp extends StatelessWidget {
  final LocaleProvider localeProvider;

  const ProFinderApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConversationListProvider()), // ✅ NEW — chat feature
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider), // ✅ i18n
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, locale, themeProvider, _) {
          return MaterialApp(
            title:                      'ProFinder',
            debugShowCheckedModeBanner: false,
            theme:                      AppTheme.lightTheme,
            darkTheme:                  AppTheme.darkTheme,
            themeMode:                  themeProvider.themeMode,

            // ✅ i18n — official Flutter localization wiring.
            locale:                     locale.locale,
            supportedLocales:           SupportedLanguages.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Arabic (and any future RTL language) gets right-to-left
            // layout automatically — Flutter derives text direction from
            // the active locale, no manual Directionality needed.

            // ✅ i18n fix — `builder`'s context sits below the Localizations
            // widget MaterialApp just configured above, so this is the
            // earliest point AppLocalizations.of(context) is guaranteed to
            // resolve. Runs again on every locale change (this whole
            // MaterialApp rebuilds via the Consumer<LocaleProvider> above),
            // keeping AppStrings.xxx in sync with whatever language is
            // currently selected — no other file needed to change.
            builder: (context, child) {
              AppStrings.setContext(context);
              return child!;
            },

            // ✅ i18n — first-ever launch shows the language selection
            // screen before anything else; afterwards it's skipped and
            // SplashScreen (existing auth flow) takes over untouched.
            home: locale.hasChosenLanguage
                ? const SplashScreen()
                : LanguageSelectionScreen(
                    onContinue: () {
                      // setLocale(markAsChosen: true) already flipped
                      // hasChosenLanguage — this Consumer rebuilds and
                      // swaps `home` to SplashScreen on its own.
                    },
                  ),
            routes: {
          '/login':           (_) => const LoginScreen(),
          '/register':        (_) => const RegisterScreen(),
          '/forgot-password': (_) => ForgotPasswordScreen(),
          '/home':            (_) => const HomeGate(),
          '/search':          (_) => const SearchScreen(),
          '/bookings':        (_) => const MyBookingsScreen(),
          '/profile':         (_) => const CustomerProfileScreen(),
          '/notifications':   (_) => const NotificationScreen(),
          '/magazine':        (_) => const MagazineScreen(), // ✅ NEW

          // ── Admin ──────────────────────────────────────
          '/admin':           (_) => const AdminMainScreen(),

          // ── Professional ───────────────────────────────
          '/pro':             (_) => ProfessionalMainScreen(),
          '/pro/bookings':    (_) => ProfessionalMainScreen(),
          '/pro/profile':     (_) => ProfessionalMainScreen(),
          '/pro/portfolio':   (_) => ProfessionalPortfolioScreen(),
        },
          );
        },
      ),
    );
  }
}

/// `/home` is shared by both guest & logged-in customers (see login/splash
/// flow). This gate reads AuthProvider once and shows the right screen —
/// no route-map changes needed anywhere else.
class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isGuest ? const GuestMainScreen() : const CustomerHomeScreen();
  }
}