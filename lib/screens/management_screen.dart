import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/managed_device.dart';
import '../providers/management_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import 'device_detail_screen.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(managementControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت شبکه')),
      body: snapshotAsync.when(
        data: (snapshot) => _buildContent(context, snapshot),
        loading: () =>
        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => _buildError(err.toString()),
      ),
    );
  }

  Widget _buildError(String message) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ManagementSnapshot snapshot) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalSpeedCard(snapshot),
        const SizedBox(height: 20),
        Text(
          'دستگاه‌های متصل (${snapshot.devices.length})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (snapshot.devices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('در حال حاضر هیچ دستگاهی آنلاین نیست')),
          )
        else
          ...snapshot.devices.map((d) => _deviceRow(context, d)),
      ],
    );
  }

  Widget _buildTotalSpeedCard(ManagementSnapshot snapshot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.router_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('سرعت لحظه‌ای کل شبکه', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _speedStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'دانلود',
                  value: formatSpeed(snapshot.totalDownKbps),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _speedStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'آپلود',
                  value: formatSpeed(snapshot.totalUpKbps),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _speedStat({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _deviceRow(BuildContext context, ManagedDevice managedDevice) {
    final statusColor = switch (managedDevice.limitStatus) {
      DeviceLimitStatus.normal => AppColors.success,
      DeviceLimitStatus.limited => AppColors.warning,
      DeviceLimitStatus.blocked => AppColors.danger,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(
                deviceIp: managedDevice.device.ipAddress,
                initialDevice: managedDevice,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    managedDevice.device.hostName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    managedDevice.device.ipAddress,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(formatSpeed(managedDevice.currentDownloadKbps),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 2),
                    Text(formatSpeed(managedDevice.currentUploadKbps),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}