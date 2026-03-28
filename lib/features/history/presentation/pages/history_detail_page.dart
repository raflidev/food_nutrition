import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../history/domain/models/meal_log.dart';
import '../../../analysis/domain/models/meal_info.dart';
import '../../../analysis/presentation/providers/analysis_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../services/storage/meal_extras_storage.dart';
import '../../../../services/api/gemini_service.dart';
import '../../../../services/storage/meal_storage.dart';
import '../../../history/presentation/providers/history_provider.dart';

class HistoryDetailPage extends ConsumerStatefulWidget {
  final MealLog meal;

  const HistoryDetailPage({super.key, required this.meal});

  @override
  ConsumerState<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends ConsumerState<HistoryDetailPage> {
  bool _showFullInstructions = false;
  bool _isFetchingNutrition = false;
  String? _nutritionError;
  MealInfo? _localMeal;
  MealLog? _updatedMeal;

  final String _geminiApiKey =
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  MealLog get _meal => _updatedMeal ?? widget.meal;

  bool get _isNutritionEmpty => _meal.calories == 0 && _meal.protein == 0;

  @override
  void initState() {
    super.initState();

    final extras = MealExtrasStorageService().loadExtras(widget.meal.id);
    _localMeal = extras.meal;

    if (_localMeal == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(analysisProvider.notifier).loadMealDbOnly(widget.meal.label);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          _buildBody(state),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildCircleButton(Icons.arrow_back, () => context.pop()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSavedOnBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AnalysisState state) {
    final bool isLoading = _localMeal == null && state.isLoading;
    final MealInfo? meal = _localMeal ?? state.mealInfo;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeroSection()),

        if (isLoading)
          SliverFillRemaining(child: _buildLoadingState())
        else ...[
          SliverToBoxAdapter(child: _buildStoredNutritionSection()),
          if (meal != null)
            SliverToBoxAdapter(child: _buildRecipeSection(meal))
          else
            SliverToBoxAdapter(child: _buildNoRecipeBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ],
    );
  }

  Widget _buildHeroSection() {
    const screenHeight = 320.0;

    return Stack(
      children: [
        SizedBox(
          height: screenHeight,
          width: double.infinity,
          child: widget.meal.imagePath.isNotEmpty
              ? Image.file(File(widget.meal.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => _buildImagePlaceholder())
              : _buildImagePlaceholder(),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(180),
                ],
                stops: const [0.45, 1.0],
              ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history,
                        size: 12, color: AppColors.onSecondaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      "RIWAYAT",
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.meal.label,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black.withAlpha(100))
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(widget.meal.date),
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.restaurant,
            size: 72, color: AppColors.outlineVariant),
      ),
    );
  }

  Widget _buildStoredNutritionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.save_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Data Tersimpan", style: AppTypography.titleMedium),
              const Spacer(),
              Text(
                "saat pencatatan",
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isNutritionEmpty) ...[
            _buildGenerateNutritionBanner(),
          ] else ...[
            _buildCalorieCard('${_meal.calories} kcal'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildStoredMacroTile(Icons.egg_outlined, 'Protein', '${_meal.protein}g', AppColors.tertiaryContainer, AppColors.onTertiaryContainer)),
                const SizedBox(width: 8),
                Expanded(child: _buildStoredMacroTile(Icons.grain_outlined, 'Karbo', '${_meal.carbohydrates}g', AppColors.secondaryContainer, AppColors.onSecondaryContainer)),
                const SizedBox(width: 8),
                Expanded(child: _buildStoredMacroTile(Icons.opacity_outlined, 'Lemak', '${_meal.fat}g', AppColors.surfaceContainerHigh, AppColors.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            _buildStoredFiberRow('${_meal.fiber}g'),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateNutritionBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16,
                  color: _nutritionError != null ? AppColors.error : AppColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _nutritionError ?? 'Data nutrisi belum tersedia saat makanan ini dicatat.',
                  style: AppTypography.bodySmall.copyWith(
                    color: _nutritionError != null ? AppColors.error : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (_geminiApiKey.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isFetchingNutrition ? null : _generateNutrition,
                child: _isFetchingNutrition
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Text('Generate nutrisi dengan Gemini'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateNutrition() async {
    setState(() {
      _isFetchingNutrition = true;
      _nutritionError = null;
    });

    try {
      final result = await GeminiService(_geminiApiKey).getNutritionInfo(_meal.label);
      if (result == null) {
        if (mounted) setState(() => _nutritionError = 'Gemini tidak mengembalikan data nutrisi.');
        return;
      }

      int parse(String? raw) =>
          int.tryParse(raw?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;

      final updated = MealLog(
        id: _meal.id,
        label: _meal.label,
        imagePath: _meal.imagePath,
        date: _meal.date,
        calories: parse(result.calories),
        protein: parse(result.protein),
        carbohydrates: parse(result.carbohydrates),
        fat: parse(result.fat),
        fiber: parse(result.fiber),
      );

      await MealStorageService().saveMeal(updated);
      await MealExtrasStorageService().saveExtras(updated.id, result, _localMeal);

      ref.invalidate(historyProvider);

      if (mounted) setState(() => _updatedMeal = updated);
    } catch (e) {
      if (mounted) setState(() => _nutritionError = e.toString());
    } finally {
      if (mounted) setState(() => _isFetchingNutrition = false);
    }
  }

  Widget _buildStoredMacroTile(IconData icon, String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.titleMedium.copyWith(color: fg, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: AppTypography.labelSmall.copyWith(color: fg.withAlpha(180))),
        ],
      ),
    );
  }

  Widget _buildStoredFiberRow(String fiber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.grass_outlined, size: 18, color: AppColors.tertiary),
          const SizedBox(width: 10),
          Text('Serat', style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
          const Spacer(),
          Text(fiber, style: AppTypography.titleMedium.copyWith(color: AppColors.tertiary)),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(String calories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.primaryContainer, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                calories,
                style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
              Text(
                "Kalori",
                style: AppTypography.labelMedium
                    .copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSection(dynamic meal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Referensi Resep", style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name, style: AppTypography.titleMedium),
                if (meal.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Bahan utama",
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      meal.ingredients.length > 6
                          ? 6
                          : meal.ingredients.length,
                      (i) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meal.ingredients[i],
                          style: AppTypography.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ],
                if (meal.instructions != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text(
                    "Cara masak",
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal.instructions!,
                    style:
                        AppTypography.bodySmall.copyWith(height: 1.6),
                    maxLines: _showFullInstructions ? null : 4,
                    overflow: _showFullInstructions
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(
                        () => _showFullInstructions = !_showFullInstructions),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showFullInstructions
                              ? 'Tampilkan lebih sedikit'
                              : 'Baca selengkapnya',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showFullInstructions
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecipeBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.outlineVariant.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Referensi resep tidak ditemukan untuk makanan ini.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          "Memuat detail...",
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSavedOnBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            "Disimpan pada ${_formatDateTime(widget.meal.date)}",
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(80),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return "${date.day} ${months[date.month]} ${date.year}, $h:$m";
  }
}
