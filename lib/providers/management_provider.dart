import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/managed_device.dart';
import '../services/router_service.dart';
import '../services/wifi_helper.dart';
import '../services/secure_storage_service.dart';
import '../config/router_config.dart' as app_config;

class ManagementSnapshot {
  final double totalDownKbps;
  final double totalUpKbps;
  final List<ManagedDevice> devices;

  ManagementSnapshot({
    required this.totalDownKbps,
    required this.totalUpKbps,
    required this.devices,
  });
}

Future<RouterService> connectToCustomerRouter() async {
  final creds = await SecureStorageService.getRouterCredentials();
  if (creds == null) {
    throw Exception('اطلاعات روتر یافت نشد، لطفاً دوباره وارد شوید');
  }
  final isWifi = await WifiHelper.isConnectedToWifi();
  if (!isWifi) {
    throw Exception('برای مدیریت دستگاه‌ها باید به وای‌فای روتر خود وصل باشید');
  }
  final gatewayIp = await WifiHelper.getGatewayIp();
  if (gatewayIp == null) {
    throw Exception('آدرس روتر یافت نشد');
  }
  final service = RouterService();
  await service.connect(gatewayIp, app_config.RouterConfig.apiPort, creds['username']!, creds['password']!);
  return service;
}

class ManagementController extends AsyncNotifier<ManagementSnapshot> {
  // سوکت ۱: فقط استریم‌های زنده
  RouterService? _live;
  // سوکت ۲: دستورات معمولی (لیست دستگاه‌ها، اکشن‌ها)
  RouterService? _cmd;

  StreamSubscription? _totalSub;
  StreamSubscription? _torchSub;
  Timer? _listTimer;
  Timer? _uiTimer;

  String _iface = 'ether1';

  double _totalDown = 0;
  double _totalUp = 0;

  List<OnlineDevice> _devices = [];
  Map<String, DeviceLimitStatus> _limits = {};

  // مجموع نرخ هر IP در پنجرهٔ فعلی torch
  final Map<String, double> _downAcc = {};
  final Map<String, double> _upAcc = {};
  // آخرین مقدار نمایش‌داده‌شده (تا بین دو بروزرسانی صفر نشود)
  Map<String, double> _downShown = {};
  Map<String, double> _upShown = {};
  DateTime _lastTorchFlush = DateTime.now();

  @override
  Future<ManagementSnapshot> build() async {
    ref.onDispose(_dispose);

    _cmd = await connectToCustomerRouter();
    _live = await connectToCustomerRouter();

    _iface = await _cmd!.detectDhcpInterface();

    await _refreshList();

    _startStreams();

    // لیست دستگاه‌ها هر ۱۰ ثانیه؛ خطا لیست قبلی را پاک نمی‌کند
    _listTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshList());

    // رندر UI هر ۵۰۰ms از آخرین داده‌های زنده
    _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _emit());

    return _buildSnapshot();
  }

  void _dispose() {
    _totalSub?.cancel();
    _torchSub?.cancel();
    _listTimer?.cancel();
    _uiTimer?.cancel();
    _live?.close();
    _cmd?.close();
  }

  void _startStreams() {
    _totalSub = _live!.totalTrafficStream(_iface).listen((d) {
      _totalDown = d['rxKbps'] ?? 0;
      _totalUp = d['txKbps'] ?? 0;
    }, onError: (_) {});

    _torchSub = _live!.torchStream(_iface).listen((e) {
      // torch هر ثانیه برای هر جریان یک رکورد می‌فرستد
      final now = DateTime.now();
      if (now.difference(_lastTorchFlush).inMilliseconds > 1500) {
        // شروع پنجرهٔ جدید: مقدار قبلی را به‌عنوان نمایش نهایی بردار
        _downShown = Map.of(_downAcc);
        _upShown = Map.of(_upAcc);
        _downAcc.clear();
        _upAcc.clear();
        _lastTorchFlush = now;
      }

      final src = e['src-address'];
      final dst = e['dst-address'];
      final tx = double.tryParse(e['tx'] ?? e['tx-rate'] ?? '0') ?? 0;
      final rx = double.tryParse(e['rx'] ?? e['rx-rate'] ?? '0') ?? 0;

      if (src != null && src.isNotEmpty) {
        _upAcc[src] = (_upAcc[src] ?? 0) + tx;
      }
      if (dst != null && dst.isNotEmpty) {
        _downAcc[dst] = (_downAcc[dst] ?? 0) + rx;
      }
      // نمایش زنده: بیشینهٔ مقدار جاری و پنجرهٔ قبل
      _downShown = {..._downShown, ..._downAcc};
      _upShown = {..._upShown, ..._upAcc};
    }, onError: (_) {});
  }

  Future<void> _refreshList() async {
    try {
      final devices = await _cmd!.getOnlineDevices();
      final limits = await _cmd!.getLimitStatuses();
      _devices = devices;
      _limits = limits;
    } catch (_) {
      // لیست قبلی حفظ می‌شود
    }
  }

  ManagementSnapshot _buildSnapshot() {
    final list = _devices.map((d) {
      return ManagedDevice(
        device: d,
        limitStatus: _limits[d.ipAddress] ?? DeviceLimitStatus.normal,
        limitDownloadKbps: 0,
        currentDownloadKbps: (_downShown[d.ipAddress] ?? 0) / 1000,
        currentUploadKbps: (_upShown[d.ipAddress] ?? 0) / 1000,
      );
    }).toList();

    return ManagementSnapshot(
      totalDownKbps: _totalDown,
      totalUpKbps: _totalUp,
      devices: list,
    );
  }

  void _emit() {
    state = AsyncData(_buildSnapshot());
  }

  Future<void> setHostName(String leaseId, String name) async {
    await _cmd?.setHostName(leaseId, name);
    await _refreshList();
    _emit();
  }

  Future<void> setSpeedLimit(String ip, int kbps) async {
    await _cmd?.setDeviceSpeedLimit(ip, kbps);
    await _refreshList();
    _emit();
  }

  Future<void> blockDevice(String ip) async {
    await _cmd?.blockDevice(ip);
    await _refreshList();
    _emit();
  }

  Future<void> removeLimit(String ip) async {
    await _cmd?.removeLimit(ip);
    await _refreshList();
    _emit();
  }
}

final managementControllerProvider =
AsyncNotifierProvider<ManagementController, ManagementSnapshot>(
  ManagementController.new,
);