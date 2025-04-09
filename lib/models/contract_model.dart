// lib/models/contract_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractModel {
  final String id;
  final String farmerId;
  final List<String> fieldIds;
  final String contractNumber;
  final DateTime contractDate;
  final String contractType;
  final String contractStatus;
  final double totalAmount;
  final PaymentInfo downPayment;
  final List<IntermediatePayment> intermediatePayments;
  final PaymentInfo finalPayment;
  final ContractDetails contractDetails;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? memo;

  ContractModel({
    required this.id,
    required this.farmerId,
    required this.fieldIds,
    required this.contractNumber,
    required this.contractDate,
    required this.contractType,
    required this.contractStatus,
    required this.totalAmount,
    required this.downPayment,
    required this.intermediatePayments,
    required this.finalPayment,
    required this.contractDetails,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.memo,
  });

  // Firestore에서 데이터 로드
  factory ContractModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 계약금 정보 처리
    PaymentInfo downPayment =
        PaymentInfo.fromMap(data['downPayment'] as Map<String, dynamic>);

    // 중도금 정보 처리
    List<IntermediatePayment> intermediatePayments = [];
    if (data['intermediatePayments'] != null) {
      intermediatePayments = List<IntermediatePayment>.from(
          (data['intermediatePayments'] as List).map(
        (x) => IntermediatePayment.fromMap(x as Map<String, dynamic>),
      ));
    }

    // 잔금 정보 처리
    PaymentInfo finalPayment =
        PaymentInfo.fromMap(data['finalPayment'] as Map<String, dynamic>);

    // 계약 세부사항 처리
    ContractDetails contractDetails = ContractDetails.fromMap(
        data['contractDetails'] as Map<String, dynamic>);

    // 첨부파일 처리
    List<Attachment> attachments = [];
    if (data['attachments'] != null) {
      attachments = List<Attachment>.from((data['attachments'] as List).map(
        (x) => Attachment.fromMap(x as Map<String, dynamic>),
      ));
    }

    // 농지 ID 목록 처리
    List<String> fieldIds = [];
    if (data['fieldIds'] != null) {
      fieldIds = List<String>.from(data['fieldIds'] as List<dynamic>);
    }

    return ContractModel(
      id: doc.id,
      farmerId: data['farmerId'] as String,
      fieldIds: fieldIds,
      contractNumber: data['contractNumber'] as String,
      contractDate: (data['contractDate'] as Timestamp).toDate(),
      contractType: data['contractType'] as String,
      contractStatus: data['contractStatus'] as String,
      totalAmount: (data['totalAmount'] as num).toDouble(),
      downPayment: downPayment,
      intermediatePayments: intermediatePayments,
      finalPayment: finalPayment,
      contractDetails: contractDetails,
      attachments: attachments,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      memo: data['memo'] as String?,
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'fieldIds': fieldIds,
      'contractNumber': contractNumber,
      'contractDate': Timestamp.fromDate(contractDate),
      'contractType': contractType,
      'contractStatus': contractStatus,
      'totalAmount': totalAmount,
      'downPayment': downPayment.toMap(),
      'intermediatePayments':
          intermediatePayments.map((x) => x.toMap()).toList(),
      'finalPayment': finalPayment.toMap(),
      'contractDetails': contractDetails.toMap(),
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'memo': memo,
    };
  }

  // 복사 및 업데이트
  ContractModel copyWith({
    String? farmerId,
    List<String>? fieldIds,
    String? contractNumber,
    DateTime? contractDate,
    String? contractType,
    String? contractStatus,
    double? totalAmount,
    PaymentInfo? downPayment,
    List<IntermediatePayment>? intermediatePayments,
    PaymentInfo? finalPayment,
    ContractDetails? contractDetails,
    List<Attachment>? attachments,
    String? memo,
  }) {
    return ContractModel(
      id: this.id,
      farmerId: farmerId ?? this.farmerId,
      fieldIds: fieldIds ?? this.fieldIds,
      contractNumber: contractNumber ?? this.contractNumber,
      contractDate: contractDate ?? this.contractDate,
      contractType: contractType ?? this.contractType,
      contractStatus: contractStatus ?? this.contractStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      downPayment: downPayment ?? this.downPayment,
      intermediatePayments: intermediatePayments ?? this.intermediatePayments,
      finalPayment: finalPayment ?? this.finalPayment,
      contractDetails: contractDetails ?? this.contractDetails,
      attachments: attachments ?? this.attachments,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      createdBy: this.createdBy,
      memo: memo ?? this.memo,
    );
  }
}

class PaymentInfo {
  final double amount;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final double? paidAmount;
  final String? receiptImageUrl;
  final String status; // 미납, 납부예정, 납부완료

