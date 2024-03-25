import 'package:flutter/material.dart';

/// Flutter code sample for [DropdownMenu].

const List<String> modelSelections = <String>['192x192', '320x320', '640x640'];
typedef SetModelCallback = void Function(String val);
typedef SetCameraCallback = void Function(String val);

const List<String> cameraSelections = <String>['High', 'Medium', 'Low'];
const List<String> modelSizeSelections = <String>[
  'Model S',
  'Model N',
  'Model M'
];

class MyDropdownMenu extends StatefulWidget {
  final SetModelCallback setModelcallback;
  final SetCameraCallback setCameraCallback;
  final SetCameraCallback setSizeCallback;

  const MyDropdownMenu(
      {Key? key,
      required this.setModelcallback,
      required this.setCameraCallback,
      required this.setSizeCallback})
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
    ]);
  }
}
