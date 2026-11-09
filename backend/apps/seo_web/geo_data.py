"""
Geographic & SEO reference dataset for ProFinder.
Maps Pakistan provinces, administrative divisions, canonical city slugs,
and category/profession SEO keywords.
"""

PROVINCES = {
    'sindh': {
        'name': 'Sindh',
        'urdu': 'سندھ',
        'capital': 'Karachi',
        'cities': [
            'karachi', 'badin', 'hyderabad', 'sukkur', 'larkana', 'mirpurkhas',
            'nawabshah', 'thatta', 'dadu', 'matli', 'talhar', 'tando-bago',
            'golarchi', 'jamshoro', 'umerkot', 'sanghar', 'shaheed-fazil-rahu',
            'jacobabad', 'shikarpur', 'khairpur', 'ghotki', 'nindo-shahar',
            'kadhan', 'tando-ghulam-ali'
        ],
        'description': 'Discover verified doctors, lawyers, engineers, plumbers, and local home service specialists across Sindh, Pakistan.'
    },
    'punjab': {
        'name': 'Punjab',
        'urdu': 'پنجاب',
        'capital': 'Lahore',
        'cities': [
            'lahore', 'faisalabad', 'rawalpindi', 'multan', 'gujranwala', 'sialkot',
            'bahawalpur', 'sargodha', 'sahiwal', 'okara', 'attock', 'chakwal',
            'chiniot', 'jhang', 'rahim-yar-khan', 'kasur', 'gujrat', 'sheikhupura',
            'dera-ghazi-khan', 'mianwali', 'bhakkar'
        ],
        'description': 'Find trusted, top-rated professional services and skilled technicians across Punjab, Pakistan.'
    },
    'khyber-pakhtunkhwa': {
        'name': 'Khyber Pakhtunkhwa',
        'urdu': 'خیبر پختونخوا',
        'capital': 'Peshawar',
        'cities': [
            'peshawar', 'abbottabad', 'mardan', 'bannu', 'swat', 'kohat',
            'charsadda', 'dera-ismail-khan', 'batkhela', 'chitral', 'haripur',
            'mansehra', 'nowshera', 'swabi'
        ],
        'description': 'Connect with qualified doctors, home repair experts, tutors, and technical professionals across Khyber Pakhtunkhwa.'
    },
    'balochistan': {
        'name': 'Balochistan',
        'urdu': 'بلوچستان',
        'capital': 'Quetta',
        'cities': [
            'quetta', 'gwadar', 'turbat', 'khuzdar', 'chaman', 'dera-bugti',
            'sibi', 'zhob', 'loralai', 'hub'
        ],
        'description': 'Access verified professional services and skilled specialists across Balochistan, Pakistan.'
    },
    'islamabad-capital-territory': {
        'name': 'Islamabad Capital Territory',
        'urdu': 'اسلام آباد',
        'capital': 'Islamabad',
        'cities': ['islamabad'],
        'description': 'Hire reliable, background-checked professional service providers in the federal capital Islamabad.'
    },
    'gilgit-baltistan': {
        'name': 'Gilgit-Baltistan',
        'urdu': 'گلگت بلتستان',
        'capital': 'Gilgit',
        'cities': ['gilgit', 'skardu', 'hunza', 'ghizer', 'diamer', 'nagar', 'astore', 'kharmang', 'shigar'],
        'description': 'Connect with verified professional services, technicians, and specialists across Gilgit-Baltistan.'
    },
    'azad-jammu-and-kashmir': {
        'name': 'Azad Jammu and Kashmir',
        'urdu': 'آزاد جموں و کشمیر',
        'capital': 'Muzaffarabad',
        'cities': ['muzaffarabad', 'mirpur', 'rawalakot', 'kotli', 'bhimber', 'bagh', 'pallandri', 'neelum'],
        'description': 'Find trusted, top-rated local professionals and certified home services across Azad Jammu and Kashmir.'
    },
}

