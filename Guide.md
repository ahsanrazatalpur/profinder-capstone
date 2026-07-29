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




def __str__(self):
    return self.name
```
Ye admin panel mein naam dikhata hai:
```
❌ Without __str__  →  "Category object (1)"
✅ With __str__     →  "Doctor"




class SubCategory(models.Model):
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
```

Matlab:
```
SubCategory → Category se connected hai ForeignKey se

Doctor (Category)
    └── Dentist    (SubCategory) → category = Doctor
    └── Cardiologist (SubCategory) → category = Doctor

SubCategory ka Category se relation — agar Category delete ho tو us ki SubCategories bhi delete ho jayen.


from django.apps import AppConfig

class SearchConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.search'
    label = 'search'
```

---

**Label kyun dalete hain** — yaad karo pehle wali problem:
```
name = 'apps.search'
```

Django todta hai:
```
app_label = 'apps'  ← galat — apps koi app nahi
model     = 'search'
```

Label add karne se:
```
label = 'search'    ← Django ko clearly bataya
app_label = 'search' ✅





default_auto_field = 'django.db.models.BigAutoField'
```

Ye har table mein **id column** ka type define karta hai:
```
BigAutoField  →  id automatically 1, 2, 3, 4... badhta hai
                 Big matlab — bohot bada number tak ja sakta hai
                 2,147,483,647 tak — sufficient for any app
```

---

Without ye line:
```
id = 1, 2, 3...  ← normal — chhota number
```

With BigAutoField:
```
id = 1, 2, 3...  ← bohot bada number tak — safe for future
```

---

Simple:
```
default_auto_field  →  id column ka type — auto increment
BigAutoField        →  bada number — future safe



## Quick Notes

```
model       →  database table
serializer  →  translator — Python to JSON, JSON to Python
view        →  API logic — request lo, response do
urls        →  address — kaunsi URL kaunsa view
admin.py    →  admin panel mein model register karo
apps.py     →  app ki config — label zaroor daalo
migrations  →  model ko actual database table banao
```

---

```
ForeignKey      →  2 tables ka relation — many to one
OneToOneField   →  2 tables ka relation — ek to ek
CASCADE         →  parent delete → child bhi delete
blank=True      →  optional field — khali chor sakte
null=True       →  database mein NULL store ho sakta
default=value   →  koi value na do → ye default use ho
auto_now_add    →  automatically current time save karo
BigAutoField    →  id auto increment — 1,2,3...
```

---

```
permission_classes = [IsAuthenticated]  →  login check karo
request.user                            →  current logged in user
partial=True                            →  sirf kuch fields update karo
write_only=True                         →  field aaye but wapas na jaye
```




categories = Category.objects.all()  ← ye ek nahi — LIST hai
serializer = CategorySerializer(categories, many=True)
#                                            ↑
#                                  many=True → list translate karo
```

---
```
many=False  →  ek object   → { }
many=True   →  list        → [ { }, { }, { } ]

// many=False — ek category
{ "id": 1, "name": "Doctor" }

// many=True — sari categories
[
    { "id": 1, "name": "Doctor" },
    { "id": 2, "name": "Lawyer" },
    { "id": 3, "name": "Plumber" }
]



path('categories/<int:category_id>/subcategories/', ...)
#                 ↑
#          ye dynamic value hai
#          Flutter yahan category ka id dega
```

---

Example:
```
/api/search/categories/1/subcategories/  → Doctor ki subcategories
/api/search/categories/2/subcategories/  → Lawyer ki subcategories



reviewer     = ForeignKey(User)   ← User se
professional = ForeignKey(User)   ← User se bhi
```

Django confused ho jata — kaunsa relation use karun?

`related_name` se clearly bataya:
```
reviewer     → given_reviews    ← maine diye reviews
professional → received_reviews ← mujhe mile reviews


def __str__(self):
    return f"{self.reviewer.email} → {self.professional.email} - {self.rating}⭐"
```

Admin panel mein aisa dikhega:
```
ahsan@gmail.com → doctor@gmail.com - 5⭐



read_only_fields = ['reviewer', 'created_at']
```
```
reviewer    →  automatically set hoga — logged in user
               Flutter se nahi aayega — khud set karenge view mein

created_at  →  automatically set hoga — current time
               Flutter se nahi aayega

{
    "professional": 2,
    "rating": 5,
    "comment": "Very good doctor!"
}
reviewer aur created_at Django khud set karega!




Bhai 3 cheezein samjhata hoon:

---

## 1. `serializers.ModelSerializer` kyun?

```python
from rest_framework import serializers

class ReviewSerializer(serializers.ModelSerializer):
```

`serializers` — DRF ka module hai
`ModelSerializer` — is module ke andar ek class hai

Isko inherit kiya — taake automatically model ki fields se serializer bane — khud se sab likhna na pade.

---

## 2. `Meta` kya hai?

