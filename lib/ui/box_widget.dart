import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:pytorch_lite_example/ui/camera_view.dart';
import 'package:pytorch_lite_example/ui/camera_view_singleton.dart';

class AudioAuto {
  final String name;
  final DateTime time;
  bool isPlay;
  AudioAuto({required this.name, required this.time, required this.isPlay});
}

/// Individual bounding box
class BoxWidget extends StatelessWidget {
  final MyDetectedObject result;
  final Color? boxesColor;
  final bool showPercentage;
  const BoxWidget(
      {Key? key,
      required this.result,
      this.boxesColor,
      this.showPercentage = true})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Color for bounding box
    //print(MediaQuery.of(context).size);
    Color? usedColor;
    //Size screenSize = CameraViewSingleton.inputImageSize;
    Size screenSize = CameraViewSingleton.actualPreviewSizeH;

    final assetsAudioPlayer = AssetsAudioPlayer();
    //Size screenSize = MediaQuery.of(context).size;
    var sign = result.sign;
    var detectedObject = result.result;
    //print(screenSize);
    double factorX = screenSize.width;
    double factorY = screenSize.height;
    if (boxesColor == null) {
      //change colors for each label
      usedColor = Colors.primaries[((detectedObject.className ??
                      detectedObject.classIndex.toString())
                  .length +
              (detectedObject.className ?? detectedObject.classIndex.toString())
                  .codeUnitAt(0) +
              detectedObject.classIndex) %
          Colors.primaries.length];
    } else {
      usedColor = boxesColor;
    }

    return Positioned(
      left: detectedObject.rect.left * factorX,
      top: detectedObject.rect.top * factorY,
      width: detectedObject.rect.width * factorX,
      height: detectedObject.rect.height * factorY,
      child: GestureDetector(
        onTap: () {
          // Add your onPressed logic here
          var signId = sign?.id;

          try {
            assetsAudioPlayer.open(
              Audio("assets/records/$signId.mp3"),
            );
          } catch (t) {
            //print("Has an error when open audio.");
          }
        },
        child: Container(
          width: detectedObject.rect.width * factorX,
          height: detectedObject.rect.height * factorY,
          decoration: BoxDecoration(
              border: Border.all(color: usedColor!, width: 3),
              borderRadius: const BorderRadius.all(Radius.circular(2))),
          child: Align(
            alignment: Alignment.topLeft,
            child: FittedBox(
              child: Container(
                color: usedColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(sign?.name ?? detectedObject.classIndex.toString()),
                    Text(" ${detectedObject.score.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
