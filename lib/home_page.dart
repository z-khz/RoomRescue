import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'room_report.dart';
import 'rooms_page.dart';
import 'room.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  List<RoomReport> reports = [];
  List<Room> rooms = [];
  bool isLoading = true;
  String? loadError;
  int selectedIndex = 0;
  String searchText = '';

  User? get user => FirebaseAuth.instance.currentUser;

  String get signedInName {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final emailName = user?.email?.split('@').first;
    if (emailName == null || emailName.isEmpty) return 'RoomRescue member';
    return emailName
        .split(RegExp(r'[._-]+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  List<RoomReport> get visibleReports {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return reports;
    return reports
        .where(
          (report) =>
              report.title.toLowerCase().contains(query) ||
              report.location.toLowerCase().contains(query) ||
              report.status.toLowerCase().contains(query),
        )
        .toList();
  }

  int get openReportCount =>
      reports.where((report) => report.status != 'resolved').length;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadReports() async {
    List<RoomReport> loadedReports = [];
    List<Room> loadedRooms = [];

    try {
      final jsonString = await rootBundle.loadString('asset/room_reports.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      loadedReports = (jsonData['data'] as List<dynamic>)
          .map((item) => RoomReport.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading room_reports.json: $e');
    }

    try {
      loadedRooms = await Room.loadFromAsset();
    } catch (e) {
      debugPrint('Error loading rooms.json: $e');
    }

    if (!mounted) return;
    setState(() {
      reports = loadedReports;
      rooms = loadedRooms;
      isLoading = false;
      loadError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedIndex == 0
              ? 'RoomRescue'
              : selectedIndex == 1
              ? 'My reports'
              : 'Rooms Directory',
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: showNotifications,
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      drawer: buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: selectedIndex,
              children: [
                dashboardContent(),
                reportsContent(),
                RoomsPage(
                  isEmbedded: true,
                  initialRooms: rooms.isNotEmpty ? rooms : null,
                  onRoomReportRequested: (room) {
                    showReportDialog(initialLocation: room.roomNumber);
                  },
                ),
              ],
            ),
      floatingActionButton: selectedIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: showReportDialog,
              icon: const Icon(Icons.add),
              label: const Text('Report issue'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Rooms',
          ),
        ],
      ),
    );
  }

  Widget buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(signedInName),
              accountEmail: Text(user?.email ?? 'Signed in'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Image.asset('asset/room.png', fit: BoxFit.cover),
              ),
              decoration: const BoxDecoration(color: Color(0xFF123C69)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => selectDrawerPage(0),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('My reports'),
              onTap: () => selectDrawerPage(1),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room_outlined),
              title: const Text('Rooms Directory'),
              onTap: () => selectDrawerPage(2),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: showSettings,
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),
    );
  }

  void selectDrawerPage(int index) {
    Navigator.pop(context);
    setState(() => selectedIndex = index);
  }

  Widget dashboardContent() {
    final recentReports = [...reports]
      ..sort((first, second) => second.reportedAt.compareTo(first.reportedAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text(
          'Good to see you, $signedInName!',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Keep your space in shape.',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Open reports',
                        style: TextStyle(color: Color(0xFF52708A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$openReportCount',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE2A8),
                  child: Icon(Icons.build_outlined, color: Color(0xFF8A5A00)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Quick actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.report_problem_outlined),
            ),
            title: const Text('Report a room issue'),
            subtitle: const Text('Tell us what needs attention.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: showReportDialog,
          ),
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8EEF5),
              child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF123C69)),
            ),
            title: const Text('Browse Products & Supplies'),
            subtitle: const Text('Search and order items or materials.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => selectedIndex = 2),
          ),
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.meeting_room_outlined, color: Color(0xFF0369A1)),
            ),
            title: const Text('All Rooms & Facilities'),
            subtitle: Text(
              rooms.isNotEmpty
                  ? 'View details for ${rooms.length} monitored rooms.'
                  : 'View room locations and equipment.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: showRoomsDirectory,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Recent activity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (recentReports.isEmpty)
          const Card(child: ListTile(title: Text('No reports yet')))
        else
          ...recentReports.take(3).map(reportTile),
      ],
    );
  }

  Widget reportsContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            controller: searchController,
            onChanged: (value) => setState(() => searchText = value),
            decoration: InputDecoration(
              hintText: 'Search reports',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchText = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
        Expanded(
          child: visibleReports.isEmpty
              ? const Center(child: Text('No matching reports.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: visibleReports.map(reportTile).toList(),
                ),
        ),
      ],
    );
  }

  Widget reportTile(RoomReport report) {
    return Card(
      child: ListTile(
        leading: Icon(
          statusIcon(report.status),
          color: statusColor(report.status),
        ),
        title: Text(report.title),
        subtitle: Text('${report.location} • ${statusLabel(report.status)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showReportDetails(report),
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loadError!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  void showReportDialog({String? initialLocation}) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController =
        TextEditingController(text: initialLocation ?? '');
    String priority = 'medium';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New room report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Issue title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => priority = value ?? priority),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    locationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add a title and location first.'),
                    ),
                  );
                  return;
                }
                final nextId = reports.isEmpty
                    ? 1
                    : reports
                              .map((report) => report.id)
                              .reduce((a, b) => a > b ? a : b) +
                          1;
                setState(() {
                  reports = [
                    RoomReport.newReport(
                      id: nextId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      location: locationController.text.trim(),
                      priority: priority,
                      reportedBy: signedInName,
                    ),
                    ...reports,
                  ];
                });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted.')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    ).then((_) {
      titleController.dispose();
      descriptionController.dispose();
      locationController.dispose();
    });
  }

  void showReportDetails(RoomReport report) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: Text(
          '${report.description}\n\nLocation: ${report.location}\nPriority: ${report.priority}\nStatus: ${statusLabel(report.status)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void showNotifications() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('You are all caught up.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void showRoomsDirectory() {
    setState(() => selectedIndex = 2);
  }


  void showSettings() {
    Navigator.pop(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('RoomRescue settings are ready for your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String statusLabel(String status) =>
      status[0].toUpperCase() + status.substring(1);

  IconData statusIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      default:
        return Icons.error_outline;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }
}
