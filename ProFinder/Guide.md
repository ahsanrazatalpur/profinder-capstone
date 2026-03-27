####################################################################################################################
Why we build this project ? : (Real Problem)
Bhai soch — Karachi mein tere ghar ka pipe toot gaya raat ko. Tu kya karega?

Google mein search karega — 50 results aayenge, kaunsa trustworthy?
Kisi se poochhhega — shayad woh na jaanta ho
Random ko call karega — price pata nahi, genuine hai ya nahi?

Ye problem sirf plumber ki nahi hai. Doctor dhundna, lawyer dhundna, tutor dhundna — sab mein yahi problem hai Pakistan mein.
ProFinder is problem ko solve karta hai:

Verified professionals ek jagah
Real reviews aur ratings
GPS se nearest pehle
Price pehle se pata
Secure payment app ke andar


####################################################################################################################
Walk me through project 

## ProFinder

**Problem** — Pakistan mein local verified professional dhundna mushkil, koi trusted platform nahi.

**Solution** — GPS-based app jahan verified professionals mile, profile dekho, book karo, pay karo.

---

**Users** — Customer, Professional, Admin

**Stack** — Flutter, Django, PostgreSQL, Stripe, Firebase, Cloudinary

**Features** — Auth, Profiles, GPS Search, Reviews, Payments, Subscriptions, Notifications, AI Matching, Admin Panel

**Database** — 18 tables, PostgreSQL only

**Deploy** — Railway (backend), Play Store (app)

####################################################################################################################

## ProFinder Tech Stack

---

### Frontend
**Flutter (Dart)** — Android + iOS + Web, ek codebase teen platforms

### Backend
**Django + Django REST Framework (Python)** — API banata hai, business logic handle karta hai

### Database
**PostgreSQL** — data store, GPS queries PostGIS extension se

### Auth
**JWT + OTP + Google OAuth** — secure login system

### Payments
**Stripe** — international payments, PCI compliant

### Notifications
**Firebase FCM** — push notifications Android + iOS

### File Storage
**Cloudinary** — images, portfolios, documents

### AI
**OpenAI GPT-4o-mini** — professional matching engine

### Deployment
**Railway** — backend + database host, free tier

---

## Why This Stack — 1 Line Each

| Technology | Reason |
|---|---|
| Flutter | Ek codebase, teen platforms |
| Django | Fast, secure, Python, industry proven |
| PostgreSQL | Structured data + GPS support |
| Stripe | Most trusted payment gateway |
| Firebase | Free, reliable notifications |
| Cloudinary | 25GB free image storage |
| GPT-4o-mini | Cheapest smart AI — $0.15/1M tokens |
| Railway | Free hosting, easy deploy |

####################################################################################################################

## ProFinder Folder Structure
---

### Root
```
profinder/
├── profinder-backend/     ← Django
└── profinder-frontend/    ← Flutter
```

---
## Backend Folder Strcuture

backend/
│
├── venv/                    ← Virtual environment (packages yahan hain)
│
├── manage.py                ← Django ka remote control
│                               (server run, database banana sab isse)
│
├── requirements.txt         ← Installed packages ki list
│                               (abhi nahi bana, baad mein banayenge)
│
├── .env                     ← Secret keys — database password, stripe key
│                               (kabhi GitHub par mat daalna)
│
├── profinder/               ← Main Django project folder
│   ├── __init__.py          ← Ye folder Python package hai — ye batata hai
│   ├── settings.py          ← Poori project ki settings
│   │                           database, installed apps, secret key
│   ├── urls.py              ← Main routes
│   │                           kaunsi URL kahan jaye
│   ├── asgi.py              ← Real-time connections ke liye
│   └── wsgi.py              ← Deployment ke liye
│
└── apps/                    ← Har feature ka apna folder
    ├── users/               ← Registration, login, auth
    ├── profiles/            ← Customer + Professional profiles
    ├── search/              ← Search + GPS
    ├── reviews/             ← Ratings + reviews
    ├── payments/            ← Stripe
    ├── notifications/       ← FCM push notifications
    ├── subscriptions/       ← Free/Basic/Premium plans
    ├── ai/                  ← AI matching engine
    └── admin_panel/         ← Admin control


### Frontend
```
profinder-frontend/
├── lib/
│   ├── main.dart          ← entry point
│   ├── screens/           ← sab screens
│   ├── widgets/           ← reusable components
│   ├── models/            ← data models
│   ├── services/          ← API calls (Django se baat)
│   └── providers/         ← Riverpod state management
├── assets/                ← images, fonts, icons
└── pubspec.yaml           ← Flutter packages
```

---

Fisrt of all we will create Backend (Django)

Reason :  We will create Djnago Backend first becasue if any user ask for any data eg : " doctor in karachi " that 
information saved in database but frontend cannot acces database data (or communicate with database) so we buid backkend first (The Talking , The rules) then frontend now frontend can acces databse information



Phir aps (folder) banao her table (features) ke liye

sab se pehle backend mn jao aur  environment active kro
cmd : venv\Scripts\activate

ek fodler banao apps se ab sare apps uske ander banao
cmd for app =  python ../manage.py startapp appname (jaha manage.py hai wahi se manage.py ka pah du)

