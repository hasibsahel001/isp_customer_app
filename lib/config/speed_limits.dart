class SpeedLimitOption {
  final int kbps;
  final String label;
  const SpeedLimitOption(this.kbps, this.label);
}

const List<SpeedLimitOption> kSpeedLimitOptions = [
  SpeedLimitOption(64, '64 کیلوبیت'),
  SpeedLimitOption(128, '128 کیلوبیت'),
  SpeedLimitOption(256, '256 کیلوبیت'),
  SpeedLimitOption(512, '512 کیلوبیت'),
  SpeedLimitOption(700, '700 کیلوبیت'),
  SpeedLimitOption(1024, '1 مگابیت'),
  SpeedLimitOption(2048, '2 مگابیت'),
  SpeedLimitOption(3072, '3 مگابیت'),
  SpeedLimitOption(4096, '4 مگابیت'),
  SpeedLimitOption(5120, '5 مگابیت'),
  SpeedLimitOption(6144, '6 مگابیت'),
  SpeedLimitOption(7168, '7 مگابیت'),
  SpeedLimitOption(8192, '8 مگابیت'),
  SpeedLimitOption(9216, '9 مگابیت'),
  SpeedLimitOption(10240, '10 مگابیت'),
];