import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../history/domain/models/meal_log.dart';
import '../../../history/presentation/providers/history_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: historyState.when(
          data: (meals) => _buildContent(context, meals),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text("Error: $e")),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<MealLog> allMeals) {
    final meals = _selectedDate == null
        ? allMeals
        : allMeals.where((m) {
            final d = m.date;
            return d.year == _selectedDate!.year &&
                d.month == _selectedDate!.month &&
                d.day == _selectedDate!.day;
          }).toList();

    final Map<String, List<MealLog>> grouped = {};
    for (final meal in meals) {
      final key = _dateKey(meal.date);
      grouped.putIfAbsent(key, () => []).add(meal);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final subtitle = _selectedDate == null
        ? "${allMeals.length} makanan tercatat"
        : "${meals.length} makanan pada ${_formatSelectedDate(_selectedDate!)}";

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Meal History", style: AppTypography.headlineMedium),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _selectedDate != null
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.calendar_month,
                          color: _selectedDate != null
                              ? Colors.white
                              : AppColors.onSurface,
                        ),
                        onPressed: () => _openCalendarSheet(context, allMeals),
                      ),
                    ),
                  ],
                ),

                if (_selectedDate != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDate = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatSelectedDate(_selectedDate!),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.close, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (meals.isEmpty)
          SliverFillRemaining(
            child: _selectedDate != null
                ? _buildEmptyFilterState()
                : _buildEmptyState(),
          )
        else ...[
          SliverToBoxAdapter(child: _buildSummaryStrip(meals)),

          for (final dateKey in sortedDates) ...[
            SliverToBoxAdapter(
              child: _buildDateHeader(context, dateKey, grouped[dateKey]!),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) =>
                    _buildMealCard(context, ref, grouped[dateKey]![i]),
                childCount: grouped[dateKey]!.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }

  void _openCalendarSheet(BuildContext context, List<MealLog> allMeals) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CalendarBottomSheet(
        meals: allMeals,
        selectedDate: _selectedDate,
        onDateSelected: (date) {
          setState(() => _selectedDate = date);
        },
      ),
    );
  }

  Widget _buildSummaryStrip(List<MealLog> meals) {
    final totalKcal = meals.fold(0, (s, m) => s + m.calories);
    final totalProtein = meals.fold(0, (s, m) => s + m.protein);
    final avgDaily =
        meals.isEmpty ? 0 : (totalKcal / _uniqueDays(meals)).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          _buildStatChip(
            Icons.local_fire_department_outlined,
            "$totalKcal",
            "Total kcal",
            AppColors.primaryContainer,
            AppColors.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.fitness_center_outlined,
            "${totalProtein}g",
            "Protein",
            AppColors.tertiaryContainer,
            AppColors.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.show_chart,
            "$avgDaily",
            "Avg kcal/hari",
            AppColors.secondaryContainer,
            AppColors.onSecondaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String value, String label, Color bg, Color fg) {
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
            Text(
              label,
              style: AppTypography.labelSmall
                  .copyWith(color: fg.withAlpha(180), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(
      BuildContext context, String dateKey, List<MealLog> meals) {
    final dailyKcal = meals.fold(0, (s, m) => s + m.calories);
    final label = _dateLabel(dateKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${meals.length} makanan",
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            "$dailyKcal kcal",
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Hapus makanan?"),
            content:
                Text("\"${meal.label}\" akan dihapus dari riwayat."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Hapus",
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(historyProvider.notifier).deleteMeal(meal.id),
      child: GestureDetector(
        onTap: () => context.push('/history/detail', extra: meal),
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
                  errorBuilder: (context2, err, stack) => Container(
                    width: 90,
                    height: 90,
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.restaurant,
                        color: AppColors.outlineVariant, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                          _buildNutriBadge(
                            "${meal.calories} kcal",
                            AppColors.primaryContainer,
                            AppColors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          _buildNutriBadge(
                            "${meal.protein}g protein",
                            AppColors.tertiaryContainer,
                            AppColors.onTertiaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  _formatTime(meal.date),
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
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
      child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(color: fg, fontSize: 10)),
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
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.no_meals_outlined,
                size: 36, color: AppColors.outlineVariant),
          ),
          const SizedBox(height: 20),
          Text("Belum ada riwayat", style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            "Foto makananmu dan mulai tracking\nnutrisi harianmu.",
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_outlined,
                size: 36, color: AppColors.outlineVariant),
          ),
          const SizedBox(height: 20),
          Text("Tidak ada data", style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            "Tidak ada makanan tercatat\npada tanggal ini.",
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _selectedDate = null),
            child: Text(
              "Tampilkan Semua",
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  String _dateLabel(String dateKey) {
    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    if (dateKey == today) return "Hari ini";
    if (dateKey == yesterday) return "Kemarin";
    final parts = dateKey.split('-');
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return "${parts[2]} ${months[int.parse(parts[1])]} ${parts[0]}";
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  String _formatSelectedDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return "${date.day} ${months[date.month]} ${date.year}";
  }

  int _uniqueDays(List<MealLog> meals) =>
      meals.map((m) => _dateKey(m.date)).toSet().length;
}

class _CalendarBottomSheet extends StatefulWidget {
  const _CalendarBottomSheet({
    required this.meals,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<MealLog> meals;
  final DateTime? selectedDate;
  final void Function(DateTime?) onDateSelected;

  @override
  State<_CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<_CalendarBottomSheet> {
  late DateTime _displayMonth;

  late Set<String> _mealDates;

  @override
  void initState() {
    super.initState();
    _mealDates = widget.meals
        .map((m) =>
            "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}")
        .toSet();

    if (widget.meals.isNotEmpty) {
      final latest = widget.meals
          .reduce((a, b) => a.date.isAfter(b.date) ? a : b)
          .date;
      _displayMonth = DateTime(latest.year, latest.month);
    } else {
      final now = DateTime.now();
      _displayMonth = DateTime(now.year, now.month);
    }
  }

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  bool _hasMeals(DateTime d) => _mealDates.contains(_dateKey(d));

  bool _isSelected(DateTime d) {
    final s = widget.selectedDate;
    return s != null &&
        s.year == d.year &&
        s.month == d.month &&
        s.day == d.day;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return now.year == d.year && now.month == d.month && now.day == d.day;
  }

  void _prevMonth() => setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text("Pilih Tanggal", style: AppTypography.titleMedium),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
                color: AppColors.onSurface,
              ),
              Text(
                _monthYearLabel(_displayMonth),
                style: AppTypography.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                color: AppColors.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          _buildGrid(),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              widget.onDateSelected(null);
              Navigator.pop(context);
            },
            child: Text(
              "Tampilkan Semua",
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final year = _displayMonth.year;
    final month = _displayMonth.month;

    final firstWeekday = DateTime(year, month, 1).weekday % 7;

    final daysInMonth = DateTime(year, month + 1, 0).day;

    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNumber = cellIndex - firstWeekday + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 52));
            }

            final date = DateTime(year, month, dayNumber);
            return Expanded(child: _buildDayCell(date));
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final selected = _isSelected(date);
    final today = _isToday(date);
    final hasMeals = _hasMeals(date);

    Color? bgColor;
    Color textColor = AppColors.onSurface;
    BoxBorder? border;

    if (selected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (today) {
      border = Border.all(color: AppColors.primary, width: 1.5);
      textColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        widget.onDateSelected(date);
        Navigator.pop(context);
      },
      child: SizedBox(
        height: 52,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: border,
                ),
                child: Center(
                  child: Text(
                    "${date.day}",
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight:
                          (selected || today) ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasMeals
                      ? (selected ? Colors.white.withAlpha(180) : AppColors.primary)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthYearLabel(DateTime d) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return "${months[d.month]} ${d.year}";
  }
}
