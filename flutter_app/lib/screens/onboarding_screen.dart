import 'package:flutter/material.dart';

import '../services/llm_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'llm_settings_screen.dart';

void openOnboardingPage(BuildContext context, {int initialStep = 0}) {
  Navigator.of(context)
      .push(slidePageRoute(OnboardingScreen(initialStep: initialStep)));
}

/// 新用户设置向导：每日目标 → AI 引擎 → 完成。
class OnboardingScreen extends StatefulWidget {
  final int initialStep;

  const OnboardingScreen({super.key, this.initialStep = 0});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _calorieMin = 1200;
  static const _calorieMax = 3500;
  static const _waterMin = 1000;
  static const _waterMax = 4000;
  static const _stepsMin = 3000;
  static const _stepsMax = 20000;
  static const _weightMin = 30.0;
  static const _weightMax = 200.0;

  final _apiKey = TextEditingController();
  final _providers = llmPresets
      .where((preset) => preset.baseUrl.isNotEmpty)
      .toList();

  late int _step;
  int _calorie = 1800;
  int _protein = 90;
  int _water = 2000;
  int _steps = 10000;
  double _targetWeight = 60;
  String _presetId = 'deepseek';
  bool _showKey = false;
  bool _connecting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, 2);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    final weight = state.currentWeightKg.clamp(_weightMin, _weightMax);
    if (state.goalsConfigured) {
      _calorie = state.calorieGoal;
      _protein = state.proteinGoal;
      _water = state.waterTargetMl;
      _steps = state.stepGoal;
      _targetWeight = state.targetWeight;
    } else {
      _targetWeight = weight.toDouble();
      _calorie = state.recommendedCalorieGoalFor(
        weightKg: weight,
        targetWeightKg: _targetWeight,
      );
      _protein = state.recommendedProteinGoalFor(
        weightKg: weight,
        targetWeightKg: _targetWeight,
      );
      _water = state.recommendedWaterTargetMlFor(weightKg: weight);
      _steps = state.recommendedStepGoal;
    }
  }

  @override
  void dispose() {
    _apiKey.dispose();
    super.dispose();
  }

  void _applyRecommendation() {
    final state = AppScope.of(context);
    setState(() {
      _calorie = state.recommendedCalorieGoalFor(targetWeightKg: _targetWeight);
      _protein = state.recommendedProteinGoalFor(targetWeightKg: _targetWeight);
      _water = state.recommendedWaterTargetMlFor();
      _steps = state.recommendedStepGoal;
    });
    showToast(context, '已按你的资料重新计算');
  }

  void _changeTargetWeight(double delta) {
    final state = AppScope.of(context);
    setState(() {
      _targetWeight = (_targetWeight + delta).clamp(_weightMin, _weightMax);
      // 目标体重是热量与蛋白质建议的核心输入，调整后一起刷新。
      _calorie = state.recommendedCalorieGoalFor(targetWeightKg: _targetWeight);
      _protein = state.recommendedProteinGoalFor(targetWeightKg: _targetWeight);
    });
  }

  void _saveGoalsAndNext() {
    final state = AppScope.of(context);
    final protein = state.recommendedProteinGoalFor(
      targetWeightKg: _targetWeight,
    );
    setState(() => _protein = protein);
    state.updateProfile(
      calorieGoal: _calorie,
      proteinGoal: protein,
      waterTargetMl: _water,
      targetWeight: _targetWeight,
      stepGoal: _steps,
    );
    setState(() => _step = 1);
  }

  Future<void> _connectAi() async {
    final state = AppScope.of(context);
    if (state.aiConfigured) {
      setState(() => _step = 2);
      return;
    }
    if (_apiKey.text.trim().isEmpty) {
      showToast(context, '请填写 API Key，或选择「稍后配置」', icon: Icons.key_rounded);
      return;
    }
    final preset = _providers.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _providers.first,
    );
    setState(() => _connecting = true);
    await state.addLlmProvider(
      name: preset.name,
      baseUrl: preset.baseUrl,
      apiKey: _apiKey.text,
    );
    if (!mounted) return;
    setState(() => _connecting = false);
    if (state.aiConfigured) {
      _apiKey.clear();
      setState(() => _step = 2);
      showToast(context, 'AI 引擎已就绪');
    } else {
      showToast(
        context,
        state.llmError ?? '已保存提供商，但还没有拿到模型，请到完整设置里选择',
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _openFullLlmSettings() async {
    await Navigator.of(context).push(
      slidePageRoute(
        const SubpageFrame(title: 'AI 模型', child: LlmSettingsScreen()),
      ),
    );
    if (mounted) setState(() {});
  }

  void _skip() {
    AppScope.of(context).markOnboardingSeen();
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _skip();
    }
  }

  void _finish() {
    AppScope.of(context).markOnboardingSeen();
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9F4), AppColors.paper, Color(0xFFF2F4EC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              if (_step < 2) _progressBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: switch (_step) {
                    0 => _goalsStep(),
                    1 => _aiStep(),
                    _ => _doneStep(),
                  },
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final revisiting = widget.initialStep > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          if (_step > 0)
            IconPill(
              icon: Icons.arrow_back_rounded,
              background: Colors.white,
              color: AppColors.ink2,
              onTap: () => setState(() => _step -= 1),
            )
          else
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                size: 17,
                color: AppColors.accent,
              ),
            ),
          const SizedBox(width: 10),
          Text('好好吃饭', style: displayStyle(size: 17)),
          const Spacer(),
          if (revisiting)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SoftTag('设置向导', background: Color(0xFFEDF3E3)),
                const SizedBox(width: 4),
                IconPill(
                  icon: Icons.close_rounded,
                  size: 30,
                  background: Colors.white,
                  color: AppColors.ink2,
                  onTap: _close,
                ),
              ],
            )
          else if (_step < 2)
            Pressable(
              onTap: _skip,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  '稍后再说',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final labels = ['每日目标', 'AI 引擎'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_step + 1} / 2 · ${labels[_step]}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green2,
                ),
              ),
              const Spacer(),
              const Text(
                '大约 1 分钟',
                style: TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (var index = 0; index < 2; index++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _step
                          ? AppColors.green2
                          : const Color(0xFFE3E7DC),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                if (index == 0) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalsStep() {
    final state = AppScope.of(context);
    final weight = state.currentWeightKg;
    return ListView(
      key: const ValueKey('onboarding-goals'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        const Text(
          '先定一个\n够得着的目标',
          style: TextStyle(
            fontSize: 27,
            height: 1.24,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '按你的身高、体重、年龄和轻活动量估算，首页的热量环、饮水与步数都会以它为准。之后随时能在「我的 → 每日目标」修改。',
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.muted,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
          decoration: BoxDecoration(
            gradient: paleHeroGradient,
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(color: const Color(0xFFE5EFD6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '每日热量预算',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  const SoftTag('按资料推荐', background: AppColors.accentSoft),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_calorie',
                    style: displayStyle(size: 42, letterSpacing: -1.4),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      '千卡 / 天',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                  const Spacer(),
                  _Stepper(
                    onMinus: _calorie <= _calorieMin
                        ? null
                        : () => setState(
                            () => _calorie = (_calorie - 50).clamp(
                              _calorieMin,
                              _calorieMax,
                            ),
                          ),
                    onPlus: _calorie >= _calorieMax
                        ? null
                        : () => setState(
                            () => _calorie = (_calorie + 50).clamp(
                              _calorieMin,
                              _calorieMax,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${_targetWeight.toStringAsFixed(1)}kg 目标 · 蛋白质约 ${_protein}g · 身高 ${state.heightCm.toStringAsFixed(0)}cm · ${state.age > 0 ? '${state.age} 岁' : '成年'}',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _GoalTile(
          icon: Icons.water_drop_outlined,
          tint: const Color(0xFFDE8B7D),
          label: '饮水目标',
          hint: '约 ${(_water / 250).round()} 杯',
          value: '$_water',
          unit: 'ml',
          onMinus: _water <= _waterMin
              ? null
              : () => setState(
                  () => _water = (_water - 100).clamp(_waterMin, _waterMax),
                ),
          onPlus: _water >= _waterMax
              ? null
              : () => setState(
                  () => _water = (_water + 100).clamp(_waterMin, _waterMax),
                ),
        ),
        const SizedBox(height: 9),
        _GoalTile(
          icon: Icons.directions_walk_rounded,
          tint: const Color(0xFF8FBF56),
          label: '每日步数',
          hint: '走动比一次性运动更容易坚持',
          value: '$_steps',
          unit: '步',
          onMinus: _steps <= _stepsMin
              ? null
              : () => setState(
                  () => _steps = (_steps - 500).clamp(_stepsMin, _stepsMax),
                ),
          onPlus: _steps >= _stepsMax
              ? null
              : () => setState(
                  () => _steps = (_steps + 500).clamp(_stepsMin, _stepsMax),
                ),
        ),
        const SizedBox(height: 9),
        _GoalTile(
          icon: Icons.flag_outlined,
          tint: const Color(0xFF7FA0AC),
          label: '目标体重',
          hint: _targetWeight < weight - 1
              ? '比现在轻 ${(weight - _targetWeight).toStringAsFixed(1)}kg'
              : _targetWeight > weight + 1
              ? '比现在重 ${(_targetWeight - weight).toStringAsFixed(1)}kg'
              : '先保持当前体重',
          value: _targetWeight.toStringAsFixed(1),
          unit: 'kg',
          onMinus: _targetWeight <= _weightMin
              ? null
              : () => _changeTargetWeight(-0.5),
          onPlus: _targetWeight >= _weightMax
              ? null
              : () => _changeTargetWeight(0.5),
        ),
        const SizedBox(height: 13),
        Center(
          child: TextButton.icon(
            onPressed: _applyRecommendation,
            icon: const Icon(Icons.auto_awesome_rounded, size: 15),
            label: const Text('按我的资料重新推荐'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green2,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _aiStep() {
    final state = AppScope.of(context);
    return ListView(
      key: const ValueKey('onboarding-ai'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        const Text(
          '接上你自己的\nAI 引擎',
          style: TextStyle(
            fontSize: 27,
            height: 1.24,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '一句话记饮食、拍照识别餐盘、健康问答都依赖模型。密钥只写入本机安全存储，不会打包进应用，也不经过我们的服务器。',
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.muted,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: const [
            SoftTag('一句话记饮食', background: Color(0xFFEEF4E4)),
            SoftTag('拍照识别', background: Color(0xFFF7EEE6)),
            SoftTag('健康问答', background: Color(0xFFEEF0F7)),
          ],
        ),
        const SizedBox(height: 16),
        if (state.aiConfigured) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F9E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0EDCD)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.green2,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.activeProvider?.name ?? 'AI'} 已连接',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '当前模型 · ${state.activeModel ?? state.activeProvider?.model ?? '待选择'}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                PillButton(
                  label: '管理',
                  tone: PillTone.outline,
                  height: 32,
                  onPressed: _openFullLlmSettings,
                ),
              ],
            ),
          ),
        ] else ...[
          const Text(
            '选择服务商',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final preset in _providers)
                _PresetChip(
                  label: preset.name,
                  active: _presetId == preset.id,
                  onTap: () => setState(() => _presetId = preset.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'API Key',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _apiKey,
            obscureText: !_showKey,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '粘贴服务商后台生成的 Key',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showKey = !_showKey),
                icon: Icon(
                  _showKey
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '保存后会先拉取该服务的模型列表，并自动选好第一个模型。',
            style: TextStyle(
              fontSize: 9.5,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _openFullLlmSettings,
          icon: const Icon(Icons.tune_rounded, size: 15),
          label: const Text('需要自定义地址或更多选项'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.green2,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppColors.muted,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  '暂时不配置也能用：饮食记录、热量和运动数据都照常工作，AI 功能会退回本地规则，并明确标注。',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.muted,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _doneStep() {
    final state = AppScope.of(context);
    final goalsDone = state.goalsConfigured;
    final aiDone = state.aiConfigured;
    return ListView(
      key: const ValueKey('onboarding-done'),
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 34,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            '已经可以开始了',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              letterSpacing: -.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            goalsDone && aiDone
                ? '目标和 AI 都按你的情况准备好了。'
                : '没设置的部分会先保留默认值，首页会继续提醒你。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SummaryCard(
          icon: Icons.flag_outlined,
          title: '每日目标',
          done: goalsDone,
          lines: goalsDone
              ? [
                  '热量 ${state.calorieGoal} 千卡 / 天',
                  '饮水 ${state.waterTargetMl}ml · 步数 ${formatNumber(state.stepGoal)}',
                  '蛋白质 ${state.proteinGoal}g · 目标体重 ${state.targetWeight.toStringAsFixed(1)}kg',
                ]
              : const ['还没有确认每日目标', '可以先使用默认值，稍后再改'],
          action: goalsDone ? null : '现在设置',
          onAction: goalsDone ? null : () => setState(() => _step = 0),
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          icon: Icons.bolt_rounded,
          title: 'AI 引擎',
          done: aiDone,
          lines: aiDone
              ? [
                  '${state.activeProvider?.name ?? 'AI'} 已连接',
                  state.activeModel ?? state.activeProvider?.model ?? '模型待选择',
                ]
              : const ['还没有连接模型', '不影响手动记录，AI 会先用本地规则'],
          action: aiDone ? null : '现在配置',
          onAction: aiDone ? null : () => setState(() => _step = 1),
        ),
        const SizedBox(height: 18),
        const Text(
          '首页会显示今日热量、饮水、步数和蛋白质进度，随时可以在「我的」里调整。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9.5, color: AppColors.muted, height: 1.55),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final state = AppScope.of(context);
    Widget? primary;
    Widget? secondary;
    if (_step == 0) {
      primary = PillButton(
        label: '下一步：配置 AI',
        icon: Icons.arrow_forward_rounded,
        expand: true,
        height: 48,
        onPressed: _saveGoalsAndNext,
      );
      secondary = TextButton(
        onPressed: () => setState(() => _step = 1),
        child: const Text(
          '先跳过目标，去配置 AI',
          style: TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      );
    } else if (_step == 1) {
      primary = PillButton(
        label: _connecting
            ? '正在连接…'
            : state.aiConfigured
            ? '下一步'
            : '连接并启用',
        icon: state.aiConfigured
            ? Icons.arrow_forward_rounded
            : Icons.link_rounded,
        expand: true,
        height: 48,
        onPressed: _connecting ? null : _connectAi,
      );
      secondary = TextButton(
        onPressed: () => setState(() => _step = 2),
        child: const Text(
          '稍后配置，先开始记录',
          style: TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      );
    } else {
      primary = PillButton(
        label: '开始记录',
        icon: Icons.check_rounded,
        expand: true,
        height: 48,
        onPressed: _finish,
      );
      if (!state.setupComplete) {
        secondary = TextButton(
          onPressed: _finish,
          child: const Text(
            '先这样，之后在「我的」继续设置',
            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
        );
      }
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xF7F6F7F4),
        border: Border(top: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          primary,
          if (secondary != null) ...[const SizedBox(height: 2), secondary],
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String hint;
  final String value;
  final String unit;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _GoalTile({
    required this.icon,
    required this.tint,
    required this.label,
    required this.hint,
    required this.value,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(icon: Icons.remove_rounded, onTap: onMinus),
              SizedBox(
                width: 62,
                child: Column(
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -.2,
                      ),
                    ),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _Stepper({required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove_rounded, onTap: onMinus),
        const SizedBox(width: 4),
        _StepButton(icon: Icons.add_rounded, onTap: onPlus),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF3F4EF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFDFE5D8) : AppColors.lineSoft,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.ink2 : const Color(0xFFC4C9C0),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? AppColors.ink : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool done;
  final List<String> lines;
  final String? action;
  final VoidCallback? onAction;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.done,
    required this.lines,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: done ? const Color(0xFFE2EDD2) : AppColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: done ? const Color(0xFFF1F8E5) : const Color(0xFFF4F5F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              size: 17,
              color: done ? AppColors.green2 : AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SoftTag(
                      done ? '已设置' : '稍后',
                      background: done
                          ? const Color(0xFFEDF6DE)
                          : const Color(0xFFF1F2ED),
                      color: done ? AppColors.green2 : AppColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                if (action != null) ...[
                  const SizedBox(height: 4),
                  Pressable(
                    onTap: onAction,
                    child: Text(
                      action!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
