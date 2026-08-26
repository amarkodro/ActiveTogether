import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/city_option.dart';
import '../../models/location_option.dart';
import '../../services/api_client.dart';
import '../../services/city_service.dart';
import '../../services/location_service.dart';

/// Ekran na kojem organizator na Google mapi označi tačnu lokaciju aktivnosti
/// i unese naziv/adresu/grad, nakon čega se lokacija kreira na backendu.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _initialPosition = LatLng(43.8563, 18.4131); // Sarajevo

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  LatLng? _selectedPosition;
  int? _cityId;
  List<CityOption> _cities = [];
  bool _loadingCities = true;
  bool _isSaving = false;

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
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Označite tačnu lokaciju na mapi.')),
      );
      return;
    }
    if (_cityId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Odaberite grad.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final apiClient = context.read<ApiClient>();
      final created = await LocationService(apiClient).create(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        cityId: _cityId!,
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
      );
      if (!mounted) return;
      Navigator.of(context).pop<LocationOption>(created);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kreiranje lokacije nije uspjelo.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Nova lokacija'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Spremi'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _initialPosition,
                      zoom: 12,
                    ),
                    onTap: (position) {
                      setState(() => _selectedPosition = position);
                    },
                    markers: _selectedPosition == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: _selectedPosition!,
                            ),
                          },
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Text(
                        'Dodirnite mapu da označite tačnu lokaciju',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Naziv lokacije',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Naziv je obavezan.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adresa',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Adresa je obavezna.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _loadingCities
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<int>(
                              initialValue: _cityId,
                              decoration: const InputDecoration(
                                labelText: 'Grad',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Odaberite grad'),
                              items: [
                                for (final c in _cities)
                                  DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _cityId = v),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
