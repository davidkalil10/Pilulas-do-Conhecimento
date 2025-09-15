import 'package:pilulasdoconhecimento/models/model_video.dart';

class Categoria {
  final String thumbnail;
  final List<TutorialVideo> videos;

  Categoria({
    required this.thumbnail,
    required this.videos,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      thumbnail: json['categoria_thumbnail'] ?? '',
      videos: (json['videos'] as List)
          .map((e) => TutorialVideo.fromJson(e))
          .toList(),
    );
  }
}