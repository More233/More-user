import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../models/explore_state.dart';

class ExploreScreenHelpers {
  static double calculateTimeDecayWeight(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return 0.0;
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return 0.0;
    
    final difference = DateTime.now().difference(createdAt);
    final diffInMinutes = difference.inMinutes;

    // Check-in sliding window of 3 hours (180 minutes)
    if (diffInMinutes > 180 || diffInMinutes < 0) {
      return 0.0;
    }

    // Exponential time decay function
    // At t=0: weight = 1.0
    // At t=60: weight = 0.36
    // At t=120: weight = 0.13
    // At t=180: weight = 0.05
    final double exponent = -diffInMinutes / 60.0;
    return math.exp(exponent);
  }

  static List<Map<String, dynamic>> getGlobalSwarmLandmarks(double userLat, double userLng) {
    final List<Map<String, dynamic>> rawLandmarks = [
      // --- SAUDI ARABIA ---
      {'id': 'kafd_riyadh', 'name': 'King Abdullah Financial District', 'ar': 'مركز الملك عبدالله المالي (KAFD)', 'lat': 24.7622, 'lng': 46.6409, 'people': 390, 'type': 'Other', 'priority': 1},
      {'id': 'kingdom_tower', 'name': 'Kingdom Centre Tower', 'ar': 'برج المملكة', 'lat': 24.7114, 'lng': 46.6743, 'people': 350, 'type': 'Other', 'priority': 2},
      {'id': 'faisaliah_tower', 'name': 'Al Faisaliah Tower', 'ar': 'برج الفيصلية', 'lat': 24.6903, 'lng': 46.6853, 'people': 310, 'type': 'Other', 'priority': 2},
      {'id': 'blvd_riyadh', 'name': 'Boulevard City', 'ar': 'بوليفارد سيتي', 'lat': 24.7733, 'lng': 46.6292, 'people': 420, 'type': 'Other', 'priority': 1},
      {'id': 'jeddah_fountain', 'name': 'King Fahd\'s Fountain', 'ar': 'نافورة الملك فهد', 'lat': 21.5161, 'lng': 39.1512, 'people': 290, 'type': 'Other', 'priority': 2},
      {'id': 'jeddah_corniche', 'name': 'Jeddah Corniche', 'ar': 'كورنيش جدة', 'lat': 21.5424, 'lng': 39.1124, 'people': 320, 'type': 'Other', 'priority': 2},
      {'id': 'jeddah_airport', 'name': 'King Abdulaziz Airport (JED)', 'ar': 'مطار الملك عبدالعزيز (JED)', 'lat': 21.6796, 'lng': 39.1565, 'people': 310, 'type': 'Airport', 'priority': 2},
      {'id': 'dammam_dmm', 'name': 'King Fahd Airport (DMM)', 'ar': 'مطار الملك فهد بالدمام (DMM)', 'lat': 26.4710, 'lng': 49.7979, 'people': 320, 'type': 'Airport', 'priority': 3},

      // --- LIBYA ---
      {'id': 'tripoli_mitiga', 'name': 'Mitiga International Airport', 'ar': 'مطار معيتيقة الدولي', 'lat': 32.9011, 'lng': 13.2806, 'people': 310, 'type': 'Airport', 'priority': 2},
      {'id': 'tripoli_martyrs', 'name': 'Martyrs\' Square', 'ar': 'ميدان الشهداء', 'lat': 32.8967, 'lng': 13.1810, 'people': 280, 'type': 'Other', 'priority': 2},
      {'id': 'tripoli_castle', 'name': 'Red Castle Museum', 'ar': 'السراي الحمراء', 'lat': 32.8953, 'lng': 13.1804, 'people': 240, 'type': 'Other', 'priority': 3},
      {'id': 'benghazi_airport', 'name': 'Benina International Airport', 'ar': 'مطار بنينا الدولي', 'lat': 32.0964, 'lng': 20.2689, 'people': 190, 'type': 'Airport', 'priority': 3},

      // --- EGYPT ---
      {'id': 'cairo_pyramids', 'name': 'Giza Pyramids Complex', 'ar': 'أهرامات الجيزة', 'lat': 29.9792, 'lng': 31.1342, 'people': 410, 'type': 'Other', 'priority': 1},
      {'id': 'cairo_tower', 'name': 'Cairo Tower', 'ar': 'برج القاهرة', 'lat': 30.0459, 'lng': 31.2243, 'people': 360, 'type': 'Other', 'priority': 2},
      {'id': 'cairo_cai', 'name': 'Cairo Airport (CAI)', 'ar': 'مطار القاهرة الدولي (CAI)', 'lat': 30.1219, 'lng': 31.4056, 'people': 340, 'type': 'Airport', 'priority': 2},
      {'id': 'alex_citadel', 'name': 'Citadel of Qaitbay', 'ar': 'قلعة قايتباي', 'lat': 31.2140, 'lng': 29.8856, 'people': 260, 'type': 'Other', 'priority': 3},
      {'id': 'alex_library', 'name': 'Bibliotheca Alexandrina', 'ar': 'مكتبة الإسكندرية', 'lat': 31.2089, 'lng': 29.9092, 'people': 280, 'type': 'Other', 'priority': 2},

      // --- UAE ---
      {'id': 'dubai_dxb', 'name': 'Dubai International Airport (DXB)', 'ar': 'مطار دبي الدولي (DXB)', 'lat': 25.2532, 'lng': 55.3657, 'people': 460, 'type': 'Airport', 'priority': 1},
      {'id': 'burj_khalifa', 'name': 'Burj Khalifa', 'ar': 'برج خليفة', 'lat': 25.1972, 'lng': 55.2744, 'people': 490, 'type': 'Other', 'priority': 1},
      {'id': 'dubai_mall', 'name': 'The Dubai Mall', 'ar': 'دبي مول', 'lat': 25.1985, 'lng': 55.2796, 'people': 480, 'type': 'Other', 'priority': 1},
      {'id': 'palm_jumeirah', 'name': 'Palm Jumeirah', 'ar': 'نخلة الجميرة', 'lat': 25.1124, 'lng': 55.1390, 'people': 410, 'type': 'Other', 'priority': 2},
      {'id': 'abu_dhabi_auh', 'name': 'Abu Dhabi Airport (AUH)', 'ar': 'مطار أبوظبي الدولي (AUH)', 'lat': 24.4244, 'lng': 54.6511, 'people': 410, 'type': 'Airport', 'priority': 2},
      {'id': 'grand_mosque', 'name': 'Sheikh Zayed Mosque', 'ar': 'جامع الشيخ زايد الكبير', 'lat': 24.4121, 'lng': 54.4750, 'people': 390, 'type': 'Other', 'priority': 2},
      {'id': 'louvre_ad', 'name': 'متحف اللوفر أبوظبي', 'ar': 'متحف اللوفر أبوظبي', 'lat': 24.5338, 'lng': 54.3983, 'people': 330, 'type': 'Other', 'priority': 3},
      {'id': 'sharjah_shj', 'name': 'Sharjah Airport (SHJ)', 'ar': 'مطار الشارقة (SHJ)', 'lat': 25.3286, 'lng': 55.5172, 'people': 360, 'type': 'Airport', 'priority': 3},
      {'id': 'al_ain_aan', 'name': 'Al Ain Airport (AAN)', 'ar': 'مطار العين (AAN)', 'lat': 24.2617, 'lng': 55.6092, 'people': 330, 'type': 'Airport', 'priority': 3},

      // --- OTHER ARAB COUNTRIES ---
      {'id': 'kuwait_kwi', 'name': 'Kuwait International Airport (KWI)', 'ar': 'مطار الكويت الدولي (KWI)', 'lat': 29.2244, 'lng': 47.9691, 'people': 340, 'type': 'Airport', 'priority': 3},
      {'id': 'kuwait_towers', 'name': 'Kuwait Towers', 'ar': 'أبراج الكويت', 'lat': 29.3819, 'lng': 48.0039, 'people': 240, 'type': 'Other', 'priority': 2},
      {'id': 'manama_bah', 'name': 'Bahrain International Airport (BAH)', 'ar': 'مطار البحرين الدولي (BAH)', 'lat': 26.2708, 'lng': 50.6336, 'people': 310, 'type': 'Airport', 'priority': 3},
      {'id': 'doha_doh', 'name': 'Hamad International Airport (DOH)', 'ar': 'مطار حمد الدولي (DOH)', 'lat': 25.2731, 'lng': 51.6081, 'people': 390, 'type': 'Airport', 'priority': 3},
      {'id': 'doha_waqif', 'name': 'Souq Waqif', 'ar': 'سوق واقف', 'lat': 25.2867, 'lng': 51.5333, 'people': 280, 'type': 'Other', 'priority': 2},
      {'id': 'muscat_mct', 'name': 'Muscat International Airport', 'ar': 'مطار مسقط الدولي', 'lat': 23.5933, 'lng': 58.2814, 'people': 260, 'type': 'Airport', 'priority': 3},
      {'id': 'amman_amm', 'name': 'Queen Alia Airport (AMM)', 'ar': 'مطار الملكة علياء (AMM)', 'lat': 31.7225, 'lng': 35.9933, 'people': 310, 'type': 'Airport', 'priority': 3},
      {'id': 'amman_citadel', 'name': 'Amman Citadel', 'ar': 'جبل القلعة بعمان', 'lat': 31.9547, 'lng': 35.9348, 'people': 210, 'type': 'Other', 'priority': 3},
      {'id': 'beirut_bey', 'name': 'Beirut Airport (BEY)', 'ar': 'مطار بيروت الدولي (BEY)', 'lat': 33.8209, 'lng': 35.4884, 'people': 290, 'type': 'Airport', 'priority': 3},
      {'id': 'beirut_rocks', 'name': 'Raouche Rocks', 'ar': 'صخرة الروشة', 'lat': 33.8903, 'lng': 35.4727, 'people': 220, 'type': 'Other', 'priority': 3},
      {'id': 'casa_mosque', 'name': 'Hassan II Mosque', 'ar': 'مسجد الحسن الثاني', 'lat': 33.6085, 'lng': -7.6327, 'people': 320, 'type': 'Other', 'priority': 2},
      {'id': 'casa_cmn', 'name': 'Mohammed V Airport (CMN)', 'ar': 'مطار محمد الخامس (CMN)', 'lat': 33.3675, 'lng': -7.5898, 'people': 270, 'type': 'Airport', 'priority': 3},
      {'id': 'marrakech_fna', 'name': 'Jemaa el-Fnaa', 'ar': 'ساحة جامع الفناء', 'lat': 31.6258, 'lng': -7.9891, 'people': 340, 'type': 'Other', 'priority': 2},
      {'id': 'algiers_alg', 'name': 'Houari Boumediene Airport (ALG)', 'ar': 'مطار هواري بومدين (ALG)', 'lat': 36.6910, 'lng': 3.2154, 'people': 230, 'type': 'Airport', 'priority': 3},
      {'id': 'tunis_tun', 'name': 'Tunis-Carthage Airport (TUN)', 'ar': 'مطار تونس قرطاج (TUN)', 'lat': 36.8510, 'lng': 10.2272, 'people': 210, 'type': 'Airport', 'priority': 3},

      // --- OTHER AFRICA ---
      {'id': 'nairobi_nbo', 'name': 'Jomo Kenyatta Airport (NBO)', 'ar': 'مطار جومو كينياتا (NBO)', 'lat': -1.3192, 'lng': 36.9275, 'people': 220, 'type': 'Airport', 'priority': 3},
      {'id': 'cape_town_cpt', 'name': 'Cape Town Airport (CPT)', 'ar': 'مطار كيب تاون الدولي (CPT)', 'lat': -33.9715, 'lng': 18.6021, 'people': 190, 'type': 'Airport', 'priority': 2},
      {'id': 'table_mountain', 'name': 'Table Mountain', 'ar': 'جبل الطاولة', 'lat': -33.9628, 'lng': 18.4098, 'people': 240, 'type': 'Other', 'priority': 3},
      {'id': 'johannesburg_jnb', 'name': 'O.R. Tambo Airport (JNB)', 'ar': 'مطار أوليفر تامبو (JNB)', 'lat': -26.1367, 'lng': 28.2461, 'people': 260, 'type': 'Airport', 'priority': 3},

      // --- EUROPE ---
      {'id': 'london_lhr', 'name': 'London Heathrow Airport (LHR)', 'ar': 'مطار لندن هيثرو (LHR)', 'lat': 51.4700, 'lng': -0.4543, 'people': 380, 'type': 'Airport', 'priority': 1},
      {'id': 'big_ben', 'name': 'Big Ben & Parliament', 'ar': 'ساعة بيج بن', 'lat': 51.5007, 'lng': -0.1246, 'people': 350, 'type': 'Other', 'priority': 2},
      {'id': 'london_eye', 'name': 'The London Eye', 'ar': 'عين لندن', 'lat': 51.5033, 'lng': -0.1195, 'people': 360, 'type': 'Other', 'priority': 2},
      {'id': 'paris_eiffel', 'name': 'Eiffel Tower', 'ar': 'برج إيفل', 'lat': 48.8584, 'lng': 2.2945, 'people': 370, 'type': 'Other', 'priority': 2},
      {'id': 'louvre_museum', 'name': 'Louvre Museum', 'ar': 'متحف اللوفر', 'lat': 48.8606, 'lng': 2.3376, 'people': 390, 'type': 'Other', 'priority': 2},
      {'id': 'paris_cdg', 'name': 'Charles de Gaulle Airport (CDG)', 'ar': 'مطار شارل ديغول (CDG)', 'lat': 49.0097, 'lng': 2.5479, 'people': 350, 'type': 'Airport', 'priority': 3},
      {'id': 'brussels_bru', 'name': 'Brussels Airport (BRU)', 'ar': 'مطار بروكسل الدولي', 'lat': 50.9008, 'lng': 4.4856, 'people': 350, 'type': 'Airport', 'priority': 3},
      {'id': 'munich_muc', 'name': 'Munich Airport (MUC)', 'ar': 'مطار ميونخ الدولي', 'lat': 48.3538, 'lng': 11.7861, 'people': 340, 'type': 'Airport', 'priority': 3},
      {'id': 'milan_mxp', 'name': 'Milan Malpensa Airport (MXP)', 'ar': 'مطار ميلانو مالبينسا', 'lat': 45.6300, 'lng': 8.7230, 'people': 360, 'type': 'Airport', 'priority': 3},
      {'id': 'barcelona_bcn', 'name': 'Barcelona-El Prat Airport (BCN)', 'ar': 'مطار برشلونة الدولي', 'lat': 41.2974, 'lng': 2.0785, 'people': 340, 'type': 'Airport', 'priority': 3},
      {'id': 'berlin_ber', 'name': 'Berlin Brandenburg Airport (BER)', 'ar': 'مطار برلين براندنبورغ', 'lat': 52.3667, 'lng': 13.5033, 'people': 350, 'type': 'Airport', 'priority': 3},
      {'id': 'warsaw_waw', 'name': 'Warsaw Chopin Airport (WAW)', 'ar': 'مطار وارسو شوبان', 'lat': 52.1672, 'lng': 20.9679, 'people': 280, 'type': 'Airport', 'priority': 3},
      {'id': 'vienna_vie', 'name': 'Vienna International Airport (VIE)', 'ar': 'مطار فيينا الدولي', 'lat': 48.1103, 'lng': 16.5697, 'people': 310, 'type': 'Airport', 'priority': 3},
      {'id': 'zurich_zrh', 'name': 'Zurich Airport (ZRH)', 'ar': 'مطار زيورخ الدولي', 'lat': 47.4582, 'lng': 8.5481, 'people': 330, 'type': 'Airport', 'priority': 3},
      {'id': 'frankfurt_fra', 'name': 'Frankfurt Airport (FRA)', 'ar': 'مطار فرانكفورت (FRA)', 'lat': 50.0379, 'lng': 8.5622, 'people': 360, 'type': 'Airport', 'priority': 2},
      {'id': 'amsterdam_ams', 'name': 'Amsterdam Airport Schiphol (AMS)', 'ar': 'مطار سخيبول أمستردام (AMS)', 'lat': 52.3105, 'lng': 4.7683, 'people': 370, 'type': 'Airport', 'priority': 2},
      {'id': 'rome_fco', 'name': 'Leonardo da Vinci Airport (FCO)', 'ar': 'مطار ليوناردو دا فينشي (FCO)', 'lat': 41.7999, 'lng': 12.2462, 'people': 350, 'type': 'Airport', 'priority': 2},
      {'id': 'madrid_mad', 'name': 'Adolfo Suárez Madrid-Barajas Airport (MAD)', 'ar': 'مطار مدريد باراخاس الدولي (MAD)', 'lat': 40.4719, 'lng': -3.5640, 'people': 340, 'type': 'Airport', 'priority': 2},
      {'id': 'moscow_svo', 'name': 'Sheremetyevo International Airport (SVO)', 'ar': 'مطار شيريميتييفو الدولي (SVO)', 'lat': 55.9726, 'lng': 37.4146, 'people': 250, 'type': 'Airport', 'priority': 2},

      // --- TURKEY ---
      {'id': 'istanbul_ist', 'name': 'Istanbul Airport (IST)', 'ar': 'مطار إسطنبول الدولي (IST)', 'lat': 41.2750, 'lng': 28.7519, 'people': 420, 'type': 'Airport', 'priority': 1},
      {'id': 'ankara_esb', 'name': 'Ankara Esenboga Airport (ESB)', 'ar': 'مطار إيسنبوغا الدولي بأنقرة', 'lat': 40.1281, 'lng': 32.9950, 'people': 380, 'type': 'Airport', 'priority': 3},
      {'id': 'izmir_adb', 'name': 'Izmir Adnan Menderes Airport (ADB)', 'ar': 'مطار عدنان مندريس الدولي بإزمير', 'lat': 38.2924, 'lng': 27.1570, 'people': 350, 'type': 'Airport', 'priority': 3},
      {'id': 'antalya_ayt', 'name': 'Antalya Airport (AYT)', 'ar': 'مطار أنطاليا الدولي', 'lat': 36.9008, 'lng': 30.7928, 'people': 340, 'type': 'Airport', 'priority': 3},
      {'id': 'bursa_yei', 'name': 'Bursa Yenisehir Airport (YEI)', 'ar': 'مطار ينيشهر الدولي ببورصة', 'lat': 40.1885, 'lng': 29.0610, 'people': 310, 'type': 'Airport', 'priority': 3},

      // --- AMERICA ---
      {'id': 'ny_times_square', 'name': 'Times Square', 'ar': 'تايمز سكوير', 'lat': 40.7580, 'lng': -73.9855, 'people': 450, 'type': 'Other', 'priority': 1},
      {'id': 'disney_world', 'name': 'Walt Disney World Resort', 'ar': 'منتجع عالم والت ديزني', 'lat': 28.3852, 'lng': -81.5639, 'people': 360, 'type': 'Other', 'priority': 2},
      {'id': 'toronto_yyz', 'name': 'Toronto Pearson Airport (YYZ)', 'ar': 'مطار تورونتو بيرسون الدولي (YYZ)', 'lat': 43.6777, 'lng': -79.6248, 'people': 380, 'type': 'Airport', 'priority': 1},
      {'id': 'los_angeles_lax', 'name': 'Los Angeles International Airport (LAX)', 'ar': 'مطار لوس أنجلوس الدولي (LAX)', 'lat': 33.9416, 'lng': -118.4085, 'people': 420, 'type': 'Airport', 'priority': 1},
      {'id': 'san_francisco_sfo', 'name': 'San Francisco International Airport (SFO)', 'ar': 'مطار سان فرانسيسكو الدولي (SFO)', 'lat': 37.6213, 'lng': -122.3790, 'people': 390, 'type': 'Airport', 'priority': 1},
      {'id': 'chicago_ord', 'name': 'O\'Hare International Airport (ORD)', 'ar': 'مطار أوهير الدولي (ORD)', 'lat': 41.9742, 'lng': -87.9073, 'people': 370, 'type': 'Airport', 'priority': 2},
      {'id': 'miami_mia', 'name': 'Miami International Airport (MIA)', 'ar': 'مطار ميامي الدولي (MIA)', 'lat': 25.7959, 'lng': -80.2870, 'people': 390, 'type': 'Airport', 'priority': 2},
      {'id': 'boston_bos', 'name': 'Boston Logan International Airport (BOS)', 'ar': 'مطار لوغان الدولي ببوسطن', 'lat': 42.3656, 'lng': -71.0096, 'people': 390, 'type': 'Airport', 'priority': 3},
      {'id': 'washington_iad', 'name': 'Dulles International Airport (IAD)', 'ar': 'مطار واشنطن دالاس الدولي', 'lat': 38.9531, 'lng': -77.4565, 'people': 380, 'type': 'Airport', 'priority': 3},
      {'id': 'philadelphia_phl', 'name': 'Philadelphia International Airport (PHL)', 'ar': 'مطار فيلادلفيا الدولي', 'lat': 39.8729, 'lng': -75.2437, 'people': 360, 'type': 'Airport', 'priority': 3},
      {'id': 'atlanta_atl', 'name': 'Hartsfield-Jackson Atlanta Airport (ATL)', 'ar': 'مطار أتلانتا هارتسفيلد جاكسون', 'lat': 33.6407, 'lng': -84.4277, 'people': 380, 'type': 'Airport', 'priority': 3},
      {'id': 'houston_iah', 'name': 'George Bush Intercontinental Airport (IAH)', 'ar': 'مطار جورج بوش الدولي بهيوستن', 'lat': 29.9902, 'lng': -95.3368, 'people': 370, 'type': 'Airport', 'priority': 3},
      {'id': 'seattle_sea', 'name': 'Seattle-Tacoma International Airport (SEA)', 'ar': 'مطار سياتل تاكوما الدولي', 'lat': 47.4502, 'lng': -122.3088, 'people': 350, 'type': 'Airport', 'priority': 3},
      {'id': 'sao_paulo_gru', 'name': 'São Paulo/Guarulhos Airport (GRU)', 'ar': 'مطار غواروليوس الدولي (GRU)', 'lat': -23.4356, 'lng': -46.4731, 'people': 220, 'type': 'Airport', 'priority': 2},
      {'id': 'buenos_aires_eze', 'name': 'Ministro Pistarini Airport (EZE)', 'ar': 'مطار إيزيزا الدولي (EZE)', 'lat': -34.8222, 'lng': -58.5358, 'people': 180, 'type': 'Airport', 'priority': 2},

      // --- ASIA ---
      {'id': 'tokyo_hnd', 'name': 'Tokyo International Airport (HND)', 'ar': 'مطار طوكيو هانيدا الدولي (HND)', 'lat': 35.5494, 'lng': 139.7798, 'people': 290, 'type': 'Airport', 'priority': 2},
      {'id': 'tokyo_tower', 'name': 'Tokyo Tower', 'ar': 'برج طوكيو', 'lat': 35.6586, 'lng': 139.7454, 'people': 280, 'type': 'Other', 'priority': 2},
      {'id': 'singapore_sin', 'name': 'Singapore Changi Airport (SIN)', 'ar': 'مطار سنغافورة تشانغي (SIN)', 'lat': 1.3644, 'lng': 103.9915, 'people': 280, 'type': 'Airport', 'priority': 2},
      {'id': 'hong_kong_hkg', 'name': 'Hong Kong International Airport (HKG)', 'ar': 'مطار هونغ كونغ الدولي (HKG)', 'lat': 22.3080, 'lng': 113.9185, 'people': 260, 'type': 'Airport', 'priority': 2},
      {'id': 'seoul_icn', 'name': 'Incheon International Airport (ICN)', 'ar': 'مطار إنشيون الدولي (ICN)', 'lat': 37.4602, 'lng': 126.4407, 'people': 290, 'type': 'Airport', 'priority': 2},
      {'id': 'beijing_pek', 'name': 'Beijing Capital Airport (PEK)', 'ar': 'مطار بكين العاصمة الدولي', 'lat': 40.0799, 'lng': 116.5976, 'people': 310, 'type': 'Airport', 'priority': 2},
      {'id': 'shanghai_pvg', 'name': 'Shanghai Pudong Airport (PVG)', 'ar': 'مطار شانغهاي بودنغ الدولي', 'lat': 31.1443, 'lng': 121.8083, 'people': 290, 'type': 'Airport', 'priority': 2},
      {'id': 'bangkok_bkk', 'name': 'Bangkok Suvarnabhumi Airport (BKK)', 'ar': 'مطار سوفارنابومي الدولي', 'lat': 13.6896, 'lng': 100.7501, 'people': 330, 'type': 'Airport', 'priority': 2},
      {'id': 'kuala_lumpur_kul', 'name': 'Kuala Lumpur Airport (KUL)', 'ar': 'مطار كوالالمبور الدولي', 'lat': 2.7456, 'lng': 101.7072, 'people': 280, 'type': 'Airport', 'priority': 2},
      {'id': 'jakarta_cgk', 'name': 'Jakarta Soekarno-Hatta Airport (CGK)', 'ar': 'مطار سوكارنو هاتا الدولي', 'lat': -6.1256, 'lng': 106.6558, 'people': 260, 'type': 'Airport', 'priority': 2},
      {'id': 'mumbai_bom', 'name': 'Chhatrapati Shivaji Maharaj Airport (BOM)', 'ar': 'مطار تشاتراباتي شيفاجي الدولي (BOM)', 'lat': 19.0896, 'lng': 72.8656, 'people': 230, 'type': 'Airport', 'priority': 2},
    ];

    return rawLandmarks.map((item) {
      final double lat = item['lat'] as double;
      final double lng = item['lng'] as double;
      final double meters = Geolocator.distanceBetween(userLat, userLng, lat, lng);
      final double km = meters / 1000;
      final String distanceStr = km < 1 
          ? '${meters.toStringAsFixed(0)} m' 
          : '${km.toStringAsFixed(1)} km';
      
      return {
        'id': 'global_swarm_${item['id']}',
        'name': item['name'],
        'arabicName': item['ar'],
        'address': item['name'],
        'latitude': lat,
        'longitude': lng,
        'rating': 4.5,
        'reviewsCount': item['people'] as int,
        'price': r'$$',
        'peopleCount': item['people'] as int,
        'basePeopleCount': item['people'] as int,
        'priority': item['priority'] as int? ?? 3,
        'type': item['type'],
        'imageUrl': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=500',
        'isSaved': false,
        'isVisited': false,
        'actionType': 'Other',
        'isRegistered': true,
        'visitors': <Map<String, dynamic>>[],
        'distance': distanceStr,
      };
    }).toList();
  }

