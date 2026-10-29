import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/room.dart';

class RoomApi {
  // Configurable API endpoint for rooms
  static const String endpoint =
      'https://raw.githubusercontent.com/roomrescue/api/main/rooms.json';

  /// ==========================================
  /// REQUIREMENT 1: HTTP GET Request Execution
  /// ==========================================
  /// Executes an HTTP GET request to fetch rooms data from a remote web service.
  static Future<List<Room>> fetchRooms({
    http.Client? client,
    String? url,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse(url ?? endpoint);
      final response = await httpClient.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timed out while fetching rooms.');
        },
      );

      if (response.statusCode == 200) {
        // Successful HTTP GET: Proceed to JSON array mapping
        return parseRooms(response.body);
      } else {
        throw Exception(
          'HTTP GET failed. Server returned status code: ${response.statusCode}',
        );
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// ==========================================
  /// REQUIREMENT 2: JSON Array Mapping
  /// ==========================================
  /// Parses the raw JSON response body and maps the JSON array into a List<Room>.
  static List<Room> parseRooms(String responseBody) {
    final dynamic decoded = jsonDecode(responseBody);

    final List<dynamic> dataList =
        decoded is Map<String, dynamic> && decoded['data'] is List
            ? decoded['data'] as List<dynamic>
            : decoded is List
                ? decoded
                : [];

    return dataList
        .whereType<Map<String, dynamic>>()
        .map((item) => Room.fromJson(item))
        .toList();
  }
}
