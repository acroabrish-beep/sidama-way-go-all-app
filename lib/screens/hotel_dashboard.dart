import 'package:flutter/material.dart';

import '../models/hotel_tourism_models.dart';
import '../models/user_model.dart';
import '../services/api/base_api_service.dart';
import '../services/api/tourism_api_service.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import '../widgets/role_protected_widget.dart';
import '../widgets/tourism_phase2_widgets.dart';

class HotelDashboard extends StatefulWidget {
  const HotelDashboard({super.key});

  @override
  State<HotelDashboard> createState() => _HotelDashboardState();
}

class _HotelDashboardState extends State<HotelDashboard> {
  final TourismApiService _service = TourismApiService();
  List<HotelModel>? _hotels;
  List<HotelReservationModel>? _reservations;
  Object? _error;
  var _loading = true;
  String? _busyReservationId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (hotels, reservations) = await (
        _service.getHotels(),
        _service.getReservations(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _hotels = hotels;
        _reservations = reservations;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (_hotels == null || _reservations == null) {
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

  Future<void> _decideReservation(
    HotelReservationModel reservation,
    String status,
  ) async {
    setState(() => _busyReservationId = reservation.id);
    try {
      final updated = await _service.updateReservationStatus(
        reservationId: reservation.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        final index =
            _reservations!.indexWhere((item) => item.id == updated.id);
        if (index >= 0) _reservations![index] = updated;
        _busyReservationId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation ${updated.statusLabel.toLowerCase()}.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busyReservationId = null);
      _showError(error);
    }
  }

  Future<void> _showAddHotelDialog() async {
    final hotel = await showDialog<HotelModel>(
      context: context,
      builder: (_) => const _AddHotelDialog(),
    );
    if (hotel == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${hotel.name} was added.'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    _load();
  }

  Future<void> _showAddRoomDialog(HotelModel hotel) async {
    final room = await showDialog<HotelRoomModel>(
      context: context,
      builder: (_) => _AddRoomDialog(hotel: hotel),
    );
    if (room == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room ${room.roomNumber} was added to ${hotel.name}.'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.hotelAdmin],
      child: DashboardBase(
        title: 'Hotel Admin',
        actions: [
          IconButton(
            tooltip: 'Refresh hotel data',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : _showAddHotelDialog,
          backgroundColor: Colors.purpleAccent,
          icon: const Icon(Icons.add_business, color: Colors.white),
          label: const Text(
            'Add hotel',
            style: TextStyle(color: Colors.white),
          ),
        ),
        children: _buildChildren(),
      ),
    );
  }

  List<Widget> _buildChildren() {
    if (_loading && (_hotels == null || _reservations == null)) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_hotels == null || _reservations == null) {
      return [_buildError()];
    }
    return [
      _buildSummary(),
      const SizedBox(height: 16),
      const Text(
        'RESERVATIONS',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 8),
      _buildReservations(),
      const SizedBox(height: 16),
      const Text(
        'HOTELS & ROOMS',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 8),
      _buildHotels(),
    ];
  }

  Widget _buildError() {
    final message = _error is ApiException
        ? (_error as ApiException).message
        : 'Could not load hotel data. Please try again.';
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _retry,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final hotels = _hotels!;
    final reservations = _reservations!;
    final roomCount = hotels.fold<int>(
      0,
      (total, hotel) => total + hotel.rooms.length,
    );
    final pendingCount =
        reservations.where((reservation) => reservation.isPending).length;
    final confirmedRevenue = reservations
        .where((reservation) => reservation.status == 'confirmed')
        .fold<double>(0, (total, reservation) => total + reservation.totalAmount);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Hotels',
          hotels.length.toString(),
          Icons.hotel,
          Colors.purpleAccent,
        ),
        _buildStatCard(
          'Rooms',
          roomCount.toString(),
          Icons.meeting_room,
          Colors.lightBlueAccent,
        ),
        _buildStatCard(
          'Pending',
          pendingCount.toString(),
          Icons.pending_actions,
          Colors.orangeAccent,
        ),
        _buildStatCard(
          'Confirmed revenue',
          '${formatAmount(confirmedRevenue)} ETB',
          Icons.payments,
          Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservations() {
    final reservations = [..._reservations!]
      ..sort((a, b) {
        if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
    if (reservations.isEmpty) {
      return const GlassCard(
        child: Text(
          'No reservations yet.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Column(
      children: reservations.map(_buildReservationCard).toList(),
    );
  }

  Widget _buildReservationCard(HotelReservationModel reservation) {
    final busy = _busyReservationId == reservation.id;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${reservation.hotelName} · Room ${reservation.roomNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              ReservationStatusChip(status: reservation.status, compact: true),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Code: ${reservation.bookingCode}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '${reservation.guestName}'
            '${reservation.guestPhone.isEmpty ? '' : ' · ${reservation.guestPhone}'}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatBookingDate(reservation.checkIn)} → '
            '${formatBookingDate(reservation.checkOut)} · '
            '${reservation.nights} night${reservation.nights == 1 ? '' : 's'} · '
            '${reservation.guests} guest${reservation.guests == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '${reservation.roomType} · ${reservation.totalLabel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (reservation.isPending) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _decideReservation(reservation, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('REJECT'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: busy
                      ? null
                      : () => _decideReservation(reservation, 'confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('CONFIRM'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHotels() {
    if (_hotels!.isEmpty) {
      return const GlassCard(
        child: Text(
          'No hotels yet. Use “Add hotel” to create one.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Column(
      children: _hotels!.map((hotel) {
        return GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hotel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '★ ${hotel.ratingLabel}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hotel.locationLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (hotel.rooms.isEmpty)
                const Text(
                  'No rooms yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                )
              else
                ...hotel.rooms.map(
                  (room) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          size: 15,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${room.roomNumber} · ${room.roomType} · '
                            'sleeps ${room.capacity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          room.rateLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          room.statusLabel,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showAddRoomDialog(hotel),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('ADD ROOM'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purpleAccent,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AddHotelDialog extends StatefulWidget {
  const _AddHotelDialog();

  @override
  State<_AddHotelDialog> createState() => _AddHotelDialogState();
}

class _AddHotelDialogState extends State<_AddHotelDialog> {
  final TourismApiService _service = TourismApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Hawassa');
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  int? _starRating;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final hasCoordinates = _latitudeController.text.trim().isNotEmpty ||
        _longitudeController.text.trim().isNotEmpty;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final hotel = await _service.createHotel(
        name: _nameController.text,
        city: _cityController.text,
        starRating: _starRating,
        description: _descriptionController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        latitude: hasCoordinates
            ? double.tryParse(_latitudeController.text.trim())
            : null,
        longitude: hasCoordinates
            ? double.tryParse(_longitudeController.text.trim())
            : null,
      );
      if (!mounted) return;
      Navigator.pop(context, hotel);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is ApiException
            ? error.message
            : 'Could not add the hotel. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add hotel'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Hotel name'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2 || text.length > 160) {
                    return 'Enter a name between 2 and 160 characters.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Enter the city.' : null,
              ),
              TextFormField(
                controller: _addressController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _phoneController,
                enabled: !_submitting,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              DropdownButtonFormField<int>(
                initialValue: _starRating,
                decoration: const InputDecoration(labelText: 'Star rating'),
                items: [1, 2, 3, 4, 5]
                    .map(
                      (star) => DropdownMenuItem(
                        value: star,
                        child: Text('$star star${star == 1 ? '' : 's'}'),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _starRating = value),
              ),
              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      enabled: !_submitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      validator: (value) => _validateCoordinate(
                        value,
                        min: -90,
                        max: 90,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      enabled: !_submitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      validator: (value) => _validateCoordinate(
                        value,
                        min: -180,
                        max: 180,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }

  String? _validateCoordinate(
    String? value, {
    required double min,
    required double max,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    if (number == null || number < min || number > max) {
      return 'Enter a value between $min and $max.';
    }
    return null;
  }
}

class _AddRoomDialog extends StatefulWidget {
  const _AddRoomDialog({required this.hotel});

  final HotelModel hotel;

  @override
  State<_AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<_AddRoomDialog> {
  final TourismApiService _service = TourismApiService();
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _typeController = TextEditingController();
  final _capacityController = TextEditingController(text: '2');
  final _rateController = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _numberController.dispose();
    _typeController.dispose();
    _capacityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final room = await _service.createRoom(
        hotelId: widget.hotel.id,
        roomNumber: _numberController.text,
        roomType: _typeController.text,
        capacity: int.parse(_capacityController.text.trim()),
        nightlyRate: double.parse(_rateController.text.trim()),
      );
      if (!mounted) return;
      Navigator.pop(context, room);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is ApiException
            ? error.message
            : 'Could not add the room. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add room to ${widget.hotel.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _numberController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Room number'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty || text.length > 20) {
                    return 'Enter a room number up to 20 characters.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Room type'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2 || text.length > 80) {
                    return 'Enter a room type (2-80 characters).';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _capacityController,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity'),
                validator: (value) {
                  final number = int.tryParse(value?.trim() ?? '');
                  if (number == null || number < 1) {
                    return 'Capacity must be at least 1.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _rateController,
                enabled: !_submitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nightly rate (ETB)',
                ),
                validator: (value) {
                  final number = double.tryParse(value?.trim() ?? '');
                  if (number == null || number < 0) {
                    return 'Enter a valid nightly rate.';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
