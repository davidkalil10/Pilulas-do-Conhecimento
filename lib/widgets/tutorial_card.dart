import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';
class TutorialCardPremium extends StatefulWidget {
  final TutorialVideo video;
  final Color renaultGold;
  final VoidCallback onPlay;

  const TutorialCardPremium({
    required this.video,
    required this.renaultGold,
    required this.onPlay,
    Key? key,
  }) : super(key: key);

  @override
  State<TutorialCardPremium> createState() => _TutorialCardPremiumState();
}

class _TutorialCardPremiumState extends State<TutorialCardPremium> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        // altura fixa só se NÃO estiver expandido!
        height: expanded ? null : 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.grey[900],
          border: Border.all(
            color: widget.renaultGold.withOpacity(0.7),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // faz a altura ser dada pelo conteúdo
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    width: double.infinity,
                    height: 110,
                    color: Colors.grey[800],
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: InkWell(
                      onTap: widget.onPlay,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.all(13),
                        child: Icon(
                          Icons.play_arrow,
                          size: 42,
                          color: widget.renaultGold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // altura só conforme conteúdo!
                children: [
                  Text(
                    widget.video.titulo,
                    style: TextStyle(
                      color: widget.renaultGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  !expanded
                      ? Text(
                    widget.video.subtitulo,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.subtitulo,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        children: widget.video.tags
                            .map((t) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          margin: EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                            color: widget.renaultGold
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.black),
                          ),
                        ))
                            .toList(),
                      ),
                      SizedBox(height: 7),
                    ],
                  ),
                  // SEM Spacer!
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Atualizado: ${widget.video.dataAtualizacao}",
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.renaultGold.withOpacity(0.8),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: widget.renaultGold,
                        ),
                        onPressed: () {
                          setState(() {
                            expanded = !expanded;
                          });
                        },
                        tooltip: expanded
                            ? 'Fechar'
                            : 'Expandir para ver detalhes',
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}