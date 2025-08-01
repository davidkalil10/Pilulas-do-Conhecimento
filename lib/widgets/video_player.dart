import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoDialog extends StatefulWidget {
  final String url;
  final String title;
  const VideoDialog({required this.url, required this.title});

  @override
  State<VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
  late VideoPlayerController _controller;
  ChewieController? _chewie;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {
          _chewie = ChewieController(
            videoPlayerController: _controller,
            aspectRatio: _controller.value.aspectRatio,
            autoPlay: true,
            looping: false,
            allowedScreenSleep: false,
          );
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800, height: 450,
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _chewie != null
                ? Chewie(controller: _chewie!)
                : CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}