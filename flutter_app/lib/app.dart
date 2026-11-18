import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/auth_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/ai_health_screen.dart';
import 'screens/diet_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/common.dart';

class HaohaoApp extends StatelessWidget {
  final AppState state;
  const HaohaoApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: '好好吃饭',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Gate(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: .9,
                maxScaleFactor: 1.2,
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: !state.guest || !state.profileComplete
          ? const AuthScreen(key: ValueKey('auth'))
          : !state.onboardingSeen
          ? const OnboardingScreen(key: ValueKey('onboarding'))
          : const MainShell(key: ValueKey('main')),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final PageController _controller = PageController();
  int _visibleTab = 0;
  Timer? _healthTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _healthTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      AppScope.of(context).refreshSteps();
    });
  }

  void _animateTo(int index) {
    if (!mounted || !_controller.hasClients) return;
    final current = (_controller.page ?? 0).round();
    if (current == index) return;
    final distance = (index - current).abs();
    _controller.animateToPage(
      index,
      duration: Duration(
        milliseconds: (260 + distance * 55).clamp(260, 520).toInt(),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.tab != _visibleTab) {
      _visibleTab = state.tab;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _animateTo(state.tab),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8F8F4), AppColors.paper, Color(0xFFF3F4EE)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  AppTopBar(onAvatarTap: () => openSettingsPage(context)),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (index) {
                        HapticFeedback.selectionClick();
                        state.setTab(index);
                      },
                      children: const [
                        KeepAlivePage(child: TodayScreen()),
                        KeepAlivePage(child: DietScreen()),
                        KeepAlivePage(child: ActivityScreen()),
                        KeepAlivePage(child: _InsightGroup()),
                        KeepAlivePage(child: AiHealthScreen()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: AppBottomNav()),
        ],
      ),
    );
  }
}

class _InsightGroup extends StatelessWidget {
  const _InsightGroup();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return GroupPager(
      labels: const ['营养分析', '报告'],
      selected: state.insightTab,
      onChanged: state.setInsightTab,
      children: const [
        NutritionScreen(key: ValueKey('nutrition')),
        ReportScreen(key: ValueKey('report')),
      ],
    );
  }
}

void openSettingsPage(BuildContext context) {
  Navigator.of(context).push(
    slidePageRoute(
      const SubpageFrame(title: '我的', child: SettingsScreen(embedded: true)),
    ),
  );
}
