class CategoryOption {
  final int id;
  final String name;

  CategoryOption({required this.id, required this.name});

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(id: json['id'] as int, name: json['name'] as String);
  }
}
