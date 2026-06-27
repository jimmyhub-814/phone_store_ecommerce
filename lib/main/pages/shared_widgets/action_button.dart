import 'package:flutter/material.dart'; 
class ActionButton extends StatelessWidget {
  String text;
  Color color;
  Color textColor;
  VoidCallback? onPressed;
  ActionButton(
      {super.key,
      required this.text,
      required this.color,
      required this.textColor,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 120),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: color,
          animationDuration: const Duration(milliseconds: 120),
          overlayColor: textColor.withValues(alpha: 0.1),
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
