import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}

/// 二级页面统一转场：轻微右滑 + 淡入，返回时反向。
Route<T> slidePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(.055, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 让 PageView 里的页面在滑走后保留滚动位置和局部状态。
class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

String formatNumber(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

OverlayEntry? _toastEntry;

void showToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_outline,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.cream),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(milliseconds: 2200),
      ),
    );
    return;
  }
  _toastEntry?.remove();
  _toastEntry = null;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopToast(
      message: message,
      icon: icon,
      onDismiss: () {
        if (_toastEntry == entry) _toastEntry = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _toastEntry = entry;
  overlay.insert(entry);
}

/// 带「撤销」的底部提示，适合删除、加水等可回退操作。
void showUndoToast(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
  IconData icon = Icons.check_circle_outline,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    showToast(context, message, icon: icon);
    return;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.cream),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        action: SnackBarAction(
          label: '撤销',
          textColor: AppColors.accent,
          onPressed: onUndo,
        ),
      ),
    );
}

class _TopToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final VoidCallback onDismiss;

  const _TopToast({
    required this.message,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2100), _hide);
  }

  Future<void> _hide() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 72,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -.35),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A111713),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 15,
                        color: AppColors.green2,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _down = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _down = false);
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 35 * widget.index), () {
      if (!_disposed) _controller.forward();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle style;
  final int decimals;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.decimals = 0,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) {
        final text = decimals == 0
            ? formatNumber(current)
            : current.toStringAsFixed(decimals);
        return Text('$text$suffix', style: style);
      },
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Uint8List? avatar;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '好' : name.substring(0, 1);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6FCEB), Color(0xFFD3E6BC)],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F4F6B43),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: avatar != null
                  ? Image.memory(
                      avatar!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: size * .36,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greenInk,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * .34,
              height: size * .34,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                Icons.eco_rounded,
                size: size * .18,
                color: AppColors.greenInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  final VoidCallback? onAvatarTap;
  const AppTopBar({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final date = state.dateForDay(state.selectedDay);
    final dateLabel =
        '${date.month}月${date.day}日 · ${weekDays[state.selectedDay].weekday}';
    final title = switch (state.tab) {
      0 => state.name,
      1 => '饮食日记',
      2 => '运动记录',
      3 => state.insightTab == 0 ? '健康趋势' : '健康报告',
      _ => 'AI 健康助手',
    };
    final isHome = state.tab == 0;
    if (!isHome) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 8),
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (state.tab == 3 && state.insightTab == 0)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: InsightPeriodMenu(
                    selected: state.insightPeriod,
                    onChanged: state.setInsightPeriod,
                  ),
                )
              else if (state.tab == 2 || state.tab == 4)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _DatePill(label: dateLabel),
                ),
            ],
          ),
        ),
      );
    }
    final hour = DateTime.now().hour;
    final greeting = hour < 5
        ? '夜深了'
        : hour < 11
        ? '早上好'
        : hour < 13
        ? '中午好'
        : hour < 18
        ? '下午好'
        : '晚上好';
    final greetingTitle = state.name.isEmpty
        ? greeting
        : '$greeting，${state.name}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Pressable(
            onTap: onAvatarTap,
            child: UserAvatar(
              name: state.name,
              size: 44,
              avatar: state.avatarBytes,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .22),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    greetingTitle,
                    key: ValueKey(greetingTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.35,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => showToast(context, '今天还没有新的提醒'),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A111713),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 21,
                    color: AppColors.ink2,
                  ),
                  Positioned(
                    right: 9.5,
                    top: 9,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const insightPeriodLabels = ['本周', '本月', '三个月'];

/// 顶栏右侧的周期下拉，对应参考稿里的「Month ⌄」。
class InsightPeriodMenu extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const InsightPeriodMenu({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final index = selected.clamp(0, insightPeriodLabels.length - 1);
    return PopupMenuButton<int>(
      initialValue: index,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: AppColors.surface,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.line),
      ),
      itemBuilder: (context) => [
        for (var i = 0; i < insightPeriodLabels.length; i++)
          PopupMenuItem<int>(
            value: i,
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    insightPeriodLabels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == index
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (i == index)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.green2,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(left: 13, right: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08111713),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              insightPeriodLabels[index],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  const _DatePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, '首页'),
    (Icons.restaurant_outlined, Icons.restaurant_rounded, '饮食'),
    (Icons.directions_run_outlined, Icons.directions_run_rounded, '运动'),
    (Icons.insights_outlined, Icons.insights_rounded, '趋势'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'AI'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFAFFFFFF),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFEEF0EA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12111713),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_items.length, (index) {
            final active = state.tab == index;
            final item = _items[index];
            return Pressable(
              onTap: () {
                HapticFeedback.selectionClick();
                state.setTab(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: active ? 96 : 52,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: Tween(begin: .72, end: 1.0).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Icon(
                        active ? item.$2 : item.$1,
                        key: ValueKey(active),
                        size: 20,
                        color: active ? Colors.white : const Color(0xFF8B958C),
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 7),
                      Text(
                        item.$3,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class GroupTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const GroupTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEE7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: Pressable(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x14283C2D),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? AppColors.green : const Color(0xFF7E897D),
                  ),
                  child: Text(labels[index]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 页内分组 + 左右滑动切换。
///
/// 和 [GroupTabs] 配合使用：点击 tab 或横向滑动都能切换，
/// 外部通过 [selected] 改值时也会平滑跟随。
class GroupPager extends StatefulWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<Widget> children;

  const GroupPager({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.children,
  });

  @override
  State<GroupPager> createState() => _GroupPagerState();
}

class _GroupPagerState extends State<GroupPager> {
  late final PageController _controller = PageController(
    initialPage: widget.selected,
  );
  late int _visible = widget.selected;

  @override
  void didUpdateWidget(covariant GroupPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != _visible) {
      _visible = widget.selected;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _animateTo(widget.selected),
      );
    }
  }

  void _animateTo(int index) {
    if (!mounted || !_controller.hasClients) return;
    final current = (_controller.page ?? _controller.initialPage.toDouble())
        .round();
    if (current == index) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GroupTabs(
          labels: widget.labels,
          selected: widget.selected,
          onChanged: widget.onChanged,
        ),
        Expanded(
          child: PageView(
            controller: _controller,
            physics: const PageScrollPhysics(),
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              widget.onChanged(index);
            },
            children: widget.children
                .map((child) => KeepAlivePage(child: child))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle(size: 21)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: Color(0xFF6F8A72),
            ),
          ),
          const SizedBox(height: 7),
          Text(title, style: displayStyle(size: 29)),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: 12), trailing!],
        ],
      ),
    );
  }
}

