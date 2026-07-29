// lib/core/utils/app_validators.dart

class AppValidators {
  AppValidators._();

  // Special characters treated as "special" for password rules everywhere
  // in this file (validator + live strength meter) — kept in one place so
  // the two never drift apart.
  static final RegExp _specialCharPattern =
      RegExp(r'''[!@#$%^&*()_+\-=\[\]{};:'",.<>/?\\|`~]''');

  // ─── Email ──────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    // Simple email format check
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    if (value.trim().length > 254) {
      return 'Email is too long';
    }
    return null; // null mean valid
  }

  // ─── Password ───────────────────────────────────────────
  // Requires: 8+ chars, 1 uppercase, 1 lowercase, 1 number, 1 special char.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Add at least one number';
    }
    if (!_specialCharPattern.hasMatch(value)) {
      return 'Add at least one special character';
    }
    return null;
  }

  // ─── Login Password ─────────────────────────────────────
  // Login is NOT account creation — the Login screen must never enforce
  // strength/composition rules (min length, upper/lower/number/special).
  // Those only matter at registration time. Here we only confirm the
  // field isn't empty; the backend is the sole source of truth on whether
  // the credentials are actually correct.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  // ─── Confirm Password ───────────────────────────────────
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Name ───────────────────────────────────────────────
  // Required, 2–50 chars (after trim + space-collapse), unicode letters
  // supported (so non-English names work), numbers not allowed.
  static String? name(String? value) {
    if (value == null) return 'Name is required';
    final collapsed = normalizeName(value);
    if (collapsed.isEmpty) {
      return 'Name is required';
    }
    if (collapsed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (collapsed.length > 50) {
      return 'Name must be under 50 characters';
    }
    if (RegExp(r'[0-9]').hasMatch(collapsed)) {
      return 'Name cannot contain numbers';
    }
    // Unicode letters/marks, spaces, and common name punctuation only.
    final validPattern = RegExp(r"^[\p{L}\p{M} '.-]+$", unicode: true);
    if (!validPattern.hasMatch(collapsed)) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  // Trims leading/trailing spaces and collapses internal multiple spaces —
  // used both by the validator above and by the screen right before the
  // name is sent to the backend, so what's validated is what's saved.
  static String normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ─── Phone ──────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.trim().length < 7) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ─── Required field (generic) ───────────────────────────
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ─── Live Password Strength (for the strength meter widget) ────────────
  // Distinct from `password()` above: that's pass/fail for form submission,
  // this is graduated (0–1 score + per-requirement checklist) for realtime
  // feedback while the user is still typing.
  static PasswordStrengthResult passwordStrength(String value) {
    final hasMinLength = value.length >= 8;
    final hasUpper     = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower     = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber    = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial   = _specialCharPattern.hasMatch(value);

    final requirements = <PasswordRequirement>[
      PasswordRequirement('Minimum 8 characters', hasMinLength),
      PasswordRequirement('Uppercase letter',     hasUpper),
      PasswordRequirement('Lowercase letter',     hasLower),
      PasswordRequirement('Number',               hasNumber),
      PasswordRequirement('Special character',    hasSpecial),
    ];

    if (value.isEmpty) {
      return PasswordStrengthResult(
        level: PasswordStrengthLevel.veryWeak,
        score: 0,
        requirements: requirements,
      );
    }

    final metCount = requirements.where((r) => r.met).length;
    // Length bonus keeps "Excellent" feeling earned rather than just
    // ticking five boxes — a 9-char password maxing every checkbox still
    // reads as "Strong", not "Excellent".
    final lengthBonus = value.length >= 12 ? 1 : 0;

    final rawScore   = metCount + lengthBonus; // out of 6
    final normalized = (rawScore / 6).clamp(0.0, 1.0);

    PasswordStrengthLevel level;
    if (metCount <= 1) {
      level = PasswordStrengthLevel.veryWeak;
    } else if (metCount == 2) {
      level = PasswordStrengthLevel.weak;
    } else if (metCount == 3) {
      level = PasswordStrengthLevel.medium;
    } else if (metCount == 4) {
      level = PasswordStrengthLevel.strong;
    } else {
      level = lengthBonus > 0
          ? PasswordStrengthLevel.excellent
          : PasswordStrengthLevel.strong;
    }

    return PasswordStrengthResult(
      level: level,
      score: normalized,
      requirements: requirements,
    );
  }
}

enum PasswordStrengthLevel { veryWeak, weak, medium, strong, excellent }

class PasswordRequirement {
  final String label;
  final bool met;
  const PasswordRequirement(this.label, this.met);
}

class PasswordStrengthResult {
  final PasswordStrengthLevel level;
  final double score; // 0.0–1.0, for the animated progress bar
  final List<PasswordRequirement> requirements;
  const PasswordStrengthResult({
    required this.level,
    required this.score,
    required this.requirements,
  });
}