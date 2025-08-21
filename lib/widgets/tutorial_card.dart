import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';

class TutorialCardPremium extends StatelessWidget {
  final TutorialVideo video;
  final Color renaultGold;
  final VoidCallback onPlay;
  final bool dark;
  const TutorialCardPremium({
    required this.video,
    required this.renaultGold,
    required this.onPlay,
    this.dark = false,
    Key? key,
  }) : super(key: key);

  // Helper para pegar categoria no idioma
  String getCategoria(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return video.categoria[languageCode] ?? video.categoria['pt'] ?? 'Categoria';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final bgCard = dark ? Colors.grey[900] : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final textColor = dark ? Colors.white70 : Colors.grey[900];

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      color: bgCard,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bgCard,
          border: Border.all(
            color: bgCard!.withOpacity(dark ? 0.6 : 0.4),
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
                  child: video.thumbnail.isNotEmpty
                      ? Image.network(
                    video.thumbnail,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey[800],
                    ),
                  )
                      : Container(
                    width: double.infinity,
                    height: 120,
                    color: Colors.grey[800],
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: InkWell(
                      onTap: onPlay,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.all(13),
                        child: Icon(
                          Icons.play_arrow,
                          size: 42,
                          color: renaultGold,
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
                    video.getTitulo(context),
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    video.getSubtitulo(context),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  // categoria como label multilíngue
                  Container(
                    decoration: BoxDecoration(
                      color: dark ? Colors.black: renaultGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    child: Text(
                      getCategoria(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: dark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${AppLocalizations.of(context)!.updatedOn}: ${video.dataAtualizacao}",
                    style: TextStyle(
                      fontSize: 10,
                      color: dark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
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