import 'package:cloud_firestore/cloud_firestore.dart';

class FieldModel {
  final String id;
  final String farmerId; // 소속 농가 ID 참조
  final Address address;
  final Area area;
  final String cropType; // 작물 종류
  final DateTime? estimatedHarvestDate;
  final CurrentStage currentStage;
  final List<String> schedules; // 작업 일정 ID 배열
  final List<String> contractIds; // 계약 ID 배열
  final String? contractStatus; // 현재 계약 상태
  final ContractRef? currentContract; // 현재 활성 계약 정보
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? memo;

  FieldModel({
    required this.id,
    required this.farmerId,
    required this.address,
    required this.area,
    required this.cropType,
    this.estimatedHarvestDate,
    required this.currentStage,
    this.schedules = const [],
    this.contractIds = const [],
    this.contractStatus,
    this.currentContract,
    required this.createdAt,
    required this.updatedAt,
    this.memo,
  });

  // Firestore에서 데이터 로드
  factory FieldModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 주소 처리
    Address address = Address.fromMap(data['address'] as Map<String, dynamic>);

    // 면적 처리
    Area area = Area.fromMap(data['area'] as Map<String, dynamic>);

    // 현재 단계 처리
    CurrentStage currentStage =
        CurrentStage.fromMap(data['currentStage'] as Map<String, dynamic>);

    // 작업 일정 ID 목록 처리
    List<String> schedules = [];
    if (data['schedules'] != null) {
      schedules = List<String>.from(data['schedules'] as List<dynamic>);
    }

    // 계약 ID 목록 처리
    List<String> contractIds = [];
    if (data['contractIds'] != null) {
      contractIds = List<String>.from(data['contractIds'] as List<dynamic>);
    }

    // 현재 계약 정보 처리
    ContractRef? currentContract;
    if (data['currentContract'] != null) {
      currentContract =
          ContractRef.fromMap(data['currentContract'] as Map<String, dynamic>);
    }

    // 수확 예정일 처리
    DateTime? estimatedHarvestDate;
    if (data['estimatedHarvestDate'] != null) {
      estimatedHarvestDate =
          (data['estimatedHarvestDate'] as Timestamp).toDate();
    }

    return FieldModel(
      id: doc.id,
      farmerId: data['farmerId'] as String,
      address: address,
      area: area,
      cropType: data['cropType'] as String,
      estimatedHarvestDate: estimatedHarvestDate,
      currentStage: currentStage,
      schedules: schedules,
      contractIds: contractIds,
      contractStatus: data['contractStatus'] as String?,
      currentContract: currentContract,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      memo: data['memo'] as String?,
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'address': address.toMap(),
      'area': area.toMap(),
      'cropType': cropType,
      'estimatedHarvestDate': estimatedHarvestDate != null
          ? Timestamp.fromDate(estimatedHarvestDate!)
          : null,
      'currentStage': currentStage.toMap(),
      'schedules': schedules,
      'contractIds': contractIds,
      'contractStatus': contractStatus,
      'currentContract': currentContract?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'memo': memo,
    };
  }

  // 복사 및 업데이트
  FieldModel copyWith({
    String? farmerId,
    Address? address,
    Area? area,
    String? cropType,
    DateTime? estimatedHarvestDate,
    CurrentStage? currentStage,
    List<String>? schedules,
    List<String>? contractIds,
    String? contractStatus,
    ContractRef? currentContract,
    String? memo,
  }) {
    return FieldModel(
      id: this.id,
      farmerId: farmerId ?? this.farmerId,
      address: address ?? this.address,
      area: area ?? this.area,
      cropType: cropType ?? this.cropType,
      estimatedHarvestDate: estimatedHarvestDate ?? this.estimatedHarvestDate,
      currentStage: currentStage ?? this.currentStage,
      schedules: schedules ?? this.schedules,
      contractIds: contractIds ?? this.contractIds,
      contractStatus: contractStatus ?? this.contractStatus,
      currentContract: currentContract ?? this.currentContract,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      memo: memo ?? this.memo,
    );
  }
}

class Address {
  final String full;
  final String? detail;
  final GeoPoint? coordinates;

  Address({
    required this.full,
    this.detail,
    this.coordinates,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    GeoPoint? coordinates;
    if (map['coordinates'] != null) {
      if (map['coordinates'] is GeoPoint) {
        coordinates = map['coordinates'] as GeoPoint;
      } else if (map['coordinates'] is Map) {
        final coords = map['coordinates'] as Map<String, dynamic>;
        if (coords.containsKey('latitude') && coords.containsKey('longitude')) {
          coordinates = GeoPoint(
            coords['latitude'] as double,
            coords['longitude'] as double,
          );
        }
      }
    }

    return Address(
      full: map['full'] as String,
      detail: map['detail'] as String?,
      coordinates: coordinates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full': full,
      'detail': detail,
      'coordinates': coordinates,
    };
  }

  Address copyWith({
    String? full,
    String? detail,
    GeoPoint? coordinates,
  }) {
    return Address(
      full: full ?? this.full,
      detail: detail ?? this.detail,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

class Area {
  final double value;
  final String unit; // 평, 제곱미터, 헥타르 등

  Area({
    required this.value,
    required this.unit,
  });

  factory Area.fromMap(Map<String, dynamic> map) {
    return Area(
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'unit': unit,
    };
  }

  Area copyWith({
    double? value,
    String? unit,
  }) {
    return Area(
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }
}

class CurrentStage {
  final String stage; // 계약예정, 계약완료, 뽑기준비 등
  final DateTime updatedAt;

  CurrentStage({
    required this.stage,
    required this.updatedAt,
  });

  factory CurrentStage.fromMap(Map<String, dynamic> map) {
    return CurrentStage(
      stage: map['stage'] as String,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stage': stage,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CurrentStage copyWith({
    String? stage,
    DateTime? updatedAt,
  }) {
    return CurrentStage(
      stage: stage ?? this.stage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContractRef {
  final String id;
  final String contractNumber;
  final DateTime? finalPaymentDueDate;

  ContractRef({
    required this.id,
    required this.contractNumber,
    this.finalPaymentDueDate,
  });

  factory ContractRef.fromMap(Map<String, dynamic> map) {
    DateTime? finalPaymentDueDate;
    if (map['finalPaymentDueDate'] != null) {
      finalPaymentDueDate = (map['finalPaymentDueDate'] as Timestamp).toDate();
    }

    return ContractRef(
      id: map['id'] as String,
      contractNumber: map['contractNumber'] as String,
      finalPaymentDueDate: finalPaymentDueDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractNumber': contractNumber,
      'finalPaymentDueDate': finalPaymentDueDate != null
          ? Timestamp.fromDate(finalPaymentDueDate!)
          : null,
    };
  }
}
