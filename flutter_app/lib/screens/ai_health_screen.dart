import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../screens/llm_settings_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AiHealthScreen extends StatefulWidget {
  const AiHealthScreen({super.key});

  @override
  State<AiHealthScreen> createState() => _AiHealthScreenState();
}

class _AiHealthScreenState extends State<AiHealthScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _typing) return;
    final state = AppScope.of(context);
    final history = state.chatMessages.length > 8
        ? state.chatMessages.sublist(state.chatMessages.length - 8)
        : List<ChatMessage>.of(state.chatMessages);
    final payload = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt(state)},
      ...history
          .where((message) => !message.local)
          .map(
            (message) => {
              'role': message.fromAi ? 'assistant' : 'user',
              'content': message.text,
            },
          ),
      {'role': 'user', 'content': text},
    ];
    setState(() {
      _typing = true;
      _input.clear();
    });
    state.addChatMessage(ChatMessage(text: text, fromAi: false));
    _scrollToEnd();
    if (state.activeProvider == null) {
      state.addChatMessage(
        const ChatMessage(
          text: '还没有连接模型。打开「我的 → AI 引擎」添加提供商和 API Key，之后我就能基于你的真实记录回答。',
          fromAi: true,
          local: true,
        ),
      );
      setState(() {
        _typing = false;
      });
      _scrollToEnd();
      return;
    }
    try {
      final reply = await state.chat(payload);
      if (!mounted) return;
      state.addChatMessage(ChatMessage(text: reply, fromAi: true));
      setState(() {
        _typing = false;
      });
    } catch (error) {
      if (!mounted) return;
      final reason = '$error'.replaceFirst('Exception: ', '');
      state.addChatMessage(
        ChatMessage(
          text: '模型请求失败：$reason\n\n先用本地规则回答：${_localReply(text)}',
          fromAi: true,
          local: true,
        ),
      );
      setState(() {
        _typing = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _systemPrompt(dynamic state) {
    final day = state.selectedDay;
    final protein = state.proteinFor(day);
    final carbs = state.carbsFor(day);
    final fat = state.fatFor(day);
    final consumed = state.consumedFor(day);
    final water = state.waterFor(day) * state.cupMl;
    final steps = state.health.steps;
    final sleep = state.health.sleepMinutes;
    final weight =
        state.health.weightKg ??
        (state.weights.isEmpty ? null : state.weights.last.kg);
    return '你是「好好吃饭」App 里的中文健康助手。只能基于下面这些真实记录回答，没有记录就说没有，不要编造数值。'
        '建议要具体、可执行、控制在 3–5 句；不做疾病诊断，不推荐药物。'
        '今日记录：热量 $consumed/${state.calorieGoal} 千卡，蛋白质 ${protein}g/${state.proteinGoal}g，碳水 ${carbs}g，脂肪 ${fat}g，'
        '饮水 $water/${state.waterTargetMl}ml，步数 ${steps ?? '未同步'}，睡眠 ${sleep == null ? '未同步' : '${sleep.round()} 分钟'}，'
        '最近体重 ${weight == null ? '未记录' : '${weight.toStringAsFixed(1)}kg'}，目标体重 ${state.targetWeight.toStringAsFixed(0)}kg。';
  }

  String _localReply(String text) {
    final state = AppScope.of(context);
    final day = state.selectedDay;
    final protein = state.proteinFor(day);
    final waterLeft = state.waterTargetMl - state.waterFor(day) * state.cupMl;
    final steps = state.health.steps;
    final weight =
        state.health.weightKg ??
        (state.weights.isEmpty ? null : state.weights.last.kg);
    if (!state.health.connected && state.consumedFor(day) == 0) {
      return '还没有可分析的记录。先连接 Health Connect，或在饮食页记录一餐，我再根据真实数据回答。';
    }
    if (text.contains('晚餐') || text.contains('怎么补')) {
      return '今天已记录 ${protein}g 蛋白质，饮水还差 ${math.max(0, waterLeft)}ml。晚餐可以选豆腐、鱼或鸡胸，配一份深色蔬菜，主食按饥饿感减 1/4。';
    }
    if (text.contains('运动') || text.contains('步数')) {
      return steps == null
          ? '还没有读到今天的步数。连接 Health Connect 后，我可以根据真实活动量给建议。'
          : '今天已记录 ${formatNumber(steps)} 步，${steps >= state.stepGoal ? '已经达到 ${formatNumber(state.stepGoal)} 步目标。' : '距离 ${formatNumber(state.stepGoal)} 步还差 ${formatNumber(state.stepGoal - steps)} 步，晚饭后快走 20 分钟就能补上。'}';
    }
    if (text.contains('体重') || text.contains('减')) {
      return weight == null
          ? '还没有体重记录。可以在身体数据页手动记录，或连接支持体重同步的设备。'
          : '最近一次体重是 ${weight.toStringAsFixed(1)}kg，目标 ${state.targetWeight.toStringAsFixed(0)}kg。建议按每周 0.3–0.5kg 的速度调整，不要继续压低热量。';
    }
    return '今天已记录 ${state.consumedFor(day)} 千卡、${protein}g 蛋白质，饮水还差 ${math.max(0, waterLeft)}ml。${waterLeft > 0 ? '优先补水，再补一份蔬菜。' : '饮水已达标，保持当前节奏。'}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final day = state.selectedDay;
    final score = state.healthScoreFor(day);
    final protein = state.proteinFor(day);
    final waterLeft = math.max(
      0,
      state.waterTargetMl - state.waterFor(day) * state.cupMl,
    );
    final steps = state.health.steps;
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 108),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Text(
            '基于你的真实记录做分析，给出可执行的下一步，而不是泛泛的建议。',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),
        ),
        if (state.activeProvider == null)
          Pressable(
            onTap: () => openLlmSettingsPage(context),
            child: Container(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.all(AppSpacing.card),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0DFCE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 17,
                    color: Color(0xFF9A6A3F),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '还没有连接模型。添加一个提供商后，这里的问答会由真实模型回答。',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF7E5732),
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: Color(0xFF9A6A3F),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 11),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.memory_rounded,
                  size: 14,
                  color: AppColors.green2,
                ),
                const SizedBox(width: 6),
                const Text(
                  '模型',
                  style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.activeModel ??
                        state.activeProvider?.model ??
                        state.activeProvider!.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2,
                    ),
                  ),
                ),
                Pressable(
                  onTap: () => openLlmSettingsPage(context),
                  child: const Text(
                    '切换',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2F9E6), Color(0xFFF6F2FB), Color(0xFFFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(color: const Color(0xFFE9EDE2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (score ?? 0).toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CustomPaint(
                        painter: _ScorePainter(value / 100),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                score == null ? '—' : '${value.round()}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  height: 1,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.ink,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                '健康评分',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          score == null ? '等待健康数据' : '基于真实记录',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          score == null
                              ? '连接 Health Connect 并记录一餐后，这里会显示基于真实数据的分析。'
                              : '今天已记录 ${state.consumedFor(day)} 千卡、${protein}g 蛋白质，饮水还差 ${formatNumber(waterLeft)}ml。',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            SoftTag(
                              '蛋白质 $protein g',
                              background: const Color(0xFFEFF8DC),
                              color: const Color(0xFF536F3F),
                            ),
                            const SizedBox(width: 5),
                            SoftTag(
                              '步数 ${steps ?? '—'}',
                              background: const Color(0xFFF0F1F8),
                              color: const Color(0xFF626785),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: '生成今日计划',
                      icon: Icons.auto_awesome_rounded,
                      expand: true,
                      onPressed: () => _send('帮我安排今天剩下的饮食和运动'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _ScoreBreakdownCard(
          consumed: state.consumedFor(day),
          protein: protein,
          proteinGoal: state.proteinGoal,
          waterMl: state.waterFor(day) * state.cupMl,
          waterGoal: state.waterTargetMl,
          steps: steps,
          stepGoal: state.stepGoal,
          sleepMinutes: state.health.sleepMinutes,
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('AI 今日总结', style: titleStyle(size: 18)),
                  const Spacer(),
                  SoftTag(
                    '本地规则 · 实时',
                    background: AppColors.surfaceSoft,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InsightLine(
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF66845B),
                title: '蛋白质',
                text: '今天已记录 ${protein}g，目标 ${state.proteinGoal}g。',
              ),
              const SizedBox(height: 8),
              _InsightLine(
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF7B9AA6),
                title: '饮水',
                text: waterLeft > 0
                    ? '距离目标还差 ${formatNumber(waterLeft)}ml。'
                    : '已达到今日饮水目标。',
              ),
              const SizedBox(height: 8),
              _InsightLine(
                icon: Icons.directions_walk_rounded,
                color: const Color(0xFF9A8146),
                title: '活动',
                text: steps == null
                    ? '连接健康数据后读取今日步数。'
                    : '今天 ${formatNumber(steps)} 步。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('今天可以这样', style: titleStyle(size: 18)),
                  const Spacer(),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: AppColors.green2,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PlanRow(
                time: '15:30',
                title: waterLeft > 0
                    ? '补水 ${formatNumber(waterLeft)}ml'
                    : '饮水已达标',
                done: waterLeft <= 0,
              ),
              const _PlanRow(time: '18:30', title: '晚餐加一份深色蔬菜', done: false),
              _PlanRow(
                time: '20:00',
                title: steps != null && steps >= state.stepGoal
                    ? '步数已达标'
                    : '快走 20 分钟',
                done: steps != null && steps >= state.stepGoal,
              ),
              const _PlanRow(time: '22:30', title: '睡前称体重', done: false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('问点什么', style: titleStyle(size: 18)),
            const Spacer(),
            Text(
              _typing ? 'AI 正在输入…' : '根据你的记录回答',
              style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _PromptChip('今天吃得健康吗？'),
              SizedBox(width: 6),
              _PromptChip('晚餐怎么补？'),
              SizedBox(width: 6),
              _PromptChip('这周运动够吗？'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...state.chatMessages.map((message) => _Bubble(message: message)),
        if (_typing)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: const Text(
              '正在整理你的记录…',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: cardDecoration(radius: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: '问问今天的饮食、运动或体重…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                  ),
                ),
              ),
              Pressable(
                onTap: _send,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'AI 建议只基于你记录的数据，不替代医生诊断。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8.5, color: Color(0xFF9AA399)),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.fromAi ? AppColors.surface : AppColors.ink,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.fromAi ? 5 : 16),
            bottomRight: Radius.circular(message.fromAi ? 16 : 5),
          ),
          border: message.fromAi ? Border.all(color: AppColors.line) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.local)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '本地规则',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                    color: message.fromAi
                        ? AppColors.muted
                        : const Color(0xFFB9C4B7),
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.65,
                color: message.fromAi ? AppColors.ink2 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String text;
  const _PromptChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Pressable(
        onTap: () {
          final state = context.findAncestorStateOfType<_AiHealthScreenState>();
          state?._send(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 10.5, color: AppColors.ink2),
          ),
        ),
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _InsightLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.55,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String time;
  final String title;
  final bool done;
  const _PlanRow({required this.time, required this.title, this.done = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? AppColors.green2 : const Color(0xFFC9CEC5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11.5, color: AppColors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  final double progress;
  _ScorePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFEFF2EA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScorePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ScoreBreakdownCard extends StatelessWidget {
  final int consumed;
  final int protein;
  final int proteinGoal;
  final int waterMl;
  final int waterGoal;
  final int? steps;
  final int stepGoal;
  final double? sleepMinutes;

  const _ScoreBreakdownCard({
    required this.consumed,
    required this.protein,
    required this.proteinGoal,
    required this.waterMl,
    required this.waterGoal,
    required this.steps,
    required this.stepGoal,
    required this.sleepMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final record =
        ((consumed > 0 ? 1 : 0) +
            (waterMl > 0 ? 1 : 0) +
            (steps != null ? 1 : 0) +
            (sleepMinutes != null ? 1 : 0)) /
        4;
    final nutrition = (protein / proteinGoal).clamp(0.0, 1.0).toDouble();
    final activity = ((steps ?? 0) / stepGoal).clamp(0.0, 1.0).toDouble();
    final water = (waterMl / math.max(1, waterGoal)).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('评分构成', style: titleStyle(size: 18)),
              const Spacer(),
              SoftTag(
                '实时',
                background: AppColors.surfaceSoft,
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ScoreRow(label: '记录完整度', value: record),
          _ScoreRow(label: '营养均衡', value: nutrition),
          _ScoreRow(label: '活动', value: activity),
          _ScoreRow(label: '饮水', value: water),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final ratio = value.clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 5,
                color: AppColors.lineSoft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, current, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: current,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent, Color(0xFFA9D95E)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${(ratio * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