```python
class Meta:
```

`Meta` — configuration class hai — serializer ko batati hai:

```
Konsa model use karo
Konsi fields include karo
Konsi fields read only hain
```

Bina `Meta` ke serializer ko pata nahi kya translate karna hai.

---

## 3. `model = Review`

```python
class Meta:
    model = Review
```

Serializer ko bataya — **Review model ka data translate karna hai** — kisi aur ka nahi.

---

Simple:

```
serializers.ModelSerializer  →  base class — sab kuch ready
Meta                         →  config — konsa model, konsi fields
model = Review               →  is model ka data translate karo
```

---

Clear bhai?


from rest_framework import serializers

class ReviewSerializer(serializers.ModelSerializer):
```
```
serializers        →  DRF ka built-in module
ModelSerializer    →  DRF ka built-in class — humne nahi banai
ReviewSerializer   →  humne banai — ModelSerializer ko extend kiya
```

---

Same jaise User model mein tha:
```
AbstractBaseUser   →  Django ka built-in
UserManager        →  Django ka built-in
User               →  humne banai — built-in ko extend kiya
```

---

Simple rule:
```
Built-in  →  import karo — use karo
Apna      →  built-in ko extend karo — customize karo





ab view py ese kam kerta
Bhai pehle upar waali cheezein samjhata hoon:

---

```python
from rest_framework import status
```
HTTP status codes — 200, 201, 400, 401 — inhe numbers ki jagah naam se use karo:
```
status.HTTP_201_CREATED      = 201
status.HTTP_400_BAD_REQUEST  = 400
```

---

```python
from rest_framework.response import Response
```
Flutter ko jawab dene ke liye — data JSON mein bhejo.

---

```python
from rest_framework.views import APIView
```
API banane ke liye base class — get, post, put methods yahan se aati hain.

---

```python
from apps.reviews.models import Review
```
Review table se data lene ke liye — database se interact karna hai.

---

```python
from apps.reviews.serializers import ReviewSerializer
```
Python object ko JSON mein convert karne ke liye — Flutter samjhe.

---

## Ab `post` method samjhao:

```python
def post(self, request, professional_id):
```
Flutter ne review submit kiya — professional ka id URL mein diya.

---

```python
serializer = ReviewSerializer(data=request.data)
```
Flutter ka data liya — serializer ko diya translate karne ke liye.

---

```python
if serializer.is_valid():
    serializer.save(
        reviewer=request.user,        ← logged in user automatically
        professional_id=professional_id ← URL se professional id
    )
```
Data valid hai — save karo — `reviewer` khud set kiya logged in user se.

---

```python
return Response(serializer.data, status=status.HTTP_201_CREATED)
```
Review ban gaya — Flutter ko data aur 201 status bhejo.

---




bhai abn ye hai model payment ka
Bhai sahi samjha — sirf `read_only_fields` clear karta hoon:

---

```python
read_only_fields = ['user', 'stripe_id', 'status', 'created_at']
```

**Kyun ye read only hain:**

```
user       →  automatically set hoga — logged in user
               Flutter se nahi aayega

stripe_id  →  Stripe se aayega — payment process hone ke baad
               Flutter se nahi aayega

status     →  Django set karega — pending, completed, failed
               Flutter se nahi aayega

created_at →  automatically current time
               Flutter se nahi aayega
```

---

**Flutter sirf ye bhejega:**

```json
{
    "amount": 500.00,
    "currency": "PKR"
}
```

Baaki sab Django khud set karega!

---

Clear bhai? Ab `views.py` kholo!





notification model
Bhai ek ek cheez samjhata hoon jo miss hain:

---

**`class Notification(models.Model)` — models.Model kyun?**
```
models.Model  →  Django ko bataya ye ek database table hai
               Django is se table banayega
```

---

**`TYPE_CHOICES` kyun?**
```
Notification ka type limit karna tha
Koi bhi random type na daal sake
Sirf ye 4 allowed:
payment, review, subscription, general
```

---

**`settings.AUTH_USER_MODEL` kya hai?**
```
settings.py mein likha tha:
AUTH_USER_MODEL = 'users.User'

Matlab → hamara custom User model use karo
Direct User import karne ki bajaye
settings se lete hain — flexible rehta hai
```

---

**`is_read` kyun?**
```
Notification padhi ya nahi:
False → user ne abhi nahi padhi  ← default
True  → user ne padh li
```

Flutter mein ye kaam aayega:
```
is_read = False → red dot dikhao
is_read = True  → dot hatao
```

---

**`def __str__` kyun?**
```
Admin panel mein dikhane ke liye:

Without __str__ → "Notification object (1)"
With __str__    → "ahsan@gmail.com - Payment Received"
```

---

Clear bhai? Ab `apps/notifications/apps.py` mein label add karo!





notification serilizer chai
Haan bhai — 100% sahi! 🎉

