import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../history/presentation/providers/history_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Meal History"),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () {}),
        ],
      ),
      body: historyState.when(
        data: (meals) {
          if (meals.isEmpty) {
            return const Center(child: Text("Belum ada riwayat makanan."));
          }
          
          // Group by Date
          final Map<String, List<dynamic>> grouped = {};
          for (var meal in meals) {
            final dateStr = "${meal.date.year}-${meal.date.month.toString().padLeft(2, '0')}-${meal.date.day.toString().padLeft(2, '0')}";
            if (!grouped.containsKey(dateStr)) {
              grouped[dateStr] = [];
            }
            grouped[dateStr]!.add(meal);
          }

          final sortedDates = grouped.keys.toList()..sort((a,b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateStr = sortedDates[index];
              final dayMeals = grouped[dateStr]!;
              int dailyKcal = dayMeals.fold(0, (sum, m) => sum + (m.calories as int));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(dateStr, dailyKcal),
                  const SizedBox(height: 16),
                  ...dayMeals.map((meal) => _buildMealCard(meal, ref)),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDateHeader(String dateStr, int dailyKcal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(dateStr, style: AppTypography.titleMedium),
        Text("$dailyKcal kcal", style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildMealCard(dynamic meal, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(meal.imagePath),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 64, height: 64, color: AppColors.surfaceContainerHigh,
                child: const Icon(Icons.fastfood, color: AppColors.outlineVariant),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("AI SCAN", style: AppTypography.labelSmall.copyWith(color: AppColors.onPrimaryContainer, fontSize: 10)),
                ),
                const SizedBox(height: 4),
                Text(meal.label, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text("${meal.calories} kcal • ${meal.protein}g Protein", style: AppTypography.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => ref.read(historyProvider.notifier).deleteMeal(meal.id),
          )
        ],
      ),
    );
  }
}
