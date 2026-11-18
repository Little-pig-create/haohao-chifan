import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

const String appDisplayVersion = '2.0.0';

void openAboutPage(BuildContext context) {
  Navigator.of(context).push(
    slidePageRoute(const SubpageFrame(title: '关于软件', child: AboutScreen())),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
      children: [
        _hero(),
        const SizedBox(height: 11),
        _section(
          title: '这是什么',
          child: const Text(
            '好好吃饭是一款围绕「每日菜单」的健康饮食应用。记录三餐、饮水、体重和运动，'
            '安排一周菜单并生成采购清单，再用趋势图和 AI 看懂自己的饮食习惯。',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.ink2,
              height: 1.75,
            ),
          ),
        ),
        const SizedBox(height: 11),
        _section(
          title: '主要功能',
          child: Column(
            children: const [
              _FeatureRow(
                icon: Icons.restaurant_menu_rounded,
                title: '今日菜单',
                text: '三餐搭配、热量环、蛋白质与饮水进度一目了然',
                color: Color(0xFFF0F7E4),
                iconColor: AppColors.green2,
              ),
              SizedBox(height: 10),
              _FeatureRow(
                icon: Icons.calendar_month_rounded,
                title: '每周计划',
                text: '提前安排 21 餐，按周生成分类采购清单',
                color: Color(0xFFF4F2FA),
                iconColor: Color(0xFF6C6590),
              ),
              SizedBox(height: 10),
              _FeatureRow(
                icon: Icons.insights_rounded,
                title: '营养分析',
                text: '热量趋势、宏量占比、体重曲线与每周洞察',
                color: Color(0xFFEDF5F7),
                iconColor: Color(0xFF4C7A88),
              ),
              SizedBox(height: 10),
              _FeatureRow(
                icon: Icons.auto_awesome_rounded,
                title: 'AI 健康助手',
                text: '一句话记饮食、拍照估热量、身体数据问答',
                color: Color(0xFFFBF2E9),
                iconColor: Color(0xFF9A6B3F),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _section(
          title: '应用信息',
          child: Column(
            children: const [
              _InfoRow(label: '版本', value: 'v$appDisplayVersion（build 1）'),
              _InfoRow(label: '运行平台', value: 'Android / iOS'),
              _InfoRow(label: '数据存储', value: '仅保存在本机'),
              _InfoRow(label: 'AI 服务', value: '你配置的模型 · 兼容 OpenAI'),
              _InfoRow(label: '账号', value: '本地账号 · 无云端同步', last: true),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _section(
          title: '隐私与数据',
          child: Column(
            children: const [
              _PrivacyPoint(
                icon: Icons.smartphone_rounded,
                title: '数据只存本机',
                text:
                    '饮食、体重、运动与聊天记录保存在这台设备，'
                    '可随时在「我的 → 数据」导出或清除。',
              ),
              SizedBox(height: 12),
              _PrivacyPoint(
                icon: Icons.cloud_off_rounded,
                title: '不经过我们的服务器',
                text: 'AI 请求由设备直接发送给你配置的模型服务商。',
              ),
              SizedBox(height: 12),
              _PrivacyPoint(
                icon: Icons.key_rounded,
                title: '密钥安全存储',
                text: 'API Key 存放在系统安全存储中，不会打包进应用。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _section(
          title: '开源与许可',
          child: Column(
            children: [
              const Text(
                '应用使用了 Flutter 及若干开源组件，完整许可列表可在下方查看。',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.ink2,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 11),
              PillButton(
                label: '查看开源许可',
                icon: Icons.description_outlined,
                tone: PillTone.outline,
                expand: true,
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: '好好吃饭',
                  applicationVersion: appDisplayVersion,
                  applicationLegalese: '© 2026 好好吃饭',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            '© 2026 好好吃饭 · 认真吃好每一餐',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(0xFF9AA399),
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(gradient: paleHeroGradient),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8FAE72), Color(0xFF4F6B43)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.eco_rounded, size: 27, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('好好吃饭', style: displayStyle(size: 24)),
                const SizedBox(height: 4),
                const Text(
                  '每日健康菜单 · 认真吃好每一餐',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 7),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SoftTag(
                      'v$appDisplayVersion',
                      background: Color(0xFFE9F0E2),
                      color: Color(0xFF3E6149),
                    ),
                    SoftTag(
                      '本地优先',
                      background: Color(0xFFF3F9E8),
                      color: Color(0xFF5B7A4B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle(size: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final Color iconColor;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _InfoRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: last ? 0 : 9, bottom: last ? 0 : 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F8E7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.green2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
