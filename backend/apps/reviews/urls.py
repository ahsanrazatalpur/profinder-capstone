# apps/reviews/urls.py
from django.urls import path
from apps.reviews.views import (
    ReviewView, MyReviewsView, MyGivenReviewsView, ReviewDetailView,
    ReviewHelpfulView, ReviewReplyView, ReviewReportView,
)

urlpatterns = [
    path('my-reviews/',                                   MyReviewsView.as_view(),      name='my_reviews'),
    path('mine/',                                         MyGivenReviewsView.as_view(), name='my_given_reviews'),  # ✅ NEW — customer's own written reviews
    path('professionals/<int:professional_id>/reviews/',  ReviewView.as_view(),         name='reviews'),

    # ✅ NEW
    path('<int:review_id>/',                              ReviewDetailView.as_view(), name='review_detail'),   # PATCH edit / DELETE own review
    path('<int:review_id>/helpful/',                      ReviewHelpfulView.as_view(),name='review_helpful'),  # POST toggle helpful
    path('<int:review_id>/reply/',                        ReviewReplyView.as_view(),  name='review_reply'),    # POST professional reply
    path('<int:review_id>/report/',                       ReviewReportView.as_view(), name='review_report'),   # POST report review
]