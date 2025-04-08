import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/field_model.dart';

class FieldService {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 농지 컬렉션 참조
  CollectionReference get _fieldsCollection => _firestore.collection('fields');

  // 농가 컬렉션 참조
  CollectionReference get _farmsCollection => _firestore.collection('farms');

  // 모든 농지 가져오기
  Stream<List<FieldModel>> getFields() {
    return _fieldsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FieldModel.fromFirestore(doc)).toList();
    });
  }

  // 특정 농가의 농지 가져오기
  Stream<List<FieldModel>> getFieldsByFarm(String farmId) {
    return _fieldsCollection
        .where('farmerId', isEqualTo: farmId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FieldModel.fromFirestore(doc)).toList();
    });
  }

  // 단일 농지 정보 가져오기
  Future<FieldModel?> getField(String fieldId) async {
    try {
      DocumentSnapshot doc = await _fieldsCollection.doc(fieldId).get();
      if (doc.exists) {
        return FieldModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting field: $e');
      return null;
    }
  }

  // 농지 등록
  Future<String?> createField({
    required String farmerId,
    required Address address,
    required Area area,
    required String cropType,
    DateTime? estimatedHarvestDate,
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

      // 현재 시간
      DateTime now = DateTime.now();

      // 초기 작업 단계 설정
      CurrentStage currentStage = CurrentStage(
        stage: '계약예정',
        updatedAt: now,
      );

      // 저장할 데이터
      Map<String, dynamic> fieldData = {
        'farmerId': farmerId,
        'address': address.toMap(),
        'area': area.toMap(),
        'cropType': cropType,
        'estimatedHarvestDate': estimatedHarvestDate != null
            ? Timestamp.fromDate(estimatedHarvestDate)
            : null,
        'currentStage': currentStage.toMap(),
        'schedules': [],
        'contractIds': [],
        'contractStatus': null,
        'currentContract': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'memo': memo,
      };

      // Firestore에 저장
      DocumentReference docRef = await _fieldsCollection.add(fieldData);

      // 농가 문서에 농지 ID 추가
      await _farmsCollection.doc(farmerId).update({
        'fields': FieldValue.arrayUnion([docRef.id]),
        'updatedAt': Timestamp.fromDate(now),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating field: $e');
      return null;
    }
  }

  // 농지 정보 수정
  Future<bool> updateField({
    required String fieldId,
    String? farmerId,
    Address? address,
    Area? area,
    String? cropType,
    DateTime? estimatedHarvestDate,
    CurrentStage? currentStage,
    String? memo,
  }) async {
    try {
      // 현재 시간
      DateTime now = DateTime.now();

      // 수정할 데이터
      Map<String, dynamic> updateData = {};

      if (farmerId != null) updateData['farmerId'] = farmerId;
      if (address != null) updateData['address'] = address.toMap();
      if (area != null) updateData['area'] = area.toMap();
      if (cropType != null) updateData['cropType'] = cropType;
      if (estimatedHarvestDate != null) {
        updateData['estimatedHarvestDate'] =
            Timestamp.fromDate(estimatedHarvestDate);
      }
      if (currentStage != null)
        updateData['currentStage'] = currentStage.toMap();
      if (memo != null) updateData['memo'] = memo;

      // 수정 시간 업데이트
      updateData['updatedAt'] = Timestamp.fromDate(now);

      // Firestore 문서 업데이트
      await _fieldsCollection.doc(fieldId).update(updateData);

      // 만약 농가가 변경되었다면, 관련 농가 문서도 업데이트
      if (farmerId != null) {
        // 기존 농지 정보 가져오기
        DocumentSnapshot fieldDoc = await _fieldsCollection.doc(fieldId).get();
        FieldModel field = FieldModel.fromFirestore(fieldDoc);

        // 기존 농가의 fields 배열에서 현재 농지 ID 제거
        await _farmsCollection.doc(field.farmerId).update({
          'fields': FieldValue.arrayRemove([fieldId]),
          'updatedAt': Timestamp.fromDate(now),
        });

        // 새 농가의 fields 배열에 현재 농지 ID 추가
        await _farmsCollection.doc(farmerId).update({
          'fields': FieldValue.arrayUnion([fieldId]),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      return true;
    } catch (e) {
      print('Error updating field: $e');
      return false;
    }
  }

  // 농지 삭제
  Future<bool> deleteField(String fieldId) async {
    try {
      // 농지 정보 가져오기
      DocumentSnapshot fieldDoc = await _fieldsCollection.doc(fieldId).get();
      if (!fieldDoc.exists) {
        throw Exception('존재하지 않는 농지입니다.');
      }

      FieldModel field = FieldModel.fromFirestore(fieldDoc);

      // 현재 시간
      DateTime now = DateTime.now();

      // 농가 문서에서 농지 ID 제거
      await _farmsCollection.doc(field.farmerId).update({
        'fields': FieldValue.arrayRemove([fieldId]),
        'updatedAt': Timestamp.fromDate(now),
      });

      // TODO: 관련된 스케줄, 계약 등의 데이터 처리 필요

      // Firestore에서 농지 삭제
      await _fieldsCollection.doc(fieldId).delete();

      return true;
    } catch (e) {
      print('Error deleting field: $e');
      return false;
    }
  }

  // 작업 단계 변경
  Future<bool> updateFieldStage(String fieldId, String newStage) async {
    try {
      // 현재 시간
      DateTime now = DateTime.now();

      // 새 작업 단계
      CurrentStage stage = CurrentStage(
        stage: newStage,
        updatedAt: now,
      );

      // Firestore 문서 업데이트
      await _fieldsCollection.doc(fieldId).update({
        'currentStage': stage.toMap(),
        'updatedAt': Timestamp.fromDate(now),
      });

      return true;
    } catch (e) {
      print('Error updating field stage: $e');
      return false;
    }
  }

  // 작물 종류별 농지 검색
  Future<List<FieldModel>> searchFieldsByCropType(String cropType) async {
    try {
      if (cropType.isEmpty) return [];

      QuerySnapshot snapshot =
          await _fieldsCollection.where('cropType', isEqualTo: cropType).get();

      return snapshot.docs.map((doc) => FieldModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching fields by crop type: $e');
      return [];
    }
  }

  // 작업 단계별 농지 검색
  Future<List<FieldModel>> searchFieldsByStage(String stage) async {
    try {
      if (stage.isEmpty) return [];

      QuerySnapshot snapshot = await _fieldsCollection
          .where('currentStage.stage', isEqualTo: stage)
          .get();

      return snapshot.docs.map((doc) => FieldModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching fields by stage: $e');
      return [];
    }
  }

  // 작물 종류 목록 가져오기
  Future<List<String>> getCropTypes() async {
    try {
      QuerySnapshot snapshot = await _fieldsCollection.get();

      // 중복 제거를 위한 Set
      Set<String> cropTypesSet = {};

      // 모든 농지에서 작물 종류 추출
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('cropType') && data['cropType'] != null) {
          cropTypesSet.add(data['cropType'] as String);
        }
      }

      // Set을 List로 변환하여 반환
      List<String> cropTypes = cropTypesSet.toList();
      cropTypes.sort(); // 알파벳순 정렬

      return cropTypes;
    } catch (e) {
      print('Error getting crop types: $e');
      return [];
    }
  }

  // 작업 단계 목록 가져오기
  Future<List<String>> getStages() async {
    try {
      QuerySnapshot snapshot = await _fieldsCollection.get();

      // 중복 제거를 위한 Set
      Set<String> stagesSet = {};

      // 모든 농지에서 작업 단계 추출
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('currentStage') &&
            data['currentStage'] != null &&
            data['currentStage'] is Map &&
            (data['currentStage'] as Map).containsKey('stage')) {
          stagesSet.add((data['currentStage'] as Map)['stage'] as String);
        }
      }

      // Set을 List로 변환하여 반환
      List<String> stages = stagesSet.toList();
      stages.sort(); // 알파벳순 정렬

      return stages;
    } catch (e) {
      print('Error getting stages: $e');
      return [];
    }
  }
}
