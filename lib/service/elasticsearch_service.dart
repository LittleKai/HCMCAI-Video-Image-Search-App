import 'dart:convert';
import 'package:http/http.dart' as http;

class ElasticsearchService {
  final String baseUrl;

  ElasticsearchService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> searchAudioByVideoAndScene(
      String query, List<Map<String, String>> videoScenePairs) async {
    final requestBody = json.encode({
      "query": {
        "bool": {
          "must": [
            {
              "match_phrase_prefix": {
                "audio": query
              }
            },
            {
              "terms": {
                "video": videoScenePairs.map((pair) => pair['video']).toSet().toList()
              }
            },
            {
              "terms": {
                "scene": videoScenePairs.map((pair) => pair['scene']).toSet().toList()
              }
            }
          ]
        }
      },
      "size": 1000
    });

    print("Elasticsearch query: $requestBody");

    final response = await http.post(
      Uri.parse('$baseUrl/aic/_search'),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    // print("Elasticsearch response status: ${response.statusCode}");
    // print("Elasticsearch response body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['hits']['hits'].map((hit) => hit['_source']));
    } else {
      throw Exception('Failed to search audio');
    }
  }

  Future<List<Map<String, dynamic>>> searchAudio(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/aic/_search'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "query": {
          "match": {"audio": query}
        }
      }),
    );
    print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(
          data['hits']['hits'].map((hit) => hit['_source']));
    } else {
      throw Exception('Failed to search audio');
    }
  }

  Future<bool> checkElasticsearchConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/aic/_count'));
      print("Elasticsearch count response: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("Error connecting to Elasticsearch: $e");
      return false;
    }
  }
}
