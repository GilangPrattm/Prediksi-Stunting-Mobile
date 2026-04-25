import 'package:flutter/material.dart';

class ColorfulIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double padding;

  const ColorfulIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24.0,
    this.padding = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }
}
