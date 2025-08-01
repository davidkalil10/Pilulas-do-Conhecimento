class TutorialVideo {
  final String titulo;
  final String subtitulo;
  final List<String> tags;
  final String url;
  final String dataAtualizacao;
  final String thumbnail; // Novo campo

  TutorialVideo({
    required this.titulo,
    required this.subtitulo,
    required this.tags,
    required this.url,
    required this.dataAtualizacao,
    required this.thumbnail, // Novo campo
  });

  factory TutorialVideo.fromJson(Map<String, dynamic> json) {
    return TutorialVideo(
      titulo: json["Titulo"] ?? "",
      subtitulo: json["Subtitulo"] ?? "",
      tags: (json["Tags"] as List).map((e) => e.toString()).toList(),
      url: json["URL"] ?? "",
      dataAtualizacao: json["data_atualizacao"] ?? "",
      thumbnail: json["thumbnail"] ?? "", // Novo campo
    );
  }
}