import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/app_notification.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storageService;

  NotificationProvider(this._apiClient, this._storageService);

  int unreadCount = 0;
  List<AppNotification> notifications = [];

  HubConnection? _connection;
  bool _connecting = false;

  Future<void> init() async {
    await refreshUnreadCount();
    await _connect();
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount = await NotificationService(_apiClient).getUnreadCount();
      notifyListeners();
    } catch (_) {
      // tiho ignoriši - nije kritično za rad aplikacije
    }
  }

  Future<void> refreshList() async {
    try {
      notifications = await NotificationService(_apiClient).getMy();
      notifyListeners();
    } catch (_) {
      // tiho ignoriši
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await NotificationService(_apiClient).markAsRead(id);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !notifications[index].isRead) {
        unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
      }
      await refreshList();
      notifyListeners();
    } catch (_) {
      // tiho ignoriši
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationService(_apiClient).markAllAsRead();
      unreadCount = 0;
      await refreshList();
      notifyListeners();
    } catch (_) {
      // tiho ignoriši
    }
  }

  Future<void> _connect() async {
    if (_connecting || _connection != null) return;
    _connecting = true;

    try {
      final token = await _storageService.getAccessToken();
      if (token == null) return;

      final hubUrl = '${ApiConfig.baseUrl}/hubs/notifications';

      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _connection!.on('ReceiveNotification', (arguments) {
        unreadCount += 1;
        refreshList();
        notifyListeners();
      });

      await _connection!.start();
    } catch (_) {
      // ako konekcija ne uspije (npr. backend nije dostupan), aplikacija i dalje radi,
      // samo bez real-time notifikacija - refreshUnreadCount se i dalje može pozvati ručno
      _connection = null;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
    unreadCount = 0;
    notifications = [];
  }
}
