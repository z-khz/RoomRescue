import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/room.dart';
import 'package:app/pages/rooms_page.dart';

void main() {
  final sampleRooms = [
    const Room(
      id: 1,
      roomNumber: 'Room 101',
      roomType: 'Single Room',
      floor: '1st Floor',
      roomCapacity: '2 Persons',
      roomStatus: 'Occupied',
      tenantName: 'Juan Dela Cruz',
      contactNumber: '0911413567',
    ),
    const Room(
      id: 2,
      roomNumber: 'Room 102',
      roomType: 'Single Room',
      floor: '1st Floor',
      roomCapacity: '1 Person',
      roomStatus: 'Occupied',
      tenantName: 'Raf Princess',
      contactNumber: '0915413567',
    ),
    const Room(
      id: 3,
      roomNumber: 'Room 103',
      roomType: 'Single Room',
      floor: '1st Floor',
      roomCapacity: '2 Persons',
      roomStatus: 'Occupied',
      tenantName: 'Davie Hudson',
      contactNumber: '09384784688',
    ),
    const Room(
      id: 4,
      roomNumber: 'Room 104',
      roomType: 'Single Room',
      floor: '1st Floor',
      roomCapacity: '2 Persons',
      roomStatus: 'Occupied',
      tenantName: 'Princess Jack',
      contactNumber: '0935358886',
    ),
  ];

  testWidgets('RoomsPage displays rooms directory and search bar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: RoomsPage(
          isEmbedded: true,
          initialRooms: sampleRooms,
        ),
      ),
    );

    await tester.pump();

    // Verify search bar is present
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText?.contains('Search') == true,
      ),
      findsOneWidget,
    );

    // Verify room cards are displayed
    expect(find.text('Room 101'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('0911413567'), findsOneWidget);

    expect(find.text('Room 102'), findsOneWidget);
    expect(find.text('Raf Princess'), findsOneWidget);
    expect(find.text('0915413567'), findsOneWidget);

    expect(find.text('Room 103'), findsOneWidget);
    expect(find.text('Davie Hudson'), findsOneWidget);
    expect(find.text('09384784688'), findsOneWidget);

    expect(find.text('Room 104'), findsOneWidget);
    expect(find.text('Princess Jack'), findsOneWidget);
    expect(find.text('0935358886'), findsOneWidget);
  });

  testWidgets('RoomsPage filters rooms dynamically when searching', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: RoomsPage(
          isEmbedded: true,
          initialRooms: sampleRooms,
        ),
      ),
    );

    await tester.pump();

    // Confirm initial rooms are loaded
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Davie Hudson'), findsOneWidget);

    // Search for "Davie"
    await tester.enterText(find.byType(TextField), 'Davie');
    await tester.pump();

    // Only Room 103 / Davie Hudson should be visible
    expect(find.text('Davie Hudson'), findsOneWidget);
    expect(find.text('Room 103'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsNothing);
    expect(find.text('Raf Princess'), findsNothing);
  });
}
