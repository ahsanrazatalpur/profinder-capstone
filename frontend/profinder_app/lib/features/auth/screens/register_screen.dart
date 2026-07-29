// lib/features/auth/screens/register_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_loader.dart';
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
import '../../../core/widgets/coming_soon_screen.dart';
import 'login_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

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
      AppHelpers.showError(context, 'Please select your profession category.');
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
        auth.errorMessage ?? AppStrings.serverError,
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

  void _goToComingSoon(String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComingSoonScreen(
          title:   provider,
          message: "We're finishing up secure sign-in with $provider. "
              "Check back soon — for now, please create your account with email.",
        ),
      ),
    );
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
      return const Padding(
        padding: EdgeInsets.only(top: 6, left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: AppColors.success),
            SizedBox(width: 6),
            Text(
              'Email available',
              style: TextStyle(
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
            const Expanded(
              child: Text(
                'This email is already registered.',
                style: TextStyle(
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
                'Sign In Instead',
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
                    Text('Create Account', style: context.textStyles.h2),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Join ProFinder and connect with professionals.',
                      style: context.textStyles.bodyMedium,
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Account Type ───────────────────────────
                    Text('Choose Account Type', style: AppTextStyles.label),
                    const SizedBox(height: AppSizes.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AccountTypeCard(
                            title:       AppStrings.customer,
                            description: 'Hire trusted professionals.',
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
                            description: 'Offer your services and grow your business.',
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
                      decoration: const InputDecoration(
                        labelText:  'Full Name',
                        hintText:   'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline),
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
                        hintText:   'example@email.com',
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
                      label:      'Country',
                      hint:       'Select your country',
                      prefixIcon: Icons.public_outlined,
                      loading:    _loadingCountries,
                      searchHint: 'Search countries...',
                      emptyMessage: 'No countries found',
                      onChanged: (country) {
                        if (country != null) _onCountrySelected(country);
                      },
                      validator: (value) =>
                          value == null ? 'Please select your country' : null,
                    ),

                    const SizedBox(height: AppSizes.sm),

                    // ── City — depends on Country ─────────────
                    SearchablePickerField<Map<String, dynamic>>(
                      key:        ValueKey(_selectedCountry?['id']),
                      value:      _selectedCity,
                      items:      List<Map<String, dynamic>>.from(_cities),
                      itemLabel:  (c) => c['name'] as String,
                      label:      'City',
                      hint:       'Select your city',
                      prefixIcon: Icons.location_city_outlined,
                      enabled:    _selectedCountry != null,
                      loading:    _loadingCities,
                      disabledHint: 'Select a country first',
                      searchHint: 'Search cities...',
                      emptyMessage: 'No cities found',
                      onChanged: (city) => setState(() => _selectedCity = city),
                      validator: (value) =>
                          value == null ? 'Please select your city' : null,
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
                                  label:      'Your Profession',
                                  hint:       'Select your category',
                                  prefixIcon: Icons.category_outlined,
                                  searchHint: 'Search professions...',
                                  emptyMessage: 'No categories found',
                                  onChanged: (cat) =>
                                      setState(() => _selectedCategory = cat),
                                  validator: (value) {
                                    if (_selectedRole == 'professional' && value == null) {
                                      return 'Please select your profession';
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
                        hintText:   'Min. 8 characters',
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
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text(
                              'Caps Lock is on',
                              style: TextStyle(
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
                        hintText:   'Re-enter your password',
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
                    ElevatedButton(
                      onPressed: (auth.isLoading || !_isFormValid) ? null : _onRegisterPressed,
                      child: auth.isLoading
                          ? const AppButtonLoader()
                          : Text(AppStrings.register),
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Divider ───────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                          child: Text('or continue with', style: AppTextStyles.label),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Google ────────────────────────────────
                    SocialAuthButton(
                      logo: SizedBox(
                        width: 22, height: 22,
                        child: CustomPaint(painter: _GoogleLogoPainter()),
                      ),
                      label:       'Continue with Google',
                      background:  AppColors.white,
                      textColor:   context.colors.textPrimary,
                      borderColor: context.colors.divider,
                      onTap: () => _goToComingSoon('Google Sign-In'),
                    ),

                    const SizedBox(height: AppSizes.sm),

                    // ── Facebook + Twitter ────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: SocialAuthButton(
                            logo: const Icon(Icons.facebook_rounded, color: AppColors.white, size: 20),
                            label:      'Facebook',
                            background: const Color(0xFF1877F2),
                            textColor:  AppColors.white,
                            onTap: () => _goToComingSoon('Facebook Sign-In'),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: SocialAuthButton(
                            logo: const Icon(Icons.close, color: AppColors.white, size: 18),
                            label:      'Twitter',
                            background: AppColors.black,
                            textColor:  AppColors.white,
                            onTap: () => _goToComingSoon('X (Twitter) Sign-In'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.md),

                    // ── Login Link ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.hasAccount, style: context.textStyles.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child:     Text(AppStrings.login),
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

// ── Google Logo ───────────────────────────────────────────────
// Drawn as a colored ring (stroke, not a filled pie) with a crossbar,
// matching the real Google "G" proportions instead of looking like a
// solid color-wheel blob.
class _GoogleLogoPainter extends CustomPainter {
  double _deg(double degrees) => degrees * 3.1415926535 / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final ringRadius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    ringPaint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, _deg(-10), _deg(100), false, ringPaint);

    ringPaint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, _deg(90), _deg(90), false, ringPaint);

    ringPaint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, _deg(180), _deg(70), false, ringPaint);

    ringPaint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, _deg(250), _deg(100), false, ringPaint);

    // Crossbar of the "G" — bridges the ring to the center on the blue
    // (right) side, which is what actually reads as a "G" rather than a
    // plain colored ring.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.15,
        center.dy - strokeWidth / 2,
        size.width / 2 - (center.dx - strokeWidth * 0.15),
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}