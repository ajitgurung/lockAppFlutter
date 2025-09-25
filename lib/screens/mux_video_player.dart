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

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final url =
        'https://stream.mux.com/${widget.playbackId}.m3u8?token=${widget.token}';
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));

    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Chewie(controller: _chewieController!);
  }
}
