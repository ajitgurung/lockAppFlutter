import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MuxVideoPlayer extends StatefulWidget {
  final String playbackId;
  final String token;

  MuxVideoPlayer({required this.playbackId, required this.token});

  @override
  _MuxVideoPlayerState createState() => _MuxVideoPlayerState();
}

class _MuxVideoPlayerState extends State<MuxVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final url = 'https://stream.mux.com/${widget.playbackId}.m3u8?token=${widget.token}';
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );
      setState(() => isLoading = false);
    } catch (e) {
      print("Video initialization error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (isLoading || _chewieController == null) {
        return Center(child: CircularProgressIndicator());
      }

      // Make video responsive to available width
      final maxWidth = constraints.maxWidth;
      final videoHeight = maxWidth / (_videoPlayerController!.value.aspectRatio);

      return Center(
        child: Container(
          width: maxWidth,
          height: videoHeight,
          child: Chewie(controller: _chewieController!),
        ),
      );
    });
  }
}