  static double calculateHybridWeight({
    required Map<String, dynamic> place,
    required bool isSaved,
  }) {
    // 1. Check-In Weight (with Time Decay) from our app
    double checkInWeight = 0.0;
    final visitors = place['visitors'] as List<dynamic>? ?? [];
    for (final visitor in visitors) {
      if (visitor is Map<String, dynamic>) {
        final String? createdAtStr = visitor['createdAt'] as String?;
        checkInWeight += calculateTimeDecayWeight(createdAtStr);
      }
    }
    final double activeCheckins = checkInWeight.clamp(0.0, 10.0);

    // 2. Real-world Popularity Base (Google/Foursquare Reviews Count)
    final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
    double reviewsContribution = 0.5; // default low baseline
    if (reviewsCount >= 1500) {
      reviewsContribution = 20.0;
    } else if (reviewsCount >= 800) {
      reviewsContribution = 14.0;
    } else if (reviewsCount >= 300) {
      reviewsContribution = 8.0;
    } else if (reviewsCount >= 100) {
      reviewsContribution = 4.0;
    } else if (reviewsCount >= 20) {
      reviewsContribution = 2.0;
    }

    // Base density contribution from current/base people count (essential for global swarm landmarks)
    final int peopleCount = (place['peopleCount'] as num? ?? 0).toInt();
    double peopleDensityContribution = 0.0;
    if (peopleCount >= 150) {
      peopleDensityContribution = 18.0;
    } else if (peopleCount >= 100) {
      peopleDensityContribution = 14.0;
    } else if (peopleCount >= 50) {
      peopleDensityContribution = 10.0;
    } else if (peopleCount >= 20) {
      peopleDensityContribution = 6.0;
    } else if (peopleCount >= 5) {
      peopleDensityContribution = 3.0;
    } else if (peopleCount > 0) {
      peopleDensityContribution = 1.5;
    }

    final double baselinePopularity = math.max(reviewsContribution, peopleDensityContribution);

    // 3. Place Quality / Rating contribution
    final double rating = (place['rating'] as num? ?? 0.0).toDouble();
    double ratingContribution = 1.0;
    if (rating >= 4.5 || rating >= 9.0) { // Google 4.5+ or Foursquare 9.0+
      ratingContribution = 1.5;
    } else if (rating >= 4.0 || rating >= 8.0) {
      ratingContribution = 1.25;
    }

    // 4. Baseline Real-world Crowd Density (combines popularity and rating)
    final double baselineDensity = baselinePopularity * ratingContribution;

    // 5. App Active Check-ins Multiplier (Amplifies the heatmap dynamically in real-time)
    final double activeMultiplier = 1.0 + (activeCheckins * 4.0);

    // 6. Saved places bonus (people bookmarked it)
    final double savedBonus = isSaved ? 5.0 : 0.0;

    // Final logical crowd density weight
    final double totalWeight = (baselineDensity * activeMultiplier) + savedBonus;

    return totalWeight;
  }



