import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:convert';

class SubmissionPanel extends StatefulWidget {
  final List<Map<String, dynamic>> selectedImages;
  final Function(Map<String, dynamic>) onRemoveImage;
  final String baseUrl;
  final String videoPath;
  final String mapKeyframePath;

  const SubmissionPanel({
    super.key,
    required this.selectedImages,
    required this.onRemoveImage,
    required this.baseUrl,
    required this.videoPath,
    required this.mapKeyframePath,
  });

  @override
  _SubmissionPanelState createState() => _SubmissionPanelState();
}

class _SubmissionPanelState extends State<SubmissionPanel> {
  bool _isVideoDialogOpen = false;
  bool isLoading = false;
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  @override
  void dispose() {
    if (_isVideoDialogOpen) {
      videoPlayerController?.dispose();
      chewieController?.dispose();
      Navigator.of(context).pop();
    }
    super.dispose();
  }

  Future<void> submitImages() async {
    if (widget.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> results = [];
      for (var image in widget.selectedImages) {
        var result = await processImage(image);
        if (result != null) {
          results.add(result);
        }
      }
      showResultDialog(results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing images: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> processImage(Map<String, dynamic> image) async {
    String relativePath = image['relative_path'];
    List<String> pathParts = relativePath.split('/');
    String videoName = pathParts[0];
    String sceneFilename = pathParts[1];
    int sceneNumber = int.parse(sceneFilename.split('_')[1].split('.')[0]);

    if (image['model'] == 'clipv2') {
      String jsonPath = '${widget.mapKeyframePath}/SceneJSON/$videoName.json';
      File jsonFile = File(jsonPath);
      if (!await jsonFile.exists()) {
        print('JSON file not found: $jsonPath');
        return null;
      }

      String jsonData = await jsonFile.readAsString();
      Map<String, dynamic> sceneData = json.decode(jsonData);
      List<List<int>> scenes = (sceneData['scenes'] as List).map((scene) {
        return (scene as List).map((frame) => frame as int).toList();
      }).toList();

      if (sceneNumber >= scenes.length || sceneNumber < 0) {
        print('Invalid scene number: $sceneNumber');
        return null;
      }

      List<int> scene = scenes[sceneNumber - 1];
      int startFrame = scene[0];
      int endFrame = scene[1];
      int midFrame = (startFrame + endFrame) ~/ 2;

      return {
        'relative_path': relativePath,
        'video_name': videoName,
        'frame_number': midFrame,
        'start_frame': startFrame,
        'model': image['model'],
      };
    } else {
      // Existing CLIP processing logic
      String csvPath = '${widget.mapKeyframePath}/$videoName.csv';
      File csvFile = File(csvPath);
      if (!await csvFile.exists()) {
        print('CSV file not found: $csvPath');
        return null;
      }

      String csvData = await csvFile.readAsString();
      List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter().convert(csvData);

      if (sceneNumber >= rowsAsListOfValues.length || sceneNumber < 1) {
        print('Invalid scene number: $sceneNumber');
        return null;
      }

      var row = rowsAsListOfValues[sceneNumber];
      var nextRow = sceneNumber + 1 < rowsAsListOfValues.length
          ? rowsAsListOfValues[sceneNumber + 1]
          : null;

      return {
        'relative_path': relativePath,
        'video_name': videoName,
        'frame_number': row[3],
        'pts_time': row[1],
        'next_pts_time': nextRow != null ? nextRow[1] : null,
        'model': image['model'],
      };
    }
  }

  void showResultDialog(List<Map<String, dynamic>> results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submission Results'),
          content: SingleChildScrollView(
            child: ListBody(
              children: results
                  .map((result) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Relative Path: ${result['relative_path']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Video: ${result['video_name']}'),
                          Text('Frame Number: ${result['frame_number']}'),
                          // Text('PTS Time: ${_calculateDuration(0, result['pts_time'])}'),
                          if (result['next_pts_time'] != null)
                            Text(
                                'Duration: ${_calculateDuration(result['pts_time'], result['next_pts_time'])} seconds'),
                          ElevatedButton(
                            child: const Text('Open Video'),
                            onPressed: () => _openVideo(result),
                          ),
                          const Divider(),
                        ],
                      ))
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Helper function to calculate duration
  String _calculateDuration(dynamic currentTime, dynamic nextTime) {
    if (currentTime == null || nextTime == null) {
      return 'N/A';
    }
    try {
      double current = double.parse(currentTime.toString());
      double next = double.parse(nextTime.toString());
      return (next - current).toStringAsFixed(2);
    } catch (e) {
      print('Error calculating duration: $e');
      return 'Error';
    }
  }

  void _openVideo(Map<String, dynamic> result) async {
    print("Opening video for result: $result"); // Debug print

    Map<String, dynamic>? processedResult = await processImage(result);
    if (processedResult == null) {
      print("Failed to process image information");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image information')),
      );
      return;
    }

    final videoFile =
        File('${widget.videoPath}/${processedResult['video_name']}.mp4');
    if (!videoFile.existsSync()) {
      print("Video file not found: ${videoFile.path}"); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video file not found: ${videoFile.path}')),
      );
      return;
    }

    VideoPlayerController? videoPlayerController;
    ChewieController? chewieController;

    void disposeControllers() {
      chewieController?.dispose();
      videoPlayerController?.dispose();
    }

    setState(() {
      _isVideoDialogOpen = true;
    });

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: FutureBuilder(
            future: () async {
              try {
                videoPlayerController = VideoPlayerController.file(videoFile);
                await videoPlayerController!.initialize();
                print("Video initialized successfully"); // Debug print

                int startTimeMs = 0;
                print(result);
                if (result['model'] == 'clipv2') {
                  if (processedResult['start_frame'] != null) {
                    // Assuming 25 fps
                    startTimeMs =
                        (processedResult['frame_number'] as int) * 1000 ~/ 25;
                  }
                } else {
                  if (processedResult['pts_time'] != null) {
                    startTimeMs =
                        (processedResult['pts_time'] as double).round() * 1000;
                  }
                }
                print("Calculated start time: $startTimeMs ms"); // Debug print

                await videoPlayerController!
                    .seekTo(Duration(milliseconds: startTimeMs));
                print("Seeked to start time successfully"); // Debug print

                chewieController = ChewieController(
                  videoPlayerController: videoPlayerController!,
                  autoPlay: true,
                  looping: false,
                  aspectRatio: videoPlayerController!.value.aspectRatio,
                );

                return chewieController;
              } catch (e) {
                print("Error initializing video: $e"); // Debug print
                return null;
              }
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError || snapshot.data == null) {
                  return Text("Error: ${snapshot.error ?? 'Unknown error'}");
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 1000, maxHeight: 750),
                      child: AspectRatio(
                        aspectRatio: chewieController!.aspectRatio ?? 16 / 9,
                        child: Chewie(controller: chewieController!),
                      ),
                    ),
                    Text(
                        "Model: ${result['model']}, Frame: ${processedResult['frame_number']}"),
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        );
      },
    ).then((_) {
      print("Dialog closed, disposing controllers"); // Debug print
      disposeControllers();
      setState(() {
        _isVideoDialogOpen = false;
      });
    });
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
          const Text('Selected Images:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.selectedImages.isEmpty)
            const Text('No images selected',
                style: TextStyle(fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedImages
                  .map((imageInfo) => _buildImageThumbnail(imageInfo))
                  .toList(),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: widget.selectedImages.isEmpty || isLoading
                ? null
                : submitImages,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(Map<String, dynamic> imageInfo) {
    String imagePath = imageInfo['relative_path'];
    if (imageInfo['model'] == 'clipv2') {
      imagePath = 'clipv2/$imagePath';
    }

    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              '${widget.baseUrl}/image/${Uri.encodeComponent(imagePath)}',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                    child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ));
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () => widget.onRemoveImage(imageInfo),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 15, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              imageInfo['model'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
          ),
        ),
      ],
    );
  }
}
