# ProFinder Backend API

> A full-featured Django REST Framework backend for a professional services marketplace — connecting customers with verified professionals (doctors, lawyers, engineers, plumbers, and more).

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

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Framework | Django | 6.0.3 |
| REST API | Django REST Framework | 3.16.1 |
| Authentication | djangorestframework-simplejwt | 5.5.1 |
| Social Login | django-allauth | 65.18.0 |
| Database | PostgreSQL via psycopg2-binary | 2.9.12 |
| File Storage | cloudinary + django-cloudinary-storage | 1.44.2 / 0.3.0 |
| Push Notifications | firebase-admin | 7.4.0 |
| AI Engine | google-genai (Gemini) | 2.7.0 |
| CORS | django-cors-headers | 4.9.0 |
| HTTP Client | httpx | 0.28.1 |
| Data Validation | pydantic | 2.13.4 |
| Environment | python-dotenv | 1.2.2 |
| WebSockets | websockets | 16.0 |
| Email | Gmail SMTP (built-in Django) | — |

### Full Dependency List (`requirements.txt`)

```
annotated-types==0.7.0       anyio==4.13.0
asgiref==3.11.1              CacheControl==0.14.4
certifi==2026.5.20           cffi==2.0.0
charset-normalizer==3.4.7    cloudinary==1.44.2
cryptography==48.0.0         distro==1.9.0
Django==6.0.3                django-allauth==65.18.0
django-cloudinary-storage==0.3.0  django-cors-headers==4.9.0
djangorestframework==3.16.1  djangorestframework_simplejwt==5.5.1
firebase_admin==7.4.0        google-api-core==2.30.3
google-auth==2.53.0          google-cloud-core==2.6.0
google-cloud-firestore==2.27.0   google-cloud-storage==3.10.1
google-crc32c==1.8.0         google-genai==2.7.0
google-resumable-media==2.9.0    googleapis-common-protos==1.75.0
grpcio==1.80.0               grpcio-status==1.80.0
httpx==0.28.1                idna==3.17
msgpack==1.1.2               proto-plus==1.28.0
protobuf==6.33.6             psycopg2-binary==2.9.12
pydantic==2.13.4             PyJWT==2.13.0
python-dotenv==1.2.2         requests==2.34.2
sqlparse==0.5.5              tenacity==9.1.4
typing_extensions==4.15.0    tzdata==2025.3
urllib3==2.7.0               websockets==16.0
```

---

## Project Structure

```
backend/
├── manage.py                   # Django management entry point
├── requirements.txt            # All Python dependencies
├── .env                        # Environment variables (never commit this)
├── firebase-credentials.json   # Firebase service account key
├── db.sqlite3                  # Local SQLite (dev only; production uses PostgreSQL)
│
├── profinder/                  # Django project configuration
│   ├── settings.py             # All project settings
│   ├── urls.py                 # Root URL routing
│   ├── asgi.py                 # ASGI entry point
│   └── wsgi.py                 # WSGI entry point
│
└── apps/                       # All Django apps
    ├── users/                  # Authentication & user management
    ├── profiles/               # User & professional profiles, portfolio
    ├── search/                 # Categories, subcategories, professional search
    ├── reviews/                # Customer reviews & ratings
    ├── payments/               # Payment records
    ├── bookings/               # Booking system
    ├── notifications/          # In-app + FCM push notifications
    ├── subscriptions/          # Subscription plans & features
    ├── ai_engine/              # AI recommendations & search history
    └── admin_panel/            # Admin actions, logs, promo banners
```

Each app follows the standard Django structure:

```
apps/<app_name>/
├── __init__.py
├── admin.py        # Django admin registration
├── apps.py         # App configuration
├── models.py       # Database models
├── serializers.py  # DRF serializers
├── views.py        # API views
├── urls.py         # App-level URL patterns
├── tests.py        # Unit tests
└── migrations/     # Database migration files
```

---

## Apps Overview

### `users` — Authentication & User Management
Handles registration, login, JWT tokens, password reset, and user roles.

**Roles:** `customer` | `professional` | `admin`

