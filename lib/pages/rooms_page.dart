import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/room_api.dart';
import '../models/room.dart';

class RoomsPage extends StatefulWidget {
  final bool isEmbedded;
  final Function(Room)? onRoomReportRequested;
  final List<Room>? initialRooms;

  const RoomsPage({
    super.key,
    this.isEmbedded = false,
    this.onRoomReportRequested,
    this.initialRooms,
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Room> _allRooms = [];
  List<Room> _filteredRooms = [];
  String _selectedFilter = 'all';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialRooms != null) {
      _allRooms = List.from(widget.initialRooms!);
      _isLoading = false;
      _applyFilter();
    } else {
      _loadRooms();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rooms = await Room.loadFromAsset();
      if (!mounted) return;

      setState(() {
        _allRooms = rooms;
        _isLoading = false;
        _errorMessage = null;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load rooms directory: $e';
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredRooms = _allRooms.where((room) {
        final matchesQuery = query.isEmpty ||
            room.roomNumber.toLowerCase().contains(query) ||
            room.tenantName.toLowerCase().contains(query) ||
            room.roomType.toLowerCase().contains(query) ||
            room.floor.toLowerCase().contains(query) ||
            room.contactNumber.toLowerCase().contains(query) ||
            room.roomStatus.toLowerCase().contains(query);

        final matchesFilter = switch (_selectedFilter) {
          'occupied' => room.isOccupied,
          'vacant' => room.isAvailable,
          'maintenance' => room.isMaintenance,
          '1st' => room.floor.toLowerCase().contains('1'),
          _ => true,
        };

        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilter();
  }

  void _onFilterSelected(String filterKey) {
    setState(() {
      _selectedFilter = filterKey;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Rooms Directory'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reload rooms',
                  onPressed: _loadRooms,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Room',
                  onPressed: _showAddRoomDialog,
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_room_fab',
        onPressed: _showAddRoomDialog,
        backgroundColor: const Color(0xFF123C69),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Add Room'),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final occupiedCount = _allRooms.where((r) => r.isOccupied).length;
    final availableCount = _allRooms.where((r) => r.isAvailable).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search input bar
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilter(),
            decoration: InputDecoration(
              hintText: 'Search by room number, tenant, type, or phone...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF123C69)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All (${_allRooms.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('occupied', 'Occupied ($occupiedCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('vacant', 'Available ($availableCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('1st', '1st Floor'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterSelected(key),
      selectedColor: const Color(0xFF123C69),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF123C69)),
            SizedBox(height: 16),
            Text(
              'Loading rooms directory...',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadRooms,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF123C69),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredRooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No matching rooms found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try clearing your search query or switching filters.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _clearSearch,
                child: const Text('Reset Search'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      color: const Color(0xFF123C69),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _filteredRooms.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final room = _filteredRooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final isOccupied = room.isOccupied;
    final statusColor = isOccupied
        ? const Color(0xFF0D9488) // Teal/Green
        : room.isMaintenance
            ? const Color(0xFFDC2626) // Red
            : const Color(0xFF2563EB); // Blue for Available

    final statusBg = isOccupied
        ? const Color(0xFFCCFBF1)
        : room.isMaintenance
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFDBEAFE);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRoomDetails(room),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Room Number Badge & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF123C69),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.meeting_room,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              room.roomNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        room.roomType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          room.roomStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Detail Grid: Floor, Capacity, Tenant, Contact
              _buildDetailRow(
                icon: Icons.layers_outlined,
                label: 'Floor',
                value: room.floor,
                secondIcon: Icons.group_outlined,
                secondLabel: 'Room Capacity',
                secondValue: room.roomCapacity,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.person_outline,
                label: 'Tenant Name',
                value: room.tenantName.isNotEmpty ? room.tenantName : 'None',
                secondIcon: Icons.phone_outlined,
                secondLabel: 'Contact Number',
                secondValue: room.contactNumber.isNotEmpty ? room.contactNumber : 'N/A',
                highlightSecond: true,
              ),

              // Amenities row (if present)
              if (room.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: room.amenities.take(3).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        amenity,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              // Card Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _copyContact(room.contactNumber),
                    icon: const Icon(Icons.copy_outlined, size: 14),
                    label: const Text('Copy Contact', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF123C69),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => _showRoomDetails(room),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('View Details', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: const Color(0xFF0F172A),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required IconData secondIcon,
    required String secondLabel,
    required String secondValue,
    bool highlightSecond = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(secondIcon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      secondLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      secondValue,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: highlightSecond
                            ? const Color(0xFF123C69)
                            : const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyContact(String contact) {
    if (contact.isEmpty || contact == 'N/A') return;
    Clipboard.setData(ClipboardData(text: contact));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$contact" to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Detailed Bottom Sheet with full tenant and room specifications
  void _showRoomDetails(Room room) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Room Number & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.roomNumber,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF123C69),
                            ),
                          ),
                          Text(
                            '${room.roomType} • ${room.building}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: room.isOccupied
                              ? const Color(0xFFCCFBF1)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          room.roomStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: room.isOccupied
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Tenant Profile Card
                  const Text(
                    'Tenant Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF123C69),
                          child: Text(
                            room.tenantName.isNotEmpty
                                ? room.tenantName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.tenantName.isNotEmpty
                                    ? room.tenantName
                                    : 'Vacant / No Tenant',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    room.contactNumber.isNotEmpty
                                        ? room.contactNumber
                                        : 'No contact number',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (room.contactNumber.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy Number',
                            onPressed: () => _copyContact(room.contactNumber),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Room Specifications
                  const Text(
                    'Room Specifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSpecificationTile('Floor Location', room.floor),
                  _buildSpecificationTile('Room Capacity', room.roomCapacity),
                  _buildSpecificationTile('Building Section', room.building),
                  _buildSpecificationTile('Room Status', room.roomStatus),
                  if (room.lastInspected.isNotEmpty)
                    _buildSpecificationTile('Last Inspected', room.lastInspected),

                  // Amenities
                  if (room.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Included Amenities',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: room.amenities.map((amenity) {
                        return Chip(
                          label: Text(amenity, style: const TextStyle(fontSize: 12)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          avatar: const Icon(Icons.check, size: 14, color: Color(0xFF0D9488)),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Bottom action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            _showEditRoomDialog(room);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Room'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            if (widget.onRoomReportRequested != null) {
                              widget.onRoomReportRequested!(room);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Create a report for ${room.roomNumber} from the Reports tab.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.report_problem_outlined),
                          label: const Text('Report Issue'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF123C69),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpecificationTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog() {
    final roomNumberCtrl = TextEditingController();
    final roomTypeCtrl = TextEditingController(text: 'Single Room');
    final floorCtrl = TextEditingController(text: '1st Floor');
    final capacityCtrl = TextEditingController(text: '2 Persons');
    final tenantCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String status = 'Occupied';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Room to Directory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Room Number (e.g. Room 105)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: roomTypeCtrl,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: floorCtrl,
                  decoration: const InputDecoration(labelText: 'Floor'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: capacityCtrl,
                  decoration: const InputDecoration(labelText: 'Room Capacity'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Room Status'),
                  items: const [
                    DropdownMenuItem(value: 'Occupied', child: Text('Occupied')),
                    DropdownMenuItem(value: 'Available', child: Text('Available / Vacant')),
                    DropdownMenuItem(value: 'Under Repair', child: Text('Under Repair')),
                  ],
                  onChanged: (val) => setModalState(() => status = val ?? status),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tenantCtrl,
                  decoration: const InputDecoration(labelText: 'Tenant Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (roomNumberCtrl.text.trim().isEmpty) return;
                final newRoom = Room(
                  id: _allRooms.length + 1,
                  roomNumber: roomNumberCtrl.text.trim(),
                  roomType: roomTypeCtrl.text.trim(),
                  floor: floorCtrl.text.trim(),
                  roomCapacity: capacityCtrl.text.trim(),
                  roomStatus: status,
                  tenantName: tenantCtrl.text.trim(),
                  contactNumber: contactCtrl.text.trim(),
                  amenities: const ['Air Conditioner', 'Study Desk', 'Wi-Fi'],
                );

                setState(() {
                  _allRooms.add(newRoom);
                  _applyFilter();
                });

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room ${newRoom.roomNumber} added to directory!'),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123C69),
              ),
              child: const Text('Add Room'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomDialog(Room room) {
    final tenantCtrl = TextEditingController(text: room.tenantName);
    final contactCtrl = TextEditingController(text: room.contactNumber);
    String status = room.roomStatus;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Edit ${room.roomNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: ['Occupied', 'Available', 'Under Repair'].contains(status)
                      ? status
                      : 'Occupied',
                  decoration: const InputDecoration(labelText: 'Room Status'),
                  items: const [
                    DropdownMenuItem(value: 'Occupied', child: Text('Occupied')),
                    DropdownMenuItem(value: 'Available', child: Text('Available / Vacant')),
                    DropdownMenuItem(value: 'Under Repair', child: Text('Under Repair')),
                  ],
                  onChanged: (val) => setModalState(() => status = val ?? status),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tenantCtrl,
                  decoration: const InputDecoration(labelText: 'Tenant Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final updated = room.copyWith(
                  roomStatus: status,
                  tenantName: tenantCtrl.text.trim(),
                  contactNumber: contactCtrl.text.trim(),
                );

                setState(() {
                  final idx = _allRooms.indexWhere((r) => r.id == room.id);
                  if (idx != -1) {
                    _allRooms[idx] = updated;
                    _applyFilter();
                  }
                });

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${room.roomNumber} updated successfully!'),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF123C69),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
