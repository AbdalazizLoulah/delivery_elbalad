/// إعدادات التطبيق العامة.
///
/// القيم الحساسة (Supabase / Google Maps) بتتقرأ من `--dart-define` أو من ملف
/// `config/dev.json` باستخدام `--dart-define-from-file=config/dev.json`.
/// لو القيم ناقصة التطبيق بيشتغل تلقائيًا في "الوضع التجريبي" بالبيانات المحلية.
class AppConfig {
  const AppConfig._();

  static const String appName = 'ديليفاري البلد';
  static const String appVersion = '1.0.0';

  /// مشروع Supabase الافتراضي (ينفع يتغير وقت البناء بـ --dart-define
  /// أو --dart-define-from-file=config/dev.json).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ovgnxrfmbmidvqotrpgb.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_vAuZpE9qwZJDTpPF53id7Q_rVW2GLeE',
  );

  /// مفتاح Google Maps (للخرايط جوّه التطبيق؛ الأندرويد بياخده كمان من
  /// android/gradle.properties).
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB701uAfKGAgDAk6qMuPC5xtJyTAV7pRV4',
  );

  /// المتجر الافتراضي للتطبيق (جنيه مصري).
  static const String currency = 'ج.م';

  /// أقصى مسافة (كم) تظهر لطيار الدليفاري كطلب "قريب".
  static const double courierSearchRadiusKm = 25;

  /// مصاريف الدليفاري: قيمة ثابتة + سعر لكل كيلومتر.
  static const double baseDeliveryFee = 10;
  static const double perKmDeliveryFee = 3;
  static const double maxDeliveryFee = 80;

  /// إجبار الوضع التجريبي (للاختبارات والتجربة من غير إنترنت).
  static bool _forceDemoMode = false;
  static void forceDemoMode(bool value) => _forceDemoMode = value;

  /// إجبار الوضع التجريبي وقت البناء:
  /// flutter build web --dart-define=FORCE_DEMO=true
  static const bool _forceDemoBuild = bool.fromEnvironment('FORCE_DEMO');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// هل التطبيق شغال بالبيانات التجريبية (من غير باك إند حقيقي).
  static bool get isDemoMode => _forceDemoMode || _forceDemoBuild || !hasSupabase;

  static const String demoNotice =
      'الوضع التجريبي: البيانات محلية. ضيف SUPABASE_URL و SUPABASE_ANON_KEY لتشغيل الباك إند.';
}
