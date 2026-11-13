import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class StatisticsBlock extends StatelessWidget {
  const StatisticsBlock({
    super.key,
    this.value = '5 ч 13 мин',
    this.label = 'прочитано за неделю',
    this.icon = Icons.schedule_rounded,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.label, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
