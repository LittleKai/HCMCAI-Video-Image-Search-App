import 'package:flutter/material.dart';

class ColorPickerPanel extends StatefulWidget {
  final Function(String, String) onColorSelected;

  const ColorPickerPanel({super.key, required this.onColorSelected});

  @override
  _ColorPickerPanelState createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  final Map<String, String> colorMap = {
    '#FF0000': 'Red',
    '#FFA500': 'Orange',
    '#FFFF00': 'Yellow',
    '#008000': 'Green',
    '#0000FF': 'Blue',
    '#4B0082': 'Indigo',
    '#800080': 'Purple',
    '#FFC0CB': 'Pink',
    '#A52A2A': 'Brown',
    '#808080': 'Gray',
    '#000000': 'Black',
    '#FFFFFF': 'White',
    '#008080': 'Teal',
    '#000080': 'Navy',
    '#40E0D0': 'Turquoise',
    '#800000': 'Maroon',
    '#808000': 'Olive',
    '#FFD700': 'Gold',
    '#C0C0C0': 'Silver',
    '#E6E6FA': 'Lavender',
    '#FF00FF': 'Magenta',
    '#FF7F50': 'Coral',
    '#F0E68C': 'Khaki',
    '#00FFFF': 'Aqua',
    '#EE82EE': 'Violet',
    '#DC143C': 'Crimson',
    '#D2B48C': 'Tan',
    '#DDA0DD': 'Plum'
  };

  String? selectedColorCode;
  String? selectedColorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Color Picker:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colorMap.keys.map((colorCode) => GestureDetector(
              onTap: () {
                setState(() {
                  selectedColorCode = colorCode;
                  selectedColorName = colorMap[colorCode];
                });
                widget.onColorSelected(colorCode, colorMap[colorCode]!);
              },
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: Color(int.parse(colorCode.substring(1, 7), radix: 16) + 0xFF000000),
                  border: Border.all(
                    color: selectedColorCode == colorCode ? Colors.black : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            )).toList(),
          ),
          if (selectedColorCode != null && selectedColorName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Selected color: $selectedColorCode ($selectedColorName)'),
            ),
        ],
      ),
    );
  }
}