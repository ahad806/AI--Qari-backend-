import 'package:al_qari/config/assets/app_assets.dart';
import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/core/services/progress_service.dart';
import 'package:al_qari/core/utils/responsive.dart';
import 'package:al_qari/features/progress/progress_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProgressController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          'Your Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          Obx(
            () => ctrl.isLoading.value
                ? const SizedBox.shrink()
                : ctrl.isRefreshing.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondaryPurple,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.secondaryPurple,
                    ),
                    onPressed: ctrl.loadProgress,
                  ),
          ),
        ],
      ),
      body: Obx(() {
        // Show full-screen spinner only on first load (no data yet).
        // Once hasData is true, keep showing existing data even while refreshing.
        if (ctrl.isLoading.value && !ctrl.hasData.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryPurple),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryPurple,
          onRefresh: ctrl.loadProgress,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Text(
                    'Track your recitation accuracy and Tajweed improvement over time.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.screenHeight(context) * 0.02),

                // ── Stats grid ──────────────────────────────────────────
                _StatsGrid(ctrl: ctrl),
                SizedBox(height: Responsive.screenHeight(context) * 0.025),

                // ── Accuracy breakdown ──────────────────────────────────
                _SectionTitle(title: 'Accuracy Breakdown'),
                const SizedBox(height: 12),
                _AccuracyRow(ctrl: ctrl),
                SizedBox(height: Responsive.screenHeight(context) * 0.025),

                // ── Chart ───────────────────────────────────────────────
                _SectionTitle(title: 'Recitation Accuracy Over Time'),
                const SizedBox(height: 12),
                _RecitationChart(history: ctrl.recitationHistory),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.ctrl});
  final ProgressController ctrl;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatCard(
          image: AppAssets.accuracyProgress,
          label: 'Accuracy',
          value: ctrl.overallAccuracy == 0
              ? '—'
              : '${ctrl.overallAccuracy.toStringAsFixed(0)}%',
          borderColor: Colors.green,
        ),
        _StatCard(
          image: AppAssets.surahProgress,
          label: 'Surahs',
          value: '${ctrl.totalSurahsRecited.value} Total',
          borderColor: AppColors.primaryPurple,
        ),
        _StatCard(
          image: AppAssets.streaksProgress,
          label: 'Streaks',
          value: '${ctrl.currentStreak.value} Days',
          borderColor: Colors.orange,
        ),
        _StatCard(
          image: AppAssets.timeProgress,
          label: 'Time',
          value: ctrl.formattedTime,
          borderColor: Colors.blueAccent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.image,
    required this.label,
    required this.value,
    required this.borderColor,
  });

  final String image;
  final String label;
  final String value;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 50),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Accuracy breakdown row ───────────────────────────────────────────────────

class _AccuracyRow extends StatelessWidget {
  const _AccuracyRow({required this.ctrl});
  final ProgressController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccuracyTile(
            label: 'Reading',
            value: ctrl.avgReadingAccuracy.value,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccuracyTile(
            label: 'Recitation',
            value: ctrl.avgRecitationAccuracy.value,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }
}

class _AccuracyTile extends StatelessWidget {
  const _AccuracyTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value == 0 ? '—' : '${value.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Line chart ───────────────────────────────────────────────────────────────

class _RecitationChart extends StatelessWidget {
  const _RecitationChart({required this.history});
  final List<SessionEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: AppColors.primaryPurple.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete recitations to see your accuracy over time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.accuracy);
    }).toList();

    final labelInterval = (history.length / 4).ceilToDouble().clamp(1.0, 999.0);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 36,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.darkPurple,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: labelInterval,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= history.length) {
                    return const SizedBox.shrink();
                  }
                  final dt = history[idx].createdAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${dt.day}/${dt.month}/${dt.year % 100}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.darkPurple,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primaryPurple,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.primaryPurple,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.25),
                    AppColors.primaryPurple.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map(
                    (s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(0)}%',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary.withValues(alpha: 0.9),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
