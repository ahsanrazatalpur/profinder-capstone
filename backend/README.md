# ProFinder Backend API

> A production-hardened Django 6 / Django REST Framework backend for the ProFinder global professional services marketplace — connecting customers with verified professionals across healthcare, legal, engineering, education, and trades with real-time WebSockets, AI-powered discovery, automated translation, and secure payment processing.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Apps Overview](#apps-overview)
- [Database Models](#database-models)
- [API Endpoints](#api-endpoints)
- [Authentication](#authentication)
- [Environment Variables](#environment-variables)
- [Installation & Setup](#installation--setup)
- [Key Features](#key-features)
- [Running Tests](#running-tests)

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Framework | Django | 6.0.3 |
| REST API | Django REST Framework | 3.16.1 |
| Authentication | djangorestframework-simplejwt | 5.5.1 |
| Social Login | django-allauth | 65.18.0 |
| Database | PostgreSQL / SQLite | 2.9.12 (psycopg2-binary) |
| WebSockets / ASGI | websockets + asgiref | 16.0 / 3.11.1 |
| File Storage | cloudinary + django-cloudinary-storage | 1.44.2 / 0.3.0 |
| Push Notifications | firebase-admin | 7.4.0 |
| AI Engine | google-genai (Gemini) | 2.7.0 |
| Payments | PayPal REST API + Exchange Rate Engine | — |
| Email Service | Brevo API / Gmail SMTP | — |
| CORS | django-cors-headers | 4.9.0 |
| HTTP Client | httpx | 0.28.1 |
| Data Validation | pydantic | 2.13.4 |
| Environment | python-dotenv | 1.2.2 |

---

## Project Structure

```
backend/
├── manage.py                   # Django CLI management entry point
├── requirements.txt            # Python dependencies
├── .env                        # Local environment variables (never commit)
├── firebase-credentials.json   # Firebase service account key
├── db.sqlite3                  # Active local database (production uses PostgreSQL)
│
├── profinder/                  # Project configuration
│   ├── settings.py             # Django settings & security hardening
│   ├── urls.py                 # Root URL routing table
│   ├── asgi.py                 # ASGI entry point for WebSockets
│   └── wsgi.py                 # WSGI entry point for HTTP
│
└── apps/                       # 12 Modular micro-apps
    ├── users/                  # Authentication, JWT, user roles & email dispatch
    ├── profiles/               # User & professional profiles, portfolio items
    ├── search/                 # High-precision search, phonetic aliases & typo correction
    ├── bookings/               # Appointment lifecycle & double-booking concurrency locks
    ├── messaging/              # Real-time WebSocket chat, voice notes & attachments
    ├── reviews/                # Verified customer ratings & reviews
    ├── payments/               # PayPal order capture, wallet ledger, exchange rate cache
    ├── subscriptions/          # Dynamic plans, quotas & feature access rules
    ├── notifications/          # In-app feed & Firebase Cloud Messaging (FCM)
    ├── ai_engine/              # Google Gemini AI & multilingual translation engine
    ├── support/                # Help center knowledge base & customer ticket system
    └── admin_panel/            # Audit logs, promo banners, Trust & Safety moderation & appeals
```

Each app follows the clean Django micro-app pattern:

```
apps/<app_name>/
├── __init__.py
├── admin.py        # Django admin interface registration
├── apps.py         # App configuration
├── models.py       # Database models & indexes
├── serializers.py  # DRF serializers & field validation
├── views.py        # API views & query optimization
├── urls.py         # App-level routing
├── tests.py        # Automated unit & integration tests
└── migrations/     # Version-controlled database migrations
```

---

## Apps Overview

### `users` — Authentication & User Management
Handles registration, login, JWT token issuance, password reset (via Brevo / SMTP), FCM device tokens, and role enforcement.
- **Roles:** `customer` | `professional` | `admin`
- **Security:** Strict password policies, JWT refresh token rotation, and notification preferences.

### `profiles` — Profile & Portfolio Management
- **UserProfile** — Customer profiles with contact information, avatar, and geographic coordinates.
- **ProfessionalProfile** — Detailed portfolios with category assignment, hourly rates, experience, bio, and verification flags.
- **Portfolio** — Portfolio item submissions approved or rejected by platform administrators.

### `search` — Discovery, Taxonomy & High-Precision Search
High-precision search engine featuring:
- Strict category isolation (e.g., plumbers never leak into doctor queries).
- Phonetic aliases for Roman Urdu, Hindi, Arabic, Spanish, and French (e.g., *bukhar* / *tabeeb* -> Doctor).
- Typo-tolerant fuzzy matching and prefix completion.
- Composite search indexes for low-latency queries.

### `bookings` — Appointment Scheduling & Lifecycle
Full booking lifecycle: `pending` → `accepted` → `completed` / `cancelled` / `rejected`.
- Database-level concurrency protection prevents double-booking identical time slots for the same professional.
- Tracks who initiated cancellation and records explicit cancellation reasons.

### `messaging` — Real-Time WebSocket Chat
- Real-time bi-directional chat via Django Channels / ASGI WebSockets.
- Voice notes upload and playback support (`voice.py`).
- Image attachment handling with Cloudinary storage.
- Read receipts, typing indicators, and message reactions.

### `reviews` — Verified Customer Reviews
- Reviews can only be left by customers who booked with the professional.
- Enforced at the database level: unique per reviewer-professional booking pair.
- Automatically recalculates and updates the professional's `average_rating`.

### `payments` — PayPal, Wallet & Currency
- **PayPal Order Capture**: Server-side validation confirming capture state directly with PayPal.
- **Wallet & Withdrawals**: Concurrency-protected balance withdrawals (`select_for_update`) preventing overdrafts or race conditions.
- **Exchange Rates**: In-memory and cached exchange rate lookup engine (`exchange.py`) for multi-currency display.

### `subscriptions` — Dynamic Plans & Quotas
Flexible database-driven subscription engine:
- Configurable feature keys (`ai_search_limit`, `booking_limit`, `portfolio_limit`, `featured_profile`).
- Billing cycles: `free`, `monthly`, `yearly`.
- Zero hardcoded limits; administrators can adjust quotas instantly.

### `notifications` — In-App Feed & Push Alerts
- Stores persistent in-app notifications in the database.
- Dispatches Firebase Cloud Messaging (FCM) push alerts for bookings, payments, moderation, and chat.
- User-level granular notification preference controls.

### `ai_engine` — Google Gemini & Multilingual Translation
- **Gemini Recommendations**: Natural-language recommendation matches based on customer requirements.
- **Symptom Doctor Finder**: Matches physical symptoms to medical specialties (`symptoms.py`).
- **Multilingual Translation Engine**: Centralized `LocalizedText` store (`translation_service.py`) caching translations across English, Urdu, Arabic, Spanish, French, and Hindi.

### `support` — Knowledge Base & Tickets
- Help center articles categorized by topic with search capability.
- Ticket submission system for customers and professionals with admin reply threads.

### `admin_panel` — Moderation, Appeals & Governance
- **AdminLog**: Immutable audit trail of every administrative action.
- **PromoBanner**: Dynamic, scheduled in-app banner advertisements with custom call-to-actions.
- **Trust & Safety**: User reporting, automated content enforcement (`enforcement.py`), and appeal review pipeline (`appeals.py`).

---

## Database Models

### `users.User`
| Field | Type | Notes |
|---|---|---|
| `email` | EmailField | Primary username identifier |
| `name` | CharField | User's full display name |
| `role` | CharField | `customer`, `professional`, or `admin` |
| `fcm_token` | CharField | Firebase push device token |
| `preferred_language` | CharField | Default: `en` (supports `ur`, `ar`, `es`, `fr`, `hi`) |
| `is_active` | BooleanField | Account status flag |

### `profiles.ProfessionalProfile`
| Field | Type | Notes |
|---|---|---|
| `user` | OneToOneField | Associated `User` |
| `category` | ForeignKey | `search.Category` |
| `bio` | TextField | Professional biography |
| `experience_years` | IntegerField | Years in industry |
| `hourly_rate` | DecimalField | Rate in professional's local currency |
| `is_verified` | BooleanField | Set upon portfolio approval |
| `average_rating` | DecimalField | Aggregated from customer reviews |

### `bookings.Booking`
| Field | Type | Notes |
|---|---|---|
| `customer` | ForeignKey | Customer `User` |
| `professional` | ForeignKey | Professional `User` |
| `date` / `time` | DateField / TimeField | Scheduled slot |
| `status` | CharField | `pending`, `accepted`, `rejected`, `completed`, `cancelled` |
| `payment_status` | CharField | `unpaid`, `paid`, `refunded` |
| `cancel_reason` | TextField | Reason if cancelled |

### `messaging.Conversation` & `messaging.Message`
| Field | Type | Notes |
|---|---|---|
| `participants` | ManyToManyField | Users in the conversation |
| `sender` | ForeignKey | Message author |
| `content` | TextField | Message text |
| `message_type` | CharField | `text`, `image`, `voice` |
| `attachment_url` | URLField | Cloudinary media link |
| `is_read` | BooleanField | Read receipt status |

### `payments.Payment` & `payments.WithdrawalRequest`
| Field | Type | Notes |
|---|---|---|
| `user` | ForeignKey | Transaction participant |
| `amount` | DecimalField | Amount charged / requested |
| `currency` | CharField | Currency code (USD, PKR, etc.) |
| `paypal_order_id` | CharField | PayPal transaction reference |
| `status` | CharField | `pending`, `completed`, `failed`, `refunded` |

### `support.SupportTicket`
| Field | Type | Notes |
|---|---|---|
| `user` | ForeignKey | Ticket submitter |
| `subject` | CharField | Issue title |
| `category` | CharField | `billing`, `technical`, `account`, `general` |
| `status` | CharField | `open`, `in_progress`, `resolved`, `closed` |
| `priority` | CharField | `low`, `medium`, `high`, `urgent` |

---

## API Endpoints

All endpoints are prefixed with `/api/`.

### Authentication — `/api/users/`
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/users/register/` | Register new user |
| POST | `/api/users/login/` | Authenticate and receive JWT tokens |
| POST | `/api/users/token/refresh/` | Refresh expired access token |
| GET / PATCH | `/api/users/me/` | Current user profile & language preferences |
| POST | `/api/users/forgot-password/` | Send password reset email |
| POST | `/api/users/reset-password/<uid>/<token>/` | Reset password |

### Profiles — `/api/profiles/`
| Method | Endpoint | Description |
|---|---|---|
| GET / PATCH | `/api/profiles/me/` | Customer profile details |
| GET / PATCH | `/api/profiles/professional/me/` | Professional profile & services |
| GET / POST | `/api/profiles/portfolio/` | List or upload portfolio items |
| PATCH | `/api/profiles/portfolio/<id>/` | Update portfolio item |

### Search & Discovery — `/api/search/`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/search/categories/` | List categories and subcategories |
| GET | `/api/search/professionals/` | High-precision query & filters |
| GET | `/api/search/professionals/<id>/` | Professional public detail |

### Bookings — `/api/bookings/`
| Method | Endpoint | Description |
|---|---|---|
| GET / POST | `/api/bookings/` | List or create booking reservations |
| PATCH | `/api/bookings/<id>/status/` | Update status (accept, complete) |
| POST | `/api/bookings/<id>/cancel/` | Cancel booking with reason |

### Real-Time Messaging — `/api/messaging/`
| Method | Endpoint | Description |
|---|---|---|
| GET / POST | `/api/messaging/conversations/` | List or create conversations |
| GET / POST | `/api/messaging/conversations/<id>/messages/` | Conversation message history |
| POST | `/api/messaging/voice/` | Upload voice note attachment |

### Payments & Wallet — `/api/payments/`
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/payments/paypal/create-order/` | Create verified PayPal order |
| POST | `/api/payments/paypal/capture-order/` | Capture and verify order settlement |
| GET / POST | `/api/payments/wallet/withdraw/` | Concurrency-safe balance withdrawal |
| GET | `/api/payments/history/` | Transaction ledger history |

### AI Engine & Translation — `/api/ai/`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/ai/recommendations/` | Gemini-powered recommendations |
| POST | `/api/ai/symptoms/` | Symptom-to-doctor specialization finder |
| POST | `/api/ai/translate/` | Dynamic multilingual translation service |

### Support & Help Desk — `/api/support/`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/support/articles/` | Search help center knowledge base |
| GET / POST | `/api/support/tickets/` | List or submit support tickets |
| POST | `/api/support/tickets/<id>/reply/` | Post message to ticket thread |

### Admin & Moderation — `/api/admin-panel/`
| Method | Endpoint | Description |
|---|---|---|
| GET / POST | `/api/admin-panel/users/` | Manage accounts, ban / unban |
| POST | `/api/admin-panel/verify/<id>/` | Verify professional portfolio |
| GET | `/api/admin-panel/reports/` | Review user reports & infractions |
| POST | `/api/admin-panel/appeals/<id>/review/` | Review and resolve user appeals |
| GET | `/api/admin-panel/logs/` | View system audit trail |
| GET / POST | `/api/admin-panel/banners/` | Manage promotional popup banners |

---

## Authentication

Authentication uses **JWT (JSON Web Tokens)** via `djangorestframework-simplejwt`.

- **Access Token** — valid for **60 minutes**
- **Refresh Token** — valid for **7 days**

Include the access token in every protected request:

```http
Authorization: Bearer <access_token>
```

---

## Installation & Setup

### 1. Environment Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate           # On Windows
# source venv/bin/activate      # On Linux / macOS
pip install -r requirements.txt
```

### 2. Apply Migrations & Build Search Index

```bash
python manage.py migrate
python manage.py build_search_index
```

### 3. Run Development Server

```bash
python manage.py runserver
```
The API will be available at `http://127.0.0.1:8000/api/`.

---

## Running Tests

Run the full production-hardened backend test suite:

```bash
python manage.py test apps.payments apps.bookings apps.reviews apps.messaging apps.notifications apps.search apps.ai_engine.tests_translation
```

All 181+ test cases pass without regressions.