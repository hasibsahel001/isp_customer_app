import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/speed_limits.dart';
import '../models/managed_device.dart';
import '../providers/management_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceIp;
  final ManagedDevice initialDevice;

  const DeviceDetailScreen({
    super.key,
    required this.deviceIp,
    required this.initialDevice,
  });

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  late TextEditingController _nameController;
  bool _isBusy = false;
  int? _selectedKbps;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDevice.device.hostName);
    final current = widget.initialDevice.limitDownloadKbps;
    if (current > 1) _selectedKbps = current;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _isBusy = true);
    try {
      await action();
      _showMessage(okMessage);
    } catch (e) {
      _showMessage('خطا: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _saveHostName() async {
    final leaseId = widget.initialDevice.device.leaseId;
    final newName = _nameController.text.trim();
    if (leaseId == null || newName.isEmpty) return;
    await _run(
          () => ref.read(managementControllerProvider.notifier).setHostName(leaseId, newName),
      'نام دستگاه ذخیره شد',
    );
  }

  Future<void> _applyLimit() async {
    final kbps = _selectedKbps;
    if (kbps == null) return;
    await _run(
          () => ref.read(managementControllerProvider.notifier).setSpeedLimit(widget.deviceIp, kbps),
      'محدودیت ${formatLimit(kbps)} اعمال شد',
    );
  }

  Future<void> _blockDevice() async {
    await _run(
          () => ref.read(managementControllerProvider.notifier).blockDevice(widget.deviceIp),
      'دستگاه بلاک شد',
    );
    if (mounted) setState(() => _selectedKbps = null);
  }

  Future<void> _removeLimit() async {
    await _run(
          () => ref.read(managementControllerProvider.notifier).removeLimit(widget.deviceIp),
      'همهٔ محدودیت‌ها حذف شد',
    );
    if (mounted) setState(() => _selectedKbps = null);
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(managementControllerProvider);

    final live = snapshotAsync.maybeWhen(
      data: (s) {
        for (final d in s.devices) {
          if (d.device.ipAddress == widget.deviceIp) return d;
        }
        return widget.initialDevice;
      },
      orElse: () => widget.initialDevice,
    );

    return Scaffold(
      appBar: AppBar(title: Text(live.device.hostName)),
      body: AbsorbPointer(
        absorbing: _isBusy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _buildStatusBanner(live),
            const SizedBox(height: 14),
            _buildHostNameCard(live),
            const SizedBox(height: 14),
            _buildCurrentSpeedRow(live),
            const SizedBox(height: 22),
            _buildLimitPicker(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _removeLimit,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('حذف محدودیت‌ها'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: _isBusy ? null : _blockDevice,
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('بلاک کردن'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ManagedDevice d) {
    final isBlocked = d.limitStatus == DeviceLimitStatus.blocked;
    final isLimited = d.limitStatus == DeviceLimitStatus.limited;
    final restricted = isBlocked || isLimited;
    final color = restricted ? AppColors.danger : AppColors.success;

    final text = isBlocked
        ? 'این دستگاه بلاک شده است'
        : isLimited
        ? 'محدودیت فعلی: ${formatLimit(d.limitDownloadKbps)}'
        : 'بدون محدودیت';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isBlocked
                ? Icons.block_rounded
                : (isLimited ? Icons.speed_rounded : Icons.check_circle_rounded),
            color: color,
          ),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHostNameCard(ManagedDevice d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نام دستگاه',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.edit_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: _isBusy ? null : _saveHostName,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(d.device.ipAddress,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCurrentSpeedRow(ManagedDevice d) {
    return Row(
      children: [
        Expanded(
          child: _speedBox(Icons.arrow_downward_rounded, 'دانلود فعلی',
              formatSpeed(d.currentDownloadKbps), AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _speedBox(Icons.arrow_upward_rounded, 'آپلود فعلی',
              formatSpeed(d.currentUploadKbps), AppColors.secondary),
        ),
      ],
    );
  }

  Widget _speedBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildLimitPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('محدودیت سرعت',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: kSpeedLimitOptions.map((opt) {
              final selected = _selectedKbps == opt.kbps;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedKbps = opt.kbps),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.headerGradient : null,
                    color: selected ? null : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? Colors.transparent : AppColors.border),
                  ),
                  child: Text(
                    formatLimit(opt.kbps),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isBusy || _selectedKbps == null) ? null : _applyLimit,
              icon: _isBusy
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.check_rounded),
              label: Text(_selectedKbps == null
                  ? 'یک سرعت انتخاب کنید'
                  : 'اعمال محدودیت ${formatLimit(_selectedKbps!)}'),
            ),
          ),
        ],
      ),
    );
  }
}