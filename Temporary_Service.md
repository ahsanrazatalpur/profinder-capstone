# ProFinder — External Services & Production Cost Guide

> **Project:** ProFinder Marketplace (Flutter App + Django Backend)  
> **Currency Baseline:** $1 USD ≈ 280 PKR  
> **Date:** October 2026  

---

## 1. Quick Master Comparison Table

| # | Service | Current Free Status | Recommended Production Plan | Monthly (USD) | Monthly (PKR) |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **1** | **Backend Hosting** | PythonAnywhere Free | DigitalOcean VPS (2GB RAM, ASGI) | **$12.00** | **Rs. 3,360** |
| **2** | **Database & Redis** | Local SQLite (`db.sqlite3`) | Supabase Managed PostgreSQL + Redis | **$25.00** | **Rs. 7,000** |
| **3** | **Gemini AI Engine** | Free Developer Tier | Google Cloud Pay-As-You-Go | **$15.00** | **Rs. 4,200** |
| **4** | **Media Storage** | Cloudinary Free (25 Credits) | AWS S3 Storage + CloudFront CDN | **$10.00** | **Rs. 2,800** |
| **5** | **Email Service** | Brevo Free (300/day) | Brevo Starter (5,000 emails/mo) | **$9.00** | **Rs. 2,520** |
| **6** | **Push Alerts (FCM)** | Firebase Spark Plan | Firebase Blaze Plan (Pay as you go) | **$0.00** | **Rs. 0** |
| **7** | **Google Sign-In** | Dev / Testing Consent | Verified Google OAuth Screen | **$0.00** | **Rs. 0** |
| **8** | **PayPal Payments** | Sandbox Test Mode | Verified Live PayPal Merchant | **$0.00\*** | **Rs. 0\*** |
| **9** | **Exchange Rates** | Open Free API | Free Cached Endpoint (Retained) | **$0.00** | **Rs. 0** |
| **10** | **Custom Domain** | Free PA Subdomain | `profinder.com` + Cloudflare SSL | **$1.16** | **Rs. 326** |

*\* PayPal has no monthly fixed fee; standard 2.99%–3.49% + $0.49 is deducted per transaction.*

---

## 2. Service-by-Service Breakdown

---

### 1. Backend Server & WebSockets

- **Current Plan:** PythonAnywhere Free Beginner Account (`ahsanrazatalpur.pythonanywhere.com`)
- **The Problem with Free Tier:**
  - PythonAnywhere free tier only runs WSGI. It **cannot run ASGI/WebSockets**, meaning live chat will not work in production.
  - Outbound HTTP requests are restricted to a whitelist. Unlisted external APIs fail.
  - CPU usage is capped at 100 seconds/day, and the site sleeps if not manually renewed every 3 months.
- **Recommended Paid Solution:**
  - **DigitalOcean Basic Droplet** (2 GB RAM, 1 vCPU, 50 GB NVMe SSD) running Daphne/ASGI and Gunicorn.
- **Estimated Cost:**
  - **Monthly:** $12.00 USD ≈ **Rs. 3,360 PKR**
  - **Annual:** $144.00 USD ≈ **Rs. 40,320 PKR**

---

### 2. Managed Database & Redis Cache

- **Current Plan:** Local SQLite Database (`db.sqlite3`)
- **The Problem with Free Tier:**
  - SQLite locks the entire database file during writes (`database is locked` error). Multiple concurrent bookings or payments will cause app crashes.
  - No Redis server is running. Real-time chat currently falls back to in-memory, which cannot scale across multiple users.
- **Recommended Paid Solution:**
  - **Supabase Pro Tier** (Managed PostgreSQL with daily automated backups) + **Upstash Redis Serverless**.
- **Estimated Cost:**
  - **Monthly:** $25.00 USD ≈ **Rs. 7,000 PKR**
  - **Annual:** $300.00 USD ≈ **Rs. 84,000 PKR**

---

### 3. Google Gemini AI & Translation Engine

- **Current Plan:** Google AI Studio Free Tier (`gemini-2.5-flash` / `gemini-flash-latest`)
- **The Problem with Free Tier:**
  - Capped at 15 Requests Per Minute (RPM) and 1,500 Requests Per Day.
  - Because of free quota limits, live translations are currently restricted to Urdu and Hindi only (`['ur', 'hi']`). Arabic, Spanish, and French dynamic content translation is deferred.
  - Free API data may be used by Google for model training.
