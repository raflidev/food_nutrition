import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../history/domain/models/meal_log.dart';
import '../../../history/presentation/providers/history_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: historyState.when(
          data: (meals) => _buildContent(context, ref, meals),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text("Error: $e")),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<MealLog> meals) {
    // Group by date
    final Map<String, List<MealLog>> grouped = {};
    for (final meal in meals) {
      final key = _dateKey(meal.date);
      grouped.putIfAbsent(key, () => []).add(meal);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Meal History", style: AppTypography.headlineMedium),
                    Text("${meals.length} makanan tercatat",
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_month_outlined, color: AppColors.onSurface),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),

        if (meals.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else ...[
          // Summary strip
          SliverToBoxAdapter(child: _buildSummaryStrip(meals)),

          // Meal groups
          for (final dateKey in sortedDates) ...[
            SliverToBoxAdapter(
              child: _buildDateHeader(context, dateKey, grouped[dateKey]!),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildMealCard(context, ref, grouped[dateKey]![i]),
                childCount: grouped[dateKey]!.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  Widget _buildSummaryStrip(List<MealLog> meals) {
    final totalKcal = meals.fold(0, (s, m) => s + m.calories);
    final totalProtein = meals.fold(0, (s, m) => s + m.protein);
    final avgDaily = meals.isEmpty ? 0 : (totalKcal / _uniqueDays(meals)).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          _buildStatChip(Icons.local_fire_department_outlined, "$totalKcal", "Total kcal", AppColors.primaryContainer, AppColors.onPrimaryContainer),
          const SizedBox(width: 12),
          _buildStatChip(Icons.fitness_center_outlined, "${totalProtein}g", "Protein", AppColors.tertiaryContainer, AppColors.onTertiaryContainer),
          const SizedBox(width: 12),
          _buildStatChip(Icons.show_chart, "$avgDaily", "Avg kcal/hari", AppColors.secondaryContainer, AppColors.onSecondaryContainer),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.titleMedium.copyWith(color: fg)),
            Text(label, style: AppTypography.labelSmall.copyWith(color: fg.withAlpha(180), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, String dateKey, List<MealLog> meals) {
    final dailyKcal = meals.fold(0, (s, m) => s + m.calories);
    final label = _dateLabel(dateKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text("${meals.length} makanan",
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
          const Spacer(),
          Text("$dailyKcal kcal",
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, WidgetRef ref, MealLog meal) {
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: AppColors.error, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Hapus makanan?"),
            content: Text("\"${meal.label}\" akan dihapus dari riwayat."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Hapus", style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => ref.read(historyProvider.notifier).deleteMeal(meal.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Food image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Image.file(
                File(meal.imagePath),
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, _) => Container(
                  width: 90,
                  height: 90,
                  color: AppColors.surfaceContainerHigh,
                  child: const Icon(Icons.restaurant, color: AppColors.outlineVariant, size: 32),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.label,
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildNutriBadge("${meal.calories} kcal", AppColors.primaryContainer, AppColors.onPrimaryContainer),
                        const SizedBox(width: 6),
                        _buildNutriBadge("${meal.protein}g protein", AppColors.tertiaryContainer, AppColors.onTertiaryContainer),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Time
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _formatTime(meal.date),
                style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutriBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: fg, fontSize: 10)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.no_meals_outlined, size: 36, color: AppColors.outlineVariant),
          ),
          const SizedBox(height: 20),
          Text("Belum ada riwayat", style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            "Foto makananmu dan mulai tracking\nnutrisi harianmu.",
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  String _dateKey(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  String _dateLabel(String dateKey) {
    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    if (dateKey == today) return "Hari ini";
    if (dateKey == yesterday) return "Kemarin";
    final parts = dateKey.split('-');
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${parts[2]} ${months[int.parse(parts[1])]} ${parts[0]}";
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  int _uniqueDays(List<MealLog> meals) {
    return meals.map((m) => _dateKey(m.date)).toSet().length;
  }
}
