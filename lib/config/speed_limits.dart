class SpeedLimitOption {
  final int kbps;
  final String label;
  const SpeedLimitOption(this.kbps, this.label);
}

const List<SpeedLimitOption> kKbpsOptions = [
  SpeedLimitOption(64, '64K'),
  SpeedLimitOption(128, '128K'),
  SpeedLimitOption(256, '256K'),
  SpeedLimitOption(512, '512K'),
  SpeedLimitOption(750, '750K'),
];

const List<SpeedLimitOption> kMbpsOptions = [
  SpeedLimitOption(1024, '1M'),
  SpeedLimitOption(1536, '1.5M'),
  SpeedLimitOption(2048, '2M'),
  SpeedLimitOption(3072, '3M'),
  SpeedLimitOption(4096, '4M'),
  SpeedLimitOption(5120, '5M'),
  SpeedLimitOption(6144, '6M'),
  SpeedLimitOption(7168, '7M'),
  SpeedLimitOption(8192, '8M'),
  SpeedLimitOption(9216, '9M'),
  SpeedLimitOption(10240, '10M'),
];

// برای سازگاری با کدهای قدیمی که همهٔ گزینه‌ها را با هم می‌خواستند
List<SpeedLimitOption> get kSpeedLimitOptions => [...kKbpsOptions, ...kMbpsOptions];