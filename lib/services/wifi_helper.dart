import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiHelper {
  static Future<bool> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  static Future<String?> getGatewayIp() async {
    final info = NetworkInfo();
    return await info.getWifiGatewayIP();
  }

  static Future<bool> isConnectedToWifi() async {
    final info = NetworkInfo();
    final wifiIp = await info.getWifiIP();
    return wifiIp != null;
  }
}