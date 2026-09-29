import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_info.dart';
import '../providers/package_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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

  Widget _buildContent(PackageInfo p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        _buildHeroCard(p),
        const SizedBox(height: 16),
        _buildTimeCard(p),
        const SizedBox(height: 16),
        _buildStatsGrid(p),
      ],
    );
  }

  Color _usageColor(int percent) {
    if (percent >= 90) return const Color(0xFFFCA5A5);
    if (percent >= 70) return const Color(0xFFFCD34D);
    return Colors.white;
  }

  // ---------- کارت اصلی (گرادیان رنگی) ----------
  Widget _buildHeroCard(PackageInfo p) {
    final isUnlimited = p.traffic.limitType == TrafficLimitType.unlimited;
    final usagePercent = p.traffic.usagePercent.clamp(0, 100);
    final barColor = _usageColor(usagePercent);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.35), blurRadius: 26, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
            ),
          ),
          Positioned(
            right: -25,
            bottom: -45,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
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
                          const Text('بستهٔ فعلی شما',
                              style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            p.serviceName ?? 'بدون بسته',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusBadge(p.isActive),
                  ],
                ),
                const SizedBox(height: 14),
                _trafficTypeBadge(p.traffic.limitType),
                const SizedBox(height: 26),
                if (isUnlimited)
                  _buildUnlimitedBanner()
                else
                  _buildTrafficBar(p, usagePercent, barColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    final color = isActive ? const Color(0xFF34D399) : const Color(0xFFF87171);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(isActive ? 'فعال' : 'غیرفعال',
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
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
        text = 'بستهٔ حجمی';
        icon = Icons.data_usage_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildUnlimitedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'بستهٔ شما هیچ محدودیت مصرفی ندارد',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficBar(PackageInfo p, int usagePercent, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatGB(p.traffic.usedGB),
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('مصرف‌شده', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
            ),
            const Spacer(),
            Text('$usagePercent٪',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: usagePercent / 100,
            minHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('باقی‌مانده: ${formatGB(p.traffic.remainingGB)}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text('کل: ${formatGB(p.traffic.totalGB)}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ---------- کارت زمان بسته ----------
  Widget _buildTimeCard(PackageInfo p) {
    final d = p.dates;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecor.card(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('مدت زمان بسته',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          if (d.isUnlimitedDuration)
            Row(
              children: const [
                Icon(Icons.all_inclusive_rounded, color: AppColors.success, size: 22),
                SizedBox(width: 10),
                Text('بدون محدودیت زمانی', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  d.isExpired ? 'منقضی شده' : '${d.daysRemaining}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: d.isExpired ? 20 : 30,
                    fontWeight: FontWeight.w800,
                    color: d.isExpired ? AppColors.danger : AppColors.textPrimary,
                  ),
                ),
                if (!d.isExpired) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('روز باقی‌مانده',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
                const Spacer(),
                if (d.totalDaysOfPackage != null)
                  Text('${d.usagePercent}٪',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: d.isExpired ? 1 : d.usagePercent / 100,
                minHeight: 12,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(d.isExpired ? AppColors.danger : AppColors.accent),
              ),
            ),
            const SizedBox(height: 8),
            if (d.totalDaysOfPackage != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${d.usedDays} روز مصرف‌شده',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  Text('${d.totalDaysOfPackage} روز کل',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
          ],
          const Divider(height: 32),
          _dateLine(Icons.play_circle_outline_rounded, 'شروع بسته', d.startDateFriendly, null),
          const SizedBox(height: 12),
          _dateLine(Icons.event_busy_rounded, 'پایان بسته', d.endDateFriendly, d.endTime),
        ],
      ),
    );
  }

  Widget _dateLine(IconData icon, String label, String? date, String? time) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(
          date ?? '-',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        if (time != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('ساعت $time',
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ],
    );
  }

  // ---------- شبکهٔ خلاصهٔ آماری ----------
  Widget _buildStatsGrid(PackageInfo p) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.data_usage_rounded,
            color: AppColors.primary,
            label: 'حجم باقی‌مانده',
            value: p.traffic.limitType == TrafficLimitType.unlimited ? '∞' : formatGB(p.traffic.remainingGB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.timer_outlined,
            color: AppColors.secondary,
            label: 'روز باقی‌مانده',
            value: p.dates.isUnlimitedDuration
                ? '∞'
                : (p.dates.isExpired ? 'تمام' : '${p.dates.daysRemaining}'),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}