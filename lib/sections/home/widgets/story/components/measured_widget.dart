import 'package:flutter/material.dart';

class MeasuredWidget extends StatefulWidget {
  final Widget child;
  final Function(Size) onSizeChanged;

  const MeasuredWidget({
    super.key,
    required this.child,
    required this.onSizeChanged,
  });

  @override
  State<MeasuredWidget> createState() => _MeasuredWidgetState();
}

class _MeasuredWidgetState extends State<MeasuredWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
  }

  @override
  void didUpdateWidget(covariant MeasuredWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
  }

  void _measureSize() {
    if (!mounted) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      widget.onSizeChanged(renderBox.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
