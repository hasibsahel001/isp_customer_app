import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_info.dart';
import '../models/customer_info.dart';
import '../providers/package_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(packageInfoProvider);
            await ref.read(packageInfoProvider.future);
          },
          child: homeAsync.when(
            data: (data) => _buildContent(data),
            loading: () => ListView(
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ],
            ),
            error: (err, stack) => _buildNoPackage(CustomerInfo()),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPackage(CustomerInfo customer) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildGreeting(customer),
        const SizedBox(height: 80),
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

  Widget _buildContent(HomeData data) {
    final p = data.package;
    if (p == null) return _buildNoPackage(data.customer);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _buildGreeting(data.customer),
        const SizedBox(height: 14),
        _buildHeroCard(p),
        const SizedBox(height: 16),
        _buildTimeCard(p),
      ],
    );
  }

  Widget _buildGreeting(CustomerInfo customer) {
    final fullName = customer.fullName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Text(
        fullName.isNotEmpty ? 'خوش آمدید $fullName، عزیز' : 'خوش آمدید',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Color _usageColor(int percent) {
    if (percent >= 90) return const Color(0xFFFCA5A5);
    if (percent >= 70) return const Color(0xFFFCD34D);
    return Colors.white;
  }

  Widget _buildHeroCard(PackageInfo p) {
    final isUnlimited = p.traffic.limitType == TrafficLimitType.unlimited;
    final usagePercent = p.traffic.usagePercent.clamp(0, 100);
    final barColor = _usageColor(usagePercent);
    final displayName = p.serviceName ?? 'بدون بسته';

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
                              style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 7),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              displayName,
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusBadge(p.isActive),
                  ],
                ),
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
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
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
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15),
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
              style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('مصرف‌شده', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13.5)),
            ),
            const Spacer(),
            Text('$usagePercent٪',
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('باقی‌مانده: ${formatGBFa(p.traffic.remainingGB)}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600)),
            Text('کل: ${formatGBFa(p.traffic.totalGB)}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ---------- کارت مدت‌زمان بسته ----------
  Widget _buildTimeCard(PackageInfo p) {
    final d = p.dates;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              const Text('مدت زمان بسته', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 18),
          if (d.isUnlimitedDuration)
            Row(
              children: const [
                Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text('بدون محدودیت زمانی', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white)),
              ],
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  d.isExpired ? 'منقضی شده' : '${d.daysRemaining}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: d.isExpired ? 18 : 28, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                if (!d.isExpired) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('روز باقی‌مانده', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                  ),
                ],
                const Spacer(),
                if (d.totalDaysOfPackage != null)
                  Text('${d.usagePercent}٪', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: d.isExpired ? 1 : d.usagePercent / 100,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(d.isExpired ? const Color(0xFFFCA5A5) : Colors.white),
              ),
            ),
            if (d.totalDaysOfPackage != null) ...[
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'مدت کل بسته: ${d.totalDaysOfPackage} روز',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withOpacity(0.18)),
          const SizedBox(height: 16),
          _dateRow(Icons.play_circle_outline_rounded, 'شروع بسته', d.startDateFriendly, null),
          const SizedBox(height: 12),
          _dateRow(Icons.event_busy_rounded, 'پایان بسته', d.endDateFriendly, d.endTime),
        ],
      ),
    );
  }

  Widget _dateRow(IconData icon, String label, String? date, String? time) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13.5, color: Colors.white.withOpacity(0.8))),
        const Spacer(),
        Text(date ?? '-', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
        if (time != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
            child: Text(time,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ],
    );
  }
}