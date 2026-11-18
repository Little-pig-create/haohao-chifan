import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _search = TextEditingController();
  int _filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8014241A),
      builder: (_) => RecipeDetailSheet(recipe: recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final keyword = _search.text.trim();
    final filter = recipeFilters[_filter];
    final list = recipes.where((recipe) {
      final byCategory = filter == '全部'
          ? true
          : filter == '已收藏'
          ? state.favorites.contains(recipe.id)
          : recipe.category == filter;
      final bySearch =
          keyword.isEmpty ||
          recipe.title.contains(keyword) ||
          recipe.summary.contains(keyword);
      return byCategory && bySearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 26),
      children: [
        const PageHeader(
          eyebrow: '精选健康灵感',
          title: '健康食谱',
          subtitle: '按热量和做法筛一遍，不用临时想吃什么。',
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: '搜索食谱...',
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recipeFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final active = _filter == index;
              return Pressable(
                onTap: () => setState(() => _filter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.green : AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: active ? AppColors.green : AppColors.line,
                    ),
                  ),
                  child: Text(
                    recipeFilters[index],
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? AppColors.cream : AppColors.ink2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_filter == 0 && keyword.isEmpty) ...[
          const SizedBox(height: 15),
          FadeSlideIn(
            child: Pressable(
              onTap: () => _open(recipes[1]),
              child: Container(
                height: 328,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D163020),
                      blurRadius: 34,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.hero),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(recipes[1].image, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [.18, .58, 1],
                            colors: [
                              Color(0x0013291C),
                              Color(0xA313291C),
                              Color(0xF011251A),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .22),
                                ),
                              ),
                              child: const Text(
                                '本周推荐',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFFF8F2DE),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '用一碗彩虹，\n唤醒身体的能量',
                              style: displayStyle(
                                size: 25,
                                color: const Color(0xFFFFFDF5),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              '12 种食材，膳食纤维和蛋白质都不低，20 分钟能做完。',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFDCE5D7),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '加入我的菜单',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.green,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 17,
                                    color: AppColors.green,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (list.isEmpty)
          const EmptyCard(
            icon: Icons.search_rounded,
            title: '没有找到符合条件的食谱',
            text: '换个关键词，或切到「全部」看看。',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 11) / 2;
              return Wrap(
                spacing: 11,
                runSpacing: 11,
                children: list.asMap().entries.map((entry) {
                  final index = entry.key;
                  final recipe = entry.value;
                  return FadeSlideIn(
                    key: ValueKey('recipe-${recipe.id}'),
                    index: index,
                    child: SizedBox(
                      width: width,
                      child: _RecipeCard(
                        recipe: recipe,
                        saved: state.favorites.contains(recipe.id),
                        onFavorite: () {
                          state.toggleFavorite(recipe.id);
                          showToast(
                            context,
                            state.favorites.contains(recipe.id)
                                ? '已收藏「${recipe.title}」'
                                : '已取消收藏「${recipe.title}」',
                          );
                        },
                        onOpen: () => _open(recipe),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool saved;
  final VoidCallback onFavorite;
  final VoidCallback onOpen;

  const _RecipeCard({
    required this.recipe,
    required this.saved,
    required this.onFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onOpen,
      child: Container(
        decoration: cardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 122,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'recipe-${recipe.id}',
                      child: Image.asset(recipe.image, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xEBFFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Pressable(
                        onTap: onFavorite,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            color: saved
                                ? AppColors.green
                                : const Color(0xF2FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            saved ? Icons.bookmark_rounded : Icons.add_rounded,
                            size: 16,
                            color: saved ? AppColors.cream : AppColors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle(size: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.minutes} 分钟',
                          style: const TextStyle(
                            fontSize: 8.8,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          Icons.local_fire_department_outlined,
                          size: 11,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${recipe.kcal} 千卡',
                          style: const TextStyle(
                            fontSize: 8.8,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.lineSoft),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            '查看食谱',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green2,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: AppColors.green2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
