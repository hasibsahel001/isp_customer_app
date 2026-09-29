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
  await service.connect(
      gatewayIp, app_config.RouterConfig.apiPort, creds['username']!, creds['password']!);
  return service;
}

class _Flow {
  final String src;
  final String dst;
  final double bits;
  final DateTime time;
  _Flow(this.src, this.dst, this.bits, this.time);
}

class ManagementController extends AsyncNotifier<ManagementSnapshot> {
  RouterService? _live;
  RouterService? _cmd;

  StreamSubscription? _totalSub;
  StreamSubscription? _torchSub;
  Timer? _listTimer;
  Timer? _uiTimer;

  String _iface = 'ether1';
  double _totalDown = 0;
  double _totalUp = 0;

  List<OnlineDevice> _devices = [];
  Map<String, int> _limits = {};

  final Map<String, _Flow> _flows = {};

  @override
  Future<ManagementSnapshot> build() async {
    ref.onDispose(_dispose);

    _cmd = await connectToCustomerRouter();
    _live = await connectToCustomerRouter();
    _iface = await _cmd!.detectDhcpInterface();

    await _refreshList();
    _startStreams();

    _listTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshList());
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
      final src = e['src-address'];
      final dst = e['dst-address'];
      if (src == null || dst == null || src.isEmpty || dst.isEmpty) return;
      final tx = double.tryParse(e['tx'] ?? '0') ?? 0;
      final rx = double.tryParse(e['rx'] ?? '0') ?? 0;
      _flows['$src>$dst'] = _Flow(src, dst, tx + rx, DateTime.now());
    }, onError: (_) {});
  }

  Future<void> _refreshList() async {
    try {
      final devices = await _cmd!.getOnlineDevices();
      final limits = await _cmd!.getLimitKbps();
      _devices = devices;
      _limits = limits;
    } catch (_) {}
  }

  ManagementSnapshot _buildSnapshot() {
    final now = DateTime.now();
    _flows.removeWhere((_, f) => now.difference(f.time).inMilliseconds > 3000);

    final down = <String, double>{};
    final up = <String, double>{};
    for (final f in _flows.values) {
      down[f.dst] = (down[f.dst] ?? 0) + f.bits;
      up[f.src] = (up[f.src] ?? 0) + f.bits;
    }

    final list = _devices.map((d) {
      final kbps = _limits[d.ipAddress] ?? 0;
      final status = kbps == 0
          ? DeviceLimitStatus.normal
          : (kbps <= 1 ? DeviceLimitStatus.blocked : DeviceLimitStatus.limited);
      return ManagedDevice(
        device: d,
        limitStatus: status,
        limitDownloadKbps: kbps,
        currentDownloadKbps: (down[d.ipAddress] ?? 0) / 1000,
        currentUploadKbps: (up[d.ipAddress] ?? 0) / 1000,
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