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

String formatGB(double? v) => v == null ? '-' : '${_trimNum(v)} GB';
String formatGBFa(double? v) => v == null ? '-' : '${_trimNum(v)} گیگابایت';

String _trimNumStr(String numStr) {
  final d = double.tryParse(numStr);
  if (d == null) return numStr;
  if (d == d.roundToDouble()) return d.toStringAsFixed(0);
  return d.toString();
}

/// نام‌های خام بسته (مثل A08-LP-140GB-3Mbps-1M یا
/// Sheb_B_9_Volume_200-GB_Speed_2M_(1-Month)) را به فرمت ساده و
/// قابل‌فهم برای مشتری تبدیل می‌کند: 140GB-3Mbps-1Month
/// در صورت هر مشکلی در تشخیص الگو، نام اصلی بدون تغییر برگردانده می‌شود.
String simplifyPackageName(String raw) {
  if (raw.trim().isEmpty) return raw;
  try {
    String remaining = raw;
    final parts = <String>[];

    // حجم (GB)
    final volumeMatch =
    RegExp(r'(\d+(?:\.\d+)?)\s*-?\s*GB', caseSensitive: false).firstMatch(remaining);
    if (volumeMatch != null) {
      parts.add('${_trimNumStr(volumeMatch.group(1)!)}GB');
      remaining = remaining.replaceFirst(volumeMatch.group(0)!, '');
    }

    // سرعت (Mbps)
    RegExpMatch? speedMatch =
    RegExp(r'(\d+(?:\.\d+)?)\s*Mbps', caseSensitive: false).firstMatch(remaining);
    speedMatch ??=
        RegExp(r'Speed[_\s-]*(\d+(?:\.\d+)?)\s*[Mm]', caseSensitive: false).firstMatch(remaining);
    if (speedMatch != null) {
      parts.add('${_trimNumStr(speedMatch.group(1)!)}Mbps');
      remaining = remaining.replaceFirst(speedMatch.group(0)!, '');
    }

    // مدت (ماه)
    RegExpMatch? durationMatch =
    RegExp(r'(\d+(?:\.\d+)?)\s*[-_]?\s*[Mm]onths?', caseSensitive: false)
        .firstMatch(remaining);
    durationMatch ??=
        RegExp(r'(\d+(?:\.\d+)?)\s*-?\s*[Mm](?![a-zA-Z])').firstMatch(remaining);
    if (durationMatch != null) {
      parts.add('${_trimNumStr(durationMatch.group(1)!)}Month');
    }

    if (parts.isEmpty) return raw;
    return parts.join('-');
  } catch (_) {
    return raw;
  }
}