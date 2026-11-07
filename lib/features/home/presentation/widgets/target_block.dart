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
    final remaining = total - current;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgressRing(current: current, total: total, size: 100),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Цель на год".toUpperCase(), style: AppTextStyles.label),
                const SizedBox(height: 12),
                Text(
                  "Осталось $remaining книг до конца года",
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("0", style: AppTextStyles.titleColor),
                          Text("дней\nподряд", style: AppTextStyles.label),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("0", style: AppTextStyles.titleColor),
                          Text("цитат\nсохранено", style: AppTextStyles.label),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("0", style: AppTextStyles.titleColor),
                          Text("слов в\nсловаре", style: AppTextStyles.label),
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
