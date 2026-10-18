# apps/search/alias_seed.py
#
# Built-in profession aliases: canonical English profession -> words people
# type for it in other languages / scripts. This is only the SEED; spelling
# variants are handled by the phonetic matcher (aliases.py), so you do not list
# every spelling (wakeel/vakeel/wkil are all covered by one entry), and more
# aliases can be added from the admin panel (SearchAlias) or generated with
# `python manage.py generate_aliases`. Multi-word aliases are allowed.

SEED_ALIASES = {
    'doctor': [
        'ڈاکٹر', 'daktar', 'daactar', 'طبيب', 'دكتور', 'طبیب',
        'डॉक्टर', 'चिकित्सक', 'डाक्टर',
        'docteur', 'médecin', 'medecin', 'médico', 'medico', 'doctora',
    ],
    'dentist': [
        'ڈینٹسٹ', 'دندان ساز', 'daant', 'dant', 'danton ka doctor',
        'डेंटिस्ट', 'दंत चिकित्सक', 'दंतवैद्य',
        'طبيب أسنان', 'طبيب اسنان', 'dentiste', 'dentista', 'odontólogo', 'odontologo',
    ],
    'nurse': [
        'نرس', 'नर्स', 'ممرضة', 'ممرض',
        'infirmier', 'infirmière', 'infirmiere', 'enfermera', 'enfermero',
    ],
    'pharmacist': [
        'فارماسسٹ', 'دوا ساز', 'फार्मासिस्ट', 'औषध विक्रेता', 'صيدلي', 'صيدلاني',
        'pharmacien', 'pharmacienne', 'farmacéutico', 'farmaceutico', 'farmacéutica',
    ],
    'lawyer': [
        'وکیل', 'wakeel', 'vakeel', 'wakil', 'vakil', 'kanoon daan',
        'वकील', 'अधिवक्ता',
        'محامي', 'محامٍ', 'محام', 'مستشار قانوني',
        'avocat', 'avocate', 'juriste', 'abogado', 'abogada', 'letrado',
    ],
    'engineer': [
        'انجینئر', 'injiniyar', 'इंजीनियर', 'अभियंता', 'अभियन्ता',
        'مهندس', 'مهندسة',
        'ingénieur', 'ingenieur', 'ingénieure', 'ingeniero', 'ingeniera',
    ],
    'architect': [
        'آرکیٹیکٹ', 'आर्किटेक्ट', 'वास्तुकार',
        'مهندس معماري', 'معماري',
        'architecte', 'arquitecto', 'arquitecta',
    ],
    'electrician': [
        'الیکٹریشن', 'bijli', 'bijli wala',
        'बिजली मिस्त्री', 'इलेक्ट्रीशियन', 'बिजलीवाला',
        'كهربائي', 'فني كهرباء',
        'électricien', 'electricien', 'électricienne', 'electricista',
    ],
    'plumber': [
        'پلمبر', 'nalka', 'nalki', 'nalka wala',
        'प्लम्बर', 'प्लंबर', 'नलसाज़', 'नलसाज',
        'سباك', 'فني صحي',
        'plombier', 'plombière', 'fontanero', 'fontanera', 'plomero', 'plomera',
    ],
    'mechanic': [
        'مکینک', 'mistri', 'mistari', 'gari ka mistri',
        'मैकेनिक', 'मिस्त्री',
        'ميكانيكي', 'فني سيارات',
        'mécanicien', 'mecanicien', 'mécanicienne', 'garagiste', 'mecánico', 'mecanico', 'mecánica',
    ],
    'carpenter': [
        'بڑھئی', 'barhai', 'बढ़ई', 'काष्ठकार',
        'نجار',
        'charpentier', 'menuisier', 'carpintero', 'carpintera',
    ],
    'painter': [
        'پینٹر', 'رنگ ساز', 'rangsaz', 'rang saz',
        'पेंटर', 'रंगसाज', 'चित्रकार',
        'دهان', 'صباغ',
        'peintre', 'pintor', 'pintora',
    ],
    'tailor': [
        'درزی', 'darzi', 'दर्जी', 'दर्ज़ी',
        'خياط', 'خياطة',
        'tailleur', 'couturier', 'couturière', 'couturiere', 'sastre', 'modista',
    ],
    'barber': [
        'حجام', 'hajam', 'nai', 'naai',
        'नाई', 'हज्जाम',
        'حلاق', 'مصفف شعر',
        'coiffeur', 'barbier', 'coiffeuse', 'barbero', 'peluquero', 'peluquera',
    ],
    'teacher': [
        'ٹیچر', 'استاد', 'ustaad', 'ustad', 'muallim',
        'shikshak', 'टीचर', 'शिक्षक', 'अध्यापक', 'अध्यापिका',
        'معلم', 'مدرس', 'أستاذ', 'استاذ',
        'professeur', 'enseignant', 'enseignante', 'maestro', 'maestra', 'profesor', 'profesora',
    ],
    'tutor': [
        'ٹیوٹر', 'ٹیشن', 'ट्यूटर', 'tuteur', 'tutrice', 'tutor', 'tutora',
    ],
    'accountant': [
        'اکاؤنٹنٹ', 'حساب دان', 'munshi',
        'अकाउंटेंट', 'मुंशी', 'लेखाकार',
        'محاسب', 'مدقق حسابات',
        'comptable', 'expert-comptable', 'contador', 'contadora', 'contable',
    ],
    'developer': [
        'ڈویلپر', 'پروگرامر',
        'डेवलपर', 'प्रोग्रामर',
        'مطور', 'مبرمج', 'مطور برمجيات',
        'développeur', 'developpeur', 'développeuse', 'programmeur', 'desarrollador', 'desarrolladora', 'programador',
    ],
    'designer': [
        'ڈیزائنر', 'डिज़ाइनर', 'डिजाइनर',
        'مصمم', 'مصممة', 'مصمم جرافيك',
        'designer', 'graphiste', 'concepteur', 'diseñador', 'disenador', 'diseñadora',
    ],
    'photographer': [
        'فوٹوگرافر', 'عکاس',
        'फोटोग्राफर', 'छायाकार',
        'مصور', 'مصورة',
        'photographe', 'cameraman', 'fotógrafo', 'fotografo', 'fotógrafa',
    ],
    'chef': [
        'باورچی', 'bawarchi', 'khansama',
        'रसोइया', 'बावर्ची', 'शेफ',
        'طباخ', 'شيف', 'طاهٍ', 'طاه',
        'cuisinier', 'cuisinière', 'chef', 'cocinero', 'cocinera',
    ],
    'driver': [
        'ڈرائیور', 'ड्राइवर', 'चालक',
        'سائق', 'شوفير',
        'chauffeur', 'conducteur', 'conductrice', 'conductor', 'conductora', 'chofer', 'chófer',
    ],
    'cleaner': [
        'کلینر', 'صفائی والا', 'safai wala',
        'क्लीनर', 'सफाईकर्मी', 'सफाईवाला',
        'عامل نظافة', 'عاملة نظافة',
        'nettoyeur', 'nettoyeuse', 'agent de ménage', 'limpiador', 'limpiadora',
    ],
    'veterinarian': [
        'ویٹرنری', 'جانوروں کا ڈاکٹر',
        'पशु चिकित्सक', 'वेटरनरी',
        'بيطري', 'طبيب بيطري',
        'vétérinaire', 'veterinaire', 'veterinario', 'veterinaria',
    ],
    'physiotherapist': [
        'فزیوتھراپسٹ',
        'फिजियोथेरेपिस्ट', 'भौतिक चिकित्सक',
        'معالج طبيعي', 'أخصائي علاج طبيعي',
        'kinésithérapeute', 'kinesitherapeute', 'kiné', 'fisioterapeuta', 'fisio',
    ],
    'psychologist': [
        'سائیکالوجسٹ', 'ماہر نفسیات',
        'मनोवैज्ञानिक', 'मनोचिकित्सक',
        'أخصائي نفسي', 'طبيب نفسي', 'معالج نفسي',
        'psychologue', 'thérapeute', 'psicólogo', 'psicologo', 'psicóloga', 'terapeuta',
    ],
    'welder': [
        'ویلڈر', 'वेल्डर', 'لحام', 'soudeur', 'soldador', 'soldadora',
    ],
    'mason': [
        'راج مستری', 'معمار', 'raj mistri',
        'राजमिस्त्री', 'معمار',
        'maçon', 'macon', 'albañil', 'albanil',
    ],
}

