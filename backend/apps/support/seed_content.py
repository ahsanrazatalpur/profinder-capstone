# apps/support/seed_content.py
#
# Starter content for the Privacy Policy and Help Center. DATA ONLY.
#
#  * The policy is a DRAFT with [PLACEHOLDER: ...] markers for facts only the
#    business can supply (legal entity, contact, retention, ...). It must be
#    reviewed (ideally by a legal reviewer) before publishing.
#  * Urdu is a working draft written by an AI assistant -> seeded with
#    is_reviewed=False, so users see English until a human reviews it.
#  * Statements about third parties describe what the CODE does today
#    (verified in the repository); re-check them whenever integrations change.
#
# Body format: '# Heading', '- bullet', blank-line separated paragraphs.

PLACEHOLDER_MARK = '[PLACEHOLDER'

POLICY_EN_TITLE = 'Privacy Policy'
POLICY_EN_BODY = """\
# Who we are
ProFinder is a marketplace app that helps customers find and book local service professionals in Pakistan. The service is operated by [PLACEHOLDER: LEGAL ENTITY NAME], [PLACEHOLDER: REGISTERED ADDRESS]. You can reach us at [PLACEHOLDER: SUPPORT EMAIL] or through Help & Support in the app.

# Information we collect
- Account details: your name, email address, phone number, gender, and the city, area and country you choose.
- Profile photo and, for professionals, profile and portfolio content.
- For professionals: identity and licence documents (such as CNIC or licence images) and bank details, used to verify your identity and professional status.
- Bookings, reviews and ratings you create or receive.
- Chat messages, voice messages and images you send in in-app chat.
- Search history and the profiles you view, used to improve search results and recommendations.
- Your device notification token and app language, so we can send notifications in your language.
- Location information that you allow the app to use, to show professionals near you.

# How we use your information
- To create and secure your account and sign you in.
- To show professionals to customers, and to let customers and professionals book, chat and review each other.
- To verify professionals and keep the marketplace safe, including handling reports and complaints.
- To send notifications about bookings, messages and announcements.
- To provide AI-assisted search and to improve the app.
- To respond to your support requests.

# Who can see your information
- Other users: professional profiles are visible to customers. When you make or receive a booking, the other party sees the details needed to complete it. Chat messages are visible to the people in that conversation.
- Our service providers, listed below, who process data on our behalf.
- Authorities or other parties where the law requires it.
We do not sell your personal information.

# Service providers we use
- Cloudinary: stores images you upload, such as profile photos and portfolio images.
- Firebase Cloud Messaging (Google): delivers push notifications to your device.
- Google Sign-In: lets you sign in with your Google account, if you choose to.
- Brevo: sends emails such as password-reset messages.
- Google Gemini: powers AI search and the translation of some app content. For AI search, the text you type and basic public listing details of professionals (such as name, rate, rating, availability and experience) are sent to Gemini. Your email address is not included.
- Our hosting and infrastructure providers, which store and process app data.

# Data retention
We keep your information for as long as your account is active and as long as needed for the purposes above. [PLACEHOLDER: RETENTION PERIOD AND WHAT HAPPENS AFTER ACCOUNT DELETION]

# Your choices and rights
- You can view and update most of your profile information in the app.
- You can control notifications and location permission in your device settings.
- To request a copy of your data or to delete your account, contact support through Help & Support in the app or at [PLACEHOLDER: SUPPORT EMAIL].

# Children
ProFinder is not intended for people under [PLACEHOLDER: MINIMUM AGE]. If you believe a child has given us personal information, contact us so we can remove it.

# Security
We use reasonable technical and organisational measures to protect your information. No online service can guarantee absolute security.

# Changes to this policy
We may update this policy. When we do, we publish the new version here with its effective date. If the changes are significant, we will tell you in the app.

# Governing law
This policy is governed by the laws of [PLACEHOLDER: GOVERNING LAW / JURISDICTION].

# Contact
Questions about this policy: [PLACEHOLDER: SUPPORT EMAIL].
"""

