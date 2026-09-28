class DatesInfo {
  final String? startDateFriendly;
  final String? endDateFriendly;
  final dynamic daysRemaining; // int، یا "expired"، یا "unlimited"
  final int? totalDaysOfPackage;

  DatesInfo({
    required this.startDateFriendly,
    required this.endDateFriendly,
    required this.daysRemaining,
    required this.totalDaysOfPackage,
  });

  factory DatesInfo.fromJson(Map<String, dynamic> json) {
    return DatesInfo(
      startDateFriendly: json['startDateFriendly'] as String?,
      endDateFriendly: json['endDateFriendly'] as String?,
      daysRemaining: json['daysRemaining'],
      totalDaysOfPackage: (json['totalDaysOfPackage'] as num?)?.toInt(),
    );
  }

  bool get isExpired => daysRemaining == 'expired';
  bool get isUnlimitedDuration => daysRemaining == 'unlimited';
}

enum TrafficLimitType { unlimited, monthlyCap, fixed }

class TrafficInfo {
  final TrafficLimitType limitType;
  final double? totalGB;
  final double? usedGB;
  final double? remainingGB;
  final int usagePercent;

  TrafficInfo({
    required this.limitType,
    required this.totalGB,
    required this.usedGB,
    required this.remainingGB,
    required this.usagePercent,
  });

  factory TrafficInfo.fromJson(Map<String, dynamic> json) {
    final typeStr = json['limitType'] as String? ?? 'fixed';
    TrafficLimitType type;
    switch (typeStr) {
      case 'unlimited':
        type = TrafficLimitType.unlimited;
        break;
      case 'monthly_cap':
        type = TrafficLimitType.monthlyCap;
        break;
      default:
        type = TrafficLimitType.fixed;
    }

    return TrafficInfo(
      limitType: type,
      totalGB: (json['totalGB'] as num?)?.toDouble(),
      usedGB: (json['usedGB'] as num?)?.toDouble(),
      remainingGB: (json['remainingGB'] as num?)?.toDouble(),
      usagePercent: (json['usagePercent'] as num?)?.toInt() ?? 0,
    );
  }
}

class PackageInfo {
  final String? serviceName;
  final String? serviceStatus;
  final DatesInfo dates;
  final TrafficInfo traffic;

  PackageInfo({
    required this.serviceName,
    required this.serviceStatus,
    required this.dates,
    required this.traffic,
  });

  bool get isActive => serviceStatus == 'Active';

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      serviceName: json['serviceName'] as String?,
      serviceStatus: json['serviceStatus'] as String?,
      dates: DatesInfo.fromJson(json['dates'] as Map<String, dynamic>),
      traffic: TrafficInfo.fromJson(json['traffic'] as Map<String, dynamic>),
    );
  }
}