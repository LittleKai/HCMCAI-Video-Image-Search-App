import 'package:flutter/material.dart';

class SearchPanel extends StatefulWidget {
  final List<bool> searchTypeSelection;
  final Function(int, bool) onSearchTypeSelectionChanged;
  final Function(List<String>, bool, bool) onSearch;

  const SearchPanel({super.key,
    required this.searchTypeSelection,
    required this.onSearchTypeSelectionChanged,
    required this.onSearch,
  });

  @override
  _SearchPanelState createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final TextEditingController _textQueryController = TextEditingController();
  bool useClip = true;
  bool useClipv2 = false;

  void _handleSearch() {
    List<String> queries = _textQueryController.text.split('@').where((q) => q.trim().isNotEmpty).toList();
    widget.onSearch(queries, useClip, useClipv2);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 8,
            child: TextField(
              controller: _textQueryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Text Query',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSearch,
                        child: const Text('SEARCH'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _textQueryController.clear();
                          });
                        },
                        child: const Text('CLEAR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('CLIP'),
                        value: useClip,
                        onChanged: (value) {
                          setState(() {
                            useClip = value!;
                            if (useClip) useClipv2 = false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('CLIPv2'),
                        value: useClipv2,
                        onChanged: (value) {
                          setState(() {
                            useClipv2 = value!;
                            if (useClipv2) useClip = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, int index) {
    return Row(
      children: [
        Checkbox(
          value: widget.searchTypeSelection[index],
          onChanged: (value) => widget.onSearchTypeSelectionChanged(index, value!),
        ),
        Text(label),
      ],
    );
  }
}