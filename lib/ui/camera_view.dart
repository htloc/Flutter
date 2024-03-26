import 'dart:developer';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:camera/camera.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:pytorch_lite/pytorch_lite.dart';

import 'camera_view_singleton.dart';

class MySign {
  final String id;
  final String name;
  final String description;

  MySign({required this.id, required this.name, required this.description});
}

class MyDetectedObject {
  ResultObjectDetection result;
  MySign? sign;
  MyDetectedObject({
    required this.result,
    required this.sign,
  });
}

Future<List<MySign>> _loadCSVData() async {
  String csvString = await rootBundle.loadString('assets/data/signs.csv');
  return CsvToObjectConverter.convert(csvString);
}

class CsvToObjectConverter {
  static Future<List<MySign>> convert(String csvString) async {
    List<List<dynamic>> csvData =
        const CsvToListConverter().convert(csvString, fieldDelimiter: '\t');

    List<MySign> objects = [];

    for (var i = 1; i < csvData.length; i++) {
      var row = csvData[i];
      if (row.length >= 3) {
        var id = row[0];
        var name = row[1];
        var description = row[2];
        objects.add(MySign(id: id, name: name, description: description));
      }
    }

    return objects;
  }
}

/// [CameraView] sends each frame for inference
class CameraView extends StatefulWidget {
  /// Callback to pass results after inference to [HomeView]
  final Function(List<MyDetectedObject> recognitions, Duration inferenceTime)
      resultsCallback;
  final Function(String classification, Duration inferenceTime)
      resultsCallbackClassification;
  final String model;
  final String cameraQuality;
  final String size;
  final double score;

  /// Constructor
  const CameraView(this.resultsCallback, this.resultsCallbackClassification,
      {Key? key,
      required this.model,
      required this.cameraQuality,
      required this.size,
      required this.score})
      : super(key: key);
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  CameraController? cameraController;
  bool predicting = false;
  bool predictingObjectDetection = false;
  ModelObjectDetection? _objectModel;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  List<MySign> _data = [];
  List<AssetsAudioPlayer> assetsAudioPlayer = [];

  bool classification = false;
  int _camFrameRotation = 0;
  String errorMessage = "";
  @override
  void initState() {
    super.initState();
    initStateAsync();
    _loadCSV();
  }

  // This function is triggered when the floating button is pressed
  void _loadCSV() async {
    List<MySign> listData = await _loadCSVData();
    setState(() {
      _data = listData;
    });
  }

  MyDetectedObject mapResult(ResultObjectDetection objectDetection) {
    String className = objectDetection.className ?? "";
    className = className.substring(0, className.length - 1);

    MySign? sign = _data.firstWhereOrNull((e) => e.id == className);
    if (sign == null) {
      print("Sign not found.");
    }

    MyDetectedObject result =
        MyDetectedObject(result: objectDetection, sign: sign);
    return result;
  }