  static double? parseDistance(String? distanceStr) {
    if (distanceStr == null) return null;
    final str = distanceStr.toLowerCase().trim();
    if (str.contains('m') && !str.contains('k')) {
      final numVal = double.tryParse(str.replaceAll('m', '').trim());
      if (numVal != null) return numVal / 1000.0;
    } else if (str.contains('km')) {
      return double.tryParse(str.replaceAll('km', '').trim());
    }
    return null;
  }

  static bool isProminentPlace(Map<String, dynamic> place) {
    if (place['isCheckIn'] == true) return true;
    final String id = place['id']?.toString() ?? '';
    if (id.startsWith('tapped_') || id.startsWith('swarm_')) return true;
    if (place['isCustomVenue'] == true || place['isRegistered'] == true) return true;

    final String type = place['type'] as String? ?? '';
    final String typeLower = type.toLowerCase();
    if (typeLower.contains('airport') ||
        typeLower.contains('hotel') ||
        typeLower.contains('park') ||
        typeLower.contains('ticket')) {
      return true;
    }

    final String name = (place['name'] as String? ?? '').toLowerCase();
    final String address = (place['address'] as String? ?? '').toLowerCase();
    if (name.contains('tower') || name.contains('mall') || name.contains('center') || name.contains('plaza') ||
        name.contains('برج') || name.contains('مول') || name.contains('مركز') || name.contains('بلازا') || name.contains('ساحة')) {
      return true;
    }
    if (address.contains('highway') || address.contains('road') || address.contains('main') ||
        address.contains('طريق') || address.contains('رئيسي') || address.contains('سريع')) {
      return true;
    }

    if (address.contains('alley') || address.contains('lane') || address.contains('side') ||
        address.contains('زقاق') || address.contains('حارة') || address.contains('فرعي')) {
      return false;
    }

    final double rating = (place['rating'] as num? ?? 0.0).toDouble();
    final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
    if (rating >= 4.4 && reviewsCount >= 10) {
      return true;
    }

    return false;
  }

