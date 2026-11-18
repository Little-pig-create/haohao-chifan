import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/about_screen.dart';
import '../screens/llm_settings_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/media_permission.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _plan;
  late final TextEditingController _calorie;
  late final TextEditingController _protein;
  late final TextEditingController _water;
  late final TextEditingController _cup;
  late final TextEditingController _target;
  late final TextEditingController _height;
  late final TextEditingController _age;
  late final TextEditingController _steps;
  String _gender = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    _name = TextEditingController(text: state.name);
    _plan = TextEditingController(text: state.planName);
    _calorie = TextEditingController(text: '${state.calorieGoal}');
    _protein = TextEditingController(text: '${state.proteinGoal}');
    _water = TextEditingController(text: '${state.waterTargetMl}');
    _cup = TextEditingController(text: '${state.cupMl}');
    _target = TextEditingController(
      text: '${state.targetWeight.toStringAsFixed(0)}',
    );
    _height = TextEditingController(text: state.heightCm.toStringAsFixed(0));
    _age = TextEditingController(text: state.age > 0 ? '${state.age}' : '');
    _steps = TextEditingController(text: '${state.stepGoal}');
    _gender = state.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _plan.dispose();
    _calorie.dispose();
    _protein.dispose();
    _water.dispose();
    _cup.dispose();
    _target.dispose();
    _height.dispose();
    _age.dispose();
    _steps.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final state = AppScope.of(context);
    state.updateProfile(
      name: _name.text.trim().isEmpty ? state.name : _name.text.trim(),
      planName: _plan.text.trim().isEmpty ? state.planName : _plan.text.trim(),
      heightCm: double.tryParse(_height.text) ?? state.heightCm,
      gender: _gender,
      age: int.tryParse(_age.text) ?? state.age,
    );
    showToast(context, '个人资料已保存');
  }

  Future<void> _pickAvatar() async {
    try {
      final allowed = await ensureMediaAccess(MediaAccessKind.gallery);
      if (!allowed) {
        if (mounted) {
          await showMediaPermissionPrompt(
            context,
            kind: MediaAccessKind.gallery,
          );
        }
        return;
      }
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      AppScope.of(context).setAvatar(bytes);
      showToast(context, '头像已更新');
    } catch (_) {
      if (!mounted) return;
      showToast(context, '没能读取这张图片，换一张试试', icon: Icons.error_outline_rounded);
    }
  }

  void _saveGoals() {
    final state = AppScope.of(context);
    state.updateProfile(
      calorieGoal: int.tryParse(_calorie.text) ?? state.calorieGoal,
      proteinGoal: int.tryParse(_protein.text) ?? state.proteinGoal,
      waterTargetMl: int.tryParse(_water.text) ?? state.waterTargetMl,
      cupMl: int.tryParse(_cup.text) ?? state.cupMl,
      targetWeight: double.tryParse(_target.text) ?? state.targetWeight,
      stepGoal: int.tryParse(_steps.text) ?? state.stepGoal,
    );
    showToast(context, '目标已保存，首页已同步');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 26),
      children: [
        if (!widget.embedded)
          const PageHeader(
            eyebrow: '偏好与配置',
            title: '设置',
            subtitle: '本地资料、每日目标、AI 服务，以及数据备份与清除。',
          ),
        if (widget.embedded) const SizedBox(height: 8),
        _accountCard(state),
        if (!state.setupComplete) ...[
          const SizedBox(height: 11),
          _guideCard(state),
        ],
        const SizedBox(height: 11),
        _card(
          title: '个人资料',
          subtitle: '显示在首页问候与顶栏',
          child: Column(
            children: [
              _field('昵称', _name, '怎么称呼你'),
              const SizedBox(height: 9),
              _genderSelector(),
              const SizedBox(height: 9),
              _field('年龄', _age, '例如 28', number: true),
              const SizedBox(height: 9),
              _field('计划名称', _plan, '例如：轻盈生活计划'),
              const SizedBox(height: 9),
              _field('身高 (cm)', _height, '用于计算 BMI，例如 170'),
              const SizedBox(height: 11),
              PillButton(
                label: '保存个人资料',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _card(
          title: '每日目标',
          subtitle: '影响热量环、饮水杯数与推荐引擎',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _field('热量目标（千卡）', _calorie, '1850', number: true),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _field('饮水目标（ml）', _water, '2000', number: true),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _field('每杯水量（ml）', _cup, '250', number: true),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _field('目标体重（kg）', _target, '55', number: true),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _field('蛋白质目标（g）', _protein, '95', number: true),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _field('步数目标', _steps, '10000', number: true),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              PillButton(
                label: '保存资料与目标',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: _saveGoals,
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _aiCard(state),
        const SizedBox(height: 11),
        _card(
          title: '每日提醒',
          subtitle: '按本机时间发送；喝水可调频率，其他提醒可调时刻',
          trailing: Switch(
            value: state.remindersEnabled,
            onChanged: (value) async {
              final ok = await state.setRemindersEnabled(value);
              if (value && !ok && mounted) {
                showToast(
                  context,
                  '通知权限未开启，请到系统设置允许通知',
                  icon: Icons.notifications_off_outlined,
                );
              }
            },
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 15,
                    color: AppColors.green2,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '喝水提醒',
                      style: TextStyle(fontSize: 11, color: AppColors.ink2),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value:
                          const [
                            15,
                            30,
                            45,
                            60,
                            90,
                            120,
                            180,
                          ].contains(state.waterReminderMinutes)
                          ? state.waterReminderMinutes
                          : 60,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      items: const [15, 30, 45, 60, 90, 120, 180]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('每 $value 分钟'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) state.setWaterReminderMinutes(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '08:00 - 22:00 之间按频率提醒',
                  style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 10),
              _reminderTimeRow(
                Icons.restaurant_outlined,
                '早餐',
                'breakfast',
                state.breakfastTime,
              ),
              _reminderTimeRow(
                Icons.lunch_dining_outlined,
                '午餐',
                'lunch',
                state.lunchTime,
              ),
              _reminderTimeRow(
                Icons.dinner_dining_outlined,
                '晚餐',
                'dinner',
                state.dinnerTime,
              ),
              _reminderTimeRow(
                Icons.monitor_weight_outlined,
                '称体重',
                'weight',
                state.weightTime,
              ),
              _reminderTimeRow(
                Icons.bedtime_outlined,
                '睡前复盘',
                'sleep',
                state.sleepTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _card(
          title: '数据',
          subtitle: '饮食与健康记录保存在本机',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: '导出到剪贴板',
                      icon: Icons.copy_all_outlined,
                      tone: PillTone.outline,
                      expand: true,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: state.exportJson()),
                        );
                        if (!context.mounted) return;
                        showToast(context, '已复制完整 JSON 备份到剪贴板');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PillButton(
                      label: '从剪贴板恢复',
                      icon: Icons.content_paste_go_rounded,
                      tone: PillTone.outline,
                      expand: true,
                      onPressed: () => _importBackup(state),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PillButton(
                label: '清除并恢复初始',
                icon: Icons.refresh_rounded,
                tone: PillTone.soft,
                expand: true,
                onPressed: () => _confirmReset(state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Pressable(
          onTap: () => openAboutPage(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F8E7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 17,
                    color: AppColors.green2,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '关于软件',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '版本信息、功能说明与数据隐私',
                        style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  'v$appDisplayVersion',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '好好吃饭 v$appDisplayVersion · Flutter',
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF9AA399),
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountCard(dynamic state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1FAE3), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: const Color(0xFFE8F1D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本地资料',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '当前版本不上传数据，换设备请用下方 JSON 备份恢复',
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              PillButton(
                label: '本地模式',
                icon: Icons.person_outline_rounded,
                tone: PillTone.outline,
                onPressed: () => showToast(
                  context,
                  '数据只保存在这台设备，可在下方导出 JSON 备份',
                  icon: Icons.info_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Pressable(
                onTap: _pickAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      name: state.name,
                      size: 42,
                      avatar: state.avatarBytes,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          size: 10,
                          color: AppColors.green2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Pressable(
                      onTap: () {
                        if (state.uid.isEmpty) return;
                        Clipboard.setData(ClipboardData(text: state.uid));
                        showToast(context, 'UID 已复制');
                      },
                      child: Row(
                        children: [
                          Text(
                            'UID · ${state.uid.isEmpty ? '生成中' : state.uid}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy_rounded,
                            size: 10,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '本地模式 · 数据只保存在这台设备',
                      style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guideCard(dynamic state) {
    return _card(
      title: '新手引导',
      subtitle: '设置向导会按你的资料推荐目标，并帮你接入 AI 模型',
      trailing: const SoftTag('待完成', background: Color(0xFFF1F2ED)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _guideStatus(
                  icon: Icons.flag_outlined,
                  label: '每日目标',
                  done: state.goalsConfigured as bool,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _guideStatus(
                  icon: Icons.bolt_rounded,
                  label: 'AI 引擎',
                  done: state.aiConfigured as bool,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PillButton(
            label: '继续完成设置',
            icon: Icons.arrow_forward_rounded,
            expand: true,
            onPressed: () => openOnboardingPage(
              context,
              initialStep: state.goalsConfigured as bool ? 1 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideStatus({
    required IconData icon,
    required String label,
    required bool done,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFF3F9E8) : const Color(0xFFF6F7F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done ? const Color(0xFFE3EDD2) : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : icon,
            size: 15,
            color: done ? AppColors.green2 : AppColors.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
          ),
          Text(
            done ? '已设置' : '待设置',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: done ? AppColors.green2 : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiCard(dynamic state) {
    final provider = state.activeProvider;
    final model = state.activeModel ?? provider?.model;
    return _card(
      title: 'AI 引擎',
      subtitle: 'AI 记录、拍照识别和健康问答都由你接入的模型完成',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: provider == null
                  ? const Color(0xFFF5F6F2)
                  : const Color(0xFFF3F9E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider == null
                    ? AppColors.line
                    : const Color(0xFFE2EDCD),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  provider == null
                      ? Icons.link_off_rounded
                      : Icons.bolt_rounded,
                  size: 15,
                  color: provider == null ? AppColors.muted : AppColors.green2,
                ),
                const SizedBox(width: 7),
                const Text(
                  '当前模型',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider == null
                        ? '未配置'
                        : (model ?? '${provider.name} · 待选模型'),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: provider == null
                          ? AppColors.muted
                          : AppColors.green2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: '管理提供商',
                  icon: Icons.tune_rounded,
                  expand: true,
                  onPressed: () => openLlmSettingsPage(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  label: '测试连通性',
                  icon: Icons.network_check_rounded,
                  tone: PillTone.outline,
                  expand: true,
                  onPressed: provider == null
                      ? () => showToast(
                          context,
                          '先添加一个提供商',
                          icon: Icons.link_off_rounded,
                        )
                      : () async {
                          showToast(
                            context,
                            '正在请求模型…',
                            icon: Icons.hourglass_top_rounded,
                          );
                          try {
                            final reply = await state.testLlm();
                            if (!context.mounted) return;
                            showToast(
                              context,
                              '连通正常：${reply.length > 30 ? '${reply.substring(0, 30)}…' : reply}',
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            showToast(
                              context,
                              '$error'.replaceFirst('Exception: ', ''),
                              icon: Icons.error_outline_rounded,
                            );
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '优先接入国内服务：DeepSeek、通义千问、Kimi、智谱、火山方舟、硅基流动、MiniMax、腾讯混元、百度千帆，也支持任意兼容地址。密钥只写入本机安全存储。',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(0xFF98A096),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup(dynamic state) async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('从 JSON 恢复', style: TextStyle(fontSize: 18)),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 9,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(hintText: '粘贴之前导出的 JSON 备份'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty || !mounted) return;
    final ok = state.importJson(raw);
    showToast(
      context,
      ok ? '备份已恢复，首页数据已刷新' : 'JSON 格式不正确，未改动现有数据',
      icon: ok ? Icons.check_circle_outline : Icons.error_outline_rounded,
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle(size: 18)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing],
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _genderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '性别',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final item in const ['男', '女', '其他']) ...[
              Expanded(
                child: Pressable(
                  onTap: () => setState(() => _gender = item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _gender == item
                          ? AppColors.ink
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _gender == item ? AppColors.ink : AppColors.line,
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _gender == item ? Colors.white : AppColors.ink2,
                      ),
                    ),
                  ),
                ),
              ),
              if (item != '其他') const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool number = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: hint, isDense: true),
        ),
      ],
    );
  }

  Widget _reminderTimeRow(
    IconData icon,
    String label,
    String key,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.green2),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.ink2),
            ),
          ),
          Pressable(
            onTap: () async {
              final state = AppScope.of(context);
              final picked = await showTimePicker(
                context: context,
                initialTime: _parseTime(value),
              );
              if (picked != null) {
                state.setReminderTime(key, _formatTime(picked));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _formatTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmReset(dynamic state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('恢复初始数据？', style: TextStyle(fontSize: 18)),
        content: const Text(
          '饮水、完成状态、体重和运动记录都会被清空，无法撤销。',
          style: TextStyle(fontSize: 12, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      state.reset();
      _name.text = state.name;
      _plan.text = state.planName;
      _calorie.text = '${state.calorieGoal}';
      _protein.text = '${state.proteinGoal}';
      _water.text = '${state.waterTargetMl}';
      _cup.text = '${state.cupMl}';
      _target.text = '${state.targetWeight.toStringAsFixed(0)}';
      _steps.text = '${state.stepGoal}';
      setState(() {});
      showToast(context, '已恢复初始数据');
    }
  }
}
