import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/theme/app_text_styles.dart';
import 'package:flutter_app/features/home/presentation/widgets/progress_ring.dart';

class TargetBlock extends StatelessWidget {
  final int total;
  final int current;

  const TargetBlock({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final remaining = (total - current).clamp(0, total);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgressRing(current: current, total: total, size: 92),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Цель на год".toUpperCase(), style: AppTextStyles.label),
                const SizedBox(height: 8),
                Text(
                  "Осталось $remaining книг до конца года",
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("7", style: AppTextStyles.titleColor),
                          Text("дней подряд", style: AppTextStyles.label),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("12", style: AppTextStyles.titleColor),
                          Text("цитат", style: AppTextStyles.label),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