### `profiles` — Profile Management
Manages two profile types:
- **UserProfile** — for customers (name, photo, phone, city, location)
- **ProfessionalProfile** — for professionals (bio, category, hourly rate, verification status, average rating)
- **Portfolio** — professionals can upload work samples; admin approves/rejects them

### `search` — Discovery & Categories
Manages the category taxonomy and powers professional search/filtering.

**Categories include:** Doctors & Healthcare, Lawyers & Legal, Engineers, Architects, Accountants, IT & Tech, Tutors, Plumbers, Electricians, Cleaners, Carpenters, Painters, and more.

### `reviews` — Ratings & Reviews
Customers leave reviews for professionals after a booking. Each customer can review a professional only once (enforced at DB level).

### `payments` — Payment Records
Tracks payment transactions with statuses: `pending`, `completed`, `failed`, `refunded`.

### `bookings` — Booking System
Full booking lifecycle management: `pending` → `accepted` → `completed` / `cancelled` / `rejected`. Tracks cancellation reasons and who cancelled.

### `notifications` — Notification System
- Saves in-app notifications to the database
- Sends real-time Firebase Cloud Messaging (FCM) push notifications to user devices
- Used across all other apps (bookings, payments, reviews, subscriptions)

### `subscriptions` — Subscription Plans
Flexible subscription system for both customers and professionals.
- Plans are fully configurable from the admin panel — no hardcoded limits
- Features (e.g. `ai_search_limit`, `booking_limit`, `featured_profile`) stored as key-value pairs in `PlanFeature`
- Supports `free`, `monthly`, and `yearly` billing

### `ai_engine` — AI-Powered Recommendations
- Stores AI recommendation results (`AIRecommendation`)
- Tracks user search history (`SearchHistory`)
- Powered by Google Gemini API

### `admin_panel` — Admin Tools
- **AdminLog** — full audit trail of all admin actions (verify, ban, approve portfolio, cancel booking, etc.)
- **PromoBanner** — configurable popup advertisements with target audience, trigger, schedule, and call-to-action link

---

## Database Models

### `users.User`
| Field | Type | Notes |
|---|---|---|
| `email` | EmailField | Unique, used as username |
| `name` | CharField | Full name |
| `role` | CharField | `customer`, `professional`, or `admin` |
| `fcm_token` | CharField | Firebase push notification token |
| `is_active` | BooleanField | Account active status |
| `created_at` | DateTimeField | Auto-set on creation |

### `profiles.UserProfile`
| Field | Type | Notes |
|---|---|---|
| `user` | OneToOneField | Links to `User` |
| `full_name` | CharField | |
| `photo_url` | CloudinaryField | Profile photo |
| `phone` | CharField | |
| `city` | CharField | |
| `latitude` / `longitude` | DecimalField | For location-based search |

### `profiles.ProfessionalProfile`
| Field | Type | Notes |
|---|---|---|
| `user` | OneToOneField | Links to `User` |
| `category` | ForeignKey | Links to `search.Category` |
| `bio` | TextField | |
| `experience_years` | IntegerField | |
| `hourly_rate` | DecimalField | |
| `is_verified` | BooleanField | Auto-set when portfolio is approved |
| `average_rating` | DecimalField | Calculated from reviews |
| `cnic_url` / `license_url` | CloudinaryField | Verification documents |

### `profiles.Portfolio`
| Field | Type | Notes |
|---|---|---|
| `professional` | ForeignKey | Links to `User` |
| `title` | CharField | |
| `image_url` | CloudinaryField | Work sample image |
| `status` | CharField | `pending`, `approved`, `rejected` |
| `admin_note` | TextField | Admin's rejection reason |
| `reviewed_at` | DateTimeField | When admin reviewed it |

### `bookings.Booking`
| Field | Type | Notes |
|---|---|---|
| `customer` | ForeignKey | Links to `User` |
| `professional` | ForeignKey | Links to `User` |
| `date` / `time` | DateField / TimeField | Booking schedule |
| `status` | CharField | `pending`, `accepted`, `rejected`, `completed`, `cancelled` |
| `cancel_reason` | TextField | Why it was cancelled |
| `cancelled_by` | CharField | `customer`, `professional`, or `admin` |

