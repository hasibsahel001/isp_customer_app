String formatSpeed(double kbps) {
  if (kbps >= 1024) {
    return '${(kbps / 1024).toStringAsFixed(1)} Mbps';
  }
  if (kbps < 1) return '0 Kbps';
  return '${kbps.toStringAsFixed(0)} Kbps';
}