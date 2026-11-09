import json
from urllib.parse import urljoin
from django.conf import settings


def get_base_url(request=None):
    """
    Returns absolute canonical base URL (https://profinder.com or request host).
    """
    if request:
        return request.build_absolute_uri('/')[:-1]
    return getattr(settings, 'SEO_SITE_URL', 'https://profinder.com')


def build_breadcrumb_schema(request, breadcrumb_items):
    """
    Generates Schema.org BreadcrumbList.
    breadcrumb_items: list of (name, relative_or_abs_path)
    """
    base_url = get_base_url(request)
    elements = []
    for idx, (name, path) in enumerate(breadcrumb_items, start=1):
        full_url = path if path.startswith('http') else urljoin(base_url, path)
        elements.append({
            "@type": "ListItem",
            "position": idx,
            "name": name,
            "item": full_url
        })
    return {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": elements
    }


def build_website_schema(request):
    """
    Generates Schema.org WebSite with SearchAction.
    """
    base_url = get_base_url(request)
    return {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": "ProFinder",
        "alternateName": "ProFinder Pakistan",
        "url": base_url,
        "potentialAction": {
            "@type": "SearchAction",
            "target": f"{base_url}/search/?q={{search_term_string}}",
            "query-input": "required name=search_term_string"
        }
    }


def build_organization_schema(request):
    """
    Generates Schema.org Organization for ProFinder platform.
    """
    base_url = get_base_url(request)
    return {
        "@context": "https://schema.org",
        "@type": "Organization",
        "name": "ProFinder",
        "url": base_url,
        "logo": f"{base_url}/static/images/logo.png",
        "description": "ProFinder is Pakistan's premier local service directory connecting verified professionals, technicians, doctors, and specialists directly with consumers.",
        "areaServed": "PK",
        "sameAs": [
            "https://www.facebook.com/profinderpk",
            "https://www.linkedin.com/company/profinderpk",
            "https://twitter.com/profinderpk"
        ]
    }


def build_professional_schema(request, profile, reviews_list=None):
    """
    Generates Schema.org Person & ProfessionalService schema for an individual professional.
    Strictly uses REAL database reviews and ratings — NO fake ratings.
    """
    base_url = get_base_url(request)
    display_name = getattr(profile.user, 'name', '') or profile.user.get_full_name()
    city = getattr(profile.user.userprofile, 'city', '') if hasattr(profile.user, 'userprofile') else ''
    area = getattr(profile.user.userprofile, 'area', '') if hasattr(profile.user, 'userprofile') else ''
    profile_url = f"{base_url}/professionals/{profile.slug}/"
    
    photo_url = None
    if profile.photo_url:
        try:
            photo_url = profile.photo_url.url
        except Exception:
            photo_url = str(profile.photo_url)

    schema = {
        "@context": "https://schema.org",
        "@type": ["Person", "ProfessionalService"],
        "name": display_name,
        "url": profile_url,
        "jobTitle": profile.specialization or (profile.category.name if profile.category else "Professional"),
        "description": profile.bio or f"Verified {profile.specialization or 'professional'} in {city or 'Pakistan'} on ProFinder.",
    }

    if photo_url:
        schema["image"] = photo_url

    # Address
    address = {
        "@type": "PostalAddress",
        "addressCountry": "PK"
    }
    if city:
        address["addressLocality"] = city
    if area:
        address["streetAddress"] = area
    schema["address"] = address

    # Hourly rate / price range
    if profile.hourly_rate and profile.hourly_rate > 0:
        schema["priceRange"] = f"PKR {profile.hourly_rate:,.0f}/hr"

    # Aggregate rating only if genuine reviews exist and average_rating > 0
    actual_reviews = reviews_list if reviews_list is not None else profile.user.received_reviews.filter(is_hidden=False)
    review_count = actual_reviews.count() if hasattr(actual_reviews, 'count') else len(actual_reviews)

    if review_count > 0 and profile.average_rating and profile.average_rating > 0:
        schema["aggregateRating"] = {
            "@type": "AggregateRating",
            "ratingValue": str(round(float(profile.average_rating), 1)),
            "reviewCount": str(review_count),
            "bestRating": "5",
            "worstRating": "1"
        }

        # Real reviews serialization
        schema_reviews = []
        for r in actual_reviews[:5]:
            reviewer_name = getattr(r.reviewer, 'name', 'Verified Customer') or 'Customer'
            schema_reviews.append({
                "@type": "Review",
                "author": {
                    "@type": "Person",
                    "name": reviewer_name
                },
                "datePublished": r.created_at.strftime('%Y-%m-%d') if hasattr(r, 'created_at') else "",
                "reviewBody": r.comment or "Verified service booking.",
                "reviewRating": {
                    "@type": "Rating",
                    "ratingValue": str(r.rating),
                    "bestRating": "5",
                    "worstRating": "1"
                }
            })
        if schema_reviews:
            schema["review"] = schema_reviews

    return schema


def build_service_schema(request, service_listing, related_pros=None):
    """
    Generates Schema.org Service schema for a specific service page.
    """
    base_url = get_base_url(request)
    service_url = f"{base_url}/services/{service_listing.slug}/"

    schema = {
        "@context": "https://schema.org",
        "@type": "Service",
        "name": service_listing.title,
        "url": service_url,
        "description": service_listing.short_description or service_listing.full_content[:200],
        "provider": {
            "@type": "Organization",
            "name": "ProFinder Verified Providers",
            "url": base_url
        },
        "areaServed": {
            "@type": "AdministrativeArea",
            "name": service_listing.city.name if service_listing.city else "Pakistan"
        }
    }
    return schema


def build_item_list_schema(request, items, title):
    """
    Generates Schema.org ItemList for category / directory pages.
    items: list of dicts with 'name', 'url', 'position'
    """
    base_url = get_base_url(request)
    elements = []
    for idx, item in enumerate(items, start=1):
        url = item.get('url', '')
        full_url = url if url.startswith('http') else urljoin(base_url, url)
        elements.append({
            "@type": "ListItem",
            "position": idx,
            "name": item.get('name', ''),
            "url": full_url
        })
    return {
        "@context": "https://schema.org",
        "@type": "ItemList",
        "name": title,
        "numberOfItems": len(elements),
        "itemListElement": elements
    }


def build_faq_schema(faq_list):
    """
    Generates Schema.org FAQPage schema from list of {'q': str, 'a': str}.
    """
    if not faq_list:
        return None
    main_entities = []
    for item in faq_list:
        q = item.get('q', '').strip()
        a = item.get('a', '').strip()
        if q and a:
            main_entities.append({
                "@type": "Question",
                "name": q,
                "acceptedAnswer": {
                    "@type": "Answer",
                    "text": a
                }
            })
    if not main_entities:
        return None
    return {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": main_entities
    }


def combine_schemas(*schemas):
    """
    Merges multiple valid schema dictionaries into a JSON string
    or a Graph array suitable for <script type="application/ld+json">.
    """
    valid = [s for s in schemas if s]
    if not valid:
        return ""
    if len(valid) == 1:
        return json.dumps(valid[0], indent=2, ensure_ascii=False)
    return json.dumps({
        "@context": "https://schema.org",
        "@graph": valid
    }, indent=2, ensure_ascii=False)
