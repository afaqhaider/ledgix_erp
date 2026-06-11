class DesignationModel {
  final String id;
  final String companyId;
  final String name;

  DesignationModel({
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

  factory DesignationModel.fromMap(Map<String, dynamic> map, String id) {
    return DesignationModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
