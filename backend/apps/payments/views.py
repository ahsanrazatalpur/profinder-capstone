from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from apps.payments.models import Payment, WithdrawalRequest
from apps.payments.serializers import PaymentSerializer, WithdrawalRequestSerializer

class PaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        payments = Payment.objects.filter(user=request.user)
        serializer = PaymentSerializer(payments, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = PaymentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user, status='pending')
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─── Wallet ────────────────────────────────────────────────────────────
# Minimum withdrawal amount — business rule, easy to tune from one place.
MIN_WITHDRAWAL_AMOUNT = 20.0


class WalletSummaryView(APIView):
    """
    GET /api/payments/wallet/
    Ek hi call mein: available balance, total earned, total withdrawn,
    pending withdrawal amount, aur combined transaction history (bookings
    ki earnings + withdrawal requests, dono chronological order mein).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from apps.bookings.models import Booking
        from apps.profiles.models import ProfessionalProfile

        user = request.user

        try:
            profile = ProfessionalProfile.objects.get(user=user)
            hourly_rate = float(profile.hourly_rate or 0)
        except ProfessionalProfile.DoesNotExist:
            hourly_rate = 0

        # NOTE: Booking mein abhi per-job price field nahi hai (jaisa
        # dashboard endpoint mein bhi likha hai) — is liye hourly_rate ko
        # har completed booking ki value maan rahe hain.
        completed_bookings = Booking.objects.filter(professional=user, status='completed').order_by('-date')
        total_earned = completed_bookings.count() * hourly_rate

        withdrawals = WithdrawalRequest.objects.filter(professional=user)
        total_withdrawn   = sum(float(w.amount) for w in withdrawals.filter(status__in=['approved', 'paid']))
        pending_withdrawal = sum(float(w.amount) for w in withdrawals.filter(status='pending'))

        available_balance = max(0.0, total_earned - total_withdrawn - pending_withdrawal)

        # ── Combined transaction history — credits (earnings) + debits (withdrawals) ──
        transactions = []
        for b in completed_bookings:
            transactions.append({
                'type':   'credit',
                'label':  f'Job completed — {b.customer.name}' if b.customer else 'Job completed',
                'amount': hourly_rate,
                'status': 'completed',
                'date':   b.date.isoformat() if b.date else None,
            })
        for w in withdrawals:
            transactions.append({
                'type':   'debit',
                'label':  'Withdrawal request',
                'amount': float(w.amount),
                'status': w.status,
                'date':   w.requested_at.date().isoformat() if w.requested_at else None,
            })
        transactions.sort(key=lambda t: t['date'] or '', reverse=True)

        return Response({
            'available_balance':   available_balance,
            'total_earned':        total_earned,
            'total_withdrawn':     total_withdrawn,
            'pending_withdrawal':  pending_withdrawal,
            'min_withdrawal':      MIN_WITHDRAWAL_AMOUNT,
            'bank_on_file':        bool(profile.bank_account_number) if hasattr(profile, 'bank_account_number') else False,
            'transactions':        transactions,
        })


class WithdrawalRequestView(APIView):
    """
    GET  /api/payments/withdrawals/   — professional ki saari withdrawal requests
    POST /api/payments/withdrawals/   — nayi request banao {"amount": 50}
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        withdrawals = WithdrawalRequest.objects.filter(professional=request.user)
        return Response(WithdrawalRequestSerializer(withdrawals, many=True).data)

    def post(self, request):
        from apps.profiles.models import ProfessionalProfile
        from apps.bookings.models import Booking

        try:
            profile = ProfessionalProfile.objects.get(user=request.user)
        except ProfessionalProfile.DoesNotExist:
            return Response({'error': 'Complete your profile first.'}, status=status.HTTP_400_BAD_REQUEST)

        if not profile.bank_account_number:
            return Response({'error': 'Add your bank details before requesting a withdrawal.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            amount = float(request.data.get('amount', 0))
        except (TypeError, ValueError):
            return Response({'error': 'Invalid amount.'}, status=status.HTTP_400_BAD_REQUEST)

        if amount < MIN_WITHDRAWAL_AMOUNT:
            return Response({'error': f'Minimum withdrawal amount is ${MIN_WITHDRAWAL_AMOUNT:.0f}.'}, status=status.HTTP_400_BAD_REQUEST)

        # ── Available balance dobara calculate karo (server-side, client
        # ke bheje number par bharosa nahi kar sakte) ──────────────────
        hourly_rate = float(profile.hourly_rate or 0)
        completed_count = Booking.objects.filter(professional=request.user, status='completed').count()
        total_earned = completed_count * hourly_rate

        existing = WithdrawalRequest.objects.filter(professional=request.user)
        total_withdrawn    = sum(float(w.amount) for w in existing.filter(status__in=['approved', 'paid']))
        pending_withdrawal = sum(float(w.amount) for w in existing.filter(status='pending'))
        available = total_earned - total_withdrawn - pending_withdrawal

        if amount > available:
            return Response({'error': f'Amount exceeds your available balance (${available:.2f}).'}, status=status.HTTP_400_BAD_REQUEST)

        withdrawal = WithdrawalRequest.objects.create(
            professional=request.user,
            amount=amount,
            bank_account_name=profile.bank_account_name,
            bank_account_number=profile.bank_account_number,
            bank_name=profile.bank_name,
        )
        return Response(WithdrawalRequestSerializer(withdrawal).data, status=status.HTTP_201_CREATED)