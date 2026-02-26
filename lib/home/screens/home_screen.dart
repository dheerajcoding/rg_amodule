import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../models/home_mock_data.dart';
import '../models/home_models.dart';
import '../widgets/category_grid.dart';
import '../widgets/hero_slider.dart';
import '../widgets/package_card.dart';
import '../widgets/pandit_card.dart';

// ── Online / Offline filter state ─────────────────────────────────────────────
enum PanditFilter { all, online, offline }

final _panditFilterProvider =
    StateProvider<PanditFilter>((_) => PanditFilter.all);

// ── Home Screen ────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final filter = ref.watch(_panditFilterProvider);

    final pandits = kMockPandits.where((p) {
      switch (filter) {
        case PanditFilter.online:
          return p.isOnline;
        case PanditFilter.offline:
          return !p.isOnline;
        case PanditFilter.all:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────────
          _HomeAppBar(userName: user?.name ?? 'Guest'),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 1. Hero Slider
                HeroSlider(
                  slides: kHeroSlides,
                  height: 190,
                  onActionTap: (route) => context.push(route),
                ),
                const SizedBox(height: 24),

                // 2. Quick Categories
                const _SectionHeader(
                  title: 'Browse Categories',
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
                ),
                CategoryGrid(
                  categories: kCategories,
                  onCategoryTap: (cat) {
                    if (cat.route != null) context.push(cat.route!);
                  },
                ),
                const SizedBox(height: 28),

                // 3. Featured Pandits header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _SectionHeader(
                          title: 'Featured Pandits',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/services'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('See all',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Online / Offline toggle
                _PanditFilterToggle(
                  selected: filter,
                  onChanged: (v) =>
                      ref.read(_panditFilterProvider.notifier).state = v,
                ),
                const SizedBox(height: 14),

                // Pandit horizontal list
                _PanditList(pandits: pandits),
                const SizedBox(height: 28),

                // 4. Popular Packages header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _SectionHeader(
                          title: 'Popular Packages',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/packages'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('See all',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // 5. Packages as sliver list (pagination-ready)
          SliverList.builder(
            itemCount: kMockPackages.length,
            itemBuilder: (_, i) => PackageCard(
              package: kMockPackages[i],
              onTap: () => context.push('/booking'),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── App Bar ────────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.userName});

  final String userName;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      pinned: true,
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_greeting,',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.padding});

  final String title;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

// ── Online/Offline toggle ──────────────────────────────────────────────────────
class _PanditFilterToggle extends StatelessWidget {
  const _PanditFilterToggle({
    required this.selected,
    required this.onChanged,
  });

  final PanditFilter selected;
  final ValueChanged<PanditFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: PanditFilter.values.map((f) {
            final isSelected = selected == f;
            return GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (f == PanditFilter.online)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      )
                    else if (f == PanditFilter.offline)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      _label(f),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _label(PanditFilter f) {
    switch (f) {
      case PanditFilter.all:
        return 'All';
      case PanditFilter.online:
        return 'Online';
      case PanditFilter.offline:
        return 'Offline';
    }
  }
}

// ── Pandit horizontal list ─────────────────────────────────────────────────────
class _PanditList extends StatelessWidget {
  const _PanditList({required this.pandits});

  final List<MockPandit> pandits;

  @override
  Widget build(BuildContext context) {
    if (pandits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Text(
            'No pandits available right now.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pandits.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => PanditCard(
          pandit: pandits[i],
          onTap: () => context.push('/booking'),
        ),
      ),
    );
  }
}

