import 'package:flutter/widgets.dart';

/// اللغة الحالية للتطبيق.
///
/// ده تخزين عام بسيط بيتحدّث من [AppSettingsCubit] قبل ما الواجهة تتبني،
/// وبيستخدم في الأماكن اللي مفيش فيها `BuildContext` (زي الـ formatters).
class AppLocale {
  const AppLocale._();

  static Locale current = const Locale('ar');

  static bool get isArabic => current.languageCode == 'ar';

  static bool get isEnglish => current.languageCode == 'en';
}

/// ترجمة نص عربي للإنجليزي (أو رجوع للنص الأصلي لو مفيش ترجمة).
///
/// المشروع مكتوب بالعربي في كل مكان، فبدل ما نغيّر كل النصوص يدويًا،
/// بنلفّها في `AppText` وبتترجم وقت العرض. النصوص الديناميكية بتتعامل
/// معاها [AppTranslations.patterns] (أرقام، أكواد طلبات، ... إلخ).
/// نفس [tr] لكن بياخد اللغة من الواجهة (وبيسجّل اعتماد على Localizations
/// علشان العنصر يتعاد بناؤه لو المستخدم غيّر اللغة).
String trOf(BuildContext context, String input) => tr(
      input,
      locale: Localizations.maybeLocaleOf(context) ?? AppLocale.current,
    );

String tr(String input, {Locale? locale}) {
  if (input.isEmpty) return input;
  final language = (locale ?? AppLocale.current).languageCode;
  if (language == 'ar') return input;

  final exact = AppTranslations.exact[input];
  if (exact != null) return _toWesternDigits(exact);

  for (final pattern in AppTranslations.patterns) {
    final match = pattern.regexp.firstMatch(input);
    if (match != null) {
      return _toWesternDigits(pattern.replace(match, locale ?? AppLocale.current));
    }
  }

  return _toWesternDigits(input);
}

/// تحويل الأرقام العربية-الهندية لأرقام غربية (مفيد في الوضع الإنجليزي).
String _toWesternDigits(String value) {
  var result = value;
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const western = '0123456789';
  for (var i = 0; i < arabic.length; i++) {
    result = result.replaceAll(arabic[i], western[i]);
  }
  return result.replaceAll('٫', '.').replaceAll('٬', ',');
}

class TranslationPattern {
  const TranslationPattern(this.regexp, this.replace);

  final RegExp regexp;
  final String Function(RegExpMatch match, Locale locale) replace;
}

/// قاموس الترجمة. المفاتيح هي النص العربي كما هو مكتوب في الكود.
class AppTranslations {
  const AppTranslations._();

