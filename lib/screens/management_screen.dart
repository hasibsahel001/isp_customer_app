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
        const SizedBox(height: 22),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 26,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.speed_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('سرعت لحظه‌ای کل شبکه',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFF34D399), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('زنده',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _speedStat(
                        icon: Icons.arrow_downward_rounded,
                        label: 'دانلود',
                        value: formatSpeed(snapshot.totalDownKbps),
                      ),
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
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
        Text(value,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _deviceRow(BuildContext context, ManagedDevice d) {
    final isBlocked = d.limitStatus == DeviceLimitStatus.blocked;
    final isLimited = d.limitStatus == DeviceLimitStatus.limited;
    final hasRestriction = isBlocked || isLimited;

    final accent = hasRestriction ? AppColors.danger : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration:
        AppDecor.card(borderColor: hasRestriction ? AppColors.danger : null),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DeviceDetailScreen(
                  deviceIp: d.device.ipAddress,
                  initialDevice: d,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isBlocked ? Icons.block_rounded : Icons.smartphone_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.device.hostName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d.device.ipAddress,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _rateChip(
                        Icons.arrow_downward_rounded,
                        formatSpeed(d.currentDownloadKbps),
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _rateChip(
                        Icons.arrow_upward_rounded,
                        formatSpeed(d.currentUploadKbps),
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                if (hasRestriction) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(isBlocked ? Icons.block_rounded : Icons.speed_rounded,
                            size: 16, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Text(
                          isBlocked
                              ? 'این دستگاه بلاک شده است'
                              : 'محدودیت سرعت: ${formatLimit(d.limitDownloadKbps)}',
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rateChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(value,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}