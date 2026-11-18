import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onSwap;
  final bool showTime;

  const MealCard({
    super.key,
    required this.meal,
    required this.completed,
    required this.onToggle,
    required this.onSwap,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFFBFCF6) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: completed ? const Color(0xFFCBD9C5) : AppColors.line,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1D2B23),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0D1D2B23),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 106,
              height: 136,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(meal.image, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF2FFFFFF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        meal.kind,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (showTime) ...[
                          _meta(Icons.schedule_rounded, meal.time),
                          const SizedBox(width: 10),
                        ],
                        _meta(
                          Icons.local_fire_department_outlined,
                          '${meal.kcal} 千卡',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle(size: 15.5, height: 1.28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: '换一个',
                            icon: Icons.refresh_rounded,
                            background: const Color(0xFFF4F1E8),
                            color: AppColors.ink2,
                            border: AppColors.line,
                            onTap: onSwap,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ActionButton(
                            label: completed ? '已完成' : '标记完成',
                            icon: Icons.check_rounded,
                            background: completed
                                ? const Color(0xFFE3EBDD)
                                : AppColors.green,
                            color: completed
                                ? const Color(0xFF3B6148)
                                : AppColors.cream,
                            border: completed
                                ? const Color(0xFFCBD9C3)
                                : AppColors.green,
                            onTap: onToggle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color color;
  final Color border;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.color,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 33,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
