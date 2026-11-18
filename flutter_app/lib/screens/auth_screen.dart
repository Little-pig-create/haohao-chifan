import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/media_permission.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _username = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _age = TextEditingController();
  String _gender = '';
  Uint8List? _avatar;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    if (state.guest) {
      _username.text = state.name;
      _gender = state.gender;
      _avatar = state.avatarBytes;
      _height.text = state.heightCm.toStringAsFixed(0);
      if (state.age > 0) _age.text = '${state.age}';
      for (final point in state.bodyPoints.reversed) {
        if (point.weightKg != null) {
          _weight.text = point.weightKg!.toStringAsFixed(1);
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _height.dispose();
    _weight.dispose();
    _age.dispose();
    super.dispose();
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
      setState(() => _avatar = bytes);
    } catch (_) {
      if (!mounted) return;
      showToast(context, '没能读取这张图片，换一张试试', icon: Icons.error_outline_rounded);
    }
  }

  void _submit() {
    final state = AppScope.of(context);
    if (_gender.isEmpty) {
      showToast(context, '请选择性别', icon: Icons.wc_rounded);
      return;
    }
    final height = double.tryParse(_height.text);
    if (height == null || height < 120 || height > 220) {
      showToast(context, '请输入 120~220 之间的身高', icon: Icons.straighten_rounded);
      return;
    }
    final weight = double.tryParse(_weight.text);
    if (weight == null || weight < 30 || weight > 200) {
      showToast(
        context,
        '请输入 30~200 之间的体重',
        icon: Icons.monitor_weight_outlined,
      );
      return;
    }
    final age = int.tryParse(_age.text);
    if (age == null || age < 10 || age > 100) {
      showToast(context, '请输入 10~100 之间的年龄', icon: Icons.cake_outlined);
      return;
    }
    final name = _username.text.trim();
    state.completeProfile(
      name: name.isEmpty ? '好好吃饭用户' : name,
      gender: _gender,
      age: age,
      heightCm: height,
      weightKg: weight,
      avatar: _avatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottom + 20),
        child: Column(
          children: [
            _hero(context),
            Transform.translate(
              offset: const Offset(0, -26),
              child: FadeSlideIn(
                index: 2,
                offset: 22,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2E1C3022),
                        blurRadius: 50,
                        offset: Offset(0, 26),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('先认识一下你', style: displayStyle(size: 24)),
                      const SizedBox(height: 6),
                      const Text(
                        '游客资料只保存在本机，用来计算 BMI 和营养目标，之后可在「我的」修改。',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Pressable(
                          onTap: _pickAvatar,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              UserAvatar(
                                name: _username.text,
                                size: 76,
                                avatar: _avatar,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 27,
                                  height: 27,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.line),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x14111713),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 14,
                                    color: AppColors.green2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _avatar == null ? '点击上传头像 · 不传就用默认头像' : '点击更换头像',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _label('昵称'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _username,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '怎么称呼你，可留空',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('性别'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final item in const ['男', '女', '其他']) ...[
                            Expanded(
                              child: _GenderChip(
                                label: item,
                                active: _gender == item,
                                onTap: () => setState(() => _gender = item),
                              ),
                            ),
                            if (item != '其他') const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _numField('身高', _height, '170', 'cm'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numField('体重', _weight, '57.3', 'kg'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _numField('年龄', _age, '28', '岁')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      PillButton(
                        label: '以游客身份开始',
                        expand: true,
                        height: 48,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '会生成本地 UID，所有记录只存在这台设备，可用「导出备份」迁移到新手机。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF9A9E92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 330,
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 22,
        22,
        42,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF9DE), Color(0xFFF8F5EE), Color(0xFFF2F1FA)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -150,
            bottom: -190,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDEBC8)),
              ),
              child: Center(
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE6E4F1)),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        size: 23,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Text(
                      '好好吃饭',
                      style: displayStyle(size: 20, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FadeSlideIn(
                index: 1,
                child: Text(
                  '吃得明白，\n才吃得长久。',
                  style: displayStyle(
                    size: 34,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 2,
                child: const Text(
                  '记下每一餐，看清热量和蛋白质还差多少，\n再按计划做下一餐。',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ink2,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );
  }

  Widget _numField(
    String label,
    TextEditingController controller,
    String hint,
    String suffix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hint, suffixText: suffix),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.ink : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}
