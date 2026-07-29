from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.contrib.postgres.indexes import GinIndex


class UserManager(BaseUserManager):
    
    def create_user(self, email, name, role, password=None):
        user = self.model(
            email=self.normalize_email(email).lower(),
            name=name,
            role=role
        )
        user.set_password(password)
        user.save()
        return user

    def create_superuser(self, email, name, role, password):
        user = self.create_user(email, name, role, password)
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
    fcm_token  = models.CharField(max_length=255, blank=True, null=True)  # ✅ NEW — for push notifications
    created_at = models.DateTimeField(auto_now_add=True)

    # ✅ i18n — synced with the Flutter app's language selection.
    # null == user has never set a language (fresh account / never opened
    # the app since this field shipped); the app treats null as "upload
    # my locally selected language" rather than "use English".
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