# Reverse mapping city slug -> province slug
CITY_TO_PROVINCE = {}
for prov_slug, prov_data in PROVINCES.items():
    for c_slug in prov_data['cities']:
        CITY_TO_PROVINCE[c_slug] = prov_slug

# Standard fallback province for unmapped Pakistan cities
DEFAULT_PROVINCE = 'sindh'

# Common canonical profession mappings (profession slug -> category name & search keywords)
PROFESSION_MAPPINGS = {
    'doctors': {
        'name': 'Doctors & Medical Specialists',
        'singular': 'Doctor',
        'urdu': 'ڈاکٹرز اور معالجین',
        'category_name': 'Doctors & Healthcare',
        'popular_services': ['Clinic Consultation', 'General Medicine', 'Online Medical Advice', 'Pediatric Care', 'Dental Care'],
    },
    'electricians': {
        'name': 'Electricians & Electrical Contractors',
        'singular': 'Electrician',
        'urdu': 'الیکٹریشن اور برقی ماہرین',
        'category_name': 'Electricians',
        'popular_services': ['Wiring Repair', 'UPS and Generator Installation', 'Circuit Breaker Fix', 'Ceiling Fan Installation', 'Solar Panel Wiring'],
    },
    'plumbers': {
        'name': 'Plumbers & Sanitary Experts',
        'singular': 'Plumber',
        'urdu': 'پلمبر اور سینیٹری سروسز',
        'category_name': 'Plumbers',
        'popular_services': ['Pipe Leak Repair', 'Water Motor Installation', 'Bathroom Fitting', 'Drain Unblocking', 'Water Tank Cleaning'],
    },
    'lawyers': {
        'name': 'Lawyers & Legal Advocates',
        'singular': 'Lawyer',
        'urdu': 'وکلاء اور قانونی مشیر',
        'category_name': 'Lawyers & Legal',
        'popular_services': ['Civil Law', 'Property Consultation', 'Corporate Legal Services', 'Family Law & Documentation'],
    },
    'engineers': {
        'name': 'Engineers & Technical Consultants',
        'singular': 'Engineer',
        'urdu': 'انجینئرز اور تکنیکی ماہرین',
        'category_name': 'Engineers',
        'popular_services': ['Civil Engineering', 'Structural Inspection', 'Electrical Design', 'Project Supervision'],
    },
    'tutors': {
        'name': 'Home Tutors & Education Specialists',
        'singular': 'Tutor',
        'urdu': 'ہوم ٹیوٹرز اور اساتذہ',
        'category_name': 'Tutors & Education',
        'popular_services': ['Matric and Inter Coaching', 'O and A Level Tutoring', 'English Language Classes', 'Math and Science Tuition'],
    },
    'cleaners': {
        'name': 'Home & Office Cleaners',
        'singular': 'Cleaner',
        'urdu': 'صفائی اور ڈیپ کلیننگ سروسز',
        'category_name': 'Cleaners',
        'popular_services': ['Home Deep Cleaning', 'Sofa and Carpet Wash', 'Water Tank Cleaning', 'Office Sanitization'],
    },
    'carpenters': {
        'name': 'Carpenters & Woodwork Craftsmen',
        'singular': 'Carpenter',
        'urdu': 'بڑھئی اور فرنیچر ساز',
        'category_name': 'Carpenter',
        'popular_services': ['Furniture Repair', 'Door and Window Fitting', 'Custom Wardrobes', 'Kitchen Cabinet Making'],
    },
    'architects': {
        'name': 'Architects & Interior Designers',
        'singular': 'Architect',
        'urdu': 'ماہر تعمیرات اور ڈیزائنرز',
        'category_name': 'Architects',
        'popular_services': ['House Planning and Map Design', 'Interior Designing', '3D Architectural Renderings', 'Renovation Advisory'],
    },
    'it-experts': {
        'name': 'IT & Software Experts',
        'singular': 'IT Expert',
        'urdu': 'آئی ٹی اور سافٹ ویئر ماہرین',
        'category_name': 'IT & Tech',
        'popular_services': ['Web Development', 'Computer Hardware Repair', 'Networking Setup', 'Mobile App Development'],
    },
}
