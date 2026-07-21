import 'package:flutter/material.dart';
import 'package:terka/theme/app_tokens.dart';

class UserLocationDot extends StatefulWidget {
  const UserLocationDot({super.key});

  @override
  State<UserLocationDot> createState() => _UserLocationDotState();
}

class _UserLocationDotState extends State<UserLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing outer ring
            Container(
              width: 36 * _controller.value,
              height: 36 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.25 * (1.0 - _controller.value)),
              ),
            ),
            // White border ring with shadow
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                // Core blue dot
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
