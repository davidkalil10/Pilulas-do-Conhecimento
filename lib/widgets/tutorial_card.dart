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
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: isDesktop ? null : (expanded ? 300 : 230),
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
          mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  child: widget.video.thumbnail.isNotEmpty
                      ? Image.network(
                    widget.video.thumbnail,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color: Colors.grey[800],
                    ),
                  )
                      : Container(
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
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
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
                  isDesktop
                  // MODO DESKTOP: subtítulo e tags completos
                      ? Column(
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
                            color: widget.renaultGold.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(fontSize: 10, color: Colors.black),
                          ),
                        ))
                            .toList(),
                      ),
                      SizedBox(height: 7),
                    ],
                  )
                  // MOBILE/TABLET: modo compact/expand
                      : !expanded
                      ? Text(
                    widget.video.subtitulo,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                      : SizedBox(
                    height: 65,
                    child: SingleChildScrollView(
                      child: Column(
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
                                style: TextStyle(fontSize: 10, color: Colors.black),
                              ),
                            ))
                                .toList(),
                          ),
                          SizedBox(height: 7),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 7),
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
                      if (!isDesktop)
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
                        ),
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