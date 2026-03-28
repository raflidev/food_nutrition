import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/capture/presentation/pages/camera_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../core/widgets/bottom_nav_bar.dart';
import '../features/analysis/domain/models/prediction_result.dart';
import '../features/analysis/presentation/pages/analysis_result_page.dart';
import '../features/history/domain/models/meal_log.dart';
import '../features/history/presentation/pages/history_detail_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/camera',
          builder: (context, state) => const CameraPage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return AnalysisResultPage(
          imageFile: extras['image'] as File?,
          prediction: extras['prediction'] as PredictionResult,
        );
      },
    ),
    GoRoute(
      path: '/history/detail',
      builder: (context, state) {
        final meal = state.extra as MealLog;
        return HistoryDetailPage(meal: meal);
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