POLICY_UR_TITLE = 'رازداری کی پالیسی'
POLICY_UR_BODY = """\
# ہم کون ہیں
ProFinder ایک مارکیٹ پلیس ایپ ہے جو پاکستان میں صارفین کو مقامی سروس پروفیشنلز تلاش کرنے اور بُک کرنے میں مدد دیتی ہے۔ یہ سروس [PLACEHOLDER: LEGAL ENTITY NAME] چلاتی ہے، پتہ: [PLACEHOLDER: REGISTERED ADDRESS]۔ آپ ہم سے [PLACEHOLDER: SUPPORT EMAIL] پر یا ایپ میں مدد اور سپورٹ کے ذریعے رابطہ کر سکتے ہیں۔

# ہم کون سی معلومات جمع کرتے ہیں
- اکاؤنٹ کی تفصیلات: آپ کا نام، ای میل، فون نمبر، جنس، اور آپ کا منتخب کردہ شہر، علاقہ اور ملک۔
- پروفائل کی تصویر، اور پروفیشنلز کے لیے پروفائل اور پورٹ فولیو کا مواد۔
- پروفیشنلز کے لیے: شناختی اور لائسنس کے دستاویزات (جیسے شناختی کارڈ یا لائسنس کی تصاویر) اور بینک کی تفصیلات، جو آپ کی شناخت اور پیشہ ورانہ حیثیت کی تصدیق کے لیے استعمال ہوتی ہیں۔
- آپ کی بنائی ہوئی یا آپ کو ملنے والی بکنگز، ریویوز اور ریٹنگز۔
- ایپ کی چیٹ میں آپ کے بھیجے ہوئے پیغامات، وائس میسج اور تصاویر۔
- سرچ ہسٹری اور وہ پروفائلز جو آپ دیکھتے ہیں، تاکہ سرچ نتائج اور تجاویز بہتر ہوں۔
- آپ کے آلے کا نوٹیفکیشن ٹوکن اور ایپ کی زبان، تاکہ ہم آپ کی زبان میں نوٹیفکیشن بھیج سکیں۔
- مقام کی وہ معلومات جس کی آپ ایپ کو اجازت دیتے ہیں، تاکہ قریبی پروفیشنلز دکھائے جا سکیں۔

# ہم آپ کی معلومات کیسے استعمال کرتے ہیں
- آپ کا اکاؤنٹ بنانے، محفوظ رکھنے اور لاگ اِن کرانے کے لیے۔
- صارفین کو پروفیشنلز دکھانے، اور صارفین اور پروفیشنلز کو بکنگ، چیٹ اور ریویو کی سہولت دینے کے لیے۔
- پروفیشنلز کی تصدیق اور مارکیٹ پلیس کو محفوظ رکھنے کے لیے، بشمول رپورٹس اور شکایات کا جائزہ۔
- بکنگز، پیغامات اور اعلانات کے نوٹیفکیشن بھیجنے کے لیے۔
- اے آئی کی مدد سے سرچ فراہم کرنے اور ایپ کو بہتر بنانے کے لیے۔
- آپ کی سپورٹ درخواستوں کا جواب دینے کے لیے۔

# آپ کی معلومات کون دیکھ سکتا ہے
- دیگر صارفین: پروفیشنلز کی پروفائلز صارفین کو نظر آتی ہیں۔ بکنگ کرنے یا وصول کرنے پر دوسرے فریق کو وہ تفصیلات نظر آتی ہیں جو بکنگ مکمل کرنے کے لیے ضروری ہیں۔ چیٹ کے پیغامات صرف اس گفتگو کے شرکاء کو نظر آتے ہیں۔
- ہمارے سروس فراہم کنندگان (نیچے درج)، جو ہماری طرف سے ڈیٹا پروسیس کرتے ہیں۔
- حکام یا دیگر فریق، جہاں قانون اس کا تقاضا کرے۔
ہم آپ کی ذاتی معلومات فروخت نہیں کرتے۔

# ہم جن سروس فراہم کنندگان کو استعمال کرتے ہیں
- Cloudinary: آپ کی اپ لوڈ کی ہوئی تصاویر، جیسے پروفائل اور پورٹ فولیو کی تصاویر، محفوظ کرتا ہے۔
- Firebase Cloud Messaging (گوگل): آپ کے آلے تک پش نوٹیفکیشن پہنچاتا ہے۔
- Google Sign-In: اگر آپ چاہیں تو اپنے گوگل اکاؤنٹ سے لاگ اِن کی سہولت دیتا ہے۔
- Brevo: ای میلز بھیجتا ہے، جیسے پاس ورڈ ری سیٹ کے پیغامات۔
- Google Gemini: اے آئی سرچ اور ایپ کے کچھ مواد کے ترجمے کے لیے۔ اے آئی سرچ میں آپ کا لکھا ہوا متن اور پروفیشنلز کی بنیادی عوامی تفصیلات (جیسے نام، ریٹ، ریٹنگ، دستیابی اور تجربہ) Gemini کو بھیجی جاتی ہیں۔ آپ کا ای میل شامل نہیں ہوتا۔
- ہمارے ہوسٹنگ اور انفراسٹرکچر فراہم کنندگان، جو ایپ کا ڈیٹا محفوظ اور پروسیس کرتے ہیں۔

# ڈیٹا کی مدتِ برقراری
ہم آپ کی معلومات اس وقت تک رکھتے ہیں جب تک آپ کا اکاؤنٹ فعال ہے اور جب تک مذکورہ مقاصد کے لیے ضرورت ہو۔ [PLACEHOLDER: RETENTION PERIOD AND WHAT HAPPENS AFTER ACCOUNT DELETION]

# آپ کے اختیارات اور حقوق
- آپ ایپ میں اپنی زیادہ تر پروفائل معلومات دیکھ اور اپ ڈیٹ کر سکتے ہیں۔
- آپ نوٹیفکیشن اور مقام کی اجازت اپنے آلے کی سیٹنگز میں کنٹرول کر سکتے ہیں۔
- اپنے ڈیٹا کی کاپی لینے یا اکاؤنٹ ڈیلیٹ کرنے کے لیے ایپ میں مدد اور سپورٹ کے ذریعے یا [PLACEHOLDER: SUPPORT EMAIL] پر رابطہ کریں۔

# بچے
ProFinder [PLACEHOLDER: MINIMUM AGE] سال سے کم عمر افراد کے لیے نہیں ہے۔ اگر آپ کو لگے کہ کسی بچے نے ہمیں ذاتی معلومات دی ہیں تو ہم سے رابطہ کریں تاکہ ہم انہیں ہٹا سکیں۔

# سکیورٹی
ہم آپ کی معلومات کے تحفظ کے لیے مناسب تکنیکی اور انتظامی اقدامات کرتے ہیں۔ کوئی بھی آن لائن سروس مکمل تحفظ کی ضمانت نہیں دے سکتی۔

# اس پالیسی میں تبدیلیاں
ہم اس پالیسی کو اپ ڈیٹ کر سکتے ہیں۔ ایسا ہونے پر نیا ورژن مؤثر تاریخ کے ساتھ یہاں شائع کیا جائے گا۔ اہم تبدیلیوں کی صورت میں ہم ایپ میں آپ کو مطلع کریں گے۔

# قابلِ اطلاق قانون
یہ پالیسی [PLACEHOLDER: GOVERNING LAW / JURISDICTION] کے قوانین کے تحت ہے۔

# رابطہ
اس پالیسی کے بارے میں سوالات: [PLACEHOLDER: SUPPORT EMAIL]۔
"""

POLICY_CHANGE_SUMMARY = 'Initial version (draft)'

# slug -> (icon_key, audience, title, description)
HELP_CATEGORIES = [
    ('getting-started', 'rocket_launch', 'all', 'Getting started',
     'Create an account and find your way around.'),
    ('bookings', 'event', 'all', 'Bookings',
     'Booking, changing and cancelling services.'),
    ('professionals', 'work', 'professional', 'For professionals',
     'Profile, verification and managing your work.'),
    ('privacy-data', 'privacy_tip', 'all', 'Privacy & your data',
     'How your information is used and how to ask about it.'),
]

# slug -> (category slug, audience, title, body)
HELP_ARTICLES = [
    ('create-account', 'getting-started', 'all', 'How do I create an account?',
     'Open the app and choose Sign up.\n\n'
     '- Enter your name, email and a password, or continue with Google.\n'
     '- Choose whether you are a customer or a professional.\n'
     '- Check your email if the app asks you to confirm it.'),
    ('forgot-password', 'getting-started', 'all', 'I forgot my password',
     'On the login screen choose Forgot password and enter your email. '
     'We will email you a link to set a new password. If nothing arrives, check your spam folder.'),
    ('find-professional', 'getting-started', 'all', 'How do I find a professional?',
     'Use Search to look by profession, name or problem, or browse the categories on the home screen. '
     'Open a profile to see ratings, reviews and details before you book.'),
    ('make-booking', 'bookings', 'customer', 'How do I book a professional?',
     'Open the professional\'s profile and choose Book. Pick the details requested and confirm. '
     'You can follow the status of your request under My Bookings.'),
    ('cancel-booking', 'bookings', 'all', 'How do I cancel a booking?',
     'Open My Bookings, select the booking and choose Cancel. You may be asked for a reason.'),
    ('pro-verification', 'professionals', 'professional', 'How does professional verification work?',
     'Upload the identity and licence documents requested in your profile. '
     'Our team reviews them and updates your verification status.'),
    ('data-we-collect', 'privacy-data', 'all', 'What information does ProFinder collect?',
     'Please read the full Privacy Policy in the app (Settings > Privacy Policy) for the complete and current list.'),
    ('delete-account', 'privacy-data', 'all', 'How do I delete my account or get a copy of my data?',
     'Contact Support from Help & Support and choose the Privacy / data request category. '
     'We will confirm your identity and respond to your request.'),
]
