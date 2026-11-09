from django.test import TestCase, Client
from django.urls import reverse
from apps.search.models import Category
from apps.profiles.models import ProfessionalProfile
from apps.admin_panel.models import City
from apps.seo_web.models import ServiceListing, SlugRedirect


class SEOWebTestCase(TestCase):
    def setUp(self):
        self.client = Client()

    def test_homepage(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "ProFinder | Find Trusted Professionals in Pakistan")
        self.assertContains(response, 'rel="canonical"')
        self.assertContains(response, 'application/ld+json')
        self.assertContains(response, 'WebSite')
        self.assertContains(response, 'Organization')
        self.assertContains(response, 'ProFinder does NOT process in-app customer payments')

    def test_category_page(self):
        cat = Category.objects.first()
        if cat:
            response = self.client.get(f'/categories/{cat.slug}/')
            self.assertEqual(response.status_code, 200)
            self.assertContains(response, cat.name)
            self.assertContains(response, 'BreadcrumbList')
            self.assertContains(response, 'ItemList')

    def test_profession_page(self):
        response = self.client.get('/profession/doctors/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Doctors")

    def test_professional_detail_page(self):
        pro = ProfessionalProfile.objects.filter(user__is_active=True).first()
        if pro:
            response = self.client.get(f'/professionals/{pro.slug}/')
            self.assertEqual(response.status_code, 200)
            self.assertContains(response, pro.user.name)
            self.assertContains(response, 'Person')

    def test_service_detail_page(self):
        service = ServiceListing.objects.first()
        if service:
            response = self.client.get(f'/services/{service.slug}/')
            self.assertEqual(response.status_code, 200)
            self.assertContains(response, service.title)
            self.assertContains(response, 'Service')

    def test_country_page(self):
        response = self.client.get('/pakistan/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Pakistan")

    def test_province_page(self):
        response = self.client.get('/pakistan/sindh/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Sindh")

    def test_city_page(self):
        city = City.objects.filter(slug='badin').first()
        if city:
            response = self.client.get('/pakistan/sindh/badin/')
            self.assertEqual(response.status_code, 200)
            self.assertContains(response, "Badin")

    def test_city_category_page(self):
        cat = Category.objects.first()
        city = City.objects.filter(slug='badin').first()
        if cat and city:
            response = self.client.get(f'/pakistan/sindh/badin/{cat.slug}/')
            self.assertEqual(response.status_code, 200)
            self.assertContains(response, cat.name)

    def test_search_page(self):
        response = self.client.get('/search/?q=doctor')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Results Directory")

    def test_robots_txt(self):
        response = self.client.get('/robots.txt')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Content-Type'], 'text/plain; charset=utf-8')
        self.assertContains(response, 'Disallow: /admin/')
        self.assertContains(response, 'Sitemap:')

    def test_llms_txt(self):
        response = self.client.get('/llms.txt')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Content-Type'], 'text/plain; charset=utf-8')
        self.assertContains(response, '# ProFinder')

    def test_sitemap_index(self):
        response = self.client.get('/sitemap.xml')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Content-Type'], 'application/xml')
        self.assertContains(response, '<sitemapindex')
        self.assertContains(response, '/sitemap-categories.xml')

    def test_slug_redirect_middleware(self):
        SlugRedirect.objects.create(
            old_path='/professionals/old-slug-123/',
            new_path='/professionals/new-slug-456/',
            status_code=301
        )
        response = self.client.get('/professionals/old-slug-123/')
        self.assertEqual(response.status_code, 301)
        self.assertEqual(response['Location'], '/professionals/new-slug-456/')

    def test_nonexistent_returns_404(self):
        response = self.client.get('/categories/non-existent-category-slug-xyz/')
        self.assertEqual(response.status_code, 404)
