import 'package:flutter/material.dart';

class ImageDisplayPanel extends StatelessWidget {
  final Function(Map<String, dynamic>) onImageSelected;
  final List<Map<String, dynamic>> searchResults;
  final String baseUrl;
  final int imageCount;

  const ImageDisplayPanel({
    super.key,
    required this.onImageSelected,
    required this.searchResults,
    required this.baseUrl,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
            child: Text(
              'Search Results (${searchResults.length} images)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 16 / 11,
              ),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final result = searchResults[index];
                String imagePath = result['relative_path'];
                if (result['model'] == 'clipv2') {
                  imagePath = 'clipv2/$imagePath';
                }
                return GestureDetector(
                  onTap: () => onImageSelected(result),
                  child: Image.network(
                    '$baseUrl/image/$imagePath',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(Map<String, dynamic> result) {
    final imageUrl =
        '$baseUrl/image/${Uri.encodeComponent(result['relative_path'])}';

    return GestureDetector(
      onTap: () => onImageSelected(result),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.error, color: Colors.red, size: 24),
                    );
                  },
                ),
              ),
            ),
          ),
          Text(
            result['relative_path']
                .split('/')
                .last, // Display only the filename
            style: const TextStyle(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
