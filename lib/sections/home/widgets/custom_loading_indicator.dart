import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double radius;
  const CustomLoadingIndicator({super.key, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(
        radius: radius,
      ),
    );
  }
}
