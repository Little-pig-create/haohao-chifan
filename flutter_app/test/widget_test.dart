import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haohao_chifan/data/demo_data.dart';
import 'package:haohao_chifan/screens/activity_screen.dart';
import 'package:haohao_chifan/screens/auth_screen.dart';
import 'package:haohao_chifan/screens/diet_screen.dart';
import 'package:haohao_chifan/screens/onboarding_screen.dart';
import 'package:haohao_chifan/screens/today_screen.dart';
import 'package:haohao_chifan/services/media_permission.dart';
import 'package:haohao_chifan/state/app_state.dart';
import 'package:haohao_chifan/theme.dart';
import 'package:haohao_chifan/widgets/common.dart';
import 'package:haohao_chifan/widgets/water_tip.dart';

void main() {
  testWidgets('auth screen renders', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.light(), home: const AuthScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('先认识一下你'), findsOneWidget);
    expect(find.text('以游客身份开始'), findsOneWidget);
  });

  testWidgets('onboarding walks new users through goals and AI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState()
      ..completeProfile(
        name: 'Alex',
        gender: '男',
        age: 30,
        heightCm: 175,
        weightKg: 70,
      );
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('先定一个\n够得着的目标'), findsOneWidget);
    expect(find.text('下一步：配置 AI'), findsOneWidget);

    await tester.tap(find.text('下一步：配置 AI'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.goalsConfigured, isTrue);
    expect(find.text('接上你自己的\nAI 引擎'), findsOneWidget);
    expect(find.text('连接并启用'), findsOneWidget);

    await tester.tap(find.text('稍后配置，先开始记录'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('已经可以开始了'), findsOneWidget);
    await tester.tap(find.text('开始记录'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.onboardingSeen, isTrue);
  });

  testWidgets('meal add flow offers search, library, photo and sentence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: DietScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('还没有任何饮食记录'), findsOneWidget);
    expect(find.textContaining('还没记录'), findsNothing);
    expect(find.text('记一餐'), findsOneWidget);
    await tester.tap(find.text('记一餐'));
    await tester.pumpAndSettle();

    expect(find.text('搜索食物'), findsOneWidget);
    expect(find.text('从菜品库添加'), findsOneWidget);
    expect(find.text('拍照识别'), findsOneWidget);
    expect(find.text('一句话记录'), findsOneWidget);

    await tester.tap(find.text('搜索食物'));
    await tester.pumpAndSettle();
    expect(find.text('搜索记录'), findsOneWidget);

    await tester.tap(find.text('鸡胸肉'));
    await tester.pump();
    await tester.tap(find.textContaining('鸡胸肉 ·'));
    await tester.pumpAndSettle();
    expect(
      state.addedFor(state.selectedDay).any((meal) => meal.title == '鸡胸肉'),
      isTrue,
    );

    await tester.tap(find.text('记一餐'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从菜品库添加'));
    await tester.pumpAndSettle();
    expect(find.text('全部菜品通用，可多选后一起记到某一餐。'), findsOneWidget);

    final kind = state.defaultMealKind;
    final dishes = dishPool.take(2).toList();
    for (final dish in dishes) {
      await tester.tap(find.text(dish.title).last);
      await tester.pump();
    }
    await tester.tap(find.textContaining('记到$kind'));
    await tester.pumpAndSettle();
    final logged = state
        .addedForKind(state.selectedDay, kind)
        .map((meal) => meal.title)
        .toSet();
    expect(logged, containsAll(dishes.map((dish) => dish.title)));
  });

  testWidgets('water card plays a stamp animation when adding a glass', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var glasses = 2;
    var adds = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return WaterCard(
                  glasses: glasses,
                  goal: 8,
                  cupMl: 250,
                  targetMl: 2000,
                  onSet: (value) => setState(() => glasses = value),
                  onAdd: () {
                    adds++;
                    setState(() => glasses++);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump(const Duration(milliseconds: 80));

    expect(adds, 1);
    expect(find.byKey(const ValueKey('water-stamp')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const ValueKey('water-stamp')), findsNothing);
  });

  testWidgets('permission prompt offers cancel and settings actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMediaPermissionPrompt(
                context,
                kind: MediaAccessKind.gallery,
              ),
              child: const Text('打开权限提示'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开权限提示'));
    await tester.pumpAndSettle();
    expect(find.text('需要相册权限'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('去设置'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('需要相册权限'), findsNothing);
  });

  testWidgets('activity page splits manual and AI exercise logging', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ActivityScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('手动记录运动'), findsOneWidget);
    expect(find.text('AI 速记'), findsOneWidget);
    expect(find.text('添加运动'), findsNothing);
  });

  testWidgets('home exercise action opens manual and AI choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: TodayScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('记运动'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('记录运动'), findsOneWidget);
    expect(find.text('手动记录运动'), findsOneWidget);
    expect(find.text('AI 速记'), findsOneWidget);
  });
}
