import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

import '../../core/localization/app_text.dart';
/// شاشة البداية الموحّدة: نفس خلفية ولوجو شاشة أندرويد الأصلية بالظبط،
/// مع مؤشر تحميل بيفضل ظاهر لحد ما التطبيق يخلص الأساسيات، وبعدها بندخل
/// على الصفحة اللي بعدها على طول (مفيش شاشة سوداء في النص).
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  static const double _logoSize = 104;
  static const String _tagline = 'طلبك من أي متجر في بلدك لحد باب البيت';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // اللوجو في نص الشاشة بالظبط — نفس مكانه في شاشة أندرويد الأصلية،
          // فمفيش "نطّة" لما فلاتر ياخد الشاشة.
          final logoTop = constraints.maxHeight / 2 - _logoSize / 2;
          final belowLogo = logoTop + _logoSize + 20;

          return Stack(
            children: [
              Positioned(
                top: logoTop,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: _logoSize,
                    height: _logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: belowLogo,
                left: 24,
                right: 24,
                child: Column(
                  children: [
                    const AppText(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const AppText(
                      _tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 26),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (AppConfig.isDemoMode)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: AppText(
                        AppConfig.demoNotice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
