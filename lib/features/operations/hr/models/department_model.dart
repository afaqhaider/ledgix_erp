class DepartmentModel {
  final String id;
  final String companyId;
  final String name;

  DepartmentModel({
    required this.id,
    required this.companyId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
