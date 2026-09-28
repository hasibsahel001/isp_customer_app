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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDevice.device.hostName);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _saveHostName() async {
    final leaseId = widget.initialDevice.device.leaseId;
    final newName = _nameController.text.trim();
    if (leaseId == null || newName.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(managementControllerProvider.notifier).setHostName(leaseId, newName);
      _showMessage('نام دستگاه ذخیره شد');
    } catch (e) {
      _showMessage('خطا: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _applyLimit(int kbps) async {
    setState(() => _isBusy = true);
    try {
      await ref.read(managementControllerProvider.notifier).setSpeedLimit(widget.deviceIp, kbps);
      _showMessage('محدودیت اعمال شد');
    } catch (e) {
      _showMessage('خطا: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _blockDevice() async {
    setState(() => _isBusy = true);
    try {
      await ref.read(managementControllerProvider.notifier).blockDevice(widget.deviceIp);
      _showMessage('دستگاه بلاک شد');
    } catch (e) {
      _showMessage('خطا: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _removeLimit() async {
    setState(() => _isBusy = true);
    try {
      await ref.read(managementControllerProvider.notifier).removeLimit(widget.deviceIp);
      _showMessage('محدودیت حذف شد');
    } catch (e) {
      _showMessage('خطا: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(managementControllerProvider);

    final liveDevice = snapshotAsync.maybeWhen(
      data: (snapshot) {
        for (final d in snapshot.devices) {
          if (d.device.ipAddress == widget.deviceIp) return d;
        }
        return widget.initialDevice;
      },
      orElse: () => widget.initialDevice,
    );

    return Scaffold(
      appBar: AppBar(title: Text(liveDevice.device.hostName)),
      body: AbsorbPointer(
        absorbing: _isBusy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHostNameCard(liveDevice),
            const SizedBox(height: 16),
            _buildCurrentSpeedRow(liveDevice),
            const SizedBox(height: 24),
            const Text('محدودیت سرعت', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _buildLimitOptions(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isBusy ? null : _removeLimit,
                child: const Text('حذف محدودیت'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                onPressed: _isBusy ? null : _blockDevice,
                child: const Text('بلاک کردن این دستگاه', style: TextStyle(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostNameCard(ManagedDevice device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نام دستگاه', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isBusy ? null : _saveHostName,
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            device.device.ipAddress,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSpeedRow(ManagedDevice device) {
    return Row(
      children: [
        Expanded(
          child: _speedBox(
            icon: Icons.arrow_downward_rounded,
            label: 'دانلود فعلی',
            value: formatSpeed(device.currentDownloadKbps),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _speedBox(
            icon: Icons.arrow_upward_rounded,
            label: 'آپلود فعلی',
            value: formatSpeed(device.currentUploadKbps),
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _speedBox({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildLimitOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kSpeedLimitOptions.map((opt) {
        return ActionChip(
          label: Text(opt.label),
          onPressed: _isBusy ? null : () => _applyLimit(opt.kbps),
          backgroundColor: AppColors.background,
          side: const BorderSide(color: AppColors.border),
        );
      }).toList(),
    );
  }
}