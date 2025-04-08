import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String subdistrict; // 면단위
  final String paymentGroup; // 결제소속
  final String? personalId; // 주민등록번호 (암호화)
  final Address? address;
  final BankInfo? bankInfo;
  final List<String> fields; // 농지 ID 참조 배열
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // 등록한 사용자 ID
  final String? memo;

  FarmModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.subdistrict,
    required this.paymentGroup,
    this.personalId,
    this.address,
    this.bankInfo,
    this.fields = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.memo,
  });

  // Firestore에서 데이터 로드
  factory FarmModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 주소 처리
    Address? address;
    if (data['address'] != null) {
      address = Address.fromMap(data['address'] as Map<String, dynamic>);
    }

    // 계좌 정보 처리
    BankInfo? bankInfo;
    if (data['bankInfo'] != null) {
      bankInfo = BankInfo.fromMap(data['bankInfo'] as Map<String, dynamic>);
    }

    // 농지 ID 목록 처리
    List<String> fields = [];
    if (data['fields'] != null) {
      fields = List<String>.from(data['fields'] as List<dynamic>);
    }

    return FarmModel(
      id: doc.id,
      name: data['name'] as String,
      phoneNumber: data['phoneNumber'] as String,
      subdistrict: data['subdistrict'] as String,
      paymentGroup: data['paymentGroup'] as String,
      personalId: data['personalId'] as String?,
      address: address,
      bankInfo: bankInfo,
      fields: fields,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      memo: data['memo'] as String?,
    );
  }

  // Map 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'subdistrict': subdistrict,
      'paymentGroup': paymentGroup,
      'personalId': personalId,
      'address': address?.toMap(),
      'bankInfo': bankInfo?.toMap(),
      'fields': fields,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'memo': memo,
    };
  }

  // 복사 및 업데이트
  FarmModel copyWith({
    String? name,
    String? phoneNumber,
    String? subdistrict,
    String? paymentGroup,
    String? personalId,
    Address? address,
    BankInfo? bankInfo,
    List<String>? fields,
    String? memo,
  }) {
    return FarmModel(
      id: this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      subdistrict: subdistrict ?? this.subdistrict,
      paymentGroup: paymentGroup ?? this.paymentGroup,
      personalId: personalId ?? this.personalId,
      address: address ?? this.address,
      bankInfo: bankInfo ?? this.bankInfo,
      fields: fields ?? this.fields,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      createdBy: this.createdBy,
      memo: memo ?? this.memo,
    );
  }
}

class Address {
  final String full;
  final String? zipcode;
  final String? detail;
  final GeoPoint? coordinates;

  Address({
    required this.full,
    this.zipcode,
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
      zipcode: map['zipcode'] as String?,
      detail: map['detail'] as String?,
      coordinates: coordinates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full': full,
      'zipcode': zipcode,
      'detail': detail,
      'coordinates': coordinates,
    };
  }

  Address copyWith({
    String? full,
    String? zipcode,
    String? detail,
    GeoPoint? coordinates,
  }) {
    return Address(
      full: full ?? this.full,
      zipcode: zipcode ?? this.zipcode,
      detail: detail ?? this.detail,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

class BankInfo {
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  BankInfo({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  factory BankInfo.fromMap(Map<String, dynamic> map) {
    return BankInfo(
      bankName: map['bankName'] as String,
      accountNumber: map['accountNumber'] as String,
      accountHolder: map['accountHolder'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    };
  }

  BankInfo copyWith({
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  }) {
    return BankInfo(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
    );
  }
}
