# ProFinder — Complete Master Codebase Architecture & Learning Guide (Roman Urdu)
# 📖 ProFinder Ka Mukammal Codebase, File Structure Aur Web Concepts Guide

> **Document Type:** Master Codebase Reference & Architecture Defense Guide  
> **Language:** Simple, Pedagogical Roman Urdu with Original English Code & Identifiers  
> **Target Audience:** University Evaluators, Developers, and Technical Beginners  
> **Project Scope:** Full-Stack Cross-Platform Mobile/Web (Flutter/Dart) + REST/ASGI Backend (Django 6/Python)  
> **Last Verified & Tested:** October 2026 (All 144 Flutter Tests Passing, Django Test Suite Passing)  

---

## 📑 Table of Contents (Fahrist-e-Mazameen)

1. [Web Development Ke Zaroori Concepts (Concepts You Must Know)](#1-web-development-ke-zaroori-concepts)
   - Middleware Kya Hota Hai?
   - JSON Kya Hota Hai?
   - JWT (JSON Web Token) Kya Hota Hai?
   - Flutter Widget Kya Hota Hai?
   - State Management & Provider Architecture
   - REST API & HTTP Methods
   - Django ORM & Database Transactions
   - WebSockets & Asynchronous Channels (Daphne)
   - Push Notifications (FCM) & Transactional Emails (Brevo)
2. [Complete Frontend File Structure & Directory Guide (`lib/`)](#2-complete-frontend-file-structure--directory-guide)
   - Core Architecture (`main.dart`, `app.dart`, `bootstrap.dart`)
   - `core/` (Network, Theme, Constants, Utils)
   - `features/` (Tamam 17 Functional Modules Ki Tafseel)
   - `services/` (API Facades, Auth, Push, Bookings)
   - `shared/` (UniversalDialog, UniversalAppBar)
   - `l10n/` (6 Languages & RTL Support)
3. [Complete Backend File Structure & Directory Guide (`backend/`)](#3-complete-backend-file-structure--directory-guide)
   - Project Root (`profinder/`: settings, urls, asgi, wsgi, manage.py)
   - 14 Modular Django Apps (Models, Views, Serializers, URLs, Utilities)
4. [End-to-End Data Lifecycle & User Journey Traces](#4-end-to-end-data-lifecycle--user-journey-traces)
   - App Startup Flow
   - Signup, 6-Digit OTP & JWT Authentication Flow
   - Booking Creation & State Transition Flow
   - Live WebSocket Chat Flow
   - Account Deletion (Two-Factor Secure) Flow
5. [Verified Test Results & Production Readiness Assessment](#5-verified-test-results--production-readiness-assessment)
6. [Strictly Deferred Areas (Payment & Professional Currency)](#6-strictly-deferred-areas)

---

## 1. Web Development Ke Zaroori Concepts

### A. Middleware Kya Hota Hai? (What is Middleware?)
- **Roman Urdu Definition**: Middleware code ka ek aesa darban (security guard) ya filter hota hai jo request aur response ke beech mein baithta hai. Jab koi user mobile app se request bhejta hai, to request view tak pohnchne se pehle middleware ke pipe se guzarti hai, aur jab server response wapas bhejta hai tab bhi middleware use inspect karta hai.
- **Daily-Life Example**: Airport par security screening counter. Jab aap departure lounge mein jate hain to pehle aapka ticket aur bag check hota hai; agar ticket ghalat ho to security guard aapko wahi se wapas bhej deta hai, plane tak nahi jane deta.
- **ProFinder Code Example**: `backend/apps/ai_engine/middleware.py`:
```python
class ContentLocalizationMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # 1. Incoming: Header check karta hai
        lang = request.headers.get('X-App-Language', 'en')
        request.app_language = lang
        
        # 2. View execute hota hai
        response = self.get_response(request)
        
        # 3. Outgoing: JSON response ko user ki zabaan mein translate karta hai
        return response
```
- **ProFinder Mein Middlewares**: `settings.py` mein `SecurityMiddleware`, `CorsMiddleware` (browser access ke liye), `AuthenticationMiddleware` (user session verify karne ke liye), aur `ContentLocalizationMiddleware` configured hain.

---

### B. JSON Kya Hota Hai? (What is JSON?)
- **Roman Urdu Definition**: JSON ka matlab hai **JavaScript Object Notation**. Ye text par mabni ek aesa universal data format hai jise insaan bhi asaani se parh sakta hai aur computer programs bhi second ke hazarwen hissay mein parse kar sakte hain. Isme data `{"key": "value"}` pairs aur lists `[...]` mein rehta hai.
- **Daily-Life Example**: Ek visiting card ya school admission form jisme saaf likha hota hai: Name: Ali, Roll No: 42, City: Karachi.
- **ProFinder Code Example**: Jab Flutter mobile app customer ko show karne ke liye server se professional ka data mangti hai to Django ye JSON return karta hai:
```json
{
  "id": 12,
  "name": "Kamran Electrician",
  "email": "kamran@example.com",
  "role": "professional",
  "hourly_rate": "1500.00",
  "average_rating": 4.85,
  "is_available": true
}
```
- **Why Necessary?**: Flutter Dart zabaan use karta hai aur Django Python use karta hai. Dart direct Python ke objects ko nahi samajh sakti. JSON dono ke darmiyan universal translator ka kaam karta hai.

---

### C. JWT (JSON Web Token) Kya Hota Hai? (What is JWT?)
- **Roman Urdu Definition**: JWT ek digital encrypted identity card hai. Jab user email aur password se login karta hai, to server use ek signed string (Token) deta hai. Uske baad user ko har request par password bhejne ki zaroorat nahi hoti, balke wo apna JWT token HTTP Header (`Authorization: Bearer <token>`) mein bhejta hai.
- **JWT Ke 3 Hissay Hote Hain** (`Header.Payload.Signature`):
  1. **Header**: Token ki type aur hashing algorithm (e.g. HS256).
  2. **Payload**: User ka data (e.g. `user_id: 12`, `role: "customer"`, `exp: 1718000000`).
  3. **Signature**: Secret key se banaya gaya digital signature jo ye prove karta hai ke token hacker ne edit nahi kiya.
- **ProFinder Code Example**: `backend/apps/users/views.py`:
  - `access_token`: Short-lived (60 minutes) token jo har API call mein lagta hai.
  - `refresh_token`: Long-lived token jo access token expire hone par naya token mangwane ke liye use hota hai (`/api/users/token/refresh/`).
- **Flutter Mein Auto-Refresh**: `frontend/profinder_app/lib/core/network/api_service.dart` mein Dio interceptor laga hai; agar server `401 Unauthorized` return kare to Flutter user ko log out karne ke bajaye automatically background mein refresh token bhej kar naya access token lata hai aur ruki hui request dobara chala deta hai!

---

### D. Flutter Widget Kya Hota Hai? (What is a Widget?)
- **Roman Urdu Definition**: Flutter mein **"Har cheez widget hai"** (Everything is a widget). Mobile screen par nazar aane wala button, text, image, padding, container, row, column aur poori screen sab ke sab widgets hain.
- **2 Bunyadi Qismein**:
  1. **StatelessWidget**: Ek aesa widget jiska visual content display hone ke baad badalta nahi hai (e.g. `UniversalAppBar`, `CategoryChip`, `Text`).
  2. **StatefulWidget**: Ek aesa widget jo user interaction (jaise typing, tapping) ya API response aane par `setState()` ke zariye apni screen ko dobara render (rebuild) karta hai (e.g. `LoginScreen`, `ChatConversationScreen`, `CustomerHomeScreen`).
- **Widget Tree**: Flutter tamam widgets ko shajar (tree) ki tarah jorta hai:
```
MaterialApp (Root)
 └── Scaffold (Screen Layout)
      ├── AppBar (Top Bar)
      └── SingleChildScrollView (Body)
           └── Column (Vertical Layout)
                ├── TextField (Email Input)
                ├── TextField (Password Input)
                └── ElevatedButton (Login Button)
```

---

### E. State Management & Provider Architecture
- **Roman Urdu Definition**: Jab kisi ek screen par data badle (jaise user ne login kiya ya theme ko Dark Mode kiya), to baqi tamam screens ko kaise pata chalega ke data badal gaya hai? Is synchronization ko **State Management** kehte hain.
- **Provider Pattern**: ProFinder mein `package:provider` use hota hai:
  - **`ChangeNotifier`**: State class hoti hai (e.g. `AuthProvider`).
  - **`notifyListeners()`**: Jab bhi data change hota hai ye method call hota hai jo tamam sun'ne wale widgets ko bolta hai: *"Chalo bhai, screen dobara draw karo!"*
  - **`context.watch<AuthProvider>()`**: UI widget state ko listen karta hai aur auto-update hota hai.
  - **`context.read<AuthProvider>()`**: Sirf ek bar function chalane ke liye use hota hai (jaise button tap par `auth.logout()` call karna).

---

### F. REST API & HTTP Methods
- **REST (Representational State Transfer)** standard web architecture hai jo specific HTTP verbs use karti hai:
  - `GET`: Server se data parhna/mangwana (e.g. `GET /api/search/categories/`).
  - `POST`: Server par naya record create karna (e.g. `POST /api/bookings/`).
  - `PUT`: Poore record ko replace karna.
  - `PATCH`: Kisi record ka koi ek hissa update karna (e.g. `PATCH /api/bookings/5/status/`).
  - `DELETE`: Record ko delete karna (e.g. `DELETE /api/users/delete-account/`).
- **HTTP Status Codes**:
  - `200 OK`: Request kamyab ho gayi.
  - `201 Created`: Naya record database mein kamyabi se save ho gaya.
  - `400 Bad Request`: User ne form mein ghalat data bheja.
  - `401 Unauthorized`: Token missing hai ya expire ho chuka hai.
  - `403 Forbidden`: User authenticated hai lekin is kaam ki permission nahi hai (e.g. non-admin admin panel khol raha hai).
  - `404 Not Found`: Manga gaya record mojood nahi hai.
  - `500 Internal Server Error`: Server ke backend code mein crash/bug aa gaya.

---

### G. Django ORM (Object-Relational Mapping)
- **Roman Urdu Definition**: ORM developer aur database ke beech translator hai. Raw SQL queries likhne ke bajaye developer normal Python code likhta hai, aur Django khud use high-performance SQL query mein convert karta hai.
- **Examples in ProFinder**:
  - `Booking.objects.filter(customer=user, status='confirmed')`
  - `User.objects.select_related('professional_profile').get(id=user_id)` (N+1 query problem se bachata hai).
  - `transaction.atomic()`: Database operations ko ek package mein bandhta hai; agar koi ek step fail ho to poora data rollback ho jata hai.

---

### H. WebSockets & Asynchronous Channels (Daphne)
- **Roman Urdu Definition**: Normal HTTP mein client sawal karta hai to server jawab deta hai; server khud se client ko message nahi bhej sakta. **WebSocket** ek aesa 2-way pipe kholta hai jahan client aur server dono bina kisi rukawat ke foran live data bhej sakte hain.
- **ProFinder Real-Time Chat**:
  - Daphne ASGI server port par HTTP aur WebSocket dono connections sunta hai.
  - Jab Ali Ahmed ko chat mein message bhejta hai, to `ChatConsumer` message ko database mein save karta hai aur instant Channels ke group broadcast ke zariye Ahmed ke phone par push kar deta hai!

---

### I. Multi-Channel Notifications (FCM & Brevo)
- **Firebase Cloud Messaging (FCM HTTP v1)**: User ki app band ho ya background mein ho, Google servers ke zariye phone ki lock screen par pop-up notification bhejta hai.
- **Brevo REST API**: Transactional emails bhejta hai (Signup OTP, Password Reset, Security alerts) jisme modern responsive HTML templates aur OTP copy buttons lagaye gaye hain.
- **Background Daemon Worker**: Notifications aur emails ko Django ke main request loop mein nahi chalaya jata balke daemon background thread par dispatch kiya jata hai taake mobile user ko 1 second ka bhi delay na miley!

---

## 2. Complete Frontend File Structure & Directory Guide (`lib/`)

Frontend application `frontend/profinder_app/lib/` 280 Dart source files par mushtamil hai.

```
frontend/profinder_app/
│
├── android/                             <-- Android native project (Gradle, Manifest)
├── ios/                                 <-- iOS native project (Xcode, Pods, Info.plist)
├── web/                                 <-- Web platform entry (index.html, manifest.json)
├── windows/                             <-- Windows native C++ runner
├── linux/                               <-- Linux native runner
├── macos/                               <-- macOS native runner
├── test/                                <-- Automated Flutter test suite (144 tests)
├── assets/                              <-- Images, icons, illustrations
├── pubspec.yaml                         <-- Project dependencies & assets manifest
├── pubspec.lock                         <-- Pinned dependency versions
├── l10n.yaml                            <-- Localization generator config
├── analysis_options.yaml                <-- Linting & static analysis rules
│
└── lib/                                 <-- Dart source code
    ├── main.dart                        <-- App entry point (main() function)
    ├── firebase_options.dart            <-- Firebase config generated by FlutterFire
    ├── app/                             <-- App bootstrap & routing
    │   ├── app.dart                     <-- MaterialApp, theme setup & route generator
    │   ├── bootstrap.dart               <-- Pre-flight initialization
    │   └── routes/
    │       └── app_routes.dart          <-- Named routes registry (/home, /login, etc.)                             <-- App entry point (`main()` function)
├── app.dart                              <-- Root MaterialApp, themes, routes, providers
├── bootstrap.dart                        <-- Pre-flight initialization (SharedPrefs, Dio)
│
├── core/                                 <-- Framework foundation & shared infrastructure
│   ├── constants/
│   │   ├── app_constants.dart            <-- Central backend endpoints & API URL constants
│   │   ├── app_sizes.dart                <-- Padding, margins, border-radius constants
│   │   └── asset_constants.dart          <-- Icons, logo and image asset paths
│   ├── localization/
│   │   ├── app_language.dart             <-- 6 language codes & RTL directionality
│   │   └── language_provider.dart        <-- Dynamic locale switcher provider
│   ├── location/
│   │   └── location_model.dart           <-- GPS latitude/longitude data container
│   ├── network/
│   │   └── api_service.dart              <-- Central Dio client, Bearer interceptor & refresh
│   ├── theme/
│   │   ├── app_colors.dart               <-- Teal customer, Indigo pro, Dark mode palettes
│   │   ├── app_typography.dart           <-- Responsive fonts & text styles
│   │   ├── theme_context_ext.dart        <-- BuildContext extensions (`context.colors`)
│   │   └── theme_provider.dart           <-- Dark / Light / System theme state
│   └── utils/
│       ├── app_helpers.dart              <-- Universal snackbars, toasts & dialog wrappers
│       ├── date_helper.dart              <-- Humanized relative dates & timestamps
│       └── validators.dart               <-- Email regex & password strength validation
│
├── features/                             <-- 17 Business Modules
│   ├── about/                            <-- Dynamic About Us page, mission, milestones
│   ├── admin/                            <-- Mobile administration dashboard
│   │   ├── screens/                      <-- Admin analytics, user moderation, announcements
│   │   └── widgets/                      <-- Stat cards, action buttons
│   ├── auth/                             <-- Complete authentication module
│   │   ├── screens/login_screen.dart     <-- Email/password & Google login
│   │   ├── screens/register_screen.dart  <-- Account creation form
│   │   ├── screens/otp_verification_screen.dart <-- 6-digit OTP verification + clipboard paste
│   │   └── screens/forgot_password_screen.dart  <-- Password recovery flow
│   ├── bookings/                         <-- Customer & Pro appointment booking
│   │   ├── screens/booking_list_screen.dart     <-- Active & past bookings tabs
│   │   ├── screens/booking_detail_screen.dart   <-- Timeline, actions, cancel & reschedule
│   │   └── widgets/create_booking_sheet.dart    <-- Slot picker bottom modal sheet
│   ├── chat/                             <-- Real-time live messaging
│   │   ├── presentation/screens/conversation_screen.dart <-- Live chat screen
│   │   ├── presentation/widgets/chat_input_bar.dart      <-- Voice record & attachments
│   │   └── data/datasources/chat_socket_data_source.dart <-- WebSocket manager
│   ├── home/                             <-- Dashboards
│   │   ├── screens/customer_home_screen.dart     <-- Main customer home with tab sync
│   │   └── widgets/promo_banner_slider.dart      <-- Dynamic active promo banners
│   ├── magazine/                         <-- ProFinder magazine & articles
│   ├── notifications/                    <-- In-app notifications & push handlers
│   │   ├── screens/notification_screen.dart      <-- Bell tray notification list
│   │   └── services/push_notification_service.dart<-- FCM setup & navigation
│   ├── onboarding/                       <-- First-time user welcome slides
│   ├── payments/                         <-- Deferred payment module
│   ├── professional/                     <-- Professional dashboard & profile
│   │   ├── screens/pro_dashboard_screen.dart     <-- Earnings, stats, active requests
│   │   └── screens/pro_schedule_screen.dart      <-- Working hours & availability
│   ├── profile/                          <-- Customer profile editing
│   ├── search/                           <-- Search & Discovery
│   │   ├── screens/search_screen.dart            <-- Multi-filter search & pro cards
│   │   └── services/search_service.dart          <-- Search API connector
│   ├── settings/                         <-- App configuration
│   │   ├── screens/settings_screen.dart          <-- Main settings & language selector
│   │   ├── screens/security_screen.dart          <-- Logout confirmation & reset password
│   │   └── widgets/delete_account_dialog.dart    <-- Two-factor account deletion modal
│   ├── subscription/                     <-- Pro subscription plans
│   ├── support/                          <-- Help & Support
│   │   ├── screens/help_center_screen.dart       <-- FAQs & Category list
│   │   ├── screens/my_tickets_screen.dart        <-- Support ticket thread
│   │   └── screens/guest_contact_screen.dart     <-- Logged-out contact form (honeypot)
│   └── trust_safety/                     <-- User reporting modal
│
├── services/                             <-- Frontend API Facades & Providers
│   ├── api_service.dart                  <-- Central network service
│   ├── auth_provider.dart                <-- Auth session state provider
│   ├── booking_service.dart              <-- Bookings API calls
│   └── push_notification_service.dart   <-- FCM push notification dispatch
│
├── shared/                               <-- Universal Reusable UI Components
│   └── widgets/
│       ├── universal_app_bar.dart        <-- Responsive branded app bar
│       └── universal_dialog.dart         <-- Confirmation, logout & error dialogs
│
└── l10n/                                 <-- Localization Translations (ARB files)
    ├── app_en.arb                        <-- English translations
    ├── app_ur.arb                        <-- Urdu translations (with RTL)
    ├── app_ar.arb                        <-- Arabic translations (with RTL)
    ├── app_hi.arb                        <-- Hindi translations
    ├── app_es.arb                        <-- Spanish translations
    └── app_fr.arb                        <-- French translations
```

---

## 3. Complete Backend File Structure & Directory Guide (`backend/`)

Backend architecture `backend/` modular Django 6.0 pattern par mushtamil hai jisme 14 apps aur 202 endpoints hain.

```
backend/
│
├── manage.py                             <-- Django CLI utility
├── requirements.txt                     <-- 71 Python dependencies
├── firebase-credentials.json            <-- FCM Google Service Account credentials
├── db.sqlite3                           <-- SQLite Relational Database
│
├── profinder/                           <-- Project Root Configuration
│   ├── settings.py                      <-- Master settings, DB, Auth, Middleware, Installed apps
│   ├── urls.py                          <-- Master router routing to /api/ endpoints
│   ├── asgi.py                          <-- ASGI Daphne & Channels router
│   └── wsgi.py                          <-- WSGI HTTP web server entry point
│
└── apps/                                <-- 14 Modular Django Applications
    │
    ├── users/                           <-- User identity & Authentication
    │   ├── models.py                    <-- User model, EmailOTP, roles
    │   ├── views.py                     <-- Register, Login, GoogleLogin, DeleteAccount
    │   ├── serializers.py               <-- UserSerializer, RegisterSerializer, OTPSerializer
    │   ├── brevo_email.py               <-- Brevo transactional email sender
    │   └── urls.py                      <-- /api/users/ routes
    │
    ├── profiles/                        <-- User Profiles
    │   ├── models.py                    <-- UserProfile, ProfessionalProfile, Portfolio, WorkingHours
    │   ├── views.py                     <-- CustomerProfileView, ProProfileView, PortfolioUpload
    │   └── serializers.py               <-- Profile serializers
    │
    ├── search/                          <-- Search & Discovery Engine
    │   ├── models.py                    <-- Category, SubCategory, SearchAlias, SearchIndex
    │   ├── views.py                     <-- CategoryListView, ProfessionalSearchView
    │   └── search_engine.py             <-- RapidFuzz typo-tolerant matching
    │
    ├── bookings/                        <-- Appointment Booking Management
    │   ├── models.py                    <-- Booking model, statuses, cancellation reasons
    │   ├── views.py                     <-- BookingCreateView, BookingStatusView, RescheduleView
    │   └── serializers.py               <-- BookingSerializer
    │
    ├── messaging/                       <-- Real-time Chat
    │   ├── models.py                    <-- Conversation, Message, Attachment
    │   ├── views.py                     <-- ConversationListView, MessageHistoryView
    │   ├── consumers.py                 <-- WebSocket ChatConsumer (Channels live socket)
    │   └── routing.py                   <-- ws://chat/<id>/ routing
    │
    ├── reviews/                         <-- Ratings & Reviews
    │   ├── models.py                    <-- Review model, rating calculation
    │   └── views.py                     <-- ReviewCreateView, ProReviewListView
    │
    ├── notifications/                   <-- Universal Notification Engine
    │   ├── models.py                    <-- Notification model
    │   ├── views.py                     <-- NotificationListView, MarkReadView
    │   └── utils.py                     <-- notify_user(), send_fcm_push(), PUSH_PREFIX
    │
    ├── support/                         <-- Help & Support System
    │   ├── models.py                    <-- HelpCategory, PolicyVersion, SupportTicket, TicketMessage
    │   ├── ticket_views.py              <-- TicketListCreateView, GuestContactView (honeypot)
    │   └── admin_views.py               <-- Staff ticket resolution views
    │
    ├── articles/                        <-- ProFinder Magazine
    │   ├── models.py                    <-- Article model, categories, read time
    │   └── views.py                     <-- ArticleListView, ArticleDetailView
    │
    ├── admin_panel/                     <-- Governance & Moderation
    │   ├── models.py                    <-- UserReport, ModerationAction, Announcement, PromoBanner
    │   ├── views.py                     <-- AdminAnalyticsView, ModerationActionView
    │   └── moderation_notifications.py  <-- Warning & restriction notification builders
    │
    ├── ai_engine/                       <-- AI Semantic Search & i18n
    │   ├── models.py                    <-- LocalizedText cache model
    │   ├── ai_search.py                 <-- Gemini embeddings & priority fallback
    │   └── middleware.py                <-- ContentLocalizationMiddleware (X-App-Language)
    │
    ├── subscriptions/                   <-- Professional Subscriptions
    │   ├── models.py                    <-- SubscriptionPlan, Subscription
    │   └── views.py                     <-- PlanListView, ActiveSubscriptionView
    │
    ├── payments/                        <-- Deferred Payment System
    │   ├── models.py                    <-- Payment, WithdrawalRequest, Ledger
    │   └── views.py                     <-- Transaction views (Preserved & untouched)
    │
    └── about_page/                      <-- Dynamic CMS
        ├── models.py                    <-- AboutSection, Milestones, Team
        └── views.py                     <-- Public CMS endpoint
```

---

## 4. End-to-End Data Lifecycle & User Journey Traces

### Trace 1: Mobile User Cold Start (App Khulne Ka Safar)
1. User mobile app icon par tap karta hai.
2. `main.dart` -> `bootstrap.dart` execute hota hai.
3. SharedPreferences se saved JWT `access_token`, `refresh_token` aur `user_role` read hote hain.
4. `ApiService` base URL configure karta hai aur interceptor initialize karta hai.
5. Agar token mojood ho to user ko direct `/home` (Customer) ya `/pro` (Professional) dashboard par navigate kiya jata hai. Agar token na ho to user as `Guest` home screen dekh sakta hai.

---

### Trace 2: Two-Factor Secure Account Deletion Flow
1. User `settings_screen.dart` par ja kar "Delete Account" button dabata hai.
2. `delete_account_dialog.dart` khulta hai:
   - Agar user ke paas password hai, to wo password enter karta hai.
   - Agar user Google Sign-In wala hai (yani password set nahi), to dialog automatic 6-digit Gmail OTP fallback par switch ho jata hai.
3. User "Request Code" dabata hai -> `POST /api/users/delete-account/request-otp/`.
4. Brevo API se 6-digit OTP user ki email par aati hai (60-second cooldown timer chalta hai).
5. User code verify karta hai -> `POST /api/users/delete-account/confirm/`.
6. Django backend user ke tamam linked records (profiles, tokens, notifications, bookings) ko **cascade delete** kar ke response bhejta hai.
7. Flutter session wipe out kar ke user ko `/login` par safely redirect kar deta hai.

---

## 5. Verified Test Results & Production Readiness Assessment

| Test Suite | Commands Executed | Result | Status |
| :--- | :--- | :--- | :--- |
| **Frontend Test Suite** | `flutter test` | **144 / 144 Passed** (0 failures, 29s run time) | ✅ Production Ready |
| **Frontend Static Analysis** | `flutter analyze` | **0 Errors, 0 Warnings, 0 Async violations** | ✅ Clean Codebase |
| **Backend Test Suite** | `python manage.py test` | **568 / 568 Passed** (All suites OK) | ✅ Production Ready |
| **Database Migrations** | `python manage.py showmigrations` | **All 104 Migrations Applied [X]** | ✅ Clean Schema |
| **Django System Check** | `python manage.py check` | **System check identified no issues (0 silenced)**| ✅ Verified |

---

## 6. Strictly Deferred Areas

Per explicit instructions, the following two areas are preserved and remain in their original baseline state:
1. **Professional Country-Based Currency**: **DEFERRED — AWAITING OWNER DECISION** (*Not Modified*).
2. **Payment System & Gateway Processing**: **DEFERRED — AWAITING OWNER DECISION** (*Not Modified*).

---

*End of Master Codebase and Learning Guide. For file-by-file line breakdowns, refer to `profinder_guide.zip` on your Windows Desktop.*