  //load your model
  Future loadModel() async {
    String pathObjectDetectionModel = "";
    int imageSize = 0;
    switch (widget.size) {
      case "Model S":
        pathObjectDetectionModel = "assets/models/yolov8s/";
        break;
      case "Model N":
        pathObjectDetectionModel = "assets/models/yolov8n/";
        break;
      case "Model M":
        pathObjectDetectionModel = "assets/models/yolov8m/";
        break;
    }

    switch (widget.model) {
      case "192x192":
        pathObjectDetectionModel += "yolov8_192x192.torchscript";
        imageSize = 192;
        break;
      case "320x320":
        pathObjectDetectionModel += "yolov8_320x320.torchscript";
        imageSize = 320;
        break;
      case "640x640":
        pathObjectDetectionModel += "yolov8_640x640.torchscript";
        imageSize = 640;
        break;
    }

    try {
      _objectModel = await PytorchLite.loadObjectDetectionModel(
          pathObjectDetectionModel, 35, imageSize, imageSize,
          labelPath: "assets/labels/labels.txt",
          objectDetectionModelType: ObjectDetectionModelType.yolov8);
    } catch (e) {
      if (e is PlatformException) {
        print("only supported for android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }

  void initStateAsync() async {
    WidgetsBinding.instance.addObserver(this);
    await loadModel();
    // Camera initialization
    try {
      initializeCamera();
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          errorMessage = ('You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          errorMessage = ('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          errorMessage = ('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          errorMessage = ('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          errorMessage = ('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          errorMessage = ('Audio access is restricted.');
          break;
        default:
          errorMessage = (e.toString());
          break;
      }
      setState(() {});
    }

    setState(() {
      predicting = false;
    });
  }

  /// Initializes the camera by setting [cameraController]
  void initializeCamera() async {
    cameras = await availableCameras();
    ResolutionPreset quality = ResolutionPreset.medium;
    var idx =
        cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    if (idx < 0) {
      log("No Back camera found - weird");
      return;
    }

    var desc = cameras[idx];
    _camFrameRotation = Platform.isAndroid ? desc.sensorOrientation : 0;

    switch (widget.cameraQuality) {
      case "High":
        quality = ResolutionPreset.high;
        break;
      case "Medium":
        quality = ResolutionPreset.medium;
        break;
      case "Low":
        quality = ResolutionPreset.low;
        break;
    }

    cameraController = CameraController(desc, quality,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
        enableAudio: false);

    await cameraController?.initialize().then((_) async {
      await cameraController?.startImageStream(onLatestImageAvailable);

      cameraController?.getMinZoomLevel().then((value) {
        _currentZoomLevel = value;
        _minAvailableZoom = value;
      });
      cameraController?.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });
      _currentExposureOffset = 0.0;
      cameraController?.getMinExposureOffset().then((value) {
        _minAvailableExposureOffset = value;
      });
      cameraController?.getMaxExposureOffset().then((value) {
        _maxAvailableExposureOffset = value;
      });

      Size? previewSize = cameraController?.value.previewSize;
      CameraViewSingleton.inputImageSize = previewSize!;

      Size screenSize = MediaQuery.of(context).size;
      CameraViewSingleton.screenSize = screenSize;
      CameraViewSingleton.ratio = cameraController!.value.aspectRatio;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container();
    }
    return Scaffold(body: _liveFeedBody());
  }

  runClassification(CameraImage cameraImage) async {
    if (predicting) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      predicting = true;
    });

    setState(() {
      predicting = false;
    });
  }

  Future<void> runObjectDetection(CameraImage cameraImage) async {
    if (predictingObjectDetection) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      predictingObjectDetection = true;
    });
    if (_objectModel != null) {
      // Start the stopwatch
      Stopwatch stopwatch = Stopwatch()..start();
      List<ResultObjectDetection> objDetect =
          await _objectModel!.getCameraImagePrediction(
        cameraImage,
        _camFrameRotation,
        minimumScore: widget.score,
        iOUThreshold: 0.8,
      );
      // Stop the stopwatch
      stopwatch.stop();

      List<MyDetectedObject> newObj =
          objDetect.map((e) => mapResult(e)).toList();

      widget.resultsCallback(newObj, stopwatch.elapsed);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      predictingObjectDetection = false;
    });
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  onLatestImageAvailable(CameraImage cameraImage) async {
    if (!mounted) {
      return;
    }
    runObjectDetection(cameraImage);
    if (!mounted) {
      return;
    }
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   if (!mounted) {
  //     return;
  //   }
  //   switch (state) {
  //     case AppLifecycleState.paused:
  //       cameraController?.stopImageStream();
  //       break;
  //     case AppLifecycleState.resumed:
  //       if (!cameraController!.value.isStreamingImages) {
  //         await cameraController?.startImageStream(onLatestImageAvailable);
  //       }
  //       break;
  //     default:
  //   }
  // }

  Widget _liveFeedBody() {
    if (cameras.isEmpty) return Container();
    if (cameraController == null) return Container();
    if (cameraController?.value.isInitialized == false) return Container();

    return CameraPreview(
      cameraController!,
      child: Stack(
        children: <Widget>[
          _zoomControl(),
          _exposureControl(),
        ],
      ),
    );
  }

  Widget _exposureControl() => Positioned(
        top: 40,
        right: 8,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 250,
          ),
          child: Column(children: [
            Container(
              width: 55,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '${_currentExposureOffset.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SizedBox(
                  height: 30,
                  child: Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (value) async {
                      setState(() {
                        _currentExposureOffset = value;
                      });
                      await cameraController?.setExposureOffset(value);
                    },
                  ),
                ),
              ),
            )
          ]),
        ),
      );

  Widget _zoomControl() => Positioned(
        bottom: 16,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Slider(
                    value: _currentZoomLevel,
                    min: _minAvailableZoom,
                    max: _maxAvailableZoom,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (value) async {
                      setState(() {
                        _currentZoomLevel = value;
                      });
                      await cameraController?.setZoomLevel(value);
                    },
                  ),
                ),
                Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        '${_currentZoomLevel.toStringAsFixed(1)}x',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    super.dispose();
  }
}
