import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/city_option.dart';
import '../../../models/paged_result.dart';
import '../../../models/reference_option.dart';
import '../../../services/api_client.dart';
import '../../../services/city_service.dart';
import '../../../services/simple_crud_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pagination_bar.dart';

class CitiesTab extends StatefulWidget {
  const CitiesTab({super.key});

  @override
  State<CitiesTab> createState() => _CitiesTabState();
}

class _CitiesTabState extends State<CitiesTab> {
  late Future<PagedResult<CityOption>> _future;
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

  Future<PagedResult<CityOption>> _load() {
    final apiClient = context.read<ApiClient>();
    return CityService(apiClient).getPaged(
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

  Future<void> _showEditor({CityOption? existing}) async {
    final apiClient = context.read<ApiClient>();
    List<ReferenceOption> countries = [];
    try {
      countries = await SimpleCrudService(apiClient, 'Countries').getAll();
    } catch (_) {}

    if (!mounted) return;

    final nameController = TextEditingController(text: existing?.name ?? '');
    int? countryId =
        existing?.countryId ??
        (countries.isNotEmpty ? countries.first.id : null);
    final formKey = GlobalKey<FormState>();
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Novi grad' : 'Uređivanje grada'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
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
                    'Država',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: countryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in countries)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setDialogState(() => countryId = v),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (countryId == null) {
                  setDialogState(() => errorMessage = 'Država je obavezna.');
                  return;
                }
                final service = CityService(apiClient);
                try {
                  if (existing == null) {
                    await service.create(
                      nameController.text.trim(),
                      countryId!,
                    );
                  } else {
                    await service.update(
                      existing.id,
                      nameController.text.trim(),
                      countryId!,
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

  Future<void> _delete(CityOption item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje'),
        content: Text(
          'Da li ste sigurni da želite obrisati grad "${item.name}"?',
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
      await CityService(apiClient).delete(item.id);
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
                    hintText: 'Pretraga po nazivu grada...',
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
                label: const Text('Dodaj grad'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<PagedResult<CityOption>>(
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
                              item.countryName ?? '',
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
