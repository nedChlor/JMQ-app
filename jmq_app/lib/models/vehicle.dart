class Vehicle {
  final int id;
  final String code;
  final String nameRu;

  Vehicle({required this.id, required this.code, this.nameRu = ''});

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'] as int,
        code: map['code'] as String,
        nameRu: (map['name_ru'] as String?) ?? '',
      );
}
