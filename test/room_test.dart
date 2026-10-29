import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/room.dart';
import 'package:app/room_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Room.fromJson accurately parses user room schema', () {
    const jsonStr = '''{
      "id": 1,
      "roomNumber": "Room 101",
      "roomType": "Single Room",
      "floor": "1st Floor",
      "roomCapacity": "2 Persons",
      "roomStatus": "Occupied",
      "tenantName": "Juan Dela Cruz",
      "contactNumber": "0911413567",
      "building": "Main Hall",
      "amenities": ["Air Conditioner", "Study Desk", "Wi-Fi"],
      "lastInspected": "2026-10-20",
      "activeIssuesCount": 0
    }''';

    final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
    final room = Room.fromJson(jsonMap);

    expect(room.id, 1);
    expect(room.roomNumber, 'Room 101');
    expect(room.roomType, 'Single Room');
    expect(room.floor, '1st Floor');
    expect(room.roomCapacity, '2 Persons');
    expect(room.roomStatus, 'Occupied');
    expect(room.tenantName, 'Juan Dela Cruz');
    expect(room.contactNumber, '0911413567');
    expect(room.isOccupied, true);
    expect(room.capacity, 2);
    expect(room.amenities.length, 3);
  });

  test('Rooms JSON asset contains all 4 requested room records', () async {
    final jsonString = await rootBundle.loadString('asset/rooms.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>;

    expect(data.length, greaterThanOrEqualTo(4));
    final rooms = data.map((item) => Room.fromJson(item as Map<String, dynamic>)).toList();

    // Verify Room 101
    final room101 = rooms.firstWhere((r) => r.roomNumber.contains('101'));
    expect(room101.roomType, 'Single Room');
    expect(room101.floor, '1st Floor');
    expect(room101.roomCapacity, '2 Persons');
    expect(room101.roomStatus, 'Occupied');
    expect(room101.tenantName, 'Juan Dela Cruz');
    expect(room101.contactNumber, '0911413567');

    // Verify Room 102
    final room102 = rooms.firstWhere((r) => r.roomNumber.contains('102'));
    expect(room102.roomType, 'Single Room');
    expect(room102.floor, '1st Floor');
    expect(room102.roomCapacity, '1 Person');
    expect(room102.roomStatus, 'Occupied');
    expect(room102.tenantName, 'Raf Princess');
    expect(room102.contactNumber, '0915413567');

    // Verify Room 103
    final room103 = rooms.firstWhere((r) => r.roomNumber.contains('103'));
    expect(room103.roomType, 'Single Room');
    expect(room103.floor, '1st Floor');
    expect(room103.roomCapacity, '2 Persons');
    expect(room103.roomStatus, 'Occupied');
    expect(room103.tenantName, 'Davie Hudson');
    expect(room103.contactNumber, '09384784688');

    // Verify Room 104
    final room104 = rooms.firstWhere((r) => r.roomNumber.contains('104'));
    expect(room104.roomType, 'Single Room');
    expect(room104.floor, '1st Floor');
    expect(room104.roomCapacity, '2 Persons');
    expect(room104.roomStatus, 'Occupied');
    expect(room104.tenantName, 'Princess Jack');
    expect(room104.contactNumber, '0935358886');
  });

  test('RoomReport.fromJson parses asset/room_reports.json cleanly', () async {
    final jsonString = await rootBundle.loadString('asset/room_reports.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>;

    expect(data.isNotEmpty, true);
    final reports = data
        .map((item) => RoomReport.fromJson(item as Map<String, dynamic>))
        .toList();
    expect(reports.length, greaterThanOrEqualTo(3));
    expect(reports.first.reportedBy.isNotEmpty, true);
  });
}

