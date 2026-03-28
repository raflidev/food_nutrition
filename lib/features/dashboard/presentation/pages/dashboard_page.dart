import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../providers/gemini_status_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    int totalCalories = 0;
    int totalProtein = 0;
    
    // Hitung total kalori hari ini
    historyState.whenData((meals) {
      final today = DateTime.now();
      final todayMeals = meals.where((m) => 
        m.date.year == today.year && 
        m.date.month == today.month && 
        m.date.day == today.day
      );
      for (var meal in todayMeals) {
        totalCalories += meal.calories;
        totalProtein += meal.protein;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildGeminiStatus(ref),
              const SizedBox(height: 20),
              _buildEnergyCard(totalCalories),
              const SizedBox(height: 24),
              _buildMacroRings(totalProtein),
              const SizedBox(height: 24),
              _buildCtaBanner(context),
              const SizedBox(height: 32),
              Text("Today's Timeline", style: AppTypography.titleLarge),
              const SizedBox(height: 16),
              _buildTimeline(historyState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.person, color: AppColors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome", style: AppTypography.labelSmall),
                Text("Healthy People", style: AppTypography.titleMedium),
              ],
            )
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
        )
      ],
    );
  }

  Widget _buildGeminiStatus(WidgetRef ref) {
    final statusAsync = ref.watch(geminiStatusProvider);

    return statusAsync.when(
      loading: () => _buildStatusChip(
        icon: Icons.hourglass_empty,
        label: 'Memeriksa Gemini AI...',
        color: AppColors.onSurfaceVariant,
        bgAlpha: 15,
        borderAlpha: 40,
      ),
      error: (_, _e) => _buildStatusChip(
        icon: Icons.warning_amber_outlined,
        label: 'Gagal memeriksa Gemini',
        color: AppColors.error,
        bgAlpha: 15,
        borderAlpha: 60,
      ),
      data: (info) {
        final color = switch (info.status) {
          GeminiStatus.ready => AppColors.primary,
          GeminiStatus.networkError => Colors.orange,
          _ => AppColors.error,
        };
        final icon = switch (info.status) {
          GeminiStatus.ready => Icons.check_circle_outline,
          GeminiStatus.networkError => Icons.wifi_off_outlined,
          GeminiStatus.invalidKey => Icons.vpn_key_off_outlined,
          GeminiStatus.noKey => Icons.key_off_outlined,
          _ => Icons.warning_amber_outlined,
        };
        return _buildStatusChip(
          icon: icon,
          label: info.message,
          color: color,
          bgAlpha: 15,
          borderAlpha: 60,
        );
      },
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
    required int bgAlpha,
    required int borderAlpha,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(bgAlpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyCard(int totalCalories) {
    final double progress = (totalCalories / 2500).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Daily Energy", style: AppTypography.titleMedium.copyWith(color: AppColors.onPrimaryContainer)),
              const Icon(Icons.local_fire_department, color: AppColors.onPrimaryContainer),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "$totalCalories",
            style: AppTypography.displayLarge.copyWith(height: 1.0, color: AppColors.onPrimaryContainer),
          ),
          Text(
            "kcal / 2,500 goal",
            style: AppTypography.labelMedium.copyWith(color: AppColors.onPrimaryContainer.withAlpha(200)),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha(50),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRings(int totalProtein) {
    // Dummy values for demonstration, protein comes from real data
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard("Protein", "$totalProtein g", 150, AppColors.tertiaryContainer, AppColors.onTertiaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMacroCard("Carbs", "140 g", 280, AppColors.secondaryContainer, AppColors.onSecondaryContainer),
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, String value, int goal, Color bgColor, Color textColor) {
    final int currentVal = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final double progress = (currentVal / goal).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMedium.copyWith(color: textColor.withAlpha(180))),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.headlineMedium.copyWith(color: textColor)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha(100),
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/camera'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Log Makanan", style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text("Identifikasi dengan AI", style: AppTypography.bodySmall),
              ],
            ),
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.camera_alt, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(AsyncValue historyState) {
    return historyState.when(
      data: (meals) {
        final today = DateTime.now();
        final todayMeals = meals.where((m) => 
          m.date.year == today.year && 
          m.date.month == today.month && 
          m.date.day == today.day
        ).toList();

        if (todayMeals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                "Belum ada makanan hari ini.",
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: todayMeals.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final meal = todayMeals[index];
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(meal.imagePath),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 64, height: 64,
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(Icons.fastfood, color: AppColors.outlineVariant),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.label, style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        "${meal.calories} kcal • ${meal.date.hour}:${meal.date.minute.toString().padLeft(2, '0')}", 
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text("${meal.protein}g P", style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Text("Error: $e"),
    );
  }
}
