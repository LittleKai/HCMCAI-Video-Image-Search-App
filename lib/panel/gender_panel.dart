import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenderPanel extends StatelessWidget {
  final List<bool> genderSelection;
  final Function(int, bool) onGenderSelectionChanged;

  const GenderPanel({super.key, 
    required this.genderSelection,
    required this.onGenderSelectionChanged,
  });

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
          const Text('Gender:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Female'),
                  value: genderSelection[0],
                  onChanged: (value) => onGenderSelectionChanged(0, value!),
                ),
              ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Number'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Male'),
                  value: genderSelection[1],
                  onChanged: (value) => onGenderSelectionChanged(1, value!),
                ),
              ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Number'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Both'),
                  value: genderSelection[2],
                  onChanged: (value) => onGenderSelectionChanged(2, value!),
                ),
              ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Number'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}