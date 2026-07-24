class DtcCode {
  final int id;
  final String vehicleModel;
  final String ecu;
  final String ecuVariant;
  final String code;
  final String dtcType;
  final String meaningEn;

  DtcCode({
    required this.id,
    required this.vehicleModel,
    required this.ecu,
    this.ecuVariant = '',
    required this.code,
    required this.dtcType,
    required this.meaningEn,
  });

  factory DtcCode.fromMap(Map<String, dynamic> map) => DtcCode(
        id: map['id'] as int,
        vehicleModel: map['vehicle_model'] as String,
        ecu: map['ecu'] as String,
        ecuVariant: (map['ecu_variant'] as String?) ?? '',
        code: map['code'] as String,
        dtcType: map['dtc_type'] as String,
        meaningEn: map['meaning_en'] as String,
      );
}
