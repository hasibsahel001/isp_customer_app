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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildTotalSpeedCard(snapshot),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('دستگاه‌های متصل',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${snapshot.devices.length}',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.speed_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 9),
              const Text('سرعت لحظه‌ای کل شبکه',
                  style: TextStyle(color: Colors.white, fontSize: 12.5)),
              const Spacer(),
              Container(
                  width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('زنده', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _speedStat(Icons.arrow_downward_rounded, 'دانلود',
                    formatSpeed(snapshot.totalUpKbps)),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _speedStat(Icons.arrow_upward_rounded, 'آپلود',
                    formatSpeed(snapshot.totalDownKbps)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _speedStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
          ],
        ),
        const SizedBox(height: 5),
        Text(value,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _deviceRow(BuildContext context, ManagedDevice d) {
    final isBlocked = d.limitStatus == DeviceLimitStatus.blocked;
    final isLimited = d.limitStatus == DeviceLimitStatus.limited;
    final hasRestriction = isBlocked || isLimited;
    final accent = hasRestriction ? AppColors.danger : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: AppDecor.card(borderColor: hasRestriction ? AppColors.danger : null, radius: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DeviceDetailScreen(deviceIp: d.device.ipAddress, initialDevice: d),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isBlocked ? Icons.block_rounded : Icons.smartphone_rounded,
                    color: accent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.device.hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            d.device.ipAddress,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                          if (hasRestriction) ...[
                            const SizedBox(width: 6),
                            Text(
                              isBlocked ? 'بلاک' : formatLimit(d.limitDownloadKbps),
                              style: const TextStyle(
                                  fontSize: 10.5, color: AppColors.danger, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _miniRate(Icons.arrow_downward_rounded, d.currentUploadKbps, AppColors.primary),
                    const SizedBox(height: 3),
                    _miniRate(Icons.arrow_upward_rounded, d.currentDownloadKbps, AppColors.secondary),
                  ],
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniRate(IconData icon, double kbps, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          formatSpeed(kbps),
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}