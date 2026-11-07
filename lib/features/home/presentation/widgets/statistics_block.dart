import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class StatisticsBlock extends StatelessWidget {
  const StatisticsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_stories_rounded, color: AppColors.white),
          const SizedBox(height: 22),
          const Text(
            '5 ч 13 мин',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'прочитано за неделю',
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}