phir ye sare aps banao

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         3/18/2026   4:11 AM                admin_panel
d-----         3/18/2026   4:11 AM                ai_engine
d-----         3/18/2026   4:10 AM                notifications
d-----         3/18/2026   4:10 AM                payments
d-----         3/18/2026   4:09 AM                profiles
d-----         3/18/2026   4:09 AM                reviews
d-----         3/18/2026   4:09 AM                search
d-----         3/18/2026   4:10 AM                subscriptions
d-----         3/18/2026   4:07 AM                users



cmd :

(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp users
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp profiles
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp search
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp reviews
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp payments
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp notifications
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp subscriptions
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp ai_engine
(venv) PS D:\Final Year Project\ProFinder\backend\apps> python ../manage.py startapp admin_panel
(venv) PS D:\Final Year Project\ProFinder\backend\apps> dir 


basic structure define
users/
│
├── migrations/    ← Database changes ka history
│                     (touch mat karna — Django khud manage karta hai)
│
├── models.py      ← Database table define karo
│                     (User ka naam, email, password — sab yahan)
│
├── views.py       ← API logic yahan
│                     (registration, login ka code yahan hoga)
│
├── admin.py       ← Django admin panel mein ye model dikhao
│
├── apps.py        ← Is app ki basic config
│
├── tests.py       ← Testing ke liye
│                     (abhi zaroorat nahi)
│
└── __init__.py    ← Ye folder Python package hai




phir setting.py mn jao aur apne jo aps install kye use define kero phir server run kerke deho
# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # 3rd party (drf)
    'rest_framework' ,

    # my apps
    'apps.users',
    'apps.profiles',
    'apps.search',
    'apps.reviews',
    'apps.payments',
    'apps.notifications',
    'apps.subscriptions',
    'apps.ai_engine',
    'apps.admin_panel'
]


make user apps ka name her app ke app.py mn same hona chye ager koi app app ke folder mn ho to pehle likh app.user phir name likho ok


phr 
cmd : python manage.py migrate   cmd chalke databse ke ander tables banao


phir ye cmd lagake cmd: python manage.py createsuperuser    admin banao jo builtin acces huga 

user model create ke bad ye cmd chlao

python manage.py makemigrations
python manage.py migrate



jab server chalrha hoga to databse delete nh huga cmd del dbname


user ke sari file banao models , serilier, view , url and admin.py jaha humene user ko admin panel mn show karaya 

phir thunder clinet vs extension down koer uspe user ko regsiter kerke dekho hogya ab admin panel pe user ko dekho

ab JWT toekn banante pehle ye intsall kero

cmd : pip install djangorestframework-simplejwt




JWt token kya hai : 
Bhai almost sahi — thoda correct karta hoon:

---

```
User login kiya
      ↓
2 tokens mile:
├── Access Token   → 60 min valid — API calls ke liye
└── Refresh Token  → 7 days valid — naya access token lene ke liye
```

---

```
Access Token expire hua (60 min baad)
      ↓
Refresh Token bhejo
      ↓
Naya Access Token mila
      ↓
User logged in rahega — dobara login nahi karna
```

---

Ek cheez correct karta hoon:

```
❌ Register hone par token nahi milta
✅ Login karne par token milta hai
```

---

Shared Preferences wala bilkul sahi kaha — Flutter mein tokens wahan save hote hain!

```
Login kiya → tokens mile → Shared Preferences mein save
Next time  → Shared Preferences check kiya → token hai → login skip
```

---



phir setting.py mn sabse last mn JWT token add kero

from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

time apne hisab se rakh sakte 
timedelta(minutes=30)   # 30 minutes
timedelta(hours=2)      # 2 ghante
timedelta(days=1)       # 1 din
timedelta(days=30)      # 1 mahina

ut by default better hai

```
timedelta  =  time duration define karna


ab login banao
login sirf view.py and url.py mn banega 




JWT token kese kam kerta 
1. Pehli baar login kiya
        ↓
JWT ne banaya — Access + Refresh token
        ↓
Flutter ne Shared Preferences mein save kiya

2. Next time app khola
        ↓
Flutter ne Shared Preferences check kiya
Access token hai? → Login skip ✅

3. 60 min baad Access token expire hua
        ↓
Flutter ne Refresh token bheja → /api/users/token/refresh/
        ↓
Django ne naya Access token diya
        ↓
Flutter ne save kiya — user logged in raha ✅

4. 7 din baad Refresh token bhi expire hua
        ↓
Flutter ne dobara login dikhaya

(iske lye hum refresh api banate)


refresh api nh banai perti khali use kerni perti ye alredy buil in hai hum user url.py mn khali import kerke oath dete

from rest_framework_simplejwt.views import TokenRefreshView
```

Ye import kiya — seedha use kar liya — khud kuch likhna nahi tha!

---
```
Register  →  humne khud view likhi  ✅
Login     →  humne khud view likhi  ✅
Refresh   →  JWT ka built-in view use kiya ✅




ab prfile app bnaege


serilizer mn 
a=class Meta:
    model = UserProfile
    fields = [...]
```

`Meta` class — serializer ko batati hai:
```
model  → konsi table use karo
fields → konse columns Flutter ko bhejo


api view mn
put  →  profile update karna
partial=True  →  sari fields zaroor nahi — jo bhi bhejo update ho jaye