  static List<Map<String, dynamic>> getFilteredPlaces(
    ExploreState state,
    double currentZoom, {
    bool forHeatmap = false,
  }) {
    final List<Map<String, dynamic>> baseList = List<Map<String, dynamic>>.from(state.allPlaces);
    if (state.selectedMapTab == 2) {
      final userLat = state.userLocation?.latitude ?? 24.7136;
      final userLng = state.userLocation?.longitude ?? 46.6753;
      baseList.addAll(getGlobalSwarmLandmarks(userLat, userLng));
    }

    if (state.selectedPlace != null) {
      final String selIdStr = state.selectedPlace!['id'].toString();
      final bool exists = baseList.any((p) => p['id'].toString() == selIdStr);
      if (!exists) {
        baseList.add(state.selectedPlace!);
      }
    }

    final unfiltered = baseList.where((place) {
      if (state.selectedPlace != null &&
          place['id'].toString() == state.selectedPlace!['id'].toString()) {
        return true;
      }
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final nameMatches = (place['name'] as String? ?? '').toLowerCase().contains(query);
        final arMatches = (place['arabicName'] as String? ?? '').toLowerCase().contains(query);
        if (!nameMatches && !arMatches) return false;
      }

      if (state.selectedMapTab == 3) {
        final filterVisited = state.filterState.visited;
        final filterSaved = state.filterState.saved;
        final bool isVisited = place['isVisited'] as bool? ?? false;
        final bool isSaved = place['isSaved'] as bool? ?? false;

        if (filterVisited && filterSaved) {
          return isVisited || isSaved;
        } else if (filterVisited) {
          return isVisited;
        } else if (filterSaved) {
          return isSaved;
        } else {
          return isVisited || isSaved;
        }
      }

      if (state.selectedMapTab == 0) {
        final type = place['type'] as String? ?? 'Other';
        if (state.selectedCategory.isNotEmpty) {
          if (type != state.selectedCategory) return false;
        } else {
          if (type == 'Movies' || type == 'Sports' || type == 'Concerts' || type == 'Ticket') {
            return false;
          }
        }
      }

      if (state.selectedMapTab == 1) {
        final type = place['type'] as String? ?? 'Other';
        if (state.selectedCategory.isNotEmpty) {
          if (type != state.selectedCategory) return false;
        } else {
          if (type != 'Movies' && type != 'Sports' && type != 'Concerts' && type != 'Ticket') {
            return false;
          }
        }
      }


      if (state.filterState.maxDistance != null) {
        final double? dist = parseDistance(place['distance'] as String?);
        if (dist == null || dist > state.filterState.maxDistance!) {
          return false;
        }
      }

      if (state.filterState.openNow) {
        final openNow = place['openNow'] as bool? ?? true;
        if (!openNow) return false;
      }

      if (state.filterState.minRating != null) {
        final rating = (place['rating'] as num? ?? 0.0).toDouble();
        if (rating < state.filterState.minRating!) return false;
      }

      if (state.filterState.priceRange != null) {
        final price = place['price'] as String? ?? r'$$';
        if (price != state.filterState.priceRange) return false;
      }

      if (state.filterState.newToMe && (place['isVisited'] as bool? ?? false)) return false;
      if (state.filterState.onList && !(place['isSaved'] as bool? ?? false)) return false;

      // DYNAMIC VIEWPORT FILTER: Filter out places that are far off-screen
      // to reduce Mapbox serialization / annotation overhead from 12,000+ points to <300.
      final center = state.lastFetchedLocation;
      final String pidStr = place['id'].toString();
      if (center != null && !pidStr.startsWith('global_swarm_')) {
        bool matchesQuery = false;
        if (state.searchQuery.isNotEmpty) {
          final query = state.searchQuery.toLowerCase();
          final nameMatches = (place['name'] as String? ?? '').toLowerCase().contains(query);
          final arMatches = (place['arabicName'] as String? ?? '').toLowerCase().contains(query);
          if (nameMatches || arMatches) {
            matchesQuery = true;
          }
        }
        if (!matchesQuery) {
          final double plat = (place['latitude'] as num?)?.toDouble() ?? 0.0;
          final double plng = (place['longitude'] as num?)?.toDouble() ?? 0.0;
          if (plat != 0.0 && plng != 0.0) {
            final double maxDist = currentZoom < 7.0
                ? 5000000.0 // 5000 km (essentially global)
                : (currentZoom < 10.0
                    ? 300000.0 // 300 km
                    : (currentZoom < 12.0
                        ? 100000.0 // 100 km
                        : 40000.0)); // 40 km for zoom >= 12.0

            final distance = Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              plat,
              plng,
            );
            if (distance > maxDist) return false;
          }
        }
      }

      return true;
    }).toList();

    if (forHeatmap) {
      return unfiltered;
    }

    // Return all unfiltered places directly. They will be rendered as dots when zoomed out and pins when zoomed in.
    return unfiltered;
  }
}
