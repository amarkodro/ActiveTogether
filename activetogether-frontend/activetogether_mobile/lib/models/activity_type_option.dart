class ActivityTypeOption {
  final int id;
  final String name;

  ActivityTypeOption({required this.id, required this.name});

  factory ActivityTypeOption.fromJson(Map<String, dynamic> json) {
    return ActivityTypeOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
