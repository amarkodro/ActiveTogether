class CityOption {
  final int id;
  final String name;
  final int? countryId;
  final String? countryName;

  CityOption({
    required this.id,
    required this.name,
    this.countryId,
    this.countryName,
  });

  factory CityOption.fromJson(Map<String, dynamic> json) {
    return CityOption(
      id: json['id'] as int,
      name: json['name'] as String,
      countryId: json['countryId'] as int?,
      countryName: json['countryName'] as String?,
    );
  }
}
