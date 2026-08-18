class CityOption {
  final int id;
  final String name;

  CityOption({required this.id, required this.name});

  factory CityOption.fromJson(Map<String, dynamic> json) {
    return CityOption(id: json['id'] as int, name: json['name'] as String);
  }
}
