// lib/services/contract_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/contract_model.dart';

class ContractService {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 계약 컬렉션 참조
  CollectionReference get _contractsCollection =>
      _firestore.collection('contracts');

  // 농가 컬렉션 참조
  CollectionReference get _farmsCollection => _firestore.collection('farms');

  // 농지 컬렉션 참조
  CollectionReference get _fieldsCollection => _firestore.collection('fields');

  // 모든 계약 가져오기
  Stream<List<ContractModel>> getContracts() {
    return _contractsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContractModel.fromFirestore(doc))
          .toList();
    });
  }

  // 특정 농가의 계약 가져오기
  Stream<List<ContractModel>> getContractsByFarm(String farmId) {
    return _contractsCollection
        .where('farmerId', isEqualTo: farmId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContractModel.fromFirestore(doc))
          .toList();
    });
  }

  // 특정 농지의 계약 가져오기
  Stream<List<ContractModel>> getContractsByField(String fieldId) {
    return _contractsCollection
        .where('fieldIds', arrayContains: fieldId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContractModel.fromFirestore(doc))
          .toList();
    });
  }

  // 계약 상태별 계약 가져오기
  Stream<List<ContractModel>> getContractsByStatus(String status) {
    return _contractsCollection
        .where('contractStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContractModel.fromFirestore(doc))
          .toList();
    });
  }

  // 단일 계약 정보 가져오기
  Future<ContractModel?> getContract(String contractId) async {
    try {
      DocumentSnapshot doc = await _contractsCollection.doc(contractId).get();
      if (doc.exists) {
        return ContractModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting contract: $e');
      return null;
    }
  }

  // 계약번호 자동 생성 (연도-월-일-시퀀스)
  Future<String> generateContractNumber() async {
    final now = DateTime.now();
    final datePrefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    try {
      // 오늘 날짜의 계약 수 카운트
      final snapshot = await _contractsCollection
          .where('contractNumber', isGreaterThanOrEqualTo: datePrefix)
          .where('contractNumber', isLessThan: '$datePrefix\uf8ff')
          .get();

      final sequenceNumber =
          (snapshot.docs.length + 1).toString().padLeft(3, '0');
      return '$datePrefix-$sequenceNumber';
    } catch (e) {
      print('Error generating contract number: $e');
      // 오류 발생 시 타임스탬프로 생성
      return '$datePrefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    }
  }

  // 계약 등록
  Future<String?> createContract({
    required String farmerId,
    required List<String> fieldIds,
    required DateTime contractDate,
    required String contractType,
    required double totalAmount,
    required PaymentInfo downPayment,
    required List<IntermediatePayment> intermediatePayments,
    required PaymentInfo finalPayment,
    required ContractDetails contractDetails,
    List<Attachment>? attachments,
    String? memo,
  }) async {
    try {
      // 현재 사용자 확인
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('인증되지 않은 사용자입니다.');
      }

      // 농가 존재 여부 확인
      DocumentSnapshot farmDoc = await _farmsCollection.doc(farmerId).get();
      if (!farmDoc.exists) {
        throw Exception('존재하지 않는 농가입니다.');
      }

      // 농지 존재 여부 확인
      for (String fieldId in fieldIds) {
        DocumentSnapshot fieldDoc = await _fieldsCollection.doc(fieldId).get();
        if (!fieldDoc.exists) {
          throw Exception('존재하지 않는 농지가 포함되어 있습니다: $fieldId');
        }
      }

      // 계약번호 생성
      String contractNumber = await generateContractNumber();

      // 현재 시간
      DateTime now = DateTime.now();

      // 저장할 데이터
      Map<String, dynamic> contractData = {
        'farmerId': farmerId,
        'fieldIds': fieldIds,
        'contractNumber': contractNumber,
        'contractDate': Timestamp.fromDate(contractDate),
        'contractType': contractType,
        'contractStatus': 'pending', // 초기 상태: 계약예정
        'totalAmount': totalAmount,
        'downPayment': downPayment.toMap(),
        'intermediatePayments':
            intermediatePayments.map((p) => p.toMap()).toList(),
        'finalPayment': finalPayment.toMap(),
        'contractDetails': contractDetails.toMap(),
        'attachments': attachments?.map((a) => a.toMap()).toList() ?? [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': currentUser.uid,
        'memo': memo,
      };

      // Firestore에 저장
      DocumentReference docRef = await _contractsCollection.add(contractData);

      // 농가 문서에 계약 ID 추가
      await _farmsCollection.doc(farmerId).update({
        'contracts': FieldValue.arrayUnion([docRef.id]),
        'activeContracts': FieldValue.increment(1),
        'totalContractAmount': FieldValue.increment(totalAmount),
        'remainingPayments': FieldValue.increment(totalAmount),
        'updatedAt': Timestamp.fromDate(now),
      });

      // 농지 문서에 계약 ID 및 계약 정보 추가
      for (String fieldId in fieldIds) {
        await _fieldsCollection.doc(fieldId).update({
          'contractIds': FieldValue.arrayUnion([docRef.id]),
          'contractStatus': 'pending',
          'currentContract': {
            'id': docRef.id,
            'contractNumber': contractNumber,
            'finalPaymentDueDate': finalPayment.dueDate != null
                ? Timestamp.fromDate(finalPayment.dueDate!)
                : null,
          },
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      return docRef.id;
    } catch (e) {
      print('Error creating contract: $e');
      return null;
    }
  }

  // 계약 정보 수정
  Future<bool> updateContract({
    required String contractId,
    String? contractType,
    String? contractStatus,
    double? totalAmount,
    PaymentInfo? downPayment,
    List<IntermediatePayment>? intermediatePayments,
    PaymentInfo? finalPayment,
    ContractDetails? contractDetails,
    String? memo,
  }) async {
    try {
      // 현재 시간
      DateTime now = DateTime.now();

      // 수정할 데이터
      Map<String, dynamic> updateData = {};

      if (contractType != null) updateData['contractType'] = contractType;
      if (contractStatus != null) updateData['contractStatus'] = contractStatus;
      if (totalAmount != null) updateData['totalAmount'] = totalAmount;
      if (downPayment != null) updateData['downPayment'] = downPayment.toMap();
      if (intermediatePayments != null) {
        updateData['intermediatePayments'] =
            intermediatePayments.map((p) => p.toMap()).toList();
      }
      if (finalPayment != null)
        updateData['finalPayment'] = finalPayment.toMap();
      if (contractDetails != null) {
        updateData['contractDetails'] = contractDetails.toMap();
      }
      if (memo != null) updateData['memo'] = memo;

      // 수정 시간 업데이트
      updateData['updatedAt'] = Timestamp.fromDate(now);

      // 기존 계약 정보 가져오기
      DocumentSnapshot contractDoc =
          await _contractsCollection.doc(contractId).get();
      if (!contractDoc.exists) {
        throw Exception('존재하지 않는 계약입니다.');
      }

      ContractModel contract = ContractModel.fromFirestore(contractDoc);

      // Firestore 문서 업데이트
      await _contractsCollection.doc(contractId).update(updateData);

      // 계약 상태가 변경된 경우, 관련 농지 문서의 계약 상태도 업데이트
      if (contractStatus != null && contractStatus != contract.contractStatus) {
        for (String fieldId in contract.fieldIds) {
          await _fieldsCollection.doc(fieldId).update({
            'contractStatus': contractStatus,
            'updatedAt': Timestamp.fromDate(now),
          });
        }
      }

      // 납부금액이 변경된 경우 농가 문서의 남은 결제 금액 업데이트
      if (totalAmount != null ||
          downPayment != null ||
          intermediatePayments != null ||
          finalPayment != null) {
        // 새 계약 정보로 계산된 총 납부액 구하기
        double paidAmount = 0;

        // 계약금 납부액
        if (downPayment != null && downPayment.paidAmount != null) {
          paidAmount += downPayment.paidAmount!;
        } else if (contract.downPayment.paidAmount != null) {
          paidAmount += contract.downPayment.paidAmount!;
        }

        // 중도금 납부액
        if (intermediatePayments != null) {
          for (var payment in intermediatePayments) {
            if (payment.paidAmount != null) {
              paidAmount += payment.paidAmount!;
            }
          }
        } else {
          for (var payment in contract.intermediatePayments) {
            if (payment.paidAmount != null) {
              paidAmount += payment.paidAmount!;
            }
          }
        }

        // 잔금 납부액
        if (finalPayment != null && finalPayment.paidAmount != null) {
          paidAmount += finalPayment.paidAmount!;
        } else if (contract.finalPayment.paidAmount != null) {
          paidAmount += contract.finalPayment.paidAmount!;
        }

        // 총 계약금액
        double newTotalAmount = totalAmount ?? contract.totalAmount;

        // 남은 결제 금액 계산
        double remainingPayment = newTotalAmount - paidAmount;

        // 농가 문서 업데이트
        await _farmsCollection.doc(contract.farmerId).update({
          'totalContractAmount':
              FieldValue.increment(newTotalAmount - contract.totalAmount),
          'remainingPayments': remainingPayment,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      return true;
    } catch (e) {
      print('Error updating contract: $e');
      return false;
    }
  }

  // 계약 상태 변경
  Future<bool> updateContractStatus(String contractId, String newStatus) async {
    try {
      return await updateContract(
          contractId: contractId, contractStatus: newStatus);
    } catch (e) {
      print('Error updating contract status: $e');
      return false;
    }
  }

  // 납부 처리
  Future<bool> processPayment({
    required String contractId,
    required String
        paymentType, // 'downPayment', 'intermediate', 'finalPayment'
    required int installmentNumber, // 중도금일 경우만 사용
    required DateTime paidDate,
    required double paidAmount,
    File? receiptImage,
  }) async {
    try {
      // 현재 시간
      DateTime now = DateTime.now();

      // 계약 정보 가져오기
      DocumentSnapshot contractDoc =
          await _contractsCollection.doc(contractId).get();
      if (!contractDoc.exists) {
        throw Exception('존재하지 않는 계약입니다.');
      }

      ContractModel contract = ContractModel.fromFirestore(contractDoc);

      // 영수증 이미지 업로드 (있는 경우)
      String? receiptImageUrl;
      if (receiptImage != null) {
        receiptImageUrl = await _uploadReceiptImage(
            contractId, paymentType, installmentNumber, receiptImage);
      }

      // 업데이트할 데이터 준비
      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(now),
      };

      // 납부 정보 업데이트
      switch (paymentType) {
        case 'downPayment':
          PaymentInfo updatedDownPayment = contract.downPayment.copyWith(
            paidDate: paidDate,
            paidAmount: paidAmount,
            status: 'paid',
            receiptImageUrl:
                receiptImageUrl ?? contract.downPayment.receiptImageUrl,
          );
          updateData['downPayment'] = updatedDownPayment.toMap();
          break;

        case 'intermediate':
          List<IntermediatePayment> updatedPayments =
              List.from(contract.intermediatePayments);
          int index = updatedPayments.indexWhere(
              (payment) => payment.installmentNumber == installmentNumber);

          if (index >= 0) {
            updatedPayments[index] = updatedPayments[index].copyWith(
              paidDate: paidDate,
              paidAmount: paidAmount,
              status: 'paid',
              receiptImageUrl:
                  receiptImageUrl ?? updatedPayments[index].receiptImageUrl,
            );
            updateData['intermediatePayments'] =
                updatedPayments.map((p) => p.toMap()).toList();
          } else {
            throw Exception('지정된 회차의 중도금을 찾을 수 없습니다.');
          }
          break;

        // lib/services/contract_service.dart (계속)
        case 'finalPayment':
          PaymentInfo updatedFinalPayment = contract.finalPayment.copyWith(
            paidDate: paidDate,
            paidAmount: paidAmount,
            status: 'paid',
            receiptImageUrl:
                receiptImageUrl ?? contract.finalPayment.receiptImageUrl,
          );
          updateData['finalPayment'] = updatedFinalPayment.toMap();
          break;

        default:
          throw Exception('올바르지 않은 납부 유형입니다.');
      }

      // 계약 상태 확인 및 업데이트
      bool allPaymentsPaid = _checkAllPaymentsPaid(contract.copyWith(
        downPayment: paymentType == 'downPayment'
            ? PaymentInfo.fromMap(
                updateData['downPayment'] as Map<String, dynamic>)
            : null,
        intermediatePayments: paymentType == 'intermediate'
            ? List<IntermediatePayment>.from(
                (updateData['intermediatePayments'] as List).map((x) =>
                    IntermediatePayment.fromMap(x as Map<String, dynamic>)))
            : null,
        finalPayment: paymentType == 'finalPayment'
            ? PaymentInfo.fromMap(
                updateData['finalPayment'] as Map<String, dynamic>)
            : null,
      ));

      if (allPaymentsPaid) {
        updateData['contractStatus'] = 'completed';
      }

      // Firestore 문서 업데이트
      await _contractsCollection.doc(contractId).update(updateData);

      // 모든 납부가 완료된 경우, 관련 농지 문서의 계약 상태도 업데이트
      if (allPaymentsPaid) {
        for (String fieldId in contract.fieldIds) {
          await _fieldsCollection.doc(fieldId).update({
            'contractStatus': 'completed',
            'updatedAt': Timestamp.fromDate(now),
          });
        }
      }

      // 농가 문서의 남은 결제 금액 업데이트
      await _farmsCollection.doc(contract.farmerId).update({
        'remainingPayments': FieldValue.increment(-paidAmount),
        'updatedAt': Timestamp.fromDate(now),
      });

      return true;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  // 모든 납부가 완료되었는지 확인하는 도우미 함수
  bool _checkAllPaymentsPaid(ContractModel contract) {
    // 계약금 확인
    if (contract.downPayment.status != 'paid') {
      return false;
    }

    // 중도금 확인 (있는 경우)
    for (var payment in contract.intermediatePayments) {
      if (payment.status != 'paid') {
        return false;
      }
    }

    // 잔금 확인
    return contract.finalPayment.status == 'paid';
  }

  // 영수증 이미지 업로드
  Future<String> _uploadReceiptImage(String contractId, String paymentType,
      int installmentNumber, File image) async {
    try {
      // 파일 경로 설정
      String fileName = '';
      if (paymentType == 'intermediate') {
        fileName =
            'payment_${paymentType}_${installmentNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        fileName =
            'payment_${paymentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      String filePath = 'payments/$contractId/receipts/$fileName';

      // Firebase Storage에 업로드
      UploadTask uploadTask = _storage.ref(filePath).putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading receipt image: $e');
      throw Exception('영수증 이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  // 첨부 파일 업로드
  Future<Attachment> uploadAttachment(
      String contractId, File file, String fileName, String fileType) async {
    try {
      // 파일 경로 설정
      String filePath =
          'contracts/$contractId/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Firebase Storage에 업로드
      UploadTask uploadTask = _storage.ref(filePath).putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      String downloadURL = await snapshot.ref.getDownloadURL();

      // 첨부 파일 정보 생성
      Attachment attachment = Attachment(
        name: fileName,
        url: downloadURL,
        type: fileType,
        uploadedAt: DateTime.now(),
      );

      // 계약 문서에 첨부 파일 추가
      await _contractsCollection.doc(contractId).update({
        'attachments': FieldValue.arrayUnion([attachment.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return attachment;
    } catch (e) {
      print('Error uploading attachment: $e');
      throw Exception('첨부 파일 업로드 중 오류가 발생했습니다: $e');
    }
  }

  // 계약 삭제
  Future<bool> deleteContract(String contractId) async {
    try {
      // 계약 정보 가져오기
      DocumentSnapshot contractDoc =
          await _contractsCollection.doc(contractId).get();
      if (!contractDoc.exists) {
        throw Exception('존재하지 않는 계약입니다.');
      }

      ContractModel contract = ContractModel.fromFirestore(contractDoc);

      // 현재 시간
      DateTime now = DateTime.now();

      // 농가 문서에서 계약 ID 제거
      await _farmsCollection.doc(contract.farmerId).update({
        'contracts': FieldValue.arrayRemove([contractId]),
        'activeContracts': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(now),
      });

      // 농지 문서에서 계약 ID 및 계약 정보 제거
      for (String fieldId in contract.fieldIds) {
        await _fieldsCollection.doc(fieldId).update({
          'contractIds': FieldValue.arrayRemove([contractId]),
          'contractStatus': null,
          'currentContract': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Firebase Storage에서 관련 파일 삭제
      try {
        // 계약 관련 폴더 참조
        final ListResult result =
            await _storage.ref('contracts/$contractId').listAll();

        // 모든 파일 삭제
        for (var ref in result.items) {
          await ref.delete();
        }

        // 모든 하위 폴더 재귀적으로 삭제
        for (var prefix in result.prefixes) {
          final ListResult subResult = await prefix.listAll();
          for (var ref in subResult.items) {
            await ref.delete();
          }
        }
      } catch (e) {
        print('Warning: Error deleting contract files: $e');
        // 파일 삭제 실패해도 계약 삭제는 계속 진행
      }

      // Firestore에서 계약 삭제
      await _contractsCollection.doc(contractId).delete();

      return true;
    } catch (e) {
      print('Error deleting contract: $e');
      return false;
    }
  }

  // 계약 유형 목록 가져오기
  Future<List<String>> getContractTypes() async {
    try {
      QuerySnapshot snapshot = await _contractsCollection.get();

      // 중복 제거를 위한 Set
      Set<String> contractTypesSet = {};

      // 모든 계약에서 계약 유형 추출
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('contractType') && data['contractType'] != null) {
          contractTypesSet.add(data['contractType'] as String);
        }
      }

      // 기본 계약 유형 추가
      contractTypesSet.addAll(['일반', '특수', '장기']);

      // Set을 List로 변환하여 반환
      List<String> contractTypes = contractTypesSet.toList();
      contractTypes.sort(); // 알파벳순 정렬

      return contractTypes;
    } catch (e) {
      print('Error getting contract types: $e');
      return ['일반', '특수', '장기']; // 기본값 반환
    }
  }

  // 계약 상태 목록 가져오기
  List<String> getContractStatuses() {
    return ['pending', 'active', 'completed', 'cancelled'];
  }

  // 특정 기간 내 납부 예정 계약 가져오기
  Future<List<ContractModel>> getDuePaymentsInPeriod(
      DateTime start, DateTime end) async {
    try {
      QuerySnapshot snapshot = await _contractsCollection.get();

      List<ContractModel> dueContracts = [];

      for (var doc in snapshot.docs) {
        ContractModel contract = ContractModel.fromFirestore(doc);

        // 계약금 확인
        if (contract.downPayment.dueDate != null &&
            contract.downPayment.status != 'paid' &&
            contract.downPayment.dueDate!.isAfter(start) &&
            contract.downPayment.dueDate!.isBefore(end)) {
          dueContracts.add(contract);
          continue; // 이미 추가됨
        }

        // 중도금 확인
        for (var payment in contract.intermediatePayments) {
          if (payment.dueDate != null &&
              payment.status != 'paid' &&
              payment.dueDate!.isAfter(start) &&
              payment.dueDate!.isBefore(end)) {
            dueContracts.add(contract);
            break; // 하나라도 있으면 추가
          }
        }

        // 잔금 확인
        if (contract.finalPayment.dueDate != null &&
            contract.finalPayment.status != 'paid' &&
            contract.finalPayment.dueDate!.isAfter(start) &&
            contract.finalPayment.dueDate!.isBefore(end)) {
          if (!dueContracts.contains(contract)) {
            dueContracts.add(contract);
          }
        }
      }

      return dueContracts;
    } catch (e) {
      print('Error getting due payments: $e');
      return [];
    }
  }
}
