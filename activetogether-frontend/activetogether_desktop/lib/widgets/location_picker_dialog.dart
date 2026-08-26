import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import '../models/city_option.dart';
import '../models/location_option.dart';
import '../services/api_client.dart';
import '../services/city_service.dart';
import '../services/location_service.dart';

/// Dijalog za kreiranje nove lokacije direktno iz forme za aktivnost —
/// admin ili organizator klikne na OpenStreetMap mapu da označi tačnu
/// lokaciju, unese naziv/adresu/grad, i lokacija se odmah kreira na
/// backendu. Vraća novokreiranu LocationOption preko Navigator.pop.
class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  static const _defaultPosition = latlong.LatLng(43.8563, 18.4131); // Sarajevo

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();

  latlong.LatLng _selectedPosition = _defaultPosition;
  int? _cityId;
  List<CityOption> _cities = [];
  bool _loadingCities = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final apiClient = context.read<ApiClient>();
    try {
      final cities = await CityService(apiClient).getAll();
      setState(() {
        _cities = cities;
        _cityId = cities.isNotEmpty ? cities.first.id : null;
        _loadingCities = false;
      });
    } catch (_) {
      setState(() => _loadingCities = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cityId == null) {
      setState(() => _errorMessage = 'Grad je obavezan.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final created = await LocationService(apiClient).create(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        cityId: _cityId!,
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
      );
      if (mounted) Navigator.of(context).pop<LocationOption>(created);
    } catch (_) {
      setState(() {
        _errorMessage = 'Greška prilikom čuvanja lokacije. Pokušajte ponovo.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova lokacija'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Naziv',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Naziv je obavezan.'
                      : null,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Adresa',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Adresa je obavezna.'
                      : null,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Grad',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _loadingCities
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<int>(
                        initialValue: _cityId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final c in _cities)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _cityId = v),
                      ),
                const SizedBox(height: 14),
                const Text(
                  'Tačna lokacija (kliknite na mapu)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 260,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedPosition,
                            initialZoom: 12,
                            onTap: (tapPosition, point) {
                              setState(() => _selectedPosition = point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.activetogether.desktop',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedPosition,
                                  width: 36,
                                  height: 36,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Text(
                              '${_selectedPosition.latitude.toStringAsFixed(5)}, '
                              '${_selectedPosition.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
