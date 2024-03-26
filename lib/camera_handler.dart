import 'package:flutter/material.dart';
import 'package:traffic_sign_recognition/ui/box_widget.dart';
import 'dart:async';
import 'ui/camera_view.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

/// [CameraHandler] stacks [CameraView] and [BoxWidget]s with bottom sheet for
class CameraHandler extends StatefulWidget {
  final String model;
  final String cameraQuality;
  final double score;
  final String size;

  const CameraHandler(
      {Key? key,
      required this.model,
      required this.cameraQuality,
      required this.size,
      required this.score})
      : super(key: key);
  @override
  _CameraHandlerState createState() => _CameraHandlerState();
}

class _CameraHandlerState extends State<CameraHandler> {
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
            cameraQuality: widget.cameraQuality,
            model: widget.model,
            size: widget.size,
            score: widget.score,
          ),

          // Bounding boxes
          boundingBoxes2(results),

          //Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              builder: (_, ScrollController scrollController) => Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0))),
                child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.keyboard_arrow_up,
                            size: 48, color: Colors.orange),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              if (classification != null)
                                StatsRow('Classification:', '$classification'),
                              if (classificationInferenceTime != null)
                                StatsRow('Classification Inference time:',
                                    '${classificationInferenceTime?.inMilliseconds} ms'),
                              if (objectDetectionInferenceTime != null)
                                StatsRow('Object Detection Inference time:',
                                    '${objectDetectionInferenceTime?.inMilliseconds} ms'),
                            ],
                          ),
                        )
                      ],
                    )),
              ),
            ),
          )
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

      assetsAudioPlayer.open(Playlist(audios: audios), loopMode: LoopMode.none);
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
