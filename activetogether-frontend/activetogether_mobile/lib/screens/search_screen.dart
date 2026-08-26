import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../models/category_option.dart';
import '../models/city_option.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/category_service.dart';
import '../services/city_service.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<CategoryOption> _categories = [];
  List<CityOption> _cities = [];

  int? _selectedCategoryId;
  int? _selectedCityId;
  bool? _selectedIsFree;
  DateTime? _selectedDate;

  List<Activity> _results = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final apiClient = context.read<ApiClient>();
    try {
      final categories = await CategoryService(apiClient).getAll();
      final cities = await CityService(apiClient).getAll();
      setState(() {
        _categories = categories;
        _cities = cities;
      });
    } catch (_) {
      // referentni podaci nisu kritični za pretragu, nastavljamo bez njih ako ne uspiju
    }
    await _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = context.read<ApiClient>();
      final dateFrom = _selectedDate == null
          ? null
          : DateTime(
              _selectedDate!.year,
              _selectedDate!.month,
              _selectedDate!.day,
            );
      final dateTo = dateFrom?.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );
      final results = await ActivityService(apiClient).getAll(
        name: _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        cityId: _selectedCityId,
        isFree: _selectedIsFree,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Greška pri pretrazi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _search();
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    _search();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Pretraga'),
        backgroundColor: const Color(0xFFF4F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Pretraži aktivnosti...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Sve'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = null);
                        _search();
                      },
                      selectedColor: const Color(0xFF1E3A8A),
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == null
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  ..._categories.map((category) {
                    final selected = _selectedCategoryId == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedCategoryId = category.id);
                          _search();
                        },
                        selectedColor: const Color(0xFF1E3A8A),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedCityId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Grad',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Svi gradovi'),
                        ),
                        for (final city in _cities)
                          DropdownMenuItem<int?>(
                            value: city.id,
                            child: Text(city.name),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCityId = value);
                        _search();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      initialValue: _selectedIsFree,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cijena',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<bool?>(
                          value: null,
                          child: Text('Sve'),
                        ),
                        DropdownMenuItem<bool?>(
                          value: true,
                          child: Text('Besplatno'),
                        ),
                        DropdownMenuItem<bool?>(
                          value: false,
                          child: Text('Premium'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedIsFree = value);
                        _search();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _selectedDate == null
                        ? 'Odaberi datum'
                        : DateFormat('dd.MM.yyyy.').format(_selectedDate!),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
            ),
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _clearDate,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Ukloni filter datuma'),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isLoading ? 'Pretraga...' : '${_results.length} rezultata',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _results.isEmpty
                  ? const Center(
                      child: Text('Nema rezultata za odabrane filtere.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final activity = _results[index];
                        return ActivityCard(
                          activity: activity,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailScreen(
                                  activityId: activity.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
