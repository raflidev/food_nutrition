import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/prediction_result.dart';
import '../providers/analysis_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../history/domain/models/meal_log.dart';
import '../../../history/presentation/providers/history_provider.dart';

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
  // In a real app, GET THIS KEY FROM FLAVOR CONFIG / ENV. For submission, provide a placeholder or text field.
  final String _geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  // A simple flag to trigger an API key input dialog if missing
  bool _needsKeyInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_geminiApiKey.isEmpty) {
        setState(() {
          _needsKeyInput = true;
        });
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Analysis Result"),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: _needsKeyInput
          ? _buildApiKeyInput()
          : (state.isLoading
              ? _buildLoading()
              : _buildContent(state)),
    );
  }

  Widget _buildApiKeyInput() {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.key, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            "Gemini API Key Required",
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Untuk mengambil data nutrisi dari AI, masukkan API Key Anda.",
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "API Key",
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _needsKeyInput = false;
                });
                _loadData(controller.text);
              }
            },
            child: const Text("Lanjutkan"),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildContent(AnalysisState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Space for fab/footer
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(widget.imageFile, widget.prediction),
          if (state.error != null) _buildErrorCard(state.error!),
          if (state.nutritionInfo != null)
            _buildNutritionSection(state.nutritionInfo!),
          if (state.mealInfo != null)
            _buildRecipeSection(state.mealInfo!),
          if (state.nutritionInfo != null)
            _buildActionFooter(state.nutritionInfo!),
        ],
      ),
    );
  }

  Widget _buildHeader(File? imageFile, PredictionResult prediction) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Image
          if (imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(
                imageFile,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: Icon(Icons.restaurant, size: 64, color: AppColors.outlineVariant)),
            ),
          const SizedBox(height: 24),
          
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  "AI ANALYZED",
                  style: AppTypography.labelSmall.copyWith(color: AppColors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Food Name & Confidence
          Text(
            prediction.label,
            style: AppTypography.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%",
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "Oops! $error",
        style: TextStyle(color: AppColors.onErrorContainer),
      ),
    );
  }

  // Gemini Nutrition output
  Widget _buildNutritionSection(dynamic info) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Estimasi Nutrisi (Gemini AI)", style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMacroCard("Kalori", info.calories, AppColors.primaryContainer)),
              const SizedBox(width: 16),
              Expanded(child: _buildMacroCard("Protein", info.protein, AppColors.tertiaryContainer)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMacroCard("Lemak", info.fat, AppColors.surfaceContainerHigh)),
              const SizedBox(width: 16),
              Expanded(child: _buildMacroCard("Karbo", info.carbohydrates, AppColors.surfaceContainerHigh)),
            ],
          ),
          const SizedBox(height: 16),
          // Fiber could fit below or beside
          _buildMacroCard("Serat", info.fiber, AppColors.surfaceContainerHigh),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  // MealDB output
  Widget _buildRecipeSection(dynamic meal) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Referensi Resep (MealDB)", style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name, style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                if (meal.ingredients.isNotEmpty) ...[
                  Text("Bahan Utama:", style: AppTypography.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      meal.ingredients.length > 5 ? 5 : meal.ingredients.length, // Show up to 5
                      (index) => Chip(
                        label: Text(
                          "${meal.ingredients[index]} ${meal.measures[index].isNotEmpty ? '(${meal.measures[index]})' : ''}".trim(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (meal.instructions != null) ...[
                  Text("Instruksi:", style: AppTypography.labelMedium),
                  const SizedBox(height: 8),
                  Text(
                    meal.instructions!,
                    style: AppTypography.bodySmall,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionFooter(dynamic info) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () async {
          final kaloriStr = info.calories.toString().replaceAll(RegExp(r'[^0-9]'), '');
          final proteinStr = info.protein.toString().replaceAll(RegExp(r'[^0-9]'), '');
          
          final log = MealLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            label: widget.prediction.label,
            imagePath: widget.imageFile?.path ?? '',
            calories: int.tryParse(kaloriStr) ?? 0,
            protein: int.tryParse(proteinStr) ?? 0,
            date: DateTime.now(),
          );

          await ref.read(historyProvider.notifier).addMeal(log);
          
          if (mounted) {
            context.go('/history');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Meal saved to history!')),
            );
          }
        },
        child: const Text('Add to Log'),
      ),
    );
  }
}
