import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/activity.dart';
import '../../models/activity_type_option.dart';
import '../../models/category_option.dart';
import '../../models/location_option.dart';
import '../../services/activity_service.dart';
import '../../services/activity_type_service.dart';
import '../../services/api_client.dart';
import '../../services/category_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/location_service.dart';
import 'location_picker_screen.dart';

class ActivityFormScreen extends StatefulWidget {
  final Activity? activity;

  const ActivityFormScreen({super.key, this.activity});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _capacityController;
  late final TextEditingController _priceController;

  int? _categoryId;
  int? _activityTypeId;
  int? _locationId;
  DateTime? _dateTime;
  bool _isFree = true;
  String? _imageUrl;
  bool _uploadingImage = false;

  List<CategoryOption> _categories = [];
  List<ActivityTypeOption> _activityTypes = [];
  List<LocationOption> _locations = [];
  bool _loadingReferenceData = true;
  bool _isSaving = false;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _nameController = TextEditingController(text: a?.name ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _capacityController = TextEditingController(
      text: a != null ? a.capacity.toString() : '',
    );
    _priceController = TextEditingController(
      text: a?.price != null ? a!.price!.toStringAsFixed(0) : '',
    );
    _categoryId = a?.categoryId;
    _activityTypeId = a?.activityTypeId;
    _locationId = a?.locationId;
    _dateTime = a?.dateTime;
    _isFree = a?.isFree ?? true;
    _imageUrl = a?.imageUrl;
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    final apiClient = context.read<ApiClient>();
    try {
      final categories = await CategoryService(apiClient).getAll();
      final activityTypes = await ActivityTypeService(apiClient).getAll();
      final locations = await LocationService(apiClient).getAll();
      setState(() {
        _categories = categories;
        _activityTypes = activityTypes;
        _locations = locations;
        _loadingReferenceData = false;
      });
    } catch (_) {
      setState(() => _loadingReferenceData = false);
    }
  }

  static const _newLocationSentinel = -1;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      final apiClient = context.read<ApiClient>();
      final url = await FileUploadService(apiClient).uploadImage(
        filePath: picked.path,
        type: 'activity',
      );
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

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationOption>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _locations = [..._locations, result];
      _locationId = result.id;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final firstDate = now;
    final suggested = _dateTime ?? now.add(const Duration(days: 1));
    final initialDate = suggested.isBefore(firstDate) ? firstDate : suggested;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dateTime != null
          ? TimeOfDay.fromDateTime(_dateTime!)
          : const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null || _activityTypeId == null || _locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Odaberite kategoriju, tip aktivnosti i lokaciju.'),
        ),
      );
      return;
    }
    if (_dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite datum i vrijeme aktivnosti.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final apiClient = context.read<ApiClient>();
      final service = ActivityService(apiClient);
      final price = _isFree
          ? null
          : double.tryParse(_priceController.text.replaceAll(',', '.'));

      if (_isEditing) {
        await service.update(
          widget.activity!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _categoryId!,
          activityTypeId: _activityTypeId!,
          locationId: _locationId!,
          dateTime: _dateTime!,
          capacity: int.parse(_capacityController.text),
          isFree: _isFree,
          price: price,
          imageUrl: _imageUrl,
        );
      } else {
        await service.create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _categoryId!,
          activityTypeId: _activityTypeId!,
          locationId: _locationId!,
          dateTime: _dateTime!,
          capacity: int.parse(_capacityController.text),
          isFree: _isFree,
          price: price,
          imageUrl: _imageUrl,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      String message = 'Čuvanje nije uspjelo.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
        title: Text(_isEditing ? 'Uredi aktivnost' : 'Nova aktivnost'),
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
        child: _loadingReferenceData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
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
                        hint: const Text('Odaberite kategoriju'),
                        items: [
                          for (final c in _categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) => v == null ? 'Obavezno polje.' : null,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tip aktivnosti',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _activityTypeId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Odaberite tip'),
                        items: [
                          for (final t in _activityTypes)
                            DropdownMenuItem(value: t.id, child: Text(t.name)),
                        ],
                        onChanged: (v) => setState(() => _activityTypeId = v),
                        validator: (v) => v == null ? 'Obavezno polje.' : null,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Lokacija',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _locationId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Odaberite lokaciju'),
                        items: [
                          for (final l in _locations)
                            DropdownMenuItem(value: l.id, child: Text(l.label)),
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
                        validator: (v) => v == null ? 'Obavezno polje.' : null,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Datum i vrijeme',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDateTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _dateTime == null
                                ? 'Odaberite datum i vrijeme'
                                : '${_dateTime!.day.toString().padLeft(2, '0')}.${_dateTime!.month.toString().padLeft(2, '0')}.${_dateTime!.year}. ${_dateTime!.hour.toString().padLeft(2, '0')}:${_dateTime!.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
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
                            return 'Unesite validan broj mjesta.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isFree = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isFree
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: _isFree
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Besplatno',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isFree
                                        ? Colors.green.shade800
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isFree = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isFree
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.grey.shade100,
                                  border: Border.all(
                                    color: !_isFree
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Premium',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isFree
                                        ? Colors.green.shade800
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!_isFree) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Cijena (EUR)',
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
                            final n = double.tryParse(
                              (v ?? '').replaceAll(',', '.'),
                            );
                            if (n == null || n <= 0)
                              return 'Unesite validnu cijenu.';
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
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
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
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Dodaj sliku',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiConfig.resolveImageUrl(_imageUrl)!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 160,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
