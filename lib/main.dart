import 'package:flutter/material.dart';
import 'package:traffic_sign_recognition/camera_handler.dart';

import 'ui/dropdown.dart';

Future<void> main() async {
  runApp(const TrafficSignAlert());
}

class TrafficSignAlert extends StatefulWidget {
  const TrafficSignAlert({Key? key}) : super(key: key);

  @override
  State<TrafficSignAlert> createState() => _TrafficSignAlertState();
}

class _TrafficSignAlertState extends State<TrafficSignAlert> {
  String modelValue = "192x192";
  String cameraValue = "High";
  String sizeValue = "Model S";
  double score = 0.8;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Traffic Sign Recognition'),
          centerTitle: true,
        ),
        body: Builder(builder: (context) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyDropdownMenu(
                  setCameraCallback: (val) => setState(() {
                    cameraValue = val;
                  }),
                  setModelcallback: (val) => setState(() {
                    modelValue = val;
                  }),
                  setSizeCallback: (val) => setState(() {
                    sizeValue = val;
                  }),
                  setScoreCallback: (val) => setState(() {
                    score = val;
                  }),
                ),
                TextButton(
                  onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CameraHandler(
                                model: modelValue,
                                cameraQuality: cameraValue,
                                size: sizeValue,
                                score: score,
                              )),
                    )
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    "Start Camera",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}
