class CustomerInfo {
  final String? name;
  final String? family;

  CustomerInfo({this.name, this.family});

  factory CustomerInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CustomerInfo();
    return CustomerInfo(
      name: json['name'] as String?,
      family: json['family'] as String?,
    );
  }

  String get fullName {
    final n = (name ?? '').trim();
    final f = (family ?? '').trim();
    final combined = '$n $f'.trim();
    return combined;
  }
}