### `reviews.Review`
| Field | Type | Notes |
|---|---|---|
| `reviewer` | ForeignKey | Customer who wrote the review |
| `professional` | ForeignKey | Professional being reviewed |
| `rating` | IntegerField | 1–5 |
| `comment` | TextField | |
| Unique constraint | | One review per reviewer-professional pair |

### `payments.Payment`
| Field | Type | Notes |
|---|---|---|
| `user` | ForeignKey | |
| `amount` | DecimalField | |
| `currency` | CharField | Default: `USD` |
| `stripe_id` | CharField | Stripe transaction reference |
| `status` | CharField | `pending`, `completed`, `failed`, `refunded` |

### `subscriptions.SubscriptionPlan`
| Field | Type | Notes |
|---|---|---|
| `name` | CharField | e.g. "Free", "Premium Monthly" |
| `plan_type` | CharField | `customer` or `professional` |
| `billing` | CharField | `free`, `monthly`, `yearly` |
| `price` | DecimalField | |
| `currency` | CharField | Default: `PKR` |
| `duration_days` | IntegerField | `0` = forever (free plan) |

### `subscriptions.PlanFeature`
Stores each feature/limit of a plan as a key-value pair.

| Key | Type | Description |
|---|---|---|
| `ai_search_limit` | int | Daily AI searches (0 = unlimited) |
| `message_send_limit` | int | Daily messages |
| `ads_enabled` | bool | Show ads to this user |
| `booking_limit` | int | Monthly bookings (professionals) |
| `portfolio_limit` | int | Max portfolio images |
| `featured_profile` | bool | Show in featured section |
| `priority_ranking` | bool | Higher in search results |
| `premium_badge` | bool | Display premium badge |

### `admin_panel.PromoBanner`
Fully configurable popup ads:

| Field | Notes |
|---|---|
| `target_audience` | `everyone`, `guest`, `free_customer`, `premium_professional`, etc. |
| `trigger` | `app_open`, `home`, `search`, `ai_search`, `booking`, `login`, `every_x_days` |
| `button_link_type` | `subscription`, `category`, `external_url`, `offer`, `none` |
| `start_date` / `end_date` | Optional scheduling |
| `priority` | Higher number = shown first |

---

## API Endpoints

All REST endpoints are prefixed with `/api/`.

### Authentication — `/api/users/`
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/users/register/` | Register new user |
| POST | `/api/users/login/` | Login, receive JWT tokens |
| POST | `/api/users/token/refresh/` | Refresh access token |
| GET / PATCH | `/api/users/me/` | Get or update current user |
| POST | `/api/users/forgot-password/` | Send password reset email |
| POST | `/api/users/reset-password/<uid>/<token>/` | Reset password |

### Profiles — `/api/profiles/`
| Method | Endpoint | Description |
|---|---|---|
| GET / PATCH | `/api/profiles/me/` | Customer profile |
| GET / PATCH | `/api/profiles/professional/me/` | Professional profile |
| GET / POST | `/api/profiles/portfolio/` | Portfolio items |
| PATCH | `/api/profiles/portfolio/<id>/` | Update portfolio item |

### Search & Discovery — `/api/search/`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/search/categories/` | List all categories |
| GET | `/api/search/professionals/` | Search & filter professionals |
| GET | `/api/search/professionals/<id>/` | Professional detail |

### Bookings — `/api/bookings/`
| Method | Endpoint | Description |
|---|---|---|
| GET / POST | `/api/bookings/` | List or create bookings |
| PATCH | `/api/bookings/<id>/status/` | Update booking status |
| POST | `/api/bookings/<id>/cancel/` | Cancel a booking |

### Reviews — `/api/reviews/`
| Method | Endpoint | Description |
|---|---|---|
| GET / POST | `/api/reviews/` | List or create reviews |
| GET | `/api/reviews/professional/<id>/` | Reviews for a professional |

### Payments — `/api/payments/`
| Method | Endpoint | Description |
|---|---|---|
| GET / POST | `/api/payments/` | List or record payments |

