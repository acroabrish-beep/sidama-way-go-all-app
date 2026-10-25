import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hotel_tourism_models.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/tourism_api_service.dart';
import '../book_ride_screen.dart';

class TouristSitesScreen extends StatefulWidget {
  /// When embedded in a dashboard tab, the screen renders without its own
  /// [Scaffold] so the parent tab bar stays in control of navigation.
  const TouristSitesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TouristSitesScreen> createState() => _TouristSitesScreenState();
}

class _TouristSitesScreenState extends State<TouristSitesScreen> {
  final TourismApiService _service = TourismApiService();
  final TextEditingController _searchController = TextEditingController();

  List<TourismSiteModel>? _sites;
  Object? _error;
  var _loading = true;
  var _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sites = await _service.getTouristSites();
      if (!mounted) return;
      setState(() {
        _sites = sites;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (_sites == null) {
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
        : 'Could not reach the tourism service. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  List<TourismSiteModel> get _filteredSites {
    final sites = _sites ?? const <TourismSiteModel>[];
    final query = _searchController.text.trim().toLowerCase();
    return sites.where((site) {
      final matchesCategory = _selectedCategory == 'all' ||
          site.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return site.name.toLowerCase().contains(query) ||
          site.address.toLowerCase().contains(query) ||
          site.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<void> _showAddSiteDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddSiteDialog(),
    );
    if (created != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tourist site added.'),
        backgroundColor: Colors.green,
      ),
    );
    _load();
  }

  Future<void> _confirmDelete(TourismSiteModel site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tourist site?'),
        content: Text(
          '"${site.name}" will be permanently removed from the public list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteTouristSite(site.id);
      if (!mounted) return;
      setState(() {
        _sites = _sites!
            .where((item) => item.id != site.id)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${site.name} was deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context).userModel?.role;
    final isAdmin =
        role == UserRole.superAdmin || role == UserRole.tourismAdmin;
    final content = _buildContent(isAdmin);
    if (widget.embedded) {
      return ColoredBox(color: const Color(0xFFF5F5F5), child: content);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourist Sites'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh sites',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: content,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : _showAddSiteDialog,
              backgroundColor: const Color(0xFF1B5E20),
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
              label: const Text(
                'Add site',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(bool isAdmin) {
    if (_loading && _sites == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sites == null) {
      final message = _error is ApiException
          ? (_error as ApiException).message
          : 'Could not load tourist sites. Please try again.';
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

    final sites = _filteredSites;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search sites...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Add tourist site',
                  onPressed: _loading ? null : _showAddSiteDialog,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_location_alt),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'All'),
                ...TourismApiService.tourismCategories.map(
                  (category) => _buildCategoryChip(
                    category,
                    category[0].toUpperCase() + category.substring(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (sites.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No tourist sites match your filters.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...sites.map((site) => _buildSiteCard(site, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = value),
        selectedColor: Colors.green.withValues(alpha: 0.2),
        checkmarkColor: const Color(0xFF1B5E20),
      ),
    );
  }

  Widget _buildSiteCard(TourismSiteModel site, bool isAdmin) {
    final (icon, color) = _categoryVisual(site.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    site.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (site.verified)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${site.categoryLabel} · ${site.address.isEmpty ? 'Hawassa' : site.address}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isAdmin
                ? IconButton(
                    tooltip: 'Delete site',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(site),
                  )
                : null,
          ),
          if (site.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                site.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _detail(
                  Icons.star,
                  Colors.amber.shade700,
                  '${site.ratingLabel} (${site.reviewsCount})',
                ),
                _detail(
                  Icons.payments,
                  Colors.green.shade700,
                  site.entryFeeLabel,
                ),
                _detail(
                  Icons.access_time,
                  Colors.grey.shade700,
                  site.openingHours.isEmpty
                      ? 'Hours not listed'
                      : site.openingHours,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              site.coordinatesLabel,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _actionButton(
                    Icons.map,
                    'Navigate',
                    () => _showNavigation(site),
                  ),
                  _actionButton(
                    Icons.local_taxi,
                    'Book Ride',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookRideScreen(
                          preselectedDestination: site.name,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1B5E20),
          side: const BorderSide(color: Color(0xFF1B5E20)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  void _showNavigation(TourismSiteModel site) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Navigate to ${site.name}'),
        content: Text(
          site.latitude == null || site.longitude == null
              ? 'Coordinates are not listed for this site.'
              : 'GPS coordinates:\n${site.coordinatesLabel}',
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

  (IconData, Color) _categoryVisual(String category) {
    switch (category) {
      case 'natural':
        return (Icons.landscape, Colors.green);
      case 'historical':
        return (Icons.account_balance, Colors.brown);
      case 'cultural':
        return (Icons.theater_comedy, Colors.orange);
      case 'religious':
        return (Icons.church, Colors.deepPurple);
      case 'entertainment':
        return (Icons.celebration, Colors.pink);
      case 'shopping':
        return (Icons.shopping_bag, Colors.blue);
      case 'dining':
        return (Icons.restaurant, Colors.red);
      default:
        return (Icons.place, Colors.teal);
    }
  }
}

class _AddSiteDialog extends StatefulWidget {
  const _AddSiteDialog();

  @override
  State<_AddSiteDialog> createState() => _AddSiteDialogState();
}

class _AddSiteDialogState extends State<_AddSiteDialog> {
  final TourismApiService _service = TourismApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();
  final _phoneController = TextEditingController();
  final _feeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  var _category = TourismApiService.tourismCategories.first;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _phoneController.dispose();
    _feeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _service.createTouristSite(
        name: _nameController.text,
        category: _category,
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        description: _descriptionController.text,
        address: _addressController.text,
        openingHours: _hoursController.text,
        phone: _phoneController.text,
        entranceFee: _feeController.text.trim().isEmpty
            ? null
            : double.parse(_feeController.text.trim()),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is ApiException
            ? error.message
            : 'Could not add the tourist site. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add tourist site'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Site name'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2 || text.length > 160) {
                    return 'Enter a name between 2 and 160 characters.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: TourismApiService.tourismCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category[0].toUpperCase() + category.substring(1),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(
                          () => _category = value ?? _category,
                        ),
              ),
              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _addressController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _hoursController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Opening hours',
                ),
              ),
              TextFormField(
                controller: _phoneController,
                enabled: !_submitting,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: _feeController,
                enabled: !_submitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Entrance fee (ETB, optional)',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final fee = double.tryParse(text);
                  if (fee == null || fee < 0) {
                    return 'Enter a valid fee, or leave it blank.';
                  }
                  return null;
                },
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
    if (text.isEmpty) return 'Required';
    final number = double.tryParse(text);
    if (number == null || number < min || number > max) {
      return '$min to $max';
    }
    return null;
  }
}
