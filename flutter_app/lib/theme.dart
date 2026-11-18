import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFFF6F7F4);
  static const paperDeep = Color(0xFFEDF0E9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF2F4EF);
  static const ink = Color(0xFF111713);
  static const ink2 = Color(0xFF3D4741);
  static const muted = Color(0xFF79837B);
  static const line = Color(0xFFE9ECE6);
  static const lineSoft = Color(0xFFF1F3EE);
  static const green = Color(0xFF17211A);
  static const green2 = Color(0xFF4F6B43);
  static const greenInk = Color(0xFF101611);
  static const sage = Color(0xFFB8C9B3);
  static const cream = Color(0xFFF7F9F2);
  static const cream2 = Color(0xFFF1F6E4);
  static const apricot = Color(0xFFE8B892);
  static const clay = Color(0xFFDF9B86);
  static const gold = Color(0xFFD6B26C);
  static const blue = Color(0xFFA9C6D1);
  static const accent = Color(0xFFCFF36B);
  static const accentSoft = Color(0xFFEEF9D7);
  static const mint = Color(0xFFF2F9E5);
  static const lavender = Color(0xFFF0EFF8);
  static const peach = Color(0xFFFAEDE3);
}

class AppRadius {
  static const card = 10.0;
  static const hero = 14.0;
  static const field = 10.0;
  static const chip = 8.0;
  static const pill = 999.0;
}

class AppSpacing {
  static const page = 16.0;
  static const card = 16.0;
  static const gap = 12.0;
  static const gapSmall = 8.0;
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
      surface: AppColors.surface,
      primary: AppColors.green,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      splashFactory: InkSparkle.splashFactory,
      fontFamilyFallback: const [
        'NotoSansSC',
        'PingFang SC',
        'HarmonyOS Sans SC',
        'Noto Sans CJK SC',
        'Noto Sans SC',
        'Microsoft YaHei',
      ],
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink, height: 1.55),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: AppColors.ink2,
          height: 1.55,
        ),
        bodySmall: TextStyle(
          fontSize: 11.5,
          color: AppColors.muted,
          height: 1.5,
        ),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F8F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: Color(0xFF98A198), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.green2, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.fromLTRB(18, 0, 18, 96),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lineSoft,
        thickness: 1,
      ),
    );
  }
}

TextStyle displayStyle({
  double size = 30,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w600,
  double height = 1.18,
  double letterSpacing = -0.4,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const [
      'NotoSansSC',
      'PingFang SC',
      'HarmonyOS Sans SC',
      'Noto Sans CJK SC',
      'Noto Sans SC',
      'Microsoft YaHei',
    ],
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle titleStyle({
  double size = 19,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w700,
  double height = 1.3,
}) {
  return TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: -0.25,
  );
}

BoxDecoration cardDecoration({
  Color color = AppColors.surface,
  double radius = AppRadius.card,
  bool border = true,
  Gradient? gradient,
}) {
  return BoxDecoration(
    color: gradient == null ? color : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    border: border ? Border.all(color: AppColors.line) : null,
    boxShadow: const [
      BoxShadow(color: Color(0x06111713), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x0A111713),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );
}

const paleHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF0F9DF), Color(0xFFFFFFFF)],
);

const softGreenGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF4FAEA), Color(0xFFFFFFFF)],
);

const lavenderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF2F0FA), Color(0xFFFFFFFF)],
);

// 保留旧名字，避免影响已有组件；视觉上改成浅色，不再是深绿卡。
const darkGradient = paleHeroGradient;
