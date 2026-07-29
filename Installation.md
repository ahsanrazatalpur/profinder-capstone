Sab se pehle 

3 fodler banai 

ek main fodler  (project root)
profinder 

us folder ke ander 2 aur fodler   
1. frontend (frontend code) 
2. backend (backend code)


phir backend folder mn gai 
python ka environment banaya
cmd  :   python -m venv venv


why we built Python environment

Virtual Environment
What — A isolated box for your project's packages.
Why — So packages install locally in project, not globally on PC.
If not created — Projects will conflict with each other, packages will break.
If created — Every project has its own clean, isolated packages.

Example

---

You have 2 projects on your PC.

```
ProFinder        needs Django version 4.2
College Project  needs Django version 3.0
```

Without venv, both install on your PC globally:

```bash
pip install django==4.2   # installed globally
pip install django==3.0   # overwrote 4.2
```

Now ProFinder is broken — because Django 4.2 is gone, 3.0 replaced it.

---

With venv, both install separately:

```bash
ProFinder/venv       → django==4.2   ✅ safe
CollegeProject/venv  → django==3.0   ✅ safe
```

Both projects work perfectly — no conflict.

---



Then active the environment :
cmd : venv\Scripts\activate
why  we need to active  ?

You created a room (venv).
But you are still standing outside.
Activate = enter the room.

# Without activate
pip install django
# Installs GLOBALLY on PC ❌

# After activate
pip install django
# Installs INSIDE venv only ✅


Do i need to active tehe env evertytime

Every time — **har baar.**

---

```
PC band kiya — venv deactivate ho gaya
Terminal band kiya — venv deactivate ho gaya
New terminal khola — venv deactivate ho gaya
```

Isliye **har baar** jab backend par kaam karo, pehle:

```bash
venv\Scripts\activate
```
Phir koi bhi kaam karo.
---
Simple rule:
> Backend folder mein ghuse — pehla kaam venv activate karo. Phir kuch bhi karo.
---

Install karna ho     →  pehle activate
Server run karna ho  →  pehle activate
Code likhna ho       →  pehle activate
Kuch bhi karna ho    →  pehle activate


####################################################################################################################

then We install Django and Djangoframework 
cmd : pip install django djangorestframework

**pip** — Python ka package installer. Jaise Play Store se apps download karte ho, waise pip se Python packages download karte ho.

**django** — Backend framework. Tumhara server, API, database sab handle karta hai.

**djangorestframework** — Django ka extension jo REST API banane deta hai. Flutter is API se baat karega.

---
Is cmd se pip install django djangorestframework ye  chzn install hui
django 6.0.3              ← backend framework
djangorestframework 3.16.1 ← REST API banane ke liye
asgiref                   ← django ka helper
sqlparse                  ← SQL queries helper
tzdata                    ← timezone handler


pip install django djangorestframework
```
Tumne sirf 2 cheezein maangi.

But **django** khud apne saath 3 cheezein laaya jo usse kaam karne ke liye zaroori hain:
```
django        → tumne manga
    ├── asgiref   → django ko chahiye tha
    ├── sqlparse  → django ko chahiye tha
    └── tzdata    → django ko chahiye tha

djangorestframework → tumne manga




####################################################################################################################
Ab Django project create Kero
cmd : django-admin startproject profinder .


---

`django-admin` — Django ka tool hai jo naye projects banata hai. Jaise Flutter mein `flutter create` hota hai.

`startproject` — Matlab "naya project shuru karo"

`profinder` — Project ka naam

`.` — Current folder mein banao, naya folder mat banao

---

Ye command chalane ke baad Django automatically ye files banayega:

```
backend/
├── manage.py        ← Django ka remote control
└── profinder/
    ├── settings.py  ← project ki settings
    ├── urls.py      ← routes — kaunsi URL kahan jaye
    └── wsgi.py      ← deployment ke liye
```

---

**Ye files kya karti hain:**

`manage.py` — server run karna, database banana, sab kuch is se hoga

`settings.py` — database ka naam, installed apps, secret key sab yahan

`urls.py` — user `/api/professionals/` pe jaaye toh kaunsa code chale

---


profinder/   ← Project ki brain — settings, routes
apps/        ← Har feature alag alag yahan
venv/        ← Packages yahan — touch mat karna
manage.py    ← Sab commands isse chalti hain



Ab Python ke server ko test kero
cmd : python manage.py runserver

Server Kaha se aya ? 

Django ke andar pehle se ek development server hota hai. Tumhe alag se kuch install nahi karna — manage.py runserver chalao aur server start ho jaata hai.
Production mein alag server use hoga (Gunicorn) — but abhi development ke liye ye kaafi hai.


manage.py q likhte her cmd mn?

Bhai simple —

---

`manage.py` ek Python file hai jo Django ke saath automatically bani.

Isko khol ke dekho — andar ye hoga:

```python
#!/usr/bin/env python

import os
import sys

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'profinder.settings')
    
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()
```

---
manage.py  
Ye file kya karti hai:
ye ek remote control hai aur 

```python
# Ye line batati hai ke settings.py kahan hai
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'profinder.settings')

# Ye line jo bhi command tum likho terminal mein
# Django ko de deti hai execute karne ke liye
execute_from_command_line(sys.argv)
```

---

Example:

```bash
python manage.py runserver
#        ↑
#   sys.argv mein "runserver" gaya
#   Django ne runserver command execute ki
#   Server start ho gaya
```

---

**1 line mein:**
> `manage.py` tumhari command leta hai aur Django ko deta hai execute karne ke liye.

---



Server chal gya  :
ab browser pr is url pe jao aur dekho  : http://127.0.0.1:8000/
ab server ko band kerdo 
cmd :  Ab terminal mein CTRL + C dabao — server band karo.




####################################################################################################################

ab pkg ko recuiremnet.txt mn save kero
cmd : pip freeze > requirements.txt
ager koi aur computer mn ye pkg install kerne hu to 
cmd : pip install -r requirements.txt


`pip freeze` — ek command hai jo batati hai ke is waqt tumhare venv mein kaunse packages installed hain.

---

Run karo:

```bash
pip freeze
```

Ye output aayega:

```
asgiref==3.11.1
django==6.0.3
djangorestframework==3.16.1
sqlparse==0.5.5
tzdata==2025.3
```

---

**Ye kyun zaroori hai?**

Jab tum ye project kisi aur PC par chalana chahو ya GitHub par daalna chahو toh:

```bash
pip freeze > requirements.txt
```

Ye command sari packages `requirements.txt` mein save kar deti hai.

Doosra banda sirf ye chalayega:

```bash
pip install -r requirements.txt
```

Aur uske PC par bhi same packages install ho jaayengi.

---

Run karo aur output batao:

```bash
pip freeze > requirements.txt
```


ab jwt token ko install kero:
cmd : pip install djangorestframework-simplejwt


