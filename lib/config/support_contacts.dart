class SupportContact {
  final String telegramUrl;
  final String whatsappNumber; // بدون صفر اول، با کد کشور
  final String displayPhone;

  const SupportContact({
    required this.telegramUrl,
    required this.whatsappNumber,
    required this.displayPhone,
  });
}

const Map<String, SupportContact> kSupportByProvince = {
  'ghazni': SupportContact(
    telegramUrl: 'https://t.me/hasibsahel',
    whatsappNumber: '93729011991',
    displayPhone: '0729011991',
  ),
  // TODO: mazar و shiberghan را وقتی فعال شدند اینجا اضافه کنید
};

const SupportContact kDefaultSupport = SupportContact(
  telegramUrl: 'https://t.me/hasibsahel',
  whatsappNumber: '93729011991',
  displayPhone: '0729011991',
);