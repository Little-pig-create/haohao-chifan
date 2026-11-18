import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';
import 'sheets.dart';

class HistoryLogSheet extends StatefulWidget {
  const HistoryLogSheet({super.key});

  @override
  State<HistoryLogSheet> createState() => _HistoryLogSheetState();
}

class _HistoryLogSheetState extends State<HistoryLogSheet> {
  DateTime _date = DateTime.now();

  String get _label => '${_date.year}年${_date.month}月${_date.day}日';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: '选择要查看的日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  IconData _icon(String kind) => switch (kind) {
    '早餐' => Icons.free_breakfast_outlined,
    '午餐' => Icons.lunch_dining_outlined,
    '晚餐' => Icons.dinner_dining_outlined,
    _ => Icons.local_cafe_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final records = state.addedForDate(state.dateKeyForDate(_date));
    final total = records.fold<int>(0, (sum, item) => sum + item.kcal);
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(
            icon: Icons.history_rounded,
            title: '饮食历史',
            subtitle: '按日期查看实际添加过的饮食记录。',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Pressable(
                  onTap: _pickDate,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: AppColors.green2,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 16,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${records.length} 项 · ${formatNumber(total)} 千卡',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: records.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 28),
                    child: Text(
                      '这一天还没有饮食记录',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = records[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9F5),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.lineSoft),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                _icon(item.kind),
                                size: 16,
                                color: AppColors.green2,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.kind} · ${item.time}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.kcal} 千卡',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
