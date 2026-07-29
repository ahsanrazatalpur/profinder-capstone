# apps/reviews/models.py
from django.db import models
from django.conf import settings
from cloudinary.models import CloudinaryField


class Review(models.Model):
    reviewer     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='given_reviews')
    professional = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='received_reviews')
    rating       = models.IntegerField(default=1)
    comment      = models.TextField(blank=True)
    created_at   = models.DateTimeField(auto_now_add=True)

    # ✅ NEW — "Verified Service" badge. True only if the reviewer had a
    # COMPLETED booking with this professional at the moment they reviewed.
    is_verified_service = models.BooleanField(default=False)

    # ✅ NEW — Edit tracking, shown as a small "Edited" badge on the card.
    is_edited = models.BooleanField(default=False)
    edited_at = models.DateTimeField(null=True, blank=True)

    # ✅ NEW — Admin moderation ONLY. A negative-but-honest review must
    # never disappear just because the professional dislikes it — only
    # a genuine policy violation (spam/fake/abuse/etc, via ReviewReport)
    # should ever get an Admin to set is_hidden=True. Hidden reviews stay
    # in the DB (for audit) but are excluded from all public reads.
    is_hidden     = models.BooleanField(default=False)
    hidden_reason = models.TextField(blank=True)
    hidden_at     = models.DateTimeField(null=True, blank=True)

    class Meta:
        # Ek user ek professional ko sirf ek review de sakta hai — DB level pe enforce
        unique_together = ('reviewer', 'professional')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['professional', '-created_at'], name='review_prof_created_idx'),
        ]

    def __str__(self):
        return f"{self.reviewer.email} → {self.professional.email} - {self.rating}"


class ReviewPhoto(models.Model):
    """Up to a handful of photos a customer attaches to their review."""
    review     = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='photos')
    image      = CloudinaryField('image')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Photo for review #{self.review_id}"


class ReviewReply(models.Model):
    """The professional's single public reply to a review."""
    review     = models.OneToOneField(Review, on_delete=models.CASCADE, related_name='reply')
    text       = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Reply to review #{self.review_id}"


class ReviewHelpful(models.Model):
    """A customer can mark a review 'Helpful' once — unique_together enforces that."""
    review     = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='helpful_votes')
    user       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='helpful_marks')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('review', 'user')

    def __str__(self):
        return f"{self.user.email} found review #{self.review_id} helpful"


class ReviewReport(models.Model):
    REASON_CHOICES = [
        ('spam',                  'Spam'),
        ('fake',                  'Fake Review'),
        ('abusive',               'Abusive Language'),
        ('harassment',            'Harassment'),
        ('off_topic',             'Off-topic'),
        ('conflict_of_interest',  'Conflict of Interest'),
        ('other',                 'Other'),
    ]
    STATUS_CHOICES = [
        ('pending',   'Pending'),
        ('reviewed',  'Reviewed'),
        ('dismissed', 'Dismissed'),
        ('actioned',  'Actioned'),
    ]

    review     = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='reports')
    reporter   = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='review_reports')
    reason     = models.CharField(max_length=30, choices=REASON_CHOICES)
    note       = models.TextField(blank=True)
    status     = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Same person reporting the same review twice is a no-op, not a new report
        unique_together = ('review', 'reporter')

    def __str__(self):
        return f"Report on review #{self.review_id} - {self.reason}"