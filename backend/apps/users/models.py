import hashlib
import os
import secrets
from datetime import timedelta

from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.contrib.postgres.indexes import GinIndex
from django.utils import timezone


class UserManager(BaseUserManager):
    
    def create_user(self, email, name, role, password=None, is_email_verified=False):
        user = self.model(
            email=self.normalize_email(email).lower(),
            name=name,
            role=role,
            is_email_verified=is_email_verified,
        )
        user.set_password(password)
        user.save()
        return user

    def create_superuser(self, email, name, role, password):
        user = self.create_user(email, name, role, password, is_email_verified=True)
        user.is_staff = True
        user.is_superuser = True
        user.save()
        return user


class User(AbstractBaseUser, PermissionsMixin):
    
    ROLE_CHOICES = [
        ('customer', 'Customer'),
        ('professional', 'Professional'),
        ('admin', 'Admin')
    ]
    
    email      = models.EmailField(unique=True)
    name       = models.CharField(max_length=255)
    role       = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active  = models.BooleanField(default=True)
    is_staff   = models.BooleanField(default=False)
    is_email_verified = models.BooleanField(default=False)
    fcm_token          = models.CharField(max_length=255, blank=True, null=True)  # ✅ NEW — for push notifications
    push_notifications  = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # ✅ i18n — synced with the Flutter app's language selection.
    LANGUAGE_CHOICES = [
        ('en', 'English'),
        ('ur', 'Urdu'),
        ('hi', 'Hindi'),
        ('ar', 'Arabic'),
        ('fr', 'French'),
        ('es', 'Spanish'),
    ]
    preferred_language = models.CharField(
        max_length=5, null=True, blank=True, choices=LANGUAGE_CHOICES,
    )
    
    objects = UserManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name', 'role']

    class Meta:
        indexes = [
            # Speeds up icontains/keyword search on name (Normal Search P1 field)
            GinIndex(fields=['name'], name='user_name_trgm_idx', opclasses=['gin_trgm_ops']),
            # role='professional' filter runs on every search request
            models.Index(fields=['role'], name='user_role_idx'),
        ]


class EmailOTP(models.Model):
    """
    Stores cryptographically hashed, one-time, time-limited 6-digit numeric OTPs.
    Plain OTP is NEVER stored in the database.
    """
    PURPOSE_SIGNUP = 'signup'
    PURPOSE_FORGOT_PASSWORD = 'forgot_password'

    PURPOSE_CHOICES = [
        (PURPOSE_SIGNUP, 'Signup Verification'),
        (PURPOSE_FORGOT_PASSWORD, 'Password Reset'),
    ]

    email = models.EmailField(db_index=True)
    otp_hash = models.CharField(max_length=128)
    salt = models.CharField(max_length=32)
    purpose = models.CharField(max_length=32, choices=PURPOSE_CHOICES, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(db_index=True)
    attempts = models.IntegerField(default=0)
    is_used = models.BooleanField(default=False)

    class Meta:
        indexes = [
            models.Index(fields=['email', 'purpose', 'is_used']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    @classmethod
    def generate_otp(cls, email: str, purpose: str, expiry_minutes: int = 5):
        """
        Generates a secure 6-digit numeric OTP, hashes it with a random salt,
        saves to database, and returns (otp_obj, plain_otp).
        Plain OTP is never stored in DB!
        """
        email = email.strip().lower()
        # Invalidate any existing unused OTP for this email and purpose
        cls.objects.filter(email=email, purpose=purpose, is_used=False).update(is_used=True)

        plain_otp = f"{secrets.SystemRandom().randint(100000, 999999)}"
        salt = secrets.token_hex(16)
        otp_hash = cls.hash_otp(plain_otp, salt)
        expires_at = timezone.now() + timedelta(minutes=expiry_minutes)

        otp_obj = cls.objects.create(
            email=email,
            otp_hash=otp_hash,
            salt=salt,
            purpose=purpose,
            expires_at=expires_at,
            attempts=0,
            is_used=False,
        )
        return otp_obj, plain_otp

    @staticmethod
    def hash_otp(plain_otp: str, salt: str) -> str:
        return hashlib.sha256(f"{salt}{plain_otp}".encode('utf-8')).hexdigest()

    def verify(self, candidate_otp: str, max_attempts: int = 5) -> tuple:
        """
        Checks candidate_otp against otp_hash.
        Enforces:
        - One-time use: must not be already used
        - Expiry: timezone.now() <= expires_at
        - Attempt limits: attempts < max_attempts
        Returns (success: bool, error_message: str)
        """
        if self.is_used:
            return False, "This verification code has already been used. Please request a new one."

        if timezone.now() > self.expires_at:
            self.is_used = True
            self.save(update_fields=['is_used'])
            return False, "This verification code has expired. Please request a new one."

        if self.attempts >= max_attempts:
            self.is_used = True
            self.save(update_fields=['is_used'])
            return False, "Too many failed attempts. This code has been invalidated. Please request a new one."

        candidate_hash = self.hash_otp(candidate_otp.strip(), self.salt)
        if secrets.compare_digest(candidate_hash, self.otp_hash):
            self.is_used = True
            self.save(update_fields=['is_used'])
            return True, ""

        self.attempts += 1
        self.save(update_fields=['attempts'])
        remaining = max_attempts - self.attempts
        if remaining <= 0:
            self.is_used = True
            self.save(update_fields=['is_used'])
            return False, "Too many failed attempts. This code has been invalidated. Please request a new one."
        return False, f"Incorrect verification code. You have {remaining} attempt{'s' if remaining != 1 else ''} remaining."