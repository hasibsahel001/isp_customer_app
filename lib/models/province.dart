class Province {
  final int id;
  final String name;
  final String displayName;

  Province({
    required this.id,
    required this.name,
    required this.displayName,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as int,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
    );
  }
}