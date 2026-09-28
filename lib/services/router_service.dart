import 'dart:async';
import 'mikrotik_api_client.dart';
import '../models/managed_device.dart';

class RouterService {
  final MikrotikApiClient _client = MikrotikApiClient();

  Future<void> connect(String host, int port, String username, String password) async {
    await _client.connect(host, port);
    await _client.login(username, password);
  }

  Future<String?> getPppoeUsername() async {
    final result = await _client.talk(['/interface/pppoe-client/print']);
    if (result.isEmpty) return null;
    for (final iface in result) {
      if (iface['running'] == 'true' && iface['user'] != null) return iface['user'];
    }
    for (final iface in result) {
      if (iface['disabled'] != 'true' && iface['user'] != null) return iface['user'];
    }
    return result.first['user'];
  }

  // اینترفیسی که DHCP server روی آن اجراست (ether1 یا bridge1 و...)
  Future<String> detectDhcpInterface() async {
    final servers = await _client.talk(['/ip/dhcp-server/print']);
    for (final s in servers) {
      if (s['disabled'] != 'true' && (s['interface'] ?? '').isNotEmpty) {
        return s['interface']!;
      }
    }
    if (servers.isNotEmpty && (servers.first['interface'] ?? '').isNotEmpty) {
      return servers.first['interface']!;
    }
    return 'ether1';
  }

  // ---------- استریم‌های زنده ----------

  // سرعت کل: خروجی هر ~۱ ثانیه از خود روتر (بدون once)
  Stream<Map<String, double>> totalTrafficStream(String iface) {
    return _client
        .stream(['/interface/monitor-traffic', '=interface=$iface'])
        .map((d) {
      final rx = double.tryParse(d['rx-bits-per-second'] ?? '0') ?? 0;
      final tx = double.tryParse(d['tx-bits-per-second'] ?? '0') ?? 0;
      return {'rxKbps': rx / 1000, 'txKbps': tx / 1000};
    });
  }

  // سرعت هر گوشی: torch دائمی. هر رکورد یک جریان است.
  Stream<Map<String, String>> torchStream(String iface) {
    return _client.stream([
      '/tool/torch',
      '=interface=$iface',
      '=src-address=0.0.0.0/0',
      '=dst-address=0.0.0.0/0',
    ]);
  }

  // ---------- لیست دستگاه‌ها (کم‌تکرار) ----------

  Future<List<OnlineDevice>> getOnlineDevices() async {
    final arp = await _client.talk(['/ip/arp/print']);
    final online = arp.where((e) => e['dynamic'] == 'true' && e['complete'] == 'true').toList();
    final leases = await _client.talk(['/ip/dhcp-server/lease/print']);

    final leaseMap = <String, Map<String, String>>{};
    for (final l in leases) {
      final mac = (l['mac-address'] ?? '').toUpperCase();
      if (mac.isNotEmpty) leaseMap[mac] = l;
    }

    return online.map((entry) {
      final ip = entry['address'] ?? '-';
      final mac = (entry['mac-address'] ?? '-').toUpperCase();
      final lease = leaseMap[mac];
      final comment = lease?['comment'];
      final host = lease?['host-name'];
      final name = (comment != null && comment.isNotEmpty)
          ? comment
          : (host != null && host.isNotEmpty ? host : 'دستگاه ناشناس');
      return OnlineDevice(ipAddress: ip, macAddress: mac, hostName: name, leaseId: lease?['.id']);
    }).toList();
  }

  // آی‌پی ← سقف دانلود بر حسب Kbps (0 یعنی بدون محدودیت)
  Future<Map<String, int>> getLimitKbps() async {
    final queues = await _client.talk(['/queue/simple/print']);
    final result = <String, int>{};
    for (final q in queues) {
      final target = (q['target'] ?? '').split('/').first;
      if (target.isEmpty) continue;
      final parts = (q['max-limit'] ?? '').split('/');
      final dl = parts.length > 1 ? parts[1] : (parts.isNotEmpty ? parts[0] : '0');
      result[target] = _parseRate(dl);
    }
    return result;
  }

  // max-limit ممکن است 512k یا 2M یا عدد خام (بیت) باشد
  int _parseRate(String s) {
    s = s.trim();
    if (s.isEmpty) return 0;
    final m = RegExp(r'^(\d+(?:\.\d+)?)([kKmMgG]?)$').firstMatch(s);
    if (m == null) return 0;
    final v = double.parse(m.group(1)!);
    switch (m.group(2)!.toLowerCase()) {
      case 'k':
        return v.round();
      case 'm':
        return (v * 1024).round();
      case 'g':
        return (v * 1024 * 1024).round();
      default:
        return (v / 1000).round();
    }
  }

  // ---------- اکشن‌ها ----------

  Future<Map<String, String>?> _findQueueByIp(String ip) async {
    final queues = await _client.talk(['/queue/simple/print']);
    for (final q in queues) {
      if ((q['target'] ?? '').startsWith('$ip/')) return q;
    }
    return null;
  }

  Future<void> setDeviceSpeedLimit(String ip, int kbps) async {
    final existing = await _findQueueByIp(ip);
    final limitStr = '${kbps}k/${kbps}k';
    if (existing != null) {
      await _client.talk(['/queue/simple/set', '=numbers=${existing['.id']}', '=max-limit=$limitStr']);
    } else {
      await _client.talk([
        '/queue/simple/add',
        '=name=app-${ip.replaceAll('.', '_')}',
        '=target=$ip/32',
        '=max-limit=$limitStr',
      ]);
    }
  }

  Future<void> blockDevice(String ip) => setDeviceSpeedLimit(ip, 1);

  Future<void> removeLimit(String ip) async {
    final existing = await _findQueueByIp(ip);
    if (existing != null) {
      await _client.talk(['/queue/simple/remove', '=numbers=${existing['.id']}']);
    }
  }

  Future<void> setHostName(String leaseId, String newName) async {
    await _client.talk(['/ip/dhcp-server/lease/set', '=numbers=$leaseId', '=comment=$newName']);
  }

  Future<void> close() => _client.close();
}