---

Sirf 2 cheezein add karta hoon:

---

**`NotificationSerializer` kyun banai?**
```
Flutter ko notifications JSON mein chahiye
Serializer Python object ko JSON mein translate karta hai
```

---

**`serializers.ModelSerializer` kyun?**
```
ModelSerializer automatically model ki fields se
serializer banata hai — khud se sab likhna nahi parta
```

---

Ab `apps/notifications/views.py` kholo!




notification view
Haan bhai — 100% sahi samjha! 🎉

---

Sirf 3 cheezein add karta hoon:

---

**`self` kyun?**
```
Class ke andar har function mein self likhte hain
self = apni class ko refer karna
```

---

**`NotificationSerializer(notifications, many=True)` — params kyun?**
```
notifications  →  ye list hai — sari notifications
many=True      →  list translate karo — ek nahi
```

---

**`patch` kyun — `put` nahi?**
```
put   →  poori object update karo — sab fields
patch →  sirf ek field update karo — is_read=True
```

Notification mein sirf `is_read` update karna tha — isliye `patch` use kiya.

---

Ab `apps/notifications/urls.py` banao — new file!



notification url
Bhai bilkul sahi samjha! 🎉

---

Sirf 2 cheezein samjhata hoon:

---

**`urlpatterns` list kyun?**
```
Django yahan se URLs dhundta hai
List mein sari URLs hoti hain
Django ek ek check karta hai — match hone par view chalta hai
```

---

**`.as_view()` kya hai?**
```
NotificationView ek class hai
Django ko function chahiye — class nahi

.as_view()  →  class ko function mein convert karta hai
               Django use kar sake
```

---

Ab migrate karo:

```bash
python manage.py makemigrations
python manage.py migrate
```

Output batao!




subscriptio model.py
Bhai simple —

---

**1. SubscriptionPlan mein:**
```python
def __str__(self):
    return self.name
```

Admin panel mein aisa dikhega:
```
❌ Without → "SubscriptionPlan object (1)"
✅ With    → "Basic"
             "Premium"
             "Free"
```

---

**2. Subscription mein:**
```python
def __str__(self):
    return f"{self.professional.email} - {self.plan.name}"
```

Admin panel mein aisa dikhega:
```
❌ Without → "Subscription object (1)"
✅ With    → "ahmed@gmail.com - Premium"
             "sara@gmail.com - Basic"
```

---

Simple:
```
__str__  →  admin panel mein readable naam dikhao
            object number ki bajaye
```

Clear bhai?


serlizer subscription
Bhai simple —

```python
class Meta:
```

Configuration class hai — serializer ko 3 cheezein batati hai:

```
model   →  konsa table use karo
fields  →  konsi columns include karo
read_only_fields → konsi fields sirf read karo — Flutter se na aaye
```

---

Bina `Meta` ke serializer ko pata nahi:
```
Konsa model?     ❌
Konsi fields?    ❌
```

Meta ke saath:
```
Model = Subscription    ✅
Fields = id, plan...    ✅
```

---

Clear bhai?


Haan bhai — 100% sahi! 🎉

---

Sirf ye part samjhata hoon jo miss tha:

---

**`SubscriptionView` GET:**
```python
subscription = Subscription.objects.filter(professional=request.user)
```
Sirf logged in professional ki subscriptions lo — baaki sab ki nahi.

---

**`SubscriptionPlanView` mein `permission_classes` nahi:**
```python
class SubscriptionPlanView(APIView):
    # permission nahi
```
Plans sab dekh sakte hain — login zaroor nahi.
```
Free, Basic, Premium  →  koi bhi dekh sake
                          register se pehle bhi
```

**`SubscriptionView` mein `permission_classes` hai:**
```python
permission_classes = [IsAuthenticated]
```
Subscribe sirf logged in professional kar sakta hai.

---

Clear bhai? Ab `urls.py` banao!


Haan bhai — 100% sahi samjha! 🎉

---

Sirf ek cheez samjhata hoon:

---

**`related_name` kyun diya — 2 ForeignKey same model par:**

```python
user         = ForeignKey(User, related_name='recommendations')
professional = ForeignKey(User, related_name='recommended_to')
```

Same problem jaise `Review` mein thi:

```
Dono User table se connected hain
Django confused hoga — kaunsa relation use karun?

related_name se clearly bataya:
user         → recommendations  ← maine maangi recommendations
professional → recommended_to   ← mujhe recommend kiya gaya
```

---

Ab `apps/ai_engine/apps.py` mein label add karo!




Bhai `name` mein comma hai — hatao:

```python
from django.apps import AppConfig

class AiEngineConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.ai_engine'
    label = 'ai_engine'
```

---

`default_auto_field` ka matlab:
```
Har table mein id column automatically banta hai
BigAutoField → bohot bada number tak ja sakta hai
```

Save karo!