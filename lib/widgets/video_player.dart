import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoDialog extends StatefulWidget {
  final String url;
  final String title;
  final bool isFile; // <-- agora obrigatório!

  const VideoDialog({
    Key? key,
    required this.url,
    required this.title,
    required this.isFile,
  }) : super(key: key);

  @override
  State<VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    // Decide qual controller usar:
    if (widget.isFile) {
      _videoPlayerController = VideoPlayerController.file(File(widget.url));
    } else {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    }
    _initializeVideoPlayerFuture = _initializeVideoPlayer().catchError((error) {
      debugPrint("Erro ao inicializar o vídeo: $error");
    });
  }

  Future<void> _initializeVideoPlayer() async {
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: false,
      allowedScreenSleep: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFF6C700),
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
    return AlertDialog(
      title: Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError || _chewieController == null) {
                return const Center(
                  child: Text("Erro ao carregar o vídeo.", style: TextStyle(color: Colors.red)),
                );
              }
              return AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF6C700)),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.closeButton),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}