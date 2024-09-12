import 'package:flutter/material.dart';

class FilterPanel extends StatefulWidget {
  final List<String> tags;
  final Function(String) onTagAdded;
  final Function(String) onTagRemoved;
  final Function() onClearTags;
  final Function(String) onApplyAsrFilter;

  const FilterPanel({super.key, 
    required this.tags,
    required this.onTagAdded,
    required this.onTagRemoved,
    required this.onClearTags,
    required this.onApplyAsrFilter,
  });

  @override
  _FilterPanelState createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _ocrController = TextEditingController();
  final TextEditingController _asrController = TextEditingController();

  void _onApplyAsrFilter() {
    widget.onApplyAsrFilter(_asrController.text);
  }

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
          const Text('Filter:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(
              labelText: 'Tag',
              hintText: 'Enter @tag and press Enter',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.startsWith('@') && value.length > 1) {
                widget.onTagAdded(value);
                _tagController.clear();
              }
            },
          ),
          Wrap(
            spacing: 8,
            children: widget.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => widget.onTagRemoved(tag),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ocrController,
            decoration: const InputDecoration(
              labelText: 'OCR',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _asrController,
            decoration: const InputDecoration(
              labelText: 'ASR',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onApplyAsrFilter,
                  child: const Text('Apply'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: ElevatedButton(
                onPressed: () {
                  _ocrController.clear();
                  _asrController.clear();
                },
                child: const Text('Clear Panel'),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: ElevatedButton(
                onPressed: widget.onClearTags,
                child: const Text('Clear Tag'),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
