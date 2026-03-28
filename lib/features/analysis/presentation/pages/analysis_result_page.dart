import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/prediction_result.dart';
import '../../domain/models/nutrition_info.dart';
import '../../domain/models/meal_info.dart';
import '../providers/analysis_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../history/domain/models/meal_log.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../../services/storage/meal_extras_storage.dart';

class AnalysisResultPage extends ConsumerStatefulWidget {
  final File? imageFile;
  final PredictionResult prediction;

  const AnalysisResultPage({
    super.key,
    required this.imageFile,
    required this.prediction,
  });

  @override
  ConsumerState<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends ConsumerState<AnalysisResultPage> {
  final String _geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  bool _needsKeyInput = false;
  bool _isSaving = false;
  bool _showFullInstructions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_geminiApiKey.isEmpty) {
        setState(() => _needsKeyInput = true);
      } else {
        _loadData(_geminiApiKey);
      }
    });
  }

  void _loadData(String key) {
    ref.read(analysisProvider.notifier).loadAnalysis(widget.prediction.label, key);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisProvider);

    if (_needsKeyInput) return _buildApiKeyScreen();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          _buildBody(state),
          // Back button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildCircleButton(Icons.arrow_back, () => context.pop()),
          ),
          // Add to log sticky button
          if (!state.isLoading && (state.nutritionInfo != null || state.mealInfo != null))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: widget.prediction.confidence >= 0.1
                  ? _buildStickyButton(state)
                  : _buildLowConfidenceBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AnalysisState state) {
    return CustomScrollView(
      slivers: [
        // Hero image + food name
        SliverToBoxAdapter(child: _buildHeroSection()),

        if (state.isLoading)
          SliverFillRemaining(child: _buildLoadingState())
        else ...[
          if (state.error != null)
            SliverToBoxAdapter(child: _buildErrorBanner(state.error!)),
          if (state.geminiError != null)
            SliverToBoxAdapter(child: _buildGeminiErrorBanner(state.geminiError!)),
          if (state.nutritionInfo != null)
            SliverToBoxAdapter(child: _buildNutritionSection(state.nutritionInfo!)),
          if (state.mealInfo != null)
            SliverToBoxAdapter(child: _buildRecipeSection(state.mealInfo!))
          else if (!state.isLoading)
            SliverToBoxAdapter(child: _buildNoRecipeBanner()),
          // Bottom padding for sticky button
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ],
    );
  }

  Widget _buildHeroSection() {
    final confidence = (widget.prediction.confidence * 100).toStringAsFixed(1);
    final screenHeight = 320.0;

    return Stack(
      children: [
        // Food image
        SizedBox(
          height: screenHeight,
          width: double.infinity,
          child: widget.imageFile != null
              ? Image.file(widget.imageFile!, fit: BoxFit.cover)
              : Container(
                  color: AppColors.surfaceContainerHigh,
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 72, color: AppColors.outlineVariant),
                  ),
                ),
        ),
        // Gradient overlay
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
        // Food name + confidence at bottom of image
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 12, color: AppColors.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text("AI ANALYZED",
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.prediction.label,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black.withAlpha(100))],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Confidence bar
              Row(
                children: [
                  Text("Confidence $confidence%",
                      style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.prediction.confidence,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                        minHeight: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text("Menganalisis nutrisi...",
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(error,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
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
          border: Border.all(color: AppColors.outlineVariant.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Referensi resep tidak ditemukan untuk makanan ini.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Info nutrisi dari Gemini tidak tersedia. Menampilkan referensi resep saja.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(dynamic info) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Estimasi Nutrisi", style: AppTypography.titleMedium),
              const Spacer(),
              Text("per 1 porsi",
                  style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          // Calories card (wide)
          _buildCalorieCard(info.calories),
          const SizedBox(height: 12),
          // Macro grid 3 columns
          Row(
            children: [
              Expanded(child: _buildMacroTile(Icons.egg_outlined, "Protein", info.protein, AppColors.tertiaryContainer, AppColors.onTertiaryContainer)),
              const SizedBox(width: 10),
              Expanded(child: _buildMacroTile(Icons.grain_outlined, "Karbo", info.carbohydrates, AppColors.secondaryContainer, AppColors.onSecondaryContainer)),
              const SizedBox(width: 10),
              Expanded(child: _buildMacroTile(Icons.opacity_outlined, "Lemak", info.fat, AppColors.surfaceContainerHigh, AppColors.onSurface)),
            ],
          ),
          const SizedBox(height: 10),
          _buildFiberRow(info.fiber),
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
          const Icon(Icons.local_fire_department, color: AppColors.primaryContainer, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(calories,
                  style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              Text("Kalori",
                  style: AppTypography.labelMedium.copyWith(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTile(IconData icon, String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.titleMedium.copyWith(color: fg, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: AppTypography.labelSmall.copyWith(color: fg.withAlpha(180))),
        ],
      ),
    );
  }

  Widget _buildFiberRow(String fiber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.grass_outlined, size: 18, color: AppColors.tertiary),
          const SizedBox(width: 10),
          Text("Serat", style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
          const Spacer(),
          Text(fiber, style: AppTypography.titleMedium.copyWith(color: AppColors.tertiary)),
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
              const Icon(Icons.menu_book_outlined, size: 20, color: AppColors.primary),
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
                BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name, style: AppTypography.titleMedium),
                if (meal.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text("Bahan utama",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      meal.ingredients.length > 6 ? 6 : meal.ingredients.length,
                      (i) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  Text("Cara masak",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(
                    meal.instructions!,
                    style: AppTypography.bodySmall.copyWith(height: 1.6),
                    maxLines: _showFullInstructions ? null : 4,
                    overflow: _showFullInstructions ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showFullInstructions = !_showFullInstructions),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showFullInstructions ? 'Tampilkan lebih sedikit' : 'Baca selengkapnya',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showFullInstructions ? Icons.expand_less : Icons.expand_more,
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

  Widget _buildLowConfidenceBanner() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Confidence terlalu rendah (< 10%). Tidak dapat menyimpan ke riwayat.",
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyButton(AnalysisState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isSaving ? null : () => _saveToLog(state.nutritionInfo, state.mealInfo),
          icon: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add, color: Colors.white),
          label: Text(_isSaving ? "Menyimpan..." : "Simpan ke Riwayat",
              style: AppTypography.titleMedium.copyWith(color: Colors.white)),
        ),
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

  Widget _buildApiKeyScreen() {
    final controller = TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.key_rounded, size: 32, color: AppColors.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text("API Key Diperlukan", style: AppTypography.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                "Masukkan Gemini API Key untuk mendapatkan informasi nutrisi.",
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  labelText: "Gemini API Key",
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() => _needsKeyInput = false);
                    _loadData(controller.text);
                  }
                },
                child: const Text("Lanjutkan"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToLog(NutritionInfo? info, MealInfo? mealInfo) async {
    setState(() => _isSaving = true);
    int parse(String? raw) =>
        int.tryParse(raw?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;

    final log = MealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: widget.prediction.label,
      imagePath: widget.imageFile?.path ?? '',
      calories: parse(info?.calories),
      protein: parse(info?.protein),
      carbohydrates: parse(info?.carbohydrates),
      fat: parse(info?.fat),
      fiber: parse(info?.fiber),
      date: DateTime.now(),
    );

    await ref.read(historyProvider.notifier).addMeal(log);
    await MealExtrasStorageService().saveExtras(log.id, info, mealInfo);

    if (mounted) {
      context.go('/history');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Berhasil disimpan ke riwayat!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
