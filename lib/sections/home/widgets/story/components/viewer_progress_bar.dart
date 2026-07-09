import 'package:flutter/material.dart';

class ViewerProgressBar extends StatelessWidget {
  final int mediaUrlsLength;
  final int currentStoryIndex;
  final AnimationController animationController;

  const ViewerProgressBar({
    super.key,
    required this.mediaUrlsLength,
    required this.currentStoryIndex,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        mediaUrlsLength,
        (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Stack(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  index < currentStoryIndex
                      ? Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      : index == currentStoryIndex
                          ? AnimatedBuilder(
                              animation: animationController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: animationController.value,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
