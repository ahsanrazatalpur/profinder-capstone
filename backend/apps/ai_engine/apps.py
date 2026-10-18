from django.apps import AppConfig


class AiEngineConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.ai_engine'
    label = 'ai_engine'

    def ready(self):
        from apps.ai_engine import signals
        signals.connect()