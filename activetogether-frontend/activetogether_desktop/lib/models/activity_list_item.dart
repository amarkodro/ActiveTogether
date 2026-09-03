class ActivityListItem {
  final int id;
  final String name;
  final String description;
  final int categoryId;
  final String categoryName;
  final int activityTypeId;
  final String activityTypeName;
  final int locationId;
  final String locationName;
  final String locationAddress;
  final int organizerId;
  final String organizerName;
  final DateTime dateTime;
  final int capacity;
  final int reservedCount;
  final bool isFree;
  final double? price;
  final String? imageUrl;
  final String status;

  ActivityListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.activityTypeId,
    required this.activityTypeName,
    required this.locationId,
    required this.locationName,
    required this.locationAddress,
    required this.organizerId,
    required this.organizerName,
    required this.dateTime,
    required this.capacity,
    required this.reservedCount,
    required this.isFree,
    this.price,
    this.imageUrl,
    required this.status,
  });

  double get fillRatio => capacity == 0 ? 0 : reservedCount / capacity;

  factory ActivityListItem.fromJson(Map<String, dynamic> json) {
    return ActivityListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      activityTypeId: json['activityTypeId'] as int,
      activityTypeName: json['activityTypeName'] as String,
      locationId: json['locationId'] as int,
      locationName: json['locationName'] as String,
      locationAddress: json['locationAddress'] as String,
      organizerId: json['organizerId'] as int,
      organizerName: json['organizerName'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String).toLocal(),
      capacity: json['capacity'] as int,
      reservedCount: json['reservedCount'] as int,
      isFree: json['isFree'] as bool,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String,
    );
  }
}
