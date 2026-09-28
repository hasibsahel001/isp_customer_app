import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_info.dart';
import '../providers/package_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('خانه')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(packageInfoProvider);
          await ref.read(packageInfoProvider.future);
        },
        child: packageAsync.when(
          data: (package) {
            if (package == null) return _buildNoPackage();
            return _buildContent(package);
          },
          loading: () => ListView(
            children: const [
              SizedBox(height: 200),
              Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ],
          ),
          error: (err, stack) => _buildNoPackage(),
        ),
      ),
    );
  }

  Widget _buildNoPackage() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'اطلاعاتی از بستهٔ اینترنتی یافت نشد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'برای بررسی مجدد، صفحه را پایین بکشید',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(PackageInfo package) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildMainCard(package),
        const SizedBox(height: 16),
        _buildInfoGrid(package),
        const SizedBox(height: 16),
        _buildDatesCard(package),
      ],
    );
  }

  Color _usageColor(int percent) {
    if (percent >= 90) return AppColors.danger;
    if (percent >= 70) return AppColors.warning;
    return AppColors.primary;
  }

  Widget _buildMainCard(PackageInfo package) {
    final isUnlimited = package.traffic.limitType == TrafficLimitType.unlimited;
    final usagePercent = package.traffic.usagePercent.clamp(0, 100);
    final barColor = _usageColor(usagePercent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بستهٔ فعلی',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package.serviceName ?? 'بدون بسته',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(package.isActive),
            ],
          ),
          const SizedBox(height: 12),

          _trafficTypeBadge(package.traffic.limitType),

          const SizedBox(height: 20),

          if (isUnlimited)
            _buildTrulyUnlimitedBanner()
          else
            _buildUsageSection(package, usagePercent, barColor),
        ],
      ),
    );
  }

  Widget _trafficTypeBadge(TrafficLimitType type) {
    String text;
    IconData icon;
    switch (type) {
      case TrafficLimitType.unlimited:
        text = 'ترافیک کاملاً نامحدود';
        icon = Icons.all_inclusive_rounded;
        break;
      case TrafficLimitType.monthlyCap:
        text = 'نامحدود با سقف ماهانه';
        icon = Icons.calendar_view_month_rounded;
        break;
      case TrafficLimitType.fixed:
        text = 'حجمی';
        icon = Icons.data_usage_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrulyUnlimitedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'بستهٔ شما هیچ محدودیت مصرفی ندارد',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection(PackageInfo package, int usagePercent, Color barColor) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: usagePercent / 100,
                  strokeWidth: 7,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
              Text(
                '$usagePercent%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _trafficLine('مصرف‌شده', package.traffic.usedGB, AppColors.textPrimary),
              const SizedBox(height: 8),
              _trafficLine('باقی‌مانده', package.traffic.remainingGB, AppColors.success),
              const SizedBox(height: 8),
              _trafficLine(
                package.traffic.limitType == TrafficLimitType.monthlyCap
                    ? 'سقف ماهانه'
                    : 'حجم کل',
                package.traffic.totalGB,
                AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trafficLine(String label, double? valueGB, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          valueGB != null ? '${valueGB.toStringAsFixed(2)} GB' : '-',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _statusBadge(bool isActive) {
    final color = isActive ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'فعال' : 'غیرفعال',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(PackageInfo package) {
    return Row(
      children: [
        Expanded(
          child: _smallCard(
            icon: Icons.calendar_month_rounded,
            label: 'مدت کل بسته',
            value: package.dates.totalDaysOfPackage != null
                ? '${package.dates.totalDaysOfPackage} روز'
                : '-',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _smallCard(
            icon: Icons.hourglass_bottom_rounded,
            label: 'روزهای باقی‌مانده',
            value: _daysRemainingText(package.dates),
            valueColor: package.dates.isExpired ? AppColors.danger : null,
          ),
        ),
      ],
    );
  }

  String _daysRemainingText(DatesInfo dates) {
    if (dates.isExpired) return 'منقضی شده';
    if (dates.isUnlimitedDuration) return 'نامحدود';
    return '${dates.daysRemaining} روز';
  }

  Widget _smallCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesCard(PackageInfo package) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _dateRow(
            Icons.play_circle_outline_rounded,
            'تاریخ شروع بسته',
            package.dates.startDateFriendly,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _dateRow(
            Icons.event_busy_rounded,
            'تاریخ پایان بسته',
            package.dates.endDateFriendly,
          ),
        ],
      ),
    );
  }

  Widget _dateRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Flexible(
            child: Text(
              value ?? '-',
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}