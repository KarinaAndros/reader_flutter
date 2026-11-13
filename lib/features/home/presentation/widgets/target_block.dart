import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/home/presentation/widgets/progress_ring.dart';

class TargetBlock extends StatelessWidget {
  final int total;
  final int current;

  const TargetBlock({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Цель на год',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.label,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$current из $total книг',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'В своём ритме, каждый день',
                  style: TextStyle(fontSize: 12, color: AppColors.label),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ProgressRing(current: current, total: total, size: 76),
        ],
      ),
    );
  }
}