# ── City Aliases (Multi-script: Urdu, Hindi, Arabic, English variations) ─────
CITY_ALIASES = {
    # Karachi
    'کراچی': 'karachi', 'करांची': 'karachi', 'कराची': 'karachi', 'كراجي': 'karachi', 'carachi': 'karachi', 'khi': 'karachi',
    # Lahore
    'لاہور': 'lahore', 'लाहौर': 'lahore', 'لاهور': 'lahore', 'lhr': 'lahore',
    # Islamabad
    'اسلام آباد': 'islamabad', 'اسلام اباد': 'islamabad', 'इस्लामाबाद': 'islamabad', 'إسلام آباد': 'islamabad', 'isb': 'islamabad',
    # Rawalpindi
    'راولپنڈی': 'rawalpindi', 'रावलपिंडी': 'rawalpindi', 'راولبندي': 'rawalpindi', 'pindi': 'rawalpindi',
    # Faisalabad
    'فیصل آباد': 'faisalabad', 'فیصل اباد': 'faisalabad', 'फैसलाबाद': 'faisalabad', 'lyallpur': 'faisalabad',
    # Multan
    'ملتان': 'multan', 'मुल्तान': 'multan',
    # Peshawar
    'پشاور': 'peshawar', 'पेशावर': 'peshawar', 'بيشاور': 'peshawar',
    # Quetta
    'کوئٹہ': 'quetta', 'क्वेटा': 'quetta',
    # Hyderabad
    'حیدرآباد': 'hyderabad', 'حیدر اباد': 'hyderabad', 'हैदराबाद': 'hyderabad',
    # Gujranwala
    'گوجرانوالہ': 'gujranwala', 'गुजरांवाला': 'gujranwala',
    # Sialkot
    'سیالکوٹ': 'sialkot', 'सियालकोट': 'sialkot',
    # Sukkur
    'سکھر': 'sukkur', 'सक्खर': 'sukkur',
    # Larkana
    'لاڑکانہ': 'larkana', 'لارکانا': 'larkana', 'लरकाना': 'larkana',
    # Badin
    'بدین': 'badin', 'बदीन': 'badin',
    # Thatta
    'ٹھٹھہ': 'thatta', 'ठट्ठा': 'thatta',
    # Abbottabad
    'ایبٹ آباد': 'abbottabad', 'ऐबटाबाद': 'abbottabad',
}
