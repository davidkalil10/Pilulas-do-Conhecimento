import 'package:flutter/material.dart';

class TutorialVideo {
  // Agora os campos de texto são Mapas
  final Map<String, dynamic> titulo;
  final Map<String, dynamic> subtitulo;
  final Map<String, dynamic> tags;
  final Map<String, dynamic> url;

  final String thumbnail;
  final String dataAtualizacao;

  TutorialVideo({
    required this.titulo,
    required this.subtitulo,
    required this.tags,
    required this.url,
    required this.thumbnail,
    required this.dataAtualizacao,
  });

  factory TutorialVideo.fromJson(Map<String, dynamic> json) {
    return TutorialVideo(
      titulo: json['Titulo'] as Map<String, dynamic>,
      subtitulo: json['Subtitulo'] as Map<String, dynamic>,
      tags: json['Tags'] as Map<String, dynamic>,
      url: json['URL'] as Map<String, dynamic>,
      thumbnail: json['thumbnail'] ?? "",
      dataAtualizacao: json['data_atualizacao'] ?? "",
    );
  }

  // Método helper para pegar o texto no idioma correto
  String getTitulo(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return titulo[languageCode] ?? titulo['pt'] ?? 'Título indisponível'; // Fallback para português
  }

  String getSubtitulo(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return subtitulo[languageCode] ?? subtitulo['pt'] ?? '';
  }

  List<String> getTags(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final tagList = tags[languageCode] ?? tags['pt'] ?? [];
    return List<String>.from(tagList);
  }

  String getUrl(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return url[languageCode] ?? url['pt'] ?? '';
  }
}