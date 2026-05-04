import 'package:flutter/material.dart';

class PriceStack extends StatelessWidget {
  const PriceStack({
    super.key,
    required this.payablePrice,
    this.originalPrice,
    this.compact = false,
    this.textAlign = TextAlign.right,
  });

  final String payablePrice;
  final String? originalPrice;
  final bool compact;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final payableStyle = TextStyle(
      fontSize: compact ? 14 : 20,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A),
      height: 1.0,
    );

    final originalStyle = TextStyle(
      fontSize: compact ? 10 : 11,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF94A3B8),
      decoration: TextDecoration.lineThrough,
      decorationColor: const Color(0xFF94A3B8),
      height: 1.0,
    );

    if (originalPrice == null || originalPrice!.trim().isEmpty) {
      return Text(
        payablePrice,
        textAlign: textAlign,
        style: payableStyle,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          payablePrice,
          textAlign: textAlign,
          style: payableStyle,
        ),
        const SizedBox(height: 2),
        Text(
          originalPrice!,
          textAlign: textAlign,
          style: originalStyle,
        ),
      ],
    );
  }
}
