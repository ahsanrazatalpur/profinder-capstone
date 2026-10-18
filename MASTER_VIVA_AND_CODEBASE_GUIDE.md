# ProFinder — Complete Master Viva & Codebase Defense Guide

> **Document Purpose:** Comprehensive Architectural Walkthrough, Codebase Guide, and University Viva Defense Manual.  
> **Target Audience:** Project Developers, University Evaluators, and Viva Examiners.  
> **Application:** ProFinder Marketplace (Cross-Platform Flutter Client + Django 6 REST / ASGI Backend).  
> **Date:** October 2026  

---

## Table of Contents

1. [Project Overview & Real-World Business Value](#1-project-overview--real-world-business-value)
   - Real-World Problem Statement
   - How ProFinder Solves It & Value Provided
   - Potential Risks, Drawbacks & Limitations
   - User & Professional Acquisition Strategy (Go-To-Market)
2. [Core Fundamentals & Viva Definitions](#2-core-fundamentals--viva-definitions)
   - Flutter vs. Dart
   - Python vs. Django vs. Django REST Framework
   - Essential Engineering Definitions (API, REST, JSON, JWT, WebSockets, ORM, etc.)
3. [Essential Commands Cheat-Sheet](#3-essential-commands-cheat-sheet)
   - Backend Terminal Guide (Virtual Environment, Migrations, Superuser, Server)
   - Frontend Terminal Guide (Pub, Run, Analyze, Test, APK Build)
4. [Frontend Architecture & Deep Dive (Flutter)](#4-frontend-architecture--deep-dive-flutter)
   - Total File Count & Directory Structure
   - Core Flutter Widgets, Classes & Functions (with Code Examples)
   - State Management with Provider Architecture
   - Complete End-to-End Frontend Request Flow
5. [Backend Architecture & Deep Dive (Django)](#5-backend-architecture--deep-dive-django)
   - Total File Count & 14 Micro-Apps Breakdown
   - Core Django & DRF Classes, Functions & Attributes (with Code Examples)
   - Database Concurrency, Locks & Security
   - Complete Request-Response Lifecycle
6. [External Cloud Services & Third-Party Integrations](#6-external-cloud-services--third-party-integrations)
7. [Top 15 University Viva Questions & Model Answers](#7-top-15-university-viva-questions--model-answers)

---

## 1. Project Overview & Real-World Business Value

---

### The Real-World Problem Statement

In Pakistan and many developing countries, the local professional services sector (healthcare, legal, engineering, education, and home repairs like electricians and plumbers) is completely **unorganized, informal, and fragmented**:

1. **No Centralized Verification:** If someone needs an emergency doctor, electrician, or lawyer at night, they rely on word-of-mouth or unverified local contacts. You cannot verify whether a doctor has a valid PMDC license or an electrician is competent.
2. **Arbitrary & Unfair Pricing (Price Gouging):** Service providers charge arbitrary rates based on customer appearance or desperation. There is zero price transparency.
3. **Safety & Trust Concerns:** Inviting unknown technicians into homes creates significant personal safety and security risks.
4. **Language & Geographic Barriers:** Most existing apps only work in English, alienating users who speak Urdu, Hindi, Arabic, or provincial dialects.

---

### How ProFinder Solves It & Value Provided

ProFinder is a full-stack, cross-platform digital marketplace that bridges customers with verified professionals:

- **Strict Multi-Stage Verification:** Professionals must submit their CNIC (National ID) and professional licenses/certifications. Administrators review and verify credentials before a profile receives the **Verified Badge (✅)**.
- **Fixed & Transparent Hourly Rates:** Every professional’s rate is displayed upfront in the user's preferred currency.
- **AI-Powered Discovery & Symptom Matcher:** Customers do not need to know medical or legal terminology. A customer typing *"sar mein shadeed dard hai"* (severe headache) is automatically matched by the Google Gemini AI engine to a **Neurologist / General Physician**.
- **Real-Time Live Chat & Voice Messaging:** Built-in WebSocket communication allows clients and professionals to negotiate details, share voice notes, and send photos before confirming an appointment.
- **Integrated Wallet & Escrow-Safe Payments:** Ensures professionals get paid for completed work while protecting customers against no-shows.

---

### Potential Risks, Drawbacks & Limitations

Being honest about system limitations demonstrates engineering maturity during a viva:

1. **Internet Dependency:** Both mobile client and backend require an active internet connection. Offline booking sync is not yet supported.
2. **Verification Bottleneck:** Manual admin verification of CNICs and degrees can create an onboarding backlog as the platform scales.
3. **Third-Party API Rate Limits:** Free AI quotas (e.g. Gemini 15 RPM) restrict automated translation throughput unless upgraded to enterprise billing.
4. **Dispute Management:** Subjective service quality (e.g., customer claims the electrician did not fix the problem properly) requires human mediation.

---

### User & Professional Acquisition Strategy (Go-To-Market)

How do you solve the **"Chicken-and-Egg"** marketplace problem (no customers without professionals, and no professionals without customers)?

1. **Supply-First Strategy (Acquiring Professionals):**
   - Onboard service providers first before launching marketing campaigns.
   - Partner with vocational training institutes (NAVTTC, TEVTA), bar associations, and medical universities.
   - Offer **Free Premium Subscriptions (0% platform commission)** for the first 6 months to early-adopter professionals.
2. **Demand-Side Strategy (Acquiring Customers):**
   - Target residential societies, universities, and commercial offices with hyper-local promotions.
   - Provide referral incentives (e.g., Rs. 500 discount coupon on first booking).
   - Use Google Play Store ASO (App Store Optimization) with multilingual search keywords.

---

## 2. Core Fundamentals & Viva Definitions

---

### Flutter vs. Dart

| Concept | Dart | Flutter |
|---|---|---|
| **What is it?** | An object-oriented, strongly-typed programming language developed by Google. | An open-source cross-platform UI framework and software development kit (SDK) built on top of Dart. |
| **Role in ProFinder** | Handles logic, data structures, asynchronous operations (`Future`, `Stream`), mathematical calculations, and API models. | Provides the visual widgets, animations, layout engines, gestures, navigation, and theme rendering across Android, iOS, and Web. |
| **Analogy** | **Dart is the engine and fuel** of the car. | **Flutter is the car body, steering wheel, seats, and dashboard.** |

---

### Python vs. Django vs. Django REST Framework (DRF)

| Concept | Python | Django | Django REST Framework (DRF) |
|---|---|---|---|
| **Definition** | High-level, interpreted programming language known for readability and vast ecosystem. | Full-stack web framework following the "batteries-included" philosophy (ORM, admin, auth built-in). | A specialized toolkit built on top of Django designed specifically to build RESTful Web APIs. |
| **Role in ProFinder** | Executes backend scripts, data models, and server algorithms. | Manages database tables, password hashing, admin dashboard, user authentication, and middleware. | Serializes database models into JSON format, validates incoming mobile app requests, and issues JWT tokens. |

---

### Core Engineering Definitions Cheat-Sheet

#### 1. What is an API (Application Programming Interface)?
A standardized bridge that allows two software programs to communicate. The Flutter mobile app does not access the database directly; it sends an HTTP request to the Django API, and Django queries the database and sends back JSON data.

#### 2. What is REST (Representational State Transfer)?
An architectural style for APIs based on stateless client-server communication using standard HTTP methods:
- **`GET`**: Retrieve data from server (e.g., `GET /api/search/professionals/`).
- **`POST`**: Create new resource (e.g., `POST /api/bookings/`).
- **`PUT` / `PATCH`**: Update existing resource (`PATCH /api/users/me/`).
- **`DELETE`**: Remove resource (`DELETE /api/bookings/5/`).

#### 3. What is JSON (JavaScript Object Notation)?
A lightweight, human-readable text format for transmitting structured data between server and client:
```json
{
  "id": 14,
  "name": "Dr. Ahmed Khan",
  "category": "Doctor",
  "hourly_rate": "2500.00",
  "is_verified": true
}
```

#### 4. What is JWT (JSON Web Token)?
A compact, cryptographically signed token used for stateless authentication:
- **Access Token:** Short-lived token (60 minutes in ProFinder) sent in the HTTP `Authorization: Bearer <token>` header with every request.
- **Refresh Token:** Long-lived token (7 days in ProFinder) stored securely on the mobile device, used to request a new access token when the current one expires without forcing the user to log in again.

#### 5. What are WebSockets & ASGI vs. WSGI?
- **WSGI (Web Server Gateway Interface):** Synchronous HTTP standard. Works on a request-response cycle (client asks -> server answers -> connection closes). Cannot maintain persistent two-way communication.
- **ASGI (Asynchronous Server Gateway Interface):** Modern asynchronous standard used by **Django Channels** and **Daphne** in ProFinder.
- **WebSockets:** A persistent, bi-directional full-duplex TCP connection. Both client and server can send messages instantly without polling. Powers ProFinder's **real-time chat**.

#### 6. What is State Management?
The mechanism of tracking, updating, and synchronizing application data across different screens (e.g., when a user logs in, their profile info, notifications count, and cart/bookings must update everywhere in the app simultaneously). ProFinder uses the **Provider** pattern.

#### 7. What is an ORM (Object-Relational Mapping)?
A tool in Django that allows developers to interact with the database using Python objects and classes instead of writing raw SQL:
```python
# Raw SQL:
# SELECT * FROM users_user WHERE email = 'customer@profinder.com';

# Django ORM:
user = User.objects.get(email='customer@profinder.com')
```

#### 8. What are Migrations?
Django’s way of propagating changes made to Python models (like adding a new field or table) into the database schema safely, keeping a version-controlled history of database changes.

---

## 3. Essential Commands Cheat-Sheet

---

### Backend Commands (Django & Python)

#### 1. How to Create and Activate a Virtual Environment (`venv`):
```bash
# Navigate to backend directory
cd backend

# Create isolated virtual environment named 'venv'
python -m venv venv

# Activate on Windows (PowerShell / Command Prompt):
venv\Scripts\activate

# Activate on Linux / macOS:
source venv/bin/activate
```
*(When active, you will see `(venv)` prefixed on your terminal line).*

#### 2. Install Dependencies:
```bash
pip install -r requirements.txt
```

#### 3. Database Migration Steps:
```bash
# 1. Detect model changes and generate migration files:
python manage.py makemigrations

# 2. Apply migrations to the database:
python manage.py migrate
```

#### 4. How to Create a Superuser (Admin Account):
```bash
python manage.py createsuperuser
```
Terminal prompt walkthrough:
```
Email address: admin@profinder.com
Name: Super Admin
Role: admin
Password: **********
Password (again): **********
Superuser created successfully.
```

#### 5. Run the Local Backend Server:
```bash
python manage.py runserver
```
*(Runs at `http://127.0.0.1:8000/api/`)*

#### 6. Rebuild Search Index:
```bash
python manage.py build_search_index
```

#### 7. Run Full Automated Backend Test Suite:
```bash
python manage.py test apps.payments apps.bookings apps.reviews apps.messaging apps.notifications apps.search apps.ai_engine.tests_translation
```

---

### Frontend Commands (Flutter & Dart)

```bash
# Navigate to flutter project
cd frontend/profinder_app

# 1. Download and link all packages listed in pubspec.yaml:
flutter pub get

# 2. Run static code analyzer to ensure 0 errors and 0 warnings:
flutter analyze

# 3. Run all 136 automated unit & widget tests:
flutter test

# 4. Launch app on connected device, emulator, or Chrome:
flutter run

# 5. Build production Android APK:
flutter build apk --release
# (Output file: build/app/outputs/flutter-apk/app-release.apk)
```

---

## 4. Frontend Architecture & Deep Dive (Flutter)

---

### Total File Count & Directory Structure

The Flutter application (`frontend/profinder_app/lib/`) consists of **273 Dart source files** organized into a **Feature-First Architecture**:

```
lib/
├── app/                  # 3 files   (App routes, route guards, auth navigation gates)
├── core/                 # 31 files  (API constants, Dio network client, theme tokens, localization helpers)
├── shared/               # 16 files  (Universal widgets: headers, category cards, buttons, banners)
├── services/             # 20 files  (Global application services: audio, push notifications, storage)
├── l10n/                 # 7 files   (Multi-language ARB localization files: en, ur, ar, es, fr, hi)
│
└── features/             # 194 files (Modular business features)
    ├── admin/            # 53 files  (Admin dashboard, user bans, portfolio approvals, moderation, ticket inbox)
    ├── chat/             # 29 files  (WebSockets, live messaging, voice recorder, audio player, attachments)
    ├── support/          # 24 files  (Help center articles, FAQs, ticket creation and thread replies)
    ├── professional/     # 21 files  (Professional dashboard, bookings manager, earnings, portfolio editor)
    ├── auth/             # 11 files  (Login, registration, forgot password, OTP verification)
    ├── profile/          # 11 files  (User profile, edit profile, language switcher, change password)
    ├── subscription/     # 9 files   (Plan cards, feature comparison, upgrade payment modal)
    ├── trust_safety/     # 7 files   (User reports, penalty appeals, policy guidelines)
    ├── home/             # 6 files   (Role-specific home screens: Customer, Guest, Professional)
    ├── magazine/         # 5 files   (Tips & articles feed, magazine detail screen)
    ├── bookings/         # 4 files   (Booking wizard, date/time picker, cancellation modal)
    ├── about/            # 4 files   (About us, terms of service, privacy policy)
    ├── settings/         # 3 files   (Notification preferences, theme mode toggle)
    ├── search/           # 2 files   (Advanced filter screen, search bar)
    ├── payments/         # 2 files   (Wallet transactions, payout requests)
    ├── notifications/    # 2 files   (Notifications feed screen, notification card)
    └── onboarding/       # 1 file    (Intro walkthrough slides)
```

---

### Core Flutter Widgets, Classes & Functions

#### 1. `StatelessWidget` vs. `StatefulWidget`
- **`StatelessWidget`**: Immutable widget whose UI depends solely on configuration passed through its constructor. Does not change dynamically over time (e.g., `CategoryCard`, `UniversalAppBar`).
- **`StatefulWidget`**: Mutable widget that maintains a dedicated `State` object across its lifecycle. Redraws whenever `setState()` is called (e.g., `ChatScreen`, `BookingScreen`).

#### StatefulWidget Lifecycle Methods:
- **`initState()`**: Called exactly once when the widget is inserted into the tree. Ideal for initializing controllers, animation tickers, or triggering initial data fetch.
- **`didChangeDependencies()`**: Called immediately after `initState()` and whenever an inherited dependency (like Theme or Locale) changes.
- **`build(BuildContext context)`**: Describes the visual UI hierarchy. Called frequently whenever state changes.
- **`dispose()`**: Called when the widget is permanently removed from the tree. **Crucial for memory management** (must dispose `TextEditingController`, `AnimationController`, and stream subscriptions to prevent memory leaks).

```dart
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); // Prevents memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Professionals')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(controller: _searchCtrl),
      ),
    );
  }
}
```

---

### State Management with Provider Architecture

ProFinder uses **Provider** (`ChangeNotifier`, `Consumer`, `context.watch`, `context.read`):

1. **`ChangeNotifier`**: A class that encapsulates data and business logic. When data changes, calling `notifyListeners()` tells all listening widgets to rebuild.
2. **`context.watch<T>()`**: Listens to changes in `T`. When `T` calls `notifyListeners()`, the widget calling `watch` is automatically rebuilt with fresh data.
3. **`context.read<T>()`**: Reads `T` once without listening. Ideal for button click callbacks (`onPressed`) to trigger methods without triggering unnecessary widget rebuilds.
4. **`Consumer<T>`**: Rebuilds only a specific granular subtree when `T` updates, optimizing rendering performance.

```dart
// 1. Provider Class
class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> fetchBookings() async {
    _isLoading = true;
    notifyListeners(); // Shows spinner

    try {
      _bookings = await bookingRepository.getMyBookings();
    } finally {
      _isLoading = false;
      notifyListeners(); // Hides spinner and shows data
    }
  }
}

// 2. UI Consumption
Widget build(BuildContext context) {
  // context.watch listens for changes
  final provider = context.watch<BookingProvider>();

  if (provider.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  return ListView.builder(
    itemCount: provider.bookings.length,
    itemBuilder: (context, index) => BookingTile(booking: provider.bookings[index]),
  );
}
```

---

### Complete End-to-End Frontend Request Flow

```
[User Action] (e.g. Taps "Confirm Booking" button)
       │
       ▼
[UI Layer: BookingScreen]
  - Form validation: formKey.currentState!.validate()
  - Calls: context.read<BookingProvider>().createBooking(...)
       │
       ▼
[State Layer: BookingProvider]
  - Sets isLoading = true -> notifyListeners() (UI shows loading indicator)
  - Invokes BookingRepository.createBooking(payload)
       │
       ▼
[Data Layer: BookingRemoteDataSource]
  - Prepares JSON payload with selected date, time, and professional ID
  - Calls DioClient.post('/api/bookings/', data: payload)
       │
       ▼
[Network Layer: Dio Interceptor]
  - Reads stored Access Token from SharedPreferences
  - Injects 'Authorization: Bearer <token>' header
  - Injects 'X-App-Language: ur' (Active locale header)
  - Transmits HTTPS POST request over the wire
       │
       ▼
[Response Handled]
  - If 201 Created: Converts JSON map into BookingModel
  - Provider adds new booking to local list -> notifyListeners()
  - UI displays success SnackBar and navigates to BookingSuccessScreen
```

---

## 5. Backend Architecture & Deep Dive (Django)

---

### Total File Count & 14 Micro-Apps Breakdown

The backend codebase contains **261 Python files** organized into 14 distinct micro-apps plus the core configuration folder:

| App Name | File Count | Core Purpose |
|---|:---:|---|
| **`profinder/`** | 5 files | Root settings, WSGI, ASGI, root URL routing, and middleware config |
| **`admin_panel`** | 27 files | Audit trail logs, promo banners, user bans, and Trust & Safety moderation |
| **`support`** | 26 files | Help articles, FAQ categories, user support tickets, and admin response threads |
| **`search`** | 24 files | Search engine, strict category isolation, phonetic aliases, and indexing commands |
| **`ai_engine`** | 24 files | Gemini recommendation engine, symptom matcher, and translation cache |
| **`profiles`** | 23 files | User profiles, professional portfolios, verification files, and profile views |
| **`messaging`** | 21 files | WebSockets ASGI consumer, live chat messages, and voice notes |
| **`users`** | 19 files | Custom user model, JWT auth, role enforcement, and Brevo password resets |
| **`payments`** | 17 files | PayPal order capture, wallet balances, withdrawal concurrency, and exchange rates |
| **`subscriptions`**| 15 files | Subscription plans, billing cycles, dynamic feature limits, and quotas |
| **`notifications`**| 14 files | In-app notification feed, preferences, and Firebase FCM push dispatcher |
| **`bookings`** | 13 files | Appointment scheduling, slot double-booking guards, and status lifecycle |
| **`articles`** | 13 files | Professional magazine, knowledge articles, and read counters |
| **`reviews`** | 12 files | 1-to-5 star verified reviews, comments, and rating recalculation |
| **`about_page`** | 12 files | Platform about content, contact inquiries, and policy pages |

---

### Core Django & DRF Classes, Functions & Attributes

#### 1. Models & Database Fields
```python
class Booking(models.Model):
    # Foreign keys establish relational connections to User
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='customer_bookings')
    professional = models.ForeignKey(User, on_delete=models.CASCADE, related_name='pro_bookings')
    
    date = models.DateField()
    time = models.TimeField()
    status = models.CharField(max_length=20, default='pending')
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-time']
        # Composite indexes for rapid database search:
        indexes = [
            models.Index(fields=['professional', 'date', 'time']),
        ]
```

- **`ForeignKey`**: Links a record to another table (Many-to-One).
- **`on_delete=models.CASCADE`**: If the user is deleted, their associated bookings are deleted.
- **`related_name`**: Allows reverse lookup (e.g., `user.customer_bookings.all()`).
- **`class Meta`**: Contains model metadata like table ordering and composite indexes.

---

#### 2. Serializers (Data Validation & JSON Transformation)
```python
class BookingSerializer(serializers.ModelSerializer):
    customer_name = serializers.ReadOnlyField(source='customer.name')

    class Meta:
        model = Booking
        fields = ['id', 'customer', 'customer_name', 'professional', 'date', 'time', 'status']

    def validate(self, attrs):
        # Custom business validation
        if attrs['date'] < datetime.date.today():
            raise serializers.ValidationError("Booking date cannot be in the past.")
        return attrs
```

---

#### 3. Database Concurrency & Race-Condition Protection

**Crucial Viva Point:** What happens if two customers attempt to book the exact same professional for the exact same hour simultaneously?

ProFinder uses **`transaction.atomic()`** and **`select_for_update()`**:
```python
from django.db import transaction

@transaction.atomic
def create_booking(request):
    # Locks the professional record so no concurrent thread can modify slots
    pro = ProfessionalProfile.objects.select_for_update().get(id=pro_id)
    
    # Check if slot is already occupied
    if Booking.objects.filter(professional=pro.user, date=slot_date, time=slot_time, status='accepted').exists():
        raise ValidationError("This time slot has already been booked by another user.")
        
    booking = Booking.objects.create(...)
    return booking
```
- **`select_for_update()`**: Acquires an exclusive database lock on the matching row until the transaction commits, preventing double-booking and wallet overdrafts.

---

### Complete Request-Response Lifecycle in Backend

```
[Incoming HTTP Request from Mobile Client]
       │
       ▼
[Web Server (Daphne / WSGI)]
  - Evaluates HTTP headers, SSL, and request path
       │
       ▼
[Django Middleware Pipeline (settings.py)]
  1. SecurityMiddleware & CorsMiddleware (Validates allowed origins)
  2. ContentLocalizationMiddleware (Reads 'X-App-Language' header)
  3. AuthenticationMiddleware (Resolves JWT token to request.user)
       │
       ▼
[URL Routing Table (profinder/urls.py -> apps/bookings/urls.py)]
  - Matches '/api/bookings/' to BookingViewSet or BookingListCreateView
       │
       ▼
[API View Controller]
  - Checks permission_classes = [IsAuthenticated]
  - Checks ScopedRateThrottle (Protects against automated spam/flooding)
       │
       ▼
[Serializer & ORM Execution]
  - Serializer validates incoming JSON body
  - Django ORM executes SQL query on PostgreSQL/SQLite
       │
       ▼
[HTTP Response Output]
  - Serializer transforms database model instances into JSON dictionary
  - View wraps data in DRF Response(serializer.data, status=201)
  - ContentLocalizationMiddleware translates dynamic text if needed
  - 201 Created JSON response returned to mobile client
```

---

## 6. External Cloud Services & Third-Party Integrations

| Service | Protocol / SDK | What ProFinder Uses It For |
|---|---|---|
| **Cloudinary** | `cloudinary_storage` | Cloud storage for user profile photos, high-resolution portfolio images, legal CNIC verification docs, and chat attachments. |
| **Firebase Cloud Messaging (FCM)** | `firebase-admin` | Real-time mobile push notification alerts for booking status updates, instant messages, and administrative warnings. |
| **Google Gemini AI** | `google-genai` | Natural language search matching, symptom-based doctor recommendations, and automated 5-language dynamic translation. |
| **Brevo (Sendinblue)** | HTTP API / SMTP | Automated transactional emails, password reset OTP links, and official administrative notifications. |
| **PayPal REST API** | HTTPS REST | Escrow-safe booking payments, subscription plan upgrades, and professional wallet payouts. |
| **Open ER-API** | HTTP GET | Provides real-time currency conversion baseline (cached for 12 hours) so users view rates in PKR, USD, AED, etc. |

---

## 7. Top 15 University Viva Questions & Model Answers

### Q1: Why did you choose Flutter instead of React Native or Native Android?
> **Answer:** "Flutter compiles directly to native ARM machine code using the Skia/Impeller graphics engine, providing 60–120 FPS performance without requiring a JavaScript bridge like React Native. Furthermore, Flutter’s single codebase allowed us to build identical responsive experiences for Android, iOS, and Web while maintaining full RTL (Right-to-Left) support for Urdu and Arabic out of the box."

---

### Q2: Why did you choose Django and DRF for the backend?
> **Answer:** "Django offers a mature, secure, 'batteries-included' architecture. It provides built-in protection against SQL injection, Cross-Site Scripting (XSS), and CSRF attacks. With Django REST Framework, we achieved clean separation between our data models, business logic, and API serialization. Additionally, Django Channels enabled us to seamlessly handle both standard REST APIs and real-time WebSockets on a unified backend."

---

### Q3: How does the AI Symptom Search work?
> **Answer:** "When a customer searches using everyday language or symptoms (e.g., *'bukhar aur jism dard'* or *'chest pain'*), our `apps.ai_engine` passes the query to Google Gemini Flash with strict prompt-engineered classification constraints. Gemini identifies the primary medical concern and maps it directly to the appropriate professional specialty (e.g., General Physician or Cardiologist), which our backend search engine then uses to filter verified doctors."

---

### Q4: How is user password security handled?
> **Answer:** "Passwords are never stored in plain text. Django uses the **PBKDF2 (Password-Based Key Derivation Function 2)** algorithm with a **SHA-256** hash and a unique cryptographic salt per user. This ensures resistance against rainbow table attacks and brute-force cracking."

---

### Q5: How do you prevent double-booking of professionals?
> **Answer:** "We enforce concurrency control at the database level using `transaction.atomic()` and `select_for_update()`. When a customer initiates a booking, the professional's slot is exclusively locked during transaction execution. If a matching accepted booking exists for that date and time, the transaction aborts and returns an HTTP 400 error."

---

### Q6: What is the difference between Access Tokens and Refresh Tokens?
> **Answer:** "An access token is short-lived (60 minutes) to minimize damage if intercepted. A refresh token is long-lived (7 days) and is stored securely on the mobile device. When the access token expires, the app silently calls `/api/users/token/refresh/` using the refresh token to receive a new access token without disrupting the user."

---

### Q7: How does real-time chat function?
> **Answer:** "Real-time chat is powered by WebSockets via Django Channels and Daphne ASGI server. When a user opens a conversation, a WebSocket connection is established. When a message is sent, the `ChatConsumer` validates the sender, persists the message to the database, and broadcasts the event across the conversation channel layer so the recipient receives it instantly with zero latency."

---

### Q8: What is the purpose of `dispose()` in Flutter?
> **Answer:** "`dispose()` is called when a State object is permanently removed from the widget tree. We use it to unregister stream listeners, cancel timers, and dispose `TextEditingController` and `AnimationController` instances. If controllers are not disposed, they remain in memory and cause memory leaks."

---

### Q9: Why do you need both WSGI and ASGI files in your backend?
> **Answer:** "WSGI (`wsgi.py`) handles standard synchronous HTTP requests (GET, POST) for our REST API. ASGI (`asgi.py`) handles asynchronous, long-lived connections required for WebSockets in our real-time messaging system."

---

### Q10: How do you support multiple languages and RTL layout?
> **Answer:** "Static UI strings are handled via Flutter's `.arb` localization files (English, Urdu, Arabic, Spanish, French, Hindi), with the framework automatically flipping the layout direction to RTL for Urdu and Arabic. Dynamic database content (such as bios and reviews) is translated on the backend by our AI localization service and cached permanently in the `LocalizedText` model."

---

### Q11: What is the difference between `context.watch()` and `context.read()`?
> **Answer:** "`context.watch<T>()` subscribes the widget to changes in provider `T`, causing the widget to rebuild whenever `notifyListeners()` is called. `context.read<T>()` retrieves the provider instance once without subscribing, which is used inside event handlers like button `onPressed` callbacks to avoid unnecessary widget rebuilds."

---

### Q12: How are files and media stored?
> **Answer:** "Uploaded images (profile photos, portfolio work, ID documents) are not stored directly on the web server disk. They are uploaded to Cloudinary's cloud storage via `django-cloudinary-storage`, and only the secure HTTPS URL is stored in the database."

---

### Q13: What happens if an API call fails due to network outage?
> **Answer:** "Our frontend Dio network client uses global error interceptors that catch socket exceptions, timeouts, and HTTP errors. These errors are mapped into user-friendly `ApiException` messages and displayed on the UI via non-intrusive snackbars or retry banners rather than crashing the application."

---

### Q14: What is the role of the `apps/admin_panel`?
> **Answer:** "The admin panel serves as the platform's governance engine. It manages professional identity verification, handles user report investigations and account bans, reviews penalty appeals, and logs an immutable audit trail (`AdminLog`) of every administrative action for accountability."

---

### Q15: How does ProFinder handle multi-currency display?
> **Answer:** "Every professional enters their fee in their local currency. When a customer views a profile, our frontend and backend exchange rate engine converts the amount to the customer's preferred currency using live exchange rates cached from the Open Exchange Rates API."
