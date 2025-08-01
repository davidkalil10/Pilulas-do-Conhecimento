import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';

class TutorialCard extends StatelessWidget {
  final TutorialVideo video;
  final VoidCallback onTap;
  const TutorialCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.play_circle_fill, size: 40, color: Colors.blue[400]),
              SizedBox(height: 10),
              Text(
                video.titulo,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              Text(
                video.subtitulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              Spacer(),
              Wrap(
                spacing: 5,
                children: video.tags.map((t) =>
                    Chip(
                      label: Text(t, style: TextStyle(fontSize: 11)),
                      backgroundColor: Colors.blue[50],
                    )
                ).toList(),
              ),
              SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  "Atualizado: ${video.dataAtualizacao}",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}