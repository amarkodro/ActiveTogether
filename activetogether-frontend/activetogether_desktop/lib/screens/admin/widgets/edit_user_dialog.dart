import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/city_option.dart';
import '../../../models/user_list_item.dart';
import '../../../services/api_client.dart';
import '../../../services/city_service.dart';
import '../../../services/user_service.dart';

class EditUserDialog extends StatefulWidget {
  final UserListItem user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  int? _selectedCityId;
  List<CityOption> _cities = [];
  bool _loadingCities = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(
      text: widget.user.phoneNumber ?? '',
    );
    _loadCities();
  }

  Future<void> _loadCities() async {
    final apiClient = context.read<ApiClient>();
    try {
      final cities = await CityService(apiClient).getAll();
      final match = cities.where((c) => c.name == widget.user.cityName);
      setState(() {
        _cities = cities;
        _selectedCityId = match.isNotEmpty ? match.first.id : null;
        _loadingCities = false;
      });
    } catch (_) {
      setState(() => _loadingCities = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      await UserService(apiClient).update(
        widget.user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        cityId: _selectedCityId,
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
      title: const Text('Uređivanje korisnika'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ime',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ime je obavezno.'
                      : null,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Prezime',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Prezime je obavezno.'
                      : null,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email je obavezan.';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(v.trim())) {
                      return 'Unesite ispravan email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Telefon (opciono)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(
                      r'^[0-9+()\-\s]{6,30}$',
                    ).hasMatch(v.trim())) {
                      return 'Broj telefona nije u ispravnom formatu.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Grad (opciono)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _loadingCities
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<int?>(
                        initialValue: _selectedCityId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Bez grada'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Bez grada'),
                          ),
                          for (final city in _cities)
                            DropdownMenuItem<int?>(
                              value: city.id,
                              child: Text(city.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCityId = value),
                      ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
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
