import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class MuxVideoPlayer extends StatefulWidget {
  final String playbackId;
  final String token;
  final String? mp4DownloadUrl; // REQUIRED for secure offline

  const MuxVideoPlayer({
    super.key,
    required this.playbackId,
    required this.token,
    this.mp4DownloadUrl,
  });

  @override
  State<MuxVideoPlayer> createState() => _MuxVideoPlayerState();
}

class _MuxVideoPlayerState extends State<MuxVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  final _secureStorage = const FlutterSecureStorage();

  bool isLoading = true;
  bool hasError = false;
  bool isDownloading = false;
  bool isDownloaded = false;
  double downloadProgress = 0;

  String? encryptedPath;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${widget.playbackId}.aes';

    if (await File(path).exists()) {
      encryptedPath = path;
      isDownloaded = true;
    }

    await _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (isDownloaded && encryptedPath != null) {
        final tempFile = await _decryptToTempFile();
        _videoPlayerController = VideoPlayerController.file(tempFile);
      } else {
        final url =
            'https://stream.mux.com/${widget.playbackId}.m3u8?token=${widget.token}';
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(url));
      }

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );

      setState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load video.';
      });
    }
  }

  Future<void> _downloadAndEncrypt() async {
    if (widget.mp4DownloadUrl == null) return;

    setState(() {
      isDownloading = true;
      downloadProgress = 0;
    });

    final dir = await getApplicationDocumentsDirectory();
    final rawPath = '${dir.path}/${widget.playbackId}.mp4';
    final encryptedFilePath = '${dir.path}/${widget.playbackId}.aes';

    final dio = Dio();

    await dio.download(
      widget.mp4DownloadUrl!,
      rawPath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            downloadProgress = received / total;
          });
        }
      },
    );

    final fileBytes = await File(rawPath).readAsBytes();

    final key = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    await File(encryptedFilePath).writeAsBytes(encrypted.bytes);

    await _secureStorage.write(
      key: widget.playbackId,
      value: jsonEncode({
        "key": base64Encode(key.bytes),
        "iv": base64Encode(iv.bytes),
      }),
    );

    await File(rawPath).delete();

    setState(() {
      encryptedPath = encryptedFilePath;
      isDownloaded = true;
      isDownloading = false;
    });

    await _initializePlayer();
  }

  Future<File> _decryptToTempFile() async {
    final dir = await getTemporaryDirectory();
    final tempPath = '${dir.path}/${widget.playbackId}_temp.mp4';

    final encryptedBytes = await File(encryptedPath!).readAsBytes();
    final stored = await _secureStorage.read(key: widget.playbackId);
    final decoded = jsonDecode(stored!);

    final key = encrypt.Key(base64Decode(decoded["key"]));
    final iv = encrypt.IV(base64Decode(decoded["iv"]));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final decrypted =
        encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);

    return await File(tempPath).writeAsBytes(decrypted);
  }

  Future<void> _deleteDownload() async {
    if (encryptedPath != null) {
      await File(encryptedPath!).delete();
      await _secureStorage.delete(key: widget.playbackId);
    }

    setState(() {
      isDownloaded = false;
      encryptedPath = null;
    });

    await _initializePlayer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(child: Text(errorMessage));
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
        const SizedBox(height: 16),
        if (!isDownloaded)
          ElevatedButton(
            onPressed: isDownloading ? null : _downloadAndEncrypt,
            child: isDownloading
                ? Text("Downloading ${(downloadProgress * 100).toInt()}%")
                : const Text("Download for Secure Offline"),
          ),
        if (isDownloaded)
          ElevatedButton(
            onPressed: _deleteDownload,
            child: const Text("Delete Download"),
          ),
      ],
    );
  }
}
