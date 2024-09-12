import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../panel/filter_panel.dart';
import '../panel/gender_panel.dart';
import '../panel/submission_panel.dart';
import '../panel/search_panel.dart';
import '../panel/image_display_panel.dart';
import '../settings_manager.dart';
import '../panel/color_picker_panel.dart';
import '../service/elasticsearch_service.dart';

class ImageRetrievalPage extends StatefulWidget {
  const ImageRetrievalPage({super.key});

  @override
  _ImageRetrievalPageState createState() => _ImageRetrievalPageState();
}

class _ImageRetrievalPageState extends State<ImageRetrievalPage> {
  List<bool> searchTypeSelection = [true, false, false, false];
  List<bool> genderSelection = [false, false, false];
  List<String> tags = [];
  List<Map<String, dynamic>> selectedImages = [];
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> originalSearchResults = [];
  String baseUrl = 'https://loudly-exciting-sparrow.ngrok-free.app';
  int imageCount = 50;
  int sceneRange = 20;
  String videoPath = '';
  String mapKeyframePath = '';
  String? selectedColorCode;
  String? selectedColorName;

  final ElasticsearchService _elasticsearchService =
      ElasticsearchService(baseUrl: 'http://localhost:9200');

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkElasticsearchConnection();
  }

  void _checkElasticsearchConnection() async {
    bool isConnected =
        await _elasticsearchService.checkElasticsearchConnection();
    print("Elasticsearch is connected: $isConnected");
  }

  Future<void> _loadSettings() async {
    final url = await SettingsManager.getBaseUrl();
    final count = await SettingsManager.getImageCount();
    final path = await SettingsManager.getVideoPath();
    final mapPath = await SettingsManager.getMapKeyframePath();
    final sRange = await SettingsManager.getSceneRange();
    setState(() {
      baseUrl = url;
      imageCount = count;
      videoPath = path;
      mapKeyframePath = mapPath;
      sceneRange = sRange;
    });
  }

  Future<void> _performSearch(
      List<String> queries, bool useClip, bool useClipv2) async {
    final String endpoint;
    final Map<String, dynamic> requestBody;

    if (queries.length == 1) {
      endpoint = '$baseUrl/search';
      requestBody = {
        'query': queries[0],
        'top_k': imageCount,
        'use_clip': useClip,
        'use_clipv2': useClipv2
      };
    } else {
      endpoint = '$baseUrl/multi_search';
      requestBody = {
        'queries': queries,
        'top_k': imageCount,
        'scene_range': sceneRange,
        'use_clip': useClip,
        'use_clipv2': useClipv2
      };
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> results =
          List<Map<String, dynamic>>.from(json.decode(response.body));
      results = results.map((result) {
        List<String> pathParts = result['relative_path'].split('/');
        String videoName = "";
        String imageName = "";

          videoName = pathParts[0];
          imageName = pathParts[1];
          if (!imageName.startsWith('scene_')) {
            imageName = 'scene_$imageName';
          }

        result['relative_path'] = '$videoName/$imageName';
        return result;
      }).toList();
      setState(() {
        searchResults = results;
        originalSearchResults = List.from(results);
      });
    } else {
      throw Exception('Failed to load search results');
    }
  }

  void _showSettingsDialog() {
    TextEditingController urlController = TextEditingController(text: baseUrl);
    TextEditingController countController =
        TextEditingController(text: imageCount.toString());
    TextEditingController videoPathController =
        TextEditingController(text: videoPath);
    TextEditingController mapKeyframePathController =
        TextEditingController(text: mapKeyframePath);
    TextEditingController sceneRangeController =
        TextEditingController(text: sceneRange.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Base URL'),
              ),
              TextField(
                controller: countController,
                decoration:
                    const InputDecoration(labelText: 'Number of Images'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: videoPathController,
                decoration:
                    const InputDecoration(labelText: 'Video Folder Path'),
              ),
              TextField(
                controller: mapKeyframePathController,
                decoration:
                    const InputDecoration(labelText: 'Map Keyframe Path'),
              ),
              TextField(
                controller: sceneRangeController,
                decoration: const InputDecoration(labelText: 'Scene Range'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                await SettingsManager.setBaseUrl(urlController.text);
                await SettingsManager.setImageCount(
                    int.parse(countController.text));
                await SettingsManager.setVideoPath(videoPathController.text);
                await SettingsManager.setMapKeyframePath(
                    mapKeyframePathController.text);
                await SettingsManager.setSceneRange(
                    int.parse(sceneRangeController.text));

                setState(() {
                  baseUrl = urlController.text;
                  imageCount = int.parse(countController.text);
                  videoPath = videoPathController.text;
                  mapKeyframePath = mapKeyframePathController.text;
                  sceneRange = int.parse(sceneRangeController.text);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _applyAsrFilter(String asrQuery) async {
    print("ASR Query: $asrQuery");
    print("Original results count: ${originalSearchResults.length}");

    if (asrQuery.isEmpty) {
      setState(() {
        searchResults = List.from(originalSearchResults);
      });
      return;
    }

    try {
      List<Map<String, String>> videoScenePairs =
          originalSearchResults.map((result) {
        List<String> pathParts = result['relative_path'].split('/');
        String video = pathParts[0];
        String scene = pathParts[1].split('.')[0];
        return {'video': video, 'scene': scene};
      }).toList();

      final audioResults = await _elasticsearchService
          .searchAudioByVideoAndScene(asrQuery, videoScenePairs);
      // print("Video-Scene pairs: $videoScenePairs");
      // print("Audio results count: ${audioResults.length}");

      setState(() {
        searchResults = originalSearchResults.where((result) {
          String video = result['relative_path'].split('/')[0];
          String scene = result['relative_path'].split('/')[1].split('.')[0];
          return audioResults.any((audioResult) =>
              audioResult['video'] == video && audioResult['scene'] == scene);
        }).toList();
      });

      print("Filtered results count: ${searchResults.length}");
    } catch (e) {
      print('Error applying ASR filter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying ASR filter: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('VIDEO SEARCH APP'),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FilterPanel(
                    tags: tags,
                    onTagAdded: (tag) {
                      setState(() {
                        tags.add(tag);
                      });
                    },
                    onTagRemoved: (tag) {
                      setState(() {
                        tags.remove(tag);
                      });
                    },
                    onClearTags: () {
                      setState(() {
                        tags.clear();
                      });
                    },
                    onApplyAsrFilter: _applyAsrFilter,
                  ),
                  ColorPickerPanel(
                    onColorSelected: (colorCode, colorName) {
                      setState(() {
                        selectedColorCode = colorCode;
                        selectedColorName = colorName;
                      });
                    },
                  ),
                  GenderPanel(
                    genderSelection: genderSelection,
                    onGenderSelectionChanged: (index, value) {
                      setState(() {
                        for (int i = 0; i < genderSelection.length; i++) {
                          genderSelection[i] = i == index;
                        }
                      });
                    },
                  ),
                  SubmissionPanel(
                    selectedImages: selectedImages,
                    onRemoveImage: (image) {
                      setState(() {
                        selectedImages.removeWhere((item) =>
                            item['relative_path'] == image['relative_path']);
                      });
                    },
                    baseUrl: baseUrl,
                    videoPath: videoPath,
                    mapKeyframePath: mapKeyframePath,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SearchPanel(
                  searchTypeSelection: searchTypeSelection,
                  onSearchTypeSelectionChanged: (index, value) {
                    setState(() {
                      if (index == 3) {
                        searchTypeSelection = [value, value, value, value];
                      } else {
                        searchTypeSelection[index] = value;
                        searchTypeSelection[3] = searchTypeSelection
                            .sublist(0, 3)
                            .every((element) => element);
                      }
                    });
                  },
                  onSearch: _performSearch,
                ),
                Expanded(
                  child: ImageDisplayPanel(
                    onImageSelected: (imageInfo) {
                      setState(() {
                        if (!selectedImages.any((item) =>
                            item['relative_path'] ==
                            imageInfo['relative_path'])) {
                          selectedImages.add(imageInfo);
                        }
                      });
                    },
                    searchResults: searchResults,
                    baseUrl: baseUrl,
                    imageCount: imageCount,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
