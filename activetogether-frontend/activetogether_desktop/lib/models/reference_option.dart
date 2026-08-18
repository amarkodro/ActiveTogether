class ReferenceOption {
  final int id;
  final String name;

  ReferenceOption({required this.id, required this.name});

  factory ReferenceOption.fromJson(Map<String, dynamic> json) {
    return ReferenceOption(id: json['id'] as int, name: json['name'] as String);
  }
}
