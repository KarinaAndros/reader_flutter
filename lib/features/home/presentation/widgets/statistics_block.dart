import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/theme/app_text_styles.dart';

class StatisticsBlock extends StatelessWidget {
  const StatisticsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.only(left: 24, right: 24),
      padding: EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Минуты чтения за неделю", style: AppTextStyles.titleH2),
                    Text("5ч 13 мин", style: AppTextStyles.titleH2Color),
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
