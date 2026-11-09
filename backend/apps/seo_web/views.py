from django.shortcuts import render, get_object_or_404, redirect
from django.http import HttpResponse, Http404
from django.db.models import Q
from django.utils import timezone
from datetime import datetime

from apps.search.models import Category
from apps.profiles.models import ProfessionalProfile, Portfolio, Certificate, ProfileView
from apps.reviews.models import Review
from apps.admin_panel.models import City, Country
from .models import ServiceListing, SlugRedirect
from .geo_data import PROVINCES, CITY_TO_PROVINCE, PROFESSION_MAPPINGS
from .seo_helpers import (
    get_base_url,
    build_breadcrumb_schema,
    build_website_schema,
    build_organization_schema,
    build_professional_schema,
    build_service_schema,
    build_item_list_schema,
    build_faq_schema,
    combine_schemas
)


def _get_lang_context(request):
    """
    Extracts current language (?lang=en|ur) and sets RTL/LTR direction.
    Restricted to English and Urdu for Pakistan-only scope.
    """
    lang = request.GET.get('lang', 'en').lower()
    if lang not in ['en', 'ur']:
        lang = 'en'
    return {
        'current_lang': lang,
        'current_lang_dir': 'rtl' if lang == 'ur' else 'ltr',
    }


def home_view(request):
    """
    SSR Homepage — Highly optimized for search engines and AI answer engines.
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    categories = Category.objects.all().order_by('name')
    featured_pros = (
        ProfessionalProfile.objects
        .filter(user__is_active=True)
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')[:8]
    )
    popular_cities = (
        City.objects
        .filter(slug__in=['karachi', 'lahore', 'islamabad', 'badin', 'hyderabad', 'rawalpindi', 'peshawar', 'quetta'])
        .order_by('name')
    )
    popular_services = ServiceListing.objects.filter(is_active=True)[:6]

    page_title = "ProFinder | Find Trusted Professionals in Pakistan"
    favicon_url = "/static/images/favicon.png"
    meta_description = (
        "Discover and connect with verified doctors, electricians, plumbers, engineers, "
        "tutors, and home service specialists across 99+ Pakistan cities. Compare transparent "
        "rates, verified reviews, and book directly with zero platform fee."
    )
    canonical_url = f"{base_url}/"

    website_schema = build_website_schema(request)
    org_schema = build_organization_schema(request)
    schema_json = combine_schemas(website_schema, org_schema)

    context = {
        'page_title': page_title,
        'favicon_url': favicon_url,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'categories': categories,
        'featured_pros': featured_pros,
        'popular_cities': popular_cities,
        'popular_services': popular_services,
        'provinces': PROVINCES,
        'breadcrumbs': [('Home', '/')],
        **lang_ctx
    }
    return render(request, 'seo_web/home.html', context)


def category_detail_view(request, category_slug):
    """
    Category Landing Page — e.g. /categories/healthcare/, /categories/electricians/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    category = get_object_or_404(Category, slug=category_slug)
    professionals = (
        ProfessionalProfile.objects
        .filter(category=category, user__is_active=True)
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')
    )
    other_categories = Category.objects.exclude(id=category.id)[:6]

    # Find unique active cities where these pros are based
    active_city_names = set(
        p.user.userprofile.city.strip().title()
        for p in professionals
        if hasattr(p.user, 'userprofile') and p.user.userprofile.city
    )
    active_cities = City.objects.filter(name__in=active_city_names).order_by('name')

    page_title = f"{category.name} in Pakistan | ProFinder"
    favicon_url = "/static/images/favicon.png"
    meta_description = (
        f"Connect with certified and verified {category.name.lower()} specialists across Pakistan. "
        f"Compare customer reviews, transparent hourly rates, and book directly on ProFinder."
    )
    canonical_url = f"{base_url}/categories/{category.slug}/"

    breadcrumbs = [
        ('Home', '/'),
        ('Categories', '/'),
        (category.name, canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)

    item_list_items = [
        {'name': p.user.name, 'url': f"{base_url}/professionals/{p.slug}/"}
        for p in professionals[:10]
    ]
    item_schema = build_item_list_schema(request, item_list_items, f"Verified {category.name} in Pakistan")

    faqs = [
        {
            'q': f"How do I find a reliable {category.name.lower()} specialist in Pakistan?",
            'a': f"ProFinder lets you filter {category.name.lower()} by city, inspect authentic customer reviews, view work portfolios, and verify credentials before booking."
        },
        {
            'q': f"What are typical charges for {category.name.lower()} in Pakistan?",
            'a': "Specialists display transparent hourly rates on their profile. Total job costs are agreed upon directly with the professional."
        },
        {
            'q': "How do I pay for services?",
            'a': "Payments are made directly to the specialist upon completion (Cash on Delivery, JazzCash, Easypaisa, or direct bank transfer). ProFinder charges no payment commission."
        }
    ]
    faq_schema = build_faq_schema(faqs)
    schema_json = combine_schemas(b_schema, item_schema, faq_schema)

    context = {
        'page_title': page_title,
        'favicon_url': favicon_url,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'category': category,
        'professionals': professionals,
        'active_cities': active_cities,
        'other_categories': other_categories,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/category.html', context)


def profession_detail_view(request, profession_slug):
    """
    Profession Landing Page — e.g. /profession/doctors/, /profession/electricians/, /profession/plumbers/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    prof_data = PROFESSION_MAPPINGS.get(profession_slug)
    if not prof_data:
        raise Http404("Profession not found in directory.")

    singular = prof_data['singular']
    cat_name = prof_data.get('category_name', '')

    professionals = (
        ProfessionalProfile.objects
        .filter(
            Q(specialization__icontains=singular) |
            Q(category__name__icontains=cat_name) |
            Q(category__slug=profession_slug),
            user__is_active=True
        )
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')
    )

    active_city_names = set(
        p.user.userprofile.city.strip().title()
        for p in professionals
        if hasattr(p.user, 'userprofile') and p.user.userprofile.city
    )
    active_cities = City.objects.filter(name__in=active_city_names).order_by('name')

    page_title = f"Find Verified {prof_data['name']} in Pakistan | ProFinder"
    meta_description = (
        f"Compare top-rated, certified {singular.lower()}s across Pakistan. "
        f"Browse verified credentials, genuine customer reviews, transparent rates, and book directly."
    )
    canonical_url = f"{base_url}/profession/{profession_slug}/"

    breadcrumbs = [
        ('Home', '/'),
        ('Professions', '/'),
        (prof_data['name'], canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)

    item_list_items = [
        {'name': p.user.name, 'url': f"{base_url}/professionals/{p.slug}/"}
        for p in professionals[:10]
    ]
    item_schema = build_item_list_schema(request, item_list_items, f"Verified {prof_data['name']}")
    schema_json = combine_schemas(b_schema, item_schema)

    context = {
        'page_title': page_title,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'profession': prof_data,
        'professionals': professionals,
        'active_cities': active_cities,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/profession.html', context)


def professional_detail_view(request, slug):
    """
    Individual Professional Profile Page — e.g. /professionals/faisal-shaikh-photographer-badin/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    pro = get_object_or_404(
        ProfessionalProfile.objects.select_related('user__userprofile', 'category'),
        slug=slug,
        user__is_active=True
    )

    # Log public view analytics quietly
    try:
        ProfileView.objects.create(
            professional=pro.user,
            viewer=request.user if request.user.is_authenticated else None
        )
    except Exception:
        pass

    reviews = (
        pro.user.received_reviews
        .filter(is_hidden=False)
        .select_related('reviewer')
        .order_by('-created_at')
    )
    reviews_count = reviews.count()

    portfolio_items = pro.user.portfolio.filter(status=Portfolio.APPROVED).order_by('-created_at')
    certificates = pro.user.certificates.all()

    city = getattr(pro.user.userprofile, 'city', '') if hasattr(pro.user, 'userprofile') else ''
    area = getattr(pro.user.userprofile, 'area', '') if hasattr(pro.user, 'userprofile') else ''
    spec = pro.specialization or (pro.category.name if pro.category else 'Specialist')

    # Related professionals in same city or category
    related_pros = (
        ProfessionalProfile.objects
        .filter(
            Q(user__userprofile__city=city) | Q(category=pro.category),
            user__is_active=True
        )
        .exclude(id=pro.id)
        .select_related('user__userprofile', 'category')
        .order_by('-average_rating')[:4]
    )

    skills_list = [s.strip() for s in pro.skills.split(',') if s.strip()] if pro.skills else []
    services_list = [s.strip() for s in pro.services.split(',') if s.strip()] if pro.services else []

    page_title = f"{pro.user.name} - {spec} in {city or 'Pakistan'} | ProFinder"
    photo_str = str(pro.photo_url.url) if (hasattr(pro, 'photo_url') and pro.photo_url) else ""
    favicon_url = photo_str if photo_str else "/static/images/favicon.png"
    og_image = photo_str if photo_str else f"{base_url}/static/images/profinder-banner.jpg"
    meta_description = (
        f"Hire {pro.user.name}, verified {spec} in {city or 'Pakistan'}. "
        f"Experience: {pro.experience_years} years. Rating: {pro.average_rating}/5.0 from {reviews_count} genuine reviews. "
        f"Transparent hourly rates and direct booking with zero commission."
    )
    canonical_url = f"{base_url}/professionals/{pro.slug}/"

    breadcrumbs = [
        ('Home', '/'),
        ('Professionals', '/'),
        (pro.user.name, canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)
    pro_schema = build_professional_schema(request, pro, reviews)
    schema_json = combine_schemas(b_schema, pro_schema)

    context = {
        'page_title': page_title,
        'favicon_url': favicon_url,
        'og_image': og_image,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'pro': pro,
        'city': city,
        'reviews': reviews,
        'reviews_count': reviews_count,
        'portfolio_items': portfolio_items,
        'certificates': certificates,
        'skills_list': skills_list,
        'services_list': services_list,
        'related_pros': related_pros,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/professional_detail.html', context)


def service_detail_view(request, service_slug):
    """
    Individual Service Page — e.g. /services/ac-repair-badin/, /services/home-cleaning-karachi/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    service = get_object_or_404(
        ServiceListing.objects.select_related('category', 'city'),
        slug=service_slug,
        is_active=True
    )

    # Specialists relevant to this service
    filters = Q(user__is_active=True)
    if service.category:
        filters &= Q(category=service.category)
    if service.city:
        filters &= Q(user__userprofile__city__iexact=service.city.name)

    specialists = (
        ProfessionalProfile.objects
        .filter(filters)
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')[:8]
    )

    page_title = f"{service.title} | ProFinder Pakistan"
    meta_description = service.short_description or (
        f"Book verified specialists for {service.title}. Compare transparent pricing, read authentic customer reviews, and hire directly."
    )
    canonical_url = f"{base_url}/services/{service.slug}/"

    breadcrumbs = [
        ('Home', '/'),
        ('Services', '/'),
        (service.title, canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)
    s_schema = build_service_schema(request, service, specialists)
    faq_schema = build_faq_schema(service.faq_data)
    schema_json = combine_schemas(b_schema, s_schema, faq_schema)

    context = {
        'page_title': page_title,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'service': service,
        'specialists': specialists,
        'faqs': service.faq_data,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/service_detail.html', context)


def country_view(request):
    """
    Country Landing Page — /pakistan/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    categories = Category.objects.all().order_by('name')
    major_cities = (
        City.objects
        .filter(slug__in=['karachi', 'lahore', 'islamabad', 'badin', 'hyderabad', 'rawalpindi', 'faisalabad', 'multan', 'peshawar', 'quetta'])
        .order_by('name')
    )
    all_cities = City.objects.all().order_by('name')

    page_title = "Find Trusted Professional Services in Pakistan | ProFinder"
    meta_description = (
        "Explore verified professional service directories across all provinces of Pakistan: "
        "Sindh, Punjab, Khyber Pakhtunkhwa, Balochistan, and Islamabad. Connect with certified experts directly."
    )
    canonical_url = f"{base_url}/pakistan/"

    breadcrumbs = [
        ('Home', '/'),
        ('Pakistan', canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)
    schema_json = combine_schemas(b_schema)

    context = {
        'page_title': page_title,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'provinces': PROVINCES,
        'major_cities': major_cities,
        'cities': all_cities,
        'categories': categories,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/country.html', context)


def province_view(request, province_slug):
    """
    Province Landing Page — e.g. /pakistan/sindh/, /pakistan/punjab/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    prov_slug = province_slug.lower()
    prov_data = PROVINCES.get(prov_slug)
    if not prov_data:
        raise Http404("Province not recognized.")

    cities = City.objects.filter(slug__in=prov_data['cities']).order_by('name')
    professionals = (
        ProfessionalProfile.objects
        .filter(user__userprofile__city__in=[c.name for c in cities], user__is_active=True)
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')[:8]
    )
    categories = Category.objects.all()[:6]

    page_title = f"Professional Services in {prov_data['name']}, Pakistan | ProFinder"
    meta_description = prov_data['description']
    canonical_url = f"{base_url}/pakistan/{prov_slug}/"

    breadcrumbs = [
        ('Home', '/'),
        ('Pakistan', f"{base_url}/pakistan/"),
        (prov_data['name'], canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)
    schema_json = combine_schemas(b_schema)

    context = {
        'page_title': page_title,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'province': prov_data,
        'province_slug': prov_slug,
        'cities': cities,
        'professionals': professionals,
        'categories': categories,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/province.html', context)


def city_view(request, province_slug, city_slug):
    """
    City Landing Page — e.g. /pakistan/sindh/badin/, /pakistan/sindh/karachi/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    prov_slug = province_slug.lower()
    prov_data = PROVINCES.get(prov_slug)
    city = get_object_or_404(City, slug=city_slug)

    categories = Category.objects.all().order_by('name')
    professionals = (
        ProfessionalProfile.objects
        .filter(user__userprofile__city__iexact=city.name, user__is_active=True)
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')
    )

    nearby_cities = (
        City.objects
        .filter(province=city.province)
        .exclude(id=city.id)[:6]
    )

    page_title = f"Find Trusted Professionals in {city.name}, {city.province or prov_data['name']} | ProFinder"
    meta_description = (
        f"Hire top-rated doctors, electricians, plumbers, engineers, tutors, and home service specialists in {city.name}. "
        f"Verified reviews, transparent rates, and direct booking."
    )
    canonical_url = f"{base_url}/pakistan/{prov_slug}/{city.slug}/"

    breadcrumbs = [
        ('Home', '/'),
        ('Pakistan', f"{base_url}/pakistan/"),
        (prov_data['name'] if prov_data else city.province, f"{base_url}/pakistan/{prov_slug}/"),
        (city.name, canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)
    item_list_items = [
        {'name': p.user.name, 'url': f"{base_url}/professionals/{p.slug}/"}
        for p in professionals[:10]
    ]
    item_schema = build_item_list_schema(request, item_list_items, f"Verified Professionals in {city.name}")
    schema_json = combine_schemas(b_schema, item_schema)

    context = {
        'page_title': page_title,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'city': city,
        'province': prov_data or {'name': city.province},
        'province_slug': prov_slug,
        'categories': categories,
        'professionals': professionals,
        'nearby_cities': nearby_cities,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/city.html', context)


def city_category_view(request, province_slug, city_slug, category_slug):
    """
    Category + Location Landing Page — e.g. /pakistan/sindh/badin/healthcare/, /pakistan/sindh/karachi/electricians/
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    prov_slug = province_slug.lower()
    prov_data = PROVINCES.get(prov_slug)
    city = get_object_or_404(City, slug=city_slug)
    category = get_object_or_404(Category, slug=category_slug)

    professionals = (
        ProfessionalProfile.objects
        .filter(
            category=category,
            user__userprofile__city__iexact=city.name,
            user__is_active=True
        )
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')
    )

    other_categories = Category.objects.exclude(id=category.id)[:6]

    page_title = f"Find Verified {category.name} in {city.name}, {city.province or 'Pakistan'} | ProFinder"
    meta_description = (
        f"Looking for reliable {category.name.lower()} in {city.name}? "
        f"Compare verified specialist profiles, genuine customer reviews, transparent hourly rates, and book directly on ProFinder."
    )
    canonical_url = f"{base_url}/pakistan/{prov_slug}/{city.slug}/{category.slug}/"

    breadcrumbs = [
        ('Home', '/'),
        ('Pakistan', f"{base_url}/pakistan/"),
        (prov_data['name'] if prov_data else city.province, f"{base_url}/pakistan/{prov_slug}/"),
        (city.name, f"{base_url}/pakistan/{prov_slug}/{city.slug}/"),
        (category.name, canonical_url)
    ]
    b_schema = build_breadcrumb_schema(request, breadcrumbs)
    item_list_items = [
        {'name': p.user.name, 'url': f"{base_url}/professionals/{p.slug}/"}
        for p in professionals[:10]
    ]
    item_schema = build_item_list_schema(request, item_list_items, f"Verified {category.name} in {city.name}")
    schema_json = combine_schemas(b_schema, item_schema)

    context = {
        'page_title': page_title,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'schema_json': schema_json,
        'city': city,
        'category': category,
        'province': prov_data or {'name': city.province},
        'province_slug': prov_slug,
        'professionals': professionals,
        'other_categories': other_categories,
        'breadcrumbs': breadcrumbs,
        **lang_ctx
    }
    return render(request, 'seo_web/city_category.html', context)


def search_view(request):
    """
    Search Page — /search/?q=...&category=...&city=...
    """
    base_url = get_base_url(request)
    lang_ctx = _get_lang_context(request)

    query = request.GET.get('q', '').strip()
    cat_slug = request.GET.get('category', '').strip()
    city_slug = request.GET.get('city', '').strip()

    categories = Category.objects.all().order_by('name')
    cities = City.objects.all().order_by('name')

    filters = Q(user__is_active=True)

    if query:
        filters &= (
            Q(specialization__icontains=query) |
            Q(skills__icontains=query) |
            Q(services__icontains=query) |
            Q(user__name__icontains=query) |
            Q(bio__icontains=query)
        )

    selected_category_obj = None
    if cat_slug:
        selected_category_obj = Category.objects.filter(slug=cat_slug).first()
        if selected_category_obj:
            filters &= Q(category=selected_category_obj)

    selected_city_obj = None
    if city_slug:
        selected_city_obj = City.objects.filter(slug=city_slug).first()
        if selected_city_obj:
            filters &= Q(user__userprofile__city__iexact=selected_city_obj.name)

    results = (
        ProfessionalProfile.objects
        .filter(filters)
        .select_related('user__userprofile', 'category')
        .order_by('-is_verified', '-average_rating')[:30]
    )

    page_title = "Search Verified Professionals & Services | ProFinder"
    meta_description = "Search and compare verified service specialists across Pakistan by trade, skill, or location on ProFinder."
    canonical_url = f"{base_url}/search/"

    # Prevent search index bloat with noindex when specific search filters are active
    meta_robots = "noindex, follow" if (query or cat_slug or city_slug) else "index, follow"

    context = {
        'page_title': page_title,
        'meta_description': meta_description,
        'canonical_url': canonical_url,
        'meta_robots': meta_robots,
        'query': query,
        'selected_category': cat_slug,
        'selected_city': city_slug,
        'selected_city_name': selected_city_obj.name if selected_city_obj else '',
        'categories': categories,
        'cities': cities,
        'results': results,
        'breadcrumbs': [('Home', '/'), ('Search', canonical_url)],
        **lang_ctx
    }
    return render(request, 'seo_web/search.html', context)


# ==============================================================================
# SITEMAP VIEWS
# ==============================================================================

def sitemap_index_view(request):
    """
    Primary XML Sitemap Index file pointing to sectional sitemaps.
    """
    base_url = get_base_url(request)
    now = timezone.now().strftime('%Y-%m-%d')
    sitemaps = [
        f"{base_url}/sitemap-categories.xml",
        f"{base_url}/sitemap-professions.xml",
        f"{base_url}/sitemap-professionals.xml",
        f"{base_url}/sitemap-locations.xml",
        f"{base_url}/sitemap-services.xml",
    ]
    xml_content = ['<?xml version="1.0" encoding="UTF-8"?>']
    xml_content.append('<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    for sm in sitemaps:
        xml_content.append('  <sitemap>')
        xml_content.append(f'    <loc>{sm}</loc>')
        xml_content.append(f'    <lastmod>{now}</lastmod>')
        xml_content.append('  </sitemap>')
    xml_content.append('</sitemapindex>')
    return HttpResponse('\n'.join(xml_content), content_type='application/xml')


def sitemap_categories_view(request):
    base_url = get_base_url(request)
    now = timezone.now().strftime('%Y-%m-%d')
    categories = Category.objects.all()

    xml = ['<?xml version="1.0" encoding="UTF-8"?>']
    xml.append('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    # Homepage
    xml.append(f'  <url><loc>{base_url}/</loc><lastmod>{now}</lastmod><changefreq>daily</changefreq><priority>1.0</priority></url>')
    for cat in categories:
        xml.append(f'  <url><loc>{base_url}/categories/{cat.slug}/</loc><lastmod>{now}</lastmod><changefreq>weekly</changefreq><priority>0.8</priority></url>')
    xml.append('</urlset>')
    return HttpResponse('\n'.join(xml), content_type='application/xml')


def sitemap_professions_view(request):
    base_url = get_base_url(request)
    now = timezone.now().strftime('%Y-%m-%d')
    xml = ['<?xml version="1.0" encoding="UTF-8"?>']
    xml.append('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    for prof_slug in PROFESSION_MAPPINGS.keys():
        xml.append(f'  <url><loc>{base_url}/profession/{prof_slug}/</loc><lastmod>{now}</lastmod><changefreq>weekly</changefreq><priority>0.8</priority></url>')
    xml.append('</urlset>')
    return HttpResponse('\n'.join(xml), content_type='application/xml')


def sitemap_professionals_view(request):
    base_url = get_base_url(request)
    now = timezone.now().strftime('%Y-%m-%d')
    pros = ProfessionalProfile.objects.filter(user__is_active=True).select_related('user')

    xml = ['<?xml version="1.0" encoding="UTF-8"?>']
    xml.append('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    for p in pros:
        xml.append(f'  <url><loc>{base_url}/professionals/{p.slug}/</loc><lastmod>{now}</lastmod><changefreq>weekly</changefreq><priority>0.7</priority></url>')
    xml.append('</urlset>')
    return HttpResponse('\n'.join(xml), content_type='application/xml')


def sitemap_locations_view(request):
    base_url = get_base_url(request)
    now = timezone.now().strftime('%Y-%m-%d')
    xml = ['<?xml version="1.0" encoding="UTF-8"?>']
    xml.append('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    # Country
    xml.append(f'  <url><loc>{base_url}/pakistan/</loc><lastmod>{now}</lastmod><changefreq>weekly</changefreq><priority>0.9</priority></url>')
    
    # Provinces
    for prov_slug in PROVINCES.keys():
        xml.append(f'  <url><loc>{base_url}/pakistan/{prov_slug}/</loc><lastmod>{now}</lastmod><changefreq>weekly</changefreq><priority>0.8</priority></url>')

    # Cities with registered professionals to prevent generating millions of thin pages
    active_cities = City.objects.filter(slug__in=CITY_TO_PROVINCE.keys())
    for city in active_cities:
        prov = CITY_TO_PROVINCE.get(city.slug, 'sindh')
        xml.append(f'  <url><loc>{base_url}/pakistan/{prov}/{city.slug}/</loc><lastmod>{now}</lastmod><changefreq>weekly</changefreq><priority>0.7</priority></url>')

    xml.append('</urlset>')
    return HttpResponse('\n'.join(xml), content_type='application/xml')


def sitemap_services_view(request):
    base_url = get_base_url(request)
    now = timezone.now().strftime('%Y-%m-%d')
    services = ServiceListing.objects.filter(is_active=True)

    xml = ['<?xml version="1.0" encoding="UTF-8"?>']
    xml.append('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    for s in services:
        xml.append(f'  <url><loc>{base_url}/services/{s.slug}/</loc><lastmod>{now}</lastmod><changefreq>weekly</changefreq><priority>0.8</priority></url>')
    xml.append('</urlset>')
    return HttpResponse('\n'.join(xml), content_type='application/xml')


# ==============================================================================
# ROBOTS.TXT & LLMS.TXT
# ==============================================================================

def robots_txt_view(request):
    base_url = get_base_url(request)
    lines = [
        "User-agent: *",
        "Allow: /",
        "Disallow: /admin/",
        "Disallow: /api/",
        "Disallow: /accounts/",
        "Disallow: /static/admin/",
        "",
        "# Explicitly allow legitimate AI & Search bots",
        "User-agent: Googlebot",
        "Allow: /",
        "",
        "User-agent: Bingbot",
        "Allow: /",
        "",
        "User-agent: OAI-SearchBot",
        "Allow: /",
        "",
        "User-agent: PerplexityBot",
        "Allow: /",
        "",
        f"Sitemap: {base_url}/sitemap.xml",
    ]
    return HttpResponse("\n".join(lines), content_type="text/plain; charset=utf-8")


def llms_txt_view(request):
    base_url = get_base_url(request)
    content = f"""# ProFinder — Find Trusted Professionals Near You

> ProFinder is Pakistan's premier local service marketplace directory connecting customers directly with verified doctors, electricians, plumbers, legal advocates, engineers, carpenters, and technical specialists across 99+ cities.

## Marketplace Architecture & Transparency
- Zero Platform Commission: Customers connect and arrange bookings directly without intermediary cuts.
- Direct Payments: All transactions are settled directly between customer and professional (Cash, Bank Transfer, JazzCash/Easypaisa).
- Verified Credentials: Each verified professional displays validated government ID, qualification certificates, and approved work portfolio samples.

## Core Navigation & Discovery Hubs
- Homepage: {base_url}/
- All Pakistan Locations: {base_url}/pakistan/
- Category Directory:
  - Doctors & Healthcare: {base_url}/categories/healthcare/
  - Electricians: {base_url}/categories/electricians/
  - Plumbers & Sanitary: {base_url}/categories/plumbers/
  - Engineers: {base_url}/categories/engineers/
  - Tutors & Education: {base_url}/categories/education/
  - Carpenters: {base_url}/categories/carpenters/
- Top Regional Portals:
  - Karachi: {base_url}/pakistan/sindh/karachi/
  - Lahore: {base_url}/pakistan/punjab/lahore/
  - Islamabad: {base_url}/pakistan/islamabad-capital-territory/islamabad/
  - Badin: {base_url}/pakistan/sindh/badin/
  - Hyderabad: {base_url}/pakistan/sindh/hyderabad/
- XML Sitemap: {base_url}/sitemap.xml
"""
    return HttpResponse(content.strip(), content_type="text/plain; charset=utf-8")
