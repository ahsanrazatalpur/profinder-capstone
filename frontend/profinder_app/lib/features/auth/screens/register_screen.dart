// lib/features/auth/screens/register_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ✅ Google Sign-In
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/google_logo.dart'; // ✅ real Google "G" (flutter_svg)
import '../../../services/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/home_service.dart';
import '../../../services/geo_service.dart';
import '../../../core/constants/country_flags.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/searchable_picker_field.dart';
import '../widgets/account_type_card.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/registration_success_dialog.dart';
import 'login_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

// Email-availability state for the Step 1 live check. `idle` covers both
// "haven't typed enough yet" and "format invalid" — no need to distinguish
// those in the UI, both just show nothing.
enum _EmailStatus { idle, checking, available, taken }

class RegisterScreen extends StatefulWidget {
  // Optional — lets callers (e.g. "Become a Professional" banners/menu items)
  // land the user directly on the professional signup path.
  final String? initialRole;

  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey               = GlobalKey<FormState>();
  final _nameController        = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _nameFocusNode     = FocusNode();
  final _emailFocusNode    = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode  = FocusNode();

  late String _selectedRole = widget.initialRole ?? 'customer';
  Map<String, dynamic>? _selectedCategory;
  bool    _obscurePassword  = true;
  bool    _obscureConfirm   = true;
  bool    _capsLockOn       = false;
  List<dynamic> _categories = [];

  // ── Step 2: Location ──────────────────────────────────────
  final _geoService = GeoService();
  List<dynamic> _countries       = [];
  List<dynamic> _cities          = [];
  Map<String, dynamic>? _selectedCountry;
  Map<String, dynamic>? _selectedCity;
  bool _loadingCountries = true;
  bool _loadingCities    = false;

  final _authService = AuthService();
  _EmailStatus _emailStatus = _EmailStatus.idle;
  Timer? _emailDebounce;

  // ── Shake-on-invalid-submit ──────────────────────────────
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _shakeAnimation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCountries();

    // Rebuild (to re-evaluate button-enabled state + live widgets) whenever
    // any Step 1 field changes.
    for (final c in [
      _nameController,
      _emailController,
      _passwordController,
      _confirmPassController,
    ]) {
      c.addListener(_refresh);
    }