- **Recommended Paid Solution:**
  - **Google Cloud Gemini Paid Tier** (Pay-As-You-Go token billing).
  - Unlocks all 5 target languages (`ur`, `hi`, `ar`, `es`, `fr`) with enterprise data privacy.
- **Estimated Cost:**
  - **Monthly:** $15.00 USD ≈ **Rs. 4,200 PKR**
  - **Annual:** $180.00 USD ≈ **Rs. 50,400 PKR**

---

### 4. Cloud Media & Document Storage

- **Current Plan:** Cloudinary Free Account (25 Monthly Transformation Credits)
- **The Problem with Free Tier:**
  - ProFinder stores user profile avatars, high-res portfolio images, legal CNIC/license verification files, and chat attachments.
  - Once 25 monthly credits are used up, all image rendering and uploads stop completely.
- **Recommended Paid Solution:**
  - **AWS S3 + CloudFront CDN** (Pay-as-you-go based on storage and bandwidth).
  - Cloudinary Plus costs $89/mo, whereas AWS S3 costs only ~$10/mo for startup scale.
- **Estimated Cost:**
  - **Monthly:** $10.00 USD ≈ **Rs. 2,800 PKR**
  - **Annual:** $120.00 USD ≈ **Rs. 33,600 PKR**

---

### 5. Transactional Email Service

- **Current Plan:** Brevo (Sendinblue) Free Plan
- **The Problem with Free Tier:**
  - Enforces a hard limit of **300 emails per day**.
  - If more than 300 users register or request password resets in a day, emails are blocked.
  - Shared free IPs can occasionally cause password reset emails to land in spam.
- **Recommended Paid Solution:**
  - **Brevo Starter Plan** (5,000 emails/month with dedicated deliverability) or **Amazon SES** ($0.10 per 1,000 emails).
- **Estimated Cost:**
  - **Monthly:** $9.00 USD ≈ **Rs. 2,520 PKR**
  - **Annual:** $108.00 USD ≈ **Rs. 30,240 PKR**

---

### 6. Firebase Cloud Messaging (FCM)

- **Current Plan:** Firebase Spark Plan (Free)
- **Status:**
  - Push notifications via FCM are **free of charge** on Android and iOS.
  - Upgrade Google Cloud project to **Blaze Plan (Pay as you go)** only to ensure billing verification for production quotas.
- **Estimated Cost:**
  - **Monthly:** **$0.00 USD** (Rs. 0 PKR)

---

### 7. Google OAuth (Social Login)

- **Current Plan:** Google Cloud Credentials (Testing Mode)
- **The Problem with Free Tier:**
  - Unverified consent screen displays a prominent red security warning: *"Google hasn't verified this app"*.
  - Limited to 100 test user accounts.
- **Recommended Paid Solution:**
  - Submit the OAuth screen for Google Verification (Requires Privacy Policy & Terms URL on a custom domain). Google charges $0 for verification.
- **Estimated Cost:**
  - **Monthly:** **$0.00 USD** (Rs. 0 PKR)

---

### 8. PayPal Payment Gateway

- **Current Plan:** PayPal Sandbox Mode (`PAYPAL_MODE = 'sandbox'`)
- **The Problem with Free Tier:**
  - Only test/dummy credit cards and sandbox accounts can be used; no real money transactions can occur.
- **Recommended Paid Solution:**
  - Switch `PAYPAL_MODE` to `live` using verified PayPal Business Merchant credentials.
- **Estimated Cost:**
  - **Monthly Fixed Fee:** **$0.00 USD** (Rs. 0 PKR)
  - **Per-Transaction Fee:** 2.99% to 3.49% + $0.49 deducted automatically per customer payment.

---

### 9. Multi-Currency Exchange Rate API

- **Current Plan:** Open Exchange Rate Endpoint (`open.er-api.com`)
- **Status:**
  - ProFinder has a built-in 12-hour database cache (`ExchangeRateCache`).
  - The free endpoint is fast and completely adequate for live production.
- **Estimated Cost:**
  - **Monthly:** **$0.00 USD** (Rs. 0 PKR)

---

### 10. Custom Domain & SSL

- **Current Plan:** PythonAnywhere Subdomain (`ahsanrazatalpur.pythonanywhere.com`)
- **The Problem with Free Tier:**
  - A commercial mobile app on the Play Store requires a professional brand domain (e.g., `api.profinder.com`).
  - Required for Google OAuth verification and PayPal live webhook signatures.
- **Recommended Paid Solution:**
  - Buy `profinder.com` from Namecheap or Cloudflare Registrar with free Let's Encrypt / Cloudflare SSL.
