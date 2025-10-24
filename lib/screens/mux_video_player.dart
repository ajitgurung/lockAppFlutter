import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MuxVideoPlayer extends StatefulWidget {
  final String playbackId;
  final String token;

  const MuxVideoPlayer({
    Key? key,
    required this.playbackId,
    required this.token,
  }) : super(key: key);

  @override
  _MuxVideoPlayerState createState() => _MuxVideoPlayerState();
}

class _MuxVideoPlayerState extends State<MuxVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final url = 'https://stream.mux.com/${widget.playbackId}.m3u8?token=${widget.token}';
      
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).scaffoldBackgroundColor,
          handleColor: Theme.of(context).scaffoldBackgroundColor,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade200,
        ),
        placeholder: Container(
          color: Colors.grey.shade900,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        autoInitialize: true,
        showControls: true,
        customControls: const CupertinoControls(
          backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
          iconColor: Colors.white,
        ),
      );

      setState(() {
        isLoading = false;
        hasError = false;
      });

    } catch (e) {
      print("Video initialization error: $e");
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load video. Please try again.';
      });
    }
  }

  Future<void> _retryLoading() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    // Dispose old controllers
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;

    // Reinitialize
    await _initializePlayer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off_rounded,
                size: 64,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'Video Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh_rounded),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _retryLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).scaffoldBackgroundColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double videoHeight;

        if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
          final aspectRatio = _videoPlayerController!.value.aspectRatio;
          videoHeight = maxWidth / aspectRatio;
        } else {
          videoHeight = maxWidth * 9 / 16; // Default 16:9 aspect ratio
        }

        // Ensure video height doesn't exceed a reasonable maximum
        videoHeight = videoHeight.clamp(200, 600);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: maxWidth,
              height: videoHeight,
              color: Colors.black,
              child: isLoading
                  ? _buildLoadingState()
                  : hasError
                      ? _buildErrorState()
                      : _chewieController != null &&
                              _chewieController!.videoPlayerController.value.isInitialized
                          ? Chewie(controller: _chewieController!)
                          : _buildErrorState(),
            ),
          ),
        );
      },
    );
  }
}