    _emailController.addListener(_onEmailChanged);
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_refresh);

    // Caps Lock detection (Desktop/Web) — global key handler while this
    // screen is mounted; harmless no-op on mobile soft keyboards.
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void _refresh() => setState(() {});

  bool _handleKeyEvent(KeyEvent event) {
    final caps = HardwareKeyboard.instance.lockModesEnabled
        .contains(KeyboardLockMode.capsLock);
    if (caps != _capsLockOn && mounted) {
      setState(() => _capsLockOn = caps);
    }
    return false; // never consume — just observing
  }

  bool get _showCapsLockHint =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  // ── Email availability ───────────────────────────────────
  void _onEmailChanged() {
    _emailDebounce?.cancel();
    final value = _emailController.text.trim();
    if (AppValidators.email(value) != null) {
      if (_emailStatus != _EmailStatus.idle) {
        setState(() => _emailStatus = _EmailStatus.idle);
      }
      return;
    }
    setState(() => _emailStatus = _EmailStatus.checking);
    _emailDebounce = Timer(const Duration(milliseconds: 600), () {
      _checkEmailNow(value);
    });
  }

  void _onEmailFocusChange() {
    // "When the email loses focus, check if it already exists" — fire
    // immediately instead of waiting out the debounce.
    if (!_emailFocusNode.hasFocus) {
      final value = _emailController.text.trim();
      if (AppValidators.email(value) == null) {
        _emailDebounce?.cancel();
        _checkEmailNow(value);
      }
    }
  }

  Future<void> _checkEmailNow(String email) async {
    final result = await _authService.checkEmailAvailability(email);
    if (!mounted) return;
    // Ignore stale responses if the user kept typing in the meantime.
    if (_emailController.text.trim() != email) return;
    if (result['success'] != true) {
      setState(() => _emailStatus = _EmailStatus.idle);
      return;
    }
    setState(() {
      _emailStatus =
          result['available'] == true ? _EmailStatus.available : _EmailStatus.taken;
    });
  }

  // ── Overall Step 1 (+ existing city/role/category) validity ─────────────
  // Drives the Create Account button's enabled state — separate from the
  // Form's validate() (which shows error text); this stays silent and just
  // gates the button.
  bool get _isFormValid {
    final nameOk    = AppValidators.name(_nameController.text) == null;
    final emailOk   = AppValidators.email(_emailController.text) == null &&
        _emailStatus == _EmailStatus.available;
    final passOk    = AppValidators.password(_passwordController.text) == null;
    final confirmOk = _confirmPassController.text.isNotEmpty &&
        _confirmPassController.text == _passwordController.text;
    final cityOk    = _selectedCountry != null && _selectedCity != null;
    final categoryOk =
        _selectedRole != 'professional' || _selectedCategory != null;

    // TEMP DEBUG — remove once the disabled-button issue is found.
    // ignore: avoid_print
    print('[FORM DEBUG] name=$nameOk email=$emailOk(status=$_emailStatus) '
        'pass=$passOk confirm=$confirmOk city=$cityOk category=$categoryOk');

    return nameOk && emailOk && passOk && confirmOk && cityOk && categoryOk;
  }

  // Load categories from backend for professional selection
  Future<void> _loadCategories() async {
    final result = await HomeService().getCategories();
    if (result['success'] && mounted) {
      setState(() => _categories = result['data'] ?? []);
    }
  }

  Future<void> _loadCountries() async {
    final result = await _geoService.getCountries();
    if (!mounted) return;
    setState(() {
      _countries        = result['data'] ?? [];
      _loadingCountries = false;
    });
  }

  Future<void> _onCountrySelected(Map<String, dynamic> country) async {
    setState(() {
      _selectedCountry = country;
      _selectedCity    = null; // reset — city list belongs to the new country
      _cities          = [];
      _loadingCities   = true;
    });
    final result = await _geoService.getCities(country['id'] as int);
    if (!mounted) return;
    setState(() {
      _cities        = result['data'] ?? [];
      _loadingCities = false;
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _emailDebounce?.cancel();
    _passwordFocusNode.removeListener(_refresh);
    _shakeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

    // Professional must select category
    if (_selectedRole == 'professional' && _selectedCategory == null) {
      _shakeController.forward(from: 0);
      AppHelpers.showError(context, AppLocalizations.of(context)!.registerCategoryRequired);
      return;
    }

    // Belt-and-braces: don't let a submit through if the email turned out
    // to already be registered (e.g. user ignored the inline warning).
    if (_emailStatus == _EmailStatus.taken) {
      _shakeController.forward(from: 0);
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      email:      _emailController.text.trim().toLowerCase(),
      name:       AppValidators.normalizeName(_nameController.text),
      role:       _selectedRole,
      password:   _passwordController.text,
      city:       _selectedCity?['name'] as String?,
      country:    _selectedCountry?['name'] as String?,
      categoryId: _selectedCategory?['id'] as int?,
    );

    if (!mounted) return;

    if (success) {
      TextInput.finishAutofillContext();
      _showSuccessDialog();
    } else {
      AppHelpers.showError(
        context,
        auth.errorMessage ?? AppLocalizations.of(context)!.registerServerError,
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => RegistrationSuccessDialog(
        onContinue: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
      ),
    );
  }

  // Shared post-login navigation — used by Google sign-in
  // (email/password login has its own copy in login_screen.dart).
  Future<void> _navigateAfterSocialLogin(AuthProvider auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('just_logged_in_banner_flag', true);
    if (!mounted) return;
    switch (auth.role) {
      case 'customer':
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 'professional':
        Navigator.pushNamedAndRemoveUntil(context, '/pro', (route) => false);
        break;
      case 'admin':
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
        break;
      default:
        AppHelpers.showError(context, AppLocalizations.of(context)!.unknownRoleError);
    }
  }

  // ✅ NEW — Google Sign-In. `_selectedRole` (Customer/Professional toggle
  // at the top of this screen) is sent along so a brand-new Google account
  // gets created with the role the person picked; an existing account
  // just logs in with whatever role it already has.
  Future<void> _handleGoogleSignIn() async {
    // Web needs `clientId` (same Web Client ID as the <meta> tag in
    // web/index.html and the backend's GOOGLE_CLIENT_ID); native
    // Android/iOS instead use `serverClientId` so the idToken's audience
    // matches what the backend verifies against.
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb
          ? '405649887034-vtb975grk99t5qrn4747bk36gifq3g6a.apps.googleusercontent.com'
          : null,
      // 🐛 FIX: native Android/iOS was never passing serverClientId, so the
      // idToken's audience was the platform's own OAuth client instead of
      // the Web client — which never matches backend's GOOGLE_CLIENT_ID.
      serverClientId: kIsWeb
          ? null
          : '405649887034-vtb975grk99t5qrn4747bk36gifq3g6a.apps.googleusercontent.com',
    );
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // person cancelled the account picker

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      // 🐛 FIX: on web, google_sign_in never returns an idToken — only an
      // accessToken. Only treat this as a failure when BOTH are missing.
      final accessToken = googleAuth.accessToken;
      if (idToken == null && accessToken == null) {
        if (!mounted) return;
        AppHelpers.showError(
          context,
          AppLocalizations.of(context)!.registerServerError,
        );
        return;
      }

      final auth = context.read<AuthProvider>();
      final success = await auth.loginWithGoogle(
        idToken: idToken,
        accessToken: idToken == null ? accessToken : null,
        role: _selectedRole,
      );
      if (!mounted) return;

      if (success) {
        await _navigateAfterSocialLogin(auth);
      } else {
        AppHelpers.showError(
          context,
          auth.errorMessage ?? AppLocalizations.of(context)!.registerServerError,
        );
      }
    } catch (e) {
      if (!mounted) return;
      // TEMP DEBUG — remove once Google Sign-In is confirmed working.
      // ignore: avoid_print
      print('[GOOGLE SIGN-IN DEBUG] $e');
      AppHelpers.showError(context, AppLocalizations.of(context)!.registerServerError);
    }
  }

  // ── Email field trailing status icon ─────────────────────
  Widget? _emailSuffixIcon() {
    switch (_emailStatus) {
      case _EmailStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _EmailStatus.available:
        return const Icon(Icons.check_circle, color: AppColors.success);
      case _EmailStatus.taken:
        return const Icon(Icons.cancel, color: AppColors.error);
      case _EmailStatus.idle:
        return null;
    }
  }

  // ── Email field inline hint (available / taken + Sign In Instead) ───────
  Widget _buildEmailHint() {
    if (_emailStatus == _EmailStatus.available) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.emailAvailableLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }
    if (_emailStatus == _EmailStatus.taken) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(
          children: [
            const Icon(Icons.cancel, size: 14, color: AppColors.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.emailTakenLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    initialEmail: _emailController.text.trim(),
                  ),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.signInInsteadLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
            vertical:   AppSizes.sm,
          ),
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.sm),

                    // ── Logo ──────────────────────────────────
                    const AppLogo(size: 90, showName: true),

                    const SizedBox(height: AppSizes.md),

                    // ── Heading ───────────────────────────────
                    Text(
                      AppLocalizations.of(context)!.registerTitle,
                      style: context.textStyles.h2,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      AppLocalizations.of(context)!.registerSubtitle,
                      style: context.textStyles.bodyMedium,
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Account Type ───────────────────────────
                    Text(
                      AppLocalizations.of(context)!.accountTypeLabel,
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AccountTypeCard(
                            title:       AppStrings.customer,
                            description: AppLocalizations.of(context)!.customerAccountDescription,
                            icon:        Icons.person_outline,
                            accentColor: AppColors.customerColor,
                            isSelected:  _selectedRole == 'customer',
                            onTap: () => setState(() {
                              _selectedRole     = 'customer';
                              _selectedCategory = null;
                            }),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          AccountTypeCard(
                            title:       AppStrings.professional,
                            description: AppLocalizations.of(context)!.professionalAccountDescription,
                            icon:        Icons.work_outline,
                            accentColor: AppColors.professionalColor,
                            isSelected:  _selectedRole == 'professional',
                            onTap: () => setState(() => _selectedRole = 'professional'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Full Name ─────────────────────────────
                    TextFormField(
                      controller:         _nameController,
                      focusNode:          _nameFocusNode,
                      style:              context.textStyles.inputText,
                      textCapitalization: TextCapitalization.words,
                      textInputAction:    TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_emailFocusNode),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fullNameLabel,
                        hintText: AppLocalizations.of(context)!.fullNameHint,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: AppValidators.name,
                    ),

                    const SizedBox(height: AppSizes.sm),

                    // ── Email ─────────────────────────────────
                    TextFormField(
                      controller:   _emailController,
                      focusNode:    _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect:  false,
                      style:        context.textStyles.inputText,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocusNode),
                      decoration: InputDecoration(
                        labelText:  AppStrings.email,
                        hintText:   AppLocalizations.of(context)!.emailHint,
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: _emailSuffixIcon(),
                      ),
                      validator: AppValidators.email,
                    ),
                    _buildEmailHint(),

                    const SizedBox(height: AppSizes.sm),

                    // ── Country ───────────────────────────────
                    SearchablePickerField<Map<String, dynamic>>(
                      value:      _selectedCountry,
                      items:      List<Map<String, dynamic>>.from(_countries),
                      itemLabel:  (c) => c['name'] as String,
                      itemLeading: (c) {
                        final flag = CountryFlags.flagFor(c['name'] as String);
                        return flag != null
                            ? Text(flag, style: const TextStyle(fontSize: 20))
                            : const Icon(Icons.public, size: 20);
                      },
                      label:      AppLocalizations.of(context)!.countryLabel,
                      hint:       AppLocalizations.of(context)!.countryHint,
                      prefixIcon: Icons.public_outlined,
                      loading:    _loadingCountries,
                      searchHint: AppLocalizations.of(context)!.countrySearchHint,
                      emptyMessage: AppLocalizations.of(context)!.countryEmptyMessage,
                      onChanged: (country) {
                        if (country != null) _onCountrySelected(country);
                      },
                      validator: (value) =>
                          value == null ? AppLocalizations.of(context)!.countryRequiredError : null,
                    ),

                    const SizedBox(height: AppSizes.sm),

                    // ── City — depends on Country ─────────────
                    SearchablePickerField<Map<String, dynamic>>(
                      key:        ValueKey(_selectedCountry?['id']),
                      value:      _selectedCity,
                      items:      List<Map<String, dynamic>>.from(_cities),
                      itemLabel:  (c) => c['name'] as String,
                      label:      AppLocalizations.of(context)!.cityLabel,
                      hint:       AppLocalizations.of(context)!.cityHint,
                      prefixIcon: Icons.location_city_outlined,
                      enabled:    _selectedCountry != null,
                      loading:    _loadingCities,
                      disabledHint: AppLocalizations.of(context)!.cityDisabledHint,
                      searchHint: AppLocalizations.of(context)!.citySearchHint,
                      emptyMessage: AppLocalizations.of(context)!.cityEmptyMessage,
                      onChanged: (city) => setState(() => _selectedCity = city),
                      validator: (value) =>
                          value == null ? AppLocalizations.of(context)!.cityRequiredError : null,
                    ),

                    // ── Category — only for professionals ─────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve:    Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _selectedRole != 'professional'
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: AppSizes.sm),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                opacity: 1,
                                child: SearchablePickerField<Map<String, dynamic>>(
                                  value: _selectedCategory,
                                  items: List<Map<String, dynamic>>.from(_categories),
                                  itemLabel: (cat) => cat['name'] ?? '',
                                  label:      AppLocalizations.of(context)!.professionLabel,
                                  hint:       AppLocalizations.of(context)!.professionHint,
                                  prefixIcon: Icons.category_outlined,
                                  searchHint: AppLocalizations.of(context)!.professionSearchHint,
                                  emptyMessage: AppLocalizations.of(context)!.professionEmptyMessage,
                                  onChanged: (cat) =>
                                      setState(() => _selectedCategory = cat),
                                  validator: (value) {
                                    if (_selectedRole == 'professional' && value == null) {
                                      return AppLocalizations.of(context)!.professionRequiredError;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: AppSizes.sm),

                    // ── Password ──────────────────────────────
                    TextFormField(
                      controller:  _passwordController,
                      focusNode:   _passwordFocusNode,
                      obscureText: _obscurePassword,
                      style:       context.textStyles.inputText,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_confirmFocusNode),
                      decoration: InputDecoration(
                        labelText:  AppStrings.password,
                        hintText:   AppLocalizations.of(context)!.passwordHint,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: AppValidators.password,
                    ),
                    if (_showCapsLockHint && _capsLockOn && _passwordFocusNode.hasFocus)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!.capsLockOnHint,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PasswordStrengthMeter(password: _passwordController.text),

                    const SizedBox(height: AppSizes.sm),

                    // ── Confirm Password ──────────────────────
                    TextFormField(
                      controller:  _confirmPassController,
                      focusNode:   _confirmFocusNode,
                      obscureText: _obscureConfirm,
                      style:       context.textStyles.inputText,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _onRegisterPressed(),
                      decoration: InputDecoration(
                        labelText:  AppStrings.confirmPass,
                        hintText:   AppLocalizations.of(context)!.confirmPasswordHint,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_confirmPassController.text.isNotEmpty)
                              Icon(
                                _confirmPassController.text == _passwordController.text
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _confirmPassController.text == _passwordController.text
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 20,
                              ),
                            IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ],
                        ),
                      ),
                      validator: (value) => AppValidators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ── Register Button ───────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (auth.isLoading || !_isFormValid) ? null : _onRegisterPressed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: auth.isLoading
                            ? const AppButtonLoader()
                            : Text(
                                AppLocalizations.of(context)!.registerCta,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Divider ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                          child: Text(
                            AppLocalizations.of(context)!.orContinueWithLabel,
                            style: AppTextStyles.label,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Google ────────────────────────────────
                    SocialAuthButton(
                      // ✅ replaced CustomPaint(painter: _GoogleLogoPainter())
                      // with the real Google "G" SVG widget — everything else
                      // about the button (size, colors, border, spacing,
                      // onTap) is unchanged.
                      logo: const GoogleLogo(size: 18),
                      label: AppLocalizations.of(context)!.googleSignInLabel,
                      background: isDark ? const Color(0xFF2C2C2E) : AppColors.white,
                      textColor: context.colors.textPrimary,
                      borderColor: context.colors.divider,
                      onTap: _handleGoogleSignIn,
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Login Link ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.hasAccount,
                          style: context.textStyles.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            AppStrings.login,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.professionalColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}