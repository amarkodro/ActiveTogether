import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/user_shell_screen.dart';
import 'screens/organizer/organizer_shell_screen.dart';
import 'providers/notification_provider.dart';

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => StorageService()),
        ProxyProvider<StorageService, ApiClient>(
          update: (_, storageService, _) => ApiClient(storageService),
        ),
        ProxyProvider2<ApiClient, StorageService, AuthService>(
          update: (_, apiClient, storageService, _) =>
              AuthService(apiClient, storageService),
        ),
        ChangeNotifierProxyProvider2<AuthService, StorageService, AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<StorageService>(),
          )..tryAutoLogin(),
          update: (_, authService, storageService, previous) =>
              previous ?? AuthProvider(authService, storageService),
        ),
        ChangeNotifierProxyProvider2<
          ApiClient,
          StorageService,
          NotificationProvider
        >(
          create: (context) => NotificationProvider(
            context.read<ApiClient>(),
            context.read<StorageService>(),
          ),
          update: (_, apiClient, storageService, previous) =>
              previous ?? NotificationProvider(apiClient, storageService),
        ),
      ],
      child: MaterialApp(
        title: 'ActiveTogether',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        if (authProvider.currentUser?.role == 'Korisnik') {
          return const UserShellScreen();
        }
        if (authProvider.currentUser?.role == 'Organizator') {
          return const OrganizerShellScreen();
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('ActiveTogether'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
          body: Center(
            child: Text(
              'Dobrodošli, ${authProvider.currentUser?.fullName ?? ''}! (Organizator dio dolazi uskoro)',
            ),
          ),
        );
    }
  }
}
