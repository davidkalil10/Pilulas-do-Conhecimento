import 'package:flutter/material.dart';
class CategoryTabClipper extends CustomClipper<Path> {
  final bool isFirst;
  final bool isLast;
  final double cut; // Largura do corte na base

  CategoryTabClipper({
    required this.isFirst,
    required this.isLast,
    required this.cut,
  });

  @override
  Path getClip(Size size) {
    final double c = cut.clamp(0, size.width / 2);
    final path = Path();

    // 1. Ponto inicial (canto superior esquerdo)
    // Se for o primeiro item, começa reto na borda. Senão, começa com um recuo.
    if (isFirst) {
      path.moveTo(0, 0);
    } else {
      path.moveTo(c, 0);
    }

    // 2. Linha para o canto superior direito
    // A linha superior é sempre reta até a extremidade direita.
    path.lineTo(size.width, 0);

    // 3. Linha para o canto inferior direito
    // Se for o último item, a borda direita é reta. Senão, é inclinada.
    if (isLast) {
      path.lineTo(size.width, size.height);
    } else {
      path.lineTo(size.width - c, size.height);
    }

    // 4. Linha para o canto inferior esquerdo
    // A linha inferior é sempre reta até a extremidade esquerda.
    path.lineTo(0, size.height);

    // 5. Fechar o caminho
    // O fechamento do Path criará a linha do canto inferior esquerdo de volta
    // ao ponto inicial, criando a inclinação esquerda (se não for o primeiro item).
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CategoryTabClipper oldClipper) {
    return oldClipper.isFirst != isFirst ||
        oldClipper.isLast != isLast ||
        oldClipper.cut != cut;
  }
}

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

      fontSize: 14,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? Colors.white : Colors.white70,
      letterSpacing: 0.2,
    );

    // Medir texto para calcular largura mínima da aba
    final tp = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final double width = tp.width + horizontalPadding * 2;
    final double cut = height * 0.55; // ajuste visual do ângulo

    if (!selected) {
      // Aba não selecionada: só texto “plano”
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
        clipper: CategoryTabClipper(isFirst: isFirst, isLast: isLast, cut: cut),
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