### Notifications — `/api/notifications/`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/notifications/` | List user notifications |
| PATCH | `/api/notifications/<id>/read/` | Mark as read |

### Subscriptions — `/api/subscriptions/`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/subscriptions/plans/` | Available plans |
| POST | `/api/subscriptions/subscribe/` | Subscribe to a plan |
| GET | `/api/subscriptions/my/` | Current user subscription |

### AI Engine — `/api/ai/`
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/ai/recommendations/` | AI-powered professional recommendations |
| GET | `/api/ai/search-history/` | User's past search queries |

### Admin Panel — `/api/admin-panel/`
| Method | Endpoint | Description |
|---|---|---|
| GET / POST | `/api/admin-panel/users/` | List users, ban/unban |
| POST | `/api/admin-panel/verify/<id>/` | Verify a professional |
| GET / POST | `/api/admin-panel/portfolio/` | Review portfolio submissions |
| GET | `/api/admin-panel/logs/` | View all admin action logs |
| GET / POST | `/api/admin-panel/banners/` | Manage promo banners |

### Google OAuth — `/accounts/`
| Endpoint | Description |
|---|---|
| `/accounts/google/login/` | Initiate Google OAuth flow |
| `/accounts/google/login/callback/` | OAuth callback (handled by allauth) |

---

## Authentication

The API uses **JWT (JSON Web Tokens)** via `djangorestframework-simplejwt`.

- **Access Token** — valid for **60 minutes**
- **Refresh Token** — valid for **7 days**

Include the access token in every protected request:

```http
Authorization: Bearer <access_token>
```

To get new tokens after expiry, call `/api/users/token/refresh/` with your refresh token.

**Google OAuth** is also supported via `django-allauth`. After a successful login, the user is redirected to `/api/users/me/`.

---

## Environment Variables

Create a `.env` file in the `backend/` root with these variables:

```env
# Django
SECRET_KEY=your-secret-key
DEBUG=True

# Database (PostgreSQL)
DB_NAME=ProFinder
DB_USER=postgres
DB_PASSWORD=your-db-password
DB_HOST=localhost
DB_PORT=5432

# Cloudinary (file storage)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Firebase (push notifications)
FIREBASE_CREDENTIALS=firebase-credentials.json

# Google Gemini (AI engine)
GEMINI_API_KEY=your-gemini-api-key

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Email (Gmail SMTP)
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

> ⚠️ **Never commit `.env` or `firebase-credentials.json` to version control.** Add both to `.gitignore`.

---

## Installation & Setup

### 1. Clone the repository

```bash
git clone <repo-url>
cd backend
```

### 2. Create and activate a virtual environment

```bash
python -m venv venv
source venv/bin/activate        # Linux / macOS
venv\Scripts\activate           # Windows
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Set up environment variables

Copy the `.env` template above and fill in your credentials.

### 5. Set up the database

Make sure PostgreSQL is running and the database exists, then:

```bash
python manage.py migrate
```

### 6. Create a superuser (admin)

```bash
python manage.py createsuperuser
```

When prompted, also set `role=admin`.

### 7. Run the development server

```bash
python manage.py runserver
```

The API will be available at `http://127.0.0.1:8000/`.

---

## Key Features

- **Role-based access control** — customers, professionals, and admins each have separate permissions and capabilities
- **JWT + Google OAuth** — flexible authentication for both mobile and web clients
- **Professional verification flow** — professionals submit portfolio items; admins approve/reject them; approval auto-sets `is_verified`
- **Subscription system** — fully DB-driven feature limits (no hardcoded values); admin can change any limit without a code deploy
- **Firebase push notifications** — real-time alerts sent to user devices even when the app is in the background
- **AI-powered recommendations** — Google Gemini API used to match customers with the most relevant professionals
- **Admin audit log** — every admin action (ban, verify, approve, cancel) is recorded with timestamp and target user
- **Promo banner system** — configurable popup ads with audience targeting, scheduling, and action links
- **Cloudinary media storage** — all user photos, portfolio images, and verification documents stored on Cloudinary