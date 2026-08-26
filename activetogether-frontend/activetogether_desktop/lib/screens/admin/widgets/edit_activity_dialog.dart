import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../models/activity_list_item.dart';
import '../../../models/location_option.dart';
import '../../../models/reference_option.dart';
import '../../../services/activity_service.dart';
import '../../../services/api_client.dart';
import '../../../services/file_upload_service.dart';
import '../../../services/reference_data_service.dart';
import '../../../widgets/location_picker_dialog.dart';

class EditActivityDialog extends StatefulWidget {
  final ActivityListItem activity;

  const EditActivityDialog({super.key, required this.activity});

  @override
  State<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<EditActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _capacityController;
  late final TextEditingController _priceController;

  int? _categoryId;
  int? _activityTypeId;
  int? _locationId;
  late DateTime _date;
  late TimeOfDay _time;
  late bool _isFree;
  String? _imageUrl;
  bool _uploadingImage = false;

  List<ReferenceOption> _categories = [];
  List<ReferenceOption> _activityTypes = [];
  List<LocationOption> _locations = [];

  bool _loadingOptions = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _nameController = TextEditingController(text: a.name);
    _descriptionController = TextEditingController(text: a.description);
    _capacityController = TextEditingController(text: a.capacity.toString());
    _priceController = TextEditingController(
      text: a.price?.toStringAsFixed(2) ?? '',
    );
    _imageUrl = a.imageUrl;
    _categoryId = a.categoryId;
    _activityTypeId = a.activityTypeId;
    _locationId = a.locationId;
    _date = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
    _time = TimeOfDay(hour: a.dateTime.hour, minute: a.dateTime.minute);
    _isFree = a.isFree;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final apiClient = context.read<ApiClient>();
    final service = ReferenceDataService(apiClient);
    try {
      final results = await Future.wait([
        service.getCategories(),
        service.getActivityTypes(),
        service.getLocations(),
      ]);
      setState(() {
        _categories = results[0] as List<ReferenceOption>;
        _activityTypes = results[1] as List<ReferenceOption>;
        _locations = results[2] as List<LocationOption>;
        _loadingOptions = false;
      });
    } catch (_) {
      setState(() => _loadingOptions = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  static const _newLocationSentinel = -1;

  Future<void> _openLocationPicker() async {
    final created = await showDialog<LocationOption>(
      context: context,
      builder: (_) => const LocationPickerDialog(),
    );
    if (created == null || !mounted) return;
    setState(() {
      _locations = [..._locations, created];
      _locationId = created.id;
    });
  }

  Future<void> _pickImage() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Slike',
          extensions: ['jpg', 'jpeg', 'png', 'webp'],
        ),
      ],
    );
    if (file == null || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      final apiClient = context.read<ApiClient>();
      final url = await FileUploadService(
        apiClient,
      ).uploadImage(filePath: file.path, type: 'activity');
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Otpremanje slike nije uspjelo.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _activityTypeId == null || _locationId == null) {
      setState(
        () => _errorMessage = 'Kategorija, vrsta i lokacija su obavezni.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    try {
      final apiClient = context.read<ApiClient>();
      await ActivityService(apiClient).update(
        widget.activity.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _categoryId!,
        activityTypeId: _activityTypeId!,
        locationId: _locationId!,
        dateTime: dateTime,
        capacity: int.parse(_capacityController.text.trim()),
        isFree: _isFree,
        price: _isFree ? null : double.tryParse(_priceController.text.trim()),
        imageUrl: _imageUrl,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage =
            'Došlo je do greške prilikom čuvanja. Provjerite podatke i pokušajte ponovo.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Uređivanje aktivnosti'),
      content: SizedBox(
        width: 460,
        child: _loadingOptions
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
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
                        'Opis',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Opis je obavezan.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Kategorija',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final c in _categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Vrsta aktivnosti',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _activityTypeId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final t in _activityTypes)
                            DropdownMenuItem(value: t.id, child: Text(t.name)),
                        ],
                        onChanged: (v) => setState(() => _activityTypeId = v),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Lokacija',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _locationId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final l in _locations)
                            DropdownMenuItem(
                              value: l.id,
                              child: Text(
                                l.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const DropdownMenuItem(
                            value: _newLocationSentinel,
                            child: Text(
                              '+ Nova lokacija (označi na mapi)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == _newLocationSentinel) {
                            _openLocationPicker();
                            return;
                          }
                          setState(() => _locationId = v);
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                DateFormat('dd.MM.yyyy.').format(_date),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time, size: 16),
                              label: Text(_time.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Kapacitet',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0)
                            return 'Unesite ispravan kapacitet.';
                          if (n < widget.activity.reservedCount) {
                            return 'Kapacitet ne može biti manji od broja prijavljenih (${widget.activity.reservedCount}).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Besplatna aktivnost'),
                        value: _isFree,
                        onChanged: (v) => setState(() => _isFree = v ?? true),
                      ),
                      if (!_isFree) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Cijena (KM)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (_isFree) return null;
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0)
                              return 'Unesite ispravnu cijenu.';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Text(
                        'Slika aktivnosti (opciono)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _uploadingImage ? null : _pickImage,
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _uploadingImage
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _imageUrl == null
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 28,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Odaberi sliku',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    ApiConfig.resolveImageUrl(_imageUrl)!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 140,
                                  ),
                                ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: (_saving || _loadingOptions) ? null : _save,
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
