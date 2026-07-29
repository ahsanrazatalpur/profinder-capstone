# apps/subscriptions/serializers.py

from rest_framework import serializers
from apps.subscriptions.models import SubscriptionPlan, PlanFeature, Subscription


class PlanFeatureSerializer(serializers.ModelSerializer):
    class Meta:
        model  = PlanFeature
        fields = ['id', 'key', 'value', 'feature_type', 'label']


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    features = PlanFeatureSerializer(many=True, read_only=True)

    class Meta:
        model  = SubscriptionPlan
        fields = [
            'id', 'name', 'plan_type', 'billing', 'price', 'currency',
            'duration_days', 'is_active', 'features', 'created_at',
        ]


class SubscriptionSerializer(serializers.ModelSerializer):
    plan_name    = serializers.CharField(source='plan.name',      read_only=True)
    plan_type    = serializers.CharField(source='plan.plan_type', read_only=True)
    billing      = serializers.CharField(source='plan.billing',   read_only=True)
    price        = serializers.DecimalField(
        source='plan.price', max_digits=10, decimal_places=2, read_only=True)
    is_valid     = serializers.SerializerMethodField()

    class Meta:
        model  = Subscription
        fields = [
            'id', 'plan', 'plan_name', 'plan_type', 'billing', 'price',
            'status', 'start_date', 'end_date', 'is_valid',
        ]
        read_only_fields = ['status', 'start_date']

    def get_is_valid(self, obj):
        return obj.is_valid()


class UserPlanStatusSerializer(serializers.Serializer):
    """
    Flutter ko user ka current plan status bhejne ke liye.
    GET /api/subscriptions/my-plan/ → yahi data aayega.
    """
    has_subscription = serializers.BooleanField()
    plan_name        = serializers.CharField(allow_null=True)
    plan_type        = serializers.CharField(allow_null=True)
    billing          = serializers.CharField(allow_null=True)
    is_premium       = serializers.BooleanField()
    end_date         = serializers.CharField(allow_null=True)
    features         = serializers.DictField(allow_null=True)
    ads_enabled      = serializers.BooleanField()
