# apps/subscriptions/views.py

from django.utils import timezone
from datetime import timedelta
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny

from apps.subscriptions.models import SubscriptionPlan, Subscription
from apps.subscriptions.serializers import (
    SubscriptionPlanSerializer,
    SubscriptionSerializer,
    UserPlanStatusSerializer,
)
from apps.subscriptions.utils import (
    get_active_subscription,
    is_premium,
    get_feature_value,
    should_show_ads,
)


# ─── Public: Plans List ───────────────────────────────────────────────────────

class SubscriptionPlanView(APIView):
    """
    GET /api/subscriptions/plans/?type=customer  → customer plans
    GET /api/subscriptions/plans/?type=professional → professional plans
    GET /api/subscriptions/plans/  → sab plans
    """
    permission_classes = [AllowAny]

    def get(self, request):
        plan_type = request.query_params.get('type', '')
        plans = SubscriptionPlan.objects.filter(is_active=True)
        if plan_type in ('customer', 'professional'):
            plans = plans.filter(plan_type=plan_type)
        return Response(SubscriptionPlanSerializer(plans, many=True).data)


# ─── User: My Plan Status ─────────────────────────────────────────────────────

class MyPlanView(APIView):
    """
    GET /api/subscriptions/my-plan/
    Flutter is se pata karta hai user ka current plan kya hai,
    limits kya hain, premium hai ya free.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sub = get_active_subscription(request.user)

        if sub is None:
            # Free user — koi subscription nahi
            return Response({
                'has_subscription': False,
                'plan_name':        'Free',
                'plan_type':        request.user.role,
                'billing':          'free',
                'is_premium':       False,
                'end_date':         None,
                'features':         {},
                'ads_enabled':      True,
            })

        # Features dict banao
        features = {}
        for f in sub.plan.features.all():
            if f.feature_type == 'int':
                features[f.key] = f.as_int()
            elif f.feature_type == 'bool':
                features[f.key] = f.as_bool()
            else:
                features[f.key] = f.value

        end_date_str = sub.end_date.strftime('%d %b %Y') if sub.end_date else None

        return Response({
            'has_subscription': True,
            'plan_name':        sub.plan.name,
            'plan_type':        sub.plan.plan_type,
            'billing':          sub.plan.billing,
            'is_premium':       is_premium(request.user),
            'end_date':         end_date_str,
            'features':         features,
            'ads_enabled':      should_show_ads(request.user),
        })


# ─── User: Subscribe / Cancel ─────────────────────────────────────────────────

class SubscriptionView(APIView):
    """
    GET  /api/subscriptions/  → meri sab subscriptions
    POST /api/subscriptions/  → new plan subscribe karo
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        subs = Subscription.objects.filter(user=request.user)
        return Response(SubscriptionSerializer(subs, many=True).data)

    def post(self, request):
        plan_id = request.data.get('plan')
        if not plan_id:
            return Response({'error': 'plan field is required.'}, status=400)

        try:
            plan = SubscriptionPlan.objects.get(id=plan_id, is_active=True)
        except SubscriptionPlan.DoesNotExist:
            return Response({'error': 'Plan not found or inactive.'}, status=404)

        # Plan type user role se match karna chahiye
        if plan.plan_type != request.user.role:
            return Response({
                'error': f'This plan is for {plan.plan_type}s only.'
            }, status=400)

        # Pehle wala active subscription cancel karo
        Subscription.objects.filter(
            user=request.user, status='active'
        ).update(status='cancelled')

        # End date calculate karo
        end_date = None
        if plan.duration_days > 0:
            end_date = timezone.now() + timedelta(days=plan.duration_days)

        sub = Subscription.objects.create(
            user=request.user,
            plan=plan,
            status='active',
            end_date=end_date,
        )

        return Response(SubscriptionSerializer(sub).data, status=201)


class CancelSubscriptionView(APIView):
    """
    POST /api/subscriptions/cancel/
    Active subscription cancel karo.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sub = get_active_subscription(request.user)
        if not sub:
            return Response({'error': 'No active subscription found.'}, status=404)

        if sub.plan.billing == 'free':
            return Response({'error': 'Free plan cancel nahi hoti.'}, status=400)

        sub.status = 'cancelled'
        sub.save(update_fields=['status'])
        return Response({'message': 'Subscription cancelled successfully.'})
