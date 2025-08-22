import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/widgets/clipper.dart';

class CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final double height;
  final double horizontalPadding;
  final VoidCallback onTap;

  const CategoryTab({
    required this.label,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.height,
    required this.horizontalPadding,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: 'RenaultSans',
      fontSize: 14,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? Colors.white : Colors.white70,
      letterSpacing: 0.2,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final double width = tp.width + horizontalPadding * 2;
    final double cut = height * 0.7;

    if (!selected) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: width,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(label, style: textStyle),
          ),
        ),
      );
    }

    // Aba selecionada: desenha shape
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: ClipPath(
        clipper: CategoryTabClipper(
          isFirst: isFirst,
          isLast: isLast,
          cut: cut,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: height,
          width: width,
          color: Colors.grey[800],
          alignment: Alignment.center,
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }
}

class CategoryTabIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final double height;
  final double horizontalPadding;
  final VoidCallback onTap;
  final Color color;

  const CategoryTabIcon({
    required this.icon,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.height,
    required this.horizontalPadding,
    required this.onTap,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cut = height * 0.7;
    if (!selected) {
      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: height + horizontalPadding,
          child: Icon(icon, color: color, size: 24),
        ),
      );
    }
    // Se selecionado, usa clipper igual ao CategoryTab
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: CategoryTabClipper(
            isFirst: isFirst, isLast: isLast, cut: cut),
        child: Container(
          height: height,
          width: height + horizontalPadding,
          color: Colors.grey[800],
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}