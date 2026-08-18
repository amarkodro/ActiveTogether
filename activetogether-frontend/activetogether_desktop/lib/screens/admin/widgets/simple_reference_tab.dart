import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/reference_option.dart';
import '../../../services/api_client.dart';
import '../../../services/simple_crud_service.dart';
import '../../../theme/app_colors.dart';

class SimpleReferenceTab extends StatefulWidget {
  final String endpoint;
  final String title;
  final String singularLabel;

  const SimpleReferenceTab({
    super.key,
    required this.endpoint,
    required this.title,
    required this.singularLabel,
  });

  @override
  State<SimpleReferenceTab> createState() => _SimpleReferenceTabState();
}

class _SimpleReferenceTabState extends State<SimpleReferenceTab> {
  late Future<List<ReferenceOption>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ReferenceOption>> _load() {
    final apiClient = context.read<ApiClient>();
    return SimpleCrudService(apiClient, widget.endpoint).getAll();
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

  Future<void> _showEditor({ReferenceOption? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? 'Novi/a ${widget.singularLabel}'
                : 'Uređivanje — ${widget.singularLabel}',
          ),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Naziv',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Naziv je obavezan.'
                        : null,
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
                final apiClient = context.read<ApiClient>();
                final service = SimpleCrudService(apiClient, widget.endpoint);
                try {
                  if (existing == null) {
                    await service.create(controller.text.trim());
                  } else {
                    await service.update(existing.id, controller.text.trim());
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

  Future<void> _delete(ReferenceOption item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje'),
        content: Text('Da li ste sigurni da želite obrisati "${item.name}"?'),
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
      await SimpleCrudService(apiClient, widget.endpoint).delete(item.id);
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
              label: Text('Dodaj — ${widget.singularLabel}'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ReferenceOption>>(
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