  static final List<TranslationPattern> patterns = [
    TranslationPattern(
      RegExp(r'^كود الطلب: (.+)$'),
      (m, locale) => 'Order code: ${m[1]}',
    ),
    TranslationPattern(
      RegExp(r'^طلب (.+)$'),
      (m, locale) => 'Order ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^تم إلغاء الطلب (.+)$'),
      (m, locale) => 'Order ${m[1]} cancelled',
    ),
    TranslationPattern(
      RegExp(r'^تم قبول الطلب (.+)$'),
      (m, locale) => 'Order ${m[1]} accepted',
    ),
    TranslationPattern(
      RegExp(r'^تم تحديث الطلب: (.+)$'),
      (m, locale) => 'Order updated: ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^متأكد إنك عايز تحذف "(.+)"؟$'),
      (m, locale) => 'Delete "${m[1]}"?',
    ),
    TranslationPattern(
      RegExp(r'^متأكد إنك عايز تلغي الطلب (.+)\؟\s*$'),
      (m, locale) => 'Cancel order ${m[1]}?',
    ),
    TranslationPattern(
      RegExp(r'^الطيار فاضل عليه (.+) بالطريق$'),
      (m, locale) => 'Courier is ${tr(m[1]!, locale: locale)} away by road',
    ),
    TranslationPattern(
      RegExp(r'^ادفع (.+)$'),
      (m, locale) => 'Pay ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^مش قادرين نرفع الصورة، حاول تاني\. \((.+)\)$'),
      (m, locale) => "Couldn't upload the image, try again. (${m[1]})",
    ),
    TranslationPattern(
      RegExp(r'^الكمية المطلوبة من "(.+)" مش متاحة\. المتاح (.+) بس\.$'),
      (m, locale) => 'Requested quantity of "${m[1]}" is not available. Only ${m[2]} left.',
    ),
    TranslationPattern(
      RegExp(r'^الكمية المطلوبة من "(.+)" مش متاحة في المخزون\.$'),
      (m, locale) => 'Requested quantity of "${m[1]}" is not available in stock.',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) منتج • (.+)$'),
      (m, locale) => '${m[1]} items • ${m[2]}',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) منتج$'),
      (m, locale) => '${m[1]} items',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) عنوان محفوظ$'),
      (m, locale) => '${m[1]} saved addresses',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) طلب$'),
      (m, locale) => '${m[1]} orders',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) قطعة$'),
      (m, locale) => '${m[1]} pcs',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) متر$'),
      (m, locale) => '${m[1]} m',
    ),
    TranslationPattern(
      RegExp(r'^([\d.]+) كم$'),
      (m, locale) => '${m[1]} km',
    ),
    TranslationPattern(
      RegExp(r'^(.+) ج\.م$'),
      (m, locale) => '${m[1]} EGP',
    ),
    TranslationPattern(
      RegExp(r'^من (\d+) يوم$'),
      (m, locale) => '${m[1]} days ago',
    ),
    TranslationPattern(
      RegExp(r'^من (\d+) ساعة$'),
      (m, locale) => '${m[1]} hours ago',
    ),
    TranslationPattern(
      RegExp(r'^من (\d+) دقيقة$'),
      (m, locale) => '${m[1]} minutes ago',
    ),
    TranslationPattern(
      RegExp(r'^آخر تحديث (.+)$'),
      (m, locale) => 'Last updated ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^أرباحك (.+)$'),
      (m, locale) => 'Your earnings ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^الطيار (.+)$'),
      (m, locale) => 'Courier ${m[1]}',
    ),
    TranslationPattern(
      RegExp(r'^الطيار فاضل عليه (.+)$'),
      (m, locale) => 'Courier is ${tr(m[1]!, locale: locale)} away',
    ),
    TranslationPattern(
      RegExp(r'^المتبقي (.+)$'),
      (m, locale) => 'Remaining ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^المشوار (.+)$'),
      (m, locale) => 'Trip ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^منك للمتجر (.+)$'),
      (m, locale) => 'To store ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^الوصول خلال (.+)$'),
      (m, locale) => 'Arrives in ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^قيمة الطلب (.+)$'),
      (m, locale) => 'Order value ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^متاح: (.+)$'),
      (m, locale) => 'Available: ${tr(m[1]!, locale: locale)}',
    ),
    TranslationPattern(
      RegExp(r'^الكمية المطلوبة من "(.+)" مش متاحة.*$'),
      (m, locale) => 'Requested quantity of "${m[1]}" is not available.',
    ),
    TranslationPattern(
      RegExp(r'^المتاح من المنتج دا (.+) بس\.$'),
      (m, locale) => 'Only ${m[1]} of this product is available.',
    ),
    TranslationPattern(
      RegExp(r'^الموقع: (.+)$'),
      (m, locale) => 'Location: ${m[1]}',
    ),
    TranslationPattern(
      RegExp(r'^موقعك: (.+)$'),
      (m, locale) => 'Your location: ${m[1]}',
    ),
    TranslationPattern(
      RegExp(r'^(.+) • إصدار (.+)$'),
      (m, locale) => '${tr(m[1]!, locale: locale)} • version ${m[2]}',
    ),
    TranslationPattern(
      RegExp(r'^أقل من دقيقة$'),
      (m, locale) => 'Less than a minute',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) دقيقة$'),
      (m, locale) => '${m[1]} min',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) ساعة$'),
      (m, locale) => '${m[1]} h',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) ساعة و(\d+) دقيقة$'),
      (m, locale) => '${m[1]} h ${m[2]} min',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) طلبات \(واحد لكل متجر\)$'),
      (m, locale) => '${m[1]} orders (one per store)',
    ),
    TranslationPattern(
      RegExp(r'^اتنشأت (\d+) طلبات \(واحد لكل متجر\)$'),
      (m, locale) => '${m[1]} orders created (one per store)',
    ),
    TranslationPattern(
      RegExp(r'لو دي أول مرة، شغّل ملف supabase/schema\.sql من SQL Editor على Supabase\.'),
      (m, locale) => 'If this is the first time, run the supabase/schema.sql file from the SQL Editor on Supabase.',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) طلبات$'),
      (m, locale) => '${m[1]} orders',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) إشعار جديد$'),
      (m, locale) => '${m[1]} new notifications',
    ),
    TranslationPattern(
      RegExp(r'^(\d+) منتجات$'),
      (m, locale) => '${m[1]} products',
    ),
  ];

  static const Map<String, String> exact = {
    // ---------------- App / common ----------------
    'ديليفاري البلد': 'Delivery Elbalad',
    'ديليفاري': 'Courier',
    'الرئيسية': 'Home',
    'سلة المشتريات': 'My Cart',
    'المفضلة': 'Favorites',
    'حسابي': 'My Account',
    'طلباتي': 'My Orders',
    'منتجاتي': 'My Products',
    'لوحة المتجر': 'Store Dashboard',
    'لوحة الطلبات': 'Orders Board',
    'توصيلاتي': 'My Deliveries',
    'عناويني': 'My Addresses',
    'طلبات المتجر': 'Store Orders',
    'الإعدادات': 'Settings',
    'المظهر': 'Appearance',
    'اللغة': 'Language',
    'فاتح': 'Light',
    'غامق': 'Dark',
    'حسب النظام': 'System',
    'العربية': 'Arabic',
    'تم': 'Done',
    'حفظ': 'Save',
    'حفظ التعديلات': 'Save changes',
    'إلغاء': 'Cancel',
    'تأكيد': 'Confirm',
    'رجوع': 'Back',
    'بعدين': 'Later',
    'تجاهل': 'Dismiss',
    'تحديث': 'Refresh',
    'تحديث الحالة': 'Update status',
    'تحديث حالة الطلب': 'Update order status',
    'إعادة المحاولة': 'Try again',
    'إعادة التحميل': 'Reload',
    'حاول تاني': 'Try again',
    'الكل': 'All',
    'جديد': 'New',
    'جديدة': 'New',
    'جارية': 'Active',
    'السابقة': 'Previous',
    'منتهية': 'Completed',
    'مكتملة': 'Completed',
    'قيد التنفيذ': 'In progress',
    'ملغي': 'Cancelled',
    'مخفي': 'Hidden',
    'ظاهر للعملاء': 'Visible to customers',
    'الافتراضي': 'Default',
    'اجعله الافتراضي': 'Set as default',
    'حذف': 'Delete',
    'تعديل': 'Edit',
    'تفاصيل الطلب': 'Order details',
    'تفاصيل المنتج': 'Product details',
    'تفاصيل التسليم': 'Delivery details',
    'الفاتورة': 'Invoice',
    'ملخص الطلب': 'Order summary',
    'المنتجات': 'Products',
    'المنتج': 'Product',
    'الكمية': 'Quantity',
    'السعر (ج.م)': 'Price (EGP)',
    'الإجمالي': 'Total',
    'المتاح': 'Available',
    'المخزون': 'Stock',
    'الوصف': 'Description',
    'التصنيف': 'Category',
    'التصنيفات': 'Categories',
    'الاسم بالكامل': 'Full name',
    'البريد الإلكتروني': 'Email',
    'كلمة السر': 'Password',
    'رقم الموبايل': 'Phone number',
    'العنوان': 'Address',
    'وصف العنوان': 'Address details',
    'عنوان التوصيل': 'Delivery address',
    'عنوان التسليم': 'Delivery address',
    'عنوان المتجر': 'Store address',
    'موقع المتجر': 'Store location',
    'الموقع على الخريطة': 'Location on the map',
    'منطقة العمل': 'Work area',
    'طريقة الدفع': 'Payment method',
    'الدفع عند الوصول': 'Cash on delivery',
    'بطاقة فيزا / ماستركارد': 'Visa / Mastercard',
    'مدفوع أونلاين': 'Paid online',
    'مدفوع': 'Paid',
    'غير مدفوع': 'Unpaid',
    'مسترجع': 'Refunded',
    'تحصيل كاش': 'Collect cash',
    'دفع آمن ومشفر': 'Secure encrypted payment',
    'دفع أونلاين آمن بالكارت': 'Secure online card payment',
    'بتدفع كاش للمندوب وقت التسليم': 'Pay cash to the courier on delivery',
    'تأكيد الطلب (الدفع عند الوصول)': 'Confirm order (cash on delivery)',
    'إتمام الطلب': 'Checkout',
    'السلة فاضية': 'Your cart is empty',
    'السلة فاضية.': 'Your cart is empty.',
    'ضيف للسلة': 'Add to cart',
    'اشتري الآن': 'Buy now',
    'إفراغ السلة': 'Clear cart',
    'اكتب تعليقك (اختياري)': 'Write your comment (optional)',
    'تقييم الطيار': 'Rate the courier',
    'تقييمك للطيار': 'Your courier rating',
    'تقييمك': 'Your rating',
    'قيّم الطيار': 'Rate courier',
    'قيّم الدليفاري': 'Rate delivery',
    'إرسال التقييم': 'Submit rating',
    'تم تسجيل تقييمك، شكرًا!': 'Thanks! Your rating was submitted.',
    'الطلب لسه ما اتسندش لطيار.': 'This order has not been assigned to a courier yet.',
    'قيّم تجربتك مع الطيار وساعدنا نقدم خدمة أحسن.':
        'Rate your courier experience and help us improve.',
    'التقييم من 1 لـ 5 نجوم.': 'Rating is from 1 to 5 stars.',
    'قيّم الطيار وخلّي الناس تعرف تجربتك': 'Rate the courier and share your experience',
    'اتصل بالطيار': 'Call courier',
    'كلمني قبل ما توصل': 'Call me before you arrive',
    'رجوع للرئيسية': 'Back to home',
    'تابع طلباتك الحالية والسابقة': 'Track your current and previous orders',
    'تابع الطيار لحظة بلحظة على الخريطة': 'Track the courier live on the map',
    'تتبع الطلب': 'Track order',
    'تفاصيل الطلب والخريطة': 'Order details and map',
    'فتح الخريطة كاملة': 'Open full map',
    'هتظهر المسافة المتبقية بين الطيار وعنوانك لحظة ما الطيار يبدأ التوصيل.':
        'The remaining distance appears when the courier starts delivery.',
    'خط مباشر (تقديري)': 'Direct line (estimated)',
    'حسب الطريق': 'By road',
    'الطيار المسؤول': 'Assigned courier',
    'مراحل الطلب': 'Order timeline',
    'وقت الإنشاء': 'Created at',
    'وقت التسليم': 'Delivered at',

    // ---------------- Home / catalog ----------------
    'بتدور على إيه النهاردة؟': 'What are you looking for today?',
    'اطلب من الصفحة الرئيسية واتابع الطلب لحظة بلحظة':
        'Order from home and track it in real time',
    'اتفرج على المنتجات، اطلب، وتابع الطلب لحد باب البيت':
        'Browse products, order, and track to your door',
    'توصيل سريع': 'Fast delivery',
    'منتج طازج بيتوصل لباب البيت في أسرع وقت.':
        'Fresh products delivered to your door quickly.',
    'عروض النهاردة': "Today's offers",
    'منتجات أخرى': 'More products',
    'جرّب تبحث بكلمة تانية أو اختار تصنيف مختلف':
        'Try another search or category',
    'مفيش منتجات في المفضلة': 'No favorites yet',
    'اضغط على القلب في أي منتج علشان تحفظه هنا':
        'Tap the heart on a product to save it here',
    'اتضاف للسلة 🛒': 'Added to cart 🛒',
    'اتضاف للمفضلة ❤️': 'Added to favorites ❤️',
    'اتشال من المفضلة': 'Removed from favorites',
    'ضيف منتجات من الصفحة الرئيسية وابدأ الطلب':
        'Add products from home to start an order',
    'مش قادرين نجيب التصنيفات': "Couldn't load categories",
    'التصنيفات لسه ما اتحملتش — اضغط "حاول تاني" فوق.':
        'Categories not loaded yet — tap "Try again" above.',
    'مفيش تصنيفات متاحة على السيرفر.':
        'No categories available on the server.',
    'الطلب من أي متجر في بلدك لحد باب البيت':
        'Order from any store in your town to your door',
    'طلبك من أي متجر في بلدك لحد باب البيت':
        'Your order from any store in your town to your door',
    'الطلب دا خلص من المخزن': 'This product is out of stock',
    'خلص من المخزن': 'Out of stock',
    'منتج جديد': 'New product',

    // ---------------- Auth / roles ----------------
    'سجل دخولك بأي دور': 'Sign in with any role',
    'اختار نوع حسابك وابدأ حالًا': 'Choose your account type and get started',
    'بائع / متجر': 'Seller / Store',
    'مشتري': 'Buyer',
    'عميل': 'Customer',
    'بائع': 'Seller',
    'نوع الحساب': 'Account type',
    'تسجيل الدخول': 'Log in',
    'تسجيل الخروج': 'Sign out',
    'إنشاء الحساب': 'Create account',
    'حساب جديد': 'New account',
    'دخول': 'Sign in',
    'دخول سريع للتجربة': 'Quick demo login',
    'حسابات للتجربة (كلمة السر: 123456)': 'Demo accounts (password: 123456)',
    'عندك حساب بالفعل؟': 'Already have an account?',
    'عندك حساب؟ سجل دخول': 'Have an account? Sign in',
    'معندكش حساب؟ اعمل حساب جديد': 'No account? Create one',
    'رجوع لاختيار نوع حساب تاني': 'Back to account type',
    'اتعمل الحساب! افتح إيميلك وأكد الحساب، وبعدين سجّل دخول من شاشة الدخول.':
        'Account created! Confirm your email, then sign in.',
    'لازم تأكد بريدك الإلكتروني الأول.': 'Please confirm your email first.',
    'اكتب الاسم': 'Enter your name',
    'اكتب البريد الإلكتروني': 'Enter your email',
    'اكتب كلمة السر': 'Enter your password',
    'اكتب رقم الموبايل': 'Enter your phone number',
    'تعديل البيانات': 'Edit profile',
    'ملفي الشخصي': 'My profile',
    'حالة الاستلام': 'Availability',
    'متاح لاستلام الطلبات القريبة': 'Available for nearby orders',
    'غير متاح حاليًا': 'Currently unavailable',
    'أنت متاح لاستلام طلبات جديدة': 'You are available for new orders',
    'توقفت عن استلام الطلبات': 'You stopped receiving orders',
    'متوقف عن استلام الطلبات': 'Not receiving orders',
    'فعّل حالة "متاح" علشان توصلك الطلبات القريبة منك':
        'Enable "Available" to receive nearby orders',
    'فعّل حالة "متاح" الأول علشان تقدر تستلم طلبات.':
        'Enable "Available" first to accept orders.',
    'محتاجين نحدد موقعك الأول علشان تقدر تستلم طلبات.':
        'We need your location first so you can receive orders.',
    'الطلب مش متاح ليك: بعيد عن المتجر أو خارج نطاق بلدك.':
        'This order is not available to you: too far from the store or outside your country.',
    'الطلب بعيد عن المتجر أو خارج نطاق بلدك.':
        'The order is too far from the store or outside your country.',
    'هتقدر تفعّل حالة "متاح" من لوحة الطلبات علشان توصلك الطلبات الأقرب ليك.':
        'Enable "Available" from the orders board to receive the closest orders.',
    'الحساب موجود لكن الملف الشخصي غير متاح، حاول تاني.':
        'The account exists but the profile is unavailable, try again.',
    'مفيش بيانات للمستخدم دا.': 'No data for this user.',
    'المستخدم غير موجود.': 'User not found.',

    // ---------------- Orders ----------------
    'طلباتك الحالية': 'Current orders',
    'مفيش طلبات جارية': 'No active orders',
    'مفيش طلبات سابقة': 'No previous orders',
    'مفيش طلبات جديدة': 'No new orders',
    'مفيش طلبات قيد التنفيذ': 'No orders in progress',
    'مفيش طلبات منتهية': 'No completed orders',
    'مفيش طلبات متاحة دلوقتي': 'No orders available right now',
    'طلبات جاهزة قريبة منك': 'Ready orders near you',
    'طلبات معروضة عليك (أنت الأقرب)': 'Offered orders (you are closest)',
    'طلبات جديدة': 'New orders',
    'الطلبات': 'Orders',
    'بانتظار موافقة المتجر': 'Waiting for store approval',
    'المتجر قبل الطلب': 'Store accepted the order',
    'جاري التجهيز': 'Preparing',
    'جاهز للاستلام': 'Ready for pickup',
    'طيار في الطريق للمتجر': 'Courier heading to store',
    'الطيار استلم الطلب': 'Courier picked up the order',
    'في الطريق إليك': 'On the way to you',
    'تم التسليم': 'Delivered',
    'بانتظار طيار': 'Waiting for a courier',
    'جاري التعيين': 'Assigning courier',
    'الطلب في الطريق للعميل': 'Order on the way to customer',
    'تم استلام الطلب من المتجر': 'Order picked up from store',
    'تم تعيين الطيار': 'Courier assigned',
    'تم تعيين طيار للطلب': 'Courier assigned to order',
    'تم إنشاء الطلب': 'Order created',
    'تم قبول الطلب': 'Order accepted',
    'تم إلغاء الطلب': 'Order cancelled',
    'تم تسليم الطلب': 'Order delivered',
    'تم تحديث حالة الطلب': 'Order status updated',
    'الطلب غير موجود.': 'Order not found.',
    'الطلب دا ملغي.': 'This order is cancelled.',
    'الطلب دا تم تسليمه بالفعل.': 'This order has already been delivered.',
    'الطلب دا خداه طيار تاني.': 'Another courier took this order.',
    'الطلب اتقفل خلاص، مش ممكن يتلغي.':
        'This order is closed and cannot be cancelled.',
    'الطلب بدأ التجهيز، مش ممكن يتلغي دلوقتي.':
        'This order is being prepared and cannot be cancelled now.',
    'الإلغاء متاح للطلبات "الدفع عند الاستلام" فقط — الطلب دا مدفوع أونلاين.':
        'Cancellation is only available for cash-on-delivery orders — this order is paid online.',
    'مش ممكن تلغي الطلب دا: الإلغاء متاح للدفع عند الاستلام فقط.':
        'You cannot cancel this order: cancellation is only for cash on delivery.',
    'تأكيد الإلغاء': 'Confirm cancellation',
    'إلغاء الطلب': 'Cancel order',
    'إلغاء الطلب (الدفع عند الاستلام)': 'Cancel order (cash on delivery)',
    'تم إنشاء طلبك بنجاح 🎉': 'Your order was created successfully 🎉',
    'تم تسليم الطلب بنجاح 🎉': 'Order delivered successfully 🎉',
    'وصل الطلب لباب البيت 🎉': 'Your order arrived at your door 🎉',
    'الطلب دا الدفع عند الاستلام، فمفيش أي مبالغ اتدفعت.':
        'This is a cash-on-delivery order, so no payment was made.',
    'الطلب جاهز للاستلام': 'Order is ready for pickup',
    'الطلب معروض على أقرب طيار متاح':
        'Order is offered to the nearest available courier',
    'المتجر ألغى الطلب': 'Store cancelled the order',
    'الطيار ألغى الطلب (الدفع عند الاستلام)':
        'Courier cancelled the order (cash on delivery)',
    'الطيار استلم الطلب من المتجر': 'Courier picked up the order from the store',
    'الطيار استلم الطلب وبدأ التوصيل':
        'Courier picked up the order and started delivery',
    'المتجر بيجهز الموافقة على طلبك': 'The store is reviewing your order',
    'المتجر هيبدأ يجهز طلبك حالًا': 'The store will start preparing your order now',
    'طلبك مقبول وجاري التحضير': 'Your order is accepted and being prepared',
    'بنحضر منتجاتك حالًا': 'We are preparing your products now',
    'الطلب اتلغى': 'Order cancelled',
    'تم تجاهل الطلب وعرضه على طيار تاني':
        'Order was ignored and offered to another courier',
    'قبل الطيار الطلب وهو في الطريق للمتجر':
        'Courier accepted the order on the way to the store',
    'قبل المتجر الطلب': 'Store accepted the order',
    'استلمت الطلب من المتجر': 'I picked up the order from the store',
    'سجلت استلام الطلب من المتجر': 'You marked the order as picked up',
    'الطلب لسه مش جاهز للاستلام من المتجر.':
        'The order is not ready for pickup from the store yet.',

    // ---------------- Cart / checkout / payment ----------------
    'السلة فاضية، ضيف منتجات الأول.': 'Your cart is empty. Add products first.',
    'بنجهز بيانات الطلب...': 'Preparing your order...',
    'بنجهز المنتجات...': 'Preparing products...',
    'ضيف عنوان للتوصيل': 'Add a delivery address',
    'اختار عنوان التوصيل من الخريطة.': 'Choose the delivery address from the map.',
    'اكتب العنوان بالتفصيل': 'Enter the full address',
    'اكتب تفاصيل العنوان.': 'Enter address details.',
    'اكتب وصف العنوان (اسم الشارع / علامة مميزة).':
        'Enter address details (street / landmark).',
    'مثال: شارع الجيش - عمارة 12 - الدور 3':
        'Example: El Geish St - Building 12 - Floor 3',
    'مثال: كلمني قبل ما توصل، الدور الثالث':
        'Example: Call me before arrival, third floor',
    'تأكيد العنوان': 'Confirm address',
    'تحديد العنوان على الخريطة': 'Set address on map',
    'اضغط على الخريطة لتحديد مكان التسليم بالظبط':
        'Tap the map to set the exact delivery location',
    'عنوان جديد': 'New address',
    'مفيش عناوين محفوظة': 'No saved addresses',
    'البيت': 'Home',
    'الشغل': 'Work',
    'أخرى': 'Other',
    'تم حفظ العنوان ✅': 'Address saved ✅',
    'ضيف عنوان من الخريطة علشان تعرف توصل طلباتك بسرعة':
        'Add an address from the map for faster delivery',
    'رقم الكارت': 'Card number',
    'رقم الكارت لازم 16 رقم': 'Card number must be 16 digits',
    'اكتب رقم الكارت': 'Enter card number',
    'رقم الكارت غير صحيح': 'Invalid card number',
    'الكارت منتهي الصلاحية': 'Card has expired',
    'الدولة': 'Country',
    'CVV غير صحيح': 'Invalid CVV',
    'بيانات الكارت غير مكتملة.': 'Card details are incomplete.',
    'الصيغة الصحيحة MM/YY': 'Correct format is MM/YY',
    'شهر غير صحيح': 'Invalid month',
    'رقم غير صحيح': 'Invalid number',
    'سعر غير صحيح': 'Invalid price',
    'بالضغط على تأكيد الطلب أنت موافق على شروط الخدمة وسياسة الاسترجاع.':
        'By confirming the order you agree to the terms of service and refund policy.',
    'ملاحظات للمتجر أو الطيار': 'Notes for the store or courier',
    'ملاحظات': 'Notes',
    'السلة': 'Cart',
    'متجر': 'Store',
    'دليفاري المتجر دا:': 'Delivery for this store:',

    // ---------------- Courier ----------------
    'شوف الطلبات القريبة منك ووصّلها وكسب':
        'Find nearby orders, deliver them, and earn',
    'الطلبات بتتوزع على الطيارين حسب أقرب موقع للمتجر':
        'Orders are assigned to couriers by nearest store location',
    'مصاريف الدليفاري': 'Delivery fee',
    'أرباح اليوم': "Today's earnings",
    'إجمالي أرباحك': 'Total earnings',
    'إجمالي الأرباح': 'Total earnings',
    'توصيلات مكتملة': 'Completed deliveries',
    'مفيش توصيلات جارية': 'No active deliveries',
    'مفيش توصيلات مكتملة': 'No completed deliveries',
    'بنجيب توصيلاتك...': 'Loading your deliveries...',
    'بنجهز طلباتك القريبة...': 'Loading nearby orders...',
    'بنجيب موقعك...': 'Getting your location...',
    'موقعك الحالي مش متحدد - الطلبات بتتحسب من آخر موقع معروف':
        'Your location is not set — orders use your last known location',
    'موقعي الحالي': 'My current location',
    'استخدم موقعي الحالي': 'Use my current location',
    'حدد موقع على الخريطة (Google Maps)': 'Pick a location on Google Maps',
    'تحديد الموقع على Google Maps': 'Pick location on Google Maps',
    'اقبل طلب من اللوحة وابدأ التوصيل':
        'Accept an order from the board and start delivery',
    'استلم وجهّز الطلبات': 'Receive and prepare orders',
    'مفيش توصيلات': 'No deliveries',
    'أرباحك': 'Your earnings',
    'المشوار': 'Trip',
    'منك للمتجر': 'To store',
    'الطيار فاضل عليه': 'Courier is away',
    'الطلب مستني الطيار يستلمه': 'Order is waiting for a courier',
    'بنجيب التصنيفات...': 'Loading categories...',
    'استنى شوية، أول ما متجر يجهّز طلب قريب منك هيوصلك إشعار هنا':
        'Wait a moment — when a nearby store prepares an order, you will be notified here.',
    'هتقدر تضيف عناوينك على الخريطة وتتابع طلباتك لحظة بلحظة.':
        'You can add addresses on the map and track orders in real time.',
    'أول ما تسلّم طلب هيظهر هنا مع أرباحه':
        'Your first delivered order will appear here with its earnings.',

    // ---------------- Seller ----------------
    'إدارة المنتجات والأسعار': 'Manage products and prices',
    'إضافة منتج': 'Add product',
    'إضافة منتج جديد': 'Add new product',
    'إضافة المنتج': 'Add product',
    'تعديل المنتج': 'Edit product',
    'اسم المنتج': 'Product name',
    'اكتب اسم المنتج': 'Enter product name',
    'صورة المنتج': 'Product image',
    'رابط صورة المنتج': 'Product image URL',
    'صوّر المنتج': 'Take product photo',
    'من المعرض': 'From gallery',
    'شيل الصورة المختارة': 'Remove selected image',
    'الصورة المختارة هتترفع لما تحفظ':
        'The selected image will upload when you save',
    'الصورة كبيرة أوي — الحد الأقصى 5 ميجا.':
        'Image is too large — max 5 MB.',
    'نوع الصورة مش مدعوم، جرّب صورة JPG أو PNG.':
        'Unsupported image type, try JPG or PNG.',
    'مش قادرين نرفع الصورة، حاول تاني.': "Couldn't upload the image, try again.",
    'بنرفع الصورة...': 'Uploading image...',
    'ضيف منتجاتك واستلم الطلبات وجهزها':
        'Add your products, receive, and prepare orders',
    'ضيف أول منتج وابدأ تستقبل طلبات من العملاء':
        'Add your first product and start receiving customer orders',
    'مفيش منتجات لسه': 'No products yet',
    'حذف المنتج': 'Delete product',
    'حذف منتجات المتجر': 'Delete store products',
    'اتحفظ المنتج ✅': 'Product saved ✅',
    'سعر المنتج لازم يكون أكبر من صفر.':
        'Product price must be greater than zero.',
    'المنتج دا خلص من المخزن حاليًا.': 'This product is out of stock.',
    'المنتج غير موجود أو تم حذفه.': 'Product not found or deleted.',
    'الموجود من المنتج دا': 'Available from this product',
    'لو قفلته المنتج مش هيظهر في السوق':
        'If disabled, the product will not appear in the market',
    'عنوان المنتج مطلوب.': 'Product name is required.',
    'إجمالي المنتجات': 'Total products',
    'إجمالي المبيعات': 'Total sales',
    'إجراءات سريعة': 'Quick actions',
    'اسم المتجر': 'Store name',
    'منتجات المتجر': 'Store products',
    'مفيش منتجات': 'No products',
    'منتجات': 'Products',

    // ---------------- Profile / addresses ----------------
    'محتاجين صلاحية الموقع علشان نحدد عنوانك ونتبع الطلب. تقدر تفعّلها من إعدادات الموبايل.':
        'We need location permission to set your address and track the order. You can enable it from phone settings.',
    'تعذر تحديد موقعك، اتأكد إن خدمة الموقع شغالة وجرب تاني.':
        'Could not determine your location. Make sure location service is on and try again.',
    'خدمة تحديد الموقع مقفولة، فعّلها من إعدادات الموبايل.':
        'Location service is off, enable it from phone settings.',
    'خدمة تحديد الموقع مش بتستجيب، جرب تاني.':
        'Location service is not responding, try again.',
    'لسه محددتش موقعك. تحديد الموقع مهم لحساب مصاريف الدليفاري.':
        'You have not set your location. It is needed to calculate delivery fees.',
    'لسه محددتش موقع المتجر': 'Store location not set yet',
    'لسه محددتش عنوان المتجر': 'Store address not set yet',
    'حدّد موقع المتجر من تعديل البيانات علشان توصلك الطلبات الأقرب':
        'Set the store location from Edit Profile to receive nearby orders.',
    'location_permission_settings':
        'Location permission is needed. Enable it from phone settings.',
    'هتقدر تحدد موقع المتجر من الملف الشخصي بعد التسجيل لتظهر لك الطلبات القريبة.':
        'You can set the store location from your profile after registration to see nearby orders.',
    'موقع المتجر بيحدد مصاريف الدليفاري ويحدد أقرب طيار لطلباتك.':
        'The store location determines delivery fees and the nearest courier.',
    'الطلبات الحالية والمكتملة وأرباحك':
        'Current and completed orders and your earnings',
    'تعديل بيانات المتجر وموقعها': 'Edit store details and location',

    // ---------------- Errors / validation ----------------
    'حصل خطأ غير متوقع، حاول تاني.': 'Unexpected error, try again.',
    'فيه مشكلة في الاتصال بالإنترنت.': 'There is an internet connection problem.',
    'في مشكلة في الاتصال بالإنترنت.': 'There is an internet connection problem.',
    'السيرفر مش بيرد دلوقتي، اتأكد من الإنترنت وحاول تاني.':
        'The server is not responding. Check your internet and try again.',
    'مش قادرين ننشئ الطلب، حاول تاني.': "Couldn't create the order, try again.",
    'مش قادرين نحفظ السلة.': "Couldn't save the cart.",
    'مش قادرين نحفظ المفضلة.': "Couldn't save favorites.",
    'مش قادرين نقرأ السلة المحفوظة.': "Couldn't read the saved cart.",
    'مش قادرين نحمل الطلب': "Couldn't load the order",
    'مش قادرين نلاقي البيانات المطلوبة.': "Couldn't find the required data.",
    'مش مسموحلك تعمل العملية دي.': 'You are not allowed to do this.',
    'لازم تسجل دخول الأول.': 'Please sign in first.',
    'فشل تسجيل الدخول، حاول تاني.': 'Sign-in failed, try again.',
    'البريد الإلكتروني أو كلمة السر غير صحيحة.':
        'Incorrect email or password.',
    'البريد الإلكتروني اللي كتبته مش صحيح، راجعه أو اكتبه من جديد.':
        'The email is invalid, please check it or enter it again.',
    'البريد الإلكتروني مسجل بالفعل، سجل دخول من فضلك.':
        'Email is already registered, please sign in.',
    'كلمة السر لازم 6 حروف على الأقل':
        'Password must be at least 6 characters',
    'كلمة السر ضعيفة، اختار كلمة سر أقوى.':
        'Weak password, choose a stronger one.',
    'كلمة السر غير صحيحة.': 'Incorrect password.',
    'رقم الموبايل غير صحيح': 'Invalid phone number',
    'صيغة البريد الإلكتروني غير صحيحة': 'Invalid email format',
    'الاسم مطلوب.': 'Name is required.',
    'الحقل دا مطلوب': 'This field is required',
    'حدث خطأ أثناء إنشاء الحساب.':
        'An error occurred while creating the account.',
    'حدث خطأ أثناء تسجيل الدخول.':
        'An error occurred while signing in.',
    'مش قادرين ننشئ الحساب، حاول تاني.':
        "Couldn't create the account, try again.",
    'مفيش حساب بالبريد الإلكتروني دا.': 'No account with this email.',
    'تعذر التحقق من جلسة تسجيل الدخول.':
        'Could not verify the login session.',
    'تعذر تسجيل الخروج.': 'Could not sign out.',
    'مش قادرين نفتح الاتصال.': 'Could not open the call.',
    'مش قادرين نفتح الصور، حاول تاني.': "Couldn't open images, try again.",
    'مشكلة في رفع الملفات، حاول تاني.': 'File upload problem, try again.',
    'حصلت مشكلة في قاعدة البيانات، حاول تاني.':
        'Database problem, try again.',
    'مش قادرين نحدّث المخزون، حاول تاني.':
        "Couldn't update the stock, try again.",
    'الكمية المطلوبة من "المنتج" مش متاحة في المخزون.':
        'The requested quantity is not available in stock.',
    'المنتج مش موجود.': 'Product not found.',
    'فيه بيانات مرتبطة ناقصة.': 'Some related data is missing.',
    'حاول تاني بعد شوية.': 'Try again in a moment.',
    'لسه مفيش تحديثات على الطلب.': 'No order updates yet.',
    'مفيش طلبات': 'No orders',
    'مفيش منتجات مطابقة': 'No matching products',
    'صفحة غير موجودة': 'Page not found',
    'المسار المطلوب غير موجود.': 'The requested route does not exist.',

    // ---------------- Demo data ----------------
    'أحمد محمود': 'Ahmed Mahmoud',
    'محمود الدليفاري': 'Mahmoud the Courier',
    'سوبر ماركت البلد': 'El Balad Supermarket',
    'خضار وفاكهة العمدة': 'El Omda Fruits & Vegetables',
    'أرز مصري فاخر 1 كجم': 'Premium Egyptian rice 1 kg',
    'برتقال عصير 1 كجم': 'Juicing oranges 1 kg',
    'بطاطس 1 كجم': 'Potatoes 1 kg',
    'جزر 1 كجم': 'Carrots 1 kg',
    'خيار 1 كجم': 'Cucumbers 1 kg',
    'طماطم بلدي 1 كجم': 'Local tomatoes 1 kg',
    'موز 1 كجم': 'Bananas 1 kg',
    'ليمون 1 كجم': 'Lemons 1 kg',
    'فراولة 500 جم': 'Strawberries 500 g',
    'عيش بلدي 10 أرغفة': 'Baladi bread 10 loaves',
    'لبن جهينة 1 لتر': 'Juhayna milk 1 L',
    'زيت ذرة 1 لتر': 'Corn oil 1 L',
    'سكر ناعم 1 كجم': 'Fine sugar 1 kg',
    'شاي العروسة 250 جم': 'El Arousa tea 250 g',
    'صابون أطباق 1 لتر': 'Dish soap 1 L',
    'مسحوق غسيل 3 كجم': 'Laundry powder 3 kg',
    'كريم سريع': 'Quick cream',
    'بقالة': 'Grocery',
    'خضار وفاكهة': 'Fruits & vegetables',
    'فاكهة وخضار': 'Fruits & vegetables',
    'مخبوزات': 'Bakery',
    'مشروبات': 'Drinks',
    'منظفات': 'Cleaning',
    'شبين الكوم': 'Shebin El Kom',
    'شبين الكوم - جامعة المنوفية - بوابة 2':
        'Shebin El Kom - Menoufia University - Gate 2',
    'شبين الكوم - سوق الخضار': 'Shebin El Kom - Vegetable Market',
    'شبين الكوم - شارع الجيش - عمارة 12 - الدور 3':
        'Shebin El Kom - El Geish St - Building 12 - Floor 3',
    'شبين الكوم - شارع الجيش - عمارة 12':
        'Shebin El Kom - El Geish St - Building 12',
    'شبين الكوم - ميدان الساعة': 'Shebin El Kom - Clock Square',
    'وصل بسرعة وبأدب، شكرًا.': 'Fast and polite, thank you.',
    'مشتري: buyer@elbalad.app': 'Buyer: buyer@elbalad.app',
    'بائع: seller@elbalad.app': 'Seller: seller@elbalad.app',
    'ديليفاري: courier@elbalad.app': 'Courier: courier@elbalad.app',
    'الوضع التجريبي: البيانات محلية. ضيف SUPABASE_URL و SUPABASE_ANON_KEY لتشغيل الباك إند.':
        'Demo mode: local data. Add SUPABASE_URL and SUPABASE_ANON_KEY to run the backend.',

    // ---------------- Strings added after the first translation pass ----------------
    'الطيار في الطريق إليك': 'Courier on the way to you',
    'المتجر': 'Store',
    'الصفحة دي مخصصة لحسابات الدليفاري.': 'This page is for courier accounts.',
    'جاري تجهيز الطلب': 'Preparing the order',
    'قبول الطلب': 'Accept order',
    'في الطريق للعميل': 'On the way to the customer',
    'رفض': 'Reject',
    'ابدأ التجهيز': 'Start preparing',
    'خلاص': 'All done',
    'الانتهاء': 'Expiry',
    'الطيار': 'Courier',
    'متاح لاستلام طلبات': 'Available for new orders',
    'اتفرج على المنتجات': 'Browse products',
    'تم إنشاء الطلب ودفع أونلاين': 'Order created and paid online',
    'تم تعيين الطيار للطلب': 'Courier assigned to the order',
    'تم تحديث البيانات ✅': 'Data updated ✅',
    'بنسجل التقييم...': 'Submitting your rating...',
    'تتبع الطلب على الخريطة': 'Track the order on the map',
    'المظهر واللغة': 'Appearance and language',
    'واجهة عربية بالكامل واتجاه من اليمين لليسار':
        'Fully Arabic interface with right-to-left layout',
    'التغيير بيتم فورًا، واختيارك بيتحفظ علشان يفضل معاك في المرة الجاية.':
        'Changes apply instantly, and your choice is saved for next time.',
    'تقدر تغيّر حالتك من لوحة الطلبات في التاب الأول.':
        'You can change your status from the orders board in the first tab.',
    'طيار متاح قبل الطلب وهو رايح للمتجر':
        'An available courier accepted the order and is heading to the store',
    'البيانات مسجلة بالفعل.': 'The data is already registered.',
    'محاولات كتير، استنى شوية وحاول تاني.':
        'Too many attempts, wait a bit and try again.',
    'الآن': 'Just now',
    'خلص': 'Sold out',
    'طلب جديد': 'New order',
    'الإشعارات': 'Notifications',
    'تعليم الكل كمقروء': 'Mark all as read',
    'مفيش إشعارات': 'No notifications',
    'هنوصلك هنا أي تحديث على حالة طلباتك':
        'We will send you any update about your orders here',
    'إشعار جديد': 'new notification',
    'تحديثات حالة الطلبات': 'Order status updates',
    'وصلنا للحد الأقصى لإرسال الإيميلات، استنى شوية أو اقفل تأكيد الإيميل من إعدادات Supabase.':
        'We reached the email sending limit. Wait a bit or disable email confirmation in Supabase settings.',
    'مش قادر نلاقي البيانات المطلوبة.': "Couldn't find the required data.",
    'حصل تعارض في اسم الصورة، جرّب تاني.': 'Image name conflict, try again.',
    'مش مسموح برفع الصور للحساب دا — اتأكد إنك مسجل كتاجر وإن السكيما اتشغلت.':
        'Image upload is not allowed for this account — make sure you are a registered seller and the schema has been applied.',
    'رفع الصور متاح لما التطبيق يكون متوصل بـ Supabase.':
        'Image upload is available when the app is connected to Supabase.',
    'خدمة الصور لسه مش متظبطة على Supabase — شغّل ملف schema.sql من SQL Editor.':
        'Image storage is not configured on Supabase yet — run schema.sql from the SQL Editor.',
    'لو دي أول مرة، شغّل ملف supabase/schema.sql من SQL Editor على Supabase.':
        'If this is the first time, run the supabase/schema.sql file from the SQL Editor on Supabase.',
    'صلاحية الموقع متقفلة للحساب دا. افتح إعدادات الموبايل → التطبيقات → ديليفاري البلد وفعّل الموقع.':
        'Location permission is disabled for this account. Open phone settings → Apps → Delivery Elbalad and enable location.',
  };
}
