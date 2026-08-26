import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/paged_result.dart';
import '../../models/user_list_item.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/edit_user_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String? _selectedRole;
  bool? _selectedStatus;
  int _page = 1;
  final int _pageSize = 10;

  late Future<PagedResult<UserListItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PagedResult<UserListItem>> _load() {
    final apiClient = context.read<ApiClient>();
    return UserService(apiClient).getAll(
      name: _searchController.text.trim(),
      role: _selectedRole,
      isActive: _selectedStatus,
      page: _page,
      pageSize: _pageSize,
    );
  }

  void _refresh({bool resetPage = false}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _load();
    });
  }

  Future<void> _editUser(UserListItem user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditUserDialog(user: user),
    );
    if (result == true) _refresh();
  }

  Future<void> _toggleActive(UserListItem user) async {
    if (user.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Blokiranje korisnika'),
          content: Text(
            'Da li ste sigurni da želite blokirati korisnika ${user.fullName}?',
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
              child: const Text('Blokiraj'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final apiClient = context.read<ApiClient>();
    try {
      await UserService(apiClient).setActive(user.id, !user.isActive);
      _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Došlo je do greške. Pokušajte ponovo.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pregled korisnika',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Pretraga po imenu ili prezimenu...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _refresh(resetPage: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: const Text('Sve uloge'),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sve uloge'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Admin',
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Organizator',
                      child: Text('Organizator'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Korisnik',
                      child: Text('Korisnik'),
                    ),
                  ],
                  onChanged: (value) {
                    _selectedRole = value;
                    _refresh(resetPage: true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: const Text('Svi statusi'),
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('Svi statusi'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('Aktivan'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('Suspendovan'),
                    ),
                  ],
                  onChanged: (value) {
                    _selectedStatus = value;
                    _refresh(resetPage: true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _refresh(resetPage: true),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: FutureBuilder<PagedResult<UserListItem>>(
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
                          const Text('Greška pri učitavanju korisnika.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _refresh(),
                            child: const Text('Pokušaj ponovo'),
                          ),
                        ],
                      ),
                    );
                  }

                  final result = snapshot.data!;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              'Ukupno ${result.totalCount} registrovanih korisnika',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildHeaderRow(),
                      const Divider(height: 1),
                      Expanded(
                        child: result.items.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nema rezultata.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: result.items.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) =>
                                    _buildRow(result.items[index]),
                              ),
                      ),
                      const Divider(height: 1),
                      _buildPagination(result),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 40),
          SizedBox(width: 12),
          Expanded(flex: 3, child: Text('KORISNIK', style: style)),
          Expanded(flex: 2, child: Text('ULOGA', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(flex: 2, child: Text('REGISTROVAN', style: style)),
          SizedBox(width: 90, child: Text('AKCIJE', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(UserListItem user) {
    final roleColor = AppColors.roleColor(user.role);
    final statusColor = user.isActive ? AppColors.success : AppColors.danger;
    final statusLabel = user.isActive ? 'Aktivan' : 'Suspendovan';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: roleColor,
            backgroundImage:
                ApiConfig.resolveImageUrl(user.profileImageUrl) != null
                ? NetworkImage(ApiConfig.resolveImageUrl(user.profileImageUrl)!)
                : null,
            child: ApiConfig.resolveImageUrl(user.profileImageUrl) != null
                ? null
                : Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd.MM.yyyy.').format(user.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Uredi',
                  onPressed: () => _editUser(user),
                ),
                IconButton(
                  icon: Icon(
                    user.isActive ? Icons.block : Icons.check_circle_outline,
                    size: 20,
                    color: user.isActive ? AppColors.danger : AppColors.success,
                  ),
                  tooltip: user.isActive ? 'Blokiraj' : 'Aktiviraj',
                  onPressed: () => _toggleActive(user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(PagedResult<UserListItem> result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Stranica $_page od ${result.totalPages}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    _page--;
                    _refresh();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < result.totalPages
                ? () {
                    _page++;
                    _refresh();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
