import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotel_tourism_models.dart';
import '../providers/auth_provider.dart';
import '../services/api/base_api_service.dart';
import '../services/api/tourism_api_service.dart';
import 'ai_assistant_screen.dart';

class HotelScreen extends StatefulWidget {
  const HotelScreen({super.key});

  @override
  State<HotelScreen> createState() => _HotelScreenState();
}

class _HotelScreenState extends State<HotelScreen> {
  final TourismApiService _service = TourismApiService();
  List<HotelModel>? _hotels;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final hotels = await _service.getHotels();
      if (!mounted) return;
      setState(() {
        _hotels = hotels;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (_hotels == null) {
        setState(() {
          _error = error;
          _loading = false;
        });
        return;
      }
      setState(() => _loading = false);
      _showError(error);
    }
  }

  Future<void> _refresh() => _load();

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _showError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Could not reach the hotel service. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _bookRoom(HotelModel hotel) async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final reservation = await showModalBottomSheet<HotelReservationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _BookingSheet(
          hotel: hotel,
          guestName: user?.fullName ?? '',
          guestPhone: user?.phone ?? '',
        ),
      ),
    );
    if (reservation == null || !mounted) return;
    await _showBookingConfirmation(reservation);
  }

  Future<void> _showBookingConfirmation(HotelReservationModel reservation) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reservation sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking code: ${reservation.bookingCode}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('${reservation.hotelName} · Room ${reservation.roomNumber}'),
            Text(
              '${formatBookingDate(reservation.checkIn)} → '
              '${formatBookingDate(reservation.checkOut)}',
            ),
            Text('Guests: ${reservation.guests} · ${reservation.totalLabel}'),
            const SizedBox(height: 12),
            const Text(
              'The hotel will confirm or reject your reservation. '
              'Keep your booking code for reference.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels & Lodging'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh hotels',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
        backgroundColor: Colors.purple[800],
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _hotels == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hotels == null) {
      return _buildError(_error ?? Exception('Hotels are unavailable.'));
    }
    final hotels = _hotels!;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: hotels.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: const [
                SizedBox(height: 80),
                Icon(Icons.hotel, size: 56, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hotels are available at the moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: hotels.length,
              itemBuilder: (context, index) =>
                  _buildHotelCard(hotels[index]),
            ),
    );
  }

  Widget _buildError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Could not load hotels. Please try again.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _retry, child: const Text('TRY AGAIN')),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard(HotelModel hotel) {
    final rooms = hotel.rooms;
    final available = hotel.availableRooms;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.purple.shade50,
            child: hotel.imageUrls.isEmpty
                ? const Icon(Icons.hotel, size: 56, color: Colors.purple)
                : Image.network(
                    hotel.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.hotel,
                      size: 56,
                      color: Colors.purple,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hotel.locationLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '★ ${hotel.ratingLabel}',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hotel.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                hotel.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          const SizedBox(height: 10),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Rooms have not been added yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${available.length} of ${rooms.length} rooms available',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...rooms.map(
                    (room) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            size: 15,
                            color: room.status == 'available'
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${room.roomNumber} · ${room.roomType} · '
                              'sleeps ${room.capacity}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            room.rateLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: available.isEmpty ? null : () => _bookRoom(hotel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[800],
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  available.isEmpty ? 'NO ROOMS AVAILABLE' : 'RESERVE ROOM',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({
    required this.hotel,
    required this.guestName,
    required this.guestPhone,
  });

  final HotelModel hotel;
  final String guestName;
  final String guestPhone;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final TourismApiService _service = TourismApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  HotelRoomModel? _room;
  late DateTime _checkIn;
  late DateTime _checkOut;
  var _guests = 1;
  var _submitting = false;
  String? _error;

  List<HotelRoomModel> get _availableRooms => widget.hotel.availableRooms;

  int get _nights {
    final days = _checkOut.difference(_checkIn).inDays;
    return days > 0 ? days : 1;
  }

  @override
  void initState() {
    super.initState();
    final rooms = _availableRooms;
    _room = rooms.isEmpty ? null : rooms.first;
    final today = DateUtils.dateOnly(DateTime.now());
    _checkIn = today;
    _checkOut = today.add(const Duration(days: 1));
    _nameController.text = widget.guestName;
    _phoneController.text = widget.guestPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckIn() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn.isBefore(today) ? today : _checkIn,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Select check-in date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _checkIn = picked;
      if (!_checkOut.isAfter(_checkIn)) {
        _checkOut = _checkIn.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickCheckOut() async {
    final first = _checkIn.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOut.isAfter(first) ? _checkOut : first,
      firstDate: first,
      lastDate: _checkIn.add(const Duration(days: 365)),
      helpText: 'Select check-out date',
    );
    if (picked == null || !mounted) return;
    setState(() => _checkOut = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final room = _room;
    if (room == null) {
      setState(() => _error = 'This hotel has no rooms available.');
      return;
    }
    if (_guests > room.capacity) {
      setState(() {
        _error = 'Room ${room.roomNumber} sleeps at most '
            '${room.capacity} guests.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final reservation = await _service.createReservation(
        hotelId: widget.hotel.id,
        roomId: room.id,
        guestName: _nameController.text,
        checkIn: _checkIn,
        checkOut: _checkOut,
        guests: _guests,
        guestPhone: _phoneController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, reservation);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is ApiException
            ? error.message
            : 'Could not book this room. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final total = (room?.nightlyRate ?? 0) * _nights;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Book at ${widget.hotel.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<HotelRoomModel>(
                initialValue: room,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                ),
                items: _availableRooms
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          '${r.roomNumber} · ${r.roomType} · ${r.rateLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() {
                          _room = value;
                          if (value != null && _guests > value.capacity) {
                            _guests = value.capacity;
                          }
                        }),
                validator: (value) =>
                    value == null ? 'Choose an available room.' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickCheckIn,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(formatBookingDate(_checkIn)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickCheckOut,
                      icon: const Icon(Icons.event_available, size: 16),
                      label: Text(formatBookingDate(_checkOut)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _guests,
                decoration: const InputDecoration(
                  labelText: 'Guests',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  room?.capacity ?? 1,
                  (index) => index + 1,
                )
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count guest${count == 1 ? '' : 's'}'),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _guests = value ?? 1),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Guest name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2 || text.length > 120) {
                    return 'Enter the guest name (2-120 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                enabled: !_submitting,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  room == null
                      ? 'No room selected.'
                      : '$_nights night${_nights == 1 ? '' : 's'} × '
                          '${room.rateLabel} = ${formatAmount(total)} ETB\n'
                          'The server recalculates the final total.',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[800],
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SEND RESERVATION'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
