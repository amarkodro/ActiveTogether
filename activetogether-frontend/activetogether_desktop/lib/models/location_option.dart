class LocationOption {
  final int id;
  final String name;
  final String address;
  final int cityId;
  final String cityName;
  final double latitude;
  final double longitude;

  LocationOption({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  String get label => '$name — $address, $cityName';

  factory LocationOption.fromJson(Map<String, dynamic> json) {
    return LocationOption(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
