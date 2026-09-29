String formatSpeed(double kbps) {
  if (kbps >= 1024) return '${(kbps / 1024).toStringAsFixed(1)} Mbps';
  if (kbps < 1) return '0 Kbps';
  return '${kbps.toStringAsFixed(0)} Kbps';
}

String formatLimit(int kbps) {
  if (kbps <= 1) return 'بلاک';
  if (kbps >= 1024) {
    final m = kbps / 1024;
    final text = m == m.roundToDouble() ? m.round().toString() : m.toStringAsFixed(1);
    return '$text Mbps';
  }
  return '$kbps Kbps';
}

String _trimNum(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

// عدد همیشه قبل از واحد نمایش داده می‌شود (مثل 160 GB)، حتی داخل متن راست‌به‌چپ
String formatGB(double? v) => v == null ? '-' : '${_trimNum(v)} GB';