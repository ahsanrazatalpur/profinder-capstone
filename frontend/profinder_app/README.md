# ProFinder Flutter Frontend

> A cross-platform Flutter application for the **ProFinder** marketplace — connecting customers with verified professionals (doctors, lawyers, engineers, technicians, and local service providers) with real-time chat, subscriptions, multilingual support, and role-based experiences.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack & Dependencies](#tech-stack--dependencies)
- [Architecture & Directory Structure](#architecture--directory-structure)
- [Role-Based Experiences](#role-based-experiences)
- [Core Features](#core-features)
  - [Real-Time Messaging & Chat](#real-time-messaging--chat)
  - [Internationalization (i18n) & RTL](#internationalization-i18n--rtl)
  - [Theme Management (Light & Dark)](#theme-management-light--dark)
  - [Search, Filtering & AI Discovery](#search-filtering--ai-discovery)
  - [Subscriptions & Usage Quotas](#subscriptions--usage-quotas)
  - [Support & Ticket System](#support--ticket-system)
- [Cross-Platform Resilience](#cross-platform-resilience)
- [Setup & Installation](#setup--installation)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [University Viva & Architecture Talking Points](#university-viva--architecture-talking-points)

---

## Overview

ProFinder is built with Flutter and Dart, targeting **Android**, **iOS**, and **Web**. The frontend interfaces with a Django REST Framework backend hosted separately, providing:
- Role-specific workflows for **Guest**, **Customer**, **Professional**, and **Admin** users.
- Live WebSockets for instant chat, typing indicators, and presence updates.
- 6-language internationalization (English, Urdu, Arabic, Spanish, French, and Hindi) with bi-directional RTL support.
- Fully automated test suite with 100% passing status across 136 test cases.

---

## Tech Stack & Dependencies

| Layer | Technology | Package / Tool |
|---|---|---|
| **Framework** | Flutter 3.x / Dart 3.x | Google Flutter SDK |
| **State Management** | Provider | `provider: ^6.1.2` |
| **HTTP & Networking** | Dio | `dio: ^5.4.1` |
| **Realtime WebSockets** | WebSockets | `web_socket_channel: ^3.0.0` |
| **Local Storage** | SharedPreferences | `shared_preferences: ^2.2.2` |
| **Image Caching** | CachedNetworkImage | `cached_network_image: ^3.3.1` |
| **Image & Media Picking** | ImagePicker & FilePicker | `image_picker: ^1.1.2`, `file_picker: ^8.1.2` |
| **Audio Recording & Playback** | Record & Audioplayers | `record: ^5.1.2`, `audioplayers: ^6.0.0` |
| **Emoji Support** | EmojiPicker Flutter | `emoji_picker_flutter: ^3.0.0` |
| **Localization** | Flutter Localizations & Intl | `flutter_localizations`, `intl: ^0.19.0` |
| **UI Components** | Glassmorphism & Icons | `flutter_svg`, `font_awesome_flutter` |

---

## Architecture & Directory Structure

The project follows a **Feature-First Clean Architecture** pattern, enforcing separation of concerns between Domain Entities, Data Sources, and Presentation State:

```
frontend/profinder_app/
├── lib/
│   ├── main.dart                       # App entry point, MultiProvider configuration, Theme & Locale injection
│   │
│   ├── app/                            # Global app routing, navigation guards, and auth gates
│   │
│   ├── core/                           # Core infrastructure, design tokens, and utilities
│   │   ├── constants/                  # API endpoints (AppConstants), typography tokens, sizes
│   │   ├── theme/                      # AppColors, AppTextStyles, ThemeProvider, ThemeContextExtension
│   │   ├── localization/               # ContentLocalizer, language selection helpers
│   │   ├── network/                    # Dio client setup, interceptors, token refresh mechanics
│   │   └── utils/                      # AppHelpers, responsive math utils, formatters
│   │
│   ├── shared/                         # Reusable cross-feature UI widgets
│   │   └── widgets/                    # ProfileHeaderCard, CategoryCard, CtaBanner, UniversalAppBar, etc.
│   │
│   ├── features/                       # Modular business domains
│   │   ├── about/                      # About page, policies, and company content
│   │   ├── admin/                      # Admin dashboard, user moderation, analytics, content editor
│   │   ├── auth/                       # Splash, login, registration, password recovery, social auth
│   │   ├── bookings/                   # Booking creation, scheduling, status tracking, review submission
│   │   ├── chat/                       # Real-time messaging (Domain, Data, Presentation)
│   │   │   ├── domain/                 # MessageEntity, ConversationEntity, ChatRepository contract
│   │   │   ├── data/                   # ChatRemoteDataSource, ChatSocketDataSource, ChatRepositoryImpl
│   │   │   └── presentation/           # ChatProvider, ConversationListProvider, ChatScreen, VoiceRecorder
│   │   ├── home/                       # Role-specific home tabs (GuestHomeScreen, CustomerHomeScreen, etc.)
│   │   ├── magazine/                   # Lifestyle & professional knowledge articles, tips, and search
│   │   ├── notifications/              # In-app notifications feed, preferences, push notification handling
│   │   ├── payments/                   # Wallet, transaction records, checkout flows
│   │   ├── professional/               # Professional workspace, bookings feed, earnings, reviews
│   │   ├── profile/                    # User settings, language picker, account security, saved items
│   │   ├── search/                     # Professional discovery, category browser, filters, AI recommendations
│   │   ├── subscription/               # Plan selection, billing, paywall limits, promo popups
│   │   └── trust_safety/               # Moderation appeals, reports, user guidelines
│   │
│   ├── l10n/                           # ARB translation files
│   │   ├── app_en.arb                  # English (Source)
│   │   ├── app_ur.arb                  # Urdu (RTL)
│   │   ├── app_ar.arb                  # Arabic (RTL)
│   │   ├── app_es.arb                  # Spanish
│   │   ├── app_fr.arb                  # French
│   │   ├── app_hi.arb                  # Hindi
│   │   └── generated/                  # Generated AppLocalizations classes
│   │
│   └── services/                       # Centralized API facades and state singletons
│
└── test/                               # Automated widget and unit tests (136 tests)
```

---

## Role-Based Experiences

ProFinder enforces dynamic Role-Based Access Control (RBAC). Upon login or token verification, users are routed to their designated shell:

| Role | Primary Shell | Features & Permissions |
|---|---|---|
| **Guest** | `GuestMainScreen` | Browse top categories, view verified professionals, read magazine articles, prompt login on booking attempt. |
| **Customer** | `CustomerHomeScreen` | Search & filter professionals, AI recommendations, book appointments, chat, make payments, leave ratings. |
| **Professional** | `ProfessionalMainScreen` | Manage booking requests (accept/reject), view wallet earnings, build portfolio, track reviews, upgrade plan. |
| **Admin** | `AdminMainScreen` | Verify professional portfolios, ban/unban accounts, inspect audit logs, manage promo popups, resolve support tickets. |

---

## Core Features

### Real-Time Messaging & Chat
- **Hybrid Real-Time Pipeline**:
  - WebSockets push text messages, live typing signals, user presence (online/last-seen), and emoji reaction updates immediately.
  - REST endpoints back pagination history (`limit=30` with `before_id`), file uploads, and fallback delivery synchronization.
- **Voice Messages**: Compact audio recorder supporting AAC/Opus encoding with cross-platform fallback (`UrlSource` for web blob URLs, `DeviceFileSource` for native disk files).
- **Optimistic UI**: Messages render instantly in `sending` state and transition to `sent`, `delivered`, or `seen` (double blue tick) upon acknowledgment.
- **Moderation**: In-chat user blocking, unblocking, and report submission matching backend enforcement policies.

### Internationalization (i18n) & RTL
- Supported languages: **English**, **Urdu**, **Arabic**, **Spanish**, **French**, and **Hindi**.
- Persisted language selection via `SharedPreferences`.
- Automatic layout flipping to **Right-to-Left (RTL)** for Urdu and Arabic without layout clipping or text overflow.

### Theme Management (Light & Dark)
- Seamless theme switching: **Light**, **Dark**, or **System Default**.
- Persisted across app restarts.
- Custom `ThemeContextExtension` (`context.colors.surface`, `context.colors.textPrimary`) providing WCAG AA contrast compliance across all screens.

### Search, Filtering & AI Discovery
- **Taxonomy Filtering**: Category, subcategory, city, rating, and hourly rate slider.
- **Google Gemini AI Recommendations**: Natural-language query search matching customer needs to professional skills.
- **Query Debounce**: Search input requests debounced at 350ms to minimize network traffic.

### Subscriptions & Usage Quotas
- Configurable subscription tiers (Free vs. Premium).
- Dynamic paywalls enforcing daily AI search limits, monthly booking quotas, and message limits.
- Promotional popups with cooldown periods, skip-lock countdown timers, and deep-link actions.

### Support & Ticket System
- Customer/Professional support ticketing with categorised inquiry forms.
- Admin support inbox with internal notes, status workflows (`open`, `in_progress`, `closed`), and customer replies.

---

## Cross-Platform Resilience

- **Flutter Web Compatibility**:
  - `dart:io.File` stub workarounds: file uploads stream through `XFile.readAsBytes()`, preventing web browser runtime crashes.
  - Image preview widget (`LocalImagePreview`) distinguishes between browser `blob:` URLs and native filesystem paths.
- **Audio Decoding**:
  - Dynamic audio format sniffing (`sniffAudioFormat`) detects file header bytes to assign accurate MIME types (`audio/mp4`, `audio/webm`, `audio/wav`).

---

## Setup & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
- Android Studio / Xcode (for mobile emulation)
- Chrome / Edge (for web testing)

### 1. Clone the repository
```bash
git clone <repo-url>
cd frontend/profinder_app
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Generate localization files (if modifying ARB strings)
```bash
flutter gen-l10n
```

### 4. Run the app
```bash
# Debug mode on connected device or emulator
flutter run

# Run on Chrome
flutter run -d chrome
```

### 5. Build for release
```bash
# Android APK
flutter build apk --release

# Web production build
flutter build web --release
```

---

## Testing & Quality Assurance

ProFinder maintains a test suite covering unit logic, providers, state transitions, and responsive widget layouts:

```bash
# Run static code analysis (0 errors, 0 warnings, 0 lints)
flutter analyze

# Run all automated tests
flutter test
```

### Test Suite Summary
- **Total Tests**: 136
- **Pass Rate**: 100%
- **Coverage Areas**:
  - Routing and authentication gates
  - Support ticket lifecycle and admin replies
  - Notification preference switches (push & email)
  - Price filter and search state
  - Responsive RTL layouts (Urdu 2x scaling)
  - Theme mode persistence

---

## University Viva & Architecture Talking Points

When presenting this project for an academic defense or technical interview, emphasize:

1. **Decoupled Architecture**: Separation of Presentation, Domain, and Data layers allows swapping API clients without breaking UI widgets.
2. **Hybrid Realtime Strategy**: Combining WebSocket channels with REST fallbacks ensures offline stability and instant responsiveness.
3. **Optimistic State Management**: Actions like reaction toggles and chat dispatches update UI optimistically with automatic rollback on network failure.
4. **Bi-directional i18n**: Support for LTR and RTL scripts with dynamic string resolution backed by Flutter's localization engine.
5. **Cross-Platform Defensive Coding**: Proactive handling of platform divergence (Web blob URLs vs. Android/iOS native file streams).