  PaymentInfo({
    required this.amount,
    this.dueDate,
    this.paidDate,
    this.paidAmount,
    this.receiptImageUrl,
    required this.status,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null,
      paidAmount: map['paidAmount'] != null
          ? (map['paidAmount'] as num).toDouble()
          : null,
      receiptImageUrl: map['receiptImageUrl'] as String?,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paidAmount': paidAmount,
      'receiptImageUrl': receiptImageUrl,
      'status': status,
    };
  }

  PaymentInfo copyWith({
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    double? paidAmount,
    String? receiptImageUrl,
    String? status,
  }) {
    return PaymentInfo(
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paidAmount: paidAmount ?? this.paidAmount,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      status: status ?? this.status,
    );
  }
}

class IntermediatePayment extends PaymentInfo {
  final int installmentNumber;

  IntermediatePayment({
    required this.installmentNumber,
    required double amount,
    DateTime? dueDate,
    DateTime? paidDate,
    double? paidAmount,
    String? receiptImageUrl,
    required String status,
  }) : super(
          amount: amount,
          dueDate: dueDate,
          paidDate: paidDate,
          paidAmount: paidAmount,
          receiptImageUrl: receiptImageUrl,
          status: status,
        );

  factory IntermediatePayment.fromMap(Map<String, dynamic> map) {
    return IntermediatePayment(
      installmentNumber: map['installmentNumber'] as int,
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null,
      paidAmount: map['paidAmount'] != null
          ? (map['paidAmount'] as num).toDouble()
          : null,
      receiptImageUrl: map['receiptImageUrl'] as String?,
      status: map['status'] as String,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> baseMap = super.toMap();
    baseMap['installmentNumber'] = installmentNumber;
    return baseMap;
  }

  @override
  IntermediatePayment copyWith({
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    double? paidAmount,
    String? receiptImageUrl,
    String? status,
  }) {
    return IntermediatePayment(
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paidAmount: paidAmount ?? this.paidAmount,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      status: status ?? this.status,
    );
  }
}

class ContractDetails {
  final DateTime? harvestPeriodStart;
  final DateTime? harvestPeriodEnd;
  final double pricePerUnit;
  final String unitType;
  final double estimatedQuantity;
  final String? specialTerms;
  final String? qualityStandards;

  ContractDetails({
    this.harvestPeriodStart,
    this.harvestPeriodEnd,
    required this.pricePerUnit,
    required this.unitType,
    required this.estimatedQuantity,
    this.specialTerms,
    this.qualityStandards,
  });

  factory ContractDetails.fromMap(Map<String, dynamic> map) {
    return ContractDetails(
      harvestPeriodStart:
          map['harvestPeriod'] != null && map['harvestPeriod']['start'] != null
              ? (map['harvestPeriod']['start'] as Timestamp).toDate()
              : null,
      harvestPeriodEnd:
          map['harvestPeriod'] != null && map['harvestPeriod']['end'] != null
              ? (map['harvestPeriod']['end'] as Timestamp).toDate()
              : null,
      pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
      unitType: map['unitType'] as String,
      estimatedQuantity: (map['estimatedQuantity'] as num).toDouble(),
      specialTerms: map['specialTerms'] as String?,
      qualityStandards: map['qualityStandards'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'harvestPeriod': {
        'start': harvestPeriodStart != null
            ? Timestamp.fromDate(harvestPeriodStart!)
            : null,
        'end': harvestPeriodEnd != null
            ? Timestamp.fromDate(harvestPeriodEnd!)
            : null,
      },
      'pricePerUnit': pricePerUnit,
      'unitType': unitType,
      'estimatedQuantity': estimatedQuantity,
      'specialTerms': specialTerms,
      'qualityStandards': qualityStandards,
    };
  }

  ContractDetails copyWith({
    DateTime? harvestPeriodStart,
    DateTime? harvestPeriodEnd,
    double? pricePerUnit,
    String? unitType,
    double? estimatedQuantity,
    String? specialTerms,
    String? qualityStandards,
  }) {
    return ContractDetails(
      harvestPeriodStart: harvestPeriodStart ?? this.harvestPeriodStart,
      harvestPeriodEnd: harvestPeriodEnd ?? this.harvestPeriodEnd,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unitType: unitType ?? this.unitType,
      estimatedQuantity: estimatedQuantity ?? this.estimatedQuantity,
      specialTerms: specialTerms ?? this.specialTerms,
      qualityStandards: qualityStandards ?? this.qualityStandards,
    );
  }
}

class Attachment {
  final String name;
  final String url;
  final String type;
  final DateTime uploadedAt;

  Attachment({
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
