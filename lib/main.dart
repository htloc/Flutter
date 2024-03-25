import 'package:flutter/material.dart';
import 'package:pytorch_lite_example/run_model_by_camera_demo.dart';

import 'ui/dropdown.dart';

Future<void> main() async {
  runApp(const ChooseDemo());
}

class ChooseDemo extends StatefulWidget {
  const ChooseDemo({Key? key}) : super(key: key);

  @override
  State<ChooseDemo> createState() => _ChooseDemoState();
}

class _ChooseDemoState extends State<ChooseDemo> {
  String modelValue = "192x192";
  String cameraValue = "High";
  String sizeValue = "Model S";

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
                ),
                TextButton(
                  onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RunModelByCameraDemo(
                                model: modelValue,
                                cameraQuality: cameraValue,
                                size: sizeValue,
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
