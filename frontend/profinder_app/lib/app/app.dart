// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/localization/locale_provider.dart';
import '../core/localization/supported_languages.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/chat/presentation/providers/conversation_list_provider.dart';
import '../features/onboarding/screens/language_selection_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_provider.dart';
import '../services/home_provider.dart';
import '../services/push_notification_service.dart';
import 'routes/app_routes.dart';

/// Root application widget for ProFinder.
///
/// Sets up global state providers, localization, theming, navigation key,
/// and application routing.
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
        ChangeNotifierProvider(create: (_) => ConversationListProvider()),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, locale, themeProvider, _) {
          return MaterialApp(
            navigatorKey: PushNotificationService.navigatorKey,
            title: 'ProFinder',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Localization wiring
            locale: locale.locale,
            supportedLocales: SupportedLanguages.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            builder: (context, child) {
              AppStrings.setContext(context);
              PushNotificationService().updateChannelLocalization(
                AppLocalizations.of(context),
              );
              return child!;
            },

            // First-ever launch shows language selection; afterwards SplashScreen takes over.
            home: locale.hasChosenLanguage
                ? const SplashScreen()
                : LanguageSelectionScreen(
                    onContinue: () {
                      // setLocale(markAsChosen: true) already updated hasChosenLanguage;
                      // Consumer automatically rebuilds and swaps home to SplashScreen.
                    },
                  ),
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
