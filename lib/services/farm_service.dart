import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm_model.dart';
import '../config/constants.dart';

class FarmService {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 농가 컬렉션 참조
  CollectionReference get _farmsCollection => _firestore.collection('farms');

  // 모든 농가 가져오기
  Stream<List<FarmModel>> getFarms() {
    return _farmsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FarmModel.fromFirestore(doc)).toList();
    });
  }

  // 단일 농가 정보 가져오기
  Future<FarmModel?> getFarm(String farmId) async {
    try {
      DocumentSnapshot doc = await _farmsCollection.doc(farmId).get();
      if (doc.exists) {
        return FarmModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting farm: $e');
      return null;
    }
  }

  // 농가 등록
  Future<String?> createFarm({
    required String name,
    required String phoneNumber,
    required String subdistrict,
    required String paymentGroup,
    String? personalId,
    Address? address,
    BankInfo? bankInfo,
    String? memo,
  }) async {
    try {
      // 현재 사용자 확인
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('인증되지 않은 사용자입니다.');
      }

      // 현재 시간
      DateTime now = DateTime.now();

      // 저장할 데이터
      Map<String, dynamic> farmData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'subdistrict': subdistrict,
        'paymentGroup': paymentGroup,
        'personalId': personalId,
        'address': address?.toMap(),
        'bankInfo': bankInfo?.toMap(),
        'fields': [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': currentUser.uid,
        'memo': memo,
      };

      // Firestore에 저장
      DocumentReference docRef = await _farmsCollection.add(farmData);
      return docRef.id;
    } catch (e) {
      print('Error creating farm: $e');
      return null;
    }
  }

  // 농가 정보 수정
  Future<bool> updateFarm({
    required String farmId,
    String? name,
    String? phoneNumber,
    String? subdistrict,
    String? paymentGroup,
    String? personalId,
    Address? address,
    BankInfo? bankInfo,
    String? memo,
  }) async {
    try {
      // 현재 시간
      DateTime now = DateTime.now();

      // 수정할 데이터
      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (subdistrict != null) updateData['subdistrict'] = subdistrict;
      if (paymentGroup != null) updateData['paymentGroup'] = paymentGroup;
      if (personalId != null) updateData['personalId'] = personalId;
      if (address != null) updateData['address'] = address.toMap();
      if (bankInfo != null) updateData['bankInfo'] = bankInfo.toMap();
      if (memo != null) updateData['memo'] = memo;

      // 수정 시간 업데이트
      updateData['updatedAt'] = Timestamp.fromDate(now);

      // Firestore 문서 업데이트
      await _farmsCollection.doc(farmId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating farm: $e');
      return false;
    }
  }

  // 농가 삭제
  Future<bool> deleteFarm(String farmId) async {
    try {
      // TODO: 관련된 농지, 작업, 계약 등의 데이터 처리 필요

      // Firestore에서 농가 삭제
      await _farmsCollection.doc(farmId).delete();
      return true;
    } catch (e) {
      print('Error deleting farm: $e');
      return false;
    }
  }

  // 이름으로 농가 검색
  Future<List<FarmModel>> searchFarmsByName(String query) async {
    try {
      if (query.isEmpty) return [];

      // 이름으로 검색 (시작 문자열 매칭)
      QuerySnapshot snapshot = await _farmsCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) => FarmModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching farms: $e');
      return [];
    }
  }

  // 전화번호로 농가 검색
  Future<List<FarmModel>> searchFarmsByPhone(String query) async {
    try {
      if (query.isEmpty) return [];

      // 전화번호로 검색 (부분 일치)
      QuerySnapshot snapshot = await _farmsCollection
          .where('phoneNumber', isGreaterThanOrEqualTo: query)
          .where('phoneNumber', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) => FarmModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching farms by phone: $e');
      return [];
    }
  }

  // 지역(면단위)별 농가 검색
  Future<List<FarmModel>> searchFarmsBySubdistrict(String subdistrict) async {
    try {
      if (subdistrict.isEmpty) return [];

      QuerySnapshot snapshot = await _farmsCollection
          .where('subdistrict', isEqualTo: subdistrict)
          .get();

      return snapshot.docs.map((doc) => FarmModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching farms by subdistrict: $e');
      return [];
    }
  }

  // 결제소속별 농가 검색
  Future<List<FarmModel>> searchFarmsByPaymentGroup(String paymentGroup) async {
    try {
      if (paymentGroup.isEmpty) return [];

      QuerySnapshot snapshot = await _farmsCollection
          .where('paymentGroup', isEqualTo: paymentGroup)
          .get();

      return snapshot.docs.map((doc) => FarmModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching farms by payment group: $e');
      return [];
    }
  }

  // 면단위 목록 가져오기
  Future<List<String>> getSubdistricts() async {
    try {
      QuerySnapshot snapshot = await _farmsCollection.get();

      // 중복 제거를 위한 Set
      Set<String> subdistrictsSet = {};

      // 모든 농가에서 면단위 추출
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('subdistrict') && data['subdistrict'] != null) {
          subdistrictsSet.add(data['subdistrict'] as String);
        }
      }

      // Set을 List로 변환하여 반환
      List<String> subdistricts = subdistrictsSet.toList();
      subdistricts.sort(); // 알파벳순 정렬

      return subdistricts;
    } catch (e) {
      print('Error getting subdistricts: $e');
      return [];
    }
  }

  // 결제소속 목록 가져오기
  Future<List<String>> getPaymentGroups() async {
    try {
      QuerySnapshot snapshot = await _farmsCollection.get();

      // 중복 제거를 위한 Set
      Set<String> paymentGroupsSet = {};

      // 모든 농가에서 결제소속 추출
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('paymentGroup') && data['paymentGroup'] != null) {
          paymentGroupsSet.add(data['paymentGroup'] as String);
        }
      }

      // Set을 List로 변환하여 반환
      List<String> paymentGroups = paymentGroupsSet.toList();
      paymentGroups.sort(); // 알파벳순 정렬

      return paymentGroups;
    } catch (e) {
      print('Error getting payment groups: $e');
      return [];
    }
  }
}
