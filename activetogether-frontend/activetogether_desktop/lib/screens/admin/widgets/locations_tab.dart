import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/city_option.dart';
import '../../../models/location_option.dart';
import '../../../services/api_client.dart';
import '../../../services/city_service.dart';
import '../../../services/location_service.dart';
import '../../../theme/app_colors.dart';

class LocationsTab extends StatefulWidget {
  const LocationsTab({super.key});

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  late Future<List<LocationOption>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LocationOption>> _load() {
    final apiClient = context.read<ApiClient>();
    return LocationService(apiClient).getAll();
  }

  void _refresh() => setState(() => _future = _load());

  String _errorText(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null)
        return data['message'].toString();
    }
    return 'Došlo je do greške. Pokušajte ponovo.';
  }

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
    final latController = TextEditingController(
      text: existing?.latitude.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: existing?.longitude.toString() ?? '',
    );
    int? cityId =
        existing?.cityId ?? (cities.isNotEmpty ? cities.first.id : null);
    final formKey = GlobalKey<FormState>();
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Nova lokacija' : 'Uređivanje lokacije',
          ),
          content: SizedBox(
            width: 380,
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: latController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'Neispravna vrijednost.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: lngController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'Neispravna vrijednost.'
                                : null,
                          ),
                        ),
                      ],
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
                      latitude: double.parse(latController.text.trim()),
                      longitude: double.parse(lngController.text.trim()),
                    );
                  } else {
                    await service.update(
                      existing.id,
                      name: nameController.text.trim(),
                      address: addressController.text.trim(),
                      cityId: cityId!,
                      latitude: double.parse(latController.text.trim()),
                      longitude: double.parse(lngController.text.trim()),
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
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showEditor(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj lokaciju'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<LocationOption>>(
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

                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nema podataka.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
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
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showEditor(existing: item),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
