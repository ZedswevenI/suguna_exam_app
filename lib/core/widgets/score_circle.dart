import 'package:flutter/material.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';
import 'package:suguna_exam_app/core/theme/app_colors.dart';

enum CircleState {
  defaultState,
  downloading,
  downloaded,
}

class ScoreCircle extends StatelessWidget {
  final double score;
  final CircleState state;
  final VoidCallback? onTap;

  const ScoreCircle({
    super.key,
    required this.score,
    this.state = CircleState.defaultState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppConstants.circleSize,
        height: AppConstants.circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getCircleColor(),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Color _getCircleColor() {
    if (state == CircleState.downloading) {
      return AppColors.backgroundLight;
    }
    return AppColors.getScoreColor(score);
  }

  Widget _buildContent() {
    switch (state) {
      case CircleState.downloading:
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      case CircleState.downloaded:
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.getScoreColor(score),
              ),
            ),
            const Positioned(
              bottom: 2,
              right: 2,
              child: Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              ),
            ),
          ],
        );
      case CircleState.defaultState:
        return Container();
    }
  }
}
