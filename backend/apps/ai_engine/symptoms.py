# apps/ai_engine/symptoms.py
#
# Maintainable symptom and problem to profession category mapping.
# Supports English, Urdu, Hindi, Arabic, French, Spanish, and Roman Urdu.
# Medical symptom matching is strictly for finding appropriate professional services,
# never for medical diagnosis or treatment advice.

SYMPTOM_TO_PROFESSION = {
    # ── Medical / Doctor / General Physician ──
    # English
    'fever': 'doctor',
    'high fever': 'doctor',
    'headache': 'doctor',
    'severe headache': 'doctor',
    'cough': 'doctor',
    'cold': 'doctor',
    'flu': 'doctor',
    'stomach pain': 'doctor',
    'stomach ache': 'doctor',
    'vomiting': 'doctor',
    'nausea': 'doctor',
    'infection': 'doctor',
    'body pain': 'doctor',
    'general physician': 'doctor',
    # Roman Urdu
    'bukhar': 'doctor',
    'bukhaar': 'doctor',
    'tez bukhar': 'doctor',
    'sar dard': 'doctor',
    'sir dard': 'doctor',
    'sardard': 'doctor',
    'pet dard': 'doctor',
    'pait dard': 'doctor',
    'ulti': 'doctor',
    'nazla': 'doctor',
    'zukam': 'doctor',
    'khansi': 'doctor',
    'khasi': 'doctor',
    'chakkar': 'doctor',
    'tabeeb': 'doctor',
    # Urdu
    'بخار': 'doctor',
    'تیز بخار': 'doctor',
    'سر درد': 'doctor',
    'پیٹ درد': 'doctor',
    'الٹی': 'doctor',
    'نزلا': 'doctor',
    'زکام': 'doctor',
    'کھانسی': 'doctor',
    'طبیب': 'doctor',
    # Hindi
    'बुखार': 'doctor',
    'तेज बुखार': 'doctor',
    'सिर दर्द': 'doctor',
    'पेट दर्द': 'doctor',
    'उल्टी': 'doctor',
    'जुकाम': 'doctor',
    'खांसी': 'doctor',
    # Arabic
    'حمى': 'doctor',
    'صداع': 'doctor',
    'ألم في المعدة': 'doctor',
    'سعال': 'doctor',
    'نزلة برد': 'doctor',
    'طبيب عام': 'doctor',
    # French
    'fièvre': 'doctor',
    'fievre': 'doctor',
    'maux de tête': 'doctor',
    'mal de tete': 'doctor',
    'mal de ventre': 'doctor',
    'toux': 'doctor',
    'rhume': 'doctor',
    # Spanish
    'fiebre': 'doctor',
    'dolor de cabeza': 'doctor',
    'dolor de estómago': 'doctor',
    'dolor de estomago': 'doctor',
    'tos': 'doctor',
    'gripe': 'doctor',

    # ── Dental / Dentist ──
    # English
    'tooth pain': 'dentist',
    'toothache': 'dentist',
    'tooth ache': 'dentist',
    'teeth pain': 'dentist',
    'gum pain': 'dentist',
    'swollen gum': 'dentist',
    'cavity': 'dentist',
    'bleeding gums': 'dentist',
    'root canal': 'dentist',
    'braces': 'dentist',
    'dental checkup': 'dentist',
    # Roman Urdu
    'dant dard': 'dentist',
    'daant dard': 'dentist',
    'dant me dard': 'dentist',
    'daant me dard': 'dentist',
    'dant mein dard': 'dentist',
    'daant mein dard': 'dentist',
    'danton ka dard': 'dentist',
    'masooron ka dard': 'dentist',
    'masooda': 'dentist',
    # Urdu
    'دانت میں درد': 'dentist',
    'دانت کا درد': 'dentist',
    'مسوڑھوں میں درد': 'dentist',
    'دانتوں کا درد': 'dentist',
    'دانتوں کا مسئلہ': 'dentist',
    # Hindi
    'दांत में दर्द': 'dentist',
    'दांत दर्द': 'dentist',
    'मसूड़ों में दर्द': 'dentist',
    'दांतों का दर्द': 'dentist',
    # Arabic
    'ألم في الأسنان': 'dentist',
    'الم في الاسنان': 'dentist',
    'ألم الأسنان': 'dentist',
    'الم الاسنان': 'dentist',
    'وجع اسنان': 'dentist',
    'وجع الأسنان': 'dentist',
    'نزيف اللثة': 'dentist',
    'تسوس الأسنان': 'dentist',
    # French
    'mal aux dents': 'dentist',
    'douleur dentaire': 'dentist',
    'saignement des gencives': 'dentist',
    'carie': 'dentist',
    # Spanish
    'dolor de muelas': 'dentist',
    'dolor de dientes': 'dentist',
    'dolor dental': 'dentist',
    'caries': 'dentist',
    'sangrado de encías': 'dentist',

    # ── Heart / Cardiologist ──
    # English
    'heart pain': 'cardiologist',
    'chest pain': 'cardiologist',
    'heart attack': 'cardiologist',
    'high blood pressure': 'cardiologist',
    'hypertension': 'cardiologist',
    'heart disease': 'cardiologist',
    # Roman Urdu
    'seene me dard': 'cardiologist',
    'seene mein dard': 'cardiologist',
    'dil ka dard': 'cardiologist',
    'dil ki bimari': 'cardiologist',
    # Urdu
    'سینے میں درد': 'cardiologist',
    'دل کا درد': 'cardiologist',
    'دل کا دورہ': 'cardiologist',
    'بلڈ پریشر': 'cardiologist',
    # Hindi
    'सीने में दर्द': 'cardiologist',
    'दिल का दर्द': 'cardiologist',
    'दिल का दौरा': 'cardiologist',
    # Arabic
    'ألم في الصدر': 'cardiologist',
    'الم في الصدر': 'cardiologist',
    'ألم القلب': 'cardiologist',
    'نوبة قلبية': 'cardiologist',
    'ضغط الدم': 'cardiologist',
    # French
    'douleur thoracique': 'cardiologist',
    'douleur au coeur': 'cardiologist',
    'crise cardiaque': 'cardiologist',
    # Spanish
    'dolor en el pecho': 'cardiologist',
    'dolor de corazón': 'cardiologist',
    'ataque al corazón': 'cardiologist',

    # ── Eye / Ophthalmologist ──
    # English
    'eye pain': 'ophthalmologist',
    'vision problem': 'ophthalmologist',
    'blurry vision': 'ophthalmologist',
    'cataract': 'ophthalmologist',
    'eye infection': 'ophthalmologist',
    # Roman Urdu
    'aankh me dard': 'ophthalmologist',
    'aankh mein dard': 'ophthalmologist',
    'nazar kamzor': 'ophthalmologist',
    # Urdu
    'آنکھ میں درد': 'ophthalmologist',
    'بینائی کا مسئلہ': 'ophthalmologist',
    'نظر کی کمزوری': 'ophthalmologist',
    # Hindi
    'आंख में दर्द': 'ophthalmologist',
    'धुंधला दिखना': 'ophthalmologist',
    # Arabic
    'ألم في العين': 'ophthalmologist',
    'تشوش الرؤية': 'ophthalmologist',
    'ضعف البصر': 'ophthalmologist',
    # French
    'mal aux yeux': 'ophthalmologist',
    'vision floue': 'ophthalmologist',
    # Spanish
    'dolor de ojos': 'ophthalmologist',
    'visión borrosa': 'ophthalmologist',

    # ── Skin / Dermatologist ──
    # English
    'skin rash': 'dermatologist',
    'skin allergy': 'dermatologist',
    'acne': 'dermatologist',
    'pimples': 'dermatologist',
    'eczema': 'dermatologist',
    # Roman Urdu
    'jild ka masla': 'dermatologist',
    'daane': 'dermatologist',
    'khujli': 'dermatologist',
    # Urdu
    'جلد کی الرجی': 'dermatologist',
    'خارش': 'dermatologist',
    'دانوں': 'dermatologist',
    # Hindi
    'त्वचा की एलर्जी': 'dermatologist',
    'खुजली': 'dermatologist',
    'मुंहासे': 'dermatologist',
    # Arabic
    'طفح جلدي': 'dermatologist',
    'حساسية جلدية': 'dermatologist',
    'حب الشباب': 'dermatologist',
    # French
    'éruption cutanée': 'dermatologist',
    'allergie cutanée': 'dermatologist',
    # Spanish
    'erupción cutánea': 'dermatologist',
    'alergia en la piel': 'dermatologist',

    # ── Bones / Physical Therapy / Orthopedic ──
    # English
    'back pain': 'physiotherapist',
    'joint pain': 'physiotherapist',
    'muscle pain': 'physiotherapist',
    'neck pain': 'physiotherapist',
    'knee pain': 'physiotherapist',
    # Roman Urdu
    'kamar dard': 'physiotherapist',
    'kamar me dard': 'physiotherapist',
    'ghutne me dard': 'physiotherapist',
    'joron ka dard': 'physiotherapist',
    # Urdu
    'کمر میں درد': 'physiotherapist',
    'کمر کا درد': 'physiotherapist',
    'جوڑوں کا درد': 'physiotherapist',
    'گھٹنوں میں درد': 'physiotherapist',
    # Hindi
    'कमर में दर्द': 'physiotherapist',
    'जोड़ों का दर्द': 'physiotherapist',
    'घुटने में दर्द': 'physiotherapist',
    # Arabic
    'ألم الظهر': 'physiotherapist',
    'ألم المفاصل': 'physiotherapist',
    'ألم الركبة': 'physiotherapist',
    # French
    'mal de dos': 'physiotherapist',
    'douleur articulaire': 'physiotherapist',
    # Spanish
    'dolor de espalda': 'physiotherapist',
    'dolor articular': 'physiotherapist',

    # ── Child / Pediatrician ──
    # English
    'child fever': 'pediatrician',
    'baby fever': 'pediatrician',
    'child sick': 'pediatrician',
    'baby sick': 'pediatrician',
    'child not eating': 'pediatrician',
    # Roman Urdu
    'bachay ko bukhar': 'pediatrician',
    'bacha beemar': 'pediatrician',
    # Urdu
    'بچے کو بخار': 'pediatrician',
    'بچہ بیمار': 'pediatrician',
    # Hindi
    'बच्चे को बुखार': 'pediatrician',
    # Arabic
    'حمى عند الأطفال': 'pediatrician',
    'طفل مريض': 'pediatrician',
    # French
    'bébé malade': 'pediatrician',
    'enfant malade': 'pediatrician',
    # Spanish
    'bebé enfermo': 'pediatrician',
    'niño enfermo': 'pediatrician',

    # ── Plumbing / Plumber ──
    # English
    'pipe leak': 'plumber',
    'leaking pipe': 'plumber',
    'water leak': 'plumber',
    'leaking tap': 'plumber',
    'clogged drain': 'plumber',
    'blocked drain': 'plumber',
    'toilet leak': 'plumber',
    'sink leak': 'plumber',
    'plumbing issue': 'plumber',
    'plumbing problem': 'plumber',
    # Roman Urdu
    'nalka kharab': 'plumber',
    'nalka leak': 'plumber',
    'pani ka pipe': 'plumber',
    'pipe phat gaya': 'plumber',
    'drain band': 'plumber',
    'toilet block': 'plumber',
    'pani leak': 'plumber',
    # Urdu
    'پائپ لیک': 'plumber',
    'نلکا خراب': 'plumber',
    'پانی کا پائپ': 'plumber',
    'نل ٹپک رہا ہے': 'plumber',
    'ڈرین بند': 'plumber',
    # Hindi
    'पाइप लीक': 'plumber',
    'नल खराब': 'plumber',
    'पानी का रिसाव': 'plumber',
    'नाली बंद': 'plumber',
    # Arabic
    'تسرب المياه': 'plumber',
    'تسرب الأنابيب': 'plumber',
    'انسداد المجاري': 'plumber',
    'صنبور يسرب': 'plumber',
    'مشكلة سباكة': 'plumber',
    # French
    'fuite d\'eau': 'plumber',
    'tuyau qui fuit': 'plumber',
    'évier bouché': 'plumber',
    'evier bouche': 'plumber',
    'problème de plomberie': 'plumber',
    # Spanish
    'fuga de agua': 'plumber',
    'tubería rota': 'plumber',
    'tuberia rota': 'plumber',
    'desagüe atascado': 'plumber',
    'problema de fontanería': 'plumber',

    # ── Electrical / Electrician ──
    # English
    'house wiring': 'electrician',
    'wiring issue': 'electrician',
    'wiring problem': 'electrician',
    'power outage': 'electrician',
    'electrical fault': 'electrician',
    'short circuit': 'electrician',
    'no electricity': 'electrician',
    'sparking': 'electrician',
    'light not working': 'electrician',
    'fan not working': 'electrician',
    'circuit breaker': 'electrician',
    # Roman Urdu
    'bijli kharab': 'electrician',
    'bijli ka masla': 'electrician',
    'wire kharab': 'electrician',
    'short circuit': 'electrician',
    'bijli chali gayi': 'electrician',
    'switch kharab': 'electrician',
    'pankha kharab': 'electrician',
    # Urdu
    'بجلی خراب': 'electrician',
    'بجلی کا مسئلہ': 'electrician',
    'شارٹ سرکٹ': 'electrician',
    'تاریں خراب': 'electrician',
    'پنکھا خراب': 'electrician',
    # Hindi
    'बिजली खराब': 'electrician',
    'शॉर्ट सर्किट': 'electrician',
    'बिजली का तार': 'electrician',
    'पंखा खराब': 'electrician',
    # Arabic
    'ماس كهربائي': 'electrician',
    'مشكلة كهربائية': 'electrician',
    'انقطاع الكهرباء': 'electrician',
    'عطل كهربائي': 'electrician',
    # French
    'court-circuit': 'electrician',
    'panne de courant': 'electrician',
    'problème électrique': 'electrician',
    'panne electrique': 'electrician',
    # Spanish
    'cortocircuito': 'electrician',
    'fallo eléctrico': 'electrician',
    'fallo electrico': 'electrician',
    'corte de luz': 'electrician',
    'problema eléctrico': 'electrician',

    # ── Legal / Lawyer ──
    # English
    'legal notice': 'lawyer',
    'legal issue': 'lawyer',
    'legal problem': 'lawyer',
    'legal dispute': 'lawyer',
    'court case': 'lawyer',
    'property dispute': 'lawyer',
    'divorce case': 'lawyer',
    'bail': 'lawyer',
    'contract dispute': 'lawyer',
    # Roman Urdu
    'adalat ka case': 'lawyer',
    'kanooni masla': 'lawyer',
    'talaq ka case': 'lawyer',
    'property ka masla': 'lawyer',
    'zamanat': 'lawyer',
    # Urdu
    'عدالتی کیس': 'lawyer',
    'قانونی مسئلہ': 'lawyer',
    'طلاق کا کیس': 'lawyer',
    'جائیداد کا تنازعہ': 'lawyer',
    'ضمانت': 'lawyer',
    # Hindi
    'कोर्ट केस': 'lawyer',
    'कानूनी मामला': 'lawyer',
    'तलाक का केस': 'lawyer',
    'जमानत': 'lawyer',
    # Arabic
    'قضية محكمة': 'lawyer',
    'نزاع قانوني': 'lawyer',
    'استشارة قانونية': 'lawyer',
    'طلاق': 'lawyer',
    'كفالة': 'lawyer',
    # French
    'procès': 'lawyer',
    'litige juridique': 'lawyer',
    'divorce': 'lawyer',
    'problème juridique': 'lawyer',
    # Spanish
    'caso judicial': 'lawyer',
    'disputa legal': 'lawyer',
    'divorcio': 'lawyer',
    'problema legal': 'lawyer',

    # ── Tech / Computer Technician ──
    # English
    'broken laptop': 'computer technician',
    'laptop repair': 'computer technician',
    'computer not working': 'computer technician',
    'computer crashed': 'computer technician',
    'pc crashed': 'computer technician',
    'virus in pc': 'computer technician',
    'screen broken': 'computer technician',
    # Roman Urdu
    'laptop kharab': 'computer technician',
    'computer kharab': 'computer technician',
    'pc kharab': 'computer technician',
    # Urdu
    'لیپ ٹاپ خراب': 'computer technician',
    'کمپیوٹر خراب': 'computer technician',
    'لیپ ٹاپ مرمت': 'computer technician',
    # Hindi
    'लैपटॉप खराब': 'computer technician',
    'कंप्यूटर खराब': 'computer technician',
    # Arabic
    'إصلاح الكمبيوتر': 'computer technician',
    'لابتوب معطل': 'computer technician',
    'حاسوب معطل': 'computer technician',
    # French
    'ordinateur en panne': 'computer technician',
    'réparation ordinateur': 'computer technician',
    # Spanish
    'ordenador roto': 'computer technician',
    'reparación de portátiles': 'computer technician',

    # ── Education / Tutors ──
    # English
    'math tutor': 'tutor',
    'maths tutor': 'tutor',
    'physics tutor': 'tutor',
    'chemistry tutor': 'tutor',
    'biology tutor': 'tutor',
    'english tutor': 'tutor',
    'home tuition': 'tutor',
    'exam preparation': 'tutor',
    'test preparation': 'tutor',
    'need a teacher': 'tutor',
    'math help': 'tutor',
    # Roman Urdu
    'parhai me masla': 'tutor',
    'parhai mein masla': 'tutor',
    'tutor chahiye': 'tutor',
    'teacher chahiye': 'tutor',
    'home tutor': 'tutor',
    'bachon ki parhai': 'tutor',
    # Urdu
    'پڑھائی کا مسئلہ': 'tutor',
    'ہوم ٹیوشن': 'tutor',
    'امتحان کی تیاری': 'tutor',
    'ٹیوٹر چاہیے': 'tutor',
    # Hindi
    'पढ़ाई में मदद': 'tutor',
    'ट्यूशन चाहिए': 'tutor',
    'परीक्षा की तैयारी': 'tutor',
    # Arabic
    'دروس خصوصية': 'tutor',
    'مساعدة في الدراسة': 'tutor',
    'معلم خصوصي': 'tutor',
    # French
    'cours particuliers': 'tutor',
    'soutien scolaire': 'tutor',
    'aide aux devoirs': 'tutor',
    # Spanish
    'clases particulares': 'tutor',
    'apoyo escolar': 'tutor',
    'profesor particular': 'tutor',

    # ── Auto / Mechanics ──
    # English
    'car breakdown': 'mechanic',
    'car not starting': 'mechanic',
    'engine problem': 'mechanic',
    'engine issue': 'mechanic',
    'flat tire': 'mechanic',
    'flat tyre': 'mechanic',
    'brake failure': 'mechanic',
    'brake problem': 'mechanic',
    'car repair': 'mechanic',
    'auto repair': 'mechanic',
    # Roman Urdu
    'gari kharab': 'mechanic',
    'car kharab': 'mechanic',
    'gari start nahi ho rahi': 'mechanic',
    'engine kharab': 'mechanic',
    'puncture': 'mechanic',
    # Urdu
    'گاڑی خراب': 'mechanic',
    'انجن کا مسئلہ': 'mechanic',
    'گاڑی سٹارٹ نہیں ہو رہی': 'mechanic',
    'گاڑی کی مرمت': 'mechanic',
    # Hindi
    'गाड़ी खराब': 'mechanic',
    'इंजन खराब': 'mechanic',
    'गाड़ी चालू नहीं हो रही': 'mechanic',
    # Arabic
    'عطل في السيارة': 'mechanic',
    'السيارة لا تعمل': 'mechanic',
    'مشكلة في المحرك': 'mechanic',
    'إصلاح السيارات': 'mechanic',
    # French
    'panne de voiture': 'mechanic',
    'voiture en panne': 'mechanic',
    'problème moteur': 'mechanic',
    'réparation auto': 'mechanic',
    # Spanish
    'coche averiado': 'mechanic',
    'avería del coche': 'mechanic',
    'el coche no arranca': 'mechanic',
    'problema de motor': 'mechanic',

    # ── Furniture / Carpentry ──
    # English
    'broken furniture': 'carpenter',
    'door repair': 'carpenter',
    'door stuck': 'carpenter',
    'table repair': 'carpenter',
    'chair repair': 'carpenter',
    'cabinet repair': 'carpenter',
    'woodwork problem': 'carpenter',
    # Roman Urdu
    'darwaza kharab': 'carpenter',
    'furniture kharab': 'carpenter',
    'mez kharab': 'carpenter',
    'kursi toot gayi': 'carpenter',
    # Urdu
    'فرنیچر کی مرمت': 'carpenter',
    'دروازہ خراب': 'carpenter',
    'لکڑی کا کام': 'carpenter',
    # Hindi
    'फर्नीचर खराब': 'carpenter',
    'दरवाजा खराब': 'carpenter',
    'लकड़ी का काम': 'carpenter',
    # Arabic
    'إصلاح الأثاث': 'carpenter',
    'باب معطل': 'carpenter',
    'أعمال نجارة': 'carpenter',
    # French
    'meuble cassé': 'carpenter',
    'porte coincée': 'carpenter',
    'réparation meuble': 'carpenter',
    # Spanish
    'mueble roto': 'carpenter',
    'puerta atascada': 'carpenter',
    'reparación de muebles': 'carpenter',

    # ── Cleaning / Housekeeping ──
    # English
    'house cleaning': 'cleaner',
    'deep cleaning': 'cleaner',
    'office cleaning': 'cleaner',
    'home cleaning': 'cleaner',
    'sofa cleaning': 'cleaner',
    'carpet cleaning': 'cleaner',
    # Roman Urdu
    'ghar ki safai': 'cleaner',
    'safai karwani hai': 'cleaner',
    'office ki safai': 'cleaner',
    # Urdu
    'گھر کی صفائی': 'cleaner',
    'صفائی سروس': 'cleaner',
    'دفتر کی صفائی': 'cleaner',
    # Hindi
    'घर की सफाई': 'cleaner',
    'सफाई सेवा': 'cleaner',
    # Arabic
    'تنظيف المنزل': 'cleaner',
    'تنظيف شامل': 'cleaner',
    'خدمة تنظيف': 'cleaner',
    # French
    'nettoyage maison': 'cleaner',
    'ménage à domicile': 'cleaner',
    'nettoyage de bureaux': 'cleaner',
    # Spanish
    'limpieza de casa': 'cleaner',
    'limpieza del hogar': 'cleaner',
    'limpieza de oficinas': 'cleaner',
}


