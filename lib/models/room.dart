import 'dart:convert';
import 'package:flutter/services.dart';

class Room {
  final int id;
  final String roomNumber;
  final String roomType;
  final String floor;
  final String roomCapacity;
  final String roomStatus;
  final String tenantName;
  final String contactNumber;
  final String building;
  final List<String> amenities;
  final String lastInspected;
  final int activeIssuesCount;

  const Room({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.roomCapacity,
    required this.roomStatus,
    required this.tenantName,
    required this.contactNumber,
    this.building = 'Main Hall',
    this.amenities = const [],
    this.lastInspected = '',
    this.activeIssuesCount = 0,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // Room number normalization
    final rawNumber = (json['roomNumber'] ?? json['number'] ?? '').toString().trim();
    final roomNumber = rawNumber.isNotEmpty
        ? (rawNumber.startsWith('Room') ? rawNumber : 'Room $rawNumber')
        : 'Unknown Room';

    // Room type
    final roomType = (json['roomType'] ?? json['type'] ?? json['name'] ?? 'Single Room').toString().trim();

    // Floor
    final rawFloor = json['floor'];
    final floor = rawFloor == null
        ? '1st Floor'
        : rawFloor.toString().toLowerCase().contains('floor')
            ? rawFloor.toString()
            : '$rawFloor${_ordinalSuffix(rawFloor)} Floor';

    // Room capacity
    final rawCapacity = json['roomCapacity'] ?? json['capacity'];
    final roomCapacity = rawCapacity == null
        ? '1 Person'
        : rawCapacity.toString().toLowerCase().contains('person')
            ? rawCapacity.toString()
            : '$rawCapacity ${rawCapacity.toString() == '1' ? 'Person' : 'Persons'}';

    // Room status
    final roomStatus = (json['roomStatus'] ?? json['status'] ?? 'Occupied').toString().trim();

    // Tenant name
    final tenantName = (json['tenantName'] ?? json['currentOccupant'] ?? '').toString().trim();

    // Contact number
    final contactNumber = (json['contactNumber'] ?? json['contact'] ?? json['phone'] ?? '').toString().trim();

    // Amenities
    final amenitiesList = (json['amenities'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        const [];

    return Room(
      id: (json['id'] as num?)?.toInt() ?? 0,
      roomNumber: roomNumber,
      roomType: roomType,
      floor: floor,
      roomCapacity: roomCapacity,
      roomStatus: roomStatus,
      tenantName: tenantName,
      contactNumber: contactNumber,
      building: (json['building'] ?? 'Main Hall').toString(),
      amenities: amenitiesList,
      lastInspected: (json['lastInspected'] ?? '').toString(),
      activeIssuesCount: (json['activeIssuesCount'] as num?)?.toInt() ?? 0,
    );
  }

  static String _ordinalSuffix(dynamic value) {
    final numVal = int.tryParse(value.toString()) ?? 1;
    if (numVal % 100 >= 11 && numVal % 100 <= 13) return 'th';
    switch (numVal % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomNumber': roomNumber,
    'roomType': roomType,
    'floor': floor,
    'roomCapacity': roomCapacity,
    'roomStatus': roomStatus,
    'tenantName': tenantName,
    'contactNumber': contactNumber,
    'building': building,
    'amenities': amenities,
    'lastInspected': lastInspected,
    'activeIssuesCount': activeIssuesCount,
  };

  /// Backwards-compatible aliases
  String get name => roomType;
  String get type => roomType;
  String get currentOccupant => tenantName;
  String get status => roomStatus;
  String get statusLabel => roomStatus;
  String get displayName => '$roomNumber - $roomType';

  int get capacity {
    final match = RegExp(r'\d+').firstMatch(roomCapacity);
    return match != null ? (int.tryParse(match.group(0)!) ?? 1) : 1;
  }

  bool get isOccupied =>
      roomStatus.toLowerCase().contains('occupied');

  bool get isAvailable =>
      roomStatus.toLowerCase().contains('vacant') ||
      roomStatus.toLowerCase().contains('available');

  bool get isMaintenance =>
      roomStatus.toLowerCase().contains('maint') ||
      roomStatus.toLowerCase().contains('repair');

  /// Loads and parses the rooms from the local JSON asset
  static Future<List<Room>> loadFromAsset({
    String assetPath = 'asset/rooms.json',
  }) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final dynamic decoded = jsonDecode(jsonString);

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

  Room copyWith({
    int? id,
    String? roomNumber,
    String? roomType,
    String? floor,
    String? roomCapacity,
    String? roomStatus,
    String? tenantName,
    String? contactNumber,
    String? building,
    List<String>? amenities,
    String? lastInspected,
    int? activeIssuesCount,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      floor: floor ?? this.floor,
      roomCapacity: roomCapacity ?? this.roomCapacity,
      roomStatus: roomStatus ?? this.roomStatus,
      tenantName: tenantName ?? this.tenantName,
      contactNumber: contactNumber ?? this.contactNumber,
      building: building ?? this.building,
      amenities: amenities ?? this.amenities,
      lastInspected: lastInspected ?? this.lastInspected,
      activeIssuesCount: activeIssuesCount ?? this.activeIssuesCount,
    );
  }
}
