class OnlineDevice {
  final String ipAddress;
  final String macAddress;
  final String hostName;
  final String? leaseId;

  OnlineDevice({
    required this.ipAddress,
    required this.macAddress,
    required this.hostName,
    required this.leaseId,
  });
}

enum DeviceLimitStatus { normal, limited, blocked }

class ManagedDevice {
  final OnlineDevice device;
  final DeviceLimitStatus limitStatus;
  final int limitDownloadKbps; // 0 یعنی بدون محدودیت
  final double currentDownloadKbps;
  final double currentUploadKbps;

  ManagedDevice({
    required this.device,
    required this.limitStatus,
    required this.limitDownloadKbps,
    this.currentDownloadKbps = 0,
    this.currentUploadKbps = 0,
  });

  ManagedDevice copyWith({
    double? currentDownloadKbps,
    double? currentUploadKbps,
  }) {
    return ManagedDevice(
      device: device,
      limitStatus: limitStatus,
      limitDownloadKbps: limitDownloadKbps,
      currentDownloadKbps: currentDownloadKbps ?? this.currentDownloadKbps,
      currentUploadKbps: currentUploadKbps ?? this.currentUploadKbps,
    );
  }
}