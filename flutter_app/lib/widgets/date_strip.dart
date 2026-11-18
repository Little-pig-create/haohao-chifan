import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import 'common.dart';

class DateStrip extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const DateStrip({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -120) {
          onChanged((selected + 1).clamp(0, weekDays.length - 1));
        } else if (details.primaryVelocity! > 120) {
          onChanged((selected - 1).clamp(0, weekDays.length - 1));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: cardDecoration(),
        child: Row(
          children: List.generate(weekDays.length, (index) {
            final active = selected == index;
            final today = index == todayIndex;
            return Expanded(
              child: Pressable(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: 55,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: active ? AppColors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: active
                        ? const [
                            BoxShadow(
                              color: Color(0x291F4433),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekDays[index].weekday,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: active
                              ? const Color(0xFFC9D9C4)
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weekDays[index].day,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? const Color(0xFFF8F2DF)
                              : AppColors.ink,
                        ),
                      ),
                      if (today) ...[
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: active ? AppColors.cream : AppColors.apricot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