- **Estimated Cost:**
  - **Annual:** $14.00 USD/year ≈ **Rs. 3,920 PKR/year**
  - **Monthly Equivalent:** **$1.16 USD / mo** (Rs. 326 PKR / mo)

---

### 11. Mobile App Store Developer Accounts

- **Google Play Console (Android):**
  - **Type:** One-time registration fee (Lifetime).
  - **Cost:** **$25.00 USD** ≈ **Rs. 7,000 PKR** (One-time)

- **Apple Developer Program (iOS — Optional):**
  - **Type:** Annual subscription.
  - **Cost:** **$99.00 USD / year** ≈ **Rs. 27,720 PKR / year**

---

## 3. Total Production Budget Summary

### 🅰️ Lean Startup Budget (Recommended for Google Play Launch)

*Covers: Google Play Store + Custom Domain + DigitalOcean VPS (WebSockets enabled) + Managed PostgreSQL + Gemini AI + AWS S3 Storage + Brevo Email.*

```
One-Time Initial Setup:
  • Google Play Console Account:         $25.00   (Rs. 7,000)

Annual Recurring:
  • Custom Domain (profinder.com):       $14.00   (Rs. 3,920 / yr)

Monthly Operating Cost:
  • DigitalOcean VPS (ASGI/WebSockets):  $12.00   (Rs. 3,360 / mo)
  • Managed PostgreSQL Database:         $25.00   (Rs. 7,000 / mo)
  • Google Gemini AI (Paid Token Pool):  $15.00   (Rs. 4,200 / mo)
  • AWS S3 Media Storage & CDN:          $10.00   (Rs. 2,800 / mo)
  • Brevo Transactional Email:           $9.00    (Rs. 2,520 / mo)
  • Firebase & PayPal Base Fee:          $0.00    (Rs. 0 / mo)
  -------------------------------------------------------------
  TOTAL MONTHLY COST:                   $71.00 / mo   (Rs. 19,880 / mo)

FIRST YEAR COMPLETE INVESTMENT:
  One-Time ($25) + Domain ($14) + 12 Months ($71 x 12 = $852)
  -------------------------------------------------------------
  TOTAL 1ST YEAR COST:                  $891.00 USD   (Rs. 249,480 PKR)
```

---

### 🅱️ Full Dual-Store Launch (Android + iOS App Store)

*Covers everything in Option A PLUS Apple Developer Program ($99/year) and 4GB RAM VPS upgrade.*

```
One-Time Initial Setup:
  • Google Play Console Account:         $25.00   (Rs. 7,000)

Annual Recurring:
  • Apple Developer Program:             $99.00   (Rs. 27,720 / yr)
  • Custom Domain (profinder.com + .pk): $35.00   (Rs. 9,800 / yr)

Monthly Operating Cost:
  • High-Performance VPS (4GB RAM):      $24.00   (Rs. 6,720 / mo)
  • Managed DB + Redis Cluster:          $35.00   (Rs. 9,800 / mo)
  • Google Gemini AI Pool:               $25.00   (Rs. 7,000 / mo)
  • Media Storage & CDN:                 $15.00   (Rs. 4,200 / mo)
  • Brevo Email Starter:                 $9.00    (Rs. 2,520 / mo)
  -------------------------------------------------------------
  TOTAL MONTHLY COST:                   $108.00 / mo  (Rs. 30,240 / mo)

FIRST YEAR COMPLETE INVESTMENT:
  One-Time ($25) + Annual ($134) + 12 Months ($108 x 12 = $1,296)
  -------------------------------------------------------------
  TOTAL 1ST YEAR COST:                  $1,455.00 USD  (Rs. 407,400 PKR)
```

---

## 4. Priority Roadmap — Which to Buy First

```
Phase 1: Brand & Store (One-Time / Annual)
  1. Buy Domain name ($14 / yr) -> Rs. 3,920
  2. Buy Google Play Console ($25 one-time) -> Rs. 7,000

Phase 2: Core Server & Database (Immediate for Live App)
  3. DigitalOcean VPS ($12 / mo) -> Rs. 3,360 / mo
  4. Managed Database ($25 / mo) -> Rs. 7,000 / mo

Phase 3: Scaling & Full AI Translation (When Users Join)
  5. Gemini AI Paid Tier ($15 / mo) -> Rs. 4,200 / mo
  6. AWS S3 Storage ($10 / mo) -> Rs. 2,800 / mo
  7. Brevo Email Starter ($9 / mo) -> Rs. 2,520 / mo
```
