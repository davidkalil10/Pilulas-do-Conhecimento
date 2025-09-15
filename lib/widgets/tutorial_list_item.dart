import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart';

class TutorialListItem extends StatelessWidget {
  final TutorialVideo video;
  final Color renaultGold;
  final VoidCallback onPlay;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final bool isDownloading;
  final double downloadProgress;
  final bool dark;

  const TutorialListItem({
    Key? key,
    required this.video,
    required this.renaultGold,
    required this.onPlay,
    required this.isFavorite,
    required this.onFavorite,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.dark = true,
  }) : super(key: key);

  String getCategoria(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return video.categoria[languageCode] ?? video.categoria['pt'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bg = dark ? Colors.grey[900] : Colors.white;
    final textColor = dark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Favoritar / salvar botão (coluna à esquerda)
          Container(
            width: 96,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.white : Colors.white, size: 28),
                ),
                if (isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: 48,
                      child: LinearProgressIndicator(
                        value: downloadProgress,
                        color: renaultGold,
                        backgroundColor: Colors.black26,
                        minHeight: 6,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Thumbnail + play overlay
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 260,
              height: 130,
              color: Colors.black,
              child: Stack(
                children: [
                  // thumbnail
                  Positioned.fill(
                    child: video.thumbnail.isNotEmpty
                        ? Image.network(video.thumbnail, fit: BoxFit.cover)
                        : Container(color: Colors.grey[800]),
                  ),
                  // play button
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.play_arrow, color: renaultGold, size: 36),
                      ),
                    ),
                  ),
                  // (não mostra duração por requisito)
                ],
              ),
            ),
          ),

          const SizedBox(width: 18),

          // Conteúdo textual (direita)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.getTitulo(context),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.getSubtitulo(context),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: dark ? Colors.black : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(getCategoria(context),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${AppLocalizations.of(context)!.updatedOn}: ${video.dataAtualizacao}",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}