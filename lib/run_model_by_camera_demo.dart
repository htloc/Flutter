import 'package:flutter/material.dart';
import 'package:pytorch_lite_example/ui/box_widget.dart';
import 'dart:async';
import 'ui/camera_view.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

/// [RunModelByCameraDemo] stacks [CameraView] and [BoxWidget]s with bottom sheet for
class RunModelByCameraDemo extends StatefulWidget {
  final bool isBestModel;

  const RunModelByCameraDemo({Key? key, required this.isBestModel})
      : super(key: key);
  @override
  _RunModelByCameraDemoState createState() => _RunModelByCameraDemoState();
}

class _RunModelByCameraDemoState extends State<RunModelByCameraDemo> {
  List<MyDetectedObject>? results;
  Duration? objectDetectionInferenceTime;
  late List<AudioAuto> autoAudio = [];
  String? classification;
  Duration? classificationInferenceTime;
  final assetsAudioPlayer = AssetsAudioPlayer();

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      checkAndRemove();
      autoAudioHandler();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // Camera View
          CameraView(
            resultsCallback,
            resultsCallbackClassification,
            isBestModel: widget.isBestModel,
          ),

          // Bounding boxes
          boundingBoxes2(results),
        ],
      ),
    );
  }

  /// Returns Stack of bounding boxes
  Widget boundingBoxes2(List<MyDetectedObject>? results) {
    if (results == null) {
      return Container();
    }

    checkAndAdd(results);
    return Stack(
      children: results.map((e) => BoxWidget(result: e)).toList(),
    );
  }

  void checkAndRemove() {
    autoAudio.removeWhere((item) =>
        (DateTime.now().difference(item.time).inSeconds >= 10) && item.isPlay);
  }

  void checkAndAdd(List<MyDetectedObject>? results) {
    results?.forEach((element) {
      if (element.sign != null &&
          !autoAudio.any((a) => a.name == element.sign?.id)) {
        autoAudio.add(AudioAuto(
            name: element.sign!.id, time: DateTime.now(), isPlay: false));
      }
    });
  }

  void autoAudioHandler() {
    if (!assetsAudioPlayer.isPlaying.value) {
      List<Audio> audios = autoAudio
          .where((element) => !element.isPlay)
          .map((e) => Audio("assets/records/records_signs_auto/${e.name}.mp3"))
          .toList();

      setState(() {
        autoAudio.forEach((element) {
          if (!element.isPlay) {
            element.isPlay = true;
          }
        });
      });

      assetsAudioPlayer.open(Playlist(audios: audios),
          loopMode: LoopMode.none //loop the full playlist
          );
    }
  }

  void resultsCallback(List<MyDetectedObject> results, Duration inferenceTime) {
    if (!mounted) {
      return;
    }
    setState(() {
      this.results = results;
      objectDetectionInferenceTime = inferenceTime;
    });
  }

  void resultsCallbackClassification(
      String classification, Duration inferenceTime) {
    if (!mounted) {
      return;
    }
    setState(() {
      this.classification = classification;
      classificationInferenceTime = inferenceTime;
    });
  }
}

/// Row for one Stats field
class StatsRow extends StatelessWidget {
  final String title;
  final String value;

  const StatsRow(this.title, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value)
        ],
      ),
    );
  }
}
