class SupportContact {
  final String telegramUrl;
  final String displayPhone; // مثلاً '0799999999'

  const SupportContact({
    required this.telegramUrl,
    required this.displayPhone,
  });

  // فرمت بین‌المللی برای لینک واتساپ (حذف صفر ابتدایی + کد کشور افغانستان)
  String get whatsappNumber {
    final digits = displayPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      return '93${digits.substring(1)}';
    }
    return digits;
  }
}

const Map<String, SupportContact> kSupportByProvince = {
  'ghazni': SupportContact(
    telegramUrl: 'https://t.me/ghaznitelegram',
    displayPhone: '079999999',
  ),
  'sheberghan': SupportContact(
    telegramUrl: 'https://t.me/sheberghantele',
    displayPhone: '0788888888',
  ),
};

const SupportContact kDefaultSupport = SupportContact(
  telegramUrl: 'https://t.me/hasibsahel',
  displayPhone: '0729011991',
);