_EMERGENCY_PHRASES = [
    # English
    'heart attack', 'severe chest pain', 'chest pain', 'cannot breathe',
    'difficulty breathing', 'heavy bleeding', 'stroke', 'unconscious',
    'overdose', 'poisoning', 'choking', 'convulsions', 'severe burn',
    # Roman Urdu
    'dil ka daura', 'dil ka dora', 'saans nahi aa rahi', 'sans nahi aa rahi',
    'behosh', 'khoon beh raha hai', 'khoon nahi ruk raha',
    # Urdu
    'دل کا دورہ', 'سینے میں شدید درد', 'سانس نہیں آ رہی', 'بے ہوش', 'شدید خون',
    # Hindi
    'दिल का दौरा', 'सांस नहीं आ रही', 'बेहोश', 'भारी रक्तस्राव',
    # Arabic
    'نوبة قلبية', 'صعوبة في التنفس', 'فقدان الوعي', 'نزيف حاد',
    # French
    'crise cardiaque', 'difficulté à respirer', 'inconscient', 'hémorragie',
    # Spanish
    'ataque cardíaco', 'ataque cardiaco', 'dificultad para respirar', 'inconsciente', 'hemorragia grave',
]


def is_medical_emergency(text: str) -> bool:
    """Detects life-threatening symptoms requiring immediate emergency services guidance."""
    if not text:
        return False
    lower = text.lower()
    return any(p in lower for p in _EMERGENCY_PHRASES)


def find_profession_from_symptoms(text: str) -> str | None:
    """
    Scans free text for known symptom/problem phrases and returns
    the canonical profession or None. Longer phrases are checked first.
    """
    pro, _ = find_symptom_detail(text)
    return pro


def find_symptom_detail(text: str) -> tuple[str | None, str | None]:
    """
    Scans free text for known symptom/problem phrases and returns
    (canonical_profession, matched_phrase) or (None, None).
    Longer phrases are checked first.
    """
    if not text:
        return None, None
    lower = text.lower()
    for phrase in sorted(SYMPTOM_TO_PROFESSION.keys(), key=len, reverse=True):
        if phrase in lower:
            return SYMPTOM_TO_PROFESSION[phrase], phrase
    return None, None

