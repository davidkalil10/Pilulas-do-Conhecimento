import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

class VideoDialog extends StatefulWidget {
  final String url;
  final String title;
  const VideoDialog({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  // Usaremos um Future para o FutureBuilder
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    // 1. Usando o construtor moderno e passando uma Uri
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    // Guardamos o futuro da inicialização para usar no FutureBuilder
    _initializeVideoPlayerFuture = _initializeVideoPlayerFuture = _initializeVideoPlayer().catchError((error) {
      // Se a inicialização falhar, podemos capturar o erro aqui.
      // O FutureBuilder vai lidar com a exibição da mensagem de erro na UI.
      debugPrint("Erro ao inicializar o vídeo: $error");
    });
  }

  Future<void> _initializeVideoPlayer() async {
    await _videoPlayerController.initialize();
    // Cria o ChewieController após a inicialização bem-sucedida
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: false,
      allowedScreenSleep: false,
      // Adicionando um toque de cor da marca
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFF6C700), // Renault Gold
        handleColor: const Color(0xFFF6C700),
        bufferedColor: Colors.grey.shade600,
        backgroundColor: Colors.grey.shade800,
      ),
      placeholder: Container(
        color: Colors.black,
      ),
    );
  }


  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usando AlertDialog para um visual mais limpo e com mais controle
    return AlertDialog(
      title: Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold)),
      // Remove o padding padrão para que o vídeo ocupe todo o espaço
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      // Ajusta o tamanho máximo para telas grandes, mas permite ser menor
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            // 2. Usando o FutureBuilder para lidar com todos os estados
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError || _chewieController == null) {
                // Se a inicialização falhou
                return const Center(
                  child: Text(
                    "Erro ao carregar o vídeo.",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              // Se a inicialização foi bem-sucedida
              return AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              );
            }
            // Enquanto o vídeo está carregando
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF6C700)),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.closeButton), // <-- CORRIGIDO,
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}