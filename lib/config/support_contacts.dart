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
    telegramUrl: 'https://t.me/khorshid',
    whatsappNumber: '93783555777',
    displayPhone: '0783555777',
  ),
  // TODO: mazar و shiberghan را وقتی فعال شدند اینجا اضافه کنید
};

const SupportContact kDefaultSupport = SupportContact(
  telegramUrl: 'https://t.me/khorshid',
  whatsappNumber: '93783555777',
  displayPhone: '0783555777',
);