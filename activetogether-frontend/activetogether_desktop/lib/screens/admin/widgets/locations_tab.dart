import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import '../../../models/city_option.dart';
import '../../../models/location_option.dart';
import '../../../models/paged_result.dart';
import '../../../services/api_client.dart';
import '../../../services/city_service.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pagination_bar.dart';

class LocationsTab extends StatefulWidget {
  const LocationsTab({super.key});

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  late Future<PagedResult<LocationOption>> _future;
  final _searchController = TextEditingController();
  int _page = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<PagedResult<LocationOption>> _load() {
    final apiClient = context.read<ApiClient>();
    return LocationService(apiClient).getPaged(
      name: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      page: _page,
      pageSize: _pageSize,
    );
  }

  void _refresh() => setState(() => _future = _load());

  void _onSearchChanged(String _) {
    setState(() {
      _page = 1;
      _future = _load();
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  String _errorText(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null)
        return data['message'].toString();
    }
    return 'Došlo je do greške. Pokušajte ponovo.';
  }

  static const _defaultMapPosition = latlong.LatLng(
    43.8563,
    18.4131,
  ); // Sarajevo

  Future<void> _showEditor({LocationOption? existing}) async {
    final apiClient = context.read<ApiClient>();
    List<CityOption> cities = [];
    try {
      cities = await CityService(apiClient).getAll();
    } catch (_) {}

    if (!mounted) return;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    int? cityId =
        existing?.cityId ?? (cities.isNotEmpty ? cities.first.id : null);
    final formKey = GlobalKey<FormState>();
    String? errorMessage;
    latlong.LatLng selectedPosition = existing != null
        ? latlong.LatLng(existing.latitude, existing.longitude)
        : _defaultMapPosition;
    final mapController = MapController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Nova lokacija' : 'Uređivanje lokacije',
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
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
                      controller: nameController,
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
                      controller: addressController,
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
                    DropdownButtonFormField<int>(
                      initialValue: cityId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in cities)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setDialogState(() => cityId = v),
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
                              mapController: mapController,
                              options: MapOptions(
                                initialCenter: selectedPosition,
                                initialZoom: 12,
                                onTap: (tapPosition, point) {
                                  setDialogState(() => selectedPosition = point);
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
                                      point: selectedPosition,
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
                                  '${selectedPosition.latitude.toStringAsFixed(5)}, '
                                  '${selectedPosition.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (cityId == null) {
                  setDialogState(() => errorMessage = 'Grad je obavezan.');
                  return;
                }
                final service = LocationService(apiClient);
                try {
                  if (existing == null) {
                    await service.create(
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      cityId: cityId!,
                      latitude: selectedPosition.latitude,
                      longitude: selectedPosition.longitude,
                    );
                  } else {
                    await service.update(
                      existing.id,
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      cityId: cityId!,
                      latitude: selectedPosition.latitude,
                      longitude: selectedPosition.longitude,
                    );
                  }
                  if (dialogContext.mounted)
                    Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  setDialogState(() => errorMessage = _errorText(e));
                }
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _refresh();
  }

  Future<void> _delete(LocationOption item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje'),
        content: Text(
          'Da li ste sigurni da želite obrisati lokaciju "${item.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final apiClient = context.read<ApiClient>();
    try {
      await LocationService(apiClient).delete(item.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pretraga po nazivu ili adresi...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                  ),
                  onSubmitted: _onSearchChanged,
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Dodaj lokaciju'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<PagedResult<LocationOption>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Greška pri učitavanju.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Pokušaj ponovo'),
                        ),
                      ],
                    ),
                  );
                }

                final result = snapshot.data!;
                final items = result.items;
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nema podataka.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.address}, ${item.cityName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showEditor(existing: item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: () => _delete(item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    PaginationBar(
                      page: result.page,
                      totalCount: result.totalCount,
                      pageSize: result.pageSize,
                      onPageChanged: _onPageChanged,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
