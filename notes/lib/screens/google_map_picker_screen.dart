import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GoogleMapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const GoogleMapPickerScreen({super.key, this.initialLocation});

  @override
  State<GoogleMapPickerScreen> createState() => _GoogleMapPickerScreenState();
}

class _GoogleMapPickerScreenState extends State<GoogleMapPickerScreen> {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<_PlaceResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  bool _showSearchResults = false;
  String? _selectedPlaceName;

  // Default: Palembang, Indonesia
  static const LatLng _defaultLocation = LatLng(-2.976074, 104.775429);

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _pickedLocation = widget.initialLocation;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
      _selectedPlaceName = null;
      _showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 3) {
        _searchPlaces(query.trim());
      } else {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'FlutterNotesApp/1.0 (example@example.com)',
        'Accept': 'application/json',
        'Accept-Language': 'id',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _searchResults = data.map((item) {
            return _PlaceResult(
              name: item['display_name'] ?? '',
              lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
              lng: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
            );
          }).toList();
          _isSearching = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectPlace(_PlaceResult place) {
    final latLng = LatLng(place.lat, place.lng);
    setState(() {
      _pickedLocation = latLng;
      _selectedPlaceName = place.name;
      _showSearchResults = false;
      _searchController.text = place.name;
    });
    FocusScope.of(context).unfocus();
    _mapController.move(latLng, 16.0);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi dinonaktifkan.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak.')),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 16.0);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan lokasi saat ini.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialTarget = widget.initialLocation ?? _pickedLocation ?? _defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          if (_pickedLocation != null)
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(_pickedLocation),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Pilih', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Map (flutter_map) – expands to full size
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialTarget,
                    initialZoom: 14.0,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.notes',
                    ),
                    if (_pickedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedLocation!,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_on, size: 40, color: theme.primaryColor),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Search Bar
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      shadowColor: Colors.black26,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onTap: () {
                          if (_searchResults.isNotEmpty) {
                            setState(() => _showSearchResults = true);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari tempat, misal: Universitas Multi Data Palembang',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                        ),
                      ),
                    ),

                    // Search Results Dropdown
                    if (_showSearchResults)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            : _searchResults.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 20, color: Colors.grey[500]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Tidak ada hasil ditemukan',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: _searchResults.length,
                                      separatorBuilder: (_, _) =>
                                          Divider(height: 1, color: Colors.grey[200]),
                                      itemBuilder: (context, index) {
                                        final place = _searchResults[index];
                                        return ListTile(
                                          dense: true,
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.location_on,
                                                size: 20, color: theme.primaryColor),
                                          ),
                                          title: Text(
                                            place.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          subtitle: Text(
                                            '${place.lat.toStringAsFixed(6)}, ${place.lng.toStringAsFixed(6)}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                          ),
                                          onTap: () => _selectPlace(place),
                                        );
                                      },
                                    ),
                                  ),
                      ),
                  ],
                ),
              ),

              // Bottom info card
              if (_pickedLocation != null)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    shadowColor: Colors.black26,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedPlaceName != null) ...[
                            Row(
                              children: [
                                Icon(Icons.place, size: 18, color: theme.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedPlaceName!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              _CoordChip(
                                label: 'Lat',
                                value: _pickedLocation!.latitude.toStringAsFixed(6),
                              ),
                              const SizedBox(width: 12),
                              _CoordChip(
                                label: 'Lng',
                                value: _pickedLocation!.longitude.toStringAsFixed(6),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(context).pop(_pickedLocation),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Konfirmasi'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Instruction overlay when nothing selected
              if (_pickedLocation == null)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, color: theme.primaryColor, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Ketuk peta untuk memilih lokasi atau cari nama tempat di atas',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // My location FAB
              Positioned(
                bottom: _pickedLocation != null ? 140 : 90,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'my_location',
                  onPressed: _goToMyLocation,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: theme.primaryColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaceResult {
  final String name;
  final double lat;
  final double lng;

  _PlaceResult({required this.name, required this.lat, required this.lng});
}

class _CoordChip extends StatelessWidget {
  final String label;
  final String value;

  const _CoordChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