enum PillTone { filled, outline, soft }

class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PillTone tone;
  final bool expand;
  final double height;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.tone = PillTone.filled,
    this.expand = false,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      PillTone.filled => AppColors.green,
      PillTone.outline => AppColors.surface,
      PillTone.soft => const Color(0xFFEEF2E7),
    };
    final fg = switch (tone) {
      PillTone.filled => AppColors.cream,
      PillTone.outline => AppColors.ink2,
      PillTone.soft => AppColors.green2,
    };
    final border = switch (tone) {
      PillTone.filled => Colors.transparent,
      PillTone.outline => AppColors.line,
      PillTone.soft => const Color(0xFFDFE7D5),
    };
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
        boxShadow: tone == PillTone.filled
            ? const [
                BoxShadow(
                  color: Color(0x241F4433),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
    return Pressable(onTap: onPressed, child: child);
  }
}

class IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color background;
  final Color color;

  const IconPill({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 34,
    this.background = const Color(0xFFEEF1E8),
    this.color = AppColors.green2,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * .34),
        ),
        child: Icon(icon, size: size * .48, color: color),
      ),
    );
  }
}

class CircleArrow extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const CircleArrow({super.key, this.onTap, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(
          Icons.arrow_outward_rounded,
          size: size * .46,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}

class SoftTag extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;

  const SoftTag(
    this.text, {
    super.key,
    this.background = const Color(0xFFEEF1E8),
    this.color = AppColors.green2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Row(
        children: [
          IconPill(icon: icon, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle(size: 15)),
                const SizedBox(height: 4),
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
      ),
    );
  }
}

class SubpageFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const SubpageFrame({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F8F4), AppColors.paper, Color(0xFFF3F4EE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
                child: Row(
                  children: [
                    IconPill(
                      icon: Icons.arrow_back_rounded,
                      background: Colors.white,
                      color: AppColors.ink2,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              // 每个二级页面使用自己的滚动控制器，避免沿用上一页的滚动位置。
              Expanded(child: PrimaryScrollController.none(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
