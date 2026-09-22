import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays the number-notation demonstration without on-screen controls.
class NumberNotationVideoScreen extends StatefulWidget {
  const NumberNotationVideoScreen({super.key});

  @override
  State<NumberNotationVideoScreen> createState() {
    return NumberNotationVideoScreenState();
  }
}

class NumberNotationVideoScreenState extends State<NumberNotationVideoScreen> {
  final VideoPlayerController videoController = VideoPlayerController.asset(
    'assets/number_notation_video.mp4',
  );

  bool videoIsReady = false;
  bool videoFailedToLoad = false;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (videoFailedToLoad) {
      content = const Center(
        child: Text(
          'The number notation video could not be opened.',
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (!videoIsReady) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fill,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: videoController.value.size.width,
            height: videoController.value.size.height,
            child: VideoPlayer(videoController),
          ),
        ),
      );
    }

    return Scaffold(backgroundColor: Colors.black, body: content);
  }

  Future<void> initializeVideo() async {
    try {
      await videoController.initialize();
      await videoController.setLooping(true);
      await videoController.play();

      if (mounted) {
        setState(() {
          videoIsReady = true;
        });
      }
    } catch (error) {
      debugPrint('Number notation video failed to load: $error');

      if (mounted) {
        setState(() {
          videoFailedToLoad = true;
        });
      }
    }
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }
}
