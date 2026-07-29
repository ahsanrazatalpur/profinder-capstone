// lib/core/constants/country_flags.dart
//
// Maps a country's display name (as stored in the backend's Country model)
// to its ISO 3166-1 alpha-2 code, so the Register screen can show a flag
// next to each country without needing an ISO-code column on that model.
// Lookup is case-insensitive; unknown names fall back to a globe icon in
// the UI — cosmetic only, never blocks registration.

class CountryFlags {
  CountryFlags._();

  static String? isoCodeFor(String countryName) =>
      _isoByName[countryName.trim().toLowerCase()];

  // ISO 3166-1 alpha-2 (e.g. "PK") -> flag emoji via Regional Indicators.
  static String emojiFor(String iso2) {
    final upper = iso2.toUpperCase();
    if (upper.length != 2) return '🏳️';
    const base = 0x1F1E6;
    final first  = base + (upper.codeUnitAt(0) - 65);
    final second = base + (upper.codeUnitAt(1) - 65);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  static String? flagFor(String countryName) {
    final iso = isoCodeFor(countryName);
    return iso == null ? null : emojiFor(iso);
  }

  static const Map<String, String> _isoByName = {
    'afghanistan':'AF','albania':'AL','algeria':'DZ','andorra':'AD','angola':'AO',
    'argentina':'AR','armenia':'AM','australia':'AU','austria':'AT','azerbaijan':'AZ',
    'bahamas':'BS','bahrain':'BH','bangladesh':'BD','barbados':'BB','belarus':'BY',
    'belgium':'BE','belize':'BZ','benin':'BJ','bhutan':'BT','bolivia':'BO',
    'bosnia and herzegovina':'BA','botswana':'BW','brazil':'BR','brunei':'BN',
    'bulgaria':'BG','burkina faso':'BF','burundi':'BI','cambodia':'KH','cameroon':'CM',
    'canada':'CA','chad':'TD','chile':'CL','china':'CN','colombia':'CO','comoros':'KM',
    'costa rica':'CR','croatia':'HR','cuba':'CU','cyprus':'CY','czech republic':'CZ',
    'czechia':'CZ','denmark':'DK','djibouti':'DJ','dominica':'DM',
    'dominican republic':'DO','ecuador':'EC','egypt':'EG','el salvador':'SV',
    'equatorial guinea':'GQ','eritrea':'ER','estonia':'EE','eswatini':'SZ',
    'ethiopia':'ET','fiji':'FJ','finland':'FI','france':'FR','gabon':'GA',
    'gambia':'GM','georgia':'GE','germany':'DE','ghana':'GH','greece':'GR',
    'grenada':'GD','guatemala':'GT','guinea':'GN','guinea-bissau':'GW','guyana':'GY',
    'haiti':'HT','honduras':'HN','hong kong':'HK','hungary':'HU','iceland':'IS',
    'india':'IN','indonesia':'ID','iran':'IR','iraq':'IQ','ireland':'IE',
    'israel':'IL','italy':'IT','ivory coast':'CI',"cote d'ivoire":'CI','jamaica':'JM',
    'japan':'JP','jordan':'JO','kazakhstan':'KZ','kenya':'KE','kiribati':'KI',
    'kosovo':'XK','kuwait':'KW','kyrgyzstan':'KG','laos':'LA','latvia':'LV',
    'lebanon':'LB','lesotho':'LS','liberia':'LR','libya':'LY','liechtenstein':'LI',
    'lithuania':'LT','luxembourg':'LU','macau':'MO','madagascar':'MG','malawi':'MW',
    'malaysia':'MY','maldives':'MV','mali':'ML','malta':'MT',
    'marshall islands':'MH','mauritania':'MR','mauritius':'MU','mexico':'MX',
    'micronesia':'FM','moldova':'MD','monaco':'MC','mongolia':'MN','montenegro':'ME',
    'morocco':'MA','mozambique':'MZ','myanmar':'MM','namibia':'NA','nauru':'NR',
    'nepal':'NP','netherlands':'NL','new zealand':'NZ','nicaragua':'NI','niger':'NE',
    'nigeria':'NG','north korea':'KP','north macedonia':'MK','norway':'NO','oman':'OM',
    'pakistan':'PK','palau':'PW','palestine':'PS','panama':'PA',
    'papua new guinea':'PG','paraguay':'PY','peru':'PE','philippines':'PH',
    'poland':'PL','portugal':'PT','qatar':'QA','romania':'RO','russia':'RU',
    'rwanda':'RW','saint lucia':'LC','samoa':'WS','san marino':'SM',
    'saudi arabia':'SA','senegal':'SN','serbia':'RS','seychelles':'SC',
    'sierra leone':'SL','singapore':'SG','slovakia':'SK','slovenia':'SI',
    'solomon islands':'SB','somalia':'SO','south africa':'ZA','south korea':'KR',
    'south sudan':'SS','spain':'ES','sri lanka':'LK','sudan':'SD','suriname':'SR',
    'sweden':'SE','switzerland':'CH','syria':'SY','taiwan':'TW','tajikistan':'TJ',
    'tanzania':'TZ','thailand':'TH','timor-leste':'TL','togo':'TG','tonga':'TO',
    'trinidad and tobago':'TT','tunisia':'TN','turkey':'TR','turkmenistan':'TM',
    'tuvalu':'TV','uganda':'UG','ukraine':'UA','united arab emirates':'AE',
    'united kingdom':'GB','united states':'US','uruguay':'UY','uzbekistan':'UZ',
    'vanuatu':'VU','vatican city':'VA','venezuela':'VE','vietnam':'VN',
    'yemen':'YE','zambia':'ZM','zimbabwe':'ZW',
  };
}