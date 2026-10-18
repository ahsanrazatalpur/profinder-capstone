# apps/users/management/commands/test_reset_email.py
#
# Usage (PythonAnywhere Bash console, project folder mein):
#     python manage.py test_reset_email customer@example.com
#
# ForgotPasswordView security ki wajah se Brevo ke errors client se chhupata
# hai (app hamesha "link sent" dikhata hai). Ye command wahi asli code path
# (ForgotPasswordView._send_reset_email) chalata hai, lekin error seedha
# terminal mein dikha deta hai taake pata chale email kyun nahi ja rahi.

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from apps.users.models import User
from apps.users.views import ForgotPasswordView


class Command(BaseCommand):
    help = "Sends a real password-reset email to an existing user and shows any Brevo error."

    def add_arguments(self, parser):
        parser.add_argument("email", help="Email of an EXISTING user account")

    def handle(self, *args, **opts):
        email = opts["email"].strip().lower()

        self.stdout.write("── Config check ──")
        self.stdout.write(f"PUBLIC_BASE_URL    : {settings.PUBLIC_BASE_URL}")
        self.stdout.write(f"DEFAULT_FROM_EMAIL : {settings.DEFAULT_FROM_EMAIL}")
        self.stdout.write(f"BREVO_API_KEY set  : {bool(getattr(settings, 'BREVO_API_KEY', None))}")

        user = User.objects.filter(email__iexact=email).first()
        if not user:
            raise CommandError(
                f"No user with email '{email}' in THIS database. "
                "(App mein 'link sent' isi wajah se dikh sakta hai — "
                "check karo ke server ka DB wahi hai jahan ye account bana.)"
            )

        self.stdout.write(f"User found         : id={user.pk}, role={user.role}")
        self.stdout.write("── Sending reset email ──")

        try:
            ForgotPasswordView()._send_reset_email(None, user)
        except Exception as e:
            msg = str(e)
            self.stderr.write(self.style.ERROR(f"FAILED: {msg}"))
            low = msg.lower()
            if "401" in msg or "unauthor" in low or "key" in low:
                self.stderr.write("Hint: BREVO_API_KEY galat hai ya Brevo mein 'Authorised IPs' restriction on hai.")
            elif "400" in msg and ("sender" in low or "from" in low):
                self.stderr.write(
                    "Hint: DEFAULT_FROM_EMAIL Brevo mein VERIFIED sender nahi hai. "
                    "Brevo → Senders, Domains & Dedicated IPs → Senders mein is address ko add/verify karo."
                )
            elif "timeout" in low or "connection" in low:
                self.stderr.write("Hint: server se api.brevo.com tak network nahi pahunch raha.")
            raise CommandError("Reset email was NOT sent.")

        self.stdout.write(self.style.SUCCESS(
            f"OK — Brevo ne email accept kar li. Inbox (aur Spam folder) check karo: {user.email}"
        ))
