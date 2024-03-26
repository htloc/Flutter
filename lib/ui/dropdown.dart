import 'package:flutter/material.dart';

const List<String> modelSelections = <String>['192x192', '320x320', '640x640'];
typedef setStringCallback = void Function(String val);
typedef setDoubleCallback = void Function(double val);

const List<String> cameraSelections = <String>['High', 'Medium', 'Low'];
const List<String> modelSizeSelections = <String>[
  'Model S',
  'Model N',
  'Model M'
];

const List<double> scoreSelections = <double>[0.6, 0.7, 0.8, 0.9, 1];

class MyDropdownMenu extends StatefulWidget {
  final setStringCallback setModelcallback;
  final setStringCallback setCameraCallback;
  final setStringCallback setSizeCallback;
  final setDoubleCallback setScoreCallback;

  const MyDropdownMenu(
      {Key? key,
      required this.setModelcallback,
      required this.setCameraCallback,
      required this.setSizeCallback,
      required this.setScoreCallback})
      : super(key: key);

  @override
  State<MyDropdownMenu> createState() => _MyDropdownMenuState();
}

class _MyDropdownMenuState extends State<MyDropdownMenu> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text("Select size:"),
      DropdownMenu<String>(
        initialSelection: modelSizeSelections.first,
        onSelected: (String? value) {
          setState(() {
            widget.setSizeCallback(value!);
          });
        },
        dropdownMenuEntries:
            modelSizeSelections.map<DropdownMenuEntry<String>>((String value) {
          return DropdownMenuEntry<String>(value: value, label: value);
        }).toList(),
      ),
      const Text("Select model:"),
      DropdownMenu<String>(
        initialSelection: modelSelections.first,
        onSelected: (String? value) {
          setState(() {
            widget.setModelcallback(value!);
          });
        },
        dropdownMenuEntries:
            modelSelections.map<DropdownMenuEntry<String>>((String value) {
          return DropdownMenuEntry<String>(value: value, label: value);
        }).toList(),
      ),
      const Text("Select camera quality:"),
      DropdownMenu<String>(
        initialSelection: cameraSelections.first,
        onSelected: (String? value) {
          setState(() {
            widget.setCameraCallback(value!);
          });
        },
        dropdownMenuEntries:
            cameraSelections.map<DropdownMenuEntry<String>>((String value) {
          return DropdownMenuEntry<String>(value: value, label: value);
        }).toList(),
      ),
      const Text("Select minimun score:"),
      DropdownMenu<double>(
        initialSelection: scoreSelections.first,
        onSelected: ((value) => {
              setState(() {
                widget.setScoreCallback(value!);
              })
            }),
        dropdownMenuEntries:
            scoreSelections.map<DropdownMenuEntry<double>>((double value) {
          return DropdownMenuEntry<double>(
              value: value, label: value.toString());
        }).toList(),
      ),
    ]);
  }
}
