import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/organizer_dashboard_stats.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_client.dart';
import '../services/dashboard_service.dart';
import '../services/file_upload_service.dart';
import '../services/organizer_request_service.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Profile> _profileFuture;
  Future<OrganizerDashboardStats>? _organizerStatsFuture;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _load();
    context.read<NotificationProvider>().init();
  }

  Future<Profile> _load() async {
    final apiClient = context.read<ApiClient>();
    final profile = await ProfileService(apiClient).getMy();
    if (profile.role == 'Organizator') {
      _organizerStatsFuture = DashboardService(apiClient).getOrganizerDashboard();
    }
    return profile;
  }

  void _refresh() {
    setState(() {
      _profileFuture = _load();
    });
  }

  Future<void> _pickAvatar(Profile profile) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final apiClient = context.read<ApiClient>();
      final url = await FileUploadService(apiClient).uploadImage(
        filePath: picked.path,
        type: 'profile',
      );
      await ProfileService(apiClient).update(
        firstName: profile.firstName,
        lastName: profile.lastName,
        phoneNumber: profile.phoneNumber,
        cityId: profile.cityId,
        profileImageUrl: url,
      );
      if (!mounted) return;
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Otpremanje slike nije uspjelo.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _becomeOrganizer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Postani organizator'),
        content: const Text(
          'Poslat ćeš zahtjev administratoru za dodjelu organizatorske uloge. Nastaviti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pošalji zahtjev'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiClient = context.read<ApiClient>();
      await OrganizerRequestService(apiClient).create();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zahtjev je poslan. Čeka odobrenje administratora.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slanje zahtjeva nije uspjelo.')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li sigurno želiš da se odjaviš?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Odjavi se', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: FutureBuilder<Profile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Greška: ${snapshot.error}'));
            }

            final profile = snapshot.data!;

            return ListView(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploadingAvatar
                            ? null
                            : () => _pickAvatar(profile),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  ApiConfig.resolveImageUrl(
                                        profile.profileImageUrl,
                                      ) !=
                                      null
                                  ? NetworkImage(
                                      ApiConfig.resolveImageUrl(
                                        profile.profileImageUrl,
                                      )!,
                                    )
                                  : null,
                              child:
                                  _uploadingAvatar ||
                                      ApiConfig.resolveImageUrl(
                                            profile.profileImageUrl,
                                          ) !=
                                          null
                                  ? (_uploadingAvatar
                                        ? const CircularProgressIndicator()
                                        : null)
                                  : Text(
                                      profile.initials,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E3A8A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.roleColor(profile.role),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          profile.role,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: profile.role == 'Organizator'
                      ? FutureBuilder<OrganizerDashboardStats>(
                          future: _organizerStatsFuture,
                          builder: (context, statsSnapshot) {
                            final stats = statsSnapshot.data;
                            return Row(
                              children: [
                                _statCard(
                                  '${stats?.activeActivitiesCount ?? '-'}',
                                  'Aktivnosti',
                                ),
                                const SizedBox(width: 10),
                                _statCard(
                                  '${stats?.totalParticipants ?? '-'}',
                                  'Učesnika',
                                ),
                                const SizedBox(width: 10),
                                _statCard(
                                  stats != null
                                      ? stats.averageRating.toStringAsFixed(1)
                                      : '-',
                                  'Prosj. ocjena',
                                ),
                              ],
                            );
                          },
                        )
                      : Row(
                          children: [
                            _statCard(
                              '${profile.totalReservations}',
                              'Rezervacija',
                            ),
                            const SizedBox(width: 10),
                            _statCard(
                              '${profile.completedActivitiesCount}',
                              'Završeno',
                            ),
                            const SizedBox(width: 10),
                            _statCard(
                              profile.averageRatingGiven?.toStringAsFixed(1) ??
                                  '-',
                              'Prosj. ocjena',
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 6),
                _menuItem(Icons.person_outline, 'Lični podaci', () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: profile),
                    ),
                  );
                  if (changed == true) _refresh();
                }),
                Consumer<NotificationProvider>(
                  builder: (context, notif, _) => ListTile(
                    leading: const Icon(
                      Icons.notifications_none,
                      color: Colors.black87,
                    ),
                    title: const Text(
                      'Notifikacije',
                      style: TextStyle(color: Colors.black87),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (notif.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${notif.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                _menuItem(
                  Icons.favorite_border,
                  'Omiljene aktivnosti',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
                _menuItem(Icons.lock_outline, 'Promijeni lozinku', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                }),
                if (profile.role == 'Korisnik')
                  _menuItem(
                    Icons.upgrade_outlined,
                    'Postani organizator',
                    _becomeOrganizer,
                  ),
                _menuItem(
                  Icons.logout,
                  'Odjavi se',
                  _logout,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(label, style: TextStyle(color: color ?? Colors.black87)),
      trailing: